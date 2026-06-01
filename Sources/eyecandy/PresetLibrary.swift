import Foundation
import SwiftUI

enum PresetLibrary {
    static let synthVoicePresets: [SynthVoicePreset] = [
        SynthVoicePreset(name: "Acid Warehouse Bass", voice: SynthVoice(instrument: .acidSaw, enabled: true, level: 0.56, octave: 1, cutoff: 0.58, resonance: 0.62, glide: 0.24, accent: 0.78, attack: 0.01, decay: 0.42, sustain: 0.10, drive: 0.62, filterEnvelope: 0.78, lfoRate: 0.18, lfoAmount: 0.20, morph: 0.36, unison: 0.12, detune: 0.08, subLevel: 0.42, noiseLevel: 0.03, fmAmount: 0.20, wavefold: 0.22, grainSize: 0.18, grainDensity: 0.25, bitcrush: 0.04)),
        SynthVoicePreset(name: "Reese Pressure", voice: SynthVoice(instrument: .reeseBass, enabled: true, level: 0.50, octave: 1, cutoff: 0.42, resonance: 0.32, glide: 0.16, accent: 0.44, attack: 0.02, decay: 0.62, sustain: 0.34, drive: 0.48, filterEnvelope: 0.36, lfoRate: 0.22, lfoAmount: 0.28, morph: 0.46, unison: 0.76, detune: 0.58, subLevel: 0.64, noiseLevel: 0.04, fmAmount: 0.16, wavefold: 0.18, grainSize: 0.16, grainDensity: 0.22, bitcrush: 0.03)),
        SynthVoicePreset(name: "Granular Halo", voice: SynthVoice(instrument: .granularCloud, enabled: true, level: 0.38, octave: 3, cutoff: 0.74, resonance: 0.18, glide: 0.08, accent: 0.22, attack: 0.18, decay: 0.78, sustain: 0.42, drive: 0.18, filterEnvelope: 0.28, lfoRate: 0.34, lfoAmount: 0.40, morph: 0.72, unison: 0.38, detune: 0.24, subLevel: 0.06, noiseLevel: 0.24, fmAmount: 0.34, wavefold: 0.10, grainSize: 0.72, grainDensity: 0.86, bitcrush: 0.05)),
        SynthVoicePreset(name: "Wavetable Glass Lead", voice: SynthVoice(instrument: .wavetableMorph, enabled: true, level: 0.42, octave: 4, cutoff: 0.78, resonance: 0.26, glide: 0.06, accent: 0.40, attack: 0.03, decay: 0.44, sustain: 0.18, drive: 0.20, filterEnvelope: 0.46, lfoRate: 0.44, lfoAmount: 0.34, morph: 0.68, unison: 0.44, detune: 0.26, subLevel: 0.04, noiseLevel: 0.02, fmAmount: 0.36, wavefold: 0.16, grainSize: 0.24, grainDensity: 0.36, bitcrush: 0.02)),
        SynthVoicePreset(name: "Phase Warp Lead", voice: SynthVoice(instrument: .phaseDistortion, enabled: true, level: 0.44, octave: 4, cutoff: 0.70, resonance: 0.36, glide: 0.05, accent: 0.56, attack: 0.01, decay: 0.38, sustain: 0.16, drive: 0.36, filterEnvelope: 0.55, lfoRate: 0.30, lfoAmount: 0.28, morph: 0.74, unison: 0.24, detune: 0.18, subLevel: 0.08, noiseLevel: 0.02, fmAmount: 0.62, wavefold: 0.36, grainSize: 0.20, grainDensity: 0.30, bitcrush: 0.10)),
        SynthVoicePreset(name: "Ring Mod Keys", voice: SynthVoice(instrument: .ringModKeys, enabled: true, level: 0.36, octave: 4, cutoff: 0.66, resonance: 0.28, glide: 0.02, accent: 0.30, attack: 0.05, decay: 0.58, sustain: 0.30, drive: 0.18, filterEnvelope: 0.32, lfoRate: 0.26, lfoAmount: 0.18, morph: 0.50, unison: 0.18, detune: 0.12, subLevel: 0.02, noiseLevel: 0.02, fmAmount: 0.78, wavefold: 0.08, grainSize: 0.18, grainDensity: 0.28, bitcrush: 0.04)),
        SynthVoicePreset(name: "Karplus Laser Pluck", voice: SynthVoice(instrument: .karplusPluck, enabled: true, level: 0.42, octave: 4, cutoff: 0.82, resonance: 0.18, glide: 0.00, accent: 0.54, attack: 0.00, decay: 0.24, sustain: 0.04, drive: 0.28, filterEnvelope: 0.64, lfoRate: 0.12, lfoAmount: 0.08, morph: 0.34, unison: 0.10, detune: 0.06, subLevel: 0.02, noiseLevel: 0.14, fmAmount: 0.18, wavefold: 0.14, grainSize: 0.12, grainDensity: 0.26, bitcrush: 0.00)),
        SynthVoicePreset(name: "Bitcrush Siren", voice: SynthVoice(instrument: .bitcrushLead, enabled: true, level: 0.40, octave: 4, cutoff: 0.62, resonance: 0.42, glide: 0.10, accent: 0.68, attack: 0.01, decay: 0.36, sustain: 0.10, drive: 0.44, filterEnvelope: 0.52, lfoRate: 0.54, lfoAmount: 0.42, morph: 0.58, unison: 0.30, detune: 0.22, subLevel: 0.06, noiseLevel: 0.08, fmAmount: 0.46, wavefold: 0.28, grainSize: 0.18, grainDensity: 0.42, bitcrush: 0.64)),
        SynthVoicePreset(name: "Spectral Drone Pad", voice: SynthVoice(instrument: .spectralDrone, enabled: true, level: 0.34, octave: 3, cutoff: 0.56, resonance: 0.44, glide: 0.18, accent: 0.20, attack: 0.34, decay: 0.92, sustain: 0.74, drive: 0.16, filterEnvelope: 0.18, lfoRate: 0.16, lfoAmount: 0.52, morph: 0.82, unison: 0.58, detune: 0.34, subLevel: 0.12, noiseLevel: 0.18, fmAmount: 0.24, wavefold: 0.08, grainSize: 0.62, grainDensity: 0.48, bitcrush: 0.02)),
        SynthVoicePreset(name: "Formant Vox Choir", voice: SynthVoice(instrument: .formantVox, enabled: true, level: 0.38, octave: 4, cutoff: 0.72, resonance: 0.58, glide: 0.08, accent: 0.26, attack: 0.08, decay: 0.70, sustain: 0.46, drive: 0.20, filterEnvelope: 0.34, lfoRate: 0.20, lfoAmount: 0.24, morph: 0.64, unison: 0.28, detune: 0.18, subLevel: 0.02, noiseLevel: 0.05, fmAmount: 0.32, wavefold: 0.10, grainSize: 0.34, grainDensity: 0.40, bitcrush: 0.03))
    ]

