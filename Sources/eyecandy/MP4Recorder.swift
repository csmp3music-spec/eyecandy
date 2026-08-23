import AVFoundation
import CoreGraphics
import Foundation

struct MP4RecordingRequest {
    var preset: VisualPreset
    var sequencer: SequencerState
    var bpm: Double
    var bloom: Double
    var exposure: Double
    var holographicMode: HolographicMode
    var hologramDepth: Double
    var minterEffectMode: MinterEffectMode
    var minterIntensity: Double
    var demosceneEffectMode: DemosceneEffectMode
    var demosceneIntensity: Double
    var lightSynthMode: LightSynthMode
    var lightSynthIntensity: Double
    var macroX: Double
    var macroY: Double
    var phosphorPersistence: Double
    var prismSplits: Int
    var flashSafety: Bool
    var paletteMode: LightPaletteMode
    var blendMode: LightBlendMode
    var visualEngineMode: VisualEngineMode
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
    var cameraInputEnabled: Bool
    var cameraOverlayOpacity: Double
    var cameraFeedbackAmount: Double
    var cameraOverlayScale: Double
    var cameraFeedbackMode: CameraFeedbackMode
    var cameraFeedbackRotation: Double
    var cameraLumaThreshold: Double
    var cameraChromaShift: Double
    var cameraMirror: Bool
    var cameraImage: CGImage?
    var stereoscopicMode: StereoscopicMode
    var stereoDepth: Double
    var sceneSeed: Int
    var blackout: Bool
    var freezeFrame: Bool
    var strobeEnabled: Bool
    var strobeRate: Double
    var delaySettings: MultiTapDelaySettings
    var duration: Double
    var fps: Int
    var width: Int
    var height: Int
}

extension MP4RecordingRequest {
    static let fallback = MP4RecordingRequest(
        preset: PresetLibrary.visualPresets[0],
        sequencer: SequencerState(),
        bpm: 132,
        bloom: 0.62,
        exposure: 0.72,
        holographicMode: .off,
        hologramDepth: 0.42,
        minterEffectMode: .off,
        minterIntensity: 0.48,
        demosceneEffectMode: .off,
        demosceneIntensity: 0.62,
        lightSynthMode: .hyperPrism,
        lightSynthIntensity: 0.68,
        macroX: 0.58,
        macroY: 0.64,
        phosphorPersistence: 0.55,
        prismSplits: 5,
        flashSafety: true,
        paletteMode: .neon,
        blendMode: .additive,
        visualEngineMode: .lightTunnel,
        experimentalVideoMode: .clean,
        experimentalVideoIntensity: 0.55,
        videoKeyThreshold: 0.52,
        videoEdgeGain: 0.46,
        videoColorWarp: 0.58,
        videoOscillatorRate: 0.50,
        feedbackSimulatorMode: .feedbackLab,
        feedbackSimulatorIntensity: 0.52,
        feedbackSimulatorDecay: 0.68,
        feedbackSimulatorZoom: 0.46,
        feedbackSimulatorTwist: 0.22,
        feedbackSimulatorDisplacement: 0.54,
        feedbackSimulatorPrism: 0.42,
        feedbackSimulatorAudioReactive: true,
        cameraInputEnabled: false,
        cameraOverlayOpacity: 0.38,
        cameraFeedbackAmount: 0.46,
        cameraOverlayScale: 1.0,
        cameraFeedbackMode: .optical,
        cameraFeedbackRotation: 0.0,
        cameraLumaThreshold: 0.22,
        cameraChromaShift: 0.18,
        cameraMirror: true,
        cameraImage: nil,
        stereoscopicMode: .off,
        stereoDepth: 0.38,
        sceneSeed: 1,
        blackout: false,
        freezeFrame: false,
        strobeEnabled: false,
        strobeRate: 8,
        delaySettings: MultiTapDelaySettings(),
        duration: 1,
        fps: 30,
        width: 1280,
        height: 720
    )
}

