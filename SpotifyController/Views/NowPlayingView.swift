import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var auth: SpotifyAuth
    @EnvironmentObject var playback: PlaybackManager
    @EnvironmentObject var settings: AppSettings

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .padding(20)

            settingsMenu
                .padding(10)
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !auth.isAuthenticated {
            loginPrompt
        } else if let track = playback.currentTrack {
            trackInfo(track)
        } else {
            noPlaybackView
        }
    }

    private var loginPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Setup required")
                .font(.headline)
            GlassEffectContainer {
                Button("Open Setup") {
                    NotificationCenter.default.post(name: .showSetupWindow, object: nil)
                }
                .glassEffect(.regular.tint(.green))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var noPlaybackView: some View {
        VStack(spacing: 8) {
            Image(systemName: "speaker.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Nothing playing")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func trackInfo(_ track: SpotifyTrack) -> some View {
        HStack(spacing: 14) {
            albumArt(track)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artistNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let device = playback.deviceName {
                    Label(device, systemImage: "hifispeaker")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func albumArt(_ track: SpotifyTrack) -> some View {
        Group {
            if let url = track.album.smallImageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.2)
                }
            } else {
                Color.secondary.opacity(0.2)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Settings Menu

    private var settingsMenu: some View {
        Menu {
            Button("Settings…") {
                openSettings()
            }
            Divider()
            Button("Quit SpotifyController") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
