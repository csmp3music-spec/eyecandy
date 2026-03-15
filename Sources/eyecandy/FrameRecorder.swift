import AVFoundation
import Foundation
import Metal

enum FrameRecorderError: LocalizedError {
    case unavailable
    case cannotAddInput
    case missingPixelBufferPool
    case notRecording
    case finalizeFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Video writer unavailable."
        case .cannotAddInput:
            return "The MP4 writer could not add its input."
        case .missingPixelBufferPool:
            return "The MP4 writer did not create a pixel buffer pool."
        case .notRecording:
            return "No recording is in progress."
        case let .finalizeFailed(message):
            return message
        }
    }
}

final class FrameRecorder {
    private let queue = DispatchQueue(label: "eyecandy.recorder")
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private(set) var isRecording = false

    func start(url: URL, size: CGSize, fps: Int) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        let writer = try AVAssetWriter(url: url, fileType: .mp4)
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())

        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: width * height * max(fps, 24) * 2,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input.expectsMediaDataInRealTime = true

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferMetalCompatibilityKey as String: true,
            ]
        )

        guard writer.canAdd(input) else {
            throw FrameRecorderError.cannotAddInput
        }

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        self.writer = writer
        self.input = input
        self.adaptor = adaptor
        self.outputURL = url
        isRecording = true
    }

    func append(texture: MTLTexture, on commandBuffer: MTLCommandBuffer, frameIndex: UInt64, fps: Int) {
        guard isRecording else { return }

        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.queue.async {
                self?.appendImmediately(texture: texture, frameIndex: frameIndex, fps: fps)
            }
        }
    }

    func finish(completion: @escaping (Result<URL, Error>) -> Void) {
        guard isRecording, let writer, let input, let outputURL else {
            completion(.failure(FrameRecorderError.notRecording))
            return
        }

        isRecording = false

        queue.async {
            input.markAsFinished()
            writer.finishWriting {
                DispatchQueue.main.async {
                    if let error = writer.error {
                        completion(.failure(error))
                    } else if writer.status == .completed {
                        completion(.success(outputURL))
                    } else {
                        completion(.failure(FrameRecorderError.finalizeFailed("The MP4 writer did not complete successfully.")))
                    }
                }
            }
        }
    }

    private func appendImmediately(texture: MTLTexture, frameIndex: UInt64, fps: Int) {
        guard
            isRecording,
            let input,
            let adaptor,
            let pool = adaptor.pixelBufferPool,
            input.isReadyForMoreMediaData
        else {
            return
        }

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(baseAddress, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        let presentationTime = CMTime(value: Int64(frameIndex), timescale: CMTimeScale(max(fps, 24)))
        _ = adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}
