import CoreGraphics
import CoreVideo
import Foundation

final class LiveBroadcastController {
    private var process: Process?
    private var inputPipe: Pipe?
    private var errorPipe: Pipe?
    private var frameTask: Task<Void, Never>?
    private var intentionalStop = false

    var isRunning: Bool {
        process?.isRunning == true
    }

    func start(
        settings: BroadcastSettings,
        width: Int,
        height: Int,
        statusHandler: @escaping @Sendable (String) -> Void,
        requestProvider: @escaping @Sendable () async -> MP4RecordingRequest
    ) throws {
        stop()
        intentionalStop = false

        guard !settings.streamKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "LiveBroadcastController", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stream key is empty"])
        }
        guard !settings.ingestURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "LiveBroadcastController", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ingest URL is empty"])
        }

        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = liveFFmpegArguments(settings: settings, width: width, height: height, redacted: false)
        process.standardInput = pipe
        process.standardOutput = Pipe()
        let errorPipe = Pipe()
        process.standardError = errorPipe
        attachErrorMonitoring(pipe: errorPipe, statusHandler: statusHandler)
        process.terminationHandler = { [weak self] process in
            guard self?.intentionalStop != true else { return }
            statusHandler("Broadcast ffmpeg exited with code \(process.terminationStatus)")
        }
        try process.run()

        self.process = process
        inputPipe = pipe
        self.errorPipe = errorPipe

        let fps = max(24, min(60, settings.frameRate))
        let frameDuration = UInt64(1_000_000_000 / fps)
        let output = pipe.fileHandleForWriting

        frameTask = Task.detached(priority: .userInitiated) { [weak self, weak process] in
            var frame = 0
            while !Task.isCancelled, process?.isRunning == true {
                let request = await requestProvider()
                do {
                    let buffer = try MP4Recorder.makePixelBuffer(width: width, height: height)
                    MP4Recorder.renderFrame(into: buffer, size: CGSize(width: width, height: height), request: request, frame: frame)
                    try Self.write(pixelBuffer: buffer, width: width, height: height, to: output)
                    frame += 1
                } catch {
                    break
                }
                try? await Task.sleep(nanoseconds: frameDuration)
            }
            try? output.close()
            if process?.isRunning == true {
                process?.terminate()
            }
            self?.process = nil
        }
    }

    func stop() {
        intentionalStop = true
        frameTask?.cancel()
        frameTask = nil
        try? inputPipe?.fileHandleForWriting.close()
        inputPipe = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe = nil
        guard let process, process.isRunning else {
            self.process = nil
            return
        }
        process.terminate()
        self.process = nil
    }

    func commandPreview(settings: BroadcastSettings, width: Int, height: Int) -> String {
        liveFFmpegArguments(settings: settings, width: width, height: height, redacted: true).joined(separator: " ")
    }

    private func liveFFmpegArguments(settings: BroadcastSettings, width: Int, height: Int, redacted: Bool) -> [String] {
        let fps = max(24, min(60, settings.frameRate))
        let bitrate = max(1000, min(20_000, settings.bitrateKbps))
        let gop = fps * 2
        var arguments = [
            "ffmpeg",
            "-hide_banner",
            "-loglevel", "warning",
            "-f", "rawvideo",
            "-pix_fmt", "bgra",
            "-s", "\(width)x\(height)",
            "-r", "\(fps)",
            "-i", "pipe:0",
        ]
        arguments.append(contentsOf: BroadcastAudioInput.inputArguments(settings: settings))
        arguments.append(contentsOf: [
            "-map", "0:v:0",
            "-map", "1:a:0",
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-tune", "zerolatency",
            "-r", "\(fps)",
            "-g", "\(gop)",
            "-b:v", "\(bitrate)k",
            "-maxrate", "\(bitrate)k",
            "-bufsize", "\(bitrate * 2)k",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", settings.target.recommendedAudioBitrate,
            "-ar", "\(settings.target.recommendedAudioSampleRate)",
            "-ac", "2",
            "-f", "flv",
            fullTargetURL(settings: settings, redacted: redacted)
        ])
        return arguments
    }

    private func attachErrorMonitoring(pipe: Pipe, statusHandler: @escaping @Sendable (String) -> Void) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
            let interesting = output
                .split(separator: "\n")
                .map(String.init)
                .filter { line in
                    let lower = line.lowercased()
                    return lower.contains("audio")
                        || lower.contains("avfoundation")
                        || lower.contains("aac")
                        || lower.contains("error")
                        || lower.contains("failed")
                        || lower.contains("invalid")
                }
                .suffix(3)
                .joined(separator: " | ")
            if !interesting.isEmpty {
                statusHandler("Broadcast: \(interesting)")
            }
        }
    }

    private func fullTargetURL(settings: BroadcastSettings, redacted: Bool) -> String {
        let base = settings.ingestURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = redacted ? "STREAM_KEY" : settings.streamKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") {
            return base + key
        }
        return base + "/" + key
    }

    private static func write(pixelBuffer: CVPixelBuffer, width: Int, height: Int, to output: FileHandle) throws {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let targetRowBytes = width * 4

        if bytesPerRow == targetRowBytes {
            let data = Data(bytes: baseAddress, count: targetRowBytes * height)
            try output.write(contentsOf: data)
            return
        }

        var data = Data()
        data.reserveCapacity(targetRowBytes * height)
        for row in 0..<height {
            let rowStart = baseAddress.advanced(by: row * bytesPerRow)
            data.append(rowStart.assumingMemoryBound(to: UInt8.self), count: targetRowBytes)
        }
        try output.write(contentsOf: data)
    }
}
