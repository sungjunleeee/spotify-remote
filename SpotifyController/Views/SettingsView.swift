import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var auth: SpotifyAuth

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Status Bar Buttons") {
                Toggle("Show Previous Track button", isOn: $settings.showPreviousButton)
                Toggle("Show Next Track button", isOn: $settings.showNextButton)
                Toggle("Hide skip buttons when nothing is playing", isOn: $settings.hideSkipButtonsWhenIdle)
            }

            Section("Spotify") {
                if auth.isAuthenticated {
                    LabeledContent("Client ID") {
                        Text(truncated(settings.clientID))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Status") {
                        Text("Connected").foregroundStyle(.green)
                    }
                    Button("Reset Setup", role: .destructive) {
                        auth.unauthorize()
                    }
                } else if settings.isSetupComplete {
                    LabeledContent("Client ID") {
                        Text(truncated(settings.clientID))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Button("Reset Setup", role: .destructive) { auth.unauthorize() }
                } else {
                    Text("Not set up").foregroundStyle(.secondary)
                    Button("Run Setup…") {
                        NotificationCenter.default.post(name: .showSetupWindow, object: nil)
                    }
                }
            }

            Section("App") {
                Button("Quit SpotifyController", role: .destructive) {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding()
    }

    private func truncated(_ id: String) -> String {
        guard id.count > 12 else { return id }
        return String(id.prefix(8)) + "…" + String(id.suffix(4))
    }
}
