import AppKit
import Foundation
import MetalKit
import simd

private struct ShaderUniforms {
    var resolutionTime: SIMD4<Float>
    var feedbackSource: SIMD4<Float>
    var motion: SIMD4<Float>
    var symmetry: SIMD4<Float>
    var optics: SIMD4<Float>
    var colorA: SIMD4<Float>
    var colorB: SIMD4<Float>
    var signalA: SIMD4<Float>
    var signalB: SIMD4<Float>
    var finishA: SIMD4<Float>
    var finishB: SIMD4<Float>
    var finishC: SIMD4<Float>
    var modes: SIMD4<Float>
    var audio: SIMD4<Float>

    init(settings: EffectSettings, audioSettings: AudioSettings, audioMetrics: AudioReactiveMetrics, size: CGSize, time: Float, frame: UInt64) {
        resolutionTime = SIMD4(Float(size.width), Float(size.height), time, Float(frame))
        feedbackSource = SIMD4(settings.feedback, settings.sourceMix, settings.zoom, settings.rotation)
        motion = SIMD4(settings.driftX, settings.driftY, settings.spiral, settings.wobble)
        symmetry = SIMD4(settings.kaleidoscope, settings.mirrorMix, settings.facetMix, settings.prism)
        optics = SIMD4(settings.prismCount, settings.refraction, settings.reflection, settings.universe)
        colorA = SIMD4(settings.hueShift, settings.saturation, settings.contrast, settings.brightness)
        colorB = SIMD4(settings.gamma, settings.chromaSplit, settings.lumaMix, settings.invert)
        signalA = SIMD4(settings.plasma, settings.tunnel, settings.twister, settings.raster)
        signalB = SIMD4(settings.rings, settings.moire, settings.fractal, settings.noise)
        finishA = SIMD4(settings.xorField, settings.scanlines, settings.grain, settings.bloom)
        finishB = SIMD4(settings.edgeGlow, settings.vignette, settings.feedbackWarp, settings.temporalJitter)
        finishC = SIMD4(settings.beat, settings.strobe, settings.pixelate, settings.detail)
        modes = SIMD4(settings.colorSpace, audioSettings.reactive ? 1.0 : 0.0, audioSettings.reactivity, 0.0)
        audio = SIMD4(audioMetrics.level, audioMetrics.bass, audioMetrics.shimmer, audioMetrics.beatPhase)
    }
}

