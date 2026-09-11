import Foundation
import SwiftUI

enum InspectorPanel: String, CaseIterable, Identifiable {
    case studio = "Studio"
    case presets = "Presets"
    case sequencer = "Sequencer"
    case synth = "Synth"
    case delayFX = "Delay FX"
    case drums = "Drums"
    case keyboard = "48-Key Keyboard"
    case lightSynth = "Light Synth"
    case feedbackCamera = "Feedback / Camera"
    case broadcast = "Broadcast"
    case performance = "Performance"
    case output = "Output"

    var id: String { rawValue }
}

enum TempoMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case goldenPhi = "Golden Phi"

    var id: String { rawValue }
}

enum PresetFamily: String, CaseIterable, Identifiable {
    case all = "All"
    case tunnel = "Tunnel"
    case mandala = "Mandala"
    case liquid = "Liquid"
    case laser = "Laser"
    case cellular = "Cellular"
    case demoscene = "Demoscene"
    case cosmic = "Cosmic"
    case minter = "Minter"
    case holographic = "Holographic"

    var id: String { rawValue }
}

enum HolographicMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case ghostPrism = "Ghost Prism"
    case scanVolume = "Scan Volume"
    case chromaDepth = "Chroma Depth"
    case interference = "Interference"
    case pepperGhost = "Pepper Ghost Stage"
    case lightField = "Light Field Volume"
    case cghSpeckle = "CGH Speckle"
    case realisticStack = "Realistic Stack"

    var id: String { rawValue }
}

enum MinterEffectMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case psychedeliaGrid = "Psychedelia Grid"
    case colourspaceFlow = "Colourspace Flow"
    case vlmNeon = "VLM Neon"
    case tempestWeb = "Tempest Web"
    case polybiusTunnel = "Polybius Tunnel"
    case gridrunnerLattice = "Gridrunner Lattice"
    case spaceGiraffeWeb = "Space Giraffe Web"
    case txkVectorBloom = "TxK Vector Bloom"
    case neonLoopz = "Neon Loopz"
    case llamaTronTrails = "LlamaTron Trails"
    case neonStampede = "Neon Stampede"
    case yakLaserGrid = "Yak Laser Grid"
    case llamaFeedback = "Llama Feedback"
    case arcadeVortex = "Arcade Vortex"

    var id: String { rawValue }
}

enum DemosceneEffectMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case copperBars = "Amiga Copper Bars"
    case plasma = "VGA Plasma"
    case rotoZoom = "Rotozoomer"
    case vectorBalls = "Vector Balls"
    case starTunnel = "Star Tunnel"
    case sineScroller = "Sine Scroller"
    case chunkyVGA = "Chunky VGA"
    case moireTunnel = "Moire Tunnel"
    case bitplaneStorm = "Bitplane Storm"
    case rasterInterference = "Raster Interference"
    case shadeBobs = "Shadebobs"
    case twister = "Twister"
    case mandelZoom = "Mandel Zoom"
    case voxelLandscape = "Voxel Landscape"
    case megaDemo = "Mega Demo"

    var id: String { rawValue }
}

enum LightSynthMode: String, CaseIterable, Identifiable {
    case hyperPrism = "Hyper Prism"
    case lissajousLaser = "Lissajous Laser"
    case recursiveBloom = "Recursive Bloom"
    case acidScope = "Acid Scope"
    case photonStorm = "Photon Storm"
    case neuralMandala = "Neural Mandala"
    case everything = "Everything"

    var id: String { rawValue }
}

enum AudioVisualizerMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case spectrumTunnel = "Spectrum Tunnel"
    case oscilloscopeGarden = "Oscilloscope Garden"
    case chromaVectorscope = "Chroma Vectorscope"
    case spectralParticles = "Spectral Particles"
    case feedbackWaveform = "Feedback Waveform"
    case spectralLattice = "Spectral Lattice"
    case phaseBloom = "Phase Bloom"
    case polyphonicLoom = "Polyphonic Loom"
    case sequencerMatrix = "Sequencer Matrix"
    case harmonicOrbits = "Harmonic Orbits"
    case granularBloom = "Granular Bloom"
    case spectralConductor = "Spectral Conductor"
    case hyperAnalyzer = "Hyper Analyzer"

    var id: String { rawValue }
}