    static func randomizedSynthVoice(seed: Int) -> SynthVoice {
        let instruments = SynthInstrument.allCases
        return SynthVoice(
            instrument: instruments[abs(seed * 7 + 3) % instruments.count],
            enabled: true,
            level: 0.30 + Double(abs(seed * 11) % 34) / 100.0,
            octave: 1 + abs(seed * 13) % 4,
            cutoff: 0.28 + Double(abs(seed * 17) % 64) / 100.0,
            resonance: Double(abs(seed * 19) % 72) / 100.0,
            glide: Double(abs(seed * 23) % 32) / 100.0,
            accent: Double(abs(seed * 29) % 82) / 100.0,
            attack: Double(abs(seed * 31) % 42) / 100.0,
            decay: 0.18 + Double(abs(seed * 37) % 76) / 100.0,
            sustain: Double(abs(seed * 41) % 78) / 100.0,
            drive: Double(abs(seed * 43) % 76) / 100.0,
            filterEnvelope: Double(abs(seed * 47) % 86) / 100.0,
            lfoRate: Double(abs(seed * 53) % 90) / 100.0,
            lfoAmount: Double(abs(seed * 59) % 70) / 100.0,
            morph: Double(abs(seed * 61) % 100) / 100.0,
            unison: Double(abs(seed * 67) % 82) / 100.0,
            detune: Double(abs(seed * 71) % 64) / 100.0,
            subLevel: Double(abs(seed * 73) % 70) / 100.0,
            noiseLevel: Double(abs(seed * 79) % 34) / 100.0,
            fmAmount: Double(abs(seed * 83) % 82) / 100.0,
            wavefold: Double(abs(seed * 89) % 74) / 100.0,
            grainSize: Double(abs(seed * 97) % 100) / 100.0,
            grainDensity: Double(abs(seed * 101) % 100) / 100.0,
            bitcrush: Double(abs(seed * 103) % 72) / 100.0
        )
    }

