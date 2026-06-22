import SwiftUI
import BlipKit

@main
struct BlipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("enabled") private var enabled = true

    var body: some Scene {
        MenuBarExtra("Blip", systemImage: "checkmark.circle.fill") {
            Toggle("Show copy confirmations", isOn: $enabled)
            SettingsLink { Text("Settings…") }
                .keyboardShortcut(",")
            Divider()
            Button("Quit Blip") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings { SettingsView() }
    }
}

/// Composition root: owns the watcher, the poll timer, and the notch controller.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var watcher: ClipboardWatcher?
    private var controller: NotchController?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = NotchController()
        self.controller = controller

        let watcher = ClipboardWatcher(pasteboard: SystemPasteboard())
        watcher.onEvent = { event in
            guard UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true else { return }
            controller.show(event)
        }
        self.watcher = watcher

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.watcher?.poll() }
        }
    }
}
