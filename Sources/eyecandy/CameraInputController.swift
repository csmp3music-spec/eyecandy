@preconcurrency import AVFoundation
import CoreImage
import CoreGraphics
import Foundation

struct CameraInputDevice: Identifiable, Hashable {
    var id: String
    var name: String
    var position: String

    var displayName: String {
        position.isEmpty ? name : "\(name) - \(position)"
    }
}

@MainActor
final class CameraInputController: NSObject, ObservableObject {
    @Published var latestImage: CGImage?
    @Published var isRunning = false
    @Published var status = "Camera off"
    @Published var availableDevices: [CameraInputDevice] = []
    @Published var selectedDeviceID = ""

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "eyecandy.camera.capture", qos: .userInitiated)
    private let ciContext = CIContext()

    override init() {
        super.init()
        refreshDevices()
    }

    func refreshDevices() {
        let devices = Self.discoverVideoDevices()
        availableDevices = devices.map {
            CameraInputDevice(id: $0.uniqueID, name: $0.localizedName, position: Self.positionName($0.position))
        }
        if selectedDeviceID.isEmpty || !availableDevices.contains(where: { $0.id == selectedDeviceID }) {
            selectedDeviceID = availableDevices.first?.id ?? ""
        }
        status = availableDevices.isEmpty ? "No camera found" : "Found \(availableDevices.count) camera\(availableDevices.count == 1 ? "" : "s")"
    }

    func selectDevice(id: String) {
        guard selectedDeviceID != id else { return }
        selectedDeviceID = id
        if isRunning {
            reconfigureRunningSession()
        } else if let device = availableDevices.first(where: { $0.id == id }) {
            status = "Selected \(device.displayName)"
        }
    }

    func start() {
        refreshDevices()
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
        if session.isRunning {
            session.stopRunning()
        }
        isRunning = false
        latestImage = nil
        status = "Camera off"
    }

    private func startSession() {
        guard configureSession() else {
            return
        }

        if !session.isRunning {
            queue.async { [session] in
                session.startRunning()
            }
        }
        isRunning = true
        status = "Camera running: \(selectedDeviceName())"
    }

    private func reconfigureRunningSession() {
        let wasRunning = session.isRunning
        if wasRunning {
            session.stopRunning()
        }
        latestImage = nil
        guard configureSession() else {
            isRunning = false
            return
        }
        if wasRunning {
            queue.async { [session] in
                session.startRunning()
            }
        }
        isRunning = wasRunning
        status = wasRunning ? "Camera running: \(selectedDeviceName())" : "Selected \(selectedDeviceName())"
    }

    private func configureSession() -> Bool {
        refreshDevicesIfNeeded()
        guard let camera = selectedCaptureDevice() else {
            status = "No camera found"
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            session.beginConfiguration()
            session.sessionPreset = .medium
            for existing in session.inputs {
                session.removeInput(existing)
            }
            if session.outputs.isEmpty {
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                output.setSampleBufferDelegate(self, queue: queue)
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
            }
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                session.commitConfiguration()
                status = "Camera input unavailable"
                return false
            }
            session.commitConfiguration()
            return true
        } catch {
            status = "Camera failed: \(error.localizedDescription)"
            return false
        }
    }

    private func selectedCaptureDevice() -> AVCaptureDevice? {
        let devices = Self.discoverVideoDevices()
        if let match = devices.first(where: { $0.uniqueID == selectedDeviceID }) {
            return match
        }
        selectedDeviceID = devices.first?.uniqueID ?? ""
        return devices.first
    }

    private func selectedDeviceName() -> String {
        availableDevices.first(where: { $0.id == selectedDeviceID })?.displayName ?? "Camera"
    }

    private func refreshDevicesIfNeeded() {
        if availableDevices.isEmpty || !availableDevices.contains(where: { $0.id == selectedDeviceID }) {
            refreshDevices()
        }
    }

    private static func discoverVideoDevices() -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .externalUnknown
        ]
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .unspecified)
        return discovery.devices
    }

    private static func positionName(_ position: AVCaptureDevice.Position) -> String {
        switch position {
        case .front:
            return "Front"
        case .back:
            return "Back"
        case .unspecified:
            return "External"
        @unknown default:
            return ""
        }
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