    static let videoPerformancePresets: [VideoPerformancePreset] = [
        VideoPerformancePreset(name: "Colourspace Bloom 1080", visualEngine: .kaleidoscopeMaze, demosceneMode: .shadeBobs, minterMode: .colourspaceFlow, palette: .colourspace, videoMode: .colourspace, resolution: .fullHD, frameRate: 60, intensity: 0.72),
        VideoPerformancePreset(name: "Neon Pulse Tunnel", visualEngine: .lightTunnel, demosceneMode: .moireTunnel, minterMode: .vlmNeon, palette: .yakNeon, videoMode: .neonPulse, resolution: .hd720, frameRate: 60, intensity: 0.82),
        VideoPerformancePreset(name: "Space Giraffe Web", visualEngine: .moireField, demosceneMode: .twister, minterMode: .spaceGiraffeWeb, palette: .laserium, videoMode: .chromaticAberration, resolution: .fullHD, frameRate: 60, intensity: 0.88),
        VideoPerformancePreset(name: "TxK Vector Square", visualEngine: .fractalLightning, demosceneMode: .vectorBalls, minterMode: .txkVectorBloom, palette: .neon, videoMode: .videoFeedback, resolution: .square, frameRate: 60, intensity: 0.78),
        VideoPerformancePreset(name: "LlamaTron Vertical", visualEngine: .cellularAutomata, demosceneMode: .bitplaneStorm, minterMode: .llamaTronTrails, palette: .phosphor, videoMode: .datamoshBlocks, resolution: .vertical, frameRate: 30, intensity: 0.70),
        VideoPerformancePreset(name: "Neon Loopz Ultrawide", visualEngine: .slitScanRibbons, demosceneMode: .rasterInterference, minterMode: .neonLoopz, palette: .yakNeon, videoMode: .vhsMelt, resolution: .ultrawide, frameRate: 60, intensity: 0.76),
        VideoPerformancePreset(name: "Mandel Lava 4K", visualEngine: .reactionDiffusion, demosceneMode: .mandelZoom, minterMode: .colourspaceFlow, palette: .acid, videoMode: .colourspace, resolution: .fourK, frameRate: 30, intensity: 0.68),
        VideoPerformancePreset(name: "Voxel Rave 720", visualEngine: .terrainGrid, demosceneMode: .voxelLandscape, minterMode: .gridrunnerLattice, palette: .laserium, videoMode: .demosceneStack, resolution: .hd720, frameRate: 60, intensity: 0.80),
        VideoPerformancePreset(name: "Phosphor Automata", visualEngine: .cellularAutomata, demosceneMode: .shadeBobs, minterMode: .psychedeliaGrid, palette: .phosphor, videoMode: .videoFeedback, resolution: .square, frameRate: 30, intensity: 0.62),
        VideoPerformancePreset(name: "Trip-A-Tron Blocks", visualEngine: .liquidCells, demosceneMode: .chunkyVGA, minterMode: .arcadeVortex, palette: .colourspace, videoMode: .datamoshBlocks, resolution: .fullHD, frameRate: 30, intensity: 0.74),
        VideoPerformancePreset(name: "Laserium Portrait", visualEngine: .oscilloscopeRibbons, demosceneMode: .twister, minterMode: .vlmNeon, palette: .laserium, videoMode: .neonPulse, resolution: .vertical, frameRate: 60, intensity: 0.84),
        VideoPerformancePreset(name: "Mega Demo Stack", visualEngine: .engineAutopilot, demosceneMode: .megaDemo, minterMode: .spaceGiraffeWeb, palette: .yakNeon, videoMode: .demosceneStack, resolution: .fullHD, frameRate: 60, intensity: 0.90),
        VideoPerformancePreset(name: "Luma Key Bloom", visualEngine: .metaballs, demosceneMode: .shadeBobs, minterMode: .colourspaceFlow, palette: .laserium, videoMode: .lumaKeyBloom, resolution: .fullHD, frameRate: 60, intensity: 0.78),
        VideoPerformancePreset(name: "Chroma Invert Keyer", visualEngine: .vectorField, demosceneMode: .rasterInterference, minterMode: .yakLaserGrid, palette: .rainbow, videoMode: .chromaInvert, resolution: .hd720, frameRate: 60, intensity: 0.74),
        VideoPerformancePreset(name: "Edge Trace Proc", visualEngine: .shapeConstellation, demosceneMode: .bitplaneStorm, minterMode: .tempestWeb, palette: .phosphor, videoMode: .edgeTrace, resolution: .square, frameRate: 60, intensity: 0.82),
        VideoPerformancePreset(name: "Oscillator Bank HD", visualEngine: .oscilloscopeRibbons, demosceneMode: .copperBars, minterMode: .vlmNeon, palette: .neon, videoMode: .oscillatorBank, resolution: .fullHD, frameRate: 60, intensity: 0.86),
        VideoPerformancePreset(name: "VectorScope Chroma", visualEngine: .particleNebula, demosceneMode: .vectorBalls, minterMode: .neonLoopz, palette: .colourspace, videoMode: .vectorScope, resolution: .fullHD, frameRate: 60, intensity: 0.80),
        VideoPerformancePreset(name: "Scan Gate Luma", visualEngine: .terrainGrid, demosceneMode: .starTunnel, minterMode: .polybiusTunnel, palette: .ultraviolet, videoMode: .scanGate, resolution: .ultrawide, frameRate: 60, intensity: 0.76),
        VideoPerformancePreset(name: "Feedback Mirror 480", visualEngine: .lightTunnel, demosceneMode: .copperBars, minterMode: .llamaFeedback, palette: .phosphor, videoMode: .videoFeedback, resolution: .sd480, frameRate: 60, intensity: 0.66),
        VideoPerformancePreset(name: "Feedback Tunnel 1440", visualEngine: .engineAutopilot, demosceneMode: .starTunnel, minterMode: .polybiusTunnel, palette: .yakNeon, videoMode: .lumaKeyBloom, resolution: .qhd, frameRate: 60, intensity: 0.84),
        VideoPerformancePreset(name: "Webcam Slit Portrait", visualEngine: .slitScanRibbons, demosceneMode: .rasterInterference, minterMode: .neonLoopz, palette: .laserium, videoMode: .slitScan, resolution: .socialPortrait, frameRate: 60, intensity: 0.72),
        VideoPerformancePreset(name: "Chroma Wash Vertical 4K", visualEngine: .particleNebula, demosceneMode: .shadeBobs, minterMode: .colourspaceFlow, palette: .rainbow, videoMode: .chromaInvert, resolution: .vertical4K, frameRate: 30, intensity: 0.70),
        VideoPerformancePreset(name: "Ultrawide Feedback Scope", visualEngine: .moireField, demosceneMode: .vectorBalls, minterMode: .spaceGiraffeWeb, palette: .colourspace, videoMode: .vectorScope, resolution: .ultrawideQHD, frameRate: 60, intensity: 0.82),
        VideoPerformancePreset(name: "Fast Preview Feedback", visualEngine: .metaballs, demosceneMode: .chunkyVGA, minterMode: .arcadeVortex, palette: .acid, videoMode: .edgeTrace, resolution: .n360, frameRate: 60, intensity: 0.76),
        VideoPerformancePreset(name: "Pixel Sort Basement", visualEngine: .liquidCells, demosceneMode: .bitplaneStorm, minterMode: .neonLoopz, palette: .acid, videoMode: .pixelSortTrails, resolution: .fullHD, frameRate: 60, intensity: 0.88),
        VideoPerformancePreset(name: "Codec Tear Warehouse", visualEngine: .cellularAutomata, demosceneMode: .rasterInterference, minterMode: .llamaFeedback, palette: .phosphor, videoMode: .codecTear, resolution: .hd720, frameRate: 60, intensity: 0.86),
        VideoPerformancePreset(name: "RGB Delay Dub Club", visualEngine: .oscilloscopeRibbons, demosceneMode: .twister, minterMode: .vlmNeon, palette: .yakNeon, videoMode: .rgbDelay, resolution: .fullHD, frameRate: 60, intensity: 0.90),
        VideoPerformancePreset(name: "Halftone Zine Rave", visualEngine: .shapeConstellation, demosceneMode: .shadeBobs, minterMode: .psychedeliaGrid, palette: .rainbow, videoMode: .halftonePosterize, resolution: .socialPortrait, frameRate: 30, intensity: 0.82),
        VideoPerformancePreset(name: "Optical Flow Squat", visualEngine: .vectorField, demosceneMode: .starTunnel, minterMode: .tempestWeb, palette: .ultraviolet, videoMode: .opticalFlowSmear, resolution: .ultrawide, frameRate: 60, intensity: 0.92),
        VideoPerformancePreset(name: "Recursive Mirror Loft", visualEngine: .kaleidoscopeMaze, demosceneMode: .moireTunnel, minterMode: .spaceGiraffeWeb, palette: .colourspace, videoMode: .recursiveMirror, resolution: .square, frameRate: 60, intensity: 0.84),
        VideoPerformancePreset(name: "Databent Halftone 480", visualEngine: .metaballs, demosceneMode: .chunkyVGA, minterMode: .arcadeVortex, palette: .laserium, videoMode: .halftonePosterize, resolution: .sd480, frameRate: 30, intensity: 0.78),
        VideoPerformancePreset(name: "Pirate Signal Sort 4K", visualEngine: .reactionDiffusion, demosceneMode: .mandelZoom, minterMode: .colourspaceFlow, palette: .infrared, videoMode: .pixelSortTrails, resolution: .fourK, frameRate: 30, intensity: 0.80),
        VideoPerformancePreset(name: "No-Wave Codec Portrait", visualEngine: .fractalLightning, demosceneMode: .rasterInterference, minterMode: .yakLaserGrid, palette: .neon, videoMode: .codecTear, resolution: .vertical, frameRate: 60, intensity: 0.87),
        VideoPerformancePreset(name: "RGB Tape Delay 1440", visualEngine: .particleNebula, demosceneMode: .vectorBalls, minterMode: .neonStampede, palette: .colourspace, videoMode: .rgbDelay, resolution: .qhd, frameRate: 60, intensity: 0.83),
        VideoPerformancePreset(name: "Flow Smear Ultrawide", visualEngine: .terrainGrid, demosceneMode: .voxelLandscape, minterMode: .polybiusTunnel, palette: .laserium, videoMode: .opticalFlowSmear, resolution: .ultrawideQHD, frameRate: 60, intensity: 0.89),
        VideoPerformancePreset(name: "Mirror Feedback Vertical 4K", visualEngine: .engineAutopilot, demosceneMode: .megaDemo, minterMode: .llamaTronTrails, palette: .yakNeon, videoMode: .recursiveMirror, resolution: .vertical4K, frameRate: 30, intensity: 0.85),
        VideoPerformancePreset(name: "Liquid Lens Ritual", visualEngine: .liquidCells, demosceneMode: .plasma, minterMode: .colourspaceFlow, palette: .rainbow, videoMode: .liquidLens, resolution: .fullHD, frameRate: 60, intensity: 0.91),
        VideoPerformancePreset(name: "Kaleido Feedback Shrine", visualEngine: .kaleidoscopeMaze, demosceneMode: .moireTunnel, minterMode: .spaceGiraffeWeb, palette: .yakNeon, videoMode: .kaleidoFeedback, resolution: .square, frameRate: 60, intensity: 0.94),
        VideoPerformancePreset(name: "Solarized Contour Club", visualEngine: .fractalLightning, demosceneMode: .shadeBobs, minterMode: .tempestWeb, palette: .ultraviolet, videoMode: .solarizedContours, resolution: .hd720, frameRate: 60, intensity: 0.86),
        VideoPerformancePreset(name: "Phosphor Burn Monitor", visualEngine: .cellularAutomata, demosceneMode: .rasterInterference, minterMode: .llamaFeedback, palette: .phosphor, videoMode: .phosphorBurn, resolution: .sd480, frameRate: 60, intensity: 0.82),
        VideoPerformancePreset(name: "Tunnel Fold Ceremony", visualEngine: .lightTunnel, demosceneMode: .starTunnel, minterMode: .polybiusTunnel, palette: .laserium, videoMode: .tunnelFold, resolution: .ultrawideQHD, frameRate: 60, intensity: 0.90),
        VideoPerformancePreset(name: "Chroma Light Leak Portrait", visualEngine: .particleNebula, demosceneMode: .twister, minterMode: .neonLoopz, palette: .colourspace, videoMode: .chromaLightLeaks, resolution: .vertical, frameRate: 60, intensity: 0.88),
        VideoPerformancePreset(name: "Liquid Lens Vertical 4K", visualEngine: .reactionDiffusion, demosceneMode: .mandelZoom, minterMode: .psychedeliaGrid, palette: .acid, videoMode: .liquidLens, resolution: .vertical4K, frameRate: 30, intensity: 0.84),
        VideoPerformancePreset(name: "Solarized Scope 1440", visualEngine: .oscilloscopeRibbons, demosceneMode: .vectorBalls, minterMode: .txkVectorBloom, palette: .neon, videoMode: .solarizedContours, resolution: .qhd, frameRate: 60, intensity: 0.87)
    ] + psychedelicPerformancePresets()

