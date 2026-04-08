import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var setupWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowSetupWindow),
            name: .showSetupWindow,
            object: nil
        )

        if !AppSettings.shared.isSetupComplete || !SpotifyAuth.shared.isAuthenticated {
            showSetupWindow()
        } else {
            PlaybackManager.shared.startPolling()
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

    @objc private func handleShowSetupWindow() {
        showSetupWindow()
    }

    func showSetupWindow() {
        if setupWindow == nil {
            let view = SetupView { [weak self] in
                self?.setupWindow?.close()
                self?.setupWindow = nil
            }
            let hosting = NSHostingView(rootView: view)
            hosting.sizingOptions = .preferredContentSize

            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "SpotifyRemote Setup"
            window.contentView = hosting
            window.center()
            window.isReleasedWhenClosed = false
            setupWindow = window
        }

        setupWindow?.level = .floating
        setupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Drop back to normal level so it doesn't permanently float above everything
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupWindow?.level = .normal
        }
    }
}
