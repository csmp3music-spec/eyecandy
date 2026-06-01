import AVFoundation
import Foundation

final class ProceduralAudioEngine {
    private struct RenderState {
        var sequencer = SequencerState()
        var bassVoice = SynthVoice()
        var leadVoice = SynthVoice(instrument: .syncLead, level: 0.30, octave: 4, cutoff: 0.68, resonance: 0.18, glide: 0.08, accent: 0.45)
        var delaySettings = MultiTapDelaySettings()
        var liveNotes: Set<Int> = []
        var masterLevel = 0.55
    }

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var state = RenderState()
    private var sourceNode: AVAudioSourceNode?
    private var sampleTime = 0.0
    private var lastStep = -1
    private var kickEnv = 0.0
    private var snareEnv = 0.0
    private var hatEnv = 0.0
    private var clapEnv = 0.0
    private var activeBassStep = false
    private var activeLeadStep = false
    private var bassStepVelocity = 0.0
    private var leadStepVelocity = 0.0
    private var kickVelocity = 0.0
    private var snareVelocity = 0.0
    private var hatVelocity = 0.0
    private var clapVelocity = 0.0
    private var bassRatchet = 1
    private var leadRatchet = 1
    private var kickRatchet = 1
    private var snareRatchet = 1
    private var hatRatchet = 1
    private var clapRatchet = 1
    private var lastKickRatchet = 0
    private var lastSnareRatchet = 0
    private var lastHatRatchet = 0
    private var lastClapRatchet = 0
    private var bassPhase = 0.0
    private var leadPhase = 0.0
    private var bassFilterState = 0.0
    private var leadFilterState = 0.0
    private var livePhases: [Int: Double] = [:]
    private let sampleRate = 44_100.0
    private var delayBuffer = Array(repeating: 0.0, count: 44_100 * 8)
    private var delayWriteIndex = 0

    var isRunning: Bool { engine.isRunning }

    func start() throws {
        if sourceNode == nil {
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
                self?.render(frameCount: Int(frameCount), audioBufferList: audioBufferList) ?? noErr
            }
            sourceNode = node
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.85
            engine.prepare()
        }