enum GPUVisualizerBackend: String, CaseIterable, Identifiable {
    case metal = "Metal GPU"
    case openGL = "OpenGL Legacy"
    case canvasOnly = "Canvas Only"

    var id: String { rawValue }
}

enum MetalVisualizerEffectMode: String, CaseIterable, Identifiable {
    case analyzer = "Analyzer Overlay"
    case introFade = "Intro Fade"
    case dissolvePortal = "Dissolve Portal"
    case psychedelicPlasma = "Psychedelic Plasma"
    case fractalBloom = "Fractal Bloom"
    case feedbackCathedral = "Feedback Cathedral"

    var id: String { rawValue }

    var shaderIndex: Float {
        switch self {
        case .analyzer: return 0
        case .introFade: return 1
        case .dissolvePortal: return 2
        case .psychedelicPlasma: return 3
        case .fractalBloom: return 4
        case .feedbackCathedral: return 5
        }
    }
}

enum PsychedelicFieldMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case chromaFlood = "Chroma Flood"
    case prismStorm = "Prism Storm"
    case liquidFractal = "Liquid Fractal"
    case everything = "Full Spectrum"

    var id: String { rawValue }
}

enum LightPaletteMode: String, CaseIterable, Identifiable {
    case neon = "Neon"
    case colourspace = "Colourspace"
    case yakNeon = "Yak Neon"
    case phosphor = "Phosphor"
    case laserium = "Laserium"
    case acid = "Acid"
    case ultraviolet = "Ultraviolet"
    case infrared = "Infrared"
    case ice = "Ice"
    case monochrome = "Monochrome"
    case rainbow = "Rainbow"
    case amber = "Amber"

    var id: String { rawValue }
}

enum LightBlendMode: String, CaseIterable, Identifiable {
    case additive = "Additive"
    case screen = "Screen"
    case softKey = "Soft Key"
    case hardKey = "Hard Key"
    case difference = "Difference"

    var id: String { rawValue }
}

enum VisualEngineMode: String, CaseIterable, Identifiable {
    case lightTunnel = "Light Tunnel"
    case vectorField = "Vector Field"
    case metaballs = "Metaballs"
    case terrainGrid = "Terrain Grid"
    case oscilloscopeRibbons = "Oscilloscope Ribbons"
    case fractalLightning = "Fractal Lightning"
    case fractalTrees = "Fractal Trees"
    case particleNebula = "Particle Nebula"
    case shapeConstellation = "Shape Constellation"
    case liquidCells = "Liquid Cells"
    case auroraFluid = "Aurora Fluid"
    case reactionDiffusion = "Reaction Diffusion"
    case kaleidoscopeMaze = "Kaleidoscope Maze"
    case moireField = "Moire Field"
    case slitScanRibbons = "Slit-Scan Ribbons"
    case cellularAutomata = "Cellular Automata"
    case engineAutopilot = "Engine Autopilot"

    var id: String { rawValue }
}

enum ExperimentalVideoMode: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case colourspace = "Colourspace"
    case neonPulse = "Neon Pulse"
    case slitScan = "Slit Scan"
    case videoFeedback = "Video Feedback"
    case chromaticAberration = "Chromatic Aberration"
    case datamoshBlocks = "Datamosh Blocks"
    case vhsMelt = "VHS Melt"
    case demosceneStack = "Demoscene Stack"
    case lumaKeyBloom = "Luma Key Bloom"
    case chromaInvert = "Chroma Invert"
    case edgeTrace = "Edge Trace"
    case oscillatorBank = "Oscillator Bank"
    case vectorScope = "Vector Scope"
    case scanGate = "Scan Gate"
    case pixelSortTrails = "Pixel Sort Trails"
    case codecTear = "Codec Tear"
    case rgbDelay = "RGB Delay"
    case halftonePosterize = "Halftone Posterize"
    case opticalFlowSmear = "Optical Flow Smear"
    case recursiveMirror = "Recursive Mirror"
    case liquidLens = "Liquid Lens"
    case kaleidoFeedback = "Kaleido Feedback"
    case solarizedContours = "Solarized Contours"
    case phosphorBurn = "Phosphor Burn"
    case tunnelFold = "Tunnel Fold"
    case chromaLightLeaks = "Chroma Light Leaks"

    var id: String { rawValue }
}

