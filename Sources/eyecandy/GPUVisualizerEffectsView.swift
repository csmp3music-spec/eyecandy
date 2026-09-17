import AppKit
import MetalKit
import OpenGL.GL
import SwiftUI

struct GPUVisualizerEffectsView: NSViewRepresentable {
    @ObservedObject var model: AppModel

    func makeNSView(context: Context) -> GPUVisualizerEffectsContainer {
        GPUVisualizerEffectsContainer()
    }

    func updateNSView(_ view: GPUVisualizerEffectsContainer, context: Context) {
        view.update(backend: model.gpuVisualizerBackend, state: GPUVisualizerEffectState(model: model))
    }
}

struct GPUVisualizerEffectState {
    var intensity: Float
    var detail: Float
    var persistence: Float
    var bass: Float
    var mid: Float
    var treble: Float
    var flux: Float
    var transient: Float
    var kick: Float
    var snare: Float
    var hat: Float
    var clap: Float
    var feedback: Float
    var macroX: Float
    var macroY: Float
    var metalEffectMode: Float
    var metalEffectIntensity: Float
    var metalEffectSpeed: Float
    var openGLStyle: Float
    var cameraImage: CGImage?
    var cameraMix: Float
    var cameraRotation: Float
    var cameraMirror: Bool

    init(intensity: Float, detail: Float, persistence: Float, bass: Float, mid: Float, treble: Float, flux: Float, transient: Float, feedback: Float, macroX: Float, macroY: Float, metalEffectMode: Float, metalEffectIntensity: Float, metalEffectSpeed: Float, kick: Float = 0, snare: Float = 0, hat: Float = 0, clap: Float = 0, openGLStyle: Float = 4, cameraImage: CGImage? = nil, cameraMix: Float = 0, cameraRotation: Float = 0, cameraMirror: Bool = false) {
        self.intensity = intensity
        self.detail = detail
        self.persistence = persistence
        self.bass = bass
        self.mid = mid
        self.treble = treble
        self.flux = flux
        self.transient = transient
        self.kick = kick
        self.snare = snare
        self.hat = hat
        self.clap = clap
        self.feedback = feedback
        self.macroX = macroX
        self.macroY = macroY
        self.metalEffectMode = metalEffectMode
        self.metalEffectIntensity = metalEffectIntensity
        self.metalEffectSpeed = metalEffectSpeed
        self.openGLStyle = openGLStyle
        self.cameraImage = cameraImage
        self.cameraMix = cameraMix
        self.cameraRotation = cameraRotation
        self.cameraMirror = cameraMirror
    }

    @MainActor init(model: AppModel) {
        intensity = Float(model.audioVisualizerIntensity)
        detail = Float(model.audioVisualizerDetail)
        persistence = Float(model.audioVisualizerPersistence)
        bass = Float(model.audioMeter.bass)
        mid = Float(model.audioMeter.mid)
        treble = Float(model.audioMeter.treble)
        flux = Float(model.audioMeter.spectralFlux)
        transient = Float(model.audioMeter.transient)
        kick = Float(model.audioMeter.kick)
        snare = Float(model.audioMeter.snare)
        hat = Float(model.audioMeter.hat)
        clap = Float(model.audioMeter.clap)
        feedback = Float(max(model.feedbackSimulatorMode == .off ? 0 : model.feedbackSimulatorIntensity, model.cameraInputEnabled ? model.cameraFeedbackAmount : 0))
        macroX = Float(model.macroX)
        macroY = Float(model.macroY)
        metalEffectMode = model.metalVisualizerEffectMode.shaderIndex
        metalEffectIntensity = Float(model.metalVisualizerEffectIntensity)
        metalEffectSpeed = Float(model.metalVisualizerEffectSpeed)
        openGLStyle = model.openGLVisualizerStyle.shaderIndex
        cameraImage = model.cameraInputEnabled ? model.cameraInput.latestImage : nil
        cameraMix = Float(model.cameraInputEnabled ? model.cameraOverlayOpacity : 0)
        cameraRotation = Float(model.cameraFeedbackRotation)
        cameraMirror = model.cameraMirror
    }
}

final class GPUVisualizerEffectsContainer: NSView {
    private var metalView: MetalVisualizerEffectsView?
    private var openGLView: OpenGLVisualizerEffectsView?
    private var currentBackend: GPUVisualizerBackend?

    override var isOpaque: Bool { false }

