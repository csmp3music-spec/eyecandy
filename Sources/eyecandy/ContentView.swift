import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalView(renderer: model.renderer, qualityScale: model.qualityScale)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.black.opacity(0.14),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 20) {
                header
                Spacer()
                footer
            }
            .padding(24)

            if model.showInspector {
                HStack {
                    Spacer()
                    inspector
                        .frame(width: 360)
                        .padding(24)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .background(Color.black)
        .task {
            model.start()
        }
        .onDisappear {
            model.stop()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("eyecandy")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)

            VStack(alignment: .leading, spacing: 6) {
                Text(model.selectedPreset.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text(model.selectedPreset.family.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))

                Text(model.selectedPreset.summary)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                StatusCapsule(text: model.isRecording ? "REC" : "LIVE", accent: model.isRecording ? Color.red : Color.cyan)
                StatusCapsule(text: model.presetIsModified ? "TWEAKED" : "PRESET", accent: model.presetIsModified ? Color.orange : Color.white.opacity(0.82))
                StatusCapsule(text: "\(Int(model.captureProfile.size.width))x\(Int(model.captureProfile.size.height))", accent: Color.pink.opacity(0.82))
                StatusCapsule(text: model.audio.reactive ? "SYNC" : "FREE", accent: model.audio.reactive ? Color.green : Color.white.opacity(0.82))
                StatusCapsule(text: model.liveOutputEnabled ? "PROJECTOR" : "LOCAL", accent: model.liveOutputEnabled ? Color.yellow : Color.white.opacity(0.82))
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.statusMessage)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.78))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())

            HStack(spacing: 10) {
                HUDButton(title: "Prev", accent: .white.opacity(0.82)) {
                    model.stepPreset(by: -1)
                }
                HUDButton(title: "Next", accent: .white.opacity(0.82)) {
                    model.stepPreset(by: 1)
                }
                HUDButton(title: "Random", accent: .orange) {
                    model.randomizeExploration()
                }
                HUDButton(title: model.audio.muted ? "Unmute" : "Mute", accent: model.audio.muted ? .red : .mint) {
                    model.toggleMute()
                }
                HUDButton(title: model.isRecording ? "Stop MP4" : "Record MP4", accent: model.isRecording ? .red : .pink) {
                    model.startOrStopRecording()
                }
                HUDButton(title: model.liveOutputEnabled ? "Close Live" : "Live Output", accent: .yellow) {
                    model.toggleLiveOutput()
                }
                HUDButton(title: "Fullscreen", accent: .purple) {
                    model.toggleFullscreen()
                }
                HUDButton(title: model.showInspector ? "Hide Controls" : "Show Controls", accent: .cyan) {
                    model.toggleInspector()
                }
            }
        }
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Inspector", selection: $model.activeTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch model.activeTab {
                case .presets:
                    presetsPanel
                case .feedback:
                    sliderPanel(sections: ControlSchema.feedbackSections)
                case .geometry:
                    sliderPanel(sections: ControlSchema.geometrySections)
                case .color:
                    colorPanel
                case .texture:
                    sliderPanel(sections: ControlSchema.textureSections)
                case .audio:
                    audioPanel
                case .capture:
                    capturePanel
                case .live:
                    livePanel
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 26, x: 0, y: 16)
    }

    private var presetsPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Search presets", text: $model.searchText)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FamilyChip(
                            title: "All",
                            isActive: model.familyFilter == nil,
                            action: { model.familyFilter = nil }
                        )

                        ForEach(PresetFamily.allCases) { family in
                            FamilyChip(
                                title: family.rawValue,
                                isActive: model.familyFilter == family,
                                action: { model.familyFilter = family }
                            )
                        }
                    }
                }

                ForEach(model.filteredPresets) { preset in
                    Button {
                        model.apply(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(preset.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                Spacer()
                                Text(preset.family.rawValue)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.62))
                            }

                            Text(preset.summary)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.72))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(preset.id == model.selectedPreset.id ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sliderPanel(sections: [ControlSection]) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(sections) { section in
                    SectionCard(title: section.title) {
                        VStack(spacing: 10) {
                            ForEach(section.descriptors) { descriptor in
                                SliderRow(
                                    title: descriptor.title,
                                    value: model.binding(for: descriptor),
                                    range: descriptor.range,
                                    step: descriptor.step,
                                    format: descriptor.format
                                )
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    ActionButton(title: "Reset Preset", accent: .white.opacity(0.86)) {
                        model.resetCurrentPreset()
                    }
                    ActionButton(title: "Experimental Tweak", accent: .orange) {
                        model.randomizeExploration()
                    }
                }
            }
        }
    }

    private var audioPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SectionCard(title: "Audio Engine") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: Binding(get: { !model.audio.muted }, set: { model.audio.muted = !$0 })) {
                            Text("Procedural soundtrack active")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .toggleStyle(.switch)

                        Toggle(isOn: Binding(get: { model.audio.reactive }, set: { model.audio.reactive = $0 })) {
                            Text("Visuals react to the soundtrack")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .toggleStyle(.switch)

                        SliderRow(title: "Master Volume", value: model.binding(for: \.masterVolume, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Reactivity", value: model.binding(for: \.reactivity, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Tempo", value: model.binding(for: \.tempo, in: 70.0 ... 180.0), range: 70.0 ... 180.0, step: 1.0, format: "%.0f")
                        SliderRow(title: "Drone Mix", value: model.binding(for: \.droneMix, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Pulse Mix", value: model.binding(for: \.pulseMix, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Percussion", value: model.binding(for: \.percussionMix, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Shimmer", value: model.binding(for: \.shimmer, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                        SliderRow(title: "Stereo Width", value: model.binding(for: \.stereoWidth, in: 0.0 ... 1.0), range: 0.0 ... 1.0, step: 0.01, format: "%.2f")
                    }
                }
            }
        }
    }

    private var colorPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SectionCard(title: "Color Space") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Color Space", selection: colorSpaceBinding) {
                            ForEach(ColorSpaceMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Minter Synesthesia pushes high-contrast rainbow cycling and harsher arcade luminance.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }

                ForEach(ControlSchema.colorSections) { section in
                    SectionCard(title: section.title) {
                        VStack(spacing: 10) {
                            ForEach(section.descriptors) { descriptor in
                                SliderRow(
                                    title: descriptor.title,
                                    value: model.binding(for: descriptor),
                                    range: descriptor.range,
                                    step: descriptor.step,
                                    format: descriptor.format
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var capturePanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SectionCard(title: "Preview Quality") {
                    VStack(spacing: 10) {
                        SliderRow(title: "Render Scale", value: Binding(
                            get: { Double(model.qualityScale) },
                            set: { model.qualityScale = Float($0) }
                        ), range: 0.75 ... 2.0, step: 0.01, format: "%.2f")

                        Text("Higher scale raises the real internal render resolution for sharper feedback and denser detail.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }

                SectionCard(title: "MP4 Capture") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Resolution", selection: $model.captureProfile) {
                            ForEach(CaptureProfile.allCases) { profile in
                                Text(profile.rawValue).tag(profile)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Frame Rate", selection: $model.exportFPS) {
                            Text("24").tag(24)
                            Text("30").tag(30)
                            Text("60").tag(60)
                        }
                        .pickerStyle(.segmented)

                        ActionButton(title: model.isRecording ? "Stop Recording" : "Start Recording", accent: model.isRecording ? .red : .pink) {
                            model.startOrStopRecording()
                        }

                        if let lastExportURL = model.lastExportURL {
                            Text(lastExportURL.path)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    private var livePanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SectionCard(title: "Performance Output") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route a clean full-screen render to a projector or second monitor while keeping controls on the main display.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))

                        ActionButton(title: model.liveOutputEnabled ? "Close Live Output" : "Open Live Output", accent: .yellow) {
                            model.toggleLiveOutput()
                        }

                        ActionButton(title: "Toggle Fullscreen", accent: .purple) {
                            model.toggleFullscreen()
                        }
                    }
                }

                SectionCard(title: "Playback") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The live output uses the same preset, tone generator, and audio-reactive state as the main renderer.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))

                        Text("Current mode: \(model.audio.reactive ? "reactive synchronicity" : "free-running feedback")")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
    }

    private var colorSpaceBinding: Binding<ColorSpaceMode> {
        Binding(
            get: { ColorSpaceMode(rawValue: Int(model.settings.colorSpace.rounded())) ?? .spectral },
            set: { mode in
                var updated = model.settings
                updated.colorSpace = mode.shaderIndex
                model.settings = updated
            }
        )
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))

            content
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SliderRow: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Float>
    let step: Float
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Slider(value: value, in: Double(range.lowerBound) ... Double(range.upperBound), step: Double(step))
                .tint(Color.white.opacity(0.88))
        }
    }
}

private struct HUDButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .foregroundStyle(Color.white)
                .background(accent.opacity(0.22), in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(accent.opacity(0.85), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Color.white)
                .background(accent.opacity(0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(accent.opacity(0.82), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct StatusCapsule: View {
    let text: String
    let accent: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.22), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(accent.opacity(0.85), lineWidth: 1)
            )
    }
}

private struct FamilyChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
