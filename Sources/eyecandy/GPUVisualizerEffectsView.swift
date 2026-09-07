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
    var feedback: Float
    var macroX: Float
    var macroY: Float
    var metalEffectMode: Float
    var metalEffectIntensity: Float
    var metalEffectSpeed: Float

    init(intensity: Float, detail: Float, persistence: Float, bass: Float, mid: Float, treble: Float, flux: Float, transient: Float, feedback: Float, macroX: Float, macroY: Float, metalEffectMode: Float, metalEffectIntensity: Float, metalEffectSpeed: Float) {
        self.intensity = intensity
        self.detail = detail
        self.persistence = persistence
        self.bass = bass
        self.mid = mid
        self.treble = treble
        self.flux = flux
        self.transient = transient
        self.feedback = feedback
        self.macroX = macroX
        self.macroY = macroY
        self.metalEffectMode = metalEffectMode
        self.metalEffectIntensity = metalEffectIntensity
        self.metalEffectSpeed = metalEffectSpeed
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
        feedback = Float(model.feedbackSimulatorMode == .off ? 0 : model.feedbackSimulatorIntensity)
        macroX = Float(model.macroX)
        macroY = Float(model.macroY)
        metalEffectMode = model.metalVisualizerEffectMode.shaderIndex
        metalEffectIntensity = Float(model.metalVisualizerEffectIntensity)
        metalEffectSpeed = Float(model.metalVisualizerEffectSpeed)
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
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        redrawTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = openGLContext else { return }
        context.makeCurrentContext()
        let size = bounds.size
        let time = Float(Date.timeIntervalSinceReferenceDate - startedAt)
        glViewport(0, 0, GLsizei(size.width), GLsizei(size.height))
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glOrtho(0, GLdouble(size.width), 0, GLdouble(size.height), -1, 1)
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()

        let lines = 18 + Int(effectState.detail * 44)
        for line in 0..<lines {
            let t = Float(line) / Float(max(1, lines - 1))
            let y = CGFloat(t) * size.height
            let motionRate: Float = 1.4 + effectState.flux * 4.0
            let motion = sin(time * motionRate + t * 19.0)
            let width = Float(size.width)
            let feedbackScale: Float = effectState.feedback * 0.035
            let driftScale: Float = 0.01 + feedbackScale
            let driftRange: Float = width * driftScale
            let drift = motion * driftRange
            let baseAlpha: Float = 0.012 + effectState.intensity * 0.065
            let brightness: Float = 0.55 + effectState.treble * 0.45
            let alpha = baseAlpha * brightness
            let wavePhase = time + t * 9.0
            let verticalOffset = sin(wavePhase) * effectState.transient * 12.0
            let waveY = Float(y) + verticalOffset
            glColor4f(0.20 + t * 0.60, 0.82, 1.0 - t * 0.40, alpha)
            glBegin(GLenum(GL_LINES))
            glVertex2f(drift, Float(y))
            glVertex2f(Float(size.width) + drift, waveY)
            glEnd()
        }

        let rings = 5 + Int(effectState.persistence * 12)
        let centerX = Float(size.width * 0.5)
        let centerY = Float(size.height * 0.5)
        let shortest = Float(min(size.width, size.height))
        for ring in 0..<rings {
            let speed: Float = 0.05 + effectState.bass * 0.16
            let phaseBase = Float(ring) / Float(rings) + time * speed
            let phase = phaseBase.truncatingRemainder(dividingBy: 1)
            let spread: Float = 0.34 + effectState.bass * 0.16
            let radius = shortest * (0.10 + phase * spread)
            glColor4f(0.82, 0.16 + phase * 0.74, 1.0, effectState.intensity * (1 - phase) * 0.10)
            glBegin(GLenum(GL_LINE_LOOP))
            for point in 0..<72 {
                let angle = Float(point) / 72.0 * .pi * 2.0
                glVertex2f(centerX + cos(angle) * radius, centerY + sin(angle) * radius * 0.64)
            }
            glEnd()
        }
        context.flushBuffer()
    }

    deinit {
        redrawTimer?.invalidate()
    }
}