    override func layout() {
        super.layout()
        metalView?.frame = bounds
        openGLView?.frame = bounds
    }

    func update(backend: GPUVisualizerBackend, state: GPUVisualizerEffectState) {
        guard backend != currentBackend else {
            metalView?.effectState = state
            openGLView?.effectState = state
            return
        }

        metalView?.removeFromSuperview()
        openGLView?.removeFromSuperview()
        metalView = nil
        openGLView = nil
        currentBackend = backend

        switch backend {
        case .metal:
            guard let device = MTLCreateSystemDefaultDevice() else {
                currentBackend = .canvasOnly
                return
            }
            let view = MetalVisualizerEffectsView(frame: bounds, device: device)
            view.effectState = state
            addSubview(view)
            metalView = view
        case .openGL:
            guard let view = OpenGLVisualizerEffectsView.make(frame: bounds) else {
                currentBackend = .canvasOnly
                return
            }
            view.effectState = state
            addSubview(view)
            openGLView = view
        case .canvasOnly:
            break
        }
    }
}

private struct MetalEffectUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var intensity: Float
    var detail: Float
    var persistence: Float
    var bass: Float
    var mid: Float
    var treble: Float
    var flux: Float
    var transient: Float
    var feedback: Float
    var macroX: Float
    var macroY: Float
    var metalEffectMode: Float
    var metalEffectIntensity: Float
    var metalEffectSpeed: Float
}

private final class MetalVisualizerEffectsView: MTKView, MTKViewDelegate {
    var effectState = GPUVisualizerEffectState(
        intensity: 0, detail: 0, persistence: 0, bass: 0, mid: 0, treble: 0, flux: 0, transient: 0, feedback: 0, macroX: 0.5, macroY: 0.5, metalEffectMode: 0, metalEffectIntensity: 0, metalEffectSpeed: 0.7
    )

    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private var startedAt = Date.timeIntervalSinceReferenceDate

    override var isOpaque: Bool { false }

