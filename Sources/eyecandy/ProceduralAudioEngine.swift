import AVFoundation
import Foundation

final class ProceduralAudioEngine {
    private struct SynthState {
        var muted = false
        var masterVolume: Float = 0.58
        var tempo: Float = 118.0
        var droneMix: Float = 0.42
        var pulseMix: Float = 0.34
        var percussionMix: Float = 0.26
        var shimmer: Float = 0.38
        var stereoWidth: Float = 0.44
        var brightness: Float = 0.45
        var motion: Float = 0.22
        var glitch: Float = 0.12
        var baseFrequency: Double = 110.0
        var scale: [Int] = [0, 3, 7, 10]
    }

    private let engine = AVAudioEngine()
    private let stateLock = NSLock()
    private let metricsLock = NSLock()
    private var state = SynthState()
    private var metrics = AudioReactiveMetrics.neutral
    private var sourceNode: AVAudioSourceNode?
    private var sampleRate: Double = 48_000.0
    private var transport: Double = 0.0
    private var dronePhaseA: Double = 0.0
    private var dronePhaseB: Double = 0.0
    private var pulsePhase: Double = 0.0
    private var shimmerPhase: Double = 0.0
    private var panPhase: Double = 0.0
    private var noiseState: UInt64 = 0x1234_5678_ABCD_EF12

    init() {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            self?.render(frameCount: Int(frameCount), audioBufferList: audioBufferList) ?? noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
        engine.prepare()
        try? engine.start()
    }

    func update(settings: EffectSettings, family: PresetFamily, audio: AudioSettings) {
        var next = SynthState()
        next.muted = audio.muted
        next.masterVolume = audio.masterVolume
        next.tempo = audio.tempo
        next.droneMix = audio.droneMix
        next.pulseMix = audio.pulseMix
        next.percussionMix = audio.percussionMix
        next.shimmer = audio.shimmer
        next.stereoWidth = audio.stereoWidth
        next.brightness = min(max((settings.saturation - 0.6) / 1.8 + settings.bloom * 0.3, 0.0), 1.0)
        next.motion = min(max(abs(settings.rotation) * 2.8 + abs(settings.spiral) * 0.45 + settings.wobble * 0.7, 0.0), 1.0)
        next.glitch = min(max(settings.xorField * 0.55 + settings.moire * 0.35 + settings.strobe * 0.4, 0.0), 1.0)
        next.baseFrequency = baseFrequency(for: family, settings: settings)
        next.scale = scale(for: family)

        stateLock.lock()
        state = next
        stateLock.unlock()

        engine.mainMixerNode.outputVolume = audio.muted ? 0.0 : 0.9
        if !engine.isRunning {
            try? engine.start()
        }
    }

    func currentMetrics() -> AudioReactiveMetrics {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return metrics
    }

    private func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let leftBase = buffers[0].mData?.assumingMemoryBound(to: Float.self) else {
            return noErr
        }

        let rightBase = buffers.count > 1
            ? buffers[1].mData?.assumingMemoryBound(to: Float.self)
            : leftBase

        let currentState = lockedState()

        let twoPi = Double.pi * 2.0
        let stepRate = Double(currentState.tempo) / 60.0
        let audibleVolume = currentState.muted ? 0.0 : Double(currentState.masterVolume)
        var rmsAccumulator = 0.0
        var bassPeak = 0.0
        var shimmerPeak = 0.0
        var latestBeatPhase = 0.0