enum RecordingResolution: String, CaseIterable, Identifiable {
    case n360 = "640 x 360"
    case sd480 = "854 x 480"
    case hd720 = "1280 x 720"
    case fullHD = "1920 x 1080"
    case qhd = "2560 x 1440"
    case square = "1080 x 1080"
    case socialPortrait = "1080 x 1350"
    case vertical = "1080 x 1920"
    case ultrawide = "1920 x 816"
    case ultrawideQHD = "2560 x 1080"
    case fourK = "3840 x 2160"
    case vertical4K = "2160 x 3840"

    var id: String { rawValue }

    var size: (width: Int, height: Int) {
        switch self {
        case .n360:
            return (640, 360)
        case .sd480:
            return (854, 480)
        case .hd720:
            return (1280, 720)
        case .fullHD:
            return (1920, 1080)
        case .qhd:
            return (2560, 1440)
        case .square:
            return (1080, 1080)
        case .socialPortrait:
            return (1080, 1350)
        case .vertical:
            return (1080, 1920)
        case .ultrawide:
            return (1920, 816)
        case .ultrawideQHD:
            return (2560, 1080)
        case .fourK:
            return (3840, 2160)
        case .vertical4K:
            return (2160, 3840)
        }
    }
}

enum CameraFeedbackMode: String, CaseIterable, Identifiable {
    case optical = "Optical Screen Loop"
    case echoTunnel = "Echo Tunnel"
    case slitEcho = "Slit Echo"
    case lumaKey = "Luma Key Overlay"
    case chromaWash = "Chroma Wash"

    var id: String { rawValue }
}

enum FeedbackSimulatorMode: String, CaseIterable, Identifiable, Hashable {
    case off = "Off"
    case opticalTunnel = "Optical Tunnel"
    case prismHall = "Prism Hall"
    case lumaBloomMemory = "Luma Bloom Memory"
    case chromaWarpField = "Chroma Warp Field"
    case scanlineMemory = "Scanline Memory"
    case mirrorLabyrinth = "Mirror Labyrinth"
    case crtCameraLoop = "CRT Camera Loop"
    case glassMonitorStack = "Glass Monitor Stack"
    case tapeHeadEcho = "Tape Head Echo"
    case surveillanceWall = "Surveillance Wall"
    case feedbackLab = "Feedback Lab"

    var id: String { rawValue }
}

enum SceneLaunchQuantization: String, CaseIterable, Identifiable {
    case immediate = "Immediate"
    case nextBeat = "Next Beat"
    case nextBar = "Next Bar"
    case fourBars = "4 Bars"

    var id: String { rawValue }

    var beatInterval: Int {
        switch self {
        case .immediate:
            return 0
        case .nextBeat:
            return 1
        case .nextBar:
            return 4
        case .fourBars:
            return 16
        }
    }

    var shortLabel: String {
        switch self {
        case .immediate:
            return "Now"
        case .nextBeat:
            return "Beat"
        case .nextBar:
            return "Bar"
        case .fourBars:
            return "4 Bars"
        }
    }
}

enum AutopilotSource: String, CaseIterable, Identifiable {
    case presets = "Preset List"
    case sceneDeck = "Scene Deck"

    var id: String { rawValue }
}

enum DeckTravelMode: String, CaseIterable, Identifiable {
    case forward = "Forward"
    case pingPong = "Ping-Pong"
    case random = "Random"

    var id: String { rawValue }
}

enum GrooveFXMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case fourOnFloor = "4-on-the-floor Pump"
    case eighths = "Eighth Pump"
    case triplets = "Triplet Pump"
    case syncopated = "Syncopated Gate"

    var id: String { rawValue }
}

