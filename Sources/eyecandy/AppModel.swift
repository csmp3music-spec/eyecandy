import AVFoundation
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPanel: InspectorPanel = .synth
    @Published var selectedFamily: PresetFamily = .all
    @Published var selectedPreset: VisualPreset = PresetLibrary.visualPresets[0]
    @Published var visualPresetFilter = ""
    @Published var tempoMode: TempoMode = .manual
    @Published var sequencer = SequencerState()
    @Published var bassVoice = SynthVoice()
    @Published var leadVoice = SynthVoice(instrument: .vocoderCarrier, level: 0.38, octave: 4, cutoff: 0.74, resonance: 0.42, glide: 0.08, accent: 0.45, chorus: 0.42, shimmer: 0.24)
    @Published var vocoder = VocoderState()
    @Published var delaySettings = MultiTapDelaySettings()
    @Published var mixer = AudioMixerState()
    @Published var modSlots = [ModSlot(enabled: true, source: .beat, destination: .zoom, amount: 0.24, rate: 1.0), ModSlot(), ModSlot()]
    @Published var liveNotes: Set<Int> = []
    @Published var autopilotEnabled = false
    @Published var autopilotBars = 8
    @Published var holographicMode: HolographicMode = .off
    @Published var hologramDepth = 0.42
    @Published var minterEffectMode: MinterEffectMode = .off
    @Published var minterIntensity = 0.48
    @Published var demosceneEffectMode: DemosceneEffectMode = .off
    @Published var demosceneIntensity = 0.62
    @Published var lightSynthMode: LightSynthMode = .neuralMandala
    @Published var lightSynthIntensity = 0.76
    @Published var audioVisualizerMode: AudioVisualizerMode = .vocalPrism
    @Published var audioVisualizerIntensity = 0.90
    @Published var audioVisualizerDetail = 0.86
    @Published var audioVisualizerPersistence = 0.64
    @Published var gpuVisualizerBackend: GPUVisualizerBackend = .metal
    @Published var metalVisualizerEffectMode: MetalVisualizerEffectMode = .fractalBloom
    @Published var metalVisualizerEffectIntensity = 0.88
    @Published var metalVisualizerEffectSpeed = 0.82
    @Published var psychedelicFieldMode: PsychedelicFieldMode = .liquidFractal
    @Published var psychedelicFieldIntensity = 0.88
    @Published var psychedelicFieldMotion = 0.86
    @Published var macroX = 0.58
    @Published var macroY = 0.64
    @Published var photonDirectorEnabled = true
    @Published var phosphorPersistence = 0.55
    @Published var prismSplits = 5
    @Published var flashSafety = true
    @Published var paletteMode: LightPaletteMode = .neon
    @Published var blendMode: LightBlendMode = .additive
    @Published var visualEngineMode: VisualEngineMode = .auroraFluid
    @Published var experimentalVideoMode: ExperimentalVideoMode = .clean
    @Published var experimentalVideoIntensity = 0.55
    @Published var videoKeyThreshold = 0.52
    @Published var videoEdgeGain = 0.46
    @Published var videoColorWarp = 0.58
    @Published var videoOscillatorRate = 0.50
    @Published var feedbackSimulatorMode: FeedbackSimulatorMode = .off
    @Published var feedbackSimulatorIntensity = 0.52
    @Published var feedbackSimulatorDecay = 0.68
    @Published var feedbackSimulatorZoom = 0.46
    @Published var feedbackSimulatorTwist = 0.22
    @Published var feedbackSimulatorDisplacement = 0.54
    @Published var feedbackSimulatorPrism = 0.42
    @Published var feedbackSimulatorAudioReactive = true
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
    @Published var activeSceneSlot: Int?
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

    var savedSceneCount: Int {
        sceneDeck.reduce(0) { count, scene in count + (scene == nil ? 0 : 1) }
    }

    var canSceneMorph: Bool {
        sceneDeck.indices.contains(sceneMorphFromSlot)
            && sceneDeck.indices.contains(sceneMorphToSlot)
            && sceneDeck[sceneMorphFromSlot] != nil
            && sceneDeck[sceneMorphToSlot] != nil
            && sceneMorphFromSlot != sceneMorphToSlot
    }

    func startAudio() {
        do {
            pushAudioState()
            try audioEngine.start()
            startAudioMetering()
            status = "Advanced synth and Vocal Prism ready"
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

    func setVocoderEnabled(_ enabled: Bool) {
        guard enabled else {
            vocoder.enabled = false
            try? audioEngine.setMicrophoneInputEnabled(false)
            pushAudioState()
            status = "Mic vocoder disabled"
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            activateVocoder()
        case .notDetermined:
            status = "Requesting microphone access..."
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.activateVocoder()
                    } else {
                        self.vocoder.enabled = false
                        self.status = "Microphone access was not granted"
                    }
                }
            }
        case .denied, .restricted:
            vocoder.enabled = false
            status = "Allow microphone access in System Settings to use the vocoder"
        @unknown default:
            vocoder.enabled = false
            status = "Microphone authorization is unavailable"
        }
    }

    func applyVocoderPerformance() {
        leadVoice.instrument = .vocoderCarrier
        leadVoice.chorus = 0.42
        leadVoice.shimmer = 0.28
        leadVoice.drive = 0.34
        audioVisualizerMode = .vocalPrism
        audioVisualizerIntensity = max(audioVisualizerIntensity, 0.88)
        audioVisualizerDetail = max(audioVisualizerDetail, 0.84)
        psychedelicFieldIntensity = max(psychedelicFieldIntensity, 0.82)
        setVocoderEnabled(true)
    }

    private func activateVocoder() {
        do {
            try audioEngine.setMicrophoneInputEnabled(true)
            vocoder.enabled = true
            pushAudioState()
            startAudioMetering()
            status = "Mic vocoder active - microphone is not monitored"
        } catch {
            vocoder.enabled = false
            status = "Mic vocoder unavailable: \(error.localizedDescription)"
        }
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
        activeSceneSlot = nil
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
        activeSceneSlot = nil
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
        feedbackSimulatorMode = feedbackSimulatorMode(for: preset.videoMode, seed: preset.name.count + preset.frameRate)
        feedbackSimulatorIntensity = min(0.88, 0.24 + preset.intensity * 0.58)
        feedbackSimulatorDecay = min(0.94, 0.34 + preset.intensity * 0.54)
        feedbackSimulatorZoom = min(0.90, 0.20 + preset.intensity * 0.56)
        feedbackSimulatorTwist = Double(((preset.name.count * 17) % 100)) / 100.0
        feedbackSimulatorDisplacement = min(0.94, 0.24 + preset.intensity * 0.62)
        feedbackSimulatorPrism = min(0.88, 0.18 + preset.intensity * 0.58)
        macroX = Double((preset.name.count * 37) % 100) / 100.0
        macroY = Double((preset.name.count * 71 + preset.frameRate) % 100) / 100.0
        prismSplits = 2 + ((preset.name.count + preset.frameRate) % 10)
        bloom = min(0.72, 0.22 + preset.intensity * 0.26)
        exposure = min(0.95, 0.48 + preset.intensity * 0.30)
        visualOutputGain = min(0.92, 0.66 + preset.intensity * 0.18)
        visualSoftClip = max(0.62, 0.82 - preset.intensity * 0.12)
        holographicMode = preset.videoMode == .clean ? .off : performanceHolographicMode(seed: preset.name.count + preset.frameRate, intensity: preset.intensity)
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

    private func feedbackSimulatorMode(for videoMode: ExperimentalVideoMode, seed: Int) -> FeedbackSimulatorMode {
        switch videoMode {
        case .videoFeedback, .recursiveMirror:
            return seed.isMultiple(of: 2) ? .crtCameraLoop : .glassMonitorStack
        case .chromaticAberration, .rgbDelay, .chromaInvert, .chromaLightLeaks:
            return seed.isMultiple(of: 3) ? .glassMonitorStack : .prismHall
        case .lumaKeyBloom, .solarizedContours, .phosphorBurn:
            return seed.isMultiple(of: 2) ? .crtCameraLoop : .lumaBloomMemory
        case .liquidLens, .opticalFlowSmear, .datamoshBlocks, .codecTear, .pixelSortTrails:
            return seed.isMultiple(of: 2) ? .tapeHeadEcho : .chromaWarpField
        case .slitScan, .scanGate, .vhsMelt, .halftonePosterize:
            return seed.isMultiple(of: 3) ? .surveillanceWall : .scanlineMemory
        case .kaleidoFeedback, .tunnelFold, .demosceneStack, .vectorScope, .oscillatorBank:
            return .mirrorLabyrinth
        case .clean, .colourspace, .neonPulse, .edgeTrace:
            let modes: [FeedbackSimulatorMode] = [.opticalTunnel, .prismHall, .lumaBloomMemory, .chromaWarpField, .scanlineMemory, .mirrorLabyrinth, .crtCameraLoop, .glassMonitorStack, .tapeHeadEcho, .surveillanceWall, .feedbackLab]
            return modes[abs(seed) % modes.count]
        }
    }

    private func performanceHolographicMode(seed: Int, intensity: Double) -> HolographicMode {
        if intensity > 0.86 {
            return .realisticStack
        }
        let modes: [HolographicMode] = [.ghostPrism, .scanVolume, .chromaDepth, .interference, .pepperGhost, .lightField, .cghSpeckle, .realisticStack]
        return modes[abs(seed) % modes.count]
    }

    func randomizeVisual() {
        if let preset = PresetLibrary.visualPresets.randomElement() {
            applyPreset(preset)
        }
    }

    func regenerateVisualScene(for preset: VisualPreset? = nil) {
        let activePreset = preset ?? selectedPreset
        activeSceneSlot = nil
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
        feedbackSimulatorMode = feedbackSimulatorMode(for: experimentalVideoMode, seed: seed + activePreset.id)
        feedbackSimulatorIntensity = min(0.84, 0.22 + profile.intensity * 0.54)
        feedbackSimulatorDecay = min(0.92, 0.38 + Double((seed * 13) % 55) / 100.0)
        feedbackSimulatorZoom = min(0.88, 0.18 + Double((seed * 17) % 62) / 100.0)
        feedbackSimulatorTwist = Double((seed * 19) % 100) / 100.0
        feedbackSimulatorDisplacement = min(0.92, 0.20 + Double((seed * 23) % 70) / 100.0)
        feedbackSimulatorPrism = min(0.88, 0.16 + Double((seed * 29) % 65) / 100.0)
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
        leadVoice.instrument = [.syncLead, .superSaw, .fmBell, .formantVox, .wavetableMorph, .phaseDistortion, .ringModKeys, .bitcrushLead, .granularCloud, .buchlaComplex, .synclavierDigital, .vectorMorph, .solinaStringer].randomElement()!
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

    func generateComposition() {
        let style = sequencer.compositionStyle
        let density = min(1.0, max(0.05, sequencer.generativeDensity))
        let variation = min(1.0, max(0.0, sequencer.phraseVariation))
        let seed = Int(Date().timeIntervalSinceReferenceDate * 1_000)
        let bassMotif: [Int]
        let leadMotif: [Int]
        let bassPulses: Int
        let leadPulses: Int

        switch style {
        case .acidLab:
            sequencer.bpm = 132 + Double(Int.random(in: -6...10))
            sequencer.scale = .phrygian
            sequencer.groove = .mpcShuffle
            sequencer.swing = 0.08 + variation * 0.10
            sequencer.patternLength = 16
            bassMotif = [0, 0, 3, 5, 7, 10, 7, 3]
            leadMotif = [12, 15, 19, 22, 24, 22, 19, 15]
            bassPulses = 6 + Int(density * 5)
            leadPulses = 4 + Int(density * 6)
        case .berlinSchool:
            sequencer.bpm = 96 + Double(Int.random(in: -8...14))
            sequencer.scale = .dorian
            sequencer.groove = .straight
            sequencer.swing = 0.02 + variation * 0.05
            sequencer.patternLength = 16
            bassMotif = [0, 7, 12, 10, 15, 12, 7, 5]
            leadMotif = [12, 19, 24, 26, 31, 29, 24, 19]
            bassPulses = 8 + Int(density * 4)
            leadPulses = 5 + Int(density * 4)
        case .psychedelicTrance:
            sequencer.bpm = 142 + Double(Int.random(in: -6...8))
            sequencer.scale = .harmonicMinor
            sequencer.groove = .electroPush
            sequencer.swing = 0.03 + variation * 0.04
            sequencer.patternLength = 16
            bassMotif = [0, 0, 7, 0, 3, 0, 8, 7]
            leadMotif = [12, 15, 19, 24, 27, 31, 27, 24]
            bassPulses = 10 + Int(density * 4)
            leadPulses = 6 + Int(density * 5)
        case .dubMutation:
            sequencer.bpm = 78 + Double(Int.random(in: -5...12))
            sequencer.scale = .minorPentatonic
            sequencer.groove = .dillaDrift
            sequencer.swing = 0.16 + variation * 0.14
            sequencer.patternLength = 16
            bassMotif = [0, 0, -5, 0, 3, 5, 0, -7]
            leadMotif = [12, 10, 7, 15, 12, 19, 15, 10]
            bassPulses = 3 + Int(density * 5)
            leadPulses = 2 + Int(density * 5)
        case .kosmischeAmbient:
            sequencer.bpm = 62 + Double(Int.random(in: -8...16))
            sequencer.scale = [.lydian, .hirajoshi, .wholeTone].randomElement()!
            sequencer.groove = .straight
            sequencer.swing = variation * 0.04
            sequencer.patternLength = 13
            bassMotif = [0, 7, 12, 19, 12, 7, 5]
            leadMotif = [12, 19, 24, 31, 36, 31, 24, 19]
            bassPulses = 3 + Int(density * 3)
            leadPulses = 2 + Int(density * 4)
        case .electroBreaks:
            sequencer.bpm = 118 + Double(Int.random(in: -8...10))
            sequencer.scale = .octatonic
            sequencer.groove = .brokenBeat
            sequencer.swing = 0.06 + variation * 0.12
            sequencer.patternLength = 16
            bassMotif = [0, 3, 0, 7, 10, 7, 3, -2]
            leadMotif = [12, 15, 18, 22, 27, 25, 22, 18]
            bassPulses = 5 + Int(density * 6)
            leadPulses = 4 + Int(density * 7)
        case .generativeRaga:
            sequencer.bpm = 108 + Double(Int.random(in: -10...18))
            sequencer.scale = [.hirajoshi, .pelog, .phrygian].randomElement()!
            sequencer.groove = .garageSkip
            sequencer.swing = 0.10 + variation * 0.12
            sequencer.patternLength = 15
            bassMotif = [0, 5, 7, 3, 8, 7, 5, 1]
            leadMotif = [12, 13, 15, 20, 24, 25, 27, 32]
            bassPulses = 4 + Int(density * 5)
            leadPulses = 5 + Int(density * 7)
        }

        configureVoices(for: style)
        let length = sequencer.patternLength
        let scale = sequencer.scale
        let root = sequencer.rootNote
        writeMelodicLane(&sequencer.bass, motif: bassMotif, pulses: bassPulses, baseOctave: 0, seed: seed, density: density, variation: variation, forceDownbeats: true, patternLength: length, scale: scale, root: root)
        writeMelodicLane(&sequencer.lead, motif: leadMotif, pulses: leadPulses, baseOctave: 1, seed: seed / 3, density: density, variation: variation, forceDownbeats: false, patternLength: length, scale: scale, root: root)
        programEuclideanDrums(style: style, density: density, variation: variation)
        syncDelayForComposition(style: style, density: density)
        normalizeSequencerLanes()
        status = "Generated \(style.rawValue) composition"
        pushAudioState()
    }

    func generateEuclideanDrums() {
        programEuclideanDrums(style: sequencer.compositionStyle, density: sequencer.generativeDensity, variation: sequencer.phraseVariation)
        normalizeSequencerLanes()
        status = "Generated Euclidean drums"
        pushAudioState()
    }

    func generateCounterMelody() {
        let chordJumps = [12, 19, 24, 17, 15, 22]
        let length = max(1, min(sequencer.patternLength, sequencer.lead.steps.count))
        for step in sequencer.lead.steps.indices {
            let source = (step + length / 2) % length
            let active = step < length && !sequencer.bass.steps[source] && (step % 2 == 1 || step % 4 == 2)
            sequencer.lead.steps[step] = active
            let bassNote = sequencer.bass.notes[source]
            let jump = chordJumps[(step + source) % chordJumps.count]
            sequencer.lead.notes[step] = nearestScaleOffset(bassNote + jump, scale: sequencer.scale, root: sequencer.rootNote)
            sequencer.lead.velocities[step] = active ? min(1.0, 0.48 + sequencer.phraseVariation * 0.36 + Double(step % 4 == 1 ? 0.18 : 0.0)) : 0.36
            sequencer.lead.probabilities[step] = active ? min(1.0, 0.58 + sequencer.generativeDensity * 0.34) : 0.25
            sequencer.lead.ratchets[step] = active && step % 8 == 7 ? [2, 3].randomElement()! : 1
        }
        leadVoice.enabled = true
        leadVoice.instrument = [.syncLead, .wavetableMorph, .ringModKeys, .phaseDistortion, .karplusPluck, .synclavierDigital, .vectorMorph, .buchlaComplex, .solinaStringer].randomElement()!
        normalizeSequencerLanes()
        status = "Generated counter melody"
        pushAudioState()
    }

    func captureLiveKeysToLead() {
        let captured = liveNotes.sorted()
        guard !captured.isEmpty else {
            status = "Hold live keyboard notes before capture"
            return
        }

        let baseNote = 60 + leadVoice.octave * 12
        let offsets = captured.map { $0 - baseNote }
        let length = max(1, min(sequencer.patternLength, sequencer.lead.steps.count))
        for step in sequencer.lead.steps.indices {
            let active = step < length && (step % 2 == 0 || (sequencer.phraseVariation > 0.55 && step % 4 == 3))
            sequencer.lead.steps[step] = active
            sequencer.lead.notes[step] = offsets[(step / 2) % offsets.count]
            sequencer.lead.velocities[step] = active ? 0.64 + Double(step % 4 == 0 ? 0.20 : 0.0) : 0.35
            sequencer.lead.probabilities[step] = active ? 0.78 + sequencer.generativeDensity * 0.20 : 0.20
            sequencer.lead.ratchets[step] = active && step % 8 == 6 ? 2 : 1
        }
        leadVoice.enabled = true
        status = "Captured \(captured.count) live key\(captured.count == 1 ? "" : "s") to lead"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func rotatePattern(_ amount: Int) {
        rotateLane(&sequencer.bass, by: amount)
        rotateLane(&sequencer.lead, by: amount)
        rotateLane(&sequencer.kick, by: amount)
        rotateLane(&sequencer.snare, by: amount)
        rotateLane(&sequencer.hat, by: amount)
        rotateLane(&sequencer.clap, by: amount)
        status = amount > 0 ? "Rotated pattern right" : "Rotated pattern left"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func mirrorPattern() {
        let length = sequencer.patternLength
        mirrorLane(&sequencer.bass, patternLength: length)
        mirrorLane(&sequencer.lead, patternLength: length)
        mirrorLane(&sequencer.kick, patternLength: length)
        mirrorLane(&sequencer.snare, patternLength: length)
        mirrorLane(&sequencer.hat, patternLength: length)
        mirrorLane(&sequencer.clap, patternLength: length)
        status = "Mirrored pattern loop"
        normalizeSequencerLanes()
        pushAudioState()
    }

    func invertMelodies() {
        let scale = sequencer.scale
        let root = sequencer.rootNote
        invertMelodyLane(&sequencer.bass, scale: scale, root: root)
        invertMelodyLane(&sequencer.lead, scale: scale, root: root)
        status = "Inverted bass and lead melodies"
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

    private func configureVoices(for style: CompositionStyle) {
        switch style {
        case .acidLab:
            bassVoice = SynthVoice(instrument: .acidSaw, enabled: true, level: 0.55, octave: 1, cutoff: 0.62, resonance: 0.58, glide: 0.22, accent: 0.82, attack: 0.01, decay: 0.38, sustain: 0.08, drive: 0.58, filterEnvelope: 0.78, lfoRate: 0.22, lfoAmount: 0.22, morph: 0.34, unison: 0.12, detune: 0.07, subLevel: 0.38, noiseLevel: 0.04, fmAmount: 0.18, wavefold: 0.24, grainSize: 0.16, grainDensity: 0.24, bitcrush: 0.03)
            leadVoice = SynthVoice(instrument: .buchlaComplex, enabled: true, level: 0.34, octave: 3, cutoff: 0.74, resonance: 0.32, glide: 0.05, accent: 0.46, attack: 0.01, decay: 0.34, sustain: 0.10, drive: 0.34, filterEnvelope: 0.46, lfoRate: 0.36, lfoAmount: 0.30, morph: 0.62, unison: 0.26, detune: 0.18, subLevel: 0.04, noiseLevel: 0.04, fmAmount: 0.62, wavefold: 0.74, grainSize: 0.18, grainDensity: 0.32, bitcrush: 0.07)
        case .berlinSchool:
            bassVoice = SynthVoice(instrument: .subSquare, enabled: true, level: 0.48, octave: 1, cutoff: 0.48, resonance: 0.24, glide: 0.18, accent: 0.38, attack: 0.02, decay: 0.62, sustain: 0.34, drive: 0.22, filterEnvelope: 0.28, lfoRate: 0.12, lfoAmount: 0.16, morph: 0.26, unison: 0.10, detune: 0.06, subLevel: 0.58, noiseLevel: 0.02, fmAmount: 0.08, wavefold: 0.08, grainSize: 0.20, grainDensity: 0.28, bitcrush: 0.0)
            leadVoice = SynthVoice(instrument: .solinaStringer, enabled: true, level: 0.38, octave: 3, cutoff: 0.70, resonance: 0.18, glide: 0.08, accent: 0.28, attack: 0.08, decay: 0.78, sustain: 0.52, drive: 0.18, filterEnvelope: 0.28, lfoRate: 0.18, lfoAmount: 0.38, morph: 0.62, unison: 0.54, detune: 0.30, subLevel: 0.04, noiseLevel: 0.03, fmAmount: 0.18, wavefold: 0.08, grainSize: 0.30, grainDensity: 0.42, bitcrush: 0.01)
        case .psychedelicTrance:
            bassVoice = SynthVoice(instrument: .reeseBass, enabled: true, level: 0.52, octave: 1, cutoff: 0.42, resonance: 0.30, glide: 0.06, accent: 0.64, attack: 0.01, decay: 0.30, sustain: 0.08, drive: 0.48, filterEnvelope: 0.52, lfoRate: 0.28, lfoAmount: 0.22, morph: 0.46, unison: 0.58, detune: 0.34, subLevel: 0.54, noiseLevel: 0.02, fmAmount: 0.14, wavefold: 0.20, grainSize: 0.12, grainDensity: 0.22, bitcrush: 0.02)
            leadVoice = SynthVoice(instrument: .vectorMorph, enabled: true, level: 0.34, octave: 3, cutoff: 0.80, resonance: 0.20, glide: 0.03, accent: 0.48, attack: 0.01, decay: 0.42, sustain: 0.18, drive: 0.26, filterEnvelope: 0.42, lfoRate: 0.44, lfoAmount: 0.40, morph: 0.78, unison: 0.68, detune: 0.38, subLevel: 0.02, noiseLevel: 0.02, fmAmount: 0.44, wavefold: 0.18, grainSize: 0.16, grainDensity: 0.30, bitcrush: 0.03)
        case .dubMutation:
            bassVoice = SynthVoice(instrument: .subSquare, enabled: true, level: 0.58, octave: 1, cutoff: 0.36, resonance: 0.20, glide: 0.24, accent: 0.46, attack: 0.02, decay: 0.72, sustain: 0.42, drive: 0.34, filterEnvelope: 0.24, lfoRate: 0.10, lfoAmount: 0.26, morph: 0.22, unison: 0.08, detune: 0.04, subLevel: 0.72, noiseLevel: 0.03, fmAmount: 0.06, wavefold: 0.06, grainSize: 0.24, grainDensity: 0.20, bitcrush: 0.0)
            leadVoice = SynthVoice(instrument: .ringModKeys, enabled: true, level: 0.28, octave: 3, cutoff: 0.58, resonance: 0.34, glide: 0.10, accent: 0.22, attack: 0.05, decay: 0.70, sustain: 0.34, drive: 0.18, filterEnvelope: 0.22, lfoRate: 0.20, lfoAmount: 0.34, morph: 0.50, unison: 0.16, detune: 0.12, subLevel: 0.02, noiseLevel: 0.04, fmAmount: 0.72, wavefold: 0.10, grainSize: 0.18, grainDensity: 0.28, bitcrush: 0.05)
        case .kosmischeAmbient:
            bassVoice = SynthVoice(instrument: .spectralDrone, enabled: true, level: 0.36, octave: 1, cutoff: 0.44, resonance: 0.34, glide: 0.42, accent: 0.18, attack: 0.28, decay: 0.92, sustain: 0.78, drive: 0.12, filterEnvelope: 0.16, lfoRate: 0.14, lfoAmount: 0.54, morph: 0.80, unison: 0.46, detune: 0.28, subLevel: 0.18, noiseLevel: 0.14, fmAmount: 0.24, wavefold: 0.06, grainSize: 0.62, grainDensity: 0.44, bitcrush: 0.01)
            leadVoice = SynthVoice(instrument: .mellotronTape, enabled: true, level: 0.30, octave: 3, cutoff: 0.72, resonance: 0.16, glide: 0.20, accent: 0.14, attack: 0.24, decay: 0.90, sustain: 0.68, drive: 0.12, filterEnvelope: 0.16, lfoRate: 0.18, lfoAmount: 0.48, morph: 0.78, unison: 0.32, detune: 0.34, subLevel: 0.04, noiseLevel: 0.22, fmAmount: 0.30, wavefold: 0.05, grainSize: 0.78, grainDensity: 0.86, bitcrush: 0.02)
        case .electroBreaks:
            bassVoice = SynthVoice(instrument: .phaseDistortion, enabled: true, level: 0.50, octave: 1, cutoff: 0.54, resonance: 0.36, glide: 0.10, accent: 0.54, attack: 0.01, decay: 0.44, sustain: 0.16, drive: 0.42, filterEnvelope: 0.50, lfoRate: 0.30, lfoAmount: 0.24, morph: 0.66, unison: 0.22, detune: 0.16, subLevel: 0.32, noiseLevel: 0.04, fmAmount: 0.58, wavefold: 0.34, grainSize: 0.18, grainDensity: 0.30, bitcrush: 0.16)
            leadVoice = SynthVoice(instrument: .synclavierDigital, enabled: true, level: 0.34, octave: 3, cutoff: 0.64, resonance: 0.42, glide: 0.06, accent: 0.62, attack: 0.01, decay: 0.34, sustain: 0.10, drive: 0.42, filterEnvelope: 0.50, lfoRate: 0.48, lfoAmount: 0.34, morph: 0.64, unison: 0.20, detune: 0.12, subLevel: 0.06, noiseLevel: 0.06, fmAmount: 0.82, wavefold: 0.26, grainSize: 0.16, grainDensity: 0.34, bitcrush: 0.24)
        case .generativeRaga:
            bassVoice = SynthVoice(instrument: .buchlaComplex, enabled: true, level: 0.42, octave: 1, cutoff: 0.70, resonance: 0.22, glide: 0.08, accent: 0.58, attack: 0.00, decay: 0.32, sustain: 0.08, drive: 0.26, filterEnvelope: 0.52, lfoRate: 0.18, lfoAmount: 0.12, morph: 0.42, unison: 0.08, detune: 0.05, subLevel: 0.18, noiseLevel: 0.16, fmAmount: 0.44, wavefold: 0.58, grainSize: 0.14, grainDensity: 0.24, bitcrush: 0.0)
            leadVoice = SynthVoice(instrument: .formantVox, enabled: true, level: 0.34, octave: 3, cutoff: 0.74, resonance: 0.52, glide: 0.12, accent: 0.30, attack: 0.08, decay: 0.70, sustain: 0.46, drive: 0.18, filterEnvelope: 0.30, lfoRate: 0.20, lfoAmount: 0.24, morph: 0.66, unison: 0.22, detune: 0.15, subLevel: 0.02, noiseLevel: 0.05, fmAmount: 0.30, wavefold: 0.08, grainSize: 0.34, grainDensity: 0.40, bitcrush: 0.02)
        }
    }

    private func writeMelodicLane(_ lane: inout StepLane, motif: [Int], pulses: Int, baseOctave: Int, seed: Int, density: Double, variation: Double, forceDownbeats: Bool, patternLength: Int, scale: SequencerScale, root: Int) {
        let length = max(1, min(patternLength, lane.steps.count))
        let mask = euclideanPattern(pulses: min(length, max(1, pulses)), steps: lane.steps.count, rotation: seed % max(1, length))
        for step in lane.steps.indices {
            let inLoop = step < length
            let downbeat = forceDownbeats && step % 4 == 0
            let ghost = Double.random(in: 0...1) < variation * 0.18 && step < length
            lane.steps[step] = inLoop && (mask[step] || downbeat || ghost)
            let motifIndex = abs(step + seed) % max(1, motif.count)
            let mutation = Double.random(in: 0...1) < variation * 0.28 ? Int.random(in: -2...2) : 0
            let octaveLift = step % 11 == 7 ? 1 : 0
            lane.notes[step] = scaleOffset(degree: motif[motifIndex] + mutation, octave: baseOctave + octaveLift, scale: scale, root: root)
            lane.velocities[step] = lane.steps[step] ? min(1.0, 0.48 + density * 0.34 + Double(step % 4 == 0 ? 0.18 : 0.0)) : 0.32
            lane.probabilities[step] = lane.steps[step] ? min(1.0, 0.58 + density * 0.34 + variation * 0.08) : max(0.10, variation * 0.28)
            lane.ratchets[step] = lane.steps[step] && variation > 0.42 && [3, 7, 11, 15].contains(step) ? [1, 2, 3].randomElement()! : 1
        }
    }

    private func programEuclideanDrums(style: CompositionStyle, density: Double, variation: Double) {
        let density = min(1.0, max(0.05, density))
        let variation = min(1.0, max(0.0, variation))
        let kickPulses: Int
        let snarePulses: Int
        let hatPulses: Int
        let clapPulses: Int
        let snareRotation: Int

        switch style {
        case .acidLab:
            kickPulses = 4 + Int(density * 2)
            snarePulses = 2
            hatPulses = 7 + Int(density * 6)
            clapPulses = 2 + Int(variation * 2)
            snareRotation = 4
        case .berlinSchool:
            kickPulses = 4
            snarePulses = 1 + Int(density * 2)
            hatPulses = 6 + Int(density * 5)
            clapPulses = 1
            snareRotation = 6
        case .psychedelicTrance:
            kickPulses = 4
            snarePulses = 2
            hatPulses = 10 + Int(density * 5)
            clapPulses = 2
            snareRotation = 4
        case .dubMutation:
            kickPulses = 3 + Int(density * 3)
            snarePulses = 2
            hatPulses = 4 + Int(density * 5)
            clapPulses = 2 + Int(variation * 2)
            snareRotation = 4
        case .kosmischeAmbient:
            kickPulses = 1 + Int(density * 2)
            snarePulses = 1
            hatPulses = 3 + Int(density * 4)
            clapPulses = variation > 0.6 ? 1 : 0
            snareRotation = 8
        case .electroBreaks:
            kickPulses = 5 + Int(density * 3)
            snarePulses = 3 + Int(variation * 2)
            hatPulses = 8 + Int(density * 5)
            clapPulses = 2 + Int(variation * 3)
            snareRotation = 3
        case .generativeRaga:
            kickPulses = 3 + Int(density * 3)
            snarePulses = 1 + Int(variation * 2)
            hatPulses = 5 + Int(density * 6)
            clapPulses = 1 + Int(variation * 2)
            snareRotation = 5
        }

        sequencer.kick.steps = euclideanPattern(pulses: kickPulses, steps: sequencer.kick.steps.count, rotation: 0)
        sequencer.snare.steps = euclideanPattern(pulses: snarePulses, steps: sequencer.snare.steps.count, rotation: snareRotation)
        sequencer.hat.steps = euclideanPattern(pulses: hatPulses, steps: sequencer.hat.steps.count, rotation: 2)
        sequencer.clap.steps = euclideanPattern(pulses: clapPulses, steps: sequencer.clap.steps.count, rotation: 7)

        for step in sequencer.kick.steps.indices {
            sequencer.kick.velocities[step] = sequencer.kick.steps[step] ? (step % 4 == 0 ? 1.0 : 0.72 + density * 0.16) : 0.42
            sequencer.kick.probabilities[step] = sequencer.kick.steps[step] ? 1.0 : 0.10
            sequencer.kick.ratchets[step] = 1
            sequencer.snare.velocities[step] = sequencer.snare.steps[step] ? 0.70 + variation * 0.22 : 0.38
            sequencer.snare.probabilities[step] = sequencer.snare.steps[step] ? 0.82 + density * 0.16 : 0.12
            sequencer.snare.ratchets[step] = sequencer.snare.steps[step] && variation > 0.62 && step % 8 == 7 ? 2 : 1
            sequencer.hat.velocities[step] = sequencer.hat.steps[step] ? 0.42 + density * 0.36 + Double(step % 4 == 2 ? 0.12 : 0.0) : 0.26
            sequencer.hat.probabilities[step] = sequencer.hat.steps[step] ? min(1.0, 0.58 + density * 0.32) : max(0.08, variation * 0.22)
            sequencer.hat.ratchets[step] = sequencer.hat.steps[step] && variation > 0.34 && [6, 14, 15].contains(step) ? [2, 3, 4].randomElement()! : 1
            sequencer.clap.velocities[step] = sequencer.clap.steps[step] ? 0.56 + variation * 0.24 : 0.28
            sequencer.clap.probabilities[step] = sequencer.clap.steps[step] ? 0.62 + density * 0.24 : 0.08
            sequencer.clap.ratchets[step] = sequencer.clap.steps[step] && variation > 0.72 ? 2 : 1
        }
    }

    private func syncDelayForComposition(style: CompositionStyle, density: Double) {
        let offsets: [Double]
        switch style {
        case .dubMutation:
            offsets = [0.375, 0.75, 1.5, 2.25, 3.0, 4.0]
            delaySettings.wet = 0.56
            delaySettings.globalFeedback = 0.42
        case .kosmischeAmbient:
            offsets = [0.5, 1.0, 1.618, 2.618, 4.0, 6.0]
            delaySettings.wet = 0.62
            delaySettings.globalFeedback = 0.36
        case .berlinSchool:
            offsets = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0]
            delaySettings.wet = 0.42
            delaySettings.globalFeedback = 0.30
        case .acidLab, .psychedelicTrance, .electroBreaks, .generativeRaga:
            offsets = [0.1875, 0.25, 0.375, 0.5, 0.75, 1.0]
            delaySettings.wet = 0.32 + density * 0.18
            delaySettings.globalFeedback = 0.22 + density * 0.16
        }

        delaySettings.enabled = true
        for index in delaySettings.taps.indices {
            delaySettings.taps[index].enabled = index < 4 || style == .kosmischeAmbient || style == .dubMutation
            delaySettings.taps[index].beatOffset = offsets[index % offsets.count]
            delaySettings.taps[index].level = max(0.10, 0.36 - Double(index) * 0.045)
            delaySettings.taps[index].feedback = max(0.05, delaySettings.globalFeedback * (0.56 - Double(index) * 0.045))
            delaySettings.taps[index].visualSpread = min(1.0, 0.12 + Double(index) * 0.13 + density * 0.12)
        }
    }

    private func euclideanPattern(pulses: Int, steps: Int, rotation: Int) -> [Bool] {
        guard steps > 0 else { return [] }
        let pulses = min(steps, max(0, pulses))
        guard pulses > 0 else { return Array(repeating: false, count: steps) }
        guard pulses < steps else { return Array(repeating: true, count: steps) }
        return (0..<steps).map { index in
            let rotated = (index + rotation + steps * 8) % steps
            return (rotated * pulses) % steps < pulses
        }
    }

    private func rotateLane(_ lane: inout StepLane, by amount: Int) {
        lane.steps = rotated(lane.steps, by: amount)
        lane.notes = rotated(lane.notes, by: amount)
        lane.velocities = rotated(lane.velocities, by: amount)
        lane.probabilities = rotated(lane.probabilities, by: amount)
        lane.ratchets = rotated(lane.ratchets, by: amount)
    }

    private func rotated<T>(_ values: [T], by amount: Int) -> [T] {
        guard !values.isEmpty else { return values }
        let shift = ((amount % values.count) + values.count) % values.count
        guard shift != 0 else { return values }
        return Array(values.suffix(shift)) + Array(values.prefix(values.count - shift))
    }

    private func mirrorLane(_ lane: inout StepLane, patternLength: Int) {
        let length = max(1, min(patternLength, lane.steps.count))
        let half = max(1, (length + 1) / 2)
        for step in half..<length {
            let source = max(0, length - 1 - step)
            lane.steps[step] = lane.steps[source]
            lane.notes[step] = lane.notes[source]
            lane.velocities[step] = lane.velocities[source]
            lane.probabilities[step] = lane.probabilities[source]
            lane.ratchets[step] = lane.ratchets[source]
        }
    }

    private func invertMelodyLane(_ lane: inout StepLane, scale: SequencerScale, root: Int) {
        let activeNotes = lane.steps.indices.filter { lane.steps[$0] }.map { lane.notes[$0] }
        let pivot = activeNotes.isEmpty ? root : Int(round(Double(activeNotes.reduce(0, +)) / Double(activeNotes.count)))
        for index in lane.notes.indices {
            let inverted = pivot - (lane.notes[index] - pivot)
            lane.notes[index] = nearestScaleOffset(inverted, scale: scale, root: root)
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

    private func nearestScaleOffset(_ offset: Int, scale: SequencerScale, root: Int) -> Int {
        let degrees = scale.degrees
        guard !degrees.isEmpty else { return offset }
        let candidates = (-4...5).flatMap { octave in
            degrees.map { root + $0 + octave * 12 }
        }
        return candidates.min { abs($0 - offset) < abs($1 - offset) } ?? offset
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
        feedbackSimulatorMode = .feedbackLab
        feedbackSimulatorIntensity = 0.86
        feedbackSimulatorDecay = 0.88
        feedbackSimulatorZoom = 0.76
        feedbackSimulatorTwist = 0.64
        feedbackSimulatorDisplacement = 0.86
        feedbackSimulatorPrism = 0.82
        feedbackSimulatorAudioReactive = true
        cameraFeedbackMode = .echoTunnel
        cameraOverlayOpacity = 0.52
        cameraFeedbackAmount = 0.76
        cameraOverlayScale = 1.06
        cameraFeedbackRotation = 0.34
        cameraChromaShift = 0.62
        holographicMode = .realisticStack
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
        feedbackSimulatorMode = .off
        feedbackSimulatorIntensity = 0.32
        feedbackSimulatorDecay = 0.42
        feedbackSimulatorZoom = 0.28
        feedbackSimulatorTwist = 0.12
        feedbackSimulatorDisplacement = 0.26
        feedbackSimulatorPrism = 0.18
        feedbackSimulatorAudioReactive = true
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

    func sceneSlotTitle(_ slot: Int) -> String {
        guard sceneDeck.indices.contains(slot) else { return "Scene" }
        if activeSceneSlot == slot {
            return "Live \(slot + 1)"
        }
        if queuedSceneSlot == slot {
            return "Queued \(slot + 1)"
        }
        return sceneDeck[slot] == nil ? "Empty \(slot + 1)" : "Scene \(slot + 1)"
    }

    func sceneSlotSubtitle(_ slot: Int) -> String {
        guard sceneDeck.indices.contains(slot) else { return "" }
        guard let scene = sceneDeck[slot] else { return "Save current look" }
        let visualMode = scene.experimentalVideoMode == .clean ? scene.lightSynthMode.rawValue : scene.experimentalVideoMode.rawValue
        return "\(scene.preset.name) / \(visualMode)"
    }

    func sceneSlotStatus(_ slot: Int) -> String? {
        guard sceneDeck.indices.contains(slot) else { return nil }
        if activeSceneSlot == slot {
            return "LIVE"
        }
        if queuedSceneSlot == slot {
            return sceneLaunchQuantization.shortLabel.uppercased()
        }
        return nil
    }

    func saveScene(slot: Int) {
        guard sceneDeck.indices.contains(slot) else { return }
        sceneDeck[slot] = makeSceneSnapshot(name: "Scene \(slot + 1)")
        activeSceneSlot = slot
        queuedSceneSlot = queuedSceneSlot == slot ? nil : queuedSceneSlot
        status = "Saved Scene \(slot + 1)"
    }

    func clearScene(slot: Int) {
        guard sceneDeck.indices.contains(slot) else { return }
        sceneDeck[slot] = nil
        if activeSceneSlot == slot {
            activeSceneSlot = nil
        }
        if queuedSceneSlot == slot {
            queuedSceneSlot = nil
        }
        repairSceneMorphEndpoints()
        status = "Cleared Scene \(slot + 1)"
    }

    func cancelQueuedScene() {
        guard let slot = queuedSceneSlot else { return }
        queuedSceneSlot = nil
        status = "Canceled Scene \(slot + 1) launch"
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
        feedbackSimulatorMode = scene.feedbackSimulatorMode
        feedbackSimulatorIntensity = scene.feedbackSimulatorIntensity
        feedbackSimulatorDecay = scene.feedbackSimulatorDecay
        feedbackSimulatorZoom = scene.feedbackSimulatorZoom
        feedbackSimulatorTwist = scene.feedbackSimulatorTwist
        feedbackSimulatorDisplacement = scene.feedbackSimulatorDisplacement
        feedbackSimulatorPrism = scene.feedbackSimulatorPrism
        feedbackSimulatorAudioReactive = scene.feedbackSimulatorAudioReactive
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
        activeSceneSlot = slot
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
            let to = sceneDeck[sceneMorphToSlot],
            sceneMorphFromSlot != sceneMorphToSlot
        else {
            status = "Choose two saved scene slots before morphing"
            return
        }

        applySceneMorph(from: from, to: to, amount: sceneMorphAmount)
        activeSceneSlot = nil
        status = "Morphed Scene \(sceneMorphFromSlot + 1) -> \(sceneMorphToSlot + 1) \(Int(sceneMorphAmount * 100))%"
    }

    func setSceneMorphEndpoint(_ endpoint: Int, slot: Int) {
        guard sceneDeck.indices.contains(slot) else { return }

        if endpoint == 0 {
            sceneMorphFromSlot = slot
        } else {
            sceneMorphToSlot = slot
        }

        guard sceneDeck[slot] != nil else {
            sceneMorphAmount = 0.0
            status = "Save Scene \(slot + 1) before morphing"
            return
        }

        if endpoint == 0 {
            if sceneMorphToSlot == slot {
                sceneMorphToSlot = fallbackMorphSlot(excluding: slot) ?? sceneMorphToSlot
            }
        } else {
            if sceneMorphFromSlot == slot {
                sceneMorphFromSlot = fallbackMorphSlot(excluding: slot) ?? sceneMorphFromSlot
            }
        }

        if sceneMorphFromSlot == sceneMorphToSlot {
            sceneMorphAmount = 0.0
            status = "Choose two different scene slots before morphing"
        }
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
        activeSceneSlot = sceneDeck.indices.last
        queuedSceneSlot = nil
        sceneMorphFromSlot = 0
        sceneMorphToSlot = sceneDeck.indices.contains(1) ? 1 : 0
        status = "Generated 8-scene performance deck"
    }

    private func repairSceneMorphEndpoints() {
        if sceneDeck.indices.contains(sceneMorphFromSlot), sceneDeck[sceneMorphFromSlot] != nil,
           sceneDeck.indices.contains(sceneMorphToSlot), sceneDeck[sceneMorphToSlot] != nil,
           sceneMorphFromSlot != sceneMorphToSlot {
            return
        }

        let savedSlots = sceneDeck.indices.filter { sceneDeck[$0] != nil }
        sceneMorphFromSlot = savedSlots.first ?? 0
        sceneMorphToSlot = savedSlots.dropFirst().first ?? sceneMorphFromSlot
        sceneMorphAmount = 0.0
    }

    private func fallbackMorphSlot(excluding slot: Int) -> Int? {
        sceneDeck.indices.first { $0 != slot && sceneDeck[$0] != nil }
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

    func applyVisualizerSynth() {
        audioVisualizerMode = .polyphonicLoom
        audioVisualizerIntensity = 0.78
        audioVisualizerDetail = 0.72
        audioVisualizerPersistence = 0.56
        lightSynthIntensity = min(1.0, max(lightSynthIntensity, 0.68))
        bloom = min(0.58, max(bloom, 0.36))
        flashSafety = true
        status = "Synth visualizer enabled"
    }

    func applyMusicSyncedPerformance() {
        audioVisualizerMode = .psychedelicKaleidoscope
        audioVisualizerIntensity = 0.86
        audioVisualizerDetail = 0.82
        audioVisualizerPersistence = 0.62
        lightSynthMode = .everything
        lightSynthIntensity = min(1.0, max(lightSynthIntensity, 0.78))
        bassVoice.chorus = 0.24
        bassVoice.sidechain = 0.58
        bassVoice.shimmer = 0.04
        leadVoice.chorus = 0.56
        leadVoice.shimmer = 0.34
        leadVoice.sidechain = 0.34
        psychedelicFieldMode = .everything
        psychedelicFieldIntensity = min(1.0, max(psychedelicFieldIntensity, 0.86))
        status = "Music-synced performance enabled"
        pushAudioState()
    }

    func applyModernVisualFoundation() {
        activeSceneSlot = nil
        queuedSceneSlot = nil
        visualEngineMode = .auroraFluid
        lightSynthMode = .neuralMandala
        lightSynthIntensity = 0.76
        audioVisualizerMode = .spectralConductor
        audioVisualizerIntensity = 0.90
        audioVisualizerDetail = 0.86
        audioVisualizerPersistence = 0.64
        gpuVisualizerBackend = .metal
        metalVisualizerEffectMode = .fractalBloom
        metalVisualizerEffectIntensity = 0.88
        metalVisualizerEffectSpeed = 0.82
        psychedelicFieldMode = .liquidFractal
        psychedelicFieldIntensity = 0.88
        psychedelicFieldMotion = 0.86
        paletteMode = .colourspace
        blendMode = .screen
        demosceneEffectMode = .off
        minterEffectMode = .off
        holographicMode = .off
        experimentalVideoMode = .clean
        feedbackSimulatorMode = .off
        status = "Modern music visualizer enabled"
    }

    func applyPsychedelic4KVisualizer() {
        applyModernVisualFoundation()
        recordingResolution = .fourK
        recordingFPS = 30
        audioVisualizerMode = .psychedelicKaleidoscope
        audioVisualizerIntensity = 0.94
        audioVisualizerDetail = 1.0
        audioVisualizerPersistence = 0.76
        psychedelicFieldMode = .everything
        psychedelicFieldIntensity = 0.90
        psychedelicFieldMotion = 0.92
        metalVisualizerEffectMode = .psychedelicPlasma
        metalVisualizerEffectIntensity = 0.92
        metalVisualizerEffectSpeed = 0.90
        status = "4K psychedelic visualizer enabled"
    }

    func apply4KMasterOutput() {
        recordingResolution = .fourK
        recordingFPS = 30
        psychedelicFieldMode = .everything
        psychedelicFieldIntensity = max(psychedelicFieldIntensity, 0.86)
        psychedelicFieldMotion = max(psychedelicFieldMotion, 0.84)
        visualOutputGain = min(0.94, max(visualOutputGain, 0.84))
        status = "4K master output configured"
    }

    func applyVertical4KMasterOutput() {
        recordingResolution = .vertical4K
        recordingFPS = 30
        psychedelicFieldMode = .everything
        psychedelicFieldIntensity = max(psychedelicFieldIntensity, 0.86)
        psychedelicFieldMotion = max(psychedelicFieldMotion, 0.84)
        visualOutputGain = min(0.94, max(visualOutputGain, 0.84))
        status = "Vertical 4K master output configured"
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
            feedbackSimulatorMode: feedbackSimulatorMode,
            feedbackSimulatorIntensity: feedbackSimulatorIntensity,
            feedbackSimulatorDecay: feedbackSimulatorDecay,
            feedbackSimulatorZoom: feedbackSimulatorZoom,
            feedbackSimulatorTwist: feedbackSimulatorTwist,
            feedbackSimulatorDisplacement: feedbackSimulatorDisplacement,
            feedbackSimulatorPrism: feedbackSimulatorPrism,
            feedbackSimulatorAudioReactive: feedbackSimulatorAudioReactive,
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
        feedbackSimulatorMode = chooseTo ? to.feedbackSimulatorMode : from.feedbackSimulatorMode
        feedbackSimulatorAudioReactive = chooseTo ? to.feedbackSimulatorAudioReactive : from.feedbackSimulatorAudioReactive
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
        feedbackSimulatorIntensity = lerp(from.feedbackSimulatorIntensity, to.feedbackSimulatorIntensity, amount)
        feedbackSimulatorDecay = lerp(from.feedbackSimulatorDecay, to.feedbackSimulatorDecay, amount)
        feedbackSimulatorZoom = lerp(from.feedbackSimulatorZoom, to.feedbackSimulatorZoom, amount)
        feedbackSimulatorTwist = lerp(from.feedbackSimulatorTwist, to.feedbackSimulatorTwist, amount)
        feedbackSimulatorDisplacement = lerp(from.feedbackSimulatorDisplacement, to.feedbackSimulatorDisplacement, amount)
        feedbackSimulatorPrism = lerp(from.feedbackSimulatorPrism, to.feedbackSimulatorPrism, amount)
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
            limiterRelease: limiterRelease,
            vocoder: vocoder
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
            audioVisualizerMode: audioVisualizerMode,
            audioVisualizerIntensity: audioVisualizerIntensity,
            audioVisualizerDetail: audioVisualizerDetail,
            audioVisualizerPersistence: audioVisualizerPersistence,
            psychedelicFieldMode: psychedelicFieldMode,
            psychedelicFieldIntensity: psychedelicFieldIntensity,
            psychedelicFieldMotion: psychedelicFieldMotion,
            experimentalVideoMode: experimentalVideoMode,
            experimentalVideoIntensity: experimentalVideoIntensity,
            videoKeyThreshold: videoKeyThreshold,
            videoEdgeGain: videoEdgeGain,
            videoColorWarp: videoColorWarp,
            videoOscillatorRate: videoOscillatorRate,
            feedbackSimulatorMode: feedbackSimulatorMode,
            feedbackSimulatorIntensity: feedbackSimulatorIntensity,
            feedbackSimulatorDecay: feedbackSimulatorDecay,
            feedbackSimulatorZoom: feedbackSimulatorZoom,
            feedbackSimulatorTwist: feedbackSimulatorTwist,
            feedbackSimulatorDisplacement: feedbackSimulatorDisplacement,
            feedbackSimulatorPrism: feedbackSimulatorPrism,
            feedbackSimulatorAudioReactive: feedbackSimulatorAudioReactive,
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
