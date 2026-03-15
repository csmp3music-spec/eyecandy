import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    let renderer: FeedbackRenderer
    let qualityScale: Float

    func makeNSView(context: Context) -> ResponsiveMetalView {
        let view = ResponsiveMetalView(frame: .zero, device: renderer.device)
        view.delegate = renderer
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        view.sizeUpdateHandler = { metalView in
            renderer.updateDrawableSize(for: metalView, qualityScale: qualityScale)
        }
        renderer.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: ResponsiveMetalView, context: Context) {
        nsView.sizeUpdateHandler = { metalView in
            renderer.updateDrawableSize(for: metalView, qualityScale: qualityScale)
        }
        renderer.updateDrawableSize(for: nsView, qualityScale: qualityScale)
    }
}

final class ResponsiveMetalView: MTKView {
    var sizeUpdateHandler: ((ResponsiveMetalView) -> Void)?

    override func layout() {
        super.layout()
        sizeUpdateHandler?(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        sizeUpdateHandler?(self)
    }
}
