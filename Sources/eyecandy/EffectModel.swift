import CoreGraphics
import Foundation

enum PresetFamily: String, CaseIterable, Identifiable {
    case trueFeedback = "True Feedback"
    case hallOfMirrors = "Hall of Mirrors"
    case prismSimulator = "Prism Simulator"
    case chromaLuma = "Chroma + Luma"
    case kaleidoscope = "Kaleidoscope"
    case plasmaTunnel = "Plasma Tunnel"
    case rasterRoto = "Raster + Rotozoom"
    case xorMoire = "XOR + Moire"
    case fractalBloom = "Fractal Bloom"
    case parallelUniverse = "Parallel Universe"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .trueFeedback:
            return "CRT recursion, scanline glow, rolling monitor collapse."
        case .hallOfMirrors:
            return "Laser-corridor reflections, mirror locks, cathedral echoes."
        case .prismSimulator:
            return "Refraction stacks, spectral faceting, optic splitting."
        case .chromaLuma:
            return "Color/luma ritualism, keyed brightness, chromatic tears."
        case .kaleidoscope:
            return "Symmetry engines, radial folds, mandala recursion."
        case .plasmaTunnel:
            return "Demoscene plasma, polar tunnels, liquid motion fields."
        case .rasterRoto:
            return "Raster bars, twister ribbons, pixel-roto turbulence."
        case .xorMoire:
            return "Interference lattices, xor grids, phase-shift delirium."
        case .fractalBloom:
            return "Iterative folds, bloom-heavy fields, strange attractor glow."
        case .parallelUniverse:
            return "Multi-echo viewers, portal drift, alternate signal layers."
        }
    }
}

enum InspectorTab: String, CaseIterable, Identifiable {
    case presets = "Presets"
    case feedback = "Feedback"
    case geometry = "Geometry"
    case color = "Color"
    case texture = "Texture"
    case audio = "Audio"
    case capture = "Capture"
    case live = "Live"

    var id: String { rawValue }
}

enum CaptureProfile: String, CaseIterable, Identifiable {
    case hd1080 = "1080p"
    case qhd1440 = "1440p"
    case uhd4K = "4K"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .hd1080:
            return CGSize(width: 1_920, height: 1_080)
        case .qhd1440:
            return CGSize(width: 2_560, height: 1_440)
        case .uhd4K:
            return CGSize(width: 3_840, height: 2_160)
        }
    }
}

enum ColorSpaceMode: Int, CaseIterable, Identifiable {
    case spectral
    case minterSynesthesia
    case prismIce
    case lavaChrome
    case lumaGhost

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .spectral:
            return "Spectral"
        case .minterSynesthesia:
            return "Minter Synesthesia"
        case .prismIce:
            return "Prism Ice"
        case .lavaChrome:
            return "Lava Chrome"
        case .lumaGhost:
            return "Luma Ghost"
        }
    }

    var shaderIndex: Float {
        Float(rawValue)
    }
}

struct EffectSettings: Equatable, Hashable, Sendable {
    var feedback: Float = 0.86
    var sourceMix: Float = 0.62
    var zoom: Float = 1.012
    var rotation: Float = 0.018
    var driftX: Float = 0.0
    var driftY: Float = 0.0
    var spiral: Float = 0.24
    var wobble: Float = 0.22
    var feedbackWarp: Float = 0.32
    var temporalJitter: Float = 0.12
    var beat: Float = 0.24
    var strobe: Float = 0.0

    var kaleidoscope: Float = 2.0
    var mirrorMix: Float = 0.22
    var facetMix: Float = 0.28
    var prism: Float = 0.18
    var prismCount: Float = 3.0
    var refraction: Float = 0.20
    var reflection: Float = 0.18
    var universe: Float = 0.12
    var pixelate: Float = 0.0
    var detail: Float = 0.58

    var hueShift: Float = 0.08
    var saturation: Float = 1.25
    var contrast: Float = 1.08
    var brightness: Float = 0.01
    var gamma: Float = 1.0
    var colorSpace: Float = ColorSpaceMode.spectral.shaderIndex
    var chromaSplit: Float = 0.006
    var lumaMix: Float = 0.28
    var invert: Float = 0.0

    var plasma: Float = 0.42
    var tunnel: Float = 0.18
    var twister: Float = 0.16
    var raster: Float = 0.12
    var rings: Float = 0.24
    var moire: Float = 0.14
    var fractal: Float = 0.16
    var noise: Float = 0.12
    var xorField: Float = 0.08
    var scanlines: Float = 0.18
    var grain: Float = 0.04
    var bloom: Float = 0.20
    var edgeGlow: Float = 0.14
    var vignette: Float = 0.10

    static let baseline = EffectSettings()
}

struct EffectPreset: Identifiable, Hashable {
    let id = UUID()
    let family: PresetFamily
    let name: String
    let summary: String
    let settings: EffectSettings
}

struct AudioSettings: Equatable, Sendable {
    var muted = false
    var reactive = true
    var reactivity: Float = 0.64
    var masterVolume: Float = 0.58
    var tempo: Float = 118.0
    var droneMix: Float = 0.42
    var pulseMix: Float = 0.34
    var percussionMix: Float = 0.26
    var shimmer: Float = 0.38
    var stereoWidth: Float = 0.44
}

struct AudioReactiveMetrics: Equatable, Hashable, Sendable {
    var level: Float
    var bass: Float
    var shimmer: Float
    var beatPhase: Float

    static let neutral = AudioReactiveMetrics(level: 0, bass: 0, shimmer: 0, beatPhase: 0)
}

struct SliderDescriptor: Identifiable {
    let id: String
    let title: String
    let keyPath: WritableKeyPath<EffectSettings, Float>
    let range: ClosedRange<Float>
    let step: Float
    let format: String
}

