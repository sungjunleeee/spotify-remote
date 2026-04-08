# spotify-remote

A minimal macOS menu bar app to control Spotify — including playback on remote devices via Spotify Connect — without opening the Spotify app.

[![GitHub release](https://img.shields.io/github/v/release/sungjunleeee/spotify-remote)](https://github.com/sungjunleeee/spotify-remote/releases/latest)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-black)](https://www.apple.com/macos/)

---

## Requirements

- macOS 26 or later
- Spotify Premium account

---

## Download & Install

**[⬇ Download latest release](https://github.com/sungjunleeee/spotify-remote/releases/latest/download/SpotifyRemote-0.2.0.dmg)**

1. Open the `.dmg` file
2. Drag **SpotifyRemote** into your Applications folder
3. Double-click the app — macOS will block it on the first launch
4. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**

---

## Usage

The app lives in your menu bar. No Dock icon.

| Action | Result |
|---|---|
| **Left-click** play/pause | Toggle playback |
| **Left-click** ⏮ / ⏭ | Skip tracks |
| **Right-click** any button | Open Now Playing popup |
| Gear icon in popup | Settings, quit |

When nothing is playing, the menu bar shows a `zzz` icon — left-click is disabled until playback starts.

---

## Developer Setup

### 1. Clone & build

```bash
git clone https://github.com/sungjunleeee/spotify-remote.git
cd spotify-remote
make run
```

### 2. Spotify API credentials

On first launch, a setup window walks you through:

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard) → **Create app**
2. Set **Redirect URI** to `spotifycontroller://callback`
3. Enable **Web API**
4. Paste your **Client ID** into the setup window and click **Connect to Spotify**

No source code changes needed — the client ID is saved in UserDefaults.

### 3. Available make targets

| Command | Description |
|---|---|
| `make run` | Build and launch |
| `make build` | Build only |
| `make dmg` | Create distributable DMG |
| `make clean` | Remove build artifacts |

---

## Known Issues

- **Status bar icon positions reset on relaunch** — The previous/next track buttons may reappear in a different position each time the app launches. macOS only persists icon positions for apps distributed via the Mac App Store.

---

## Releasing a new version (maintainers)

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build and upload the DMG to the [Releases](https://github.com/sungjunleeee/spotify-remote/releases) page.

---

## License

MIT
