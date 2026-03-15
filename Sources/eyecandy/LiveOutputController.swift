import AppKit
import SwiftUI

@MainActor
final class LiveOutputController: NSObject, NSWindowDelegate {
    private weak var model: AppModel?
    private var window: NSWindow?

    init(model: AppModel) {
        self.model = model
    }

    func present() -> String {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return window.screen?.localizedName ?? "live display"
        }

        guard let model else {
            return "live display"
        }

        let targetScreen = NSScreen.screens.first(where: { $0 != NSScreen.main }) ?? NSScreen.main
        let frame = targetScreen?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: targetScreen
        )

        window.delegate = self
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = NSHostingView(rootView: LiveOutputScene(model: model))
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(nil)

        self.window = window
        return targetScreen?.localizedName ?? "main display"
    }

    func close() {
        window?.close()
        window = nil
    }

    func windowWillClose(_ notification: Notification) {
        model?.liveOutputEnabled = false
        window = nil
    }
}

private struct LiveOutputScene: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalView(renderer: model.liveRenderer, qualityScale: max(model.qualityScale, 1.0))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 5) {
                Text("LIVE OUTPUT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
                Text(model.selectedPreset.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(20)
        }
        .background(Color.black)
    }
}