    private static func psychedelicPerformancePresets() -> [VideoPerformancePreset] {
        let adjectives = [
            "Psychedelic", "Hyperdelic", "Kaleido", "Liquid", "Luma", "Chroma", "Astral", "Prismatic",
            "Neuro", "Vortex", "Solarized", "Optical", "Acid", "Hologram", "Scanner", "Feedback"
        ]
        let nouns = [
            "Brain Melt", "Retina Bloom", "Dream Gate", "Tunnel Choir", "Pixel Ritual", "Scope Storm",
            "Mirror Engine", "Pulse Shrine", "Signal Garden", "Ghost Reactor", "Light Furnace", "Echo Cathedral",
            "Plasma Chapel", "Vector Rave", "Color Organ", "Wave Temple"
        ]
        let engines = VisualEngineMode.allCases.filter { $0 != .engineAutopilot } + [.engineAutopilot]
        let demoModes = DemosceneEffectMode.allCases
        let minterModes = MinterEffectMode.allCases.filter { $0 != .off }
        let palettes = LightPaletteMode.allCases
        let videoModes = ExperimentalVideoMode.allCases.filter { $0 != .clean }
        let resolutions = RecordingResolution.allCases
        let frameRates = [24, 30, 60]

        return (0..<128).map { index in
            let adjective = adjectives[index % adjectives.count]
            let noun = nouns[(index / adjectives.count + index * 3) % nouns.count]
            let engine = engines[(index * 5 + 3) % engines.count]
            let demo = demoModes[(index * 7 + 2) % demoModes.count]
            let minter = minterModes[(index * 11 + 1) % minterModes.count]
            let palette = palettes[(index * 13 + 4) % palettes.count]
            let video = videoModes[(index * 17 + 5) % videoModes.count]
            let resolution = resolutions[(index * 19 + 2) % resolutions.count]
            let frameRate = frameRates[(index * 23 + 1) % frameRates.count]
            let intensity = 0.58 + Double((index * 29) % 39) / 100.0
            return VideoPerformancePreset(
                name: "\(adjective) \(noun) \(String(format: "%03d", index + 1))",
                visualEngine: engine,
                demosceneMode: demo,
                minterMode: minter,
                palette: palette,
                videoMode: video,
                resolution: resolution,
                frameRate: frameRate,
                intensity: min(0.96, intensity)
            )
        }
    }

