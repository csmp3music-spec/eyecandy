@preconcurrency import AVFoundation
import CoreImage
import CoreGraphics
import Foundation

@MainActor
final class CameraInputController: NSObject, ObservableObject {
    @Published var latestImage: CGImage?
    @Published var isRunning = false
    @Published var status = "Camera off"

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "eyecandy.camera.capture", qos: .userInitiated)
    private let ciContext = CIContext()

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.startSession()
                    } else {
                        self?.status = "Camera permission denied"
                    }
                }
            }
        case .denied, .restricted:
            status = "Camera permission denied"
        @unknown default:
            status = "Camera permission unavailable"
        }
    }

    func stop() {
        session.stopRunning()
        isRunning = false
        latestImage = nil
        status = "Camera off"
    }

    private func startSession() {
        if session.inputs.isEmpty {
            guard let camera = AVCaptureDevice.default(for: .video) else {
                status = "No camera found"
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                session.beginConfiguration()
                session.sessionPreset = .medium
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                output.setSampleBufferDelegate(self, queue: queue)
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                session.commitConfiguration()
            } catch {
                status = "Camera failed: \(error.localizedDescription)"
                return
            }
        }

        if !session.isRunning {
            queue.async { [session] in
                session.startRunning()
            }
        }
        isRunning = true
        status = "Camera running"
    }
}

extension CameraInputController: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = image.extent
        Task { @MainActor [weak self] in
            guard let self, let cgImage = self.ciContext.createCGImage(image, from: extent) else { return }
            self.latestImage = cgImage
        }
    }
}
