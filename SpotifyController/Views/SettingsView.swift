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

            Section("Account") {
                if auth.isAuthenticated {
                    LabeledContent("Spotify") {
                        Text("Connected")
                            .foregroundStyle(.green)
                    }
                    Button("Log Out", role: .destructive) {
                        auth.logout()
                        PlaybackManager.shared.stopPolling()
                    }
                } else {
                    LabeledContent("Spotify") {
                        Text("Not connected")
                            .foregroundStyle(.secondary)
                    }
                    Button("Log In to Spotify") {
                        auth.startAuthFlow()
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
}
