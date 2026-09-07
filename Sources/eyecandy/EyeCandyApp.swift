import Foundation
import SwiftUI

@main
struct EyeCandyApp: App {
    init() {
        if CommandLine.arguments.contains("--record-smoke") {
            do {
                let request = MP4RecordingRequest(
                    preset: PresetLibrary.visualPresets.first { $0.family == .holographic } ?? PresetLibrary.visualPresets[0],
                    sequencer: SequencerState(),
                    bpm: 132,
                    bloom: 0.7,
                    exposure: 0.85,
                    holographicMode: .chromaDepth,
                    hologramDepth: 0.7,
                    minterEffectMode: .neonStampede,
                    minterIntensity: 0.65,
                    demosceneEffectMode: .megaDemo,
                    demosceneIntensity: 0.75,
                    lightSynthMode: .everything,
                    lightSynthIntensity: 0.8,
                    macroX: 0.68,
                    macroY: 0.72,
                    phosphorPersistence: 0.66,
                    prismSplits: 6,
                    flashSafety: true,
                    paletteMode: .neon,
                    blendMode: .additive,
                    visualEngineMode: .engineAutopilot,
                    audioVisualizerMode: .hyperAnalyzer,
                    audioVisualizerIntensity: 0.76,
                    audioVisualizerDetail: 0.72,
                    audioVisualizerPersistence: 0.58,
                    experimentalVideoMode: .clean,
                    experimentalVideoIntensity: 0.55,
                    videoKeyThreshold: 0.52,
                    videoEdgeGain: 0.46,
                    videoColorWarp: 0.58,
                    videoOscillatorRate: 0.50,
                    feedbackSimulatorMode: .feedbackLab,
                    feedbackSimulatorIntensity: 0.58,
                    feedbackSimulatorDecay: 0.72,
                    feedbackSimulatorZoom: 0.52,
                    feedbackSimulatorTwist: 0.32,
                    feedbackSimulatorDisplacement: 0.60,
                    feedbackSimulatorPrism: 0.48,
                    feedbackSimulatorAudioReactive: true,
                    cameraInputEnabled: false,
                    cameraOverlayOpacity: 0.38,
                    cameraFeedbackAmount: 0.46,
                    cameraOverlayScale: 1.0,
                    cameraFeedbackMode: .optical,
                    cameraFeedbackRotation: 0.0,
                    cameraLumaThreshold: 0.22,
                    cameraChromaShift: 0.18,
                    cameraMirror: true,
                    cameraImage: nil,
                    stereoscopicMode: .off,
                    stereoDepth: 0.38,
                    sceneSeed: 1,
                    blackout: false,
                    freezeFrame: false,
                    strobeEnabled: false,
                    strobeRate: 8,
                    delaySettings: MultiTapDelaySettings(),
                    duration: 1,
                    fps: 12,
                    width: 640,
                    height: 360
                )
                let url = try MP4Recorder.render(request: request)
                print("record-smoke saved \(url.path)")
                Foundation.exit(0)
            } catch {
                let nsError = error as NSError
                fputs("record-smoke failed: \(error.localizedDescription) [\(nsError.domain) \(nsError.code)] \(nsError.userInfo)\n", stderr)
                Foundation.exit(1)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("All Notes Off") {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }
}
