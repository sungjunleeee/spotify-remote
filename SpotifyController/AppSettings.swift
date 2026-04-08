import Foundation
import ServiceManagement

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showPreviousButton: Bool {
        didSet {
            UserDefaults.standard.set(showPreviousButton, forKey: "show_previous_button")
            NotificationCenter.default.post(name: .statusBarLayoutChanged, object: nil)
        }
    }

    @Published var showNextButton: Bool {
        didSet {
            UserDefaults.standard.set(showNextButton, forKey: "show_next_button")
            NotificationCenter.default.post(name: .statusBarLayoutChanged, object: nil)
        }
    }

    @Published var hideSkipButtonsWhenIdle: Bool {
        didSet {
            UserDefaults.standard.set(hideSkipButtonsWhenIdle, forKey: "hide_skip_when_idle")
            NotificationCenter.default.post(name: .statusBarLayoutChanged, object: nil)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = !launchAtLogin // revert on failure
            }
        }
    }

    private init() {
        showPreviousButton = UserDefaults.standard.object(forKey: "show_previous_button") as? Bool ?? false
        showNextButton = UserDefaults.standard.object(forKey: "show_next_button") as? Bool ?? true
        hideSkipButtonsWhenIdle = UserDefaults.standard.object(forKey: "hide_skip_when_idle") as? Bool ?? false
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

extension Notification.Name {
    static let statusBarLayoutChanged = Notification.Name("statusBarLayoutChanged")
}