struct ControlSection: Identifiable {
    let id: String
    let title: String
    let descriptors: [SliderDescriptor]
}

enum ControlSchema {
    static let feedbackSections: [ControlSection] = [
        ControlSection(
            id: "loop",
            title: "Loop",
            descriptors: [
                SliderDescriptor(id: "feedback", title: "Feedback", keyPath: \.feedback, range: 0.0 ... 0.99, step: 0.001, format: "%.3f"),
                SliderDescriptor(id: "sourceMix", title: "Source Mix", keyPath: \.sourceMix, range: 0.0 ... 1.4, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "zoom", title: "Zoom", keyPath: \.zoom, range: 0.85 ... 1.18, step: 0.001, format: "%.3f"),
                SliderDescriptor(id: "rotation", title: "Rotation", keyPath: \.rotation, range: -0.32 ... 0.32, step: 0.001, format: "%.3f"),
                SliderDescriptor(id: "feedbackWarp", title: "Warp", keyPath: \.feedbackWarp, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "temporalJitter", title: "Temporal Jitter", keyPath: \.temporalJitter, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
            ]
        ),
        ControlSection(
            id: "motion",
            title: "Motion",
            descriptors: [
                SliderDescriptor(id: "driftX", title: "Drift X", keyPath: \.driftX, range: -1.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "driftY", title: "Drift Y", keyPath: \.driftY, range: -1.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "spiral", title: "Spiral", keyPath: \.spiral, range: -1.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "wobble", title: "Wobble", keyPath: \.wobble, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "beat", title: "Beat", keyPath: \.beat, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "strobe", title: "Strobe", keyPath: \.strobe, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
            ]
        ),
    ]

    static let geometrySections: [ControlSection] = [
        ControlSection(
            id: "symmetry",
            title: "Symmetry",
            descriptors: [
                SliderDescriptor(id: "kaleidoscope", title: "Segments", keyPath: \.kaleidoscope, range: 1.0 ... 16.0, step: 1.0, format: "%.0f"),
                SliderDescriptor(id: "mirrorMix", title: "Mirror Mix", keyPath: \.mirrorMix, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "facetMix", title: "Facet Mix", keyPath: \.facetMix, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "prism", title: "Prism", keyPath: \.prism, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "prismCount", title: "Prism Count", keyPath: \.prismCount, range: 1.0 ... 12.0, step: 1.0, format: "%.0f"),
            ]
        ),
        ControlSection(
            id: "optic",
            title: "Optics",
            descriptors: [
                SliderDescriptor(id: "refraction", title: "Refraction", keyPath: \.refraction, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "reflection", title: "Reflection", keyPath: \.reflection, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "universe", title: "Universe Echo", keyPath: \.universe, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "pixelate", title: "Pixelate", keyPath: \.pixelate, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "detail", title: "Detail", keyPath: \.detail, range: 0.1 ... 1.2, step: 0.01, format: "%.2f"),
            ]
        ),
    ]

    static let colorSections: [ControlSection] = [
        ControlSection(
            id: "color",
            title: "Color",
            descriptors: [
                SliderDescriptor(id: "hueShift", title: "Hue Shift", keyPath: \.hueShift, range: -1.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "saturation", title: "Saturation", keyPath: \.saturation, range: 0.0 ... 2.4, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "contrast", title: "Contrast", keyPath: \.contrast, range: 0.4 ... 2.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "brightness", title: "Brightness", keyPath: \.brightness, range: -0.6 ... 0.6, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "gamma", title: "Gamma", keyPath: \.gamma, range: 0.4 ... 1.8, step: 0.01, format: "%.2f"),
            ]
        ),
        ControlSection(
            id: "separation",
            title: "Separation",
            descriptors: [
                SliderDescriptor(id: "chromaSplit", title: "Chroma Split", keyPath: \.chromaSplit, range: 0.0 ... 0.03, step: 0.0005, format: "%.4f"),
                SliderDescriptor(id: "lumaMix", title: "Luma Mix", keyPath: \.lumaMix, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "invert", title: "Invert", keyPath: \.invert, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
            ]
        ),
    ]

    static let textureSections: [ControlSection] = [
        ControlSection(
            id: "signal",
            title: "Signal",
            descriptors: [
                SliderDescriptor(id: "plasma", title: "Plasma", keyPath: \.plasma, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "tunnel", title: "Tunnel", keyPath: \.tunnel, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "twister", title: "Twister", keyPath: \.twister, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "raster", title: "Raster", keyPath: \.raster, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "rings", title: "Rings", keyPath: \.rings, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "moire", title: "Moire", keyPath: \.moire, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "fractal", title: "Fractal", keyPath: \.fractal, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "noise", title: "Noise", keyPath: \.noise, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "xorField", title: "XOR Field", keyPath: \.xorField, range: 0.0 ... 1.2, step: 0.01, format: "%.2f"),
            ]
        ),
        ControlSection(
            id: "finish",
            title: "Finish",
            descriptors: [
                SliderDescriptor(id: "scanlines", title: "Scanlines", keyPath: \.scanlines, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "grain", title: "Grain", keyPath: \.grain, range: 0.0 ... 0.35, step: 0.005, format: "%.3f"),
                SliderDescriptor(id: "bloom", title: "Bloom", keyPath: \.bloom, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "edgeGlow", title: "Edge Glow", keyPath: \.edgeGlow, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
                SliderDescriptor(id: "vignette", title: "Vignette", keyPath: \.vignette, range: 0.0 ... 1.0, step: 0.01, format: "%.2f"),
            ]
        ),
    ]

    static let allDescriptors: [SliderDescriptor] = (
        feedbackSections +
        geometrySections +
        colorSections +
        textureSections
    ).flatMap(\.descriptors)
}
