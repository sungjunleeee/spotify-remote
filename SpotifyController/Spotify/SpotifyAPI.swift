import Foundation

enum SpotifyAPIError: Error {
    case noActiveDevice
}

class SpotifyAPI {
    nonisolated(unsafe) static let shared = SpotifyAPI()
    private init() {}

    /// Throws `SpotifyAPIError.noActiveDevice` when Spotify has no active player (204).
    /// Returns `nil` on auth/decode failure. Throws network errors.
    func getPlaybackState() async throws -> SpotifyPlaybackState? {
        guard let token = await SpotifyAuth.shared.getValidToken() else { return nil }

        var req = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 204 { throw SpotifyAPIError.noActiveDevice }
        if status == 401 { await SpotifyAuth.shared.logout(); return nil }

        return try? JSONDecoder().decode(SpotifyPlaybackState.self, from: data)
    }

    func togglePlayPause(isPlaying: Bool) async throws {
        let path = isPlaying ? "/me/player/pause" : "/me/player/play"
        _ = try await request("PUT", path)
    }

    func skipToNext() async throws {
        _ = try await request("POST", "/me/player/next")
    }

    func skipToPrevious() async throws {
        _ = try await request("POST", "/me/player/previous")
    }

    // MARK: - Private

    private func request(_ method: String, _ path: String) async throws -> Data? {
        guard let token = await SpotifyAuth.shared.getValidToken() else { return nil }

        var req = URLRequest(url: URL(string: "https://api.spotify.com/v1\(path)")!)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 204 { return nil }
        if status == 401 {
            await SpotifyAuth.shared.logout()
            return nil
        }
        return data
    }
}
