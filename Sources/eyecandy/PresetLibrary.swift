import Foundation

enum PresetLibrary {
    static func build() -> [EffectPreset] {
        var presets: [EffectPreset] = []
        for family in PresetFamily.allCases {
            for index in 0 ..< 10 {
                let progress = Float(index) / 9.0
                let settings = settings(for: family, progress: progress, variant: index)
                let presetNumber = String(format: "%02d", index + 1)
                presets.append(
                    EffectPreset(
                        family: family,
                        name: "\(family.rawValue) \(presetNumber)",
                        summary: family.summary,
                        settings: settings
                    )
                )
            }
        }
        return presets
    }

    private static func settings(for family: PresetFamily, progress: Float, variant: Int) -> EffectSettings {
        switch family {
        case .trueFeedback:
            return trueFeedback(progress: progress, variant: variant)
        case .hallOfMirrors:
            return hallOfMirrors(progress: progress, variant: variant)
        case .prismSimulator:
            return prismSimulator(progress: progress, variant: variant)
        case .chromaLuma:
            return chromaLuma(progress: progress, variant: variant)
        case .kaleidoscope:
            return kaleidoscope(progress: progress, variant: variant)
        case .plasmaTunnel:
            return plasmaTunnel(progress: progress, variant: variant)
        case .rasterRoto:
            return rasterRoto(progress: progress, variant: variant)
        case .xorMoire:
            return xorMoire(progress: progress, variant: variant)
        case .fractalBloom:
            return fractalBloom(progress: progress, variant: variant)
        case .parallelUniverse:
            return parallelUniverse(progress: progress, variant: variant)
        }
    }

    private static func trueFeedback(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = ColorSpaceMode.spectral.shaderIndex
        settings.feedback = 0.82 + progress * 0.15
        settings.sourceMix = 0.52 - progress * 0.22
        settings.zoom = 1.004 + progress * 0.02
        settings.rotation = signed(progress, amplitude: 0.06, variant: variant)
        settings.feedbackWarp = 0.18 + progress * 0.52
        settings.temporalJitter = 0.06 + progress * 0.3
        settings.scanlines = 0.16 + progress * 0.34
        settings.edgeGlow = 0.18 + progress * 0.28
        settings.bloom = 0.15 + progress * 0.22
        settings.raster = 0.08 + progress * 0.18
        settings.noise = 0.06 + progress * 0.16
        settings.tunnel = 0.08 + progress * 0.16
        settings.hueShift = 0.03 + progress * 0.18
        settings.detail = 0.44 + progress * 0.26
        return settings
    }

    private static func hallOfMirrors(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (variant % 2 == 0 ? ColorSpaceMode.prismIce : ColorSpaceMode.lumaGhost).shaderIndex
        settings.feedback = 0.78 + progress * 0.18
        settings.zoom = 1.01 + progress * 0.05
        settings.rotation = signed(progress, amplitude: 0.11, variant: variant)
        settings.kaleidoscope = 2.0 + Float(variant % 5) * 2.0
        settings.mirrorMix = 0.42 + progress * 0.5
        settings.reflection = 0.45 + progress * 0.42
        settings.refraction = 0.18 + progress * 0.32
        settings.prism = 0.18 + progress * 0.26
        settings.prismCount = 4.0 + Float(variant % 6)
        settings.universe = 0.14 + progress * 0.36
        settings.bloom = 0.22 + progress * 0.28
        settings.edgeGlow = 0.24 + progress * 0.36
        settings.rings = 0.22 + progress * 0.18
        settings.vignette = 0.16 + progress * 0.2
        return settings
    }

    private static func prismSimulator(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = ColorSpaceMode.prismIce.shaderIndex
        settings.feedback = 0.68 + progress * 0.18
        settings.sourceMix = 0.66 + progress * 0.2
        settings.prism = 0.38 + progress * 0.52
        settings.prismCount = 5.0 + Float(variant % 7)
        settings.refraction = 0.36 + progress * 0.5
        settings.reflection = 0.18 + progress * 0.18
        settings.kaleidoscope = 3.0 + Float(variant % 4) * 2.0
        settings.chromaSplit = 0.008 + progress * 0.018
        settings.hueShift = 0.10 + progress * 0.4
        settings.saturation = 1.2 + progress * 0.6
        settings.bloom = 0.18 + progress * 0.32
        settings.rings = 0.14 + progress * 0.22
        settings.plasma = 0.24 + progress * 0.22
        return settings
    }

    private static func chromaLuma(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = ColorSpaceMode.lumaGhost.shaderIndex
        settings.feedback = 0.72 + progress * 0.18
        settings.sourceMix = 0.56 + progress * 0.42
        settings.chromaSplit = 0.01 + progress * 0.02
        settings.lumaMix = 0.36 + progress * 0.56
        settings.hueShift = signed(progress, amplitude: 0.52, variant: variant)
        settings.saturation = 1.28 + progress * 0.72
        settings.contrast = 1.02 + progress * 0.4
        settings.brightness = signed(progress, amplitude: 0.08, variant: variant)
        settings.gamma = 0.82 + progress * 0.46
        settings.invert = progress > 0.74 ? 0.22 + progress * 0.46 : 0.0
        settings.plasma = 0.22 + progress * 0.36
        settings.noise = 0.12 + progress * 0.18
        settings.raster = 0.08 + progress * 0.18
        settings.edgeGlow = 0.12 + progress * 0.2
        return settings
    }

