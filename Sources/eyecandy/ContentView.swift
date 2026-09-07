import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        HStack(spacing: 0) {
            RendererView(model: model)
                .frame(minWidth: 720, minHeight: 560)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                header

                topOptionMenus
                quickPanelGrid
                liveStatusStrip

                InspectorScrollView {
                    inspectorPanelContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.trailing, 10)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(16)
            .frame(width: 390)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onChange(of: model.sequencer) { _ in model.pushAudioState() }
        .onChange(of: model.bassVoice) { _ in model.pushAudioState() }
        .onChange(of: model.leadVoice) { _ in model.pushAudioState() }
        .onChange(of: model.delaySettings) { _ in model.pushAudioState() }
        .onChange(of: model.mixer) { _ in model.pushAudioState() }
        .onChange(of: model.masterLevel) { _ in model.pushAudioState() }
        .onChange(of: model.masterDrive) { _ in model.pushAudioState() }
        .onChange(of: model.stereoWidth) { _ in model.pushAudioState() }
        .onChange(of: model.limiterCeiling) { _ in model.pushAudioState() }
        .onChange(of: model.limiterRelease) { _ in model.pushAudioState() }
        .onAppear { model.startAudio() }
    }

    @ViewBuilder
    private var inspectorPanelContent: some View {
        switch model.selectedPanel {
        case .studio:
            studioPanel
        case .presets:
            presetPanel
        case .sequencer:
            sequencerPanel
        case .synth:
            synthPanel
        case .delayFX:
            delayFXPanel
        case .drums:
            drumPanel
        case .keyboard:
            keyboardPanel
        case .lightSynth:
            lightSynthPanel
        case .feedbackCamera:
            feedbackCameraPanel
        case .broadcast:
            broadcastPanel
        case .performance:
            performancePanel
        case .output:
            outputPanel
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("sonic screwdriver eyecandy")
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer()
                Text(model.selectedPanel.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(model.status)
                .foregroundStyle(.secondary)
                .font(.caption)
                .lineLimit(2)
            HStack(spacing: 8) {
                Button { model.startAudio() } label: {
                    Label("Start", systemImage: "play.fill")
                }
                Button { model.stopAudio() } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                Button { model.randomizeVisual() } label: {
                    Label("Random", systemImage: "shuffle")
                }
                Button { model.regenerateVisualScene() } label: {
                    Label("Regen", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .controlSize(.small)
        }
    }

    private var quickPanelGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            quickPanelButton(.studio, "Studio", "dial.medium")
            quickPanelButton(.lightSynth, "Visual", "camera.filters")
            quickPanelButton(.sequencer, "Seq", "square.grid.4x3.fill")
            quickPanelButton(.synth, "Synth", "waveform")
            quickPanelButton(.performance, "Perf", "bolt.fill")
            quickPanelButton(.output, "Output", "slider.horizontal.3")
        }
    }

    private func quickPanelButton(_ panel: InspectorPanel, _ title: String, _ systemImage: String) -> some View {
        Button {
            model.selectedPanel = panel
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(model.selectedPanel == panel ? .cyan : .secondary)
        .controlSize(.small)
    }

    private var liveStatusStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                statusCapsule("\(Int(model.sequencer.bpm)) BPM", color: .cyan)
                statusCapsule(model.audioVisualizerMode.rawValue, color: .pink)
                statusCapsule(model.paletteMode.rawValue, color: .orange)
            }
            meterRow("Audio", value: max(model.audioMeter.peakLeft, model.audioMeter.peakRight))
            meterRow("Flux", value: model.audioMeter.spectralFlux)
        }
        .padding(10)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func statusCapsule(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }

    private var topOptionMenus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                optionMenu("Panel", selection: $model.selectedPanel, systemImage: "sidebar.left")

                Menu {
                    optionButtons(PresetFamily.allCases, selection: $model.selectedFamily)
                    Divider()
                    Menu("Visual Presets") {
                        ForEach(model.filteredPresets) { preset in
                            Button(preset.name) { model.applyPreset(preset) }
                        }
                    }
                    Menu("Performance Presets") {
                        ForEach(PresetLibrary.videoPerformancePresets) { preset in
                            Button(preset.name) { model.applyVideoPerformancePreset(preset) }
                        }
                    }
                } label: {
                    Label("Presets", systemImage: "sparkles")
                }

                Menu {
                    optionButtons(LightSynthMode.allCases, selection: $model.lightSynthMode)
                    Divider()
                    Menu("Engine") {
                        optionButtons(VisualEngineMode.allCases, selection: $model.visualEngineMode)
                    }
                    Menu("Audio Visualizer") {
                        optionButtons(AudioVisualizerMode.allCases, selection: $model.audioVisualizerMode)
                    }
                    Menu("Palette") {
                        optionButtons(LightPaletteMode.allCases, selection: $model.paletteMode)
                    }
                    Menu("Blend") {
                        optionButtons(LightBlendMode.allCases, selection: $model.blendMode)
                    }
                    Menu("Stereo") {
                        optionButtons(StereoscopicMode.allCases, selection: $model.stereoscopicMode)
                    }
                    Menu("Demoscene") {
                        optionButtons(DemosceneEffectMode.allCases, selection: $model.demosceneEffectMode)
                    }
                    Menu("Minter") {
                        optionButtons(MinterEffectMode.allCases, selection: $model.minterEffectMode)
                    }
                    Menu("Hologram") {
                        optionButtons(HolographicMode.allCases, selection: $model.holographicMode)
                    }
                } label: {
                    Label("Visual", systemImage: "camera.filters")
                }
            }

            HStack(spacing: 8) {
                Menu {
                    optionButtons(ExperimentalVideoMode.allCases, selection: $model.experimentalVideoMode)
                    Divider()
                    Menu("Camera Source") {
                        if model.cameraInput.availableDevices.isEmpty {
                            Button("No cameras found") {}
                                .disabled(true)
                        } else {
                            ForEach(model.cameraInput.availableDevices) { device in
                                Button {
                                    model.selectCameraDevice(device.id)
                                } label: {
                                    if device.id == model.cameraInput.selectedDeviceID {
                                        Label(device.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(device.displayName)
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Refresh Cameras") { model.refreshCameraDevices() }
                    }
                    Menu("Camera Feedback") {
                        optionButtons(CameraFeedbackMode.allCases, selection: $model.cameraFeedbackMode)
                    }
                    Menu("Feedback Simulator") {
                        optionButtons(FeedbackSimulatorMode.allCases, selection: $model.feedbackSimulatorMode)
                    }
                    Toggle("Camera Input", isOn: cameraInputBinding)
                    Toggle("Simulator Audio Reactive", isOn: $model.feedbackSimulatorAudioReactive)
                    Toggle("Mirror Camera", isOn: $model.cameraMirror)
                    Toggle("Freeze Frame", isOn: $model.freezeFrame)
                    Toggle("Blackout", isOn: $model.blackout)
                    Toggle("Strobe Gate", isOn: $model.strobeEnabled)
                    Divider()
                    Button("Trip Max") { model.setTripMaximum() }
                    Button("Safe Cruise") { model.setSafeCruise() }
                } label: {
                    Label("Video", systemImage: "video")
                }

                Menu {
                    optionButtons(TempoMode.allCases, selection: tempoModeBinding)
                    Menu("Composition") {
                        optionButtons(CompositionStyle.allCases, selection: $model.sequencer.compositionStyle)
                    }
                    Menu("Groove") {
                        optionButtons(GrooveTemplate.allCases, selection: $model.sequencer.groove)
                    }
                    Menu("Scale") {
                        optionButtons(SequencerScale.allCases, selection: $model.sequencer.scale)
                    }
                    Menu("Bass Instrument") {
                        optionButtons(SynthInstrument.allCases, selection: $model.bassVoice.instrument)
                    }
                    Menu("Lead Instrument") {
                        optionButtons(SynthInstrument.allCases, selection: $model.leadVoice.instrument)
                    }
                    Menu("Drum Presets") {
                        ForEach(PresetLibrary.drumPresets) { preset in
                            Button(preset.name) { model.applyDrumPreset(preset) }
                        }
                    }
                    Divider()
                    Toggle("Play Sequencer", isOn: $model.sequencer.isPlaying)
                    Button("Generate Composition") { model.generateComposition() }
                    Button("Euclidean Drums") { model.generateEuclideanDrums() }
                    Button("Counter Melody") { model.generateCounterMelody() }
                    Button("Randomize Pattern") { model.randomizePattern() }
                    Button("Mutate Pattern") { model.mutatePattern() }
                    Button("Humanize Pattern") { model.humanizePattern() }
                } label: {
                    Label("Audio", systemImage: "waveform")
                }

                Menu {
                    Menu("Resolution") {
                        optionButtons(RecordingResolution.allCases, selection: $model.recordingResolution)
                    }
                    Menu("Frame Rate") {
                        Button("24 fps") { model.recordingFPS = 24 }
                        Button("30 fps") { model.recordingFPS = 30 }
                        Button("60 fps") { model.recordingFPS = 60 }
                    }
                    Divider()
                    Button(model.isRecording ? "Rendering MP4..." : "Record MP4") { model.recordMP4() }
                        .disabled(model.isRecording)
                } label: {
                    Label("Record", systemImage: "record.circle")
                }

                Menu {
                    Menu("Source") {
                        optionButtons(BroadcastSourceMode.allCases, selection: $model.broadcastSettings.sourceMode)
                    }
                    Menu("Target") {
                        ForEach(BroadcastTarget.allCases) { target in
                            Button(target.rawValue) { model.applyBroadcastTarget(target) }
                        }
                    }
                    Menu("Audio") {
                        optionButtons(BroadcastAudioMode.allCases, selection: $model.broadcastSettings.audioMode)
                    }
                    Divider()
                    Button("Facebook Safe Setup") { model.applyFacebookLiveSafeSetup() }
                    Button(model.isBroadcasting ? "Broadcasting..." : "Start Broadcast") { model.startBroadcast() }
                        .disabled(model.isBroadcasting || model.broadcastSettings.streamKey.isEmpty)
                    Button("Stop Broadcast") { model.stopBroadcast() }
                        .disabled(!model.isBroadcasting)
                } label: {
                    Label("Live", systemImage: "dot.radiowaves.left.and.right")
                }
            }
        }
        .menuStyle(.button)
        .controlSize(.small)
    }

    private func optionMenu<T>(_ title: String, selection: Binding<T>, systemImage: String) -> some View where T: CaseIterable & Identifiable & RawRepresentable & Hashable, T.RawValue == String, T.AllCases: RandomAccessCollection, T.AllCases.Element == T {
        Menu {
            optionButtons(T.allCases, selection: selection)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }

    @ViewBuilder
    private func optionButtons<Options, T>(_ options: Options, selection: Binding<T>) -> some View where Options: RandomAccessCollection, Options.Element == T, T: Identifiable & RawRepresentable & Hashable, T.RawValue == String {
        ForEach(Array(options), id: \.self) { option in
            Button {
                selection.wrappedValue = option
            } label: {
                if option == selection.wrappedValue {
                    Label(option.rawValue, systemImage: "checkmark")
                } else {
                    Text(option.rawValue)
                }
            }
        }
    }

    private var studioPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelCard("Performance Deck", systemImage: "slider.horizontal.3") {
                HStack {
                    Button(model.sequencer.isPlaying ? "Stop Seq" : "Play Seq") {
                        model.sequencer.isPlaying.toggle()
                    }
                    Button("Tap") { model.tapTempo() }
                    Button("Random Visual") { model.randomizeVisual() }
                    Button("Regenerate") { model.regenerateVisualScene() }
                }
                .controlSize(.small)

                HStack {
                    Text("Tempo \(Int(model.sequencer.bpm)) BPM")
                        .font(.headline)
                    Spacer()
                    Text(model.tempoMode.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: bpmBinding, in: 40...240) { Text("Tempo") }

                Picker("Scene launch", selection: $model.sceneLaunchQuantization) {
                    ForEach(SceneLaunchQuantization.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("\(model.savedSceneCount) / 8 scenes saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if model.queuedSceneSlot != nil {
                        Button("Cancel Queue") { model.cancelQueuedScene() }
                            .controlSize(.small)
                    }
                }

                if let queued = model.queuedSceneSlot {
                    Text("Queued Scene \(queued + 1) for \(model.sceneLaunchQuantization.shortLabel)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
                    ForEach(0..<8, id: \.self) { slot in
                        sceneDeckSlotButton(slot, minHeight: 62)
                    }
                }

                HStack {
                    Button("Generate Deck") { model.randomizeSceneDeck() }
                    Button("Safe Output") { model.applyProductionSafeOutput() }
                    Button("Wide Stage") { model.applyWideStageMix() }
                }
                .controlSize(.small)
            }

            panelCard("Mixer", systemImage: "music.note.list") {
                mixerChannelEditor("Bass", channel: $model.mixer.bass, accent: .cyan)
                mixerChannelEditor("Lead", channel: $model.mixer.lead, accent: .pink)
                mixerChannelEditor("Drums", channel: $model.mixer.drums, accent: .orange)
                mixerChannelEditor("Keys", channel: $model.mixer.liveKeys, accent: .green)
                mixerChannelEditor("FX Return", channel: $model.mixer.fxReturn, accent: .purple, showSend: false)
                VStack(alignment: .leading, spacing: 6) {
                    meterRow("L", value: model.audioMeter.peakLeft)
                    meterRow("R", value: model.audioMeter.peakRight)
                    meterRow("GR", value: model.audioMeter.limiterReduction)
                }
            }

            panelCard("Audio Visualizer", systemImage: "waveform.path.ecg") {
                Picker("Mode", selection: $model.audioVisualizerMode) {
                    ForEach(AudioVisualizerMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                Slider(value: $model.audioVisualizerIntensity, in: 0...1) { Text("Intensity") }
                Slider(value: $model.audioVisualizerDetail, in: 0...1) { Text("Detail") }
                Slider(value: $model.audioVisualizerPersistence, in: 0...1) { Text("Persistence") }
                VStack(alignment: .leading, spacing: 6) {
                    meterRow("Bass", value: model.audioMeter.bass)
                    meterRow("Mid", value: model.audioMeter.mid)
                    meterRow("High", value: model.audioMeter.treble)
                    meterRow("Flux", value: model.audioMeter.spectralFlux)
                }
                HStack {
                    Button("Max") { model.applyVisualizerMax() }
                    Button("Synth") { model.applyVisualizerSynth() }
                    Button("Focus") { model.applyVisualizerFocus() }
                }
                .controlSize(.small)
            }

            panelCard("Visual Output", systemImage: "sun.max") {
                Picker("GPU effects", selection: $model.gpuVisualizerBackend) {
                    ForEach(GPUVisualizerBackend.allCases) { backend in
                        Text(backend.rawValue).tag(backend)
                    }
                }
                .pickerStyle(.menu)
                Picker("Metal program", selection: $model.metalVisualizerEffectMode) {
                    ForEach(MetalVisualizerEffectMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                Slider(value: $model.metalVisualizerEffectIntensity, in: 0...1) { Text("Metal effect intensity") }
                Slider(value: $model.metalVisualizerEffectSpeed, in: 0.1...2.5) { Text("Metal effect speed") }
                Picker("Psychedelic field", selection: $model.psychedelicFieldMode) {
                    ForEach(PsychedelicFieldMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                Slider(value: $model.psychedelicFieldIntensity, in: 0...1) { Text("Psychedelic intensity") }
                Slider(value: $model.psychedelicFieldMotion, in: 0.1...2.5) { Text("Psychedelic motion") }
                Slider(value: $model.lightSynthIntensity, in: 0...1) { Text("Synth intensity") }
                Slider(value: $model.experimentalVideoIntensity, in: 0...1) { Text("Video intensity") }
                Slider(value: $model.bloom, in: 0...1) { Text("Bloom") }
                Slider(value: $model.exposure, in: 0.1...1.2) { Text("Exposure") }
                Slider(value: $model.visualOutputGain, in: 0.3...1.0) { Text("Visual gain") }
                Slider(value: $model.visualSoftClip, in: 0.45...0.98) { Text("Visual soft clip") }
                HStack {
                    Toggle("Flash safety", isOn: $model.flashSafety)
                    Spacer()
                    Button("Safe Cruise") { model.setSafeCruise() }
                    Button("Trip Max") { model.setTripMaximum() }
                }
                .controlSize(.small)
            }
        }
    }

    private func panelCard<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private func sceneDeckSlotButton(_ slot: Int, minHeight: CGFloat = 58) -> some View {
        Button {
            model.recallScene(slot: slot)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(model.sceneSlotTitle(slot))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    if let status = model.sceneSlotStatus(slot) {
                        Text(status)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(sceneSlotAccent(slot))
                    }
                }
                Text(model.sceneSlotSubtitle(slot))
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        }
        .disabled(model.sceneDeck[slot] == nil)
        .buttonStyle(.bordered)
        .tint(sceneSlotAccent(slot))
    }

    private func sceneSlotAccent(_ slot: Int) -> Color {
        if model.activeSceneSlot == slot {
            return .green
        }
        if model.queuedSceneSlot == slot {
            return .orange
        }
        return model.sceneDeck[slot] == nil ? .secondary : .cyan
    }

    private var presetPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Search visual presets", text: $model.visualPresetFilter)
                .textFieldStyle(.roundedBorder)
            Picker("Family", selection: $model.selectedFamily) {
                ForEach(PresetFamily.allCases) { family in
                    Text(family.rawValue).tag(family)
                }
            }
            .pickerStyle(.menu)
            Text("\(model.filteredPresets.count) of \(PresetLibrary.visualPresets.count) presets")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(model.filteredPresets) { preset in
                    Button {
                        model.applyPreset(preset)
                    } label: {
                        HStack {
                            Circle().fill(preset.colorA).frame(width: 12, height: 12)
                            Text(preset.name)
                            Spacer()
                            Text(preset.family.rawValue).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var sequencerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Play sequencer", isOn: $model.sequencer.isPlaying)
            Picker("Tempo mode", selection: tempoModeBinding) {
                ForEach(TempoMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Stepper("BPM \(String(format: "%.1f", model.sequencer.bpm))", value: bpmBinding, in: 60...220, step: 1)
            Slider(value: bpmBinding, in: 40...240) { Text("Tempo") }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button("Tap") { model.tapTempo() }
                        Button("-0.1") { model.nudgeTempo(-0.1) }
                        Button("+0.1") { model.nudgeTempo(0.1) }
                        Button("-1") { model.nudgeTempo(-1) }
                        Button("+1") { model.nudgeTempo(1) }
                    }
                    HStack {
                        Button("-5") { model.nudgeTempo(-5) }
                        Button("+5") { model.nudgeTempo(5) }
                        Button("Half") { model.halveTempo() }
                        Button("Double") { model.doubleTempo() }
                        Button("Phi") { model.applyGoldenTempoMode() }
                    }
                }
                .controlSize(.small)
                Slider(value: $model.sequencer.swing, in: 0...0.65) { Text("Swing") }
                Text("Swing \(Int(model.sequencer.swing * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Groove", selection: $model.sequencer.groove) {
                    ForEach(GrooveTemplate.allCases) { groove in
                        Text(groove.rawValue).tag(groove)
                    }
                }
                .pickerStyle(.menu)
                Picker("Scale", selection: $model.sequencer.scale) {
                    ForEach(SequencerScale.allCases) { scale in
                        Text(scale.rawValue).tag(scale)
                    }
                }
                .pickerStyle(.menu)
                Picker("Root", selection: $model.sequencer.rootNote) {
                    ForEach(0..<12, id: \.self) { root in
                        Text(pitchClassName(root)).tag(root)
                    }
                }
                .pickerStyle(.menu)
                Picker("Composition", selection: $model.sequencer.compositionStyle) {
                    ForEach(CompositionStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
                Slider(value: $model.sequencer.generativeDensity, in: 0.05...1) { Text("Generator density") }
                Slider(value: $model.sequencer.phraseVariation, in: 0...1) { Text("Phrase variation") }
                Slider(value: $model.sequencer.humanize, in: 0...1) { Text("Humanize") }
                Slider(value: $model.sequencer.mutationAmount, in: 0...1) { Text("Mutation") }
                Stepper("Pattern length \(model.sequencer.patternLength)", value: $model.sequencer.patternLength, in: 4...16)
                HStack {
                    Button("Generate Composition") { model.generateComposition() }
                    Button("Euclidean Drums") { model.generateEuclideanDrums() }
                }
                HStack {
                    Button("Counter Melody") { model.generateCounterMelody() }
                    Button("Capture Keys") { model.captureLiveKeysToLead() }
                }
                HStack {
                    Button("Rotate L") { model.rotatePattern(-1) }
                    Button("Rotate R") { model.rotatePattern(1) }
                    Button("Mirror") { model.mirrorPattern() }
                    Button("Invert") { model.invertMelodies() }
                }
                .controlSize(.small)
                laneEditor(title: "Bass", lane: $model.sequencer.bass)
                laneEditor(title: "Lead", lane: $model.sequencer.lead)
                laneEditor(title: "Kick", lane: $model.sequencer.kick)
                laneEditor(title: "Snare", lane: $model.sequencer.snare)
                laneEditor(title: "Hat", lane: $model.sequencer.hat)
                laneEditor(title: "Clap", lane: $model.sequencer.clap)
                HStack {
                    Button("Randomize") { model.randomizePattern() }
                    Button("Mutate") { model.mutatePattern() }
                    Button("Humanize") { model.humanizePattern() }
                    Button("Clear") { model.clearPattern() }
                }
                HStack {
                    Button("Acid Line") { model.generateAcidLine() }
                    Button("Lead Arp") { model.generateLeadArp() }
                    Button("Ratchet Fill") { model.addRatchetFill() }
                }
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var tempoModeBinding: Binding<TempoMode> {
        Binding(
            get: { model.tempoMode },
            set: { model.applyTempoMode($0) }
        )
    }

    private var bpmBinding: Binding<Double> {
        Binding(
            get: { model.sequencer.bpm },
            set: { model.setManualTempo($0) }
        )
    }

    private var cameraInputBinding: Binding<Bool> {
        Binding(
            get: { model.cameraInputEnabled },
            set: { model.setCameraInputEnabled($0) }
        )
    }

    private var cameraDeviceBinding: Binding<String> {
        Binding(
            get: { model.cameraInput.selectedDeviceID },
            set: { model.selectCameraDevice($0) }
        )
    }

    private var synthPanel: some View {
            VStack(alignment: .leading, spacing: 14) {
                voiceEditor("Analog Bass Line", voice: $model.bassVoice)
                Divider()
                voiceEditor("Space Lead", voice: $model.leadVoice)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var delayFXPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Multitap audio delay", isOn: $model.delaySettings.enabled)
            Slider(value: $model.delaySettings.wet, in: 0...1) { Text("Wet mix") }
            Slider(value: $model.delaySettings.globalFeedback, in: 0...0.92) { Text("Global feedback") }
            Toggle("Multitap visual delay", isOn: $model.delaySettings.visualDelayEnabled)
            Slider(value: $model.delaySettings.visualEchoOpacity, in: 0...1) { Text("Visual echo opacity") }
            HStack {
                Text("\(Int(model.sequencer.bpm)) BPM")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Sync taps") { model.syncDelayToTempoPreset() }
            }

            Divider()

            ForEach($model.delaySettings.taps) { $tap in
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Tap \(String(format: "%.2f", tap.beatOffset)) beat", isOn: $tap.enabled)
                    Slider(value: $tap.beatOffset, in: 0.0625...4) { Text("Beat offset") }
                    Slider(value: $tap.level, in: 0...0.8) { Text("Level") }
                    Slider(value: $tap.feedback, in: 0...0.8) { Text("Feedback") }
                    Slider(value: $tap.visualSpread, in: 0...1) { Text("Visual spread") }
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var drumPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drum Machines").font(.headline)
            ForEach(PresetLibrary.drumPresets) { preset in
                Button(preset.name) { model.applyDrumPreset(preset) }
            }
            laneEditor(title: "Kick", lane: $model.sequencer.kick)
            laneEditor(title: "Snare", lane: $model.sequencer.snare)
            laneEditor(title: "Hat", lane: $model.sequencer.hat)
            laneEditor(title: "Clap", lane: $model.sequencer.clap)
        }
    }

    private var keyboardPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("48-Key Live Synth").font(.headline)
                Spacer()
                Button("All Notes Off") { model.allNotesOff() }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 12), spacing: 4) {
                ForEach(36..<84, id: \.self) { note in
                    Button(noteName(note)) {
                        model.toggleNote(note)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(model.liveNotes.contains(note) ? .pink : keyTint(note))
                    .controlSize(.small)
                }
            }
        }
    }

    private var lightSynthPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $model.lightSynthMode) {
                ForEach(LightSynthMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Visual engine", selection: $model.visualEngineMode) {
                ForEach(VisualEngineMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Stereo", selection: $model.stereoscopicMode) {
                ForEach(StereoscopicMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.stereoDepth, in: 0...1) { Text("Stereo depth") }

            Picker("Palette", selection: $model.paletteMode) {
                ForEach(LightPaletteMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Blend", selection: $model.blendMode) {
                ForEach(LightBlendMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Video mode", selection: $model.experimentalVideoMode) {
                ForEach(ExperimentalVideoMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Picker("Audio visualizer", selection: $model.audioVisualizerMode) {
                ForEach(AudioVisualizerMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.audioVisualizerIntensity, in: 0...1) { Text("Visualizer intensity") }
            Slider(value: $model.audioVisualizerDetail, in: 0...1) { Text("Visualizer detail") }
            Slider(value: $model.audioVisualizerPersistence, in: 0...1) { Text("Visualizer persistence") }
            Slider(value: $model.experimentalVideoIntensity, in: 0...1) { Text("Video intensity") }
            Slider(value: $model.videoKeyThreshold, in: 0...1) { Text("Key threshold") }
            Slider(value: $model.videoEdgeGain, in: 0...1) { Text("Edge gain") }
            Slider(value: $model.videoColorWarp, in: 0...1) { Text("Color warp") }
            Slider(value: $model.videoOscillatorRate, in: 0...1) { Text("Oscillator rate") }
            Picker("Feedback simulator", selection: $model.feedbackSimulatorMode) {
                ForEach(FeedbackSimulatorMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.feedbackSimulatorIntensity, in: 0...1) { Text("Feedback sim intensity") }
            Slider(value: $model.feedbackSimulatorDecay, in: 0...1) { Text("Feedback sim decay") }
            Slider(value: $model.feedbackSimulatorZoom, in: 0...1) { Text("Feedback sim zoom") }
            Slider(value: $model.feedbackSimulatorDisplacement, in: 0...1) { Text("Feedback sim displacement") }
            Slider(value: $model.feedbackSimulatorPrism, in: 0...1) { Text("Feedback sim prism") }

            Toggle("Photon director", isOn: $model.photonDirectorEnabled)
            Toggle("Flash safety", isOn: $model.flashSafety)
            Toggle("Blackout", isOn: $model.blackout)
            Toggle("Freeze frame", isOn: $model.freezeFrame)
            Toggle("Strobe gate", isOn: $model.strobeEnabled)
            Slider(value: $model.strobeRate, in: 1...24) { Text("Strobe rate") }
            Slider(value: $model.lightSynthIntensity, in: 0...1) { Text("Intensity") }
            Slider(value: $model.phosphorPersistence, in: 0...1) { Text("Phosphor persistence") }
            Stepper("Prism splits \(model.prismSplits)", value: $model.prismSplits, in: 1...12)

            VStack(alignment: .leading, spacing: 8) {
                Text("XY Macro Pad").font(.headline)
                GeometryReader { proxy in
                    let x = proxy.size.width * model.macroX
                    let y = proxy.size.height * (1.0 - model.macroY)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.72))
                        ForEach(0..<8, id: \.self) { index in
                            Path { path in
                                let gx = proxy.size.width * Double(index + 1) / 9.0
                                path.move(to: CGPoint(x: gx, y: 0))
                                path.addLine(to: CGPoint(x: gx, y: proxy.size.height))
                            }
                            .stroke(.cyan.opacity(0.16), lineWidth: 1)
                            Path { path in
                                let gy = proxy.size.height * Double(index + 1) / 9.0
                                path.move(to: CGPoint(x: 0, y: gy))
                                path.addLine(to: CGPoint(x: proxy.size.width, y: gy))
                            }
                            .stroke(.pink.opacity(0.12), lineWidth: 1)
                        }
                        Circle()
                            .fill(.radialGradient(colors: [.white, .cyan, .pink.opacity(0.35)], center: .center, startRadius: 2, endRadius: 18))
                            .frame(width: 30, height: 30)
                            .position(x: x, y: y)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                model.photonDirectorEnabled = false
                                model.macroX = min(1, max(0, value.location.x / max(1, proxy.size.width)))
                                model.macroY = min(1, max(0, 1.0 - value.location.y / max(1, proxy.size.height)))
                            }
                    )
                }
                .frame(height: 160)
                Text("X: warp/prism density  Y: feedback/energy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Trip Max") { model.setTripMaximum() }
                Button("Safe Cruise") { model.setSafeCruise() }
            }

            Divider()

            Text("Scene Deck").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
                ForEach(0..<8, id: \.self) { slot in
                    VStack(spacing: 4) {
                        sceneDeckSlotButton(slot, minHeight: 52)
                        HStack(spacing: 4) {
                            Button("Save") {
                                model.saveScene(slot: slot)
                            }
                            Button("Clear") {
                                model.clearScene(slot: slot)
                            }
                            .disabled(model.sceneDeck[slot] == nil)
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private var broadcastPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Source", selection: $model.broadcastSettings.sourceMode) {
                ForEach(BroadcastSourceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Target", selection: Binding(
                get: { model.broadcastSettings.target },
                set: { model.applyBroadcastTarget($0) }
            )) {
                ForEach(BroadcastTarget.allCases) { target in
                    Text(target.rawValue).tag(target)
                }
            }
            .pickerStyle(.menu)

            TextField("RTMP/RTMPS ingest URL", text: $model.broadcastSettings.ingestURL)
                .textFieldStyle(.roundedBorder)
            SecureField("Stream key", text: $model.broadcastSettings.streamKey)
                .textFieldStyle(.roundedBorder)
            if model.broadcastSettings.target == .facebook {
                Toggle("Facebook compatibility mode", isOn: $model.broadcastSettings.facebookCompatibilityMode)
                Button("Facebook Safe Setup") { model.applyFacebookLiveSafeSetup() }
                    .controlSize(.small)
                Text("Use Facebook Live Producer. Paste the RTMPS server URL and stream key, keep this app streaming, then click Go Live in Facebook.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker("Audio", selection: $model.broadcastSettings.audioMode) {
                ForEach(BroadcastAudioMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            if model.broadcastSettings.audioMode == .desktopStereoMix {
                TextField("AVFoundation audio device", text: $model.broadcastSettings.audioDeviceName)
                    .textFieldStyle(.roundedBorder)
                Text("Route system audio to this stereo mix device in Audio MIDI Setup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("List audio devices") { model.listBroadcastAudioDevices() }
                    .controlSize(.small)
            }
            if model.broadcastSettings.sourceMode == .latestRecordingLoop {
                Toggle("Loop latest recording", isOn: $model.broadcastSettings.loopLatestRecording)
            }
            Stepper("Video bitrate \(model.broadcastSettings.bitrateKbps) kbps", value: $model.broadcastSettings.bitrateKbps, in: 1000...20000, step: 500)
            Picker("Frame rate", selection: $model.broadcastSettings.frameRate) {
                Text("24").tag(24)
                Text("30").tag(30)
                Text("60").tag(60)
            }
            .pickerStyle(.menu)

            HStack {
                Button(model.isBroadcasting ? "Broadcasting..." : "Start Broadcast") {
                    model.startBroadcast()
                }
                .disabled(model.isBroadcasting || model.broadcastSettings.streamKey.isEmpty)
                .buttonStyle(.borderedProminent)

                Button("Stop") {
                    model.stopBroadcast()
                }
                .disabled(!model.isBroadcasting)
            }

            if let url = model.latestRecordingURL() {
                Text(model.broadcastSettings.sourceMode == .trueLive ? "Source: live renderer \(model.recordingResolution.rawValue)" : "Source: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(model.broadcastSettings.sourceMode == .trueLive ? "True live mode streams generated frames directly to RTMP." : "Record an MP4 first. Broadcast uses the latest recording as a looping RTMP source.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(model.broadcastCommandPreview())
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(8)
        }
    }

    private var feedbackCameraPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Camera feedback input", isOn: cameraInputBinding)
            Text(model.cameraInput.status)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Picker("Camera source", selection: cameraDeviceBinding) {
                    if model.cameraInput.availableDevices.isEmpty {
                        Text("No cameras found").tag("")
                    } else {
                        ForEach(model.cameraInput.availableDevices) { device in
                            Text(device.displayName).tag(device.id)
                        }
                    }
                }
                .pickerStyle(.menu)

                Button("Refresh") { model.refreshCameraDevices() }
                    .controlSize(.small)
            }

            Picker("Feedback mode", selection: $model.cameraFeedbackMode) {
                ForEach(CameraFeedbackMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Toggle("Mirror camera", isOn: $model.cameraMirror)
            Slider(value: $model.cameraOverlayOpacity, in: 0...1) { Text("Camera opacity") }
            Slider(value: $model.cameraFeedbackAmount, in: 0...1) { Text("Feedback depth") }
            Slider(value: $model.cameraOverlayScale, in: 0.6...1.6) { Text("Feedback scale") }
            Slider(value: $model.cameraFeedbackRotation, in: -1...1) { Text("Feedback rotation") }
            Slider(value: $model.cameraLumaThreshold, in: 0...1) { Text("Luma threshold") }
            Slider(value: $model.cameraChromaShift, in: 0...1) { Text("Chroma shift") }

            Divider()

            Picker("Video mode", selection: $model.experimentalVideoMode) {
                ForEach(ExperimentalVideoMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.experimentalVideoIntensity, in: 0...1) { Text("Video intensity") }
            Slider(value: $model.videoKeyThreshold, in: 0...1) { Text("Processor key threshold") }
            Slider(value: $model.videoEdgeGain, in: 0...1) { Text("Processor edge gain") }
            Slider(value: $model.videoColorWarp, in: 0...1) { Text("Processor color warp") }
            Slider(value: $model.videoOscillatorRate, in: 0...1) { Text("Processor oscillator rate") }

            Divider()

            Text("Procedural Feedback Simulator").font(.headline)
            Picker("Simulator mode", selection: $model.feedbackSimulatorMode) {
                ForEach(FeedbackSimulatorMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Toggle("Audio reactive simulator", isOn: $model.feedbackSimulatorAudioReactive)
            Slider(value: $model.feedbackSimulatorIntensity, in: 0...1) { Text("Simulator intensity") }
            Slider(value: $model.feedbackSimulatorDecay, in: 0...1) { Text("Frame memory / decay") }
            Slider(value: $model.feedbackSimulatorZoom, in: 0...1) { Text("Recursive zoom") }
            Slider(value: $model.feedbackSimulatorTwist, in: 0...1) { Text("Recursive twist") }
            Slider(value: $model.feedbackSimulatorDisplacement, in: 0...1) { Text("Displacement") }
            Slider(value: $model.feedbackSimulatorPrism, in: 0...1) { Text("Prism split") }
        }
    }

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Autopilot scene morphing", isOn: $model.autopilotEnabled)
            Stepper("Autopilot every \(model.autopilotBars) bars", value: $model.autopilotBars, in: 1...32)
            Picker("Scene launch quantize", selection: $model.sceneLaunchQuantization) {
                ForEach(SceneLaunchQuantization.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Text("\(model.savedSceneCount) / 8 deck slots saved")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let queued = model.queuedSceneSlot {
                HStack {
                    Text("Queued Scene \(queued + 1) for \(model.sceneLaunchQuantization.shortLabel)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Cancel") { model.cancelQueuedScene() }
                        .controlSize(.small)
                }
            }

            Divider()

            Text("Scene Morph").font(.headline)
            HStack {
                Picker("From", selection: morphEndpointBinding(0)) {
                    ForEach(0..<8, id: \.self) { slot in
                        Text(model.sceneDeck[slot] == nil ? "\(slot + 1) Empty" : "\(slot + 1) \(model.sceneDeck[slot]?.name ?? "")").tag(slot)
                    }
                }
                Picker("To", selection: morphEndpointBinding(1)) {
                    ForEach(0..<8, id: \.self) { slot in
                        Text(model.sceneDeck[slot] == nil ? "\(slot + 1) Empty" : "\(slot + 1) \(model.sceneDeck[slot]?.name ?? "")").tag(slot)
                    }
                }
            }
            .pickerStyle(.menu)
            Slider(value: sceneMorphBinding, in: 0...1) { Text("Morph") }
                .disabled(!model.canSceneMorph)
            Text("\(Int(model.sceneMorphAmount * 100))%  \(model.sceneDeck[model.sceneMorphFromSlot]?.name ?? "Empty") -> \(model.sceneDeck[model.sceneMorphToSlot]?.name ?? "Empty")")
                .font(.caption)
                .foregroundStyle(model.canSceneMorph ? Color.secondary : Color.orange)
            HStack {
                Button("Save From") { model.saveMorphEndpoint(0) }
                Button("Save To") { model.saveMorphEndpoint(1) }
                Button("Generate Deck") { model.randomizeSceneDeck() }
            }
            .controlSize(.small)

            Divider()

            Picker("Demoscene mode", selection: $model.demosceneEffectMode) {
                ForEach(DemosceneEffectMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.demosceneIntensity, in: 0...1) { Text("Demoscene intensity") }

            Divider()

            Picker("Minter mode", selection: $model.minterEffectMode) {
                ForEach(MinterEffectMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.minterIntensity, in: 0...1) { Text("Minter intensity") }

            Picker("Holographic mode", selection: $model.holographicMode) {
                ForEach(HolographicMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Slider(value: $model.hologramDepth, in: 0...1) { Text("Hologram depth") }

            Divider()

            ForEach($model.modSlots) { $slot in
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Mod slot", isOn: $slot.enabled)
                    Picker("Source", selection: $slot.source) {
                        ForEach(ModSource.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Destination", selection: $slot.destination) {
                        ForEach(ModDestination.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Slider(value: $slot.amount, in: 0...1) { Text("Amount") }
                    Slider(value: $slot.rate, in: 0.05...8) { Text("Rate") }
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var sceneMorphBinding: Binding<Double> {
        Binding(
            get: { model.sceneMorphAmount },
            set: { model.setSceneMorph($0) }
        )
    }

    private func morphEndpointBinding(_ endpoint: Int) -> Binding<Int> {
        Binding(
            get: { endpoint == 0 ? model.sceneMorphFromSlot : model.sceneMorphToSlot },
            set: { model.setSceneMorphEndpoint(endpoint, slot: $0) }
        )
    }

    private var outputPanel: some View {
            VStack(alignment: .leading, spacing: 12) {
                Slider(value: $model.masterLevel, in: 0...1) { Text("Master level") }
                Slider(value: $model.masterDrive, in: 0...1) { Text("Master drive") }
                Slider(value: $model.stereoWidth, in: 0...1) { Text("Stereo width") }
                Slider(value: $model.limiterCeiling, in: 0.3...0.98) { Text("Limiter ceiling") }
                Slider(value: $model.limiterRelease, in: 0...1) { Text("Limiter release") }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio meter").font(.headline)
                    meterRow("L", value: model.audioMeter.peakLeft)
                    meterRow("R", value: model.audioMeter.peakRight)
                    meterRow("GR", value: model.audioMeter.limiterReduction)
                    meterRow("Bass", value: model.audioMeter.bass)
                    meterRow("Mid", value: model.audioMeter.mid)
                    meterRow("High", value: model.audioMeter.treble)
                    meterRow("Flux", value: model.audioMeter.spectralFlux)
                    Text("Limiter hits \(model.audioMeter.limitedFrames)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(model.audioMeter.limitedFrames > 0 ? .orange : .secondary)
                }
                Slider(value: $model.bloom, in: 0...1) { Text("Bloom") }
                Slider(value: $model.exposure, in: 0.1...1.2) { Text("Exposure") }
                Slider(value: $model.visualOutputGain, in: 0.3...1.0) { Text("Visual gain") }
                Slider(value: $model.visualSoftClip, in: 0.45...0.98) { Text("Visual soft clip") }

                HStack {
                    Button("Safe Output") { model.applyProductionSafeOutput() }
                    Button("Wide Stage") { model.applyWideStageMix() }
                }
                .controlSize(.small)

                Divider()

                Stepper("Record \(Int(model.recordingDuration)) sec", value: $model.recordingDuration, in: 3...60, step: 1)
                Picker("Resolution", selection: $model.recordingResolution) {
                    ForEach(RecordingResolution.allCases) { resolution in
                        Text(resolution.rawValue).tag(resolution)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Button("4K Master") { model.apply4KMasterOutput() }
                    Button("Vertical 4K") { model.applyVertical4KMasterOutput() }
                }
                .controlSize(.small)

                let recordingSize = model.recordingResolution.size
                Text("Capture: \(recordingSize.width) x \(recordingSize.height) at \(model.recordingFPS) fps")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                TextField("Search performance presets", text: $model.performancePresetFilter)
                    .textFieldStyle(.roundedBorder)
                Text("\(model.filteredVideoPerformancePresets.count) of \(PresetLibrary.videoPerformancePresets.count) presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), spacing: 6) {
                    ForEach(model.filteredVideoPerformancePresets) { preset in
                        Button(preset.name) { model.applyVideoPerformancePreset(preset) }
                            .controlSize(.small)
                    }
                }

                Picker("Frame rate", selection: $model.recordingFPS) {
                    Text("24 fps").tag(24)
                    Text("30 fps").tag(30)
                    Text("60 fps").tag(60)
                }
                .pickerStyle(.menu)

                Button(model.isRecording ? "Rendering MP4..." : "Record MP4") {
                    model.recordMP4()
                }
                .disabled(model.isRecording)
                .buttonStyle(.borderedProminent)

                if let url = model.lastRecordingURL {
                    Text(url.path)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
    }

    private func meterRow(_ label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.monospaced())
                .frame(width: 42, alignment: .leading)
            ProgressView(value: min(1.0, max(0.0, value)), total: 1.0)
                .progressViewStyle(.linear)
            Text("\(Int(min(1.0, max(0.0, value)) * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)
        }
    }

    private func mixerChannelEditor(_ title: String, channel: Binding<MixerChannel>, accent: Color, showSend: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Toggle("M", isOn: channel.muted)
                    .toggleStyle(.button)
                    .tint(.red)
                    .controlSize(.mini)
                Toggle("S", isOn: channel.solo)
                    .toggleStyle(.button)
                    .tint(.yellow)
                    .controlSize(.mini)
            }
            Slider(value: channel.level, in: 0...1.2) { Text("Level") }
                .tint(accent)
            HStack {
                Text("Pan")
                    .font(.caption)
                    .frame(width: 34, alignment: .leading)
                Slider(value: channel.pan, in: -1...1)
                Text(String(format: "%+.2f", channel.wrappedValue.pan))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
            if showSend {
                HStack {
                    Text("Send")
                        .font(.caption)
                        .frame(width: 34, alignment: .leading)
                    Slider(value: channel.send, in: 0...1)
                    Text("\(Int(channel.wrappedValue.send * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func laneEditor(title: String, lane: Binding<StepLane>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { index in
                    Button(lane.wrappedValue.steps[index] ? "●" : "○") {
                        lane.wrappedValue.steps[index].toggle()
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .frame(width: 20, height: 24)
                    .opacity(index < model.sequencer.patternLength ? 1 : 0.28)
                    .buttonStyle(.bordered)
                }
            }
            Stepper("Length \(lane.wrappedValue.length)", value: lane.length, in: 1...16)
                .controlSize(.small)
            HStack {
                Text("Chance")
                    .font(.caption)
                    .frame(width: 48, alignment: .leading)
                Slider(value: laneProbabilityBinding(lane), in: 0...1)
                Text("\(Int(average(lane.wrappedValue.probabilities) * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 38, alignment: .trailing)
            }
            HStack {
                Text("Velocity")
                    .font(.caption)
                    .frame(width: 48, alignment: .leading)
                Slider(value: laneVelocityBinding(lane), in: 0.05...1)
                Text("\(Int(average(lane.wrappedValue.velocities) * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 38, alignment: .trailing)
            }
            Stepper("Ratchet all x\(laneRatchetBinding(lane).wrappedValue)", value: laneRatchetBinding(lane), in: 1...8)
                .controlSize(.small)
        }
    }

    private func laneProbabilityBinding(_ lane: Binding<StepLane>) -> Binding<Double> {
        Binding(
            get: { average(lane.wrappedValue.probabilities) },
            set: { value in
                lane.wrappedValue.probabilities = Array(repeating: value, count: lane.wrappedValue.steps.count)
            }
        )
    }

    private func laneVelocityBinding(_ lane: Binding<StepLane>) -> Binding<Double> {
        Binding(
            get: { average(lane.wrappedValue.velocities) },
            set: { value in
                lane.wrappedValue.velocities = Array(repeating: value, count: lane.wrappedValue.steps.count)
            }
        )
    }

    private func laneRatchetBinding(_ lane: Binding<StepLane>) -> Binding<Int> {
        Binding(
            get: { max(1, lane.wrappedValue.ratchets.max() ?? 1) },
            set: { value in
                lane.wrappedValue.ratchets = Array(repeating: value, count: lane.wrappedValue.steps.count)
            }
        )
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func voiceEditor(_ title: String, voice: Binding<SynthVoice>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: voice.enabled)
                .font(.headline)
            Picker("Instrument", selection: voice.instrument) {
                ForEach(SynthInstrument.allCases) { instrument in
                    Text(instrument.rawValue).tag(instrument)
                }
            }
            .pickerStyle(.menu)
            HStack {
                Menu("Preset") {
                    ForEach(PresetLibrary.synthVoicePresets) { preset in
                        Button(preset.name) {
                            voice.wrappedValue = preset.voice
                        }
                    }
                }
                Button("Randomize Voice") {
                    voice.wrappedValue = PresetLibrary.randomizedSynthVoice(seed: Int(Date().timeIntervalSinceReferenceDate * 1_000))
                }
            }
            .controlSize(.small)
            Slider(value: voice.level, in: 0...1) { Text("Level") }
            Stepper("Octave " + String(voice.wrappedValue.octave), value: voice.octave, in: 0...5)
            Slider(value: voice.cutoff, in: 0...1) { Text("Cutoff") }
            Slider(value: voice.resonance, in: 0...1) { Text("Resonance") }
            Slider(value: voice.glide, in: 0...1) { Text("Glide") }
            Slider(value: voice.accent, in: 0...1) { Text("Accent") }
            Slider(value: voice.attack, in: 0...1) { Text("Attack") }
            Slider(value: voice.decay, in: 0...1) { Text("Decay") }
            Slider(value: voice.sustain, in: 0...1) { Text("Sustain") }
            Slider(value: voice.drive, in: 0...1) { Text("Drive") }
            Slider(value: voice.filterEnvelope, in: 0...1) { Text("Filter envelope") }
            Slider(value: voice.lfoRate, in: 0...1) { Text("LFO rate") }
            Slider(value: voice.lfoAmount, in: 0...1) { Text("LFO amount") }
            Slider(value: voice.morph, in: 0...1) { Text("Morph") }
            Slider(value: voice.unison, in: 0...1) { Text("Unison") }
            Slider(value: voice.detune, in: 0...1) { Text("Detune") }
            Slider(value: voice.subLevel, in: 0...1) { Text("Sub") }
            Slider(value: voice.noiseLevel, in: 0...1) { Text("Noise") }
            Slider(value: voice.fmAmount, in: 0...1) { Text("FM / Ring") }
            Slider(value: voice.wavefold, in: 0...1) { Text("Wavefold") }
            Slider(value: voice.grainSize, in: 0...1) { Text("Grain size") }
            Slider(value: voice.grainDensity, in: 0...1) { Text("Grain density") }
            Slider(value: voice.bitcrush, in: 0...1) { Text("Bitcrush") }
        }
    }

    private func pitchClassName(_ pitchClass: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return names[((pitchClass % 12) + 12) % 12]
    }

    private func noteName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return "\(names[midi % 12])\(midi / 12 - 1)"
    }

    private func keyTint(_ midi: Int) -> Color {
        [1, 3, 6, 8, 10].contains(midi % 12) ? .purple : .blue
    }
}

private struct InspectorScrollView<Content: View>: NSViewRepresentable {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = hostingView
        context.coordinator.hostingView = hostingView

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            hostingView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?
    }
}