    init(frame: CGRect, device: MTLDevice) {
        super.init(frame: frame, device: device)
        layer?.isOpaque = false
        framebufferOnly = true
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColorMake(0, 0, 0, 0)
        preferredFramesPerSecond = 60
        enableSetNeedsDisplay = false
        isPaused = false
        delegate = self
        commandQueue = device.makeCommandQueue()
        pipelineState = Self.makePipeline(device: device, pixelFormat: colorPixelFormat)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pipelineState, let descriptor = currentRenderPassDescriptor, let drawable = currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        let now = Float(Date.timeIntervalSinceReferenceDate - startedAt)
        var uniforms = MetalEffectUniforms(
            resolution: SIMD2(Float(drawableSize.width), Float(drawableSize.height)),
            time: now,
            intensity: effectState.intensity,
            detail: effectState.detail,
            persistence: effectState.persistence,
            bass: effectState.bass,
            mid: effectState.mid,
            treble: effectState.treble,
            flux: effectState.flux,
            transient: effectState.transient,
            feedback: effectState.feedback,
            macroX: effectState.macroX,
            macroY: effectState.macroY,
            metalEffectMode: effectState.metalEffectMode,
            metalEffectIntensity: effectState.metalEffectIntensity,
            metalEffectSpeed: effectState.metalEffectSpeed
        )
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalEffectUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static func makePipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState? {
        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut { float4 position [[position]]; float2 uv; };
        struct Uniforms {
            float2 resolution; float time; float intensity; float detail; float persistence;
            float bass; float mid; float treble; float flux; float transient; float feedback;
            float macroX; float macroY; float metalEffectMode; float metalEffectIntensity;
            float metalEffectSpeed;
        };

        vertex VertexOut visualizerVertex(uint vertexID [[vertex_id]]) {
            float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
            VertexOut out;
            out.position = float4(positions[vertexID], 0.0, 1.0);
            out.uv = positions[vertexID] * 0.5 + 0.5;
            return out;
        }

        float hash21(float2 p) { return fract(sin(dot(p, float2(41.17, 289.31))) * 28371.91); }

        float hash31(float3 p) { return fract(sin(dot(p, float3(17.13, 71.71, 43.91))) * 15137.19); }

        float3 spectralColor(float phase) {
            return 0.5 + 0.5 * cos(6.283185 * (phase + float3(0.0, 0.33, 0.67)));
        }

        float fractalField(float2 point, float time, float detail) {
            float2 z = point;
            float2 c = float2(sin(time * 0.19), cos(time * 0.13)) * 0.34;
            float trap = 10.0;
            for (int index = 0; index < 8; index++) {
                z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
                trap = min(trap, abs(length(z) - 0.38 - detail * 0.18));
                if (dot(z, z) > 18.0) { break; }
            }
            return exp(-trap * (15.0 + detail * 35.0));
        }

        fragment float4 visualizerFragment(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
            float2 uv = in.uv;
            float2 centered = uv - 0.5;
            centered.x *= u.resolution.x / max(1.0, u.resolution.y);
            float radius = length(centered);
            float angle = atan2(centered.y, centered.x);
            float scan = 0.5 + 0.5 * sin(uv.y * u.resolution.y * (0.34 + u.detail * 0.80) + u.time * 8.0);
            float rings = 0.5 + 0.5 * sin(radius * (92.0 + u.detail * 130.0) - u.time * (4.0 + u.bass * 12.0));
            float spokes = pow(max(0.0, sin(angle * (12.0 + u.detail * 30.0) + u.time * (0.8 + u.flux * 5.0))), 18.0);
            float feedback = pow(max(0.0, sin(radius * (180.0 + u.feedback * 160.0) - u.time * 6.0)), 32.0);
            float grain = hash21(floor(uv * u.resolution.xy * (0.10 + u.detail * 0.14)) + floor(u.time * 24.0));
            float particle = smoothstep(0.94 - u.transient * 0.16, 1.0, grain) * (0.25 + u.flux * 0.75);
            float alpha = (scan * 0.025 + rings * 0.045 + spokes * 0.14 + feedback * 0.09 + particle * 0.18) * u.intensity;
            alpha *= smoothstep(0.82, 0.10, radius);
            float hue = angle * 0.159 + u.time * 0.035 + u.macroX * 0.22;
            float3 color = spectralColor(hue);
            color = mix(color, float3(0.65, 1.0, 0.86), scan * (0.22 + u.treble * 0.30));
            float effectAlpha = 0.0;
            float3 effectColor = color;
            float speed = max(0.1, u.metalEffectSpeed);

            if (u.metalEffectMode > 0.5 && u.metalEffectMode < 1.5) {
                float cycle = fract(u.time * speed * 0.075);
                float fadeIn = smoothstep(0.0, 0.17, cycle);
                float fadeOut = 1.0 - smoothstep(0.72, 1.0, cycle);
                float gate = fadeIn * fadeOut;
                float rays = pow(max(0.0, sin(angle * 18.0 - u.time * speed * 2.4)), 26.0);
                float horizon = exp(-abs(centered.y + sin(u.time * speed) * 0.12) * (20.0 + u.detail * 42.0));
                effectColor = mix(float3(0.08, 0.48, 1.0), float3(1.0, 0.12, 0.68), rays + radius * 0.7);
                effectAlpha = gate * (rays * 0.30 + horizon * 0.18 + rings * 0.08);
            } else if (u.metalEffectMode > 1.5 && u.metalEffectMode < 2.5) {
                float dissolveTime = fract(u.time * speed * 0.11);
                float noise = hash31(float3(floor(uv * u.resolution.xy * 0.12), floor(u.time * speed * 12.0)));
                float threshold = dissolveTime * 1.25 - 0.12;
                float body = smoothstep(threshold - 0.10, threshold + 0.06, noise);
                float edge = 1.0 - smoothstep(0.0, 0.075, abs(noise - threshold));
                float portal = exp(-abs(radius - (0.16 + dissolveTime * 0.34)) * (16.0 + u.detail * 40.0));
                effectColor = mix(spectralColor(noise + u.time * 0.03), float3(1.0, 0.92, 0.48), edge);
                effectAlpha = (body * portal * 0.32 + edge * 0.34) * (0.50 + u.flux * 0.50);
            } else if (u.metalEffectMode > 2.5 && u.metalEffectMode < 3.5) {
                float kaleidoAngle = abs(fract(angle / 6.283185 * (5.0 + floor(u.detail * 10.0))) - 0.5);
                float plasma = sin(radius * (28.0 + u.detail * 54.0) + u.time * speed * 2.4);
                plasma += sin(kaleidoAngle * 44.0 - u.time * speed * 1.7);
                plasma += sin((centered.x + centered.y) * 18.0 + u.time * speed);
                plasma = 0.5 + 0.5 * sin(plasma);
                effectColor = spectralColor(plasma + radius * 0.36 + u.macroY * 0.18);
                effectAlpha = plasma * smoothstep(0.86, 0.08, radius) * (0.10 + u.flux * 0.22);
            } else if (u.metalEffectMode > 3.5 && u.metalEffectMode < 4.5) {
                float field = fractalField(centered * (1.85 + u.bass * 0.42), u.time * speed, u.detail);
                float petals = pow(max(0.0, sin(angle * (8.0 + u.detail * 22.0) + u.time * speed)), 12.0);
                effectColor = spectralColor(field * 0.78 + angle * 0.11 + u.time * 0.025);
                effectAlpha = (field * 0.36 + petals * field * 0.20) * smoothstep(0.96, 0.04, radius);
            } else if (u.metalEffectMode > 4.5) {
                float depth = fract(-log(max(0.001, radius)) * (5.0 + u.feedback * 9.0) - u.time * speed * 1.8);
                float arches = pow(max(0.0, sin(angle * (6.0 + u.detail * 15.0) + depth * 8.0)), 22.0);
                float vault = exp(-abs(sin(depth * 14.0 + radius * 32.0)) * (4.0 + u.detail * 9.0));
                effectColor = mix(float3(0.08, 0.92, 0.84), spectralColor(depth + u.macroX * 0.2), arches);
                effectAlpha = (arches * 0.30 + vault * 0.14) * smoothstep(0.94, 0.05, radius);
            }
            float blend = clamp(effectAlpha * u.metalEffectIntensity, 0.0, 0.72);
            color = mix(color, effectColor, blend);
            alpha = max(alpha, effectAlpha * u.metalEffectIntensity);
            return float4(color, clamp(alpha, 0.0, 0.48));
        }
        """
        do {
            let library = try device.makeLibrary(source: source, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "visualizerVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "visualizerFragment")
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            return nil
        }
    }
}

private final class OpenGLVisualizerEffectsView: NSOpenGLView {
    var effectState = GPUVisualizerEffectState(
        intensity: 0, detail: 0, persistence: 0, bass: 0, mid: 0, treble: 0, flux: 0, transient: 0, feedback: 0, macroX: 0.5, macroY: 0.5, metalEffectMode: 0, metalEffectIntensity: 0, metalEffectSpeed: 0.7
    )

    private var startedAt = Date.timeIntervalSinceReferenceDate
    private var redrawTimer: Timer?
    private var feedbackTexture: GLuint = 0
    private var cameraTexture: GLuint = 0
    private var textureWidth: GLsizei = 0
    private var textureHeight: GLsizei = 0

    override var isOpaque: Bool { false }

    static func make(frame: CGRect) -> OpenGLVisualizerEffectsView? {
        let attributes: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersionLegacy),
            UInt32(NSOpenGLPFAColorSize), 24,
            UInt32(NSOpenGLPFAAlphaSize), 8,
            UInt32(NSOpenGLPFADoubleBuffer),
            0
        ]
        guard let pixelFormat = NSOpenGLPixelFormat(attributes: attributes) else { return nil }
        return OpenGLVisualizerEffectsView(frame: frame, effectPixelFormat: pixelFormat)
    }

    private init(frame: CGRect, effectPixelFormat: NSOpenGLPixelFormat) {
        super.init(frame: frame, pixelFormat: effectPixelFormat)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareOpenGL() {
        super.prepareOpenGL()
        openGLContext?.makeCurrentContext()
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_BLEND))
        glEnable(GLenum(GL_LINE_SMOOTH))
        glHint(GLenum(GL_LINE_SMOOTH_HINT), GLenum(GL_NICEST))
        glGenTextures(1, &feedbackTexture)
        glGenTextures(1, &cameraTexture)
        redrawTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = openGLContext else { return }
        context.makeCurrentContext()

        let backingSize = convertToBacking(bounds).size
        let width = max(1, GLsizei(backingSize.width.rounded()))
        let height = max(1, GLsizei(backingSize.height.rounded()))
        let time = Float(Date.timeIntervalSinceReferenceDate - startedAt)
        ensureFeedbackTexture(width: width, height: height)

        glViewport(0, 0, width, height)
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glOrtho(0, GLdouble(width), 0, GLdouble(height), -1, 1)
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        drawFeedback(width: Float(width), height: Float(height))
        drawCameraSource(width: Float(width), height: Float(height))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE))

        let style = Int(effectState.openGLStyle.rounded())
        if style == 0 || style == 4 {
            drawNeonHighway(width: Float(width), height: Float(height), time: time)
        }
        if style == 1 || style == 4 {
            drawAcidKaleidoscope(width: Float(width), height: Float(height), time: time)
        }
        if style == 2 || style == 4 {
            drawLissajousBloom(width: Float(width), height: Float(height), time: time)
        }
        if style == 3 || style == 4 {
            drawStarfield(width: Float(width), height: Float(height), time: time)
        }
        drawBeatBursts(width: Float(width), height: Float(height), time: time)
        drawScanlines(width: Float(width), height: Float(height), time: time)

        glBindTexture(GLenum(GL_TEXTURE_2D), feedbackTexture)
        glCopyTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, 0, 0, width, height)
        context.flushBuffer()
    }

    private func ensureFeedbackTexture(width: GLsizei, height: GLsizei) {
        guard feedbackTexture != 0, (width != textureWidth || height != textureHeight) else { return }
        textureWidth = width
        textureHeight = height
        glBindTexture(GLenum(GL_TEXTURE_2D), feedbackTexture)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_LINEAR))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_CLAMP_TO_EDGE))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_CLAMP_TO_EDGE))
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(GL_RGBA), width, height, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
    }

    private func drawFeedback(width: Float, height: Float) {
        guard textureWidth > 0, textureHeight > 0 else { return }
        let feedback = 0.56 + effectState.persistence * 0.34 + effectState.feedback * 0.08
        let zoom = 1.0 + effectState.bass * 0.010 + effectState.flux * 0.006
        let driftX = sin(Float(Date.timeIntervalSinceReferenceDate - startedAt) * 0.31) * effectState.flux * width * 0.008
        let driftY = effectState.snare * height * 0.006
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_TEXTURE_2D))
        glBindTexture(GLenum(GL_TEXTURE_2D), feedbackTexture)
        glColor4f(0.98 + effectState.treble * 0.02, 0.90 + effectState.mid * 0.10, 1.0, feedback)
        let left = (width - width * zoom) * 0.5 + driftX
        let bottom = (height - height * zoom) * 0.5 + driftY
        glBegin(GLenum(GL_QUADS))
        glTexCoord2f(0, 0); glVertex2f(left, bottom)
        glTexCoord2f(1, 0); glVertex2f(left + width * zoom, bottom)
        glTexCoord2f(1, 1); glVertex2f(left + width * zoom, bottom + height * zoom)
        glTexCoord2f(0, 1); glVertex2f(left, bottom + height * zoom)
        glEnd()
        glDisable(GLenum(GL_TEXTURE_2D))
    }

    private func drawCameraSource(width: Float, height: Float) {
        guard effectState.cameraMix > 0.01, let image = effectState.cameraImage, uploadCameraImage(image) else { return }
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_TEXTURE_2D))
        glBindTexture(GLenum(GL_TEXTURE_2D), cameraTexture)
        glColor4f(1, 1, 1, min(0.92, effectState.cameraMix * 0.78))
        glPushMatrix()
        glTranslatef(width * 0.5, height * 0.5, 0)
        glRotatef(effectState.cameraRotation * 18.0, 0, 0, 1)
        glTranslatef(-width * 0.5, -height * 0.5, 0)
        let leftTex: Float = effectState.cameraMirror ? 1 : 0
        let rightTex: Float = effectState.cameraMirror ? 0 : 1
        glBegin(GLenum(GL_QUADS))
        glTexCoord2f(leftTex, 1); glVertex2f(0, 0)
        glTexCoord2f(rightTex, 1); glVertex2f(width, 0)
        glTexCoord2f(rightTex, 0); glVertex2f(width, height)
        glTexCoord2f(leftTex, 0); glVertex2f(0, height)
        glEnd()
        glPopMatrix()
        glDisable(GLenum(GL_TEXTURE_2D))
    }

    private func uploadCameraImage(_ image: CGImage) -> Bool {
        let representation = NSBitmapImageRep(cgImage: image)
        guard let pixels = representation.bitmapData else { return false }
        glBindTexture(GLenum(GL_TEXTURE_2D), cameraTexture)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_LINEAR))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_CLAMP_TO_EDGE))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_CLAMP_TO_EDGE))
        glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1)
        glTexImage2D(
            GLenum(GL_TEXTURE_2D),
            0,
            GLint(GL_RGBA),
            GLsizei(representation.pixelsWide),
            GLsizei(representation.pixelsHigh),
            0,
            GLenum(GL_RGBA),
            GLenum(GL_UNSIGNED_BYTE),
            pixels
        )
        return true
    }

    private func drawNeonHighway(width: Float, height: Float, time: Float) {
        let horizon = height * (0.47 + effectState.snare * 0.06)
        let floorLines = 12 + Int(effectState.detail * 22)
        let alpha = effectState.intensity * (0.06 + effectState.hat * 0.10)
        glLineWidth(1.0 + effectState.treble * 1.8)
        for line in 0..<floorLines {
            let t = (Float(line) / Float(floorLines) + time * (0.10 + effectState.kick * 0.22)).truncatingRemainder(dividingBy: 1)
            let y = horizon - 8 + pow(t, 2.25) * (height - horizon + 10)
            glColor4f(0.12 + t * 0.50, 0.68 + t * 0.32, 1.0, alpha * (1.0 - t * 0.25))
            glBegin(GLenum(GL_LINES))
            glVertex2f(0, y)
            glVertex2f(width, y)
            glEnd()
        }

        let lanes = 14 + Int(effectState.detail * 20)
        let center = width * 0.5
        for lane in -lanes...lanes {
            let laneT = Float(lane) / Float(max(1, lanes))
            let wobble = sin(time * (0.65 + effectState.flux * 2.4) + laneT * 12.0) * width * 0.015
            glColor4f(0.92, 0.12 + abs(laneT) * 0.58, 1.0 - abs(laneT) * 0.28, alpha * (0.55 + effectState.kick * 0.70))
            glBegin(GLenum(GL_LINES))
            glVertex2f(center + laneT * width * 0.035 + wobble * 0.1, horizon)
            glVertex2f(center + laneT * width * 0.76 + wobble, 0)
            glEnd()
        }
    }

    private func drawAcidKaleidoscope(width: Float, height: Float, time: Float) {
        let centerX = width * 0.5
        let centerY = height * 0.5
        let radius = min(width, height) * (0.24 + effectState.bass * 0.18)
        let petals = 8 + Int(effectState.detail * 18)
        let layers = 2 + Int(effectState.persistence * 5)
        for layer in 0..<layers {
            let layerT = Float(layer) / Float(max(1, layers))
            let rotation = time * (0.18 + effectState.flux * 0.54) * (layer.isMultiple(of: 2) ? 1 : -1)
            for petal in 0..<petals {
                let a = Float(petal) / Float(petals) * .pi * 2 + rotation
                let hue = Float(petal) / Float(petals) + time * 0.025 + layerT * 0.18
                let color = spectralColor(hue)
                glColor4f(color.0, color.1, color.2, effectState.intensity * (0.018 + effectState.mid * 0.060 + effectState.snare * 0.075))
                glLineWidth(0.8 + effectState.treble * 2.2)
                glBegin(GLenum(GL_LINE_STRIP))
                for point in 0...52 {
                    let u = Float(point) / 52.0
                    let twist = sin(u * .pi * (3.0 + effectState.treble * 8.0) + time * 2.6 + Float(petal))
                    let r = radius * (0.22 + u * (0.56 + layerT * 0.36)) + twist * radius * (0.03 + effectState.transient * 0.07)
                    let angle = a + (u - 0.5) * (.pi / Float(petals)) * (1.4 + effectState.mid * 1.8)
                    glVertex2f(centerX + cos(angle) * r, centerY + sin(angle) * r * (0.62 + effectState.mid * 0.22))
                }
                glEnd()
            }
        }
    }

    private func drawLissajousBloom(width: Float, height: Float, time: Float) {
        let centerX = width * 0.5
        let centerY = height * 0.5
        let scale = min(width, height) * (0.18 + effectState.harmonicScale)
        let strands = 2 + Int(effectState.detail * 5)
        for strand in 0..<strands {
            let shift = Float(strand) * 0.72 + time * (0.34 + effectState.flux * 0.74)
            let color = spectralColor(Float(strand) / Float(strands) + time * 0.04)
            glColor4f(color.0, color.1, color.2, effectState.intensity * (0.035 + effectState.mid * 0.10 + effectState.hat * 0.06))
            glLineWidth(0.8 + effectState.treble * 2.8)
            glBegin(GLenum(GL_LINE_STRIP))
            for point in 0...240 {
                let t = Float(point) / 240.0 * .pi * 2
                let x = sin(t * (3.0 + effectState.bass * 2.0) + shift) * scale
                let y = sin(t * (4.0 + effectState.mid * 3.0) + shift * 1.37) * scale * (0.58 + effectState.treble * 0.24)
                glVertex2f(centerX + x, centerY + y)
            }
            glEnd()
        }
    }

    private func drawStarfield(width: Float, height: Float, time: Float) {
        let stars = 120 + Int(effectState.detail * 260)
        let centerX = width * (0.5 + effectState.macroX * 0.08 - 0.04)
        let centerY = height * (0.5 + effectState.macroY * 0.08 - 0.04)
        glPointSize(1.0 + effectState.transient * 4.0)
        glBegin(GLenum(GL_POINTS))
        for star in 0..<stars {
            let seed = Float(star) * 12.9898
            let angle = hash(seed + 1.7) * .pi * 2
            let depth = (hash(seed + 5.1) + time * (0.08 + effectState.kick * 0.34)).truncatingRemainder(dividingBy: 1)
            let radius = pow(depth, 2.4) * min(width, height) * (0.22 + effectState.bass * 0.30)
            let color = spectralColor(hash(seed + 9.3) + time * 0.025)
            glColor4f(color.0, color.1, color.2, effectState.intensity * (0.015 + (1.0 - depth) * 0.11 + effectState.hat * 0.06))
            glVertex2f(centerX + cos(angle) * radius, centerY + sin(angle) * radius)
        }
        glEnd()
    }

    private func drawBeatBursts(width: Float, height: Float, time: Float) {
        let pulse = min(1, effectState.kick * 0.88 + effectState.snare * 0.52 + effectState.transient * 0.44)
        guard pulse > 0.01 else { return }
        let centerX = width * 0.5
        let centerY = height * 0.5
        let rays = 20 + Int(effectState.detail * 64)
        let inner = min(width, height) * (0.035 + effectState.bass * 0.11)
        let outer = min(width, height) * (0.16 + pulse * 0.34)
        glLineWidth(1.0 + pulse * 4.0)
        for ray in 0..<rays {
            let angle = Float(ray) / Float(rays) * .pi * 2 + time * (0.16 + effectState.flux * 0.72)
            let color = spectralColor(Float(ray) / Float(rays) + time * 0.06)
            glColor4f(color.0, color.1, color.2, effectState.intensity * pulse * (0.045 + effectState.clap * 0.08))
            glBegin(GLenum(GL_LINES))
            glVertex2f(centerX + cos(angle) * inner, centerY + sin(angle) * inner)
            glVertex2f(centerX + cos(angle) * outer, centerY + sin(angle) * outer)
            glEnd()
        }
    }

    private func drawScanlines(width: Float, height: Float, time: Float) {
        let count = 12 + Int(effectState.detail * 30)
        glLineWidth(1)
        for line in 0..<count {
            let t = Float(line) / Float(count)
            let y = (t * height + sin(time * 4.0 + t * 28.0) * effectState.hat * 8.0).truncatingRemainder(dividingBy: height)
            glColor4f(0.12, 0.92, 1.0, effectState.intensity * (0.005 + effectState.hat * 0.018))
            glBegin(GLenum(GL_LINES))
            glVertex2f(0, y)
            glVertex2f(width, y)
            glEnd()
        }
    }

    private func spectralColor(_ phase: Float) -> (Float, Float, Float) {
        let wave = phase * .pi * 2
        return (0.5 + 0.5 * cos(wave), 0.5 + 0.5 * cos(wave + 2.094), 0.5 + 0.5 * cos(wave + 4.188))
    }

    private func hash(_ value: Float) -> Float {
        (sin(value) * 43_758.5453).truncatingRemainder(dividingBy: 1).magnitude
    }

    deinit {
        redrawTimer?.invalidate()
        openGLContext?.makeCurrentContext()
        if feedbackTexture != 0 {
            glDeleteTextures(1, &feedbackTexture)
        }
        if cameraTexture != 0 {
            glDeleteTextures(1, &cameraTexture)
        }
    }
}

private extension GPUVisualizerEffectState {
    var harmonicScale: Float { 0.16 + mid * 0.11 + bass * 0.07 }
}
