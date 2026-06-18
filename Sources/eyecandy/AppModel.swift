import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPanel: InspectorPanel = .studio
    @Published var selectedFamily: PresetFamily = .all
    @Published var selectedPreset: VisualPreset = PresetLibrary.visualPresets[0]
    @Published var visualPresetFilter = ""
    @Published var tempoMode: TempoMode = .manual
    @Published var sequencer = SequencerState()
    @Published var bassVoice = SynthVoice()
    @Published var leadVoice = SynthVoice(instrument: .syncLead, level: 0.32, octave: 4, cutoff: 0.68, resonance: 0.18, glide: 0.08, accent: 0.45)
    @Published var delaySettings = MultiTapDelaySettings()
    @Published var mixer = AudioMixerState()
    @Published var modSlots = [ModSlot(enabled: true, source: .beat, destination: .zoom, amount: 0.24, rate: 1.0), ModSlot(), ModSlot()]
    @Published var liveNotes: Set<Int> = []
    @Published var autopilotEnabled = false
    @Published var autopilotBars = 8
    @Published var holographicMode: HolographicMode = .ghostPrism
    @Published var hologramDepth = 0.42
    @Published var minterEffectMode: MinterEffectMode = .neonStampede
    @Published var minterIntensity = 0.48
    @Published var demosceneEffectMode: DemosceneEffectMode = .megaDemo
    @Published var demosceneIntensity = 0.62
    @Published var lightSynthMode: LightSynthMode = .everything
    @Published var lightSynthIntensity = 0.68
    @Published var audioVisualizerMode: AudioVisualizerMode = .hyperAnalyzer
    @Published var audioVisualizerIntensity = 0.72
    @Published var audioVisualizerDetail = 0.66
    @Published var audioVisualizerPersistence = 0.48
    @Published var macroX = 0.58
    @Published var macroY = 0.64
    @Published var photonDirectorEnabled = true
    @Published var phosphorPersistence = 0.55
    @Published var prismSplits = 5
    @Published var flashSafety = true
    @Published var paletteMode: LightPaletteMode = .neon
    @Published var blendMode: LightBlendMode = .additive
    @Published var visualEngineMode: VisualEngineMode = .engineAutopilot
    @Published var experimentalVideoMode: ExperimentalVideoMode = .clean
    @Published var experimentalVideoIntensity = 0.55
    @Published var videoKeyThreshold = 0.52
    @Published var videoEdgeGain = 0.46
    @Published var videoColorWarp = 0.58
    @Published var videoOscillatorRate = 0.50
    @Published var cameraInputEnabled = false
    @Published var cameraFeedbackMode: CameraFeedbackMode = .optical
    @Published var cameraOverlayOpacity = 0.38
    @Published var cameraFeedbackAmount = 0.46
    @Published var cameraOverlayScale = 1.0
    @Published var cameraFeedbackRotation = 0.0
    @Published var cameraLumaThreshold = 0.22
    @Published var cameraChromaShift = 0.18
    @Published var cameraMirror = true
    @Published var stereoscopicMode: StereoscopicMode = .off
    @Published var stereoDepth = 0.38
    @Published var blackout = false
    @Published var freezeFrame = false
    @Published var strobeEnabled = false
    @Published var strobeRate = 8.0
    @Published var sceneDeck: [LightSceneSnapshot?] = Array(repeating: nil, count: 8)
    @Published var sceneLaunchQuantization: SceneLaunchQuantization = .nextBar
    @Published var queuedSceneSlot: Int?
    @Published var sceneMorphFromSlot = 0
    @Published var sceneMorphToSlot = 1
    @Published var sceneMorphAmount = 0.0
    @Published var masterLevel = 0.55
    @Published var masterDrive = 0.18
    @Published var stereoWidth = 0.62
    @Published var limiterCeiling = 0.92
    @Published var limiterRelease = 0.38
    @Published var audioMeter = AudioMeterSnapshot()
    @Published var bloom = 0.36
    @Published var exposure = 0.58
    @Published var visualOutputGain = 0.80
    @Published var visualSoftClip = 0.74
    @Published var recordingDuration = 12.0
    @Published var recordingFPS = 30
    @Published var recordingResolution: RecordingResolution = .hd720
    @Published var performancePresetFilter = ""
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var broadcastSettings = BroadcastSettings()
    @Published var isBroadcasting = false
    @Published var sceneSeed = 1
    @Published var sceneCutTime = Date().timeIntervalSinceReferenceDate
    @Published var status = "Ready"

    private let audioEngine = ProceduralAudioEngine()
    private let broadcastController = BroadcastController()
    private let liveBroadcastController = LiveBroadcastController()
    let cameraInput = CameraInputController()
    private let goldenRatio = 1.618_033_988_749_895
    private let goldenTempoBPM = 161.8
    private var autopilotIndex = 0
    private var lastAutopilotBeat = -1
    private var lastQueuedSceneBeat = -1
    private var tapTempoTimes: [TimeInterval] = []
    private var audioMeterTimer: Timer?

    var filteredPresets: [VisualPreset] {
        let familyFiltered = selectedFamily == .all
            ? PresetLibrary.visualPresets
            : PresetLibrary.visualPresets.filter { $0.family == selectedFamily }
        let query = visualPresetFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return familyFiltered }
        return familyFiltered.filter { preset in
            preset.name.localizedCaseInsensitiveContains(query)
                || preset.family.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    var beatPhase: Double {
        let seconds = Date().timeIntervalSinceReferenceDate
        return (seconds * sequencer.bpm / 60.0).truncatingRemainder(dividingBy: 1)
    }

    var filteredVideoPerformancePresets: [VideoPerformancePreset] {
        let query = performancePresetFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return PresetLibrary.videoPerformancePresets }
        return PresetLibrary.videoPerformancePresets.filter { preset in
            preset.name.localizedCaseInsensitiveContains(query)
                || preset.visualEngine.rawValue.localizedCaseInsensitiveContains(query)
                || preset.demosceneMode.rawValue.localizedCaseInsensitiveContains(query)
                || preset.minterMode.rawValue.localizedCaseInsensitiveContains(query)
                || preset.palette.rawValue.localizedCaseInsensitiveContains(query)
                || preset.videoMode.rawValue.localizedCaseInsensitiveContains(query)
                || preset.resolution.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    func startAudio() {
        do {
            pushAudioState()
            try audioEngine.start()
            startAudioMetering()
            status = "Audio engine running"
        } catch {
            status = "Audio failed: \(error.localizedDescription)"
        }
    }

    func stopAudio() {
        audioEngine.stop()
        audioMeterTimer?.invalidate()
        audioMeterTimer = nil
        status = "Audio stopped"
    }

    func refreshAudioMeter() {
        audioMeter = audioEngine.meterSnapshot()
    }

    func toggleNote(_ midiNote: Int) {
        if liveNotes.contains(midiNote) {
            liveNotes.remove(midiNote)
        } else {
            liveNotes.insert(midiNote)
        }
        pushAudioState()
    }

    func allNotesOff() {
        liveNotes.removeAll()
        pushAudioState()
    }

    func applyPreset(_ preset: VisualPreset) {
        selectedPreset = preset
        selectedFamily = preset.family
        regenerateVisualScene(for: preset)
    }

    func applyDrumPreset(_ preset: DrumPreset) {
        sequencer.kick.steps = preset.kick
        sequencer.snare.steps = preset.snare
        sequencer.hat.steps = preset.hat
        sequencer.clap.steps = preset.clap
        normalizeSequencerLanes()
        pushAudioState()
    }

    func applyVideoPerformancePreset(_ preset: VideoPerformancePreset) {
        visualEngineMode = preset.visualEngine
        demosceneEffectMode = preset.demosceneMode
        minterEffectMode = preset.minterMode
        paletteMode = preset.palette
        experimentalVideoMode = preset.videoMode
        recordingResolution = preset.resolution
        recordingFPS = preset.frameRate
        lightSynthIntensity = preset.intensity
        demosceneIntensity = min(1.0, preset.intensity + 0.04)
        minterIntensity = min(1.0, preset.intensity + 0.06)
        experimentalVideoIntensity = preset.intensity
        videoKeyThreshold = max(0.18, min(0.82, 1.0 - preset.intensity * 0.58))
        videoEdgeGain = min(1.0, preset.intensity + 0.10)
        videoColorWarp = min(1.0, preset.intensity + 0.04)
        videoOscillatorRate = min(1.0, 0.22 + preset.intensity * 0.74)
        macroX = Double((preset.name.count * 37) % 100) / 100.0
        macroY = Double((preset.name.count * 71 + preset.frameRate) % 100) / 100.0
        prismSplits = 2 + ((preset.name.count + preset.frameRate) % 10)
        bloom = min(0.72, 0.22 + preset.intensity * 0.26)
        exposure = min(0.95, 0.48 + preset.intensity * 0.30)
        visualOutputGain = min(0.92, 0.66 + preset.intensity * 0.18)
        visualSoftClip = max(0.62, 0.82 - preset.intensity * 0.12)
        holographicMode = preset.videoMode == .clean ? .off : HolographicMode.allCases[(preset.name.count + preset.frameRate) % HolographicMode.allCases.count]
        cameraFeedbackMode = feedbackMode(for: preset.videoMode)
        cameraOverlayOpacity = min(0.72, 0.18 + preset.intensity * 0.42)
        cameraFeedbackAmount = min(1.0, 0.24 + preset.intensity * 0.66)
        cameraOverlayScale = 0.86 + Double((preset.name.count * 5) % 34) / 100.0
        cameraFeedbackRotation = Double(((preset.name.count * 7) % 140) - 70) / 100.0
        cameraLumaThreshold = max(0.08, min(0.82, 1.0 - preset.intensity))
        cameraChromaShift = Double((preset.name.count * 11) % 100) / 100.0
        photonDirectorEnabled = false
        status = "Loaded \(preset.name)"
    }

    private func feedbackMode(for videoMode: ExperimentalVideoMode) -> CameraFeedbackMode {
        switch videoMode {
        case .videoFeedback, .demosceneStack, .kaleidoFeedback:
            return .echoTunnel
        case .slitScan, .scanGate, .tunnelFold:
            return .slitEcho
        case .lumaKeyBloom, .solarizedContours:
            return .lumaKey
        case .chromaInvert, .colourspace, .vectorScope, .rgbDelay, .halftonePosterize, .liquidLens, .chromaLightLeaks:
            return .chromaWash
        case .clean, .neonPulse, .chromaticAberration, .datamoshBlocks, .vhsMelt, .edgeTrace, .oscillatorBank, .pixelSortTrails, .codecTear, .opticalFlowSmear, .recursiveMirror, .phosphorBurn:
            return .optical
        }
    }

    func randomizeVisual() {
        if let preset = PresetLibrary.visualPresets.randomElement() {
            applyPreset(preset)
        }
    }

    func regenerateVisualScene(for preset: VisualPreset? = nil) {
        let activePreset = preset ?? selectedPreset
        let seed = Int.random(in: 1...999_999)
        sceneSeed = seed
        sceneCutTime = Date().timeIntervalSinceReferenceDate

        let profile = PresetLibrary.proceduralProfile(for: activePreset, seed: seed)
        visualEngineMode = profile.visualEngine
        minterEffectMode = profile.minterMode
        lightSynthMode = profile.lightMode
        paletteMode = profile.palette
        blendMode = profile.blend
        demosceneEffectMode = profile.demosceneMode
        holographicMode = profile.holographicMode
        lightSynthIntensity = profile.intensity
        minterIntensity = activePreset.family == .minter ? profile.intensity : profile.intensity * 0.25
        prismSplits = profile.prismSplits
        macroX = Double((seed * 37) % 100) / 100.0
        macroY = Double((seed * 71) % 100) / 100.0
        photonDirectorEnabled = false
        status = "Generated \(visualEngineMode.rawValue)"
    }

    func randomizePattern() {
        sequencer.bass.steps = sequencer.bass.steps.indices.map { _ in Bool.random() }
        sequencer.lead.steps = sequencer.lead.steps.indices.map { _ in Bool.random() }
        sequencer.hat.steps = sequencer.hat.steps.indices.map { index in index % 2 == 0 || Bool.random() }
        sequencer.bass.notes = sequencer.bass.notes.indices.map { index in scaleOffset(degree: index * 2 + Int.random(in: 0...4), octave: index % 3) }
        sequencer.lead.notes = sequencer.lead.notes.indices.map { index in scaleOffset(degree: index * 3 + Int.random(in: 0...5), octave: 1 + index % 2) }
        sequencer.bass.velocities = sequencer.bass.velocities.map { _ in Double.random(in: 0.55...1.0) }
        sequencer.lead.velocities = sequencer.lead.velocities.map { _ in Double.random(in: 0.45...0.95) }
        sequencer.hat.probabilities = sequencer.hat.probabilities.map { _ in Double.random(in: 0.62...1.0) }
        sequencer.hat.ratchets = sequencer.hat.ratchets.indices.map { index in index % 4 == 2 ? [1, 2, 3, 4].randomElement()! : 1 }
        normalizeSequencerLanes()
        pushAudioState()
    }

    func clearPattern() {
        sequencer.bass.steps = Array(repeating: false, count: 16)
        sequencer.lead.steps = Array(repeating: false, count: 16)
        sequencer.kick.steps = Array(repeating: false, count: 16)
        sequencer.snare.steps = Array(repeating: false, count: 16)
        sequencer.hat.steps = Array(repeating: false, count: 16)
        sequencer.clap.steps = Array(repeating: false, count: 16)
        normalizeSequencerLanes()
        pushAudioState()
    }

    func generateAcidLine() {
        let accents = [0, 3, 5, 7, 10, 12, 14]
        sequencer.bass.steps = sequencer.bass.steps.indices.map { step in
            accents.contains(step) || (step % 4 == 2 && Bool.random())
        }
        sequencer.bass.notes = sequencer.bass.notes.indices.map { step in
            let degree = [0, 1, 2, 4, 5, 7, 9, 11][(step * 3 + Int.random(in: 0...2)) % 8]
            let octave = step % 8 == 7 ? 1 : 0
            return scaleOffset(degree: degree, octave: octave)
        }
        sequencer.bass.velocities = sequencer.bass.velocities.indices.map { step in step % 4 == 0 ? 1.0 : Double.random(in: 0.56...0.88) }
        sequencer.bass.probabilities = sequencer.bass.probabilities.indices.map { step in step % 8 == 7 ? 0.72 : 1.0 }
        sequencer.bass.ratchets = sequencer.bass.ratchets.indices.map { step in [3, 7, 11, 15].contains(step) ? [1, 2, 3].randomElement()! : 1 }
        bassVoice.instrument = .acidSaw
        bassVoice.cutoff = 0.64
        bassVoice.resonance = 0.46
        bassVoice.accent = 0.72
        bassVoice.drive = 0.54
        bassVoice.filterEnvelope = 0.68
        bassVoice.wavefold = 0.22
        bassVoice.subLevel = 0.30
        bassVoice.lfoRate = 0.24
        bassVoice.lfoAmount = 0.18
        status = "Generated acid line"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func generateLeadArp() {
        sequencer.lead.steps = sequencer.lead.steps.indices.map { step in step % 2 == 1 || [6, 10, 14].contains(step) }
        sequencer.lead.notes = sequencer.lead.notes.indices.map { step in
            let octave = 1 + (step / 6) % 2
            return scaleOffset(degree: step * 2 + (step % 3), octave: octave)
        }
        sequencer.lead.velocities = sequencer.lead.velocities.indices.map { step in step % 4 == 1 ? 0.92 : Double.random(in: 0.42...0.78) }
        sequencer.lead.probabilities = sequencer.lead.probabilities.indices.map { step in [5, 9, 13].contains(step) ? 0.58 : 0.86 }
        sequencer.lead.ratchets = sequencer.lead.ratchets.indices.map { step in step % 8 == 7 ? 2 : 1 }
        leadVoice.instrument = [.syncLead, .superSaw, .fmBell, .formantVox, .wavetableMorph, .phaseDistortion, .ringModKeys, .bitcrushLead, .granularCloud].randomElement()!
        leadVoice.cutoff = 0.70
        leadVoice.resonance = 0.22
        leadVoice.accent = 0.48
        leadVoice.morph = Double.random(in: 0.35...0.86)
        leadVoice.unison = Double.random(in: 0.15...0.72)
        leadVoice.detune = Double.random(in: 0.08...0.46)
        leadVoice.fmAmount = Double.random(in: 0.18...0.66)
        leadVoice.wavefold = Double.random(in: 0.05...0.38)
        leadVoice.bitcrush = leadVoice.instrument == .bitcrushLead ? 0.48 : Double.random(in: 0.0...0.20)
        status = "Generated scale-locked lead arp"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func mutatePattern() {
        let amount = min(1.0, max(0.0, sequencer.mutationAmount))
        let scale = sequencer.scale
        let root = sequencer.rootNote
        mutateLane(&sequencer.bass, melodic: true, density: 0.34, amount: amount, scale: scale, root: root)
        mutateLane(&sequencer.lead, melodic: true, density: 0.28, amount: amount, scale: scale, root: root)
        mutateLane(&sequencer.kick, melodic: false, density: 0.16, amount: amount, scale: scale, root: root)
        mutateLane(&sequencer.snare, melodic: false, density: 0.14, amount: amount, scale: scale, root: root)
        mutateLane(&sequencer.hat, melodic: false, density: 0.38, amount: amount, scale: scale, root: root)
        mutateLane(&sequencer.clap, melodic: false, density: 0.12, amount: amount, scale: scale, root: root)
        status = "Mutated sequencer \(Int(sequencer.mutationAmount * 100))%"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func humanizePattern() {
        humanizeLane(&sequencer.bass, range: 0.18)
        humanizeLane(&sequencer.lead, range: 0.22)
        humanizeLane(&sequencer.kick, range: 0.10)
        humanizeLane(&sequencer.snare, range: 0.16)
        humanizeLane(&sequencer.hat, range: 0.28)
        humanizeLane(&sequencer.clap, range: 0.20)
        sequencer.humanize = min(1.0, max(sequencer.humanize, 0.18))
        status = "Humanized velocities and chance"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func addRatchetFill() {
        let fillSteps = [3, 7, 11, 14, 15]
        for step in sequencer.hat.ratchets.indices {
            sequencer.hat.ratchets[step] = fillSteps.contains(step) ? [2, 3, 4, 6].randomElement()! : max(1, sequencer.hat.ratchets[step])
            sequencer.hat.probabilities[step] = fillSteps.contains(step) ? Double.random(in: 0.68...1.0) : sequencer.hat.probabilities[step]
        }
        for step in sequencer.snare.ratchets.indices where [11, 15].contains(step) {
            sequencer.snare.ratchets[step] = [2, 3].randomElement()!
            sequencer.snare.probabilities[step] = 0.65
        }
        status = "Added ratchet fill"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func tapTempo() {
        tempoMode = .manual
        let now = Date().timeIntervalSinceReferenceDate
        tapTempoTimes.append(now)
        tapTempoTimes = tapTempoTimes.filter { now - $0 < 3.0 }
        guard tapTempoTimes.count >= 2 else {
            status = "Tap tempo..."
            return
        }

        let intervals = zip(tapTempoTimes.dropFirst(), tapTempoTimes).map { $0 - $1 }
        let average = intervals.reduce(0, +) / Double(intervals.count)
        guard average > 0 else { return }
        sequencer.bpm = min(240, max(40, 60.0 / average))
        status = "Tempo \(Int(sequencer.bpm)) BPM"
        pushAudioState()
    }

    func nudgeTempo(_ amount: Double) {
        tempoMode = .manual
        sequencer.bpm = min(240, max(40, sequencer.bpm + amount))
        status = "Tempo \(Int(sequencer.bpm)) BPM"
        pushAudioState()
    }

    func halveTempo() {
        tempoMode = .manual
        sequencer.bpm = max(40, sequencer.bpm / 2.0)
        status = "Tempo \(Int(sequencer.bpm)) BPM"
        pushAudioState()
    }

    func doubleTempo() {
        tempoMode = .manual
        sequencer.bpm = min(240, sequencer.bpm * 2.0)
        status = "Tempo \(Int(sequencer.bpm)) BPM"
        pushAudioState()
    }

    func setManualTempo(_ bpm: Double) {
        tempoMode = .manual
        sequencer.bpm = min(240, max(40, bpm))
    }

    func applyTempoMode(_ mode: TempoMode) {
        tempoMode = mode
        switch mode {
        case .manual:
            status = "Manual tempo"
        case .goldenPhi:
            applyGoldenTempoMode()
        }
    }

    func applyGoldenTempoMode() {
        tempoMode = .goldenPhi
        sequencer.bpm = goldenTempoBPM
        sequencer.swing = 1.0 / pow(goldenRatio, 2.0)
        sequencer.patternLength = 13
        applyGoldenDelayTaps()
        status = "Golden Phi tempo \(String(format: "%.1f", sequencer.bpm)) BPM"
        pushAudioState()
    }

    func syncDelayToTempoPreset() {
        let offsets = [0.25, 0.375, 0.5, 0.75, 1.0, 1.5]
        for index in delaySettings.taps.indices {
            delaySettings.taps[index].beatOffset = offsets[index]
            delaySettings.taps[index].enabled = index < 4
            delaySettings.taps[index].visualSpread = 0.12 + Double(index) * 0.11
        }
        status = "Delay taps synced to tempo"
        pushAudioState()
    }

    func applyGoldenDelayTaps() {
        let offsets = [
            1.0 / pow(goldenRatio, 3.0),
            1.0 / pow(goldenRatio, 2.0),
            1.0 / goldenRatio,
            1.0,
            goldenRatio,
            pow(goldenRatio, 2.0)
        ]
        for index in delaySettings.taps.indices {
            let offset = offsets[index % offsets.count]
            delaySettings.taps[index].beatOffset = offset
            delaySettings.taps[index].enabled = true
            delaySettings.taps[index].level = max(0.12, 0.36 - Double(index) * 0.045)
            delaySettings.taps[index].feedback = max(0.06, 0.22 - Double(index) * 0.028)
            delaySettings.taps[index].visualSpread = min(1.0, offset / pow(goldenRatio, 2.0))
        }
    }

    private func normalizeSequencerLanes() {
        sequencer.bass.normalize()
        sequencer.lead.normalize()
        sequencer.kick.normalize()
        sequencer.snare.normalize()
        sequencer.hat.normalize()
        sequencer.clap.normalize()
        sequencer.patternLength = min(16, max(1, sequencer.patternLength))
    }

    private func scaleOffset(degree: Int, octave: Int) -> Int {
        let degrees = sequencer.scale.degrees
        guard !degrees.isEmpty else { return sequencer.rootNote + degree }
        let normalizedDegree = ((degree % degrees.count) + degrees.count) % degrees.count
        let octaveCarry = Int(floor(Double(degree) / Double(degrees.count)))
        return sequencer.rootNote + degrees[normalizedDegree] + (octave + octaveCarry) * 12
    }

    private func mutateLane(_ lane: inout StepLane, melodic: Bool, density: Double, amount: Double, scale: SequencerScale, root: Int) {
        for index in lane.steps.indices {
            if Double.random(in: 0...1) < amount * density {
                lane.steps[index].toggle()
            }
            if melodic, Double.random(in: 0...1) < amount * 0.44 {
                lane.notes[index] = scaleOffset(degree: index + Int.random(in: -3...8), octave: Int.random(in: 0...2), scale: scale, root: root)
            }
            if Double.random(in: 0...1) < amount * 0.52 {
                lane.velocities[index] = min(1.0, max(0.05, lane.velocities[index] + Double.random(in: -0.22...0.22)))
            }
            if Double.random(in: 0...1) < amount * 0.40 {
                lane.probabilities[index] = min(1.0, max(0.18, lane.probabilities[index] + Double.random(in: -0.24...0.18)))
            }
            if Double.random(in: 0...1) < amount * 0.18 {
                lane.ratchets[index] = [1, 1, 1, 2, 3, 4].randomElement()!
            }
        }
    }

    private func scaleOffset(degree: Int, octave: Int, scale: SequencerScale, root: Int) -> Int {
        let degrees = scale.degrees
        guard !degrees.isEmpty else { return root + degree }
        let normalizedDegree = ((degree % degrees.count) + degrees.count) % degrees.count
        let octaveCarry = Int(floor(Double(degree) / Double(degrees.count)))
        return root + degrees[normalizedDegree] + (octave + octaveCarry) * 12
    }

    private func humanizeLane(_ lane: inout StepLane, range: Double) {
        for index in lane.velocities.indices {
            lane.velocities[index] = min(1.0, max(0.08, lane.velocities[index] + Double.random(in: -range...range)))
        }
        for index in lane.probabilities.indices where lane.steps[index] {
            lane.probabilities[index] = min(1.0, max(0.45, lane.probabilities[index] + Double.random(in: -range * 0.65...range * 0.25)))
        }
    }

    func tickPerformanceClock() {
        launchQueuedSceneIfNeeded()

        guard autopilotEnabled else { return }
        let presets = filteredPresets
        guard !presets.isEmpty else { return }

        let seconds = Date().timeIntervalSinceReferenceDate
        let beat = Int(floor(seconds * sequencer.bpm / 60.0))
        let interval = max(1, autopilotBars * 4)
        guard beat != lastAutopilotBeat, beat % interval == 0 else { return }

        lastAutopilotBeat = beat
        autopilotIndex = (autopilotIndex + 1) % presets.count
        applyPreset(presets[autopilotIndex])
    }

    func tickLightSynthDirector(time: TimeInterval) {
        guard photonDirectorEnabled else { return }
        macroX = 0.5 + sin(time * 0.071) * 0.42 + sin(time * 0.013) * 0.06
        macroY = 0.5 + cos(time * 0.053) * 0.38 + sin(time * 0.019) * 0.08
        macroX = min(1, max(0, macroX))
        macroY = min(1, max(0, macroY))
    }

    func setTripMaximum() {
        photonDirectorEnabled = false
        lightSynthMode = .everything
        lightSynthIntensity = 1.0
        macroX = 0.92
        macroY = 0.86
        phosphorPersistence = 0.88
        prismSplits = 8
        experimentalVideoMode = .demosceneStack
        experimentalVideoIntensity = 0.82
        videoKeyThreshold = 0.34
        videoEdgeGain = 0.86
        videoColorWarp = 0.92
        videoOscillatorRate = 0.74
        cameraFeedbackMode = .echoTunnel
        cameraOverlayOpacity = 0.52
        cameraFeedbackAmount = 0.76
        cameraOverlayScale = 1.06
        cameraFeedbackRotation = 0.34
        cameraChromaShift = 0.62
        holographicMode = .interference
        minterEffectMode = .llamaFeedback
        demosceneEffectMode = .megaDemo
    }

    func setSafeCruise() {
        photonDirectorEnabled = false
        lightSynthIntensity = 0.42
        macroX = 0.45
        macroY = 0.35
        phosphorPersistence = 0.35
        prismSplits = 3
        experimentalVideoMode = .clean
        experimentalVideoIntensity = 0.32
        videoKeyThreshold = 0.58
        videoEdgeGain = 0.32
        videoColorWarp = 0.42
        videoOscillatorRate = 0.40
        cameraFeedbackMode = .optical
        cameraOverlayOpacity = 0.28
        cameraFeedbackAmount = 0.28
        cameraOverlayScale = 1.0
        cameraFeedbackRotation = 0.0
        cameraChromaShift = 0.12
        flashSafety = true
    }

    func setCameraInputEnabled(_ enabled: Bool) {
        cameraInputEnabled = enabled
        if enabled {
            cameraInput.start()
            status = cameraInput.status
        } else {
            cameraInput.stop()
            status = "Camera input off"
        }
    }

    func refreshCameraDevices() {
        cameraInput.refreshDevices()
        status = cameraInput.status
    }

    func selectCameraDevice(_ id: String) {
        cameraInput.selectDevice(id: id)
        status = cameraInput.status
    }

    func saveScene(slot: Int) {
        guard sceneDeck.indices.contains(slot) else { return }
        sceneDeck[slot] = makeSceneSnapshot(name: "Scene \(slot + 1)")
        status = "Saved Scene \(slot + 1)"
    }

    func recallScene(slot: Int) {
        guard sceneDeck.indices.contains(slot), let scene = sceneDeck[slot] else { return }
        guard sceneLaunchQuantization == .immediate else {
            queuedSceneSlot = slot
            status = "Queued Scene \(slot + 1) for \(sceneLaunchQuantization.shortLabel)"
            return
        }

        launchScene(scene, slot: slot)
    }

    private func launchSceneIfAvailable(slot: Int) {
        guard sceneDeck.indices.contains(slot), let scene = sceneDeck[slot] else { return }
        launchScene(scene, slot: slot)
    }

    private func launchScene(_ scene: LightSceneSnapshot, slot: Int) {
        selectedPreset = scene.preset
        selectedFamily = scene.preset.family
        lightSynthMode = scene.lightSynthMode
        paletteMode = scene.paletteMode
        blendMode = scene.blendMode
        macroX = scene.macroX
        macroY = scene.macroY
        lightSynthIntensity = scene.intensity
        phosphorPersistence = scene.phosphorPersistence
        prismSplits = scene.prismSplits
        demosceneEffectMode = scene.demosceneMode
        minterEffectMode = scene.minterMode
        holographicMode = scene.holographicMode
        experimentalVideoMode = scene.experimentalVideoMode
        experimentalVideoIntensity = scene.experimentalVideoIntensity
        videoKeyThreshold = scene.videoKeyThreshold
        videoEdgeGain = scene.videoEdgeGain
        videoColorWarp = scene.videoColorWarp
        videoOscillatorRate = scene.videoOscillatorRate
        cameraFeedbackMode = scene.cameraFeedbackMode
        cameraOverlayOpacity = scene.cameraOverlayOpacity
        cameraFeedbackAmount = scene.cameraFeedbackAmount
        cameraOverlayScale = scene.cameraOverlayScale
        cameraFeedbackRotation = scene.cameraFeedbackRotation
        cameraLumaThreshold = scene.cameraLumaThreshold
        cameraChromaShift = scene.cameraChromaShift
        cameraMirror = scene.cameraMirror
        photonDirectorEnabled = false
        queuedSceneSlot = nil
        sceneCutTime = Date().timeIntervalSinceReferenceDate
        status = "Launched Scene \(slot + 1)"
    }

    private func launchQueuedSceneIfNeeded() {
        guard let slot = queuedSceneSlot else { return }
        let interval = sceneLaunchQuantization.beatInterval
        guard interval > 0 else {
            launchSceneIfAvailable(slot: slot)
            return
        }

        let seconds = Date().timeIntervalSinceReferenceDate
        let beat = Int(floor(seconds * sequencer.bpm / 60.0))
        guard beat != lastQueuedSceneBeat, beat % interval == 0 else { return }
        lastQueuedSceneBeat = beat
        launchSceneIfAvailable(slot: slot)
    }

    func setSceneMorph(_ amount: Double) {
        sceneMorphAmount = min(1.0, max(0.0, amount))
        guard
            sceneDeck.indices.contains(sceneMorphFromSlot),
            sceneDeck.indices.contains(sceneMorphToSlot),
            let from = sceneDeck[sceneMorphFromSlot],
            let to = sceneDeck[sceneMorphToSlot]
        else {
            status = "Save scenes in both morph slots first"
            return
        }

        applySceneMorph(from: from, to: to, amount: sceneMorphAmount)
        status = "Morphed Scene \(sceneMorphFromSlot + 1) -> \(sceneMorphToSlot + 1) \(Int(sceneMorphAmount * 100))%"
    }

    func saveMorphEndpoint(_ endpoint: Int) {
        if endpoint == 0 {
            saveScene(slot: sceneMorphFromSlot)
        } else {
            saveScene(slot: sceneMorphToSlot)
        }
    }

    func randomizeSceneDeck() {
        for slot in sceneDeck.indices {
            if let preset = PresetLibrary.visualPresets.randomElement() {
                selectedPreset = preset
                selectedFamily = preset.family
                regenerateVisualScene(for: preset)
                experimentalVideoMode = ExperimentalVideoMode.allCases.filter { $0 != .clean }.randomElement() ?? .colourspace
                experimentalVideoIntensity = Double.random(in: 0.45...0.92)
                videoKeyThreshold = Double.random(in: 0.22...0.72)
                videoEdgeGain = Double.random(in: 0.34...0.98)
                videoColorWarp = Double.random(in: 0.42...1.0)
                videoOscillatorRate = Double.random(in: 0.25...0.92)
                macroX = Double.random(in: 0.08...0.92)
                macroY = Double.random(in: 0.08...0.92)
                sceneDeck[slot] = makeSceneSnapshot(name: "Generated \(slot + 1)")
            }
        }
        status = "Generated 8-scene performance deck"
    }

    func applyProductionSafeOutput() {
        flashSafety = true
        masterLevel = 0.52
        masterDrive = 0.12
        stereoWidth = 0.58
        limiterCeiling = 0.84
        limiterRelease = 0.44
        bloom = 0.28
        exposure = 0.56
        visualOutputGain = 0.74
        visualSoftClip = 0.70
        mixer.fxReturn.level = 0.34
        status = "Applied producer-safe output"
        pushAudioState()
    }

    func applyWideStageMix() {
        mixer.bass = MixerChannel(level: 0.80, pan: -0.18, send: 0.22)
        mixer.lead = MixerChannel(level: 0.74, pan: 0.22, send: 0.38)
        mixer.drums = MixerChannel(level: 0.88, pan: 0.0, send: 0.16)
        mixer.liveKeys = MixerChannel(level: 0.70, pan: 0.0, send: 0.28)
        mixer.fxReturn = MixerChannel(level: 0.46, pan: 0.0, send: 0.0)
        stereoWidth = 0.78
        masterDrive = 0.16
        status = "Applied wide-stage mix"
        pushAudioState()
    }

    func applyVisualizerMax() {
        audioVisualizerMode = .hyperAnalyzer
        audioVisualizerIntensity = 0.92
        audioVisualizerDetail = 0.88
        audioVisualizerPersistence = 0.62
        lightSynthIntensity = min(1.0, max(lightSynthIntensity, 0.74))
        experimentalVideoIntensity = min(1.0, max(experimentalVideoIntensity, 0.62))
        visualOutputGain = min(0.92, max(visualOutputGain, 0.82))
        visualSoftClip = min(0.86, max(visualSoftClip, 0.68))
        status = "Visualizer max enabled"
    }

    func applyVisualizerFocus() {
        audioVisualizerMode = .spectrumTunnel
        audioVisualizerIntensity = 0.58
        audioVisualizerDetail = 0.50
        audioVisualizerPersistence = 0.32
        bloom = min(bloom, 0.34)
        exposure = min(exposure, 0.60)
        flashSafety = true
        status = "Visualizer focus enabled"
    }

    private func makeSceneSnapshot(name: String) -> LightSceneSnapshot {
        LightSceneSnapshot(
            name: name,
            preset: selectedPreset,
            lightSynthMode: lightSynthMode,
            paletteMode: paletteMode,
            blendMode: blendMode,
            macroX: macroX,
            macroY: macroY,
            intensity: lightSynthIntensity,
            phosphorPersistence: phosphorPersistence,
            prismSplits: prismSplits,
            demosceneMode: demosceneEffectMode,
            minterMode: minterEffectMode,
            holographicMode: holographicMode,
            experimentalVideoMode: experimentalVideoMode,
            experimentalVideoIntensity: experimentalVideoIntensity,
            videoKeyThreshold: videoKeyThreshold,
            videoEdgeGain: videoEdgeGain,
            videoColorWarp: videoColorWarp,
            videoOscillatorRate: videoOscillatorRate,
            cameraFeedbackMode: cameraFeedbackMode,
            cameraOverlayOpacity: cameraOverlayOpacity,
            cameraFeedbackAmount: cameraFeedbackAmount,
            cameraOverlayScale: cameraOverlayScale,
            cameraFeedbackRotation: cameraFeedbackRotation,
            cameraLumaThreshold: cameraLumaThreshold,
            cameraChromaShift: cameraChromaShift,
            cameraMirror: cameraMirror
        )
    }

    private func applySceneMorph(from: LightSceneSnapshot, to: LightSceneSnapshot, amount: Double) {
        let chooseTo = amount >= 0.5
        selectedPreset = chooseTo ? to.preset : from.preset
        selectedFamily = selectedPreset.family
        lightSynthMode = chooseTo ? to.lightSynthMode : from.lightSynthMode
        paletteMode = chooseTo ? to.paletteMode : from.paletteMode
        blendMode = chooseTo ? to.blendMode : from.blendMode
        demosceneEffectMode = chooseTo ? to.demosceneMode : from.demosceneMode
        minterEffectMode = chooseTo ? to.minterMode : from.minterMode
        holographicMode = chooseTo ? to.holographicMode : from.holographicMode
        experimentalVideoMode = chooseTo ? to.experimentalVideoMode : from.experimentalVideoMode
        cameraFeedbackMode = chooseTo ? to.cameraFeedbackMode : from.cameraFeedbackMode
        cameraMirror = chooseTo ? to.cameraMirror : from.cameraMirror

        macroX = lerp(from.macroX, to.macroX, amount)
        macroY = lerp(from.macroY, to.macroY, amount)
        lightSynthIntensity = lerp(from.intensity, to.intensity, amount)
        phosphorPersistence = lerp(from.phosphorPersistence, to.phosphorPersistence, amount)
        prismSplits = Int(round(lerp(Double(from.prismSplits), Double(to.prismSplits), amount)))
        experimentalVideoIntensity = lerp(from.experimentalVideoIntensity, to.experimentalVideoIntensity, amount)
        videoKeyThreshold = lerp(from.videoKeyThreshold, to.videoKeyThreshold, amount)
        videoEdgeGain = lerp(from.videoEdgeGain, to.videoEdgeGain, amount)
        videoColorWarp = lerp(from.videoColorWarp, to.videoColorWarp, amount)
        videoOscillatorRate = lerp(from.videoOscillatorRate, to.videoOscillatorRate, amount)
        cameraOverlayOpacity = lerp(from.cameraOverlayOpacity, to.cameraOverlayOpacity, amount)
        cameraFeedbackAmount = lerp(from.cameraFeedbackAmount, to.cameraFeedbackAmount, amount)
        cameraOverlayScale = lerp(from.cameraOverlayScale, to.cameraOverlayScale, amount)
        cameraFeedbackRotation = lerp(from.cameraFeedbackRotation, to.cameraFeedbackRotation, amount)
        cameraLumaThreshold = lerp(from.cameraLumaThreshold, to.cameraLumaThreshold, amount)
        cameraChromaShift = lerp(from.cameraChromaShift, to.cameraChromaShift, amount)
        photonDirectorEnabled = false
    }

    private func lerp(_ a: Double, _ b: Double, _ amount: Double) -> Double {
        a + (b - a) * amount
    }

    func pushAudioState() {
        audioEngine.update(
            sequencer: sequencer,
            bassVoice: bassVoice,
            leadVoice: leadVoice,
            delaySettings: delaySettings,
            mixer: mixer,
            liveNotes: liveNotes,
            masterLevel: masterLevel,
            masterDrive: masterDrive,
            stereoWidth: stereoWidth,
            limiterCeiling: limiterCeiling,
            limiterRelease: limiterRelease
        )
    }

    private func startAudioMetering() {
        guard audioMeterTimer == nil else { return }
        audioMeterTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAudioMeter()
            }
        }
    }

    func recordMP4() {
        guard !isRecording else { return }
        isRecording = true
        status = "Rendering MP4..."
        let request = makeRecordingRequest(duration: recordingDuration, fps: recordingFPS)

        Task.detached(priority: .userInitiated) {
            do {
                let url = try MP4Recorder.render(request: request)
                await MainActor.run {
                    self.lastRecordingURL = url
                    self.isRecording = false
                    self.status = "MP4 saved: \(url.lastPathComponent)"
                }
            } catch {
                await MainActor.run {
                    self.isRecording = false
                    self.status = "MP4 failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func makeRecordingRequest(duration: Double, fps: Int? = nil) -> MP4RecordingRequest {
        let outputSize = recordingResolution.size
        let frameRate = fps ?? recordingFPS
        return MP4RecordingRequest(
            preset: selectedPreset,
            sequencer: sequencer,
            bpm: sequencer.bpm,
            bloom: bloom,
            exposure: exposure,
            holographicMode: holographicMode,
            hologramDepth: hologramDepth,
            minterEffectMode: minterEffectMode,
            minterIntensity: minterIntensity,
            demosceneEffectMode: demosceneEffectMode,
            demosceneIntensity: demosceneIntensity,
            lightSynthMode: lightSynthMode,
            lightSynthIntensity: lightSynthIntensity,
            macroX: macroX,
            macroY: macroY,
            phosphorPersistence: phosphorPersistence,
            prismSplits: prismSplits,
            flashSafety: flashSafety,
            paletteMode: paletteMode,
            blendMode: blendMode,
            visualEngineMode: visualEngineMode,
            experimentalVideoMode: experimentalVideoMode,
            experimentalVideoIntensity: experimentalVideoIntensity,
            videoKeyThreshold: videoKeyThreshold,
            videoEdgeGain: videoEdgeGain,
            videoColorWarp: videoColorWarp,
            videoOscillatorRate: videoOscillatorRate,
            cameraInputEnabled: cameraInputEnabled,
            cameraOverlayOpacity: cameraOverlayOpacity,
            cameraFeedbackAmount: cameraFeedbackAmount,
            cameraOverlayScale: cameraOverlayScale,
            cameraFeedbackMode: cameraFeedbackMode,
            cameraFeedbackRotation: cameraFeedbackRotation,
            cameraLumaThreshold: cameraLumaThreshold,
            cameraChromaShift: cameraChromaShift,
            cameraMirror: cameraMirror,
            cameraImage: cameraInput.latestImage,
            stereoscopicMode: stereoscopicMode,
            stereoDepth: stereoDepth,
            sceneSeed: sceneSeed,
            blackout: blackout,
            freezeFrame: freezeFrame,
            strobeEnabled: strobeEnabled,
            strobeRate: strobeRate,
            delaySettings: delaySettings,
            duration: duration,
            fps: frameRate,
            width: outputSize.width,
            height: outputSize.height
        )
    }

    func applyBroadcastTarget(_ target: BroadcastTarget) {
        broadcastSettings.target = target
        broadcastSettings.ingestURL = target.defaultURL
        broadcastSettings.frameRate = target.recommendedFrameRate
        broadcastSettings.bitrateKbps = target.recommendedBitrateKbps
        if target == .facebook {
            broadcastSettings.facebookCompatibilityMode = true
            recordingResolution = target.recommendedResolution
            broadcastSettings.sourceMode = .trueLive
            status = "Facebook Live selected: RTMPS 443, 720p30, H.264/AAC, 2s keyframes"
        } else {
            status = "Broadcast target set to \(target.rawValue)"
        }
    }

    func applyFacebookLiveSafeSetup() {
        applyBroadcastTarget(.facebook)
        broadcastSettings.audioMode = .desktopStereoMix
        broadcastSettings.loopLatestRecording = true
        recordingResolution = .hd720
        status = "Facebook Safe Setup ready: paste Live Producer URL/key, route desktop audio, then Start Broadcast"
    }

    func listBroadcastAudioDevices() {
        status = "Listing broadcast audio devices..."
        Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["ffmpeg", "-hide_banner", "-f", "avfoundation", "-list_devices", "true", "-i", ""]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let devices = output
                    .split(separator: "\n")
                    .map(String.init)
                    .filter { $0.contains("AVFoundation audio devices") || $0.range(of: #"\[[0-9]+\]"#, options: .regularExpression) != nil }
                    .suffix(12)
                    .joined(separator: "  ")
                await MainActor.run {
                    self.status = devices.isEmpty ? "No ffmpeg audio devices listed" : devices
                }
            } catch {
                await MainActor.run {
                    self.status = "Could not list audio devices: \(error.localizedDescription)"
                }
            }
        }
    }

    func startBroadcast() {
        guard !isBroadcasting else { return }
        guard validateBroadcastSettings() else { return }

        do {
            switch broadcastSettings.sourceMode {
            case .trueLive:
                let size = recordingResolution.size
                try liveBroadcastController.start(
                    settings: broadcastSettings,
                    width: size.width,
                    height: size.height,
                    statusHandler: broadcastStatusHandler()
                ) { [weak self] in
                    guard let self else { return MP4RecordingRequest.fallback }
                    return await MainActor.run {
                        self.makeRecordingRequest(duration: 1, fps: self.broadcastSettings.frameRate)
                    }
                }
            case .latestRecordingLoop:
                guard let sourceURL = latestRecordingURL() else {
                    status = "Record an MP4 first before broadcasting"
                    return
                }
                try broadcastController.start(settings: broadcastSettings, sourceURL: sourceURL, statusHandler: broadcastStatusHandler())
            }
            isBroadcasting = true
            let audioSummary = broadcastSettings.audioMode == .desktopStereoMix ? "audio from \(BroadcastAudioInput.previewName(settings: broadcastSettings))" : "silent stereo audio"
            let targetSummary = broadcastSettings.target == .facebook ? "Facebook Live" : broadcastSettings.target.rawValue
            status = broadcastSettings.sourceMode == .trueLive ? "Broadcasting true live output to \(targetSummary) with \(audioSummary)" : "Broadcasting latest MP4 to \(targetSummary) with \(audioSummary)"
        } catch {
            isBroadcasting = false
            status = "Broadcast failed: \(error.localizedDescription)"
        }
    }

    func stopBroadcast() {
        broadcastController.stop()
        liveBroadcastController.stop()
        isBroadcasting = false
        status = "Broadcast stopped"
    }

    func broadcastCommandPreview() -> String {
        if broadcastSettings.sourceMode == .trueLive {
            let size = recordingResolution.size
            return liveBroadcastController.commandPreview(settings: broadcastSettings, width: size.width, height: size.height)
        }
        guard let sourceURL = latestRecordingURL() else {
            return "Record an MP4 first to preview the RTMP command."
        }
        return broadcastController.commandPreview(settings: broadcastSettings, sourceURL: sourceURL)
    }

    private func broadcastStatusHandler() -> @Sendable (String) -> Void {
        { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                self.status = message
                if message.contains("exited with code") {
                    self.isBroadcasting = false
                }
            }
        }
    }

    private func validateBroadcastSettings() -> Bool {
        let ingest = broadcastSettings.ingestURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = broadcastSettings.streamKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            status = "Broadcast failed: paste the Facebook Live stream key first"
            return false
        }
        if broadcastSettings.target == .facebook {
            guard ingest.hasPrefix("rtmps://") || ingest.hasPrefix("rtmp://") else {
                status = "Facebook failed: ingest URL must start with rtmps://live-api-s.facebook.com:443/rtmp"
                return false
            }
            if broadcastSettings.facebookCompatibilityMode {
                recordingResolution = .hd720
                broadcastSettings.frameRate = 30
                broadcastSettings.bitrateKbps = min(6000, max(2500, broadcastSettings.bitrateKbps))
            }
        }
        return true
    }

    func latestRecordingURL() -> URL? {
        if let lastRecordingURL {
            return lastRecordingURL
        }
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("recordings", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        return files
            .filter { $0.pathExtension.lowercased() == "mp4" }
            .max { left, right in
                let leftDate = (try? left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rightDate = (try? right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return leftDate < rightDate
            }
    }
}
