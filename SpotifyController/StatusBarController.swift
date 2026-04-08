import AppKit
import SwiftUI
import Combine

@MainActor
class StatusBarController {
    // All three items are created once and never removed — only visibility toggles
    private var playPauseItem: NSStatusItem
    private var previousItem: NSStatusItem
    private var nextItem: NSStatusItem

    private var popover: NSPopover
    private var clickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        let nowPlayingView = NowPlayingView()
            .environmentObject(SpotifyAuth.shared)
            .environmentObject(PlaybackManager.shared)
            .environmentObject(AppSettings.shared)
        popover.contentViewController = NSHostingController(rootView: nowPlayingView)
        popover.contentSize = NSSize(width: 280, height: 200)

        // Create in reverse display order: macOS inserts each new item to the LEFT
        // of previously added ones, so create right-to-left to get [⏮] [⏸] [⏭]
        // All properties must be initialized before any self method calls.
        nextItem     = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        playPauseItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        previousItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        configure(nextItem,      symbol: "forward.fill",    action: #selector(handleNext))
        configure(playPauseItem, symbol: "moon.zzz.fill",   action: #selector(handlePlayPause))
        configure(previousItem,  symbol: "backward.fill",   action: #selector(handlePrevious))

        updateOptionalButtonVisibility()

        // Update play/pause icon when playing state or track presence changes
        Publishers.CombineLatest(
            PlaybackManager.shared.$isPlaying,
            PlaybackManager.shared.$currentTrack
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isPlaying, currentTrack in
            self?.updatePlayPauseIcon(isPlaying: isPlaying, hasTrack: currentTrack != nil)
        }
        .store(in: &cancellables)

        // Re-evaluate skip button visibility only when idle state actually flips
        PlaybackManager.shared.$currentTrack
            .map { $0 == nil }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateOptionalButtonVisibility() }
            .store(in: &cancellables)

        // Re-evaluate on settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSettingsChanged),
            name: .statusBarLayoutChanged,
            object: nil
        )
    }

    // MARK: - Setup

    private func configure(_ item: NSStatusItem, symbol: String, action: Selector) {
        guard let button = item.button else { return }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.image?.isTemplate = true
        button.action = action
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func updateOptionalButtonVisibility() {
        let isIdle = PlaybackManager.shared.currentTrack == nil
        let hideNow = AppSettings.shared.hideSkipButtonsWhenIdle && isIdle

        nextItem.isVisible     = AppSettings.shared.showNextButton && !hideNow
        previousItem.isVisible = AppSettings.shared.showPreviousButton && !hideNow
    }

    @objc private func onSettingsChanged() {
        updateOptionalButtonVisibility()
    }

    private func updatePlayPauseIcon(isPlaying: Bool, hasTrack: Bool) {
        let symbol = hasTrack ? (isPlaying ? "pause.fill" : "play.fill") : "moon.zzz.fill"
        playPauseItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        playPauseItem.button?.image?.isTemplate = true
    }

    // MARK: - Actions

    @objc private func handlePlayPause(_ sender: NSStatusBarButton) {
        if isRightClick {
            showPopover(from: sender)
        } else if PlaybackManager.shared.currentTrack != nil {
            PlaybackManager.shared.togglePlayPause()
        }
    }

    @objc private func handleNext(_ sender: NSStatusBarButton) {
        if isRightClick { showPopover(from: sender) } else { PlaybackManager.shared.skipToNext() }
    }

    @objc private func handlePrevious(_ sender: NSStatusBarButton) {
        if isRightClick { showPopover(from: sender) } else { PlaybackManager.shared.skipToPrevious() }
    }

    private var isRightClick: Bool {
        NSApp.currentEvent?.type == .rightMouseUp
    }

    // MARK: - Popover

    private func showPopover(from button: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
            return
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
