// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpotifyController",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "SpotifyController",
            path: "SpotifyController",
            exclude: ["Info.plist"]
        )
    ]
)
