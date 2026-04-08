import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()

        if SpotifyAuth.shared.isAuthenticated {
            PlaybackManager.shared.startPolling()
        } else {
            SpotifyAuth.shared.startAuthFlow()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first, url.scheme == "spotifycontroller" else { return }
        Task {
            await SpotifyAuth.shared.handleCallback(url: url)
            if SpotifyAuth.shared.isAuthenticated {
                PlaybackManager.shared.startPolling()
            }
        }
    }
}
