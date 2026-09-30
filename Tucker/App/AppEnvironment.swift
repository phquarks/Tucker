import AppKit
import Foundation
import os

@MainActor
final class AppEnvironment: ObservableObject {
    let preferences: Preferences
    let launchAtLoginService: LaunchAtLoginService
    let keyboardShortcutService: KeyboardShortcutService
    let displayService: DisplayService
    let menuBarController: MenuBarController

    private let logger = Logger(subsystem: "com.quarks.tucker", category: "Environment")

    init(userDefaults: UserDefaults = .standard) {
        preferences = Preferences(userDefaults: userDefaults)
        launchAtLoginService = LaunchAtLoginService()
        displayService = DisplayService()
        menuBarController = MenuBarController(preferences: preferences)
        keyboardShortcutService = KeyboardShortcutService(preferences: preferences)

        keyboardShortcutService.onToggle = { [weak menuBarController] in
            menuBarController?.toggle(source: .keyboardShortcut)
        }
        displayService.onDisplayConfigurationChanged = { [weak menuBarController] in
            menuBarController?.displayConfigurationDidChange()
        }
    }

    func start() {
        preferences.registerDefaults()
        menuBarController.start()
        keyboardShortcutService.start()
        displayService.start()
        logger.info("Environment started.")
    }

    func stop() {
        keyboardShortcutService.stop()
        displayService.stop()
        menuBarController.stop()
    }
}
