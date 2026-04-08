import Foundation
import Combine

@MainActor
class PlaybackManager: ObservableObject {
    static let shared = PlaybackManager()

    @Published var isPlaying = false
    @Published var currentTrack: SpotifyTrack?
    @Published var progressMs: Int = 0
    @Published var deviceName: String?

    private var pollingTask: Task<Void, Never>?

    private init() {}

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchState()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPlaying = false
        currentTrack = nil
    }

    func togglePlayPause() {
        let wasPlaying = isPlaying
        isPlaying.toggle() // Optimistic update
        Task {
            do {
                try await SpotifyAPI.shared.togglePlayPause(isPlaying: wasPlaying)
            } catch {
                isPlaying = wasPlaying // Revert on failure
            }
        }
    }

    func skipToNext() {
        Task {
            try? await SpotifyAPI.shared.skipToNext()
            try? await Task.sleep(for: .milliseconds(500))
            await fetchState()
        }
    }

    func skipToPrevious() {
        Task {
            try? await SpotifyAPI.shared.skipToPrevious()
            try? await Task.sleep(for: .milliseconds(500))
            await fetchState()
        }
    }

    // MARK: - Private

    private func fetchState() async {
        guard let state = try? await SpotifyAPI.shared.getPlaybackState() else { return }
        isPlaying = state.isPlaying
        currentTrack = state.item
        progressMs = state.progressMs ?? 0
        deviceName = state.device?.name
    }
}
