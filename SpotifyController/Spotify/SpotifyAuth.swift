import Foundation
import CryptoKit
import AppKit

@MainActor
class SpotifyAuth: ObservableObject {
    static let shared = SpotifyAuth()

    private let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    private let redirectURI = "spotifycontroller://callback"
    private let scopes = "user-read-playback-state user-modify-playback-state user-read-currently-playing"

    @Published var isAuthenticated = false

    private var codeVerifier = ""

    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "spotify_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "spotify_access_token") }
    }

    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "spotify_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "spotify_refresh_token") }
    }

    private var tokenExpiry: Date? {
        get { UserDefaults.standard.object(forKey: "spotify_token_expiry") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "spotify_token_expiry") }
    }

    private init() {
        isAuthenticated = accessToken != nil && (tokenExpiry.map { $0 > Date() } ?? false)
    }

    func startAuthFlow() {
        codeVerifier = makeCodeVerifier()
        let challenge = makeCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: scopes),
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    func handleCallback(url: URL) async {
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { return }
        await exchangeCode(code)
    }

    func getValidToken() async -> String? {
        // Still valid with 60s buffer
        if let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60), let token = accessToken {
            return token
        }
        await refreshAccessToken()
        return accessToken
    }

    func logout() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        isAuthenticated = false
    }

    // MARK: - Private

    private func exchangeCode(_ code: String) async {
        var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = encodeBody([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": codeVerifier,
        ])
        await applyToken(from: req)
    }

    private func refreshAccessToken() async {
        guard let refresh = refreshToken else {
            isAuthenticated = false
            return
        }
        var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = encodeBody([
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": clientID,
        ])
        await applyToken(from: req)
    }

    private func applyToken(from request: URLRequest) async {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let token = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            accessToken = token.accessToken
            if let r = token.refreshToken { refreshToken = r }
            tokenExpiry = Date().addingTimeInterval(TimeInterval(token.expiresIn))
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    private func encodeBody(_ params: [String: String]) -> Data? {
        params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
    }

    private func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func makeCodeChallenge(from verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