final class FeedbackRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice

    private let commandQueue: MTLCommandQueue
    private let scenePipeline: MTLRenderPipelineState
    private let copyPipeline: MTLRenderPipelineState
    private let samplerState: MTLSamplerState
    private let recorder = FrameRecorder()

    private weak var view: MTKView?
    private var settings = EffectSettings.baseline
    private var qualityScale: Float = 1.35
    private var captureSize = CaptureProfile.hd1080.size
    private var captureFPS = 30
    private var presetName = "True Feedback 01"
    private var audioSettings = AudioSettings()
    private var isRecording = false
    private var frameIndex: UInt64 = 0
    private var startTime = CACurrentMediaTime()
    private var pingTextures: [MTLTexture?] = [nil, nil]
    private var currentTextureIndex = 0
    private var workingSize = CGSize.zero
    private var isUpdatingDrawableSize = false
    var audioProvider: (() -> AudioReactiveMetrics)?

    override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is required for eyecandy.")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Unable to create a Metal command queue.")
        }

        self.device = device
        self.commandQueue = commandQueue

        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: ShaderSource.library, options: nil)
        } catch {
            fatalError("Unable to compile Metal shaders: \(error.localizedDescription)")
        }

        let sceneDescriptor = MTLRenderPipelineDescriptor()
        sceneDescriptor.vertexFunction = library.makeFunction(name: "passthroughVertex")
        sceneDescriptor.fragmentFunction = library.makeFunction(name: "feedbackFragment")
        sceneDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let copyDescriptor = MTLRenderPipelineDescriptor()
        copyDescriptor.vertexFunction = library.makeFunction(name: "passthroughVertex")
        copyDescriptor.fragmentFunction = library.makeFunction(name: "copyFragment")
        copyDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            scenePipeline = try device.makeRenderPipelineState(descriptor: sceneDescriptor)
            copyPipeline = try device.makeRenderPipelineState(descriptor: copyDescriptor)
        } catch {
            fatalError("Unable to create Metal pipelines: \(error.localizedDescription)")
        }

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            fatalError("Unable to create a Metal sampler.")
        }
        self.samplerState = samplerState

        super.init()
    }

    func attach(to view: MTKView) {
        self.view = view
        updateDrawableSize(for: view, qualityScale: qualityScale)
    }

    func update(settings: EffectSettings, audioSettings: AudioSettings, qualityScale: Float, captureSize: CGSize, captureFPS: Int, presetName: String) {
        self.settings = settings
        self.audioSettings = audioSettings
        self.qualityScale = qualityScale
        self.captureSize = captureSize
        self.captureFPS = captureFPS
        self.presetName = presetName

        if let view {
            updateDrawableSize(for: view, qualityScale: qualityScale)
        }
    }

    func startRecording(to url: URL, size: CGSize, fps: Int) throws {
        captureSize = size
        captureFPS = fps
        try recorder.start(url: url, size: size, fps: fps)
        isRecording = true
        resetFeedback()
    }

    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard recorder.isRecording else {
            completion(.failure(FrameRecorderError.notRecording))
            return
        }

        isRecording = false
        recorder.finish { [weak self] result in
            self?.resetFeedback()
            completion(result)
        }
    }

    func updateDrawableSize(for view: MTKView, qualityScale: Float) {
        guard !isUpdatingDrawableSize else { return }

        let backingScale = view.window?.backingScaleFactor
            ?? view.window?.screen?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? 2.0

        let width = max(Int((view.bounds.width * backingScale * CGFloat(qualityScale)).rounded(.up)), 1)
        let height = max(Int((view.bounds.height * backingScale * CGFloat(qualityScale)).rounded(.up)), 1)
        let nextSize = CGSize(width: width, height: height)
        guard view.drawableSize != nextSize else { return }

        isUpdatingDrawableSize = true
        view.drawableSize = nextSize
        isUpdatingDrawableSize = false
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        let targetSize = isRecording ? captureSize : CGSize(width: view.drawableSize.width, height: view.drawableSize.height)
        guard targetSize.width >= 1.0, targetSize.height >= 1.0 else { return }

        ensureFeedbackTextures(size: targetSize)
        guard let previousTexture = pingTextures[currentTextureIndex], let nextTexture = pingTextures[1 - currentTextureIndex] else {
            return
        }

        commandBuffer.label = "EyeCandy Frame \(frameIndex) \(presetName)"
        renderScene(into: nextTexture, previous: previousTexture, size: targetSize, with: commandBuffer)
        renderPreview(into: drawable.texture, source: nextTexture, with: commandBuffer, descriptor: renderPassDescriptor)

        if recorder.isRecording {
            recorder.append(texture: nextTexture, on: commandBuffer, frameIndex: frameIndex, fps: captureFPS)
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()

        currentTextureIndex = 1 - currentTextureIndex
        frameIndex += 1
    }

    private func renderScene(into texture: MTLTexture, previous: MTLTexture, size: CGSize, with commandBuffer: MTLCommandBuffer) {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        let elapsed = Float(CACurrentMediaTime() - startTime)
        let metrics = audioProvider?() ?? .neutral
        var uniforms = ShaderUniforms(
            settings: settings,
            audioSettings: audioSettings,
            audioMetrics: metrics,
            size: size,
            time: elapsed,
            frame: frameIndex
        )

        encoder.setRenderPipelineState(scenePipeline)
        encoder.setFragmentTexture(previous, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ShaderUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
    }

    private func renderPreview(into texture: MTLTexture, source: MTLTexture, with commandBuffer: MTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(copyPipeline)
        encoder.setFragmentTexture(source, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
    }

    private func ensureFeedbackTextures(size: CGSize) {
        if size == workingSize, pingTextures.allSatisfy({ $0 != nil }) {
            return
        }

        workingSize = size
        pingTextures = [makeTexture(size: size), makeTexture(size: size)]
        currentTextureIndex = 0
    }

    private func makeTexture(size: CGSize) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: max(Int(size.width.rounded()), 1),
            height: max(Int(size.height.rounded()), 1),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .shared
        return device.makeTexture(descriptor: descriptor)
    }

    private func resetFeedback() {
        pingTextures = [nil, nil]
        workingSize = .zero
        currentTextureIndex = 0
        frameIndex = 0
        startTime = CACurrentMediaTime()
    }
}
