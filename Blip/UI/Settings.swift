import SwiftUI

/// A small, native settings window (Cmd-,). Apple-minimal.
struct SettingsView: View {
    @AppStorage("enabled") private var enabled = true
    @AppStorage("duration") private var duration = 2.6
    @AppStorage("soundEnabled") private var soundEnabled = false
    @AppStorage("showPreview") private var showPreview = true
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section {
                Toggle("Show copy confirmations", isOn: $enabled)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, value in LoginItem.setEnabled(value) }
            }

            Section("Appearance") {
                Toggle("Show a preview of copied text", isOn: $showPreview)
                Toggle("Play a sound", isOn: $soundEnabled)
                LabeledContent("On screen for") {
                    Slider(value: $duration, in: 1.0...6.0, step: 0.2) { Text("Duration") }
                        .frame(width: 180)
                    Text("\(duration, specifier: "%.1f")s").monospacedDigit().foregroundStyle(.secondary)
                }
            }

            Section {
                Label(
                    "Blip is local-only. It never stores your clipboard, never sends anything over the network, and shows \u{201C}hidden\u{201D} for password-manager copies.",
                    systemImage: "lock.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 360)
    }
}