    static let visualPresets: [VisualPreset] = {
        let families: [PresetFamily] = [.tunnel, .mandala, .liquid, .laser, .cellular, .demoscene, .cosmic, .minter, .holographic]
        let wordsA = ["Acid", "Chrome", "Dream", "Neon", "Vortex", "Plasma", "Crystal", "Astral", "Liquid", "Mirror", "Yak", "Prism", "Camera", "Luma", "Chroma", "Echo", "Vector", "Laser"]
        let wordsB = ["Temple", "Bloom", "Scanner", "Feedback", "Orbit", "Cathedral", "Machine", "Serpent", "Signal", "Ritual", "Stampede", "Hologram", "Loop", "Gate", "Scope", "Tunnel"]

        let generated = (0..<220).map { index in
            let family = families[index % families.count]
            let hue = Double((index * 37) % 360) / 360.0
            let symmetry = [3, 4, 5, 6, 8, 10, 12][index % 7]
            let name = "\(wordsA[index % wordsA.count]) \(wordsB[(index / wordsA.count + index) % wordsB.count]) \(String(format: "%03d", index + 1))"
            return VisualPreset(
                id: index,
                name: name,
                family: family,
                colorA: .hsba(hue, 0.88, 0.96),
                colorB: .hsba(hue + 0.28, 0.82, 0.90),
                colorC: .hsba(hue + 0.58, 0.72, 1.00),
                density: 0.35 + Double((index * 11) % 61) / 100.0,
                warp: 0.20 + Double((index * 17) % 80) / 100.0,
                feedback: 0.10 + Double((index * 13) % 70) / 100.0,
                symmetry: symmetry,
                strobe: Double((index * 19) % 35) / 100.0
            )
        }
        return generated + minterSignaturePresets()
    }()

