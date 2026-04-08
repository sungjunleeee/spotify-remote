import Foundation

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

struct SpotifyPlaybackState: Codable {
    let isPlaying: Bool
    let item: SpotifyTrack?
    let progressMs: Int?
    let device: SpotifyDevice?

    enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case item
        case progressMs = "progress_ms"
        case device
    }
}

struct SpotifyDevice: Codable {
    let id: String?
    let name: String
    let type: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case isActive = "is_active"
    }
}

struct SpotifyTrack: Codable, Equatable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let durationMs: Int

    enum CodingKeys: String, CodingKey {
        case id, name, artists, album
        case durationMs = "duration_ms"
    }

    var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

struct SpotifyArtist: Codable, Equatable {
    let id: String
    let name: String
}

struct SpotifyAlbum: Codable, Equatable {
    let id: String
    let name: String
    let images: [SpotifyImage]

    var smallImageURL: URL? {
        images.sorted { ($0.width ?? 999) < ($1.width ?? 999) }.first.flatMap { URL(string: $0.url) }
    }
}

struct SpotifyImage: Codable, Equatable {
    let url: String
    let width: Int?
    let height: Int?
}