        for frame in 0 ..< frameCount {
            let time = transport / sampleRate
            let beat = time * stepRate
            let lane = beat * 4.0
            let step = Int(floor(lane))
            let frac = lane - floor(lane)
            latestBeatPhase = frac

            let note = currentState.scale[step % currentState.scale.count]
            let accentNote = currentState.scale[(step + 2) % currentState.scale.count] + ((step / 8).isMultiple(of: 2) ? 12 : 0)
            let carrier = currentState.baseFrequency * pow(2.0, Double(note) / 12.0)
            let pulseFrequency = currentState.baseFrequency * pow(2.0, Double(accentNote) / 12.0)
            let shimmerFrequency = carrier * (1.48 + Double(currentState.shimmer) * 0.18)

            let fm = sin(dronePhaseB * 0.5) * Double(currentState.motion) * 18.0
            dronePhaseA += twoPi * (carrier + fm) / sampleRate
            dronePhaseB += twoPi * ((carrier * 0.503) + Double(currentState.glitch) * 2.0) / sampleRate
            pulsePhase += twoPi * pulseFrequency / sampleRate
            shimmerPhase += twoPi * shimmerFrequency / sampleRate
            panPhase += twoPi * (0.06 + Double(currentState.motion) * 0.16) / sampleRate

            let accent = step.isMultiple(of: 8) ? 1.0 : 0.58
            let pulseEnvelope = exp(-frac * (6.0 - Double(currentState.percussionMix) * 3.0))
            let percussionEnvelope = exp(-frac * 22.0)

            let drone = (sin(dronePhaseA) * 0.36 + sin(dronePhaseB) * 0.22 + sin(dronePhaseA * 0.5) * 0.18) * Double(currentState.droneMix)
            let pulse = tanh(sin(pulsePhase) * (2.6 + Double(currentState.brightness) * 5.0)) * Double(currentState.pulseMix) * pulseEnvelope * accent
            let shimmer = sin(shimmerPhase + sin(dronePhaseA) * Double(currentState.shimmer) * 0.65) * 0.16 * Double(currentState.shimmer)
            let percussion = (randomUnit() - 0.5) * percussionEnvelope * Double(currentState.percussionMix) * (0.25 + Double(currentState.glitch) * 0.8)

            var sample = (drone + pulse + shimmer + percussion) * Double(currentState.masterVolume)
            sample = tanh(sample * 1.8) * 0.82

            rmsAccumulator += abs(sample)
            bassPeak = max(bassPeak, abs(pulse))
            shimmerPeak = max(shimmerPeak, abs(shimmer))

            let pan = sin(panPhase) * Double(currentState.stereoWidth) * 0.72
            leftBase[frame] = Float(clamped(sample * audibleVolume * (1.0 - pan)))
            rightBase?[frame] = Float(clamped(sample * audibleVolume * (1.0 + pan)))
            transport += 1.0
        }

        updateMetrics(
            level: Float(min(max((rmsAccumulator / Double(max(frameCount, 1))) * 2.1, 0.0), 1.0)),
            bass: Float(min(max(bassPeak * 1.5, 0.0), 1.0)),
            shimmer: Float(min(max(shimmerPeak * 2.5, 0.0), 1.0)),
            beatPhase: Float(latestBeatPhase)
        )

        return noErr
    }

    private func lockedState() -> SynthState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state
    }

    private func zero(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>?, frames: Int) {
        for frame in 0 ..< frames {
            left[frame] = 0.0
            right?[frame] = 0.0
        }
    }

    private func updateMetrics(level: Float, bass: Float, shimmer: Float, beatPhase: Float) {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        metrics.level = metrics.level * 0.76 + level * 0.24
        metrics.bass = metrics.bass * 0.70 + bass * 0.30
        metrics.shimmer = metrics.shimmer * 0.72 + shimmer * 0.28
        metrics.beatPhase = beatPhase
    }

    private func randomUnit() -> Double {
        noiseState = noiseState &* 6364136223846793005 &+ 1
        return Double((noiseState >> 33) & 0xFFFF) / Double(0xFFFF)
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, -1.0), 1.0)
    }

    private func baseFrequency(for family: PresetFamily, settings: EffectSettings) -> Double {
        let base: Double
        switch family {
        case .trueFeedback:
            base = 82.41
        case .hallOfMirrors:
            base = 92.50
        case .prismSimulator:
            base = 110.00
        case .chromaLuma:
            base = 123.47
        case .kaleidoscope:
            base = 130.81
        case .plasmaTunnel:
            base = 98.00
        case .rasterRoto:
            base = 146.83
        case .xorMoire:
            base = 155.56
        case .fractalBloom:
            base = 87.31
        case .parallelUniverse:
            base = 103.83
        }

        let contour = Double(settings.feedbackWarp * 22.0 + settings.kaleidoscope * 0.7 + settings.universe * 15.0)
        return base + contour
    }

    private func scale(for family: PresetFamily) -> [Int] {
        switch family {
        case .trueFeedback:
            return [0, 3, 7, 10]
        case .hallOfMirrors:
            return [0, 1, 5, 7, 10]
        case .prismSimulator:
            return [0, 2, 4, 7, 9]
        case .chromaLuma:
            return [0, 3, 5, 8, 10]
        case .kaleidoscope:
            return [0, 2, 5, 7, 9, 11]
        case .plasmaTunnel:
            return [0, 3, 5, 7, 10]
        case .rasterRoto:
            return [0, 4, 7, 9, 11]
        case .xorMoire:
            return [0, 1, 4, 6, 10]
        case .fractalBloom:
            return [0, 3, 6, 7, 10]
        case .parallelUniverse:
            return [0, 2, 3, 7, 9, 10]
        }
    }
}
