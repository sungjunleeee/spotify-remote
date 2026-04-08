import SwiftUI
import AppKit

struct SetupView: View {
    @State private var clientIDInput = ""
    @State private var copied = false
    @State private var awaitingAuth = false
    @State private var isConnected = false
    @ObservedObject private var auth = SpotifyAuth.shared
    var onComplete: () -> Void

    private let redirectURI = "spotifycontroller://callback"

    var body: some View {
        Group {
            if isConnected {
                successView
            } else {
                setupForm
            }
        }
        .padding(28)
        .frame(width: 460)
        .onChange(of: auth.isAuthenticated) { _, authenticated in
            guard authenticated && awaitingAuth else { return }
            isConnected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 56))
            Text("Successfully connected!")
                .font(.title2.bold())
            Text("You're all set. SpotifyRemote is ready to use.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Setup form

    private var setupForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("SpotifyRemote Setup")
                .font(.title2.bold())

            // Step 1
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 1 — Create a Spotify Developer App")
                    .font(.headline)

                instructionRow(number: "1") {
                    Text("Go to **developer.spotify.com/dashboard**")
                }
                action: {
                    if let url = URL(string: "https://developer.spotify.com/dashboard") {
                        NSWorkspace.shared.open(url)
                    }
                }
                actionLabel: { Text("Open ↗") }

                plainRow(number: "2") { Text("Click **Create App**") }

                instructionRow(number: "3") {
                    Text("Set **Redirect URI** to: ")
                }
                action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(redirectURI, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                }
                actionLabel: {
                    Text(copied ? "Copied ✓" : "Copy")
                }
                extra: {
                    Text(redirectURI)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                plainRow(number: "4") { Text("Enable **Web API** and save") }
            }

            Divider()

            // Step 2
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 2 — Enter your Client ID")
                    .font(.headline)

                Text("Paste the Client ID from your Spotify app dashboard:")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                TextField("Client ID", text: $clientIDInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: clientIDInput) { _, new in
                        let cleaned = new.components(separatedBy: .newlines).joined()
                        if cleaned != new { clientIDInput = cleaned }
                    }
            }

            // Connect button
            HStack {
                Spacer()
                Button {
                    AppSettings.shared.clientID = clientIDInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    awaitingAuth = true
                    SpotifyAuth.shared.startAuthFlow()
                } label: {
                    Text("Connect to Spotify →")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(clientIDInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Row helpers

    @ViewBuilder
    private func instructionRow<Label: View, ActionLabel: View>(
        number: String,
        @ViewBuilder label: () -> Label,
        action: @escaping () -> Void,
        @ViewBuilder actionLabel: () -> ActionLabel
    ) -> some View {
        instructionRow(number: number, label: label, action: action, actionLabel: actionLabel, extra: { EmptyView() })
    }

    @ViewBuilder
    private func instructionRow<Label: View, ActionLabel: View, Extra: View>(
        number: String,
        @ViewBuilder label: () -> Label,
        action: @escaping () -> Void,
        @ViewBuilder actionLabel: () -> ActionLabel,
        @ViewBuilder extra: () -> Extra
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(number).")
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .trailing)
                label()
                Spacer()
                Button(action: action) { actionLabel() }
                    .buttonStyle(.borderless)
                    .font(.subheadline)
            }
            if Extra.self != EmptyView.self {
                HStack {
                    Spacer().frame(width: 24)
                    extra()
                }
            }
        }
    }

    @ViewBuilder
    private func plainRow<Label: View>(number: String, @ViewBuilder label: () -> Label) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(number).")
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            label()
        }
    }
}