    static func minterProfile(for preset: VisualPreset) -> MinterPresetProfile? {
        guard preset.family == .minter else { return nil }
        let index = max(0, preset.id - 1000)
        let minterModes: [MinterEffectMode] = [.psychedeliaGrid, .colourspaceFlow, .vlmNeon, .tempestWeb, .polybiusTunnel, .gridrunnerLattice, .spaceGiraffeWeb, .txkVectorBloom, .neonLoopz, .llamaTronTrails, .neonStampede, .yakLaserGrid, .llamaFeedback, .arcadeVortex]
        let engines: [VisualEngineMode] = [.vectorField, .terrainGrid, .oscilloscopeRibbons, .fractalLightning, .particleNebula, .shapeConstellation, .lightTunnel, .metaballs, .liquidCells, .moireField, .slitScanRibbons, .kaleidoscopeMaze]
        let lightModes: [LightSynthMode] = [.lissajousLaser, .photonStorm, .recursiveBloom, .acidScope, .hyperPrism, .neuralMandala, .everything]
        let palettes: [LightPaletteMode] = [.colourspace, .yakNeon, .phosphor, .laserium, .neon, .acid, .rainbow, .ultraviolet, .infrared, .amber]
        let blends: [LightBlendMode] = [.additive, .screen, .softKey, .difference]
        let demoModes: [DemosceneEffectMode] = [.copperBars, .starTunnel, .vectorBalls, .sineScroller, .megaDemo, .plasma, .moireTunnel, .bitplaneStorm, .rasterInterference, .shadeBobs, .twister, .mandelZoom, .voxelLandscape]
        let holoModes: [HolographicMode] = [.off, .ghostPrism, .chromaDepth, .interference]

        return MinterPresetProfile(
            minterMode: minterModes[index % minterModes.count],
            visualEngine: engines[(index * 3 + 1) % engines.count],
            lightMode: lightModes[(index * 5 + 2) % lightModes.count],
            palette: palettes[(index * 7 + 1) % palettes.count],
            blend: blends[(index * 3) % blends.count],
            demosceneMode: demoModes[(index * 5) % demoModes.count],
            holographicMode: holoModes[(index * 2 + 1) % holoModes.count],
            intensity: 0.58 + Double((index * 13) % 38) / 100.0,
            prismSplits: 3 + (index % 7)
        )
    }

