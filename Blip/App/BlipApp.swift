import SwiftUI
import BlipKit

/// Entry point. Blip is a menu-bar accessory; the real surface is a notch pill
/// driven from the menu bar (wired up in later tasks). For now, a minimal
/// MenuBarExtra proves the app builds and runs.
@main
struct BlipApp: App {
    var body: some Scene {
        MenuBarExtra("Blip", systemImage: "checkmark.circle") {
            Text("Blip \(BlipKit.version)")
            Divider()
            Button("Quit Blip") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