        if !engine.isRunning {
            try engine.start()
        }
    }

    func stop() {
        engine.stop()
    }

    func update(sequencer: SequencerState, bassVoice: SynthVoice, leadVoice: SynthVoice, delaySettings: MultiTapDelaySettings, liveNotes: Set<Int>, masterLevel: Double) {
        lock.lock()
        state.sequencer = sequencer
        state.bassVoice = bassVoice
        state.leadVoice = leadVoice
        state.delaySettings = delaySettings
        state.liveNotes = liveNotes
        state.masterLevel = masterLevel
        lock.unlock()
    }

    private func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        lock.lock()
        let snapshot = state
        lock.unlock()

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let secondsPerStep = 60.0 / max(40.0, snapshot.sequencer.bpm) / 4.0
        let patternLength = max(1, min(16, snapshot.sequencer.patternLength))

        for frame in 0..<frameCount {
            let swung = swungStepPosition(time: sampleTime, secondsPerStep: secondsPerStep, sequencer: snapshot.sequencer)
            let absoluteStep = Int(floor(swung))
            let step = absoluteStep % patternLength
            let stepPhase = swung - floor(swung)

            if step != lastStep {
                lastStep = step
                if snapshot.sequencer.isPlaying {
                    latchStep(snapshot.sequencer, absoluteStep: absoluteStep)
                }
            }

            updateDrumRatchets(stepPhase: stepPhase)

            var sample = 0.0
            if snapshot.sequencer.isPlaying {
                let bassStep = laneStep(snapshot.sequencer.bass, absoluteStep: absoluteStep)
                let leadStep = laneStep(snapshot.sequencer.lead, absoluteStep: absoluteStep)
                sample += synthSample(lane: snapshot.sequencer.bass, voice: snapshot.bassVoice, step: bassStep, phase: stepPhase, phaseStore: &bassPhase, filterState: &bassFilterState, baseNote: 36, active: activeBassStep, velocity: bassStepVelocity, ratchet: bassRatchet)
                sample += synthSample(lane: snapshot.sequencer.lead, voice: snapshot.leadVoice, step: leadStep, phase: stepPhase, phaseStore: &leadPhase, filterState: &leadFilterState, baseNote: 60, active: activeLeadStep, velocity: leadStepVelocity, ratchet: leadRatchet)
                sample += drumSample()
            }
            sample += liveKeyboardSample(notes: snapshot.liveNotes)
            sample = applyMultiTapDelay(sample, settings: snapshot.delaySettings, secondsPerBeat: 60.0 / max(40.0, snapshot.sequencer.bpm))
            sample = tanh(sample * snapshot.masterLevel)

            for buffer in buffers {
                let pointer = buffer.mData!.assumingMemoryBound(to: Float.self)
                pointer[frame] = Float(sample)
            }
            sampleTime += 1.0 / sampleRate
        }

        return noErr
    }

    private func latchStep(_ sequencer: SequencerState, absoluteStep: Int) {
        let bassStep = laneStep(sequencer.bass, absoluteStep: absoluteStep)
        let leadStep = laneStep(sequencer.lead, absoluteStep: absoluteStep)
        let kickStep = laneStep(sequencer.kick, absoluteStep: absoluteStep)
        let snareStep = laneStep(sequencer.snare, absoluteStep: absoluteStep)
        let hatStep = laneStep(sequencer.hat, absoluteStep: absoluteStep)
        let clapStep = laneStep(sequencer.clap, absoluteStep: absoluteStep)

        activeBassStep = stepPasses(sequencer.bass, step: bassStep, absoluteStep: absoluteStep, salt: 11)
        activeLeadStep = stepPasses(sequencer.lead, step: leadStep, absoluteStep: absoluteStep, salt: 17)
        bassStepVelocity = performedVelocity(sequencer.bass, step: bassStep, absoluteStep: absoluteStep, salt: 101, humanize: sequencer.humanize)
        leadStepVelocity = performedVelocity(sequencer.lead, step: leadStep, absoluteStep: absoluteStep, salt: 107, humanize: sequencer.humanize)
        bassRatchet = sequencer.bass.ratchets[bassStep]
        leadRatchet = sequencer.lead.ratchets[leadStep]

        if stepPasses(sequencer.kick, step: kickStep, absoluteStep: absoluteStep, salt: 23) {
            kickVelocity = performedVelocity(sequencer.kick, step: kickStep, absoluteStep: absoluteStep, salt: 109, humanize: sequencer.humanize)
            kickRatchet = sequencer.kick.ratchets[kickStep]
            lastKickRatchet = 0
            kickEnv = kickVelocity
        }
        if stepPasses(sequencer.snare, step: snareStep, absoluteStep: absoluteStep, salt: 29) {
            snareVelocity = performedVelocity(sequencer.snare, step: snareStep, absoluteStep: absoluteStep, salt: 113, humanize: sequencer.humanize)
            snareRatchet = sequencer.snare.ratchets[snareStep]
            lastSnareRatchet = 0
            snareEnv = snareVelocity
        }
        if stepPasses(sequencer.hat, step: hatStep, absoluteStep: absoluteStep, salt: 31) {
            hatVelocity = performedVelocity(sequencer.hat, step: hatStep, absoluteStep: absoluteStep, salt: 127, humanize: sequencer.humanize)
            hatRatchet = sequencer.hat.ratchets[hatStep]
            lastHatRatchet = 0
            hatEnv = hatVelocity
        }
        if stepPasses(sequencer.clap, step: clapStep, absoluteStep: absoluteStep, salt: 37) {
            clapVelocity = performedVelocity(sequencer.clap, step: clapStep, absoluteStep: absoluteStep, salt: 131, humanize: sequencer.humanize)
            clapRatchet = sequencer.clap.ratchets[clapStep]
            lastClapRatchet = 0
            clapEnv = clapVelocity
        }
    }

    private func updateDrumRatchets(stepPhase: Double) {
        retriggerDrum(ratchet: kickRatchet, stepPhase: stepPhase, last: &lastKickRatchet, env: &kickEnv, velocity: kickVelocity)
        retriggerDrum(ratchet: snareRatchet, stepPhase: stepPhase, last: &lastSnareRatchet, env: &snareEnv, velocity: snareVelocity)
        retriggerDrum(ratchet: hatRatchet, stepPhase: stepPhase, last: &lastHatRatchet, env: &hatEnv, velocity: hatVelocity)
        retriggerDrum(ratchet: clapRatchet, stepPhase: stepPhase, last: &lastClapRatchet, env: &clapEnv, velocity: clapVelocity)
    }

    private func retriggerDrum(ratchet: Int, stepPhase: Double, last: inout Int, env: inout Double, velocity: Double) {
        guard ratchet > 1, velocity > 0 else { return }
        let subStep = min(ratchet - 1, Int(stepPhase * Double(ratchet)))
        if subStep > last {
            last = subStep
            env = velocity * pow(0.86, Double(subStep))
        }
    }

    private func synthSample(lane: StepLane, voice: SynthVoice, step: Int, phase: Double, phaseStore: inout Double, filterState: inout Double, baseNote: Int, active: Bool, velocity: Double, ratchet: Int) -> Double {
        guard voice.enabled, active else { return 0 }
        let note = baseNote + voice.octave * 12 + lane.notes[step]
        let freq = midiFrequency(note)
        phaseStore = (phaseStore + freq / sampleRate).truncatingRemainder(dividingBy: 1)
        let saw = 2.0 * phaseStore - 1.0
        let square = phaseStore < 0.5 ? 1.0 : -1.0
        let sine = sin(phaseStore * .pi * 2.0)
        let octaveSaw = 2.0 * ((phaseStore * 2.0).truncatingRemainder(dividingBy: 1)) - 1.0
        let sub = phaseStore < 0.25 || (phaseStore > 0.5 && phaseStore < 0.75) ? 1.0 : -1.0
        let lfo = sin(sampleTime * (0.08 + voice.lfoRate * 14.0) * .pi * 2.0)
        let slow = lfo * 0.5 + 0.5
        let morph = min(1.0, max(0.0, voice.morph + lfo * voice.lfoAmount * 0.45))
        let detune = 0.003 + voice.detune * 0.024
        let unisonA = 2.0 * ((phaseStore + detune).truncatingRemainder(dividingBy: 1)) - 1.0
        let unisonB = 2.0 * ((phaseStore - detune * 0.7 + 1.0).truncatingRemainder(dividingBy: 1)) - 1.0
        let unisonSaw = saw * (1.0 - voice.unison) + ((saw + unisonA + unisonB) / 3.0) * voice.unison
        let fmIndex = 0.35 + voice.fmAmount * 7.0
        let fm = sin((phaseStore * .pi * 2.0) + sin(phaseStore * .pi * 2.0 * (2.0 + voice.resonance * 8.0)) * fmIndex)
        let formant = sin(phaseStore * .pi * 2.0) * 0.42
            + sin(phaseStore * .pi * 6.0) * (0.22 + voice.resonance * 0.18)
            + sin(phaseStore * .pi * 10.0) * (0.08 + voice.cutoff * 0.12)
        let noise = Double.random(in: -1...1)
        let ring = sine * sin(sampleTime * freq * (1.25 + voice.fmAmount * 7.0) * .pi * 2.0)
        let distortedPhase = (phaseStore + sin(phaseStore * .pi * 2.0) * (0.08 + voice.morph * 0.42)).truncatingRemainder(dividingBy: 1)
        let phaseDist = sin(distortedPhase * .pi * 2.0)
        let grainWindow = pow(max(0.0, sin(phase * .pi * Double(2 + Int(voice.grainDensity * 9.0)))), 0.5 + voice.grainSize * 2.4)
        let grain = (sin((phaseStore + floor(sampleTime * (8.0 + voice.grainDensity * 80.0)) * 0.037).truncatingRemainder(dividingBy: 1) * .pi * 2.0) * 0.55 + noise * 0.45) * grainWindow
        let pluck = (saw * 0.45 + noise * 0.55) * exp(-phase * (4.0 + voice.decay * 12.0))
        let spectral = sine * 0.22
            + sin(phaseStore * .pi * 2.0 * (1.5 + morph * 3.5)) * 0.24
            + sin(phaseStore * .pi * 2.0 * (2.25 + voice.resonance * 5.0)) * 0.18
        let raw: Double
        switch voice.instrument {
        case .acidSaw:
            raw = unisonSaw * 0.72 + square * 0.28
        case .subSquare:
            raw = square * 0.78 + sine * 0.22
        case .superSaw:
            raw = unisonSaw * 0.78 + sine * 0.22
        case .fmBell:
            raw = fm * (0.62 + slow * 0.28)
        case .glassPad:
            raw = sine * 0.46 + sin(phaseStore * .pi * 4.0 + slow) * 0.28 + sin(phaseStore * .pi * 7.0) * 0.12
        case .noiseOrgan:
            raw = sine * 0.36 + square * 0.22 + noise * (0.16 + voice.resonance * 0.16)
        case .syncLead:
            raw = unisonSaw * 0.48 + octaveSaw * 0.36 + square * 0.16
        case .formantVox:
            raw = formant
        case .wavetableMorph:
            raw = sine * (1.0 - morph) + unisonSaw * morph * 0.62 + fm * morph * 0.28
        case .granularCloud:
            raw = grain
        case .reeseBass:
            raw = (unisonSaw * 0.62 + sub * 0.38) * (0.72 + 0.28 * sin(sampleTime * freq * 0.035))
        case .phaseDistortion:
            raw = phaseDist * 0.78 + unisonSaw * 0.22
        case .ringModKeys:
            raw = ring * 0.72 + sine * 0.24
        case .karplusPluck:
            raw = pluck
        case .bitcrushLead:
            raw = unisonSaw * 0.58 + square * 0.22 + fm * 0.20
        case .spectralDrone:
            raw = spectral + noise * voice.noiseLevel * 0.65
        }
        let ratchetPhase = (phase * Double(max(1, ratchet))).truncatingRemainder(dividingBy: 1)
        let attack = max(0.001, voice.attack * 0.45)
        let decay = max(0.05, voice.decay)
        let env: Double
        if ratchetPhase < attack {
            env = ratchetPhase / attack
        } else {
            let decayPhase = (ratchetPhase - attack) / max(0.05, 1.0 - attack)
            env = voice.sustain + (1.0 - voice.sustain) * exp(-decayPhase * (1.0 + decay * 8.0))
        }
        let accent = step % 4 == 0 ? 1.0 + voice.accent : 1.0
        var shaped = raw + sub * voice.subLevel * 0.45 + noise * voice.noiseLevel
        let fold = max(0.0, voice.wavefold)
        shaped = sin(shaped * (1.0 + fold * 6.0))
        shaped = tanh(shaped * (1.0 + voice.drive * 8.0))
        let cutoffEnvelope = env * voice.filterEnvelope + lfo * voice.lfoAmount * 0.18
        let cutoff = min(0.98, max(0.02, voice.cutoff + cutoffEnvelope * 0.42))
        let coeff = 0.025 + pow(cutoff, 2.0) * 0.72
        filterState += (shaped - filterState) * coeff
        let filtered = filterState + (shaped - filterState) * voice.resonance * 0.35
        let crushed = applyBitcrush(filtered, amount: max(voice.bitcrush, voice.instrument == .bitcrushLead ? 0.45 : 0.0))
        return crushed * env * voice.level * accent * velocity
    }

    private func drumSample() -> Double {
        let noise = Double.random(in: -1...1)
        let kick = sin((1.0 - kickEnv) * 90.0) * kickEnv * 1.25
        let snare = noise * snareEnv * 0.48
        let hat = noise * hatEnv * 0.22
        let clap = (noise * 0.62 + sin(sampleTime * 2_700.0) * 0.18) * clapEnv * 0.34
        kickEnv *= 0.997
        snareEnv *= 0.975
        hatEnv *= 0.88
        clapEnv *= 0.965
        if kickEnv < 0.0001 { kickEnv = 0 }
        if snareEnv < 0.0001 { snareEnv = 0 }
        if hatEnv < 0.0001 { hatEnv = 0 }
        if clapEnv < 0.0001 { clapEnv = 0 }
        return kick + snare + hat + clap
    }

    private func applyBitcrush(_ value: Double, amount: Double) -> Double {
        let amount = min(1.0, max(0.0, amount))
        guard amount > 0.001 else { return value }
        let levels = max(4.0, 128.0 - amount * 120.0)
        return round(value * levels) / levels
    }

    private func liveKeyboardSample(notes: Set<Int>) -> Double {
        var mixed = 0.0
        let active = max(1, notes.count)
        for note in notes {
            let freq = midiFrequency(note)
            var phase = livePhases[note] ?? 0
            phase = (phase + freq / sampleRate).truncatingRemainder(dividingBy: 1)
            livePhases[note] = phase
            mixed += sin(phase * .pi * 2.0) * 0.32 / Double(active)
        }
        livePhases = livePhases.filter { notes.contains($0.key) }
        return mixed
    }

    private func applyMultiTapDelay(_ input: Double, settings: MultiTapDelaySettings, secondsPerBeat: Double) -> Double {
        guard settings.enabled else {
            delayBuffer[delayWriteIndex] = input
            delayWriteIndex = (delayWriteIndex + 1) % delayBuffer.count
            return input
        }

        var wet = 0.0
        var feedbackFeed = 0.0
        for tap in settings.taps where tap.enabled {
            let delaySamples = max(1, min(delayBuffer.count - 1, Int(tap.beatOffset * secondsPerBeat * sampleRate)))
            let readIndex = (delayWriteIndex - delaySamples + delayBuffer.count) % delayBuffer.count
            let delayed = delayBuffer[readIndex]
            wet += delayed * tap.level
            feedbackFeed += delayed * tap.feedback
        }

        let feedback = min(0.92, max(0, settings.globalFeedback)) * feedbackFeed
        delayBuffer[delayWriteIndex] = tanh(input + feedback)
        delayWriteIndex = (delayWriteIndex + 1) % delayBuffer.count

        let wetMix = min(1, max(0, settings.wet))
        return input * (1.0 - wetMix * 0.55) + wet * wetMix
    }

    private func swungStepPosition(time: Double, secondsPerStep: Double, sequencer: SequencerState) -> Double {
        let raw = time / secondsPerStep
        let pair = floor(raw / 2.0)
        let phase = raw - pair * 2.0
        let shift = min(0.65, max(0, sequencer.swing + grooveSwingBias(sequencer.groove))) * 0.5
        if phase < 1.0 + shift {
            return pair * 2.0 + phase / (1.0 + shift)
        }
        return pair * 2.0 + 1.0 + (phase - 1.0 - shift) / max(0.2, 1.0 - shift)
    }

    private func grooveSwingBias(_ groove: GrooveTemplate) -> Double {
        switch groove {
        case .straight:
            return 0
        case .mpcShuffle:
            return 0.10
        case .brokenBeat:
            return 0.06
        case .electroPush:
            return 0.03
        case .garageSkip:
            return 0.14
        case .dillaDrift:
            return 0.18
        }
    }

    private func laneStep(_ lane: StepLane, absoluteStep: Int) -> Int {
        max(0, absoluteStep % max(1, min(lane.length, lane.steps.count)))
    }

    private func stepPasses(_ lane: StepLane, step: Int, absoluteStep: Int, salt: Int) -> Bool {
        guard step < lane.steps.count, lane.steps[step] else { return false }
        let probability = step < lane.probabilities.count ? lane.probabilities[step] : 1.0
        guard probability < 0.999 else { return true }
        return deterministicUnit(absoluteStep: absoluteStep, step: step, salt: salt) <= probability
    }

    private func performedVelocity(_ lane: StepLane, step: Int, absoluteStep: Int, salt: Int, humanize: Double) -> Double {
        let base = step < lane.velocities.count ? lane.velocities[step] : 0.82
        let jitter = (deterministicUnit(absoluteStep: absoluteStep, step: step, salt: salt) * 2.0 - 1.0) * humanize * 0.32
        return min(1.0, max(0.05, base + jitter))
    }

    private func deterministicUnit(absoluteStep: Int, step: Int, salt: Int) -> Double {
        let x = sin(Double(absoluteStep * 9_973 + step * 313 + salt * 1_271) * 12.9898) * 43_758.5453
        return x - floor(x)
    }

    private func midiFrequency(_ note: Int) -> Double {
        440.0 * pow(2.0, Double(note - 69) / 12.0)
    }
}
