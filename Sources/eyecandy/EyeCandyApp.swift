import SwiftUI

@main
struct EyeCandyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1180, minHeight: 760)
        }
        .defaultSize(width: 1580, height: 960)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
