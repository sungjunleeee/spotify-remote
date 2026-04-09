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
        // Skip buttons avoid isVisible toggling — confirmed Apple bug (FB9052637)
        // resets saved position to far left. Instead we toggle length + image + action.
        nextItem     = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        nextItem.autosaveName = "com.spotifycontroller.next"
        playPauseItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        playPauseItem.autosaveName = "com.spotifycontroller.playpause"
        previousItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        previousItem.autosaveName = "com.spotifycontroller.previous"

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
        let shrinkWhenIdle = AppSettings.shared.hideSkipButtonsWhenIdle && isIdle

        applyVisibility(
            item: nextItem,
            symbol: "forward.fill",
            action: #selector(handleNext),
            enabled: AppSettings.shared.showNextButton,
            shrink: shrinkWhenIdle
        )
        applyVisibility(
            item: previousItem,
            symbol: "backward.fill",
            action: #selector(handlePrevious),
            enabled: AppSettings.shared.showPreviousButton,
            shrink: shrinkWhenIdle
        )
    }

    // When a button is opted out entirely, hide it via isVisible so it takes no space.
    // When it's opted in but idle-hiding is active, use the shrink trick instead —
    // toggling isVisible is a confirmed Apple bug (FB9052637) that resets item position
    // to the far left on re-show, so we avoid it for the frequently-toggled idle case.
    private func applyVisibility(
        item: NSStatusItem,
        symbol: String,
        action: Selector,
        enabled: Bool,
        shrink: Bool
    ) {
        guard enabled else {
            item.isVisible = false
            return
        }
        item.isVisible = true
        if shrink {
            item.length = 0.0001
            item.button?.image = nil
            item.button?.action = nil
            item.button?.isEnabled = false
        } else {
            item.length = NSStatusItem.squareLength
            let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            img?.isTemplate = true
            item.button?.image = img
            item.button?.action = action
            item.button?.isEnabled = true
        }
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