    static func proceduralProfile(for preset: VisualPreset, seed: Int) -> MinterPresetProfile {
        if let minter = minterProfile(for: preset) {
            return minter
        }

        let familyBias: [PresetFamily: [VisualEngineMode]] = [
            .tunnel: [.lightTunnel, .terrainGrid, .particleNebula, .oscilloscopeRibbons, .moireField],
            .mandala: [.shapeConstellation, .fractalTrees, .particleNebula, .metaballs, .kaleidoscopeMaze],
            .liquid: [.liquidCells, .metaballs, .particleNebula, .vectorField, .reactionDiffusion],
            .laser: [.vectorField, .fractalLightning, .oscilloscopeRibbons, .lightTunnel, .slitScanRibbons],
            .cellular: [.liquidCells, .metaballs, .fractalTrees, .shapeConstellation, .cellularAutomata, .reactionDiffusion],
            .demoscene: [.terrainGrid, .vectorField, .oscilloscopeRibbons, .fractalLightning, .moireField, .cellularAutomata],
            .cosmic: [.particleNebula, .shapeConstellation, .terrainGrid, .lightTunnel, .kaleidoscopeMaze],
            .holographic: [.vectorField, .particleNebula, .shapeConstellation, .oscilloscopeRibbons, .slitScanRibbons],
            .all: [.lightTunnel, .vectorField, .metaballs, .terrainGrid, .moireField]
        ]
        let engines = familyBias[preset.family] ?? [.lightTunnel, .vectorField, .metaballs, .terrainGrid, .oscilloscopeRibbons, .fractalLightning, .fractalTrees, .particleNebula, .shapeConstellation, .liquidCells, .reactionDiffusion, .kaleidoscopeMaze, .moireField, .slitScanRibbons, .cellularAutomata]
        let lightModes: [LightSynthMode] = [.hyperPrism, .lissajousLaser, .recursiveBloom, .acidScope, .photonStorm, .neuralMandala, .everything]
        let palettes: [LightPaletteMode] = [.neon, .colourspace, .yakNeon, .phosphor, .laserium, .acid, .ultraviolet, .infrared, .ice, .monochrome, .rainbow, .amber]
        let blends: [LightBlendMode] = [.additive, .screen, .softKey, .hardKey, .difference]
        let demoModes: [DemosceneEffectMode] = [.off, .copperBars, .plasma, .rotoZoom, .vectorBalls, .starTunnel, .sineScroller, .chunkyVGA, .moireTunnel, .bitplaneStorm, .rasterInterference, .shadeBobs, .twister, .mandelZoom, .voxelLandscape, .megaDemo]
        let holoModes: [HolographicMode] = [.off, .ghostPrism, .scanVolume, .chromaDepth, .interference]
        let minterModes: [MinterEffectMode] = [.off, .psychedeliaGrid, .colourspaceFlow, .vlmNeon, .tempestWeb, .polybiusTunnel, .gridrunnerLattice, .spaceGiraffeWeb, .txkVectorBloom, .neonLoopz, .llamaTronTrails, .neonStampede, .yakLaserGrid, .llamaFeedback, .arcadeVortex]
        let key = abs(preset.id * 131 + seed * 17)

        return MinterPresetProfile(
            minterMode: minterModes[key % minterModes.count],
            visualEngine: engines[key % engines.count],
            lightMode: lightModes[(key / 3) % lightModes.count],
            palette: palettes[(key / 5) % palettes.count],
            blend: blends[(key / 7) % blends.count],
            demosceneMode: demoModes[(key / 11) % demoModes.count],
            holographicMode: holoModes[(key / 13) % holoModes.count],
            intensity: 0.42 + Double(key % 52) / 100.0,
            prismSplits: 2 + (key % 9)
        )
    }

