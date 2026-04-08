import SwiftUI

@main
struct SpotifyControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(SpotifyAuth.shared)
                .environmentObject(AppSettings.shared)
        }
    }
}