    private static func kaleidoscope(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (variant % 3 == 0 ? ColorSpaceMode.minterSynesthesia : ColorSpaceMode.spectral).shaderIndex
        settings.feedback = 0.70 + progress * 0.24
        settings.kaleidoscope = 4.0 + Float(variant)
        settings.mirrorMix = 0.34 + progress * 0.52
        settings.facetMix = 0.28 + progress * 0.48
        settings.spiral = signed(progress, amplitude: 0.82, variant: variant)
        settings.rotation = signed(progress, amplitude: 0.14, variant: variant)
        settings.rings = 0.24 + progress * 0.5
        settings.plasma = 0.28 + progress * 0.28
        settings.fractal = 0.22 + progress * 0.34
        settings.bloom = 0.24 + progress * 0.24
        settings.hueShift = 0.04 + progress * 0.28
        return settings
    }

    private static func plasmaTunnel(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (progress > 0.55 ? ColorSpaceMode.minterSynesthesia : ColorSpaceMode.spectral).shaderIndex
        settings.feedback = 0.76 + progress * 0.14
        settings.zoom = 1.01 + progress * 0.04
        settings.rotation = signed(progress, amplitude: 0.08, variant: variant)
        settings.plasma = 0.5 + progress * 0.6
        settings.tunnel = 0.42 + progress * 0.56
        settings.rings = 0.28 + progress * 0.22
        settings.noise = 0.12 + progress * 0.3
        settings.fractal = 0.18 + progress * 0.24
        settings.feedbackWarp = 0.22 + progress * 0.36
        settings.edgeGlow = 0.18 + progress * 0.28
        settings.vignette = 0.10 + progress * 0.24
        return settings
    }

    private static func rasterRoto(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = ColorSpaceMode.minterSynesthesia.shaderIndex
        settings.feedback = 0.68 + progress * 0.16
        settings.sourceMix = 0.52 + progress * 0.34
        settings.zoom = 0.94 + progress * 0.14
        settings.rotation = signed(progress, amplitude: 0.22, variant: variant)
        settings.twister = 0.32 + progress * 0.58
        settings.raster = 0.28 + progress * 0.62
        settings.pixelate = 0.08 + progress * 0.54
        settings.scanlines = 0.18 + progress * 0.4
        settings.noise = 0.08 + progress * 0.18
        settings.xorField = 0.08 + progress * 0.22
        settings.beat = 0.24 + progress * 0.46
        settings.detail = 0.34 + progress * 0.42
        return settings
    }

    private static func xorMoire(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (variant % 2 == 0 ? ColorSpaceMode.lavaChrome : ColorSpaceMode.lumaGhost).shaderIndex
        settings.feedback = 0.64 + progress * 0.18
        settings.sourceMix = 0.6 + progress * 0.3
        settings.rotation = signed(progress, amplitude: 0.18, variant: variant)
        settings.zoom = 0.96 + progress * 0.12
        settings.moire = 0.34 + progress * 0.62
        settings.xorField = 0.28 + progress * 0.72
        settings.raster = 0.16 + progress * 0.24
        settings.noise = 0.10 + progress * 0.26
        settings.invert = progress > 0.62 ? 0.12 + progress * 0.52 : 0.0
        settings.hueShift = 0.14 + progress * 0.24
        settings.contrast = 1.08 + progress * 0.42
        settings.edgeGlow = 0.08 + progress * 0.16
        return settings
    }

    private static func fractalBloom(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (variant % 2 == 0 ? ColorSpaceMode.spectral : ColorSpaceMode.lavaChrome).shaderIndex
        settings.feedback = 0.76 + progress * 0.18
        settings.sourceMix = 0.5 + progress * 0.16
        settings.spiral = signed(progress, amplitude: 0.42, variant: variant)
        settings.fractal = 0.42 + progress * 0.66
        settings.plasma = 0.2 + progress * 0.24
        settings.rings = 0.14 + progress * 0.28
        settings.universe = 0.18 + progress * 0.34
        settings.bloom = 0.28 + progress * 0.52
        settings.edgeGlow = 0.18 + progress * 0.36
        settings.chromaSplit = 0.006 + progress * 0.014
        settings.hueShift = 0.08 + progress * 0.34
        settings.vignette = 0.12 + progress * 0.22
        return settings
    }

    private static func parallelUniverse(progress: Float, variant: Int) -> EffectSettings {
        var settings = EffectSettings.baseline
        settings.colorSpace = (variant % 2 == 0 ? ColorSpaceMode.prismIce : ColorSpaceMode.minterSynesthesia).shaderIndex
        settings.feedback = 0.8 + progress * 0.16
        settings.sourceMix = 0.46 + progress * 0.36
        settings.zoom = 1.01 + progress * 0.03
        settings.rotation = signed(progress, amplitude: 0.1, variant: variant)
        settings.universe = 0.34 + progress * 0.62
        settings.reflection = 0.18 + progress * 0.24
        settings.refraction = 0.14 + progress * 0.22
        settings.kaleidoscope = 2.0 + Float(variant % 6)
        settings.feedbackWarp = 0.24 + progress * 0.46
        settings.temporalJitter = 0.08 + progress * 0.22
        settings.hueShift = 0.16 + progress * 0.44
        settings.saturation = 1.14 + progress * 0.5
        settings.fractal = 0.16 + progress * 0.3
        settings.moire = 0.08 + progress * 0.2
        settings.bloom = 0.2 + progress * 0.22
        return settings
    }

    private static func signed(_ progress: Float, amplitude: Float, variant: Int) -> Float {
        let centered = (progress * 2.0) - 1.0
        let direction: Float = variant.isMultiple(of: 2) ? 1.0 : -1.0
        return centered * amplitude * direction
    }
}