    private static func minterSignaturePresets() -> [VisualPreset] {
        let names = [
            "Yak Neon V-Crew", "Tempest Web Grazer", "Gridrunner Laser Pasture", "Polybius Gate Bloom",
            "Llama Feedback Shrine", "Neon Oxide Stampede", "Mutant Camel Prism", "Space Giraffe Tube",
            "Colourspace Rave Grid", "Psychedelia Wool Field", "Trip-a-Tron Reactor", "Laser Zone Herd",
            "Superzapper Pasture", "Ruminant Vector Choir", "Attack Camel Aurora", "Minotaur Gate Pulse",
            "Yak Hair Oscilloscope", "Neon Hoofprint Tunnel", "Bovver Boots Plasma", "Giles Prism Crew",
            "Jaguar Tube Rider", "VLM Acid Cathedral", "Rave Web Ungulator", "Llamatron Ghost Net",
            "Oxidized Rainbow Grid", "Pasture of Lasers", "Hypno Yak Reactor", "Sheep In Vector Space",
            "Grid Grazer Revolution", "Camelback Lightstorm", "Tempest Bonus Spiral", "Neon Wool Cyclone",
            "Minteresque Photon Rush", "Arcade Pasture Bloom", "Ruminant Feedback Gate", "Yak Chrome Stampede",
            "Llama Neon Mandala", "Space Hoof Particle Choir", "Web Edge Supernova", "Colour Organ Camel",
            "Acid Grazer Lattice", "V-Crew Star Tunnel", "Jaguar Psychedelia Net", "Gridrunner Prism Snake",
            "Polybius Pasture Drive", "Mutant Neon Cells", "Sheepish Laser Bloom", "Hoofbeat Roto Grid",
            "Yak Signal Cathedral", "Llamasoftish Photon Field", "Rave Camel Constellation", "Tempest Herdline",
            "Neon Ruminant Driver", "Psychedelic Wool Machine", "Trip Reactor Giraffe", "Laser Grazer Deluxe",
            "Yak Spiral Bonus", "Moozak Prism Wave", "Grid Pasture Attack", "Space Llama Reactor",
            "Colourspace Supergrid", "Bisonic Neon Gate", "Vector Wool Hypnosis", "Final Yak Lightshow"
        ]

        return names.enumerated().map { offset, name in
            let hue = Double((offset * 29 + 11) % 360) / 360.0
            return VisualPreset(
                id: 1000 + offset,
                name: name,
                family: .minter,
                colorA: .hsba(hue, 0.98, 1.0),
                colorB: .hsba(hue + 0.22 + Double(offset % 5) * 0.015, 0.92, 0.96),
                colorC: .hsba(hue + 0.55, 0.86, 1.0),
                density: 0.58 + Double((offset * 17) % 40) / 100.0,
                warp: 0.42 + Double((offset * 23) % 55) / 100.0,
                feedback: 0.28 + Double((offset * 19) % 48) / 100.0,
                symmetry: [3, 4, 5, 6, 8, 9, 12, 16][offset % 8],
                strobe: 0.08 + Double((offset * 11) % 24) / 100.0
            )
        }
    }

    static let drumPresets: [DrumPreset] = [
        DrumPreset(name: "Four on the Floor",
                   kick: [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false],
                   snare: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
                   hat: [false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false],
                   clap: [false, false, false, false, true, false, false, true, false, false, false, false, true, false, false, true]),
        DrumPreset(name: "Broken Ritual",
                   kick: [true, false, false, true, false, false, true, false, false, true, false, false, true, false, false, false],
                   snare: [false, false, false, false, true, false, false, false, false, true, false, false, false, false, true, false],
                   hat: [true, false, true, true, false, true, false, true, true, false, true, false, true, false, true, false],
                   clap: [false, false, false, false, false, false, true, false, false, false, false, true, false, false, false, false]),
        DrumPreset(name: "Motorik Rush",
                   kick: [true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false],
                   snare: [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
                   hat: [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true],
                   clap: [false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true]),
        DrumPreset(name: "Triptronics",
                   kick: [true, false, false, false, false, true, false, true, false, false, true, false, true, false, false, false],
                   snare: [false, false, false, true, false, false, false, false, false, false, true, false, false, false, false, true],
                   hat: [false, true, false, true, true, false, true, false, false, true, false, true, true, false, true, false],
                   clap: [false, false, false, false, true, false, false, false, false, false, false, true, false, false, true, false])
    ] + psychedelicDrumPresets()

    private static func psychedelicDrumPresets() -> [DrumPreset] {
        let names = [
            "Acid Warehouse", "Laser Breakbeat", "DMT Electro", "Cosmic Footwork",
            "Hypno Dub", "Neon Jungle", "Kraut Pulse", "Rave Polyrhythm",
            "Glitch Mandala", "Temple Breaks", "Astral Garage", "Feedback Techno",
            "Trip Hop Engine", "Prism Shuffle", "Vortex Motorik", "Chroma Stutter"
        ]

        return names.enumerated().map { index, name in
            let kick = (0..<16).map { step in
                step == 0 || step == 8 || ((step * (index + 3) + index) % 11 == 0)
            }
            let snare = (0..<16).map { step in
                step == 4 || step == 12 || ((step + index * 2) % 13 == 0 && step % 2 == 1)
            }
            let hat = (0..<16).map { step in
                step % (index % 3 + 2) == 0 || ((step * 5 + index) % 9 == 0)
            }
            let clap = (0..<16).map { step in
                step == 7 || step == 15 || ((step * 3 + index) % 14 == 0)
            }
            return DrumPreset(name: name, kick: kick, snare: snare, hat: hat, clap: clap)
        }
    }
}