struct VideoPerformancePreset: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var visualEngine: VisualEngineMode
    var demosceneMode: DemosceneEffectMode
    var minterMode: MinterEffectMode
    var palette: LightPaletteMode
    var videoMode: ExperimentalVideoMode
    var resolution: RecordingResolution
    var frameRate: Int
    var intensity: Double
}

enum StereoscopicMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case anaglyph = "Red/Cyan Anaglyph"
    case sideBySide = "Side-by-Side"
    case topBottom = "Top/Bottom"
    case lineInterlace = "Line Interlace"
    case depthGhost = "Depth Ghost"

    var id: String { rawValue }
}

struct LightSceneSnapshot: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var preset: VisualPreset
    var lightSynthMode: LightSynthMode
    var paletteMode: LightPaletteMode
    var blendMode: LightBlendMode
    var macroX: Double
    var macroY: Double
    var intensity: Double
    var phosphorPersistence: Double
    var prismSplits: Int
    var demosceneMode: DemosceneEffectMode
    var minterMode: MinterEffectMode
    var holographicMode: HolographicMode
    var experimentalVideoMode: ExperimentalVideoMode
    var experimentalVideoIntensity: Double
    var videoKeyThreshold: Double
    var videoEdgeGain: Double
    var videoColorWarp: Double
    var videoOscillatorRate: Double
    var feedbackSimulatorMode: FeedbackSimulatorMode
    var feedbackSimulatorIntensity: Double
    var feedbackSimulatorDecay: Double
    var feedbackSimulatorZoom: Double
    var feedbackSimulatorTwist: Double
    var feedbackSimulatorDisplacement: Double
    var feedbackSimulatorPrism: Double
    var feedbackSimulatorAudioReactive: Bool
    var cameraFeedbackMode: CameraFeedbackMode
    var cameraOverlayOpacity: Double
    var cameraFeedbackAmount: Double
    var cameraOverlayScale: Double
    var cameraFeedbackRotation: Double
    var cameraLumaThreshold: Double
    var cameraChromaShift: Double
    var cameraMirror: Bool
}

struct PatternSnapshot: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var sequencer: SequencerState
    var bassVoice: SynthVoice
    var leadVoice: SynthVoice
    var delaySettings: MultiTapDelaySettings
    var mixer: AudioMixerState
}

struct MinterPresetProfile: Hashable {
    var minterMode: MinterEffectMode
    var visualEngine: VisualEngineMode
    var lightMode: LightSynthMode
    var palette: LightPaletteMode
    var blend: LightBlendMode
    var demosceneMode: DemosceneEffectMode
    var holographicMode: HolographicMode
    var intensity: Double
    var prismSplits: Int
}

struct DelayTap: Identifiable, Hashable {
    let id = UUID()
    var enabled: Bool
    var beatOffset: Double
    var level: Double
    var feedback: Double
    var visualSpread: Double
}

struct MultiTapDelaySettings: Hashable {
    var enabled = true
    var wet = 0.38
    var globalFeedback = 0.28
    var visualDelayEnabled = true
    var visualEchoOpacity = 0.42
    var taps: [DelayTap] = [
        DelayTap(enabled: true, beatOffset: 0.25, level: 0.34, feedback: 0.22, visualSpread: 0.12),
        DelayTap(enabled: true, beatOffset: 0.50, level: 0.28, feedback: 0.18, visualSpread: 0.24),
        DelayTap(enabled: true, beatOffset: 0.75, level: 0.22, feedback: 0.14, visualSpread: 0.36),
        DelayTap(enabled: true, beatOffset: 1.00, level: 0.18, feedback: 0.10, visualSpread: 0.48),
        DelayTap(enabled: false, beatOffset: 1.50, level: 0.15, feedback: 0.08, visualSpread: 0.60),
        DelayTap(enabled: false, beatOffset: 2.00, level: 0.12, feedback: 0.06, visualSpread: 0.72)
    ]
}

