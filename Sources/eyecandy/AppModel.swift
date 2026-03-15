import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    let renderer = FeedbackRenderer()
    let liveRenderer = FeedbackRenderer()
    let audioEngine = ProceduralAudioEngine()
    private var liveOutputController: LiveOutputController?

    @Published private(set) var presets: [EffectPreset]
    @Published var selectedPreset: EffectPreset
    @Published var settings: EffectSettings {
        didSet {
            presetIsModified = settings != selectedPreset.settings
            syncRenderer()
        }
    }

    @Published var searchText = ""
    @Published var familyFilter: PresetFamily?
    @Published var activeTab: InspectorTab = .presets
    @Published var showInspector = true
    @Published var presetIsModified = false
    @Published var qualityScale: Float = 1.35 {
        didSet { syncRenderer() }
    }
    @Published var audio = AudioSettings() {
        didSet { syncAudio() }
    }
    @Published var captureProfile: CaptureProfile = .hd1080 {
        didSet { syncRenderer() }
    }
    @Published var exportFPS: Int = 30 {
        didSet { syncRenderer() }
    }
    @Published var isRecording = false
    @Published var liveOutputEnabled = false
    @Published var statusMessage = "High-definition recursive feedback ready."
    @Published var lastExportURL: URL?

    init() {
        let presetList = PresetLibrary.build()
        self.presets = presetList
        self.selectedPreset = presetList[0]
        self.settings = presetList[0].settings
        renderer.audioProvider = { [weak audioEngine] in
            audioEngine?.currentMetrics() ?? .neutral
        }
        liveRenderer.audioProvider = { [weak audioEngine] in
            audioEngine?.currentMetrics() ?? .neutral
        }
        syncRenderer()
        syncAudio()
    }

    func start() {
        syncRenderer()
        syncAudio()
    }

    func stop() {
        if liveOutputEnabled {
            toggleLiveOutput()
        }
    }

    var filteredPresets: [EffectPreset] {
        presets.filter { preset in
            let matchesFamily = familyFilter.map { $0 == preset.family } ?? true
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesText = query.isEmpty ||
                preset.name.localizedCaseInsensitiveContains(query) ||
                preset.summary.localizedCaseInsensitiveContains(query) ||
                preset.family.rawValue.localizedCaseInsensitiveContains(query)
            return matchesFamily && matchesText
        }
    }

    func binding(for descriptor: SliderDescriptor) -> Binding<Double> {
        Binding(
            get: { Double(self.settings[keyPath: descriptor.keyPath]) },
            set: { newValue in
                var updated = self.settings
                let clamped = min(max(Float(newValue), descriptor.range.lowerBound), descriptor.range.upperBound)
                updated[keyPath: descriptor.keyPath] = clamped
                self.settings = updated
            }
        )
    }

    func apply(_ preset: EffectPreset) {
        selectedPreset = preset
        settings = preset.settings
        presetIsModified = false
        statusMessage = "\(preset.name) loaded."
    }

    func resetCurrentPreset() {
        apply(selectedPreset)
    }

    func stepPreset(by delta: Int) {
        guard let currentIndex = presets.firstIndex(where: { $0.id == selectedPreset.id }) else { return }
        let nextIndex = (currentIndex + delta + presets.count) % presets.count
        apply(presets[nextIndex])
    }

    func randomizeExploration() {
        let base = presets.randomElement() ?? selectedPreset
        selectedPreset = base

        var nextSettings = base.settings
        for descriptor in ControlSchema.allDescriptors {
            let span = descriptor.range.upperBound - descriptor.range.lowerBound
            let delta = Float.random(in: -0.18 ... 0.18) * span * 0.28
            let candidate = nextSettings[keyPath: descriptor.keyPath] + delta
            nextSettings[keyPath: descriptor.keyPath] = min(max(candidate, descriptor.range.lowerBound), descriptor.range.upperBound)
        }

        settings = nextSettings
        presetIsModified = true
        statusMessage = "Experimental variation generated from \(base.name)."
    }

    func toggleInspector() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            showInspector.toggle()
        }
    }

    func toggleMute() {
        audio.muted.toggle()
    }

    func toggleLiveOutput() {
        if liveOutputEnabled {
            liveOutputController?.close()
            liveOutputController = nil
            liveOutputEnabled = false
            statusMessage = "Live output closed."
            return
        }

        let controller = liveOutputController ?? LiveOutputController(model: self)
        let screenName = controller.present()
        liveOutputController = controller
        liveOutputEnabled = true
        statusMessage = "Live output routed to \(screenName)."
    }

    func toggleFullscreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
        statusMessage = "Fullscreen toggled."
    }

    func binding(for keyPath: WritableKeyPath<AudioSettings, Float>, in range: ClosedRange<Float>) -> Binding<Double> {
        Binding(
            get: { Double(self.audio[keyPath: keyPath]) },
            set: { newValue in
                var updated = self.audio
                updated[keyPath: keyPath] = min(max(Float(newValue), range.lowerBound), range.upperBound)
                self.audio = updated
            }
        )
    }

    func startOrStopRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        let panel = NSSavePanel()
        panel.title = "Record Eye Candy"
        panel.nameFieldStringValue = "eyecandy-\(timestamp()).mp4"
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try renderer.startRecording(to: url, size: captureProfile.size, fps: exportFPS)
            isRecording = true
            statusMessage = "Recording MP4 to \(url.lastPathComponent)."
        } catch {
            statusMessage = "Recording failed to start: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        isRecording = false
        renderer.stopRecording { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(url):
                self.lastExportURL = url
                self.statusMessage = "Saved \(url.lastPathComponent)."
            case let .failure(error):
                self.statusMessage = "Recording failed: \(error.localizedDescription)"
            }
        }
    }

    func syncRenderer() {
        renderer.update(
            settings: settings,
            audioSettings: audio,
            qualityScale: qualityScale,
            captureSize: captureProfile.size,
            captureFPS: exportFPS,
            presetName: selectedPreset.name
        )
        liveRenderer.update(
            settings: settings,
            audioSettings: audio,
            qualityScale: max(qualityScale, 1.0),
            captureSize: captureProfile.size,
            captureFPS: exportFPS,
            presetName: selectedPreset.name
        )
    }

    private func syncAudio() {
        audioEngine.update(settings: settings, family: selectedPreset.family, audio: audio)
        syncRenderer()
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