enum MP4Recorder {
    static func makePixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &buffer)
        guard status == kCVReturnSuccess, let buffer else {
            throw NSError(domain: "MP4Recorder", code: 7, userInfo: [NSLocalizedDescriptionKey: "Could not allocate live pixel buffer"])
        }
        return buffer
    }

    static func renderFrame(into pixelBuffer: CVPixelBuffer, size: CGSize, request: MP4RecordingRequest, frame: Int) {
        drawFrame(pixelBuffer: pixelBuffer, size: size, request: request, frame: frame)
    }

    static func render(request: MP4RecordingRequest) throws -> URL {
        let outputURL = try makeOutputURL()
        let writer = try AVAssetWriter(url: outputURL, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: request.width,
            AVVideoHeightKey: request.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 9_000_000
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: request.width,
            kCVPixelBufferHeightKey as String: request.height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw NSError(domain: "MP4Recorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
        }
        writer.add(input)
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "MP4Recorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not start MP4 writer"])
        }
        writer.startSession(atSourceTime: .zero)

        let totalFrames = max(1, Int(request.duration * Double(request.fps)))
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(request.fps))
        let size = CGSize(width: request.width, height: request.height)

        for frame in 0..<totalFrames {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.002)
            }

            guard let pool = adaptor.pixelBufferPool else {
                throw NSError(domain: "MP4Recorder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Pixel buffer pool unavailable"])
            }

            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let pixelBuffer = buffer else {
                throw NSError(domain: "MP4Recorder", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not allocate pixel buffer"])
            }

            drawFrame(pixelBuffer: pixelBuffer, size: size, request: request, frame: frame)
            let time = CMTimeMultiply(frameDuration, multiplier: Int32(frame))
            if !adaptor.append(pixelBuffer, withPresentationTime: time) {
                throw writer.error ?? NSError(domain: "MP4Recorder", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not append frame"])
            }
        }

        input.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status == .failed {
            throw writer.error ?? NSError(domain: "MP4Recorder", code: 6, userInfo: [NSLocalizedDescriptionKey: "MP4 writer failed"])
        }

        return outputURL
    }

    private static func makeOutputURL() throws -> URL {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let directory = root.appendingPathComponent("recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return directory.appendingPathComponent("eyecandy-\(formatter.string(from: Date())).mp4")
    }

    private static func drawFrame(pixelBuffer: CVPixelBuffer, size: CGSize, request: MP4RecordingRequest, frame: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: baseAddress,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }

        var t = Double(frame) / Double(max(1, request.fps))
        if request.freezeFrame { t = 0 }
        let beat = (t * request.bpm / 60.0).truncatingRemainder(dividingBy: 1)
        context.setFillColor(CGColor(red: 0.005, green: 0.004, blue: 0.012, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        if request.blackout { return }

        drawSelectedExportEngine(context, size: size, request: request, time: t, beat: beat, stereoOffset: 0)
        drawStereoExportLayer(context, size: size, request: request, time: t, beat: beat)
        drawDemosceneLayer(context, size: size, request: request, time: t, beat: beat)
        drawAdvancedLightSynthLayer(context, size: size, request: request, time: t, beat: beat)
        drawVisualDelayTaps(context, size: size, request: request, time: t)
        drawMinterLayer(context, size: size, request: request, time: t, beat: beat)
        drawHolographicLayer(context, size: size, request: request, time: t, beat: beat)
        drawPaletteAndGate(context, size: size, request: request, time: t)
        drawExperimentalVideoMode(context, size: size, request: request, time: t, beat: beat)
        drawFeedbackSimulatorLayer(context, size: size, request: request, time: t, beat: beat)
        drawCameraFeedbackOverlay(context, size: size, request: request, time: t)
    }

    private static func drawSelectedExportEngine(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, stereoOffset: Double) {
        let mode = resolvedVisualEngine(request.visualEngineMode, time: time)
        switch mode {
        case .lightTunnel, .engineAutopilot:
            drawCoreLightSynth(context, size: size, request: request, time: time, beat: beat, stereoOffset: stereoOffset)
        case .vectorField:
            drawVectorFieldEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .metaballs, .liquidCells:
            drawMetaballsEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .terrainGrid:
            drawTerrainGridEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .oscilloscopeRibbons:
            drawOscilloscopeEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .fractalLightning, .shapeConstellation:
            drawConstellationEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .fractalTrees:
            drawFractalTreesEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .particleNebula:
            drawParticleEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .reactionDiffusion:
            drawReactionDiffusionEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .kaleidoscopeMaze:
            drawKaleidoscopeMazeEngine(context: context, size: size, request: request, time: time, beat: beat, stereoOffset: stereoOffset)
        case .moireField:
            drawMoireFieldEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .slitScanRibbons:
            drawSlitScanRibbonsEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        case .cellularAutomata:
            drawCellularAutomataEngine(context: context, size: size, request: request, time: time, stereoOffset: stereoOffset)
        }
    }

    private static func resolvedVisualEngine(_ mode: VisualEngineMode, time: Double) -> VisualEngineMode {
        guard mode == .engineAutopilot else { return mode }
        let engines: [VisualEngineMode] = [.lightTunnel, .vectorField, .metaballs, .terrainGrid, .oscilloscopeRibbons, .fractalLightning, .fractalTrees, .particleNebula, .shapeConstellation, .liquidCells, .reactionDiffusion, .kaleidoscopeMaze, .moireField, .slitScanRibbons, .cellularAutomata]
        return engines[Int(time / 12.0) % engines.count]
    }

    private static func drawStereoExportLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        guard request.stereoscopicMode != .off else { return }
        let depth = 8.0 + request.stereoDepth * 42.0
        switch request.stereoscopicMode {
        case .off:
            return
        case .anaglyph, .depthGhost:
            drawSelectedExportEngine(context, size: size, request: request, time: time + 0.05, beat: beat, stereoOffset: -depth)
            drawSelectedExportEngine(context, size: size, request: request, time: time - 0.05, beat: beat, stereoOffset: depth)
        case .sideBySide:
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
            drawSelectedExportEngine(context, size: CGSize(width: size.width / 2, height: size.height), request: request, time: time + 0.04, beat: beat, stereoOffset: -depth * 0.25)
            context.restoreGState()
            context.saveGState()
            context.translateBy(x: size.width / 2, y: 0)
            context.clip(to: CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
            drawSelectedExportEngine(context, size: CGSize(width: size.width / 2, height: size.height), request: request, time: time - 0.04, beat: beat, stereoOffset: depth * 0.25)
            context.restoreGState()
        case .topBottom:
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: size.height / 2))
            drawSelectedExportEngine(context, size: CGSize(width: size.width, height: size.height / 2), request: request, time: time + 0.04, beat: beat, stereoOffset: -depth * 0.2)
            context.restoreGState()
            context.saveGState()
            context.translateBy(x: 0, y: size.height / 2)
            context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: size.height / 2))
            drawSelectedExportEngine(context, size: CGSize(width: size.width, height: size.height / 2), request: request, time: time - 0.04, beat: beat, stereoOffset: depth * 0.2)
            context.restoreGState()
        case .lineInterlace:
            for row in stride(from: 0.0, to: size.height, by: 6.0) {
                context.setFillColor(CGColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 0.12 + request.stereoDepth * 0.16))
                context.fill(CGRect(x: 0, y: row, width: size.width, height: 2))
            }
        }
    }

    private static func drawCoreLightSynth(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, stereoOffset: Double = 0) {
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let trailCount = Int(36 + request.preset.density * 120)
        let symmetry = max(1, request.preset.symmetry)
        let hueBase = Double((request.preset.id * 37) % 360) / 360.0

        context.setLineCap(.round)
        context.setBlendMode(.plusLighter)

        for i in 0..<trailCount {
            let amount = Double(i) / Double(max(1, trailCount - 1))
            let radius = shortest * (0.035 + amount * 0.56)
            let spin = time * (0.3 + request.preset.warp * 0.9) + amount * .pi * 6.0 + beat * .pi * 2.0
            let alpha = max(0.04, 0.72 - amount * 0.55)
            let color = neonColor(hueBase + amount * 0.46 + beat * 0.08, alpha: alpha * request.exposure)
            context.setStrokeColor(color)
            context.setLineWidth(1.0 + (1.0 - amount) * 4.0)

            for spoke in 0..<symmetry {
                let path = CGMutablePath()
                let angle = spin + Double(spoke) / Double(symmetry) * .pi * 2.0
                for pointIndex in 0..<48 {
                    let u = Double(pointIndex) / 47.0
                    let wave = sin(u * .pi * (3.0 + request.preset.density * 9.0) + time * (2.0 + request.preset.warp * 8.0))
                    let r = radius * (0.54 + u * 0.92) + wave * request.preset.warp * 42.0
                    let a = angle + u * (0.85 + request.preset.warp * 1.1) + sin(time + u * 12.0) * 0.16
                    let point = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
                    if pointIndex == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.addPath(path)
                context.strokePath()
            }
        }
    }

    private static func drawVectorFieldEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let cols = 28
        let rows = 18
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let hueBase = Double((request.preset.id * 37) % 360) / 360.0
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let angle = atan2(ny, nx) + sin(nx * 8 + time) + cos(ny * 7 - time * 1.3)
                let length = 10.0 + request.preset.warp * 44.0
                let origin = CGPoint(x: Double(x) * cellW + cellW / 2 + stereoOffset, y: Double(y) * cellH + cellH / 2)
                context.setStrokeColor(neonColor(hueBase + nx + ny + time * 0.04, alpha: 0.34))
                context.setLineWidth(1.2)
                context.move(to: CGPoint(x: origin.x - cos(angle) * length * 0.45, y: origin.y - sin(angle) * length * 0.45))
                context.addLine(to: CGPoint(x: origin.x + cos(angle) * length, y: origin.y + sin(angle) * length))
                context.strokePath()
            }
        }
    }

    private static func drawMetaballsEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.screen)
        let cols = 46
        let rows = 28
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let hueBase = Double((request.preset.id * 41) % 360) / 360.0
        var centers: [CGPoint] = []
        for index in 0..<7 {
            let i = Double(index)
            centers.append(CGPoint(
                x: size.width * (0.5 + sin(time * (0.17 + i * 0.03) + i) * 0.38) + stereoOffset,
                y: size.height * (0.5 + cos(time * (0.13 + i * 0.04) + i * 1.7) * 0.35)
            ))
        }
        for y in 0..<rows {
            for x in 0..<cols {
                let px = Double(x) * cellW
                let py = Double(y) * cellH
                var field = 0.0
                for center in centers {
                    let dx = px - center.x
                    let dy = py - center.y
                    field += 9500.0 / Swift.max(120.0, dx * dx + dy * dy)
                }
                if field > 0.42 {
                    context.setFillColor(neonColor(hueBase + field + time * 0.05, alpha: min(0.32, (field - 0.42) * 0.20)))
                    context.fill(CGRect(x: px, y: py, width: cellW + 1, height: cellH + 1))
                }
            }
        }
    }

    private static func drawTerrainGridEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let horizon = size.height * 0.58
        let hueBase = Double((request.preset.id * 29) % 360) / 360.0
        for row in 0..<24 {
            let depth = Double(row) / 24.0
            let y = horizon + pow(depth, 2.1) * size.height * 0.55
            context.setStrokeColor(neonColor(hueBase + depth + time * 0.02, alpha: 0.15 + depth * 0.42))
            context.setLineWidth(1.0 + depth * 2.0)
            context.beginPath()
            for col in 0...64 {
                let xNorm = Double(col) / 64.0 * 2.0 - 1.0
                let perspective = 1.0 + depth * 4.0
                let wave = sin(xNorm * 7.0 + time * 1.7 + depth * 9.0) * 24.0 * depth
                let x = size.width / 2 + xNorm * size.width * 0.62 / perspective + stereoOffset * depth
                if col == 0 { context.move(to: CGPoint(x: x, y: y + wave)) } else { context.addLine(to: CGPoint(x: x, y: y + wave)) }
            }
            context.strokePath()
        }
    }

    private static func drawOscilloscopeEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let hueBase = Double((request.preset.id * 19) % 360) / 360.0
        for ribbon in 0..<7 {
            let yBase = size.height * (0.18 + Double(ribbon) * 0.105)
            context.setStrokeColor(neonColor(hueBase + Double(ribbon) / 7.0 + time * 0.04, alpha: 0.36))
            context.setLineWidth(2.0 + Double(ribbon) * 0.35)
            context.beginPath()
            for pointIndex in 0..<180 {
                let u = Double(pointIndex) / 179.0
                let amp = 28.0 + Double(ribbon) * 10.0
                let y = yBase + sin(u * .pi * (4.0 + Double(ribbon)) + time * (2.0 + Double(ribbon) * 0.3)) * amp
                let x = u * size.width + stereoOffset * sin(u * .pi)
                if pointIndex == 0 { context.move(to: CGPoint(x: x, y: y)) } else { context.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.strokePath()
        }
    }

    private static func drawConstellationEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let hueBase = Double((request.preset.id * 67) % 360) / 360.0
        var points: [CGPoint] = []
        for index in 0..<32 {
            let t = Double(index) / 32.0
            let radius = min(size.width, size.height) * (0.16 + 0.34 * pow(sin(t * .pi * 3.0 + time * 0.4), 2))
            points.append(CGPoint(x: center.x + cos(t * .pi * 2.0 + time * 0.3) * radius, y: center.y + sin(t * .pi * 2.0 - time * 0.22) * radius))
        }
        for i in points.indices {
            for j in (i + 1)..<points.count where abs(j - i) == 5 || (i + j) % 11 == 0 {
                context.setStrokeColor(neonColor(hueBase + Double(i + j) / 64.0, alpha: 0.16))
                context.setLineWidth(1)
                context.move(to: points[i])
                context.addLine(to: points[j])
                context.strokePath()
            }
        }
    }

    private static func drawFractalTreesEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let hueBase = Double((request.preset.id * 31 + request.sceneSeed) % 360) / 360.0
        for trunk in 0..<5 {
            let x = size.width * (Double(trunk) + 0.5) / 5.0 + stereoOffset * 0.4
            let base = CGPoint(x: x, y: size.height * 0.92)
            let length = size.height * (0.12 + 0.035 * Double((request.sceneSeed + trunk) % 5))
            let sway = sin(time * 0.8 + Double(trunk) + Double(request.sceneSeed % 11)) * 0.18
            drawTreeBranch(
                context: context,
                start: base,
                angle: -.pi / 2 + sway,
                length: length,
                depth: 7,
                hue: hueBase + Double(trunk) / 5.0,
                time: time,
                intensity: request.lightSynthIntensity,
                seed: request.sceneSeed
            )
        }
    }

    private static func drawTreeBranch(context: CGContext, start: CGPoint, angle: Double, length: Double, depth: Int, hue: Double, time: Double, intensity: Double, seed: Int) {
        guard depth > 0, length > 2 else { return }
        let end = CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
        context.setStrokeColor(neonColor(hue + Double(depth) * 0.07 + time * 0.025, alpha: 0.06 + Double(depth) * 0.045 * intensity))
        context.setLineWidth(max(0.6, Double(depth) * 0.75))
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let fork = 0.34 + Double((seed + depth) % 8) * 0.025
        let pulse = sin(time * 1.1 + Double(depth)) * 0.12
        drawTreeBranch(context: context, start: end, angle: angle - fork + pulse, length: length * 0.72, depth: depth - 1, hue: hue + 0.04, time: time, intensity: intensity, seed: seed)
        drawTreeBranch(context: context, start: end, angle: angle + fork - pulse, length: length * 0.70, depth: depth - 1, hue: hue + 0.09, time: time, intensity: intensity, seed: seed)
        if depth % 2 == 0 {
            drawTreeBranch(context: context, start: end, angle: angle + pulse * 0.5, length: length * 0.54, depth: depth - 2, hue: hue + 0.16, time: time, intensity: intensity, seed: seed)
        }
    }

    private static func drawParticleEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let hueBase = Double((request.preset.id * 13) % 360) / 360.0
        for particle in 0..<260 {
            let seed = Double((particle * 9283) % 12011) / 12011.0
            let spiral = seed * .pi * 18.0 + time * (0.18 + seed * 0.5)
            let radius = pow(seed, 0.72) * min(size.width, size.height) * 0.55
            let point = CGPoint(x: center.x + cos(spiral) * radius * (0.55 + request.macroX), y: center.y + sin(spiral * 1.17) * radius * (0.45 + request.macroY))
            let diameter = 1.2 + (1.0 - seed) * 7.0 * request.lightSynthIntensity
            context.setFillColor(neonColor(hueBase + seed + time * 0.03, alpha: 0.12 + (1.0 - seed) * 0.42))
            context.fillEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter))
        }
    }

    private static func drawReactionDiffusionEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let cols = 54
        let rows = 34
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols)
                let ny = Double(y) / Double(rows)
                let reaction = abs(sin((sin(nx * 18.0 + time * 0.65) * cos(ny * 20.0 - time * 0.55) + request.macroX * 0.04 - request.macroY * 0.04) * 18.0 + time * 0.85))
                guard reaction > 0.48 else { continue }
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: time + reaction, alpha: (reaction - 0.35) * 0.24))
                context.fill(CGRect(x: Double(x) * cellW + stereoOffset * 0.12, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1))
            }
        }
    }

    private static func drawKaleidoscopeMazeEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let symmetry = max(6, request.preset.symmetry * 2)
        let rings = 14 + Int(request.macroY * 18)
        for ring in 1...rings {
            let radius = min(size.width, size.height) * Double(ring) / Double(rings) * 0.54
            for spoke in 0..<symmetry {
                let phase = Double(spoke) / Double(symmetry)
                let a0 = phase * .pi * 2.0 + time * 0.13 + Double(ring % 3) * 0.16
                let a1 = a0 + .pi / Double(symmetry) * (1.0 + sin(time + Double(ring)) * 0.7)
                context.setStrokeColor(neonColor(phase + Double(ring) * 0.07 + time * 0.03, alpha: 0.10 + request.lightSynthIntensity * 0.22))
                context.setLineWidth(1.0 + request.exposure * 1.8)
                context.move(to: CGPoint(x: center.x + cos(a0) * radius, y: center.y + sin(a0) * radius))
                context.addLine(to: CGPoint(x: center.x + cos(a1) * radius * (0.76 + beat * 0.18), y: center.y + sin(a1) * radius * (0.76 + beat * 0.18)))
                context.strokePath()
            }
        }
    }

    private static func drawMoireFieldEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.screen)
        let centers = [
            CGPoint(x: size.width * (0.36 + sin(time * 0.17) * 0.12) + stereoOffset, y: size.height * 0.50),
            CGPoint(x: size.width * (0.64 + cos(time * 0.13) * 0.12) + stereoOffset, y: size.height * (0.50 + sin(time * 0.11) * 0.18))
        ]
        for (centerIndex, center) in centers.enumerated() {
            for ring in 0..<42 {
                let radius = Double(ring) * min(size.width, size.height) / 70.0 + sin(time * 1.2 + Double(ring)) * 4.0
                context.setStrokeColor(neonColor(Double(ring) * 0.025 + Double(centerIndex) * 0.3 + time * 0.02, alpha: 0.045 + request.lightSynthIntensity * 0.055))
                context.setLineWidth(1)
                context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
        }
    }

    private static func drawSlitScanRibbonsEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.plusLighter)
        let strips = 44
        let stripW = size.width / Double(strips)
        for strip in 0..<strips {
            let t = Double(strip) / Double(strips)
            let delay = t * (0.9 + request.macroX * 2.4)
            context.setStrokeColor(neonColor(t + time * 0.04, alpha: 0.12 + request.exposure * 0.16))
            context.setLineWidth(max(1.0, stripW * 0.42))
            context.beginPath()
            for pointIndex in 0...80 {
                let y = Double(pointIndex) / 80.0 * size.height
                let wave = sin(y * 0.028 + time * 2.0 - delay * 3.0) * (18.0 + request.macroY * 70.0)
                let x = Double(strip) * stripW + stripW / 2 + wave + stereoOffset * t
                if pointIndex == 0 { context.move(to: CGPoint(x: x, y: y)) } else { context.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.strokePath()
        }
    }

    private static func drawCellularAutomataEngine(context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, stereoOffset: Double) {
        context.setBlendMode(.screen)
        let cols = 48
        let rows = 30
        let generation = Int(time * (4.0 + request.macroY * 18.0))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let seed = (x * 73) ^ (y * 151) ^ (generation * 313) ^ request.sceneSeed
                let neighbors = ((seed >> 1) ^ (seed >> 4) ^ (seed >> 7)) & 7
                let alive = neighbors == 3 || (neighbors == 2 && ((seed >> 3) & 1) == 1)
                guard alive else { continue }
                context.setFillColor(neonColor(Double(neighbors) / 8.0 + time * 0.02, alpha: 0.14 + request.lightSynthIntensity * 0.24))
                let rectX = CGFloat(Double(x) * cellW + 1.0 + stereoOffset * 0.06)
                let rectY = CGFloat(Double(y) * cellH + 1.0)
                context.fill(CGRect(x: rectX, y: rectY, width: CGFloat(cellW - 1.0), height: CGFloat(cellH - 1.0)))
            }
        }
    }

    private static func drawMinterLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        guard request.minterEffectMode != .off || request.preset.family == .minter else { return }
        switch request.minterEffectMode {
        case .psychedeliaGrid:
            drawMinterPsychedeliaGrid(context, size: size, request: request, time: time, beat: beat)
            return
        case .colourspaceFlow:
            drawMinterColourspaceFlow(context, size: size, request: request, time: time, beat: beat)
            return
        case .vlmNeon:
            drawHyperPrism(context, size: size, request: request, time: time, beat: beat, intensity: request.minterIntensity)
            drawLissajousLaser(context, size: size, request: request, time: time * 0.72, intensity: min(1.0, request.minterIntensity + 0.18))
            drawNeuralMandala(context, size: size, request: request, time: time, intensity: request.minterIntensity)
            return
        case .tempestWeb:
            drawMinterTempestWeb(context, size: size, request: request, time: time, beat: beat)
            return
        case .polybiusTunnel:
            drawMinterPolybiusTunnel(context, size: size, request: request, time: time, beat: beat)
            return
        case .gridrunnerLattice:
            drawMinterGridrunnerLattice(context, size: size, request: request, time: time)
            return
        case .spaceGiraffeWeb:
            drawMinterTempestWeb(context, size: size, request: request, time: time, beat: beat)
            drawMinterPolybiusTunnel(context, size: size, request: request, time: time * 1.13, beat: beat)
            return
        case .txkVectorBloom:
            drawMinterTempestWeb(context, size: size, request: request, time: time * 1.2, beat: beat)
            drawRecursiveBloom(context, size: size, request: request, time: time, intensity: request.minterIntensity)
            return
        case .neonLoopz:
            drawMinterColourspaceFlow(context, size: size, request: request, time: time * 0.82, beat: beat)
            drawLissajousLaser(context, size: size, request: request, time: time, intensity: request.minterIntensity)
            return
        case .llamaTronTrails:
            drawMinterPsychedeliaGrid(context, size: size, request: request, time: time, beat: beat)
            drawMinterGridrunnerLattice(context, size: size, request: request, time: time)
            return
        case .off, .neonStampede, .yakLaserGrid, .llamaFeedback, .arcadeVortex:
            break
        }
        let intensity = request.minterIntensity
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let hueBase = Double((request.preset.id * 53) % 360) / 360.0

        context.setBlendMode(.plusLighter)
        context.setLineCap(.round)

        let gridCount = 22
        for i in 0..<gridCount {
            let u = Double(i) / Double(gridCount - 1)
            let y = size.height * u
            let x = size.width * u
            let wobble = sin(time * 2.8 + u * 11.0) * 32.0 * intensity
            context.setStrokeColor(neonColor(hueBase + u * 0.72 + beat * 0.12, alpha: 0.22 + intensity * 0.25))
            context.setLineWidth(1.0 + intensity * 2.0)
            context.move(to: CGPoint(x: 0, y: y + wobble))
            context.addLine(to: CGPoint(x: size.width, y: y - wobble))
            context.strokePath()
            context.move(to: CGPoint(x: x + wobble, y: 0))
            context.addLine(to: CGPoint(x: x - wobble, y: size.height))
            context.strokePath()
        }

        let critters = 18
        for critter in 0..<critters {
            let phase = Double(critter) / Double(critters)
            let orbit = min(size.width, size.height) * (0.12 + 0.36 * phase)
            let angle = time * (0.9 + phase) + phase * .pi * 8.0
            let p = CGPoint(x: center.x + cos(angle) * orbit, y: center.y + sin(angle * 1.3) * orbit * 0.72)
            context.setFillColor(neonColor(hueBase + phase + time * 0.04, alpha: 0.35 + intensity * 0.45))
            let rect = CGRect(x: p.x - 5 - intensity * 8, y: p.y - 5 - intensity * 8, width: 10 + intensity * 16, height: 10 + intensity * 16)
            context.fillEllipse(in: rect)
        }
    }

    private static func drawMinterPsychedeliaGrid(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        context.setBlendMode(.plusLighter)
        let cols = 24
        let rows = 16
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let dx = Double(x) - Double(cols) * request.macroX
                let dy = Double(y) - Double(rows) * (1.0 - request.macroY)
                let wave = sin(hypot(dx, dy) * 0.9 - time * 4.0 + beat * .pi * 2.0)
                guard wave > 0.18 else { continue }
                let inset = (1.0 - wave) * min(cellW, cellH) * 0.36
                context.setFillColor(neonColor(wave + time * 0.06, alpha: 0.10 + request.minterIntensity * 0.32))
                context.fill(CGRect(x: Double(x) * cellW + inset, y: Double(y) * cellH + inset, width: cellW - inset * 2, height: cellH - inset * 2))
            }
        }
    }

    private static func drawMinterColourspaceFlow(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        context.setBlendMode(.plusLighter)
        for band in 0..<32 {
            let t = Double(band) / 32.0
            context.setStrokeColor(neonColor(t + time * 0.035, alpha: 0.08 + request.minterIntensity * 0.17))
            context.setLineWidth(1.0 + request.minterIntensity * 3.0)
            context.beginPath()
            for pointIndex in 0...90 {
                let u = Double(pointIndex) / 90.0
                let x = u * size.width
                let y = size.height * (0.18 + t * 0.64) + sin(u * 10.0 + time * (1.0 + t) + beat * 3.0) * (16.0 + request.macroY * 70.0)
                if pointIndex == 0 { context.move(to: CGPoint(x: x, y: y)) } else { context.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.strokePath()
        }
    }

    private static func drawMinterTempestWeb(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let lanes = 18
        for lane in 0..<lanes {
            let angle = Double(lane) / Double(lanes) * .pi * 2.0 + time * 0.08
            context.setStrokeColor(neonColor(Double(lane) / Double(lanes) + time * 0.02, alpha: 0.10 + request.minterIntensity * 0.16))
            context.setLineWidth(1)
            context.move(to: center)
            context.addLine(to: CGPoint(x: center.x + cos(angle) * size.width, y: center.y + sin(angle) * size.height))
            context.strokePath()
            for ring in 1..<18 {
                let radius = min(size.width, size.height) * Double(ring) / 18.0 * (0.18 + beat * 0.09)
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                context.setFillColor(neonColor(Double(ring) / 18.0, alpha: 0.18 + request.minterIntensity * 0.26))
                context.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
            }
        }
    }

    private static func drawMinterPolybiusTunnel(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for gate in 0..<28 {
            let phase = (Double(gate) / 28.0 + time * (0.12 + request.macroY * 0.22)).truncatingRemainder(dividingBy: 1)
            let scale = pow(phase, 1.9)
            let w = size.width * scale * 1.35
            let h = size.height * scale * 1.05
            context.setStrokeColor(neonColor(phase + beat, alpha: (1.0 - phase) * (0.12 + request.minterIntensity * 0.28)))
            context.setLineWidth(1.0 + (1.0 - phase) * 7.0)
            context.stroke(CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h))
        }
    }

    private static func drawMinterGridrunnerLattice(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        let spacing = 34.0 - request.minterIntensity * 12.0
        for x in stride(from: -size.height, through: size.width + size.height, by: spacing) {
            context.setStrokeColor(neonColor(0.32 + x * 0.0008, alpha: 0.08 + request.minterIntensity * 0.15))
            context.setLineWidth(1)
            context.move(to: CGPoint(x: x + sin(time + x * 0.01) * 12.0, y: 0))
            context.addLine(to: CGPoint(x: x + size.height * 0.55, y: size.height))
            context.strokePath()
        }
        for y in stride(from: 0.0, through: size.height + size.width, by: spacing) {
            context.setStrokeColor(neonColor(0.78 + y * 0.0008, alpha: 0.08 + request.minterIntensity * 0.15))
            context.move(to: CGPoint(x: 0, y: y + sin(time * 1.4 + y * 0.01) * 12.0))
            context.addLine(to: CGPoint(x: size.width, y: y - size.width * 0.45))
            context.strokePath()
        }
    }

    private static func drawAdvancedLightSynthLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        let mode = request.lightSynthMode
        let intensity = request.flashSafety ? min(request.lightSynthIntensity, 0.82) : request.lightSynthIntensity

        if mode == .lissajousLaser || mode == .acidScope || mode == .everything {
            drawLissajousLaser(context, size: size, request: request, time: time, intensity: intensity)
        }
        if mode == .hyperPrism || mode == .everything {
            drawHyperPrism(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        }
        if mode == .recursiveBloom || mode == .everything {
            drawRecursiveBloom(context, size: size, request: request, time: time, intensity: intensity)
        }
        if mode == .photonStorm || mode == .everything {
            drawPhotonStorm(context, size: size, request: request, time: time, intensity: intensity)
        }
        if mode == .neuralMandala || mode == .everything {
            drawNeuralMandala(context, size: size, request: request, time: time, intensity: intensity)
        }
    }

    private static func drawPaletteAndGate(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let blendAlpha: Double
        switch request.blendMode {
        case .additive:
            blendAlpha = 0.04
        case .screen:
            blendAlpha = 0.075
        case .softKey:
            blendAlpha = 0.10
        case .hardKey:
            blendAlpha = 0.14
        case .difference:
            blendAlpha = 0.09
        }
        context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: time, alpha: blendAlpha * request.lightSynthIntensity))
        context.fill(CGRect(origin: .zero, size: size))

        guard request.strobeEnabled else { return }
        let cappedRate = request.flashSafety ? min(request.strobeRate, 10.0) : request.strobeRate
        let phase = (time * cappedRate).truncatingRemainder(dividingBy: 1)
        if phase < 0.08 {
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: (request.flashSafety ? 0.22 : 0.55) * request.lightSynthIntensity))
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private static func drawExperimentalVideoMode(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        let intensity = request.flashSafety ? min(request.experimentalVideoIntensity, 0.82) : request.experimentalVideoIntensity
        guard request.experimentalVideoMode != .clean, intensity > 0.01 else { return }
        context.setBlendMode(.screen)
        switch request.experimentalVideoMode {
        case .clean:
            return
        case .colourspace:
            for band in 0..<48 {
                let t = Double(band) / 48.0
                context.setFillColor(neonColor(t + time * 0.06 + beat * 0.08, alpha: 0.025 + intensity * 0.055))
                context.fill(CGRect(x: 0, y: size.height * t, width: size.width, height: size.height / 36.0))
            }
        case .neonPulse:
            let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
            for ring in 0..<18 {
                let phase = (Double(ring) / 18.0 + beat).truncatingRemainder(dividingBy: 1)
                let radius = min(size.width, size.height) * (0.04 + phase * 0.64)
                context.setStrokeColor(neonColor(phase + time * 0.08, alpha: (1.0 - phase) * intensity * 0.18))
                context.setLineWidth(1.0 + intensity * 5.0)
                context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
        case .slitScan:
            for strip in stride(from: 0.0, to: size.width, by: 18.0) {
                let offset = sin(strip * 0.025 + time * 2.6) * 22.0 * intensity
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: time + strip / max(1, size.width), alpha: 0.025 + intensity * 0.045))
                context.fill(CGRect(x: strip + offset, y: 0, width: 10, height: size.height))
            }
        case .videoFeedback:
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for echo in 1...10 {
                let phase = Double(echo) / 10.0
                let inset = min(size.width, size.height) * phase * 0.035 * intensity
                context.setStrokeColor(neonColor(phase + time * 0.04, alpha: (1.0 - phase) * intensity * 0.10))
                context.setLineWidth(2)
                context.stroke(CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2))
                context.strokeEllipse(in: CGRect(x: center.x - inset * 2, y: center.y - inset, width: inset * 4, height: inset * 2))
            }
        case .chromaticAberration:
            for line in stride(from: 0.0, to: size.height, by: 9.0) {
                let shift = sin(line * 0.05 + time * 4.0) * 28.0 * intensity
                context.setLineWidth(2)
                context.setStrokeColor(CGColor(red: 1, green: 0.1, blue: 0.6, alpha: 0.045 + intensity * 0.07))
                context.move(to: CGPoint(x: shift, y: line))
                context.addLine(to: CGPoint(x: size.width + shift, y: line))
                context.strokePath()
                context.setStrokeColor(CGColor(red: 0.1, green: 0.9, blue: 1, alpha: 0.045 + intensity * 0.07))
                context.move(to: CGPoint(x: -shift, y: line + 3))
                context.addLine(to: CGPoint(x: size.width - shift, y: line + 3))
                context.strokePath()
            }
        case .datamoshBlocks:
            let block = 32.0
            let cols = Int(size.width / block) + 1
            let rows = Int(size.height / block) + 1
            let frame = Int(time * 12.0)
            for y in 0..<rows {
                for x in 0..<cols where (((x * 19) ^ (y * 41) ^ frame) & 15) == 0 {
                    context.setFillColor(neonColor(Double(x + y) * 0.05 + time * 0.04, alpha: 0.05 + intensity * 0.13))
                    context.fill(CGRect(x: Double(x) * block + sin(time + Double(y)) * 18.0 * intensity, y: Double(y) * block, width: block * 1.6, height: block))
                }
            }
        case .vhsMelt:
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.012 + intensity * 0.025))
            context.setLineWidth(1)
            for row in stride(from: 0.0, to: size.height, by: 4.0) {
                let wave = sin(row * 0.035 + time * 3.7) + sin(row * 0.011 - time * 1.8)
                context.move(to: CGPoint(x: wave * 18.0 * intensity, y: row))
                context.addLine(to: CGPoint(x: size.width + wave * 18.0 * intensity, y: row))
                context.strokePath()
            }
        case .demosceneStack:
            drawMoireTunnel(context, size: size, request: request, time: time)
            drawRasterInterference(context, size: size, request: request, time: time)
            drawBitplaneStorm(context, size: size, request: request, time: time)
        case .lumaKeyBloom:
            drawLumaKeyBloom(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .chromaInvert:
            drawChromaInvert(context, size: size, request: request, time: time, intensity: intensity)
        case .edgeTrace:
            drawEdgeTrace(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .oscillatorBank:
            drawVideoOscillatorBank(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .vectorScope:
            drawVectorScope(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .scanGate:
            drawScanGate(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .pixelSortTrails:
            drawPixelSortTrails(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .codecTear:
            drawCodecTear(context, size: size, request: request, time: time, intensity: intensity)
        case .rgbDelay:
            drawRGBDelay(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .halftonePosterize:
            drawHalftonePosterize(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .opticalFlowSmear:
            drawOpticalFlowSmear(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .recursiveMirror:
            drawRecursiveMirror(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .liquidLens:
            drawLiquidLens(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .kaleidoFeedback:
            drawKaleidoFeedback(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .solarizedContours:
            drawSolarizedContours(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .phosphorBurn:
            drawPhosphorBurn(context, size: size, request: request, time: time, intensity: intensity)
        case .tunnelFold:
            drawTunnelFold(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        case .chromaLightLeaks:
            drawChromaLightLeaks(context, size: size, request: request, time: time, beat: beat, intensity: intensity)
        }
    }

    private static func drawLumaKeyBloom(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let threshold = request.videoKeyThreshold
        let cells = 18 + Int(request.videoEdgeGain * 18)
        let cellW = size.width / Double(cells)
        let cellH = size.height / Double(cells)
        let hueBase = Double((request.preset.id * 37) % 360) / 360.0
        for y in 0..<cells {
            for x in 0..<cells {
                let nx = Double(x) / Double(cells) - 0.5
                let ny = Double(y) / Double(cells) - 0.5
                let radial = 1.0 - min(1.0, hypot(nx, ny) * 1.65)
                let signal = 0.5
                    + 0.28 * sin(nx * 14.0 + time * (1.2 + request.videoOscillatorRate * 4.0))
                    + 0.22 * cos(ny * 12.0 - time * 1.7)
                    + 0.18 * sin((nx + ny) * 18.0 + beat * .pi * 2.0)
                    + radial * 0.32
                guard signal > threshold else { continue }
                let key = min(1.0, (signal - threshold) / max(0.08, 1.0 - threshold))
                let inset = (1.0 - key) * min(cellW, cellH) * 0.42
                context.setFillColor(neonColor(hueBase + signal + time * 0.04, alpha: key * intensity * 0.24))
                context.fill(CGRect(x: Double(x) * cellW + inset, y: Double(y) * cellH + inset, width: cellW - inset * 2, height: cellH - inset * 2))
            }
        }
    }

    private static func drawChromaInvert(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let bands = 14 + Int(request.videoColorWarp * 26)
        for band in 0..<bands {
            let t = Double(band) / Double(max(1, bands - 1))
            let y = size.height * t
            let height = size.height / Double(bands) * (1.2 + request.videoEdgeGain)
            let hue = 1.0 - (t + time * (0.025 + request.videoOscillatorRate * 0.07)).truncatingRemainder(dividingBy: 1)
            let offset = sin(time * 1.8 + t * 19.0) * size.width * 0.05 * request.videoColorWarp
            context.setFillColor(neonColor(hue, alpha: (0.035 + intensity * 0.10) * request.videoColorWarp))
            context.fill(CGRect(x: offset, y: y - height * 0.5, width: size.width, height: height))
        }
        for column in stride(from: 0.0, to: size.width, by: 23.0) {
            let x = column + sin(column * 0.04 + time * 2.1) * 18.0 * request.videoColorWarp
            context.setFillColor(neonColor(0.58 + time * 0.03, alpha: 0.025 + intensity * 0.065))
            context.fill(CGRect(x: x, y: 0, width: 2.0 + request.videoEdgeGain * 5.0, height: size.height))
        }
    }

    private static func drawEdgeTrace(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let contours = 16 + Int(request.videoEdgeGain * 32)
        let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
        let hueBase = Double((request.preset.id * 41) % 360) / 360.0
        for contour in 0..<contours {
            let t = Double(contour) / Double(contours)
            let radius = min(size.width, size.height) * (0.06 + t * 0.62)
            let path = CGMutablePath()
            for point in 0...110 {
                let u = Double(point) / 110.0 * .pi * 2.0
                let edge = sin(u * (3.0 + request.videoColorWarp * 9.0) + time * (1.0 + request.videoOscillatorRate * 3.0) + t * 11.0)
                let r = radius * (0.82 + edge * 0.12 + sin(beat * .pi * 2.0 + t * 6.0) * 0.045)
                let p = CGPoint(x: center.x + cos(u) * r, y: center.y + sin(u) * r * (0.62 + request.videoKeyThreshold * 0.45))
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.setStrokeColor(neonColor(hueBase + t + time * 0.03, alpha: (1.0 - t) * intensity * (0.10 + request.videoEdgeGain * 0.18)))
            context.setLineWidth(0.8 + request.videoEdgeGain * 4.5)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawVideoOscillatorBank(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let oscillators = 5 + Int(request.videoColorWarp * 7)
        let hueBase = Double((request.preset.id * 53) % 360) / 360.0
        for oscillator in 0..<oscillators {
            let t = Double(oscillator) / Double(oscillators)
            let frequency = 1.0 + Double(oscillator) * (1.4 + request.videoKeyThreshold * 4.0)
            let path = CGMutablePath()
            for point in 0...220 {
                let u = Double(point) / 220.0
                let x = u * size.width
                let carrier = sin(u * .pi * 2.0 * frequency + time * (0.7 + request.videoOscillatorRate * 5.0))
                let modulator = cos(u * .pi * (frequency * 0.37 + 1.0) - time * (1.1 + t))
                let y = size.height * (0.18 + t * 0.64) + (carrier + modulator * 0.45 + sin(beat * .pi * 2.0) * 0.25) * size.height * (0.035 + request.videoEdgeGain * 0.055)
                if point == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.setStrokeColor(neonColor(hueBase + t + time * 0.05, alpha: 0.10 + intensity * 0.24))
            context.setLineWidth(1.0 + request.videoEdgeGain * 3.2)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawVectorScope(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let radius = min(size.width, size.height) * (0.18 + request.videoColorWarp * 0.28)
        for trace in 0..<6 {
            let tracePhase = Double(trace) / 6.0
            let path = CGMutablePath()
            var didMove = false
            for point in 0...360 {
                let u = Double(point) / 360.0 * .pi * 2.0
                let luma = 0.62 + sin(u * (2.0 + tracePhase * 4.0) + time * 1.2 + beat * .pi * 2.0) * 0.28
                guard luma > request.videoKeyThreshold * 0.72 else {
                    didMove = false
                    continue
                }
                let chroma = 0.62 + cos(u * (3.0 + request.videoOscillatorRate * 4.0) - time * 1.6 + tracePhase) * 0.28
                let p = CGPoint(
                    x: center.x + cos(u + chroma * request.videoColorWarp) * radius * luma,
                    y: center.y + sin(u * (1.0 + request.videoEdgeGain * 0.28)) * radius * chroma
                )
                if didMove { path.addLine(to: p) } else { path.move(to: p); didMove = true }
            }
            context.setStrokeColor(neonColor(tracePhase + time * 0.035, alpha: 0.09 + intensity * 0.21))
            context.setLineWidth(1.0 + request.videoEdgeGain * 2.5)
            context.addPath(path)
            context.strokePath()
        }
        context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.05 + intensity * 0.08))
        context.setLineWidth(1)
        context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    private static func drawScanGate(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let spacing = 4.0 + (1.0 - request.videoEdgeGain) * 12.0
        let gateWidth = 0.12 + (1.0 - request.videoKeyThreshold) * 0.42
        let hueBase = Double((request.preset.id * 67) % 360) / 360.0
        context.setLineWidth(1.0 + request.videoEdgeGain * 2.8)
        for row in stride(from: 0.0, to: size.height, by: spacing) {
            let phase = (row / max(1, size.height) + time * (0.06 + request.videoOscillatorRate * 0.20) + beat * 0.05).truncatingRemainder(dividingBy: 1)
            guard phase < gateWidth else { continue }
            let offset = sin(row * 0.025 + time * 2.4) * 36.0 * request.videoColorWarp
            context.setStrokeColor(neonColor(hueBase + phase + time * 0.04, alpha: 0.045 + intensity * 0.11))
            context.move(to: CGPoint(x: offset, y: row))
            context.addLine(to: CGPoint(x: size.width + offset, y: row + sin(time + row * 0.03) * 6.0))
            context.strokePath()
        }
    }

    private static func drawPixelSortTrails(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let rows = 18 + Int(request.videoEdgeGain * 28)
        let laneHeight = size.height / Double(rows)
        let threshold = request.videoKeyThreshold
        for row in 0..<rows {
            let y = Double(row) * laneHeight
            let rowPhase = Double(row) / Double(rows)
            let signal = 0.5 + 0.35 * sin(rowPhase * 15.0 + time * (0.8 + request.videoOscillatorRate * 3.8)) + 0.20 * cos(beat * .pi * 2.0 + rowPhase * 9.0)
            guard signal > threshold * 0.82 else { continue }
            let segments = 5 + Int(request.videoColorWarp * 10)
            for segment in 0..<segments {
                let s = Double(segment) / Double(segments)
                let sortLength = size.width * (0.08 + pow(signal, 2.0) * (0.18 + request.videoColorWarp * 0.36))
                let drift = sin(time * (1.2 + s) + rowPhase * 18.0) * size.width * 0.08 * intensity
                let x = (s * size.width + drift + Double(row * 31).truncatingRemainder(dividingBy: max(1.0, size.width))).truncatingRemainder(dividingBy: max(1.0, size.width))
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: signal + s + time * 0.035, alpha: 0.035 + intensity * 0.13))
                context.fill(CGRect(x: x - sortLength * 0.5, y: y, width: sortLength, height: max(2.0, laneHeight * 0.72)))
            }
        }
    }

    private static func drawCodecTear(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let block = 26.0 + (1.0 - request.videoEdgeGain) * 30.0
        let rows = Int(size.height / block) + 1
        let frame = Int(time * (8.0 + request.videoOscillatorRate * 22.0))
        for row in 0..<rows {
            let y = Double(row) * block
            let hit = (((row * 73) ^ frame) & 7) < 3
            let offset = hit ? sin(time * 2.0 + Double(row) * 1.7) * size.width * (0.03 + request.videoColorWarp * 0.16) : 0
            let alpha = hit ? 0.055 + intensity * 0.16 : 0.012 + intensity * 0.025
            context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: Double(row) * 0.07 + time * 0.04, alpha: alpha))
            context.fill(CGRect(x: offset, y: y, width: size.width * (1.0 + request.videoColorWarp * 0.28), height: block * (0.55 + request.videoEdgeGain * 0.65)))
        }

        let macro = max(18.0, block * 0.72)
        let cols = Int(size.width / macro) + 1
        for row in stride(from: 0, to: rows, by: 2) {
            for col in 0..<cols where (((col * 29) &+ (row * 47) &+ frame) % 17) < 3 {
                let x = Double(col) * macro + sin(Double(row) + time) * macro * 0.6
                let y = Double(row) * block
                let w = macro * (1.0 + request.videoColorWarp * 3.0)
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: Double(col + row) * 0.05, alpha: 0.07 + intensity * 0.15))
                context.fill(CGRect(x: x, y: y, width: w, height: macro * 0.92))
            }
        }
    }

    private static func drawRGBDelay(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
        let channels: [(CGColor, Double, Double)] = [
            (CGColor(red: 1, green: 0.05, blue: 0.20, alpha: 1), 0.00, 1.0),
            (CGColor(red: 0.05, green: 1, blue: 0.25, alpha: 1), 0.33, -0.7),
            (CGColor(red: 0.05, green: 0.80, blue: 1, alpha: 1), 0.66, 0.55)
        ]
        for (baseColor, phase, direction) in channels {
            for ring in 0..<16 {
                let t = Double(ring) / 16.0
                let delay = phase + t * 0.05
                let radius = min(size.width, size.height) * (0.05 + t * 0.58 + 0.035 * sin(beat * .pi * 2.0 + delay * 5.0))
                let dx = sin(time * (0.7 + request.videoOscillatorRate * 2.4) + delay * 9.0) * 32.0 * request.videoColorWarp * direction
                let dy = cos(time * (0.6 + request.videoOscillatorRate * 2.0) + delay * 7.0) * 24.0 * request.videoColorWarp * direction
                context.setStrokeColor(baseColor.copy(alpha: (1.0 - t) * (0.035 + intensity * 0.13)) ?? baseColor)
                context.setLineWidth(1.0 + request.videoEdgeGain * 3.0)
                context.strokeEllipse(in: CGRect(x: center.x + dx - radius, y: center.y + dy - radius, width: radius * 2, height: radius * 2))
            }
        }
    }

    private static func drawHalftonePosterize(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let cols = 24 + Int(request.videoEdgeGain * 30)
        let rows = max(12, Int(Double(cols) * size.height / max(1.0, size.width)))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let luma = 0.5 + 0.28 * sin(nx * 18.0 + time * (0.9 + request.videoOscillatorRate * 2.8)) + 0.24 * cos(ny * 16.0 - time * 1.4) + 0.16 * sin((nx - ny) * 24.0 + beat * .pi * 2.0)
                let quantized = floor(max(0.0, min(1.0, luma)) * 4.0) / 4.0
                guard quantized > request.videoKeyThreshold * 0.52 else { continue }
                let radius = min(cellW, cellH) * (0.12 + quantized * 0.42 * intensity)
                let cx = Double(x) * cellW + cellW * 0.5
                let cy = Double(y) * cellH + cellH * 0.5
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: quantized + Double(x + y) * 0.012 + time * 0.025, alpha: 0.05 + intensity * 0.16))
                context.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
            }
        }
    }

    private static func drawOpticalFlowSmear(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
        let streaks = 54 + Int(request.videoEdgeGain * 76)
        for streak in 0..<streaks {
            let t = Double(streak) / Double(streaks)
            let angle = t * .pi * 2.0 * (2.0 + request.videoColorWarp * 3.0) + sin(time * 0.32 + t * 8.0)
            let distance = min(size.width, size.height) * (0.10 + t * 0.68)
            let vx = cos(angle)
            let vy = sin(angle)
            let origin = CGPoint(x: center.x + vx * distance * (0.35 + 0.65 * sin(t * 11.0 + time)), y: center.y + vy * distance)
            let flow = 22.0 + 120.0 * intensity * (0.25 + request.videoColorWarp) * (0.4 + 0.6 * abs(sin(beat * .pi * 2.0 + t * 6.0)))
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.04, alpha: 0.045 + intensity * 0.15))
            context.setLineWidth(0.8 + request.videoEdgeGain * 3.4)
            context.move(to: CGPoint(x: origin.x - vx * flow * 0.25, y: origin.y - vy * flow * 0.25))
            context.addLine(to: CGPoint(x: origin.x + vx * flow, y: origin.y + vy * flow))
            context.strokePath()
        }
    }

    private static func drawRecursiveMirror(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let copies = 8 + Int(request.videoEdgeGain * 12)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for copy in 0..<copies {
            let t = Double(copy) / Double(max(1, copies - 1))
            let inset = min(size.width, size.height) * t * (0.018 + intensity * 0.045)
            let wobble = sin(time * (0.8 + request.videoOscillatorRate * 2.0) + t * 9.0) * 12.0 * request.videoColorWarp
            let rect = CGRect(x: inset + wobble, y: inset - wobble, width: size.width - inset * 2, height: size.height - inset * 2)
            let path = CGPath(roundedRect: rect, cornerWidth: max(0, 12.0 * (1.0 - t)), cornerHeight: max(0, 12.0 * (1.0 - t)), transform: nil)
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.025, alpha: (1.0 - t) * (0.055 + intensity * 0.18)))
            context.setLineWidth(1.0 + request.videoEdgeGain * 3.0)
            context.addPath(path)
            context.strokePath()
            if copy % 2 == 0 {
                context.setStrokeColor(neonColor(0.62 + t, alpha: (1.0 - t) * intensity * 0.08))
                context.setLineWidth(1)
                context.strokeEllipse(in: CGRect(x: center.x - rect.width * 0.25, y: center.y - rect.height * 0.18, width: rect.width * 0.5, height: rect.height * 0.36))
            }
        }
    }

    private static func drawLiquidLens(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let cols = 18 + Int(request.videoEdgeGain * 30)
        let rows = max(10, Int(Double(cols) * size.height / max(1.0, size.width)))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let ripple = sin((nx * nx + ny * ny) * 42.0 - time * (2.0 + request.videoOscillatorRate * 5.0))
                    + sin(nx * 18.0 + time * 1.2)
                    + cos(ny * 16.0 - beat * .pi * 2.0)
                let radius = min(cellW, cellH) * (0.16 + abs(ripple) * 0.24 * intensity)
                let warpX = sin(ny * 11.0 + time) * cellW * request.videoColorWarp
                let warpY = cos(nx * 10.0 - time * 0.8) * cellH * request.videoColorWarp
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: ripple * 0.18 + time * 0.025, alpha: 0.035 + intensity * 0.12))
                context.fillEllipse(in: CGRect(x: Double(x) * cellW + cellW * 0.5 + warpX - radius, y: Double(y) * cellH + cellH * 0.5 + warpY - radius, width: radius * 2, height: radius * 2))
            }
        }
    }

    private static func drawKaleidoFeedback(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let copies = 10 + Int(request.videoEdgeGain * 18)
        let symmetry = 6 + Int(request.videoColorWarp * 10)
        for copy in 0..<copies {
            let phase = Double(copy) / Double(copies)
            let radius = min(size.width, size.height) * (0.06 + phase * 0.52)
            for spoke in 0..<symmetry {
                let angle = Double(spoke) / Double(symmetry) * .pi * 2.0 + time * (0.05 + request.videoOscillatorRate * 0.22) + phase * 2.0
                let fold = abs(sin(angle * 2.0 + beat * .pi * 2.0))
                let p1 = CGPoint(x: center.x + cos(angle) * radius * fold, y: center.y + sin(angle) * radius)
                let p2 = CGPoint(x: center.x + cos(angle + 0.28 + phase) * radius * (1.0 + intensity * 0.25), y: center.y + sin(angle + 0.28 + phase) * radius)
                context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: phase + Double(spoke) * 0.03 + time * 0.04, alpha: (1.0 - phase) * (0.035 + intensity * 0.11)))
                context.setLineWidth(0.8 + request.videoEdgeGain * 2.8)
                context.move(to: center)
                context.addLine(to: p1)
                context.addLine(to: p2)
                context.strokePath()
            }
        }
    }

    private static func drawSolarizedContours(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let contours = 22 + Int(request.videoEdgeGain * 42)
        let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
        for contour in 0..<contours {
            let t = Double(contour) / Double(contours)
            let path = CGMutablePath()
            let points = 140
            for point in 0...points {
                let u = Double(point) / Double(points) * .pi * 2.0
                let luma = 0.5 + 0.5 * sin(u * (2.0 + request.videoColorWarp * 8.0) + t * 11.0 + time * (0.7 + request.videoOscillatorRate * 3.0))
                let quantized = floor(luma * 5.0) / 5.0
                let radius = min(size.width, size.height) * (0.08 + t * 0.62) * (0.82 + quantized * 0.18)
                let p = CGPoint(x: center.x + cos(u) * radius, y: center.y + sin(u) * radius * (0.62 + beat * 0.10))
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.setStrokeColor(neonColor(1.0 - t + time * 0.03, alpha: (0.04 + intensity * 0.12) * (1.0 - t * 0.45)))
            context.setLineWidth(0.9 + request.videoEdgeGain * 3.0)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawPhosphorBurn(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let bands = 26 + Int(request.videoEdgeGain * 42)
        for band in 0..<bands {
            let t = Double(band) / Double(bands)
            let y = size.height * t
            let drift = sin(time * (0.6 + request.videoOscillatorRate * 2.0) + t * 18.0) * size.width * 0.04 * request.videoColorWarp
            let alpha = (0.025 + intensity * 0.10) * pow(1.0 - t * 0.35, 1.8)
            context.setFillColor(CGColor(red: 0.15, green: 1.0, blue: 0.24, alpha: alpha))
            context.fill(CGRect(x: drift, y: y, width: size.width, height: max(2.0, size.height / Double(bands) * 0.72)))
            context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.03, alpha: alpha * 0.65))
            context.fill(CGRect(x: -drift * 0.5, y: y + 2, width: size.width, height: 1.2))
        }
    }

    private static func drawTunnelFold(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rings = 18 + Int(request.videoEdgeGain * 28)
        let sides = 5 + Int(request.videoColorWarp * 8)
        for ring in 0..<rings {
            let t = Double(ring) / Double(rings)
            let radius = min(size.width, size.height) * (0.04 + t * 0.68)
            let path = CGMutablePath()
            for side in 0...sides {
                let u = Double(side) / Double(sides) * .pi * 2.0
                let fold = abs(sin(u * 2.0 + time * (0.6 + request.videoOscillatorRate * 2.2) + t * 5.0))
                let r = radius * (0.72 + fold * 0.34 + sin(beat * .pi * 2.0 + t * 7.0) * 0.05)
                let p = CGPoint(x: center.x + cos(u + t * 1.5) * r, y: center.y + sin(u + t * 1.5) * r)
                if side == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.035, alpha: (1.0 - t) * (0.045 + intensity * 0.15)))
            context.setLineWidth(1.0 + request.videoEdgeGain * 3.5)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawChromaLightLeaks(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let leaks = 9 + Int(request.videoColorWarp * 12)
        for leak in 0..<leaks {
            let t = Double(leak) / Double(max(1, leaks - 1))
            let x = size.width * (sin(time * 0.11 + t * 8.0) * 0.5 + 0.5)
            let y = size.height * (cos(time * 0.09 + t * 6.0 + beat) * 0.5 + 0.5)
            let radius = min(size.width, size.height) * (0.10 + 0.24 * abs(sin(time * 0.3 + t * 5.0)))
            context.setFillColor(neonColor(t + time * 0.04, alpha: 0.035 + intensity * 0.14))
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2.4, height: radius * 1.5))
            context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: t + 0.5, alpha: 0.025 + intensity * 0.08))
            context.fill(CGRect(x: x - radius * 1.8, y: y - 2, width: radius * 3.6, height: 4 + request.videoEdgeGain * 10))
        }
    }

    private static func drawFeedbackSimulatorLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        guard request.feedbackSimulatorMode != .off, request.feedbackSimulatorIntensity > 0.01 else { return }
        let intensity = request.flashSafety ? min(request.feedbackSimulatorIntensity, 0.84) : request.feedbackSimulatorIntensity
        let energy = request.feedbackSimulatorAudioReactive ? musicEnergy(at: time, sequencer: request.sequencer) : 0.42
        context.setBlendMode(.screen)

        switch request.feedbackSimulatorMode {
        case .off:
            return
        case .opticalTunnel:
            drawFeedbackOpticalTunnel(context, size: size, request: request, time: time, beat: beat, intensity: intensity, energy: energy)
        case .prismHall:
            drawFeedbackPrismHall(context, size: size, request: request, time: time, intensity: intensity, energy: energy)
        case .lumaBloomMemory:
            drawFeedbackLumaBloomMemory(context, size: size, request: request, time: time, beat: beat, intensity: intensity, energy: energy)
        case .chromaWarpField:
            drawFeedbackChromaWarpField(context, size: size, request: request, time: time, intensity: intensity, energy: energy)
        case .scanlineMemory:
            drawFeedbackScanlineMemory(context, size: size, request: request, time: time, intensity: intensity, energy: energy)
        case .mirrorLabyrinth:
            drawFeedbackMirrorLabyrinth(context, size: size, request: request, time: time, beat: beat, intensity: intensity, energy: energy)
        case .feedbackLab:
            drawFeedbackOpticalTunnel(context, size: size, request: request, time: time, beat: beat, intensity: intensity * 0.72, energy: energy)
            drawFeedbackPrismHall(context, size: size, request: request, time: time, intensity: intensity * 0.62, energy: energy)
            drawFeedbackLumaBloomMemory(context, size: size, request: request, time: time, beat: beat, intensity: intensity * 0.58, energy: energy)
            drawFeedbackChromaWarpField(context, size: size, request: request, time: time, intensity: intensity * 0.54, energy: energy)
            drawFeedbackScanlineMemory(context, size: size, request: request, time: time, intensity: intensity * 0.48, energy: energy)
            drawFeedbackMirrorLabyrinth(context, size: size, request: request, time: time, beat: beat, intensity: intensity * 0.50, energy: energy)
        }
    }

    private static func drawFeedbackOpticalTunnel(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width * (0.5 + (request.macroX - 0.5) * 0.28), y: size.height * (0.5 + (0.5 - request.macroY) * 0.22))
        let shortest = min(size.width, size.height)
        let echoes = 10 + Int(request.feedbackSimulatorDecay * 22)
        let zoom = 0.018 + request.feedbackSimulatorZoom * 0.060
        for echo in 0..<echoes {
            let t = Double(echo) / Double(max(1, echoes - 1))
            let falloff = pow(1.0 - t, 0.9 + (1.0 - request.feedbackSimulatorDecay) * 1.6)
            let inset = shortest * t * zoom * (1.0 + energy * 0.38)
            let wobble = sin(time * (0.55 + request.videoOscillatorRate * 1.4) + t * 12.0) * shortest * 0.018 * request.feedbackSimulatorDisplacement
            let rect = CGRect(x: inset + wobble, y: inset - wobble * 0.7, width: size.width - inset * 2, height: size.height - inset * 2)
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: CGFloat((t - 0.5) * request.feedbackSimulatorTwist * .pi * 0.38 + sin(beat * .pi * 2.0 + t * 5.0) * 0.018 * energy))
            context.translateBy(x: -center.x, y: -center.y)
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.025, alpha: falloff * intensity * 0.16))
            context.setLineWidth(0.8 + falloff * (2.2 + energy * 4.0))
            context.stroke(rect)
            if echo % 3 == 0 {
                let ring = inset * (1.4 + request.feedbackSimulatorZoom)
                context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + 0.45, alpha: falloff * intensity * 0.07))
                context.setLineWidth(0.7 + energy * 2.0)
                context.strokeEllipse(in: CGRect(x: center.x - ring, y: center.y - ring * 0.56, width: ring * 2, height: ring * 1.12))
            }
            context.restoreGState()
        }
    }

    private static func drawFeedbackPrismHall(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let echoes = 7 + Int(request.feedbackSimulatorPrism * 13)
        let channels: [(CGColor, Double, Double)] = [
            (CGColor(red: 1, green: 0, blue: 0.18, alpha: 1), 0.0, 1.0),
            (CGColor(red: 0.1, green: 1, blue: 0.2, alpha: 1), 0.33, -0.6),
            (CGColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 1), 0.66, 0.8)
        ]
        for echo in 0..<echoes {
            let t = Double(echo) / Double(max(1, echoes - 1))
            let radius = shortest * (0.08 + t * (0.55 + request.feedbackSimulatorZoom * 0.24))
            let sides = 3 + Int(request.feedbackSimulatorPrism * 7)
            for (color, hueOffset, direction) in channels {
                let split = shortest * request.feedbackSimulatorPrism * 0.020 * direction * (1.0 + t * 3.0)
                let rotation = time * (0.04 + request.feedbackSimulatorTwist * 0.20) * direction + t * .pi * 0.7
                let path = CGMutablePath()
                for side in 0...sides {
                    let u = Double(side) / Double(sides) * .pi * 2.0 + rotation
                    let refract = sin(u * 2.0 + time * 1.7 + energy * 3.0) * request.feedbackSimulatorDisplacement * shortest * 0.018
                    let p = CGPoint(x: center.x + cos(u) * (radius + refract) + split, y: center.y + sin(u) * (radius * 0.72 - refract * 0.4))
                    if side == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                let alpha = pow(1.0 - t, 1.2) * intensity * (0.08 + request.feedbackSimulatorPrism * 0.11)
                context.setStrokeColor(color.copy(alpha: alpha) ?? color)
                context.setLineWidth(0.7 + energy * 2.0)
                context.addPath(path)
                context.strokePath()
                if echo % 2 == 0 {
                    context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: hueOffset + t + time * 0.02, alpha: alpha * 0.55))
                    context.setLineWidth(1.6 + request.feedbackSimulatorPrism * 2.0)
                    context.addPath(path)
                    context.strokePath()
                }
            }
        }
    }

    private static func drawFeedbackLumaBloomMemory(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double, energy: Double) {
        let cells = 18 + Int(request.feedbackSimulatorDisplacement * 26)
        let cellW = size.width / Double(cells)
        let cellH = size.height / Double(cells)
        let threshold = request.videoKeyThreshold * 0.72
        for y in 0..<cells {
            for x in 0..<cells {
                let nx = Double(x) / Double(cells) - 0.5
                let ny = Double(y) / Double(cells) - 0.5
                let luma = 0.50
                    + sin(nx * 13.0 + time * (0.8 + request.videoOscillatorRate * 2.6)) * 0.22
                    + cos(ny * 11.0 - time * 1.2) * 0.20
                    + sin((nx * nx + ny * ny) * 38.0 - beat * .pi * 2.0) * 0.18
                    + energy * 0.18
                guard luma > threshold else { continue }
                let key = min(1.0, (luma - threshold) / max(0.08, 1.0 - threshold))
                let memory = pow(key, 0.7 + (1.0 - request.feedbackSimulatorDecay) * 1.8)
                let bloom = min(cellW, cellH) * (0.12 + memory * (0.42 + request.feedbackSimulatorZoom * 0.38))
                let cx = Double(x) * cellW + cellW * 0.5 + sin(time + ny * 8.0) * cellW * request.feedbackSimulatorDisplacement * 0.45
                let cy = Double(y) * cellH + cellH * 0.5 + cos(time * 0.8 + nx * 8.0) * cellH * request.feedbackSimulatorDisplacement * 0.45
                context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: luma + time * 0.026, alpha: memory * intensity * 0.14))
                context.fillEllipse(in: CGRect(x: cx - bloom, y: cy - bloom, width: bloom * 2, height: bloom * 2))
            }
        }
    }

    private static func drawFeedbackChromaWarpField(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double, energy: Double) {
        let rows = 14 + Int(request.feedbackSimulatorDisplacement * 20)
        let cols = 18 + Int(request.feedbackSimulatorDisplacement * 28)
        let amp = min(size.width, size.height) * (0.014 + request.feedbackSimulatorDisplacement * 0.055) * (0.7 + energy)
        for row in 0...rows {
            let ny = Double(row) / Double(max(1, rows))
            let path = CGMutablePath()
            for col in 0...cols {
                let nx = Double(col) / Double(max(1, cols))
                let field = feedbackNoise(nx * 3.2 + request.macroX, ny * 2.8 + request.macroY, time * (0.18 + request.videoOscillatorRate * 0.4))
                let twist = sin((nx - 0.5) * (ny - 0.5) * 26.0 + time * (0.7 + request.feedbackSimulatorTwist)) * amp * request.feedbackSimulatorTwist
                let x = nx * size.width + field * amp + twist
                let y = ny * size.height + sin(field * .pi + time + nx * 7.0) * amp * 0.55
                if col == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: ny + time * 0.018, alpha: 0.035 + intensity * 0.095))
            context.setLineWidth(0.7 + energy * 2.0)
            context.addPath(path)
            context.strokePath()
        }
        for col in 0...cols where col % 2 == 0 {
            let nx = Double(col) / Double(max(1, cols))
            let path = CGMutablePath()
            for row in 0...rows {
                let ny = Double(row) / Double(max(1, rows))
                let field = feedbackNoise(nx * 2.8 - request.macroY, ny * 3.3 + request.macroX, time * (0.16 + request.videoOscillatorRate * 0.36) + 2.1)
                let x = nx * size.width + cos(field * .pi * 2.0 + time) * amp * 0.65
                let y = ny * size.height + field * amp
                if row == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: nx + 0.5, alpha: 0.020 + intensity * 0.065))
            context.setLineWidth(0.6 + request.feedbackSimulatorPrism * 1.6)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawFeedbackScanlineMemory(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double, energy: Double) {
        let spacing = 3.0 + (1.0 - request.feedbackSimulatorDecay) * 9.0
        let driftScale = size.width * (0.012 + request.feedbackSimulatorDisplacement * 0.10)
        var rowIndex = 0
        for row in stride(from: 0.0, to: size.height, by: spacing) {
            let t = row / max(1.0, size.height)
            let decay = pow(1.0 - t * 0.32, 1.0 + (1.0 - request.feedbackSimulatorDecay) * 2.0)
            let drift = sin(row * 0.030 + time * (1.2 + request.videoOscillatorRate * 3.0)) * driftScale
                + sin(time * 0.7 + Double(rowIndex) * 0.43) * driftScale * 0.35 * energy
            context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + time * 0.018, alpha: decay * (0.020 + intensity * 0.065)))
            context.setLineWidth(0.7 + energy * 1.8)
            context.move(to: CGPoint(x: drift, y: row))
            context.addLine(to: CGPoint(x: size.width + drift, y: row + sin(time + t * 10.0) * request.feedbackSimulatorTwist * 8.0))
            context.strokePath()
            if rowIndex % 11 == 0 {
                context.setFillColor(CGColor(red: 0.16, green: 1.0, blue: 0.28, alpha: decay * intensity * 0.025))
                context.fill(CGRect(x: drift * 0.35, y: row, width: size.width, height: max(1.0, spacing * (1.0 + request.feedbackSimulatorZoom * 2.0))))
            }
            rowIndex += 1
        }
    }

    private static func drawFeedbackMirrorLabyrinth(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let symmetry = 5 + Int(request.feedbackSimulatorPrism * 11)
        let depth = 8 + Int(request.feedbackSimulatorDecay * 16)
        for ring in 0..<depth {
            let t = Double(ring) / Double(max(1, depth - 1))
            let radius = shortest * (0.06 + t * (0.54 + request.feedbackSimulatorZoom * 0.18))
            let alpha = pow(1.0 - t, 1.15) * intensity * (0.055 + energy * 0.060)
            for segment in 0..<symmetry {
                let a = Double(segment) / Double(symmetry) * .pi * 2.0 + time * (0.025 + request.feedbackSimulatorTwist * 0.16) + t * 0.9
                let b = a + .pi * 2.0 / Double(symmetry) * (0.44 + sin(beat * .pi * 2.0 + t * 5.0) * 0.08)
                let fold = 0.72 + abs(sin(a * 2.0 + time)) * 0.36
                let shard = CGMutablePath()
                shard.move(to: center)
                shard.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius * fold))
                shard.addLine(to: CGPoint(x: center.x + cos(b) * radius * (1.0 + request.feedbackSimulatorDisplacement * 0.18), y: center.y + sin(b) * radius * fold))
                shard.closeSubpath()
                context.setStrokeColor(paletteColor(request.paletteMode, preset: request.preset, time: t + Double(segment) * 0.05 + time * 0.02, alpha: alpha))
                context.setLineWidth(0.7 + request.feedbackSimulatorPrism * 2.2)
                context.addPath(shard)
                context.strokePath()
                if segment % 2 == 0 {
                    context.setFillColor(paletteColor(request.paletteMode, preset: request.preset, time: 1.0 - t + Double(segment) * 0.03, alpha: alpha * 0.24))
                    context.addPath(shard)
                    context.fillPath()
                }
            }
        }
    }

    private static func feedbackNoise(_ x: Double, _ y: Double, _ z: Double) -> Double {
        let a = sin(x * 5.13 + z * 1.70) * 0.50
        let b = cos(y * 6.71 - z * 1.31) * 0.32
        let c = sin((x + y) * 9.23 + sin(z * 0.7) * 2.0) * 0.18
        return a + b + c
    }

    private static func drawCameraFeedbackOverlay(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        guard request.cameraInputEnabled, let image = request.cameraImage else { return }

        let baseOpacity = request.cameraOverlayOpacity
        let feedback = request.cameraFeedbackAmount
        let scale = request.cameraOverlayScale
        let shortest = min(size.width, size.height)
        let echoCount: Int
        switch request.cameraFeedbackMode {
        case .optical, .lumaKey:
            echoCount = 5
        case .echoTunnel, .chromaWash:
            echoCount = 9
        case .slitEcho:
            echoCount = 16
        }

        context.saveGState()
        context.setBlendMode(.screen)
        for echo in 0...echoCount {
            let amount = Double(echo) / Double(max(1, echoCount))
            let modeBoost = request.cameraFeedbackMode == .echoTunnel ? 0.48 : 0.28
            let echoScale = scale + amount * feedback * modeBoost
            let width = size.width * echoScale
            let height = size.height * echoScale
            let driftX = sin(time * 0.7 + amount * 5.0) * shortest * feedback * 0.025 * amount
            let driftY = cos(time * 0.6 + amount * 4.0) * shortest * feedback * 0.020 * amount
            let rect = CGRect(
                x: (size.width - width) / 2 + driftX,
                y: (size.height - height) / 2 + driftY,
                width: width,
                height: height
            )
            context.saveGState()
            let lumaGate = request.cameraFeedbackMode == .lumaKey ? max(0.05, 1.0 - request.cameraLumaThreshold) : 1.0
            context.setAlpha(baseOpacity * lumaGate * pow(max(0.08, 1.0 - amount), 1.45) * (echo == 0 ? 1.0 : feedback))
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: CGFloat((amount + 0.12) * request.cameraFeedbackRotation * .pi))
            context.translateBy(x: -size.width / 2, y: -size.height / 2)
            if request.cameraMirror {
                context.translateBy(x: size.width, y: 0)
                context.scaleBy(x: -1, y: 1)
            }
            if request.cameraFeedbackMode == .slitEcho {
                let stripeHeight = max(4.0, size.height / Double(echoCount + 1) * 0.72)
                let y = size.height * amount + sin(time * 1.3 + amount * 8.0) * stripeHeight
                context.clip(to: CGRect(x: 0, y: y, width: size.width, height: stripeHeight))
            }
            context.draw(image, in: rect)
            if request.cameraFeedbackMode == .chromaWash {
                context.setFillColor(neonColor(amount + time * 0.04 + request.cameraChromaShift, alpha: 0.035 + feedback * 0.08))
                context.fill(CGRect(origin: .zero, size: size))
            }
            context.restoreGState()
        }
        context.restoreGState()
    }

    private static func drawVisualDelayTaps(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        let settings = request.delaySettings
        guard settings.enabled, settings.visualDelayEnabled else { return }

        context.setBlendMode(.plusLighter)
        let secondsPerBeat = 60.0 / max(40.0, request.bpm)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let hueBase = Double((request.preset.id * 37) % 360) / 360.0

        for tap in settings.taps where tap.enabled {
            let delayedTime = time - tap.beatOffset * secondsPerBeat
            let energy = musicEnergy(at: delayedTime, sequencer: request.sequencer)
            let opacity = settings.visualEchoOpacity * tap.level * (0.35 + energy * 0.85)
            let spread = 0.12 + tap.visualSpread * 0.62
            let ringCount = 3 + Int(tap.visualSpread * 5)

            for ring in 0..<ringCount {
                let phase = (delayedTime * 0.18 + Double(ring) / Double(ringCount)).truncatingRemainder(dividingBy: 1)
                let radius = shortest * (0.06 + phase * spread)
                let wobble = sin(delayedTime * 2.0 + Double(ring)) * shortest * 0.025 * tap.visualSpread
                let rect = CGRect(x: center.x - radius + wobble, y: center.y - radius * 0.64 - wobble, width: radius * 2.0, height: radius * 1.28)
                context.setStrokeColor(neonColor(hueBase + phase + tap.beatOffset, alpha: opacity * (1.0 - phase * 0.55)))
                context.setLineWidth(1.0 + energy * 4.0)
                context.strokeEllipse(in: rect)
            }

            let rays = 8 + Int(tap.visualSpread * 18)
            for ray in 0..<rays {
                let amount = Double(ray) / Double(rays)
                let angle = delayedTime * (0.4 + tap.visualSpread) + amount * .pi * 2.0
                let length = shortest * (0.18 + tap.visualSpread * 0.42 + energy * 0.18)
                context.setStrokeColor(neonColor(hueBase + amount + delayedTime * 0.03, alpha: opacity * 0.42))
                context.setLineWidth(0.8 + tap.level * 3.0)
                context.move(to: CGPoint(x: center.x + cos(angle) * shortest * 0.04, y: center.y + sin(angle) * shortest * 0.04))
                context.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                context.strokePath()
            }
        }
    }

    private static func musicEnergy(at time: TimeInterval, sequencer: SequencerState) -> Double {
        let secondsPerStep = 60.0 / max(40.0, sequencer.bpm) / 4.0
        let position = swungStepPosition(time: max(0, time), secondsPerStep: secondsPerStep, swing: sequencer.swing)
        let step = Int(floor(position)) % max(1, sequencer.patternLength)
        var energy = 0.05
        if sequencer.kick.steps[step] { energy += 0.45 }
        if sequencer.snare.steps[step] { energy += 0.25 }
        if sequencer.hat.steps[step] { energy += 0.12 }
        if sequencer.bass.steps[step] { energy += 0.22 }
        if sequencer.lead.steps[step] { energy += 0.18 }
        return min(1.0, energy)
    }

    private static func swungStepPosition(time: Double, secondsPerStep: Double, swing: Double) -> Double {
        let raw = time / secondsPerStep
        let pair = floor(raw / 2.0)
        let phase = raw - pair * 2.0
        let shift = min(0.65, max(0, swing)) * 0.5
        if phase < 1.0 + shift {
            return pair * 2.0 + phase / (1.0 + shift)
        }
        return pair * 2.0 + 1.0 + (phase - 1.0 - shift) / max(0.2, 1.0 - shift)
    }

    private static func paletteColor(_ mode: LightPaletteMode, preset: VisualPreset, time: Double, alpha: Double) -> CGColor {
        switch mode {
        case .neon:
            return neonColor(Double((preset.id * 37) % 360) / 360.0 + time * 0.04, alpha: alpha)
        case .colourspace:
            return neonColor(time * 0.045 + 0.18, alpha: alpha)
        case .yakNeon:
            return neonColor(0.80 + sin(time * 0.21) * 0.18, alpha: alpha)
        case .phosphor:
            return CGColor(red: 0.30 + 0.20 * sin(time * 0.33), green: 1.0, blue: 0.34, alpha: alpha)
        case .laserium:
            return neonColor(0.58 + sin(time * 0.17) * 0.16, alpha: alpha)
        case .acid:
            return neonColor(0.23 + sin(time * 0.3) * 0.08, alpha: alpha)
        case .ultraviolet:
            return CGColor(red: 0.45, green: 0.12, blue: 1.0, alpha: alpha)
        case .infrared:
            return CGColor(red: 1.0, green: 0.08, blue: 0.03, alpha: alpha)
        case .ice:
            return CGColor(red: 0.55, green: 0.95, blue: 1.0, alpha: alpha)
        case .monochrome:
            return CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha)
        case .rainbow:
            return neonColor(time * 0.07, alpha: alpha)
        case .amber:
            return CGColor(red: 1.0, green: 0.62, blue: 0.12, alpha: alpha)
        }
    }

    private static func drawLissajousLaser(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        context.setLineCap(.round)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * (0.18 + request.macroY * 0.34)
        let splits = max(1, request.prismSplits)
        let hueBase = Double((request.preset.id * 31) % 360) / 360.0

        for split in 0..<splits {
            let offset = Double(split) - Double(splits - 1) / 2.0
            let path = CGMutablePath()
            let ax = 2.0 + floor(request.macroX * 7.0)
            let ay = 3.0 + floor(request.macroY * 8.0)
            let phase = time * (0.7 + request.macroX * 1.6) + offset * 0.09
            for pointIndex in 0..<420 {
                let u = Double(pointIndex) / 419.0 * .pi * 2.0
                let x = sin(ax * u + phase) + 0.32 * sin((ax + ay) * u * 0.5 - time)
                let y = sin(ay * u + phase * 1.37) + 0.28 * cos((ay + 1.0) * u + time * 0.6)
                let p = CGPoint(x: center.x + x * radius + offset * 3.5, y: center.y + y * radius * 0.72 - offset * 2.5)
                if pointIndex == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.setStrokeColor(neonColor(hueBase + Double(split) / Double(splits) + time * 0.03, alpha: 0.12 + intensity * 0.42))
            context.setLineWidth(0.7 + intensity * 2.8)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawHyperPrism(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rays = 18 + Int(request.macroX * 40)
        let length = hypot(size.width, size.height) * (0.32 + request.macroY * 0.44)
        let hueBase = Double((request.preset.id * 43) % 360) / 360.0
        for ray in 0..<rays {
            let t = Double(ray) / Double(rays)
            let angle = t * .pi * 2.0 + time * (0.12 + request.macroX * 0.35) + sin(beat * .pi * 2.0 + t * 9.0) * 0.08
            let inner = min(size.width, size.height) * (0.035 + 0.08 * sin(time + t * 6.0))
            context.setStrokeColor(neonColor(hueBase + t + time * 0.05, alpha: 0.05 + intensity * 0.21))
            context.setLineWidth(1.0 + intensity * 3.0)
            context.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
            context.strokePath()
        }
    }

    private static func drawRecursiveBloom(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.screen)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let hueBase = Double((request.preset.id * 23) % 360) / 360.0
        for shell in 0..<18 {
            let t = Double(shell) / 18.0
            let scale = pow(t, 1.22)
            let radius = min(size.width, size.height) * (0.04 + scale * (0.58 + request.macroY * 0.2))
            let sides = 5 + Int(request.macroX * 8)
            let rotation = time * (0.22 + request.macroY * 0.24) + t * .pi
            let path = CGMutablePath()
            for side in 0...sides {
                let angle = rotation + Double(side) / Double(sides) * .pi * 2.0
                let wobble = 1.0 + sin(time * 1.5 + Double(side) + t * 8.0) * 0.12
                let point = CGPoint(x: center.x + cos(angle) * radius * wobble, y: center.y + sin(angle) * radius * wobble)
                if side == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.setStrokeColor(neonColor(hueBase + t - time * 0.035, alpha: (1.0 - t) * (0.08 + intensity * 0.22) * request.phosphorPersistence))
            context.setLineWidth(1.0 + (1.0 - t) * 6.0)
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawPhotonStorm(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width * request.macroX, y: size.height * (1.0 - request.macroY))
        let hueBase = Double((request.preset.id * 17) % 360) / 360.0
        let count = 120 + Int(intensity * 220)
        for particle in 0..<count {
            let seed = Double((particle * 6187) % 7919) / 7919.0
            let phase = (seed + time * (0.03 + request.macroX * 0.10)).truncatingRemainder(dividingBy: 1)
            let angle = seed * .pi * 16.0 + time * (0.4 + request.macroY)
            let distance = pow(phase, 1.8) * hypot(size.width, size.height) * 0.62
            let p1 = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            let p0 = CGPoint(x: center.x + cos(angle) * max(0, distance - 18 - phase * 90), y: center.y + sin(angle) * max(0, distance - 18 - phase * 90))
            context.setStrokeColor(neonColor(hueBase + seed + time * 0.04, alpha: phase * intensity * 0.36))
            context.setLineWidth(0.8 + phase * 2.6)
            context.move(to: p0)
            context.addLine(to: p1)
            context.strokePath()
        }
    }

    private static func drawNeuralMandala(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, intensity: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let hueBase = Double((request.preset.id * 71) % 360) / 360.0
        let nodes = 28
        let base = min(size.width, size.height) * (0.18 + request.macroY * 0.24)
        var points: [CGPoint] = []
        for index in 0..<nodes {
            let t = Double(index) / Double(nodes)
            let angle = t * .pi * 2.0
            let r = base * (0.72 + 0.28 * sin(time * 1.4 + t * 18.0))
            points.append(CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r))
        }
        for i in points.indices {
            for j in (i + 1)..<points.count where (j - i) % 5 == 0 || (j + i) % 9 == 0 {
                let t = Double((i + j) % points.count) / Double(points.count)
                context.setStrokeColor(neonColor(hueBase + t + time * 0.02, alpha: 0.025 + intensity * 0.070))
                context.setLineWidth(0.8)
                context.move(to: points[i])
                context.addLine(to: points[j])
                context.strokePath()
            }
        }
        for (index, point) in points.enumerated() {
            let diameter = 5.0 + intensity * 9.0 * (0.6 + 0.4 * sin(time * 3.0 + Double(index)))
            context.setFillColor(neonColor(hueBase + Double(index) / Double(nodes), alpha: 0.22 + intensity * 0.30))
            context.fillEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter))
        }
    }

    private static func drawDemosceneLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        let mode = request.demosceneEffectMode
        guard mode != .off || request.preset.family == .demoscene else { return }

        if mode == .copperBars || mode == .megaDemo || request.preset.family == .demoscene {
            drawCopperBars(context, size: size, request: request, time: time)
        }
        if mode == .plasma || mode == .megaDemo {
            drawPlasma(context, size: size, request: request, time: time)
        }
        if mode == .rotoZoom || mode == .megaDemo {
            drawRotoZoom(context, size: size, request: request, time: time)
        }
        if mode == .vectorBalls || mode == .megaDemo {
            drawVectorBalls(context, size: size, request: request, time: time)
        }
        if mode == .starTunnel || mode == .megaDemo {
            drawStarTunnel(context, size: size, request: request, time: time)
        }
        if mode == .chunkyVGA || mode == .megaDemo {
            drawChunkyVGA(context, size: size, request: request, time: time)
        }
        if mode == .moireTunnel || mode == .megaDemo {
            drawMoireTunnel(context, size: size, request: request, time: time)
        }
        if mode == .bitplaneStorm || mode == .megaDemo {
            drawBitplaneStorm(context, size: size, request: request, time: time)
        }
        if mode == .rasterInterference || mode == .megaDemo {
            drawRasterInterference(context, size: size, request: request, time: time)
        }
        if mode == .shadeBobs || mode == .megaDemo {
            drawShadeBobs(context, size: size, request: request, time: time)
        }
        if mode == .twister || mode == .megaDemo {
            drawTwister(context, size: size, request: request, time: time)
        }
        if mode == .mandelZoom || mode == .megaDemo {
            drawMandelZoom(context, size: size, request: request, time: time)
        }
        if mode == .voxelLandscape || mode == .megaDemo {
            drawVoxelLandscape(context, size: size, request: request, time: time)
        }
    }

    private static func drawCopperBars(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let bars = 20
        let height = size.height / 24.0
        let hueBase = Double((request.preset.id * 37) % 360) / 360.0
        for bar in 0..<bars {
            let phase = Double(bar) / Double(bars)
            let y = (sin(time * 1.35 + phase * .pi * 2.0) * 0.42 + 0.5) * size.height
            let width = size.width * (0.58 + 0.34 * sin(time * 0.85 + phase * 7.0))
            let x = (size.width - width) / 2.0
            let rect = CGRect(x: x, y: y - height / 2, width: width, height: height)
            let colors = [
                neonColor(hueBase + phase, alpha: 0.04),
                neonColor(hueBase + phase + 0.10, alpha: 0.28 * request.demosceneIntensity),
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.24 * request.demosceneIntensity),
                neonColor(hueBase + phase + 0.32, alpha: 0.22 * request.demosceneIntensity),
                neonColor(hueBase + phase, alpha: 0.04)
            ] as CFArray
            let locations: [CGFloat] = [0, 0.24, 0.48, 0.72, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                context.saveGState()
                context.addPath(CGPath(roundedRect: rect, cornerWidth: height * 0.45, cornerHeight: height * 0.45, transform: nil))
                context.clip()
                context.drawLinearGradient(gradient, start: CGPoint(x: x, y: rect.minY), end: CGPoint(x: x, y: rect.maxY), options: [])
                context.restoreGState()
            }
        }
    }

    private static func drawPlasma(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let columns = 48
        let rows = 30
        let cellW = size.width / Double(columns)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<columns {
                let nx = Double(x) / Double(columns) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let radial = sqrt(nx * nx + ny * ny)
                let value = sin(nx * 16.0 + time * 1.7)
                    + sin(ny * 13.0 + time * 2.1)
                    + sin((nx + ny) * 11.0 + time * 1.1)
                    + sin(radial * 32.0 - time * 3.0)
                context.setFillColor(neonColor(value * 0.08 + time * 0.035, alpha: 0.04 + request.demosceneIntensity * 0.08))
                context.fill(CGRect(x: Double(x) * cellW, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1))
            }
        }
    }

    private static func drawRotoZoom(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        context.setLineWidth(2.0)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let hueBase = Double((request.preset.id * 61) % 360) / 360.0
        for index in 0..<14 {
            let t = Double(index) / 14.0
            let side = min(size.width, size.height) * (0.14 + t * 0.78)
            let rotation = time * (0.45 + request.preset.warp * 0.45) + t * .pi
            let path = CGMutablePath()
            for corner in 0..<4 {
                let angle = rotation + Double(corner) * .pi / 2.0 + .pi / 4.0
                let point = CGPoint(x: center.x + cos(angle) * side, y: center.y + sin(angle) * side)
                if corner == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.setStrokeColor(neonColor(hueBase + t + time * 0.05, alpha: (1.0 - t) * 0.24 * request.demosceneIntensity))
            context.addPath(path)
            context.strokePath()
        }
    }

    private static func drawVectorBalls(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.23
        let hueBase = Double((request.preset.id * 29) % 360) / 360.0
        for lat in 0..<9 {
            let theta = (Double(lat) / 8.0 - 0.5) * .pi
            for lon in 0..<18 {
                let phi = Double(lon) / 18.0 * .pi * 2.0
                var x = cos(theta) * cos(phi)
                let y = sin(theta)
                var z = cos(theta) * sin(phi)
                let rot = time * 0.9
                let rx = x * cos(rot) - z * sin(rot)
                let rz = x * sin(rot) + z * cos(rot)
                x = rx
                z = rz
                let perspective = 1.5 / (2.1 - z)
                let point = CGPoint(x: center.x + x * radius * perspective, y: center.y + y * radius * perspective)
                let diameter = (3.0 + 9.0 * perspective) * request.demosceneIntensity
                context.setFillColor(neonColor(hueBase + Double(lon) / 18.0 + time * 0.04, alpha: 0.20 + 0.38 * perspective))
                context.fillEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter))
            }
        }
    }

    private static func drawStarTunnel(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for star in 0..<120 {
            let seed = Double((star * 73) % 997) / 997.0
            let angle = seed * .pi * 2.0 + sin(seed * 17.0) * 0.4
            let travel = (time * (0.18 + request.demosceneIntensity * 0.42) + seed).truncatingRemainder(dividingBy: 1)
            let r1 = pow(travel, 1.8) * min(size.width, size.height) * 0.75
            let r0 = max(0, r1 - 24.0 - travel * 90.0)
            context.setStrokeColor(neonColor(seed + time * 0.02, alpha: travel * 0.50))
            context.setLineWidth(1 + travel * 3)
            context.move(to: CGPoint(x: center.x + cos(angle) * r0, y: center.y + sin(angle) * r0))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * r1, y: center.y + sin(angle) * r1))
            context.strokePath()
        }
    }

    private static func drawChunkyVGA(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let block = 28.0
        let columns = Int(size.width / block) + 1
        let rows = Int(size.height / block) + 1
        for y in 0..<rows {
            for x in 0..<columns where (x + y) % 3 == 0 {
                let value = sin(Double(x) * 0.7 + time * 2.0) + cos(Double(y) * 0.8 - time * 2.4)
                let alpha = max(0, value) * 0.05 * request.demosceneIntensity
                context.setFillColor(neonColor(value * 0.2 + time * 0.02, alpha: alpha))
                context.fill(CGRect(x: Double(x) * block, y: Double(y) * block, width: block, height: block))
            }
        }
    }

    private static func drawMoireTunnel(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for ring in 0..<36 {
            let phase = (Double(ring) / 36.0 + time * 0.08).truncatingRemainder(dividingBy: 1)
            let radius = pow(phase, 1.45) * min(size.width, size.height) * 0.72
            let wobble = sin(time * 2.4 + Double(ring) * 0.8) * 18.0
            context.setStrokeColor(neonColor(phase + time * 0.04, alpha: (1.0 - phase) * 0.18 * request.demosceneIntensity))
            context.setLineWidth(1.0 + request.demosceneIntensity * 3.0)
            context.strokeEllipse(in: CGRect(x: center.x - radius - wobble, y: center.y - radius * 0.62 + wobble, width: radius * 2, height: radius * 1.24))
        }
    }

    private static func drawBitplaneStorm(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let block = 18.0
        let columns = Int(size.width / block) + 1
        let rows = Int(size.height / block) + 1
        let plane = Int(time * 9.0) & 7
        for y in 0..<rows {
            for x in 0..<columns {
                let mask = ((x * 13) ^ (y * 29) ^ (plane * 47)) & 15
                guard mask == 0 || mask == 7 else { continue }
                context.setFillColor(neonColor(Double(mask) * 0.08 + time * 0.05, alpha: 0.045 + request.demosceneIntensity * 0.10))
                context.fill(CGRect(x: Double(x) * block, y: Double(y) * block, width: block, height: block))
            }
        }
    }

    private static func drawRasterInterference(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        for row in stride(from: 0.0, to: size.height, by: 5.0) {
            let phase = row / max(1, size.height)
            let offset = sin(row * 0.06 + time * 4.0) * 42.0 * request.demosceneIntensity
            context.setStrokeColor(neonColor(phase + time * 0.03, alpha: 0.035 + request.demosceneIntensity * 0.075))
            context.setLineWidth(1)
            context.move(to: CGPoint(x: offset, y: row))
            context.addLine(to: CGPoint(x: size.width + offset, y: row + sin(time + phase * 12.0) * 8.0))
            context.strokePath()
        }
    }

    private static func drawShadeBobs(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        for bob in 0..<18 {
            let t = Double(bob) / 18.0
            let x = size.width * (0.5 + sin(time * (0.31 + t) + t * 9.0) * 0.42)
            let y = size.height * (0.5 + cos(time * (0.37 + t * 0.7) + t * 7.0) * 0.36)
            let radius = 18.0 + request.demosceneIntensity * 46.0
            context.setFillColor(neonColor(t + time * 0.04, alpha: 0.035 + request.demosceneIntensity * 0.070))
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }

    private static func drawTwister(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        let centerX = size.width / 2
        for slice in 0..<76 {
            let t = Double(slice) / 75.0
            let y = size.height * t
            let phase = time * 2.4 + t * .pi * 5.0
            context.setStrokeColor(neonColor(t + time * 0.03, alpha: 0.10 + request.demosceneIntensity * 0.22))
            context.setLineWidth(2.0 + request.demosceneIntensity * 4.0)
            context.move(to: CGPoint(x: centerX + sin(phase) * size.width * 0.22, y: y))
            context.addLine(to: CGPoint(x: centerX + cos(phase) * size.width * 0.22, y: y + size.height / 76.0))
            context.strokePath()
        }
    }

    private static func drawMandelZoom(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.screen)
        let cols = 44
        let rows = 28
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let zoom = 0.65 + 0.35 * sin(time * 0.27)
        for y in 0..<rows {
            for x in 0..<cols {
                let cx = (Double(x) / Double(cols) - 0.62) * zoom - 0.45
                let cy = (Double(y) / Double(rows) - 0.5) * zoom
                var zx = 0.0
                var zy = 0.0
                var iter = 0
                while zx * zx + zy * zy < 4.0 && iter < 12 {
                    let next = zx * zx - zy * zy + cx
                    zy = 2.0 * zx * zy + cy
                    zx = next
                    iter += 1
                }
                guard iter < 12 else { continue }
                context.setFillColor(neonColor(Double(iter) / 12.0 + time * 0.03, alpha: Double(iter) / 12.0 * (0.05 + request.demosceneIntensity * 0.13)))
                context.fill(CGRect(x: Double(x) * cellW, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1))
            }
        }
    }

    private static func drawVoxelLandscape(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double) {
        context.setBlendMode(.plusLighter)
        let horizon = size.height * 0.44
        for row in 0..<42 {
            let depth = Double(row) / 42.0
            context.setStrokeColor(neonColor(depth + time * 0.03, alpha: 0.055 + depth * request.demosceneIntensity * 0.20))
            context.setLineWidth(1.0 + depth * 2.0)
            context.beginPath()
            for col in 0...72 {
                let xNorm = Double(col) / 72.0 * 2.0 - 1.0
                let terrain = sin(xNorm * 8.0 + time * 1.2 + depth * 4.0) + cos(xNorm * 3.0 - time * 0.8)
                let x = size.width / 2 + xNorm * size.width * (0.35 + depth * 0.48)
                let y = horizon + depth * depth * size.height * 0.72 - terrain * (18.0 + depth * 62.0)
                if col == 0 { context.move(to: CGPoint(x: x, y: y)) } else { context.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.strokePath()
        }
    }

    private static func drawHolographicLayer(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double) {
        guard request.holographicMode != .off || request.preset.family == .holographic else { return }
        let mode: HolographicMode = request.holographicMode == .off ? .ghostPrism : request.holographicMode
        let depth = request.hologramDepth
        context.setBlendMode(.screen)

        let scanLines = mode == .realisticStack ? 72 : 56
        for line in 0..<scanLines {
            let y = size.height * Double(line) / Double(scanLines)
            let alpha = 0.018 + depth * 0.05 + sin(time * 6.0 + Double(line)) * 0.010
            context.setStrokeColor(CGColor(red: 0.35, green: 1.0, blue: 0.92, alpha: max(0.0, alpha)))
            context.setLineWidth(0.8)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y + sin(time + Double(line)) * depth * (mode == .realisticStack ? 12.0 : 8.0)))
            context.strokePath()
        }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for shell in 0..<9 {
            let phase = (Double(shell) / 9.0 + beat).truncatingRemainder(dividingBy: 1)
            let inset = min(size.width, size.height) * (0.05 + phase * 0.42)
            let rect = CGRect(x: center.x - inset, y: center.y - inset * 0.58, width: inset * 2.0, height: inset * 1.16)
            context.setStrokeColor(CGColor(red: 0.55, green: 0.95, blue: 1.0, alpha: (1.0 - phase) * (0.12 + depth * 0.18)))
            context.setLineWidth(1.0 + depth * 3.0)
            context.strokeEllipse(in: rect)
        }

        if mode == .pepperGhost || mode == .realisticStack {
            drawPepperGhostStage(context, size: size, request: request, time: time, beat: beat, depth: depth)
        }

        if mode == .lightField || mode == .realisticStack {
            drawLightFieldVolume(context, size: size, request: request, time: time, beat: beat, depth: depth)
        }

        if mode == .cghSpeckle || mode == .realisticStack || mode == .interference {
            drawCGHSpeckle(context, size: size, request: request, time: time, depth: depth)
        }

        if mode == .chromaDepth || mode == .interference || mode == .realisticStack {
            context.setBlendMode(.plusLighter)
            for band in 0..<18 {
                let y = size.height * Double(band) / 18.0
                let offset = sin(time * 2.0 + Double(band) * 0.8) * depth * 40.0
                context.setStrokeColor(CGColor(red: 1.0, green: 0.1, blue: 0.55, alpha: 0.10 + depth * 0.10))
                context.move(to: CGPoint(x: offset, y: y))
                context.addLine(to: CGPoint(x: size.width + offset, y: y + 20))
                context.strokePath()
                context.setStrokeColor(CGColor(red: 0.1, green: 0.75, blue: 1.0, alpha: 0.10 + depth * 0.10))
                context.move(to: CGPoint(x: -offset, y: y + 6))
                context.addLine(to: CGPoint(x: size.width - offset, y: y - 14))
                context.strokePath()
            }
        }
    }

    private static func drawPepperGhostStage(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, depth: Double) {
        context.setBlendMode(.screen)
        let shortest = min(size.width, size.height)
        let topInset = max(20, size.width * (0.22 - depth * 0.04))
        let bottomInset = max(12, size.width * (0.10 - depth * 0.025))
        let topY = size.height * 0.18
        let bottomY = size.height * 0.84

        let plane = CGMutablePath()
        plane.move(to: CGPoint(x: topInset, y: topY))
        plane.addLine(to: CGPoint(x: size.width - topInset, y: topY + shortest * 0.035))
        plane.addLine(to: CGPoint(x: size.width - bottomInset, y: bottomY))
        plane.addLine(to: CGPoint(x: bottomInset, y: bottomY - shortest * 0.045))
        plane.closeSubpath()
        context.addPath(plane)
        context.setFillColor(CGColor(red: 0.10, green: 0.95, blue: 1.0, alpha: 0.018 + depth * 0.035))
        context.fillPath()
        context.addPath(plane)
        context.setStrokeColor(CGColor(red: 0.64, green: 1.0, blue: 0.94, alpha: 0.10 + depth * 0.18))
        context.setLineWidth(1.0 + depth * 2.2)
        context.strokePath()

        let center = CGPoint(x: size.width * (0.50 + sin(time * 0.19) * 0.035), y: size.height * (0.55 + cos(time * 0.13) * 0.03))
        let layers = max(5, 5 + Int(depth * 4.0))
        for echo in 0..<layers {
            let t = Double(echo) / Double(max(1, layers - 1))
            let lift = shortest * (0.18 + t * 0.12 + beat * 0.04)
            let drift = sin(time * 0.6 + t * 4.7) * shortest * depth * (0.03 + t * 0.02)
            let width = shortest * (0.20 + t * 0.06)
            let height = shortest * (0.38 - t * 0.05)
            let x = center.x + drift + (t - 0.5) * shortest * depth * 0.12
            let y = center.y - lift * 0.35 + t * shortest * 0.05
            let alpha = (1.0 - t * 0.72) * (0.070 + depth * 0.12)
            let body = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)

            context.setStrokeColor(CGColor(red: 0.35, green: 1.0, blue: 0.88, alpha: alpha))
            context.setLineWidth(0.9 + depth * 2.2)
            context.strokeEllipse(in: body)
            context.setStrokeColor(neonColor(Double((request.preset.id * 17) % 360) / 360.0 + t, alpha: alpha * 0.55))
            context.setLineWidth(0.7 + depth * 1.4)
            context.strokeEllipse(in: body.insetBy(dx: width * 0.18, dy: height * 0.20))

            let spine = CGMutablePath()
            spine.move(to: CGPoint(x: x, y: body.minY + height * 0.18))
            spine.addCurve(
                to: CGPoint(x: x + sin(time + t * 3.0) * width * 0.16, y: body.maxY - height * 0.16),
                control1: CGPoint(x: x - width * 0.20, y: y - height * 0.10),
                control2: CGPoint(x: x + width * 0.24, y: y + height * 0.20)
            )
            context.addPath(spine)
            context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha * 0.62))
            context.setLineWidth(0.55 + depth)
            context.strokePath()
        }

        let shadow = CGRect(x: center.x - shortest * 0.24, y: size.height * 0.82, width: shortest * 0.48, height: shortest * 0.055)
        context.setBlendMode(.multiply)
        context.setFillColor(CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.18 + depth * 0.18))
        context.fillEllipse(in: shadow)
        context.setBlendMode(.plusLighter)

        for glint in 0..<10 {
            let t = Double(glint) / 9.0
            let x = bottomInset + (size.width - bottomInset * 2.0) * t
            let y = bottomY - shortest * 0.03 + sin(time * 1.4 + t * 8.0) * shortest * 0.012
            context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.035 + depth * 0.085))
            context.setLineWidth(0.7 + depth * 1.2)
            context.move(to: CGPoint(x: x, y: y))
            context.addLine(to: CGPoint(x: x + shortest * (0.035 + depth * 0.05), y: y - shortest * (0.08 + depth * 0.04)))
            context.strokePath()
        }
    }

    private static func drawLightFieldVolume(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, beat: Double, depth: Double) {
        context.setBlendMode(.screen)
        let shortest = min(size.width, size.height)
        let center = CGPoint(x: size.width * (0.50 + sin(time * 0.07) * 0.04), y: size.height * (0.50 + cos(time * 0.09) * 0.04))
        let hueBase = Double((request.preset.id * 31) % 360) / 360.0
        let slices = 22
        for slice in 0..<slices {
            let t = Double(slice) / Double(max(1, slices - 1))
            let z = (t - 0.5) * 2.0
            let parallax = z * shortest * depth * 0.18
            let wobble = sin(time * 0.45 + t * 9.0)
            let w = shortest * (0.18 + t * 0.42)
            let h = shortest * (0.10 + t * 0.22)
            let rect = CGRect(
                x: center.x - w / 2 + parallax * 0.55 + wobble * depth * 18.0,
                y: center.y - h / 2 + parallax * 0.18 + cos(time * 0.37 + t * 6.0) * depth * 16.0,
                width: w,
                height: h
            )
            let alpha = (1.0 - abs(z) * 0.58) * (0.020 + depth * 0.070)
            context.setStrokeColor(neonColor(hueBase + t + time * 0.025, alpha: alpha))
            context.setLineWidth(0.8 + depth * 1.8)
            context.strokeEllipse(in: rect)

            if slice % 2 == 0 {
                context.setStrokeColor(CGColor(red: 0.35, green: 1.0, blue: 0.92, alpha: alpha * 0.85))
                context.setLineWidth(0.5 + depth)
                context.move(to: CGPoint(x: rect.minX, y: rect.midY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + sin(time + t * 7.0) * h * 0.22))
                context.strokePath()
            }

            for voxel in 0..<7 {
                let seedA = Double((slice * 73 + voxel * 41 + request.sceneSeed * 17) % 997) / 997.0
                let seedB = Double((slice * 29 + voxel * 67 + request.sceneSeed * 23) % 991) / 991.0
                let angle = seedA * .pi * 2.0 + time * (0.18 + seedB * 0.22)
                let radius = seedB * 0.48
                let x = rect.midX + cos(angle) * rect.width * radius
                let y = rect.midY + sin(angle * 1.7) * rect.height * radius
                let d = shortest * (0.0035 + seedA * 0.0045) * (0.7 + depth)
                context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha * (1.6 + seedB)))
                context.fillEllipse(in: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d))
            }
        }

        context.setBlendMode(.plusLighter)
        for ray in 0..<28 {
            let t = Double(ray) / 28.0
            let angle = t * .pi * 2.0 + sin(time * 0.19) * 0.35
            let inner = shortest * (0.08 + beat * 0.08)
            let outer = shortest * (0.32 + depth * 0.28 + 0.05 * sin(time + t * 11.0))
            context.setStrokeColor(neonColor(hueBase + 0.35 + t, alpha: 0.018 + depth * 0.045))
            context.setLineWidth(0.6 + depth * 1.3)
            context.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner * 0.58))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer * 0.58))
            context.strokePath()
        }
    }

    private static func drawCGHSpeckle(_ context: CGContext, size: CGSize, request: MP4RecordingRequest, time: Double, depth: Double) {
        context.setBlendMode(.plusLighter)
        let grains = 150 + Int(depth * 180)
        let hueBase = Double((request.preset.id * 43) % 360) / 360.0
        for grain in 0..<grains {
            let sx = Double((grain * 37 + request.sceneSeed * 11) % 997) / 997.0
            let sy = Double((grain * 61 + request.sceneSeed * 19) % 991) / 991.0
            let x = sx * size.width
            let y = sy * size.height
            let carrier = sin(x * 0.018 + y * 0.013 + time * 1.6 + Double(grain % 17))
            let shimmer = 0.5 + 0.5 * sin(time * (0.68 + Double(grain % 13) * 0.033) + Double(grain) * 1.913)
            let alpha = (0.010 + carrier * carrier * 0.034 + shimmer * 0.026) * depth
            let diameter = 0.75 + sx * (1.7 + depth * 1.6)
            context.setFillColor(grain % 5 == 0 ? neonColor(hueBase + sx + time * 0.01, alpha: alpha) : CGColor(red: 0.78, green: 1.0, blue: 0.96, alpha: alpha))
            context.fillEllipse(in: CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter))
        }

        let rows = 18
        for row in 0..<rows {
            let t = Double(row) / Double(rows)
            let step = max(10.0, size.width / 96.0)
            context.setStrokeColor(CGColor(red: 0.55, green: 1.0, blue: 0.92, alpha: 0.018 + depth * 0.052))
            context.setLineWidth(0.55 + depth * 1.15)
            context.beginPath()
            context.move(to: CGPoint(x: 0, y: size.height * t))
            for x in stride(from: 0.0, through: size.width, by: step) {
                let phase = x * 0.018 + t * 19.0 + time * (0.55 + depth)
                let y = size.height * t + sin(phase) * (8.0 + depth * 28.0) + cos(phase * 0.43) * depth * 18.0
                context.addLine(to: CGPoint(x: x, y: y))
            }
            context.strokePath()
        }
    }

    private static func neonColor(_ hue: Double, alpha: Double) -> CGColor {
        let h = hue.truncatingRemainder(dividingBy: 1)
        let sector = h * 6.0
        let x = 1.0 - abs(sector.truncatingRemainder(dividingBy: 2.0) - 1.0)
        let rgb: (Double, Double, Double)
        switch Int(sector) {
        case 0: rgb = (1, x, 0)
        case 1: rgb = (x, 1, 0)
        case 2: rgb = (0, 1, x)
        case 3: rgb = (0, x, 1)
        case 4: rgb = (x, 0, 1)
        default: rgb = (1, 0, x)
        }
        return CGColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: min(1, max(0, alpha)))
    }
}