struct AudioMeterSnapshot: Hashable {
    var peakLeft = 0.0
    var peakRight = 0.0
    var limiterReduction = 0.0
    var limitedFrames = 0
    var bass = 0.0
    var mid = 0.0
    var treble = 0.0
    var transient = 0.0
    var spectralFlux = 0.0
    var spectralCentroid = 0.0
    var stereoBalance = 0.0
    var rhythmicPulse = 0.0
    var harmonicEnergy = 0.0
}

enum BroadcastTarget: String, CaseIterable, Identifiable {
    case youtube = "YouTube Live"
    case facebook = "Facebook Live"
    case custom = "Custom RTMP"

    var id: String { rawValue }

    var defaultURL: String {
        switch self {
        case .youtube:
            return "rtmps://a.rtmps.youtube.com/live2"
        case .facebook:
            return "rtmps://live-api-s.facebook.com:443/rtmp"
        case .custom:
            return "rtmp://"
        }
    }

    var recommendedFrameRate: Int {
        switch self {
        case .facebook:
            return 30
        case .youtube, .custom:
            return 30
        }
    }

    var recommendedBitrateKbps: Int {
        switch self {
        case .facebook:
            return 4500
        case .youtube, .custom:
            return 6000
        }
    }

    var recommendedResolution: RecordingResolution {
        switch self {
        case .facebook:
            return .hd720
        case .youtube, .custom:
            return .hd720
        }
    }

    var recommendedAudioSampleRate: Int {
        switch self {
        case .facebook:
            return 44100
        case .youtube, .custom:
            return 48000
        }
    }

    var recommendedAudioBitrate: String {
        switch self {
        case .facebook:
            return "128k"
        case .youtube, .custom:
            return "192k"
        }
    }
}

enum BroadcastSourceMode: String, CaseIterable, Identifiable {
    case trueLive = "True Live Output"
    case latestRecordingLoop = "Loop Latest MP4"

    var id: String { rawValue }
}

enum BroadcastAudioMode: String, CaseIterable, Identifiable {
    case desktopStereoMix = "Desktop Stereo Mix"
    case silent = "Silent"

    var id: String { rawValue }
}

struct BroadcastSettings: Hashable {
    var target: BroadcastTarget = .youtube
    var sourceMode: BroadcastSourceMode = .trueLive
    var audioMode: BroadcastAudioMode = .desktopStereoMix
    var audioDeviceName = "BlackHole 2ch"
    var ingestURL = BroadcastTarget.youtube.defaultURL
    var streamKey = ""
    var bitrateKbps = 6000
    var frameRate = 30
    var loopLatestRecording = true
    var facebookCompatibilityMode = true
}

enum ModSource: String, CaseIterable, Identifiable {
    case lfo = "LFO Sine"
    case triangle = "LFO Triangle"
    case beat = "Beat Phase"
    case bass = "Bass Energy"
    case noise = "Noise Drift"

    var id: String { rawValue }
}

enum ModDestination: String, CaseIterable, Identifiable {
    case warp = "Warp"
    case hue = "Hue"
    case zoom = "Zoom"
    case feedback = "Feedback"
    case strobes = "Strobes"

    var id: String { rawValue }
}

struct VisualPreset: Identifiable, Hashable {
    let id: Int
    let name: String
    let family: PresetFamily
    let colorA: Color
    let colorB: Color
    let colorC: Color
    let density: Double
    let warp: Double
    let feedback: Double
    let symmetry: Int
    let strobe: Double
}

struct ModSlot: Identifiable, Hashable {
    let id = UUID()
    var enabled = false
    var source: ModSource = .lfo
    var destination: ModDestination = .warp
    var amount = 0.35
    var rate = 0.25
}

struct MixerChannel: Hashable {
    var level = 0.8
    var pan = 0.0
    var send = 0.3
    var muted = false
    var solo = false
}

struct AudioMixerState: Hashable {
    var bass = MixerChannel(level: 0.82, pan: -0.14, send: 0.24)
    var lead = MixerChannel(level: 0.72, pan: 0.12, send: 0.34)
    var drums = MixerChannel(level: 0.86, pan: 0.0, send: 0.18)
    var liveKeys = MixerChannel(level: 0.68, pan: 0.0, send: 0.30)
    var fxReturn = MixerChannel(level: 0.42, pan: 0.0, send: 0.0)
}

