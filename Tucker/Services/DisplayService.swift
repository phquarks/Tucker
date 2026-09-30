import AppKit
import Combine
import Foundation
import os

@MainActor
final class DisplayService {
    var onDisplayConfigurationChanged: (() -> Void)?

    private let logger = Logger(subsystem: "com.quarks.tucker", category: "Display")
    private var tokens: [NSObjectProtocol] = []

    func start() {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleDisplayChange() }
        })

        tokens.append(center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleDisplayChange() }
        })

        tokens.append(center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleDisplayChange() }
        })
    }

    func stop() {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
        tokens.removeAll()
    }

    private func handleDisplayChange() {
        logger.info("Observed display or screen state change.")
        onDisplayConfigurationChanged?()
    }
}
