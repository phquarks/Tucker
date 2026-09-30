import SwiftUI

@main
struct TuckerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(environment: appDelegate.environment)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Tucker") {
                    appDelegate.showAbout()
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