struct GrooveFXState: Hashable {
    var mode: GrooveFXMode = .off
    var amount = 0.38
    var curve = 0.58
    var stereoSkew = 0.18
}

struct SynthVoice: Hashable {
    var instrument: SynthInstrument = .acidSaw
    var enabled = true
    var level = 0.45
    var octave = 2
    var cutoff = 0.55
    var resonance = 0.25
    var glide = 0.12
    var accent = 0.55
    var attack = 0.02
    var decay = 0.46
    var sustain = 0.18
    var drive = 0.24
    var filterEnvelope = 0.42
    var lfoRate = 0.18
    var lfoAmount = 0.16
    var morph = 0.50
    var unison = 0.18
    var detune = 0.16
    var subLevel = 0.20
    var noiseLevel = 0.04
    var fmAmount = 0.28
    var wavefold = 0.12
    var grainSize = 0.32
    var grainDensity = 0.44
    var bitcrush = 0.0
    var chorus = 0.18
    var shimmer = 0.08
    var sidechain = 0.24
}

struct SynthVoicePreset: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var voice: SynthVoice
}

enum SynthInstrument: String, CaseIterable, Identifiable, Hashable {
    case acidSaw = "Acid Saw"
    case subSquare = "Sub Square"
    case superSaw = "Super Saw"
    case fmBell = "FM Bell"
    case glassPad = "Glass Pad"
    case noiseOrgan = "Noise Organ"
    case syncLead = "Sync Lead"
    case formantVox = "Formant Vox"
    case wavetableMorph = "Wavetable Morph"
    case granularCloud = "Granular Cloud"
    case reeseBass = "Reese Bass"
    case phaseDistortion = "Phase Distortion"
    case ringModKeys = "Ring Mod Keys"
    case karplusPluck = "Karplus Pluck"
    case bitcrushLead = "Bitcrush Lead"
    case spectralDrone = "Spectral Drone"
    case buchlaComplex = "Buchla Complex"
    case mellotronTape = "Mellotron Tape"
    case solinaStringer = "Solina Stringer"
    case synclavierDigital = "Synclavier Digital"
    case vectorMorph = "Vector Morph"

    var id: String { rawValue }
}

enum GrooveTemplate: String, CaseIterable, Identifiable, Hashable {
    case straight = "Straight"
    case mpcShuffle = "MPC Shuffle"
    case brokenBeat = "Broken Beat"
    case electroPush = "Electro Push"
    case garageSkip = "Garage Skip"
    case dillaDrift = "Dilla Drift"

    var id: String { rawValue }
}

enum CompositionStyle: String, CaseIterable, Identifiable, Hashable {
    case acidLab = "Acid Lab"
    case berlinSchool = "Berlin School"
    case psychedelicTrance = "Psychedelic Trance"
    case dubMutation = "Dub Mutation"
    case kosmischeAmbient = "Kosmische Ambient"
    case electroBreaks = "Electro Breaks"
    case generativeRaga = "Generative Raga"

    var id: String { rawValue }
}

enum SequencerScale: String, CaseIterable, Identifiable, Hashable {
    case chromatic = "Chromatic"
    case minorPentatonic = "Minor Pentatonic"
    case dorian = "Dorian"
    case phrygian = "Phrygian"
    case harmonicMinor = "Harmonic Minor"
    case lydian = "Lydian"
    case hirajoshi = "Hirajoshi"
    case pelog = "Pelog"
    case octatonic = "Octatonic"
    case wholeTone = "Whole Tone"

    var id: String { rawValue }

    var degrees: [Int] {
        switch self {
        case .chromatic:
            return Array(0..<12)
        case .minorPentatonic:
            return [0, 3, 5, 7, 10]
        case .dorian:
            return [0, 2, 3, 5, 7, 9, 10]
        case .phrygian:
            return [0, 1, 3, 5, 7, 8, 10]
        case .harmonicMinor:
            return [0, 2, 3, 5, 7, 8, 11]
        case .lydian:
            return [0, 2, 4, 6, 7, 9, 11]
        case .hirajoshi:
            return [0, 2, 3, 7, 8]
        case .pelog:
            return [0, 1, 3, 7, 8]
        case .octatonic:
            return [0, 2, 3, 5, 6, 8, 9, 11]
        case .wholeTone:
            return [0, 2, 4, 6, 8, 10]
        }
    }
}

