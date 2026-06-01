import Foundation

final class BroadcastController {
    private var process: Process?
    private var errorPipe: Pipe?
    private var intentionalStop = false

    var isRunning: Bool {
        process?.isRunning == true
    }

    func start(settings: BroadcastSettings, sourceURL: URL, statusHandler: @escaping @Sendable (String) -> Void) throws {
        stop()
        intentionalStop = false

        guard !settings.streamKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "BroadcastController", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stream key is empty"])
        }
        guard !settings.ingestURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "BroadcastController", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ingest URL is empty"])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ffmpegArguments(settings: settings, sourceURL: sourceURL, redacted: false)
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
        self.errorPipe = errorPipe
    }

    func stop() {
        intentionalStop = true
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe = nil
        guard let process, process.isRunning else {
            self.process = nil
            return
        }
        process.terminate()
        self.process = nil
    }

    func commandPreview(settings: BroadcastSettings, sourceURL: URL) -> String {
        (["ffmpeg"] + ffmpegArguments(settings: settings, sourceURL: sourceURL, redacted: true).dropFirst()).joined(separator: " ")
    }

    private func ffmpegArguments(settings: BroadcastSettings, sourceURL: URL, redacted: Bool) -> [String] {
        let target = fullTargetURL(settings: settings, redacted: redacted)
        let fps = max(24, min(60, settings.frameRate))
        let bitrate = max(1000, min(20_000, settings.bitrateKbps))
        let gop = fps * 2

        var arguments = [
            "ffmpeg",
            "-hide_banner",
            "-loglevel", "warning",
            "-re"
        ]

        if settings.loopLatestRecording {
            arguments.append(contentsOf: ["-stream_loop", "-1"])
        }

        arguments.append(contentsOf: [
            "-i", sourceURL.path,
        ])
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
            target
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
}
