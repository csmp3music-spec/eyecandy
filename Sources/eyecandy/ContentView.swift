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

                ScrollView(.vertical) {
                    inspectorPanelContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.visible)
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
        .onChange(of: model.masterLevel) { _ in model.pushAudioState() }
        .onAppear { model.startAudio() }
    }

    @ViewBuilder
    private var inspectorPanelContent: some View {
        switch model.selectedPanel {
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
            Text("sonic screwdriver eyecandy")
                .font(.title2.bold())
            Text(model.status)
                .foregroundStyle(.secondary)
                .font(.caption)
            HStack {
                Button("Start Audio") { model.startAudio() }
                Button("Stop") { model.stopAudio() }
                Button("Random Visual") { model.randomizeVisual() }
                Button("Regenerate") { model.regenerateVisualScene() }
            }
        }
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
                    Menu("Camera Feedback") {
                        optionButtons(CameraFeedbackMode.allCases, selection: $model.cameraFeedbackMode)
                    }
                    Toggle("Camera Input", isOn: cameraInputBinding)
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

    private var presetPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Family", selection: $model.selectedFamily) {
                ForEach(PresetFamily.allCases) { family in
                    Text(family.rawValue).tag(family)
                }
            }
            .pickerStyle(.menu)

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
                Slider(value: $model.sequencer.humanize, in: 0...1) { Text("Humanize") }
                Slider(value: $model.sequencer.mutationAmount, in: 0...1) { Text("Mutation") }
                Stepper("Pattern length \(model.sequencer.patternLength)", value: $model.sequencer.patternLength, in: 4...16)
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
            Slider(value: $model.experimentalVideoIntensity, in: 0...1) { Text("Video intensity") }
            Slider(value: $model.videoKeyThreshold, in: 0...1) { Text("Key threshold") }
            Slider(value: $model.videoEdgeGain, in: 0...1) { Text("Edge gain") }
            Slider(value: $model.videoColorWarp, in: 0...1) { Text("Color warp") }
            Slider(value: $model.videoOscillatorRate, in: 0...1) { Text("Oscillator rate") }

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
                        Button(model.sceneDeck[slot] == nil ? "Empty \(slot + 1)" : "Recall \(slot + 1)") {
                            model.recallScene(slot: slot)
                        }
                        .disabled(model.sceneDeck[slot] == nil)
                        .controlSize(.small)
                        Button("Save \(slot + 1)") {
                            model.saveScene(slot: slot)
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
        }
    }

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Autopilot scene morphing", isOn: $model.autopilotEnabled)
            Stepper("Autopilot every \(model.autopilotBars) bars", value: $model.autopilotBars, in: 1...32)

            Divider()

            Text("Scene Morph").font(.headline)
            HStack {
                Picker("From", selection: $model.sceneMorphFromSlot) {
                    ForEach(0..<8, id: \.self) { slot in
                        Text("\(slot + 1)").tag(slot)
                    }
                }
                Picker("To", selection: $model.sceneMorphToSlot) {
                    ForEach(0..<8, id: \.self) { slot in
                        Text("\(slot + 1)").tag(slot)
                    }
                }
            }
            .pickerStyle(.menu)
            Slider(value: sceneMorphBinding, in: 0...1) { Text("Morph") }
            Text("\(Int(model.sceneMorphAmount * 100))%  \(model.sceneDeck[model.sceneMorphFromSlot]?.name ?? "Empty") -> \(model.sceneDeck[model.sceneMorphToSlot]?.name ?? "Empty")")
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private var outputPanel: some View {
            VStack(alignment: .leading, spacing: 12) {
                Slider(value: $model.masterLevel, in: 0...1) { Text("Master level") }
                Slider(value: $model.bloom, in: 0...1) { Text("Bloom") }
                Slider(value: $model.exposure, in: 0.1...1.4) { Text("Exposure") }

                Divider()

                Stepper("Record \(Int(model.recordingDuration)) sec", value: $model.recordingDuration, in: 3...60, step: 1)
                Picker("Resolution", selection: $model.recordingResolution) {
                    ForEach(RecordingResolution.allCases) { resolution in
                        Text(resolution.rawValue).tag(resolution)
                    }
                }
                .pickerStyle(.menu)

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

    private func noteName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return "\(names[midi % 12])\(midi / 12 - 1)"
    }

    private func keyTint(_ midi: Int) -> Color {
        [1, 3, 6, 8, 10].contains(midi % 12) ? .purple : .blue
    }
}