struct StepLane: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var steps: [Bool]
    var notes: [Int]
    var velocities: [Double]
    var probabilities: [Double]
    var ratchets: [Int]
    var length: Int

    init(name: String, steps: [Bool], notes: [Int]? = nil, velocities: [Double]? = nil, probabilities: [Double]? = nil, ratchets: [Int]? = nil, length: Int? = nil) {
        self.name = name
        self.steps = steps
        self.notes = Self.normalized(notes ?? Array(repeating: 0, count: steps.count), fallback: 0, count: steps.count)
        self.velocities = Self.normalized(velocities ?? Array(repeating: 0.82, count: steps.count), fallback: 0.82, count: steps.count).map { min(1.0, max(0.05, $0)) }
        self.probabilities = Self.normalized(probabilities ?? Array(repeating: 1.0, count: steps.count), fallback: 1.0, count: steps.count).map { min(1.0, max(0.0, $0)) }
        self.ratchets = Self.normalized(ratchets ?? Array(repeating: 1, count: steps.count), fallback: 1, count: steps.count).map { min(8, max(1, $0)) }
        self.length = min(steps.count, max(1, length ?? steps.count))
    }

    mutating func normalize() {
        notes = Self.normalized(notes, fallback: 0, count: steps.count)
        velocities = Self.normalized(velocities, fallback: 0.82, count: steps.count).map { min(1.0, max(0.05, $0)) }
        probabilities = Self.normalized(probabilities, fallback: 1.0, count: steps.count).map { min(1.0, max(0.0, $0)) }
        ratchets = Self.normalized(ratchets, fallback: 1, count: steps.count).map { min(8, max(1, $0)) }
        length = min(steps.count, max(1, length))
    }

    private static func normalized<T>(_ values: [T], fallback: T, count: Int) -> [T] {
        if values.count == count { return values }
        if values.count > count { return Array(values.prefix(count)) }
        return values + Array(repeating: fallback, count: count - values.count)
    }
}

struct SequencerState: Hashable {
    var isPlaying = true
    var bpm = 132.0
    var swing = 0.0
    var groove: GrooveTemplate = .straight
    var humanize = 0.0
    var mutationAmount = 0.20
    var compositionStyle: CompositionStyle = .psychedelicTrance
    var generativeDensity = 0.62
    var phraseVariation = 0.38
    var scale: SequencerScale = .minorPentatonic
    var rootNote = 0
    var patternLength = 16
    var bass = StepLane(
        name: "Acid Bass",
        steps: [true, false, false, true, false, true, false, false, true, false, true, false, false, true, false, true],
        notes: [0, 0, 3, 7, 0, 10, 7, 3, 0, 0, 12, 10, 7, 3, 0, 10]
    )
    var lead = StepLane(
        name: "Space Lead",
        steps: [false, true, false, false, true, false, true, false, false, false, true, false, true, false, false, true],
        notes: [12, 15, 19, 22, 24, 22, 19, 15, 12, 15, 19, 27, 24, 22, 19, 15]
    )
    var kick = StepLane(name: "Kick", steps: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false])
    var snare = StepLane(name: "Snare", steps: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false])
    var hat = StepLane(name: "Hat", steps: [false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false])
    var clap = StepLane(name: "Clap", steps: [false, false, false, false, true, false, false, true, false, false, false, false, true, false, false, true])
}

struct DrumPreset: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var kick: [Bool]
    var snare: [Bool]
    var hat: [Bool]
    var clap: [Bool]
}

extension Color {
    static func hsba(_ hue: Double, _ saturation: Double, _ brightness: Double, _ opacity: Double = 1) -> Color {
        Color(hue: hue.truncatingRemainder(dividingBy: 1), saturation: saturation, brightness: brightness, opacity: opacity)
    }
}
