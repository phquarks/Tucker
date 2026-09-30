import Combine
import Foundation
import ServiceManagement
import os

@MainActor
final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var statusDescription = "Unknown"
    @Published var lastErrorMessage: String?

    private let logger = Logger(subsystem: "com.quarks.tucker", category: "LaunchAtLogin")

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        statusDescription = description(for: SMAppService.mainApp.status)
    }

    func setEnabled(_ enabled: Bool) throws {
        lastErrorMessage = nil
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
            refreshStatus()
        } catch {
            refreshStatus()
            logger.error("SMAppService failed: \(error.localizedDescription)")
            throw error
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func description(for status: SMAppService.Status) -> String {
        switch status {
        case .notRegistered: "Not Registered"
        case .enabled: "Enabled"
        case .requiresApproval: "Requires Approval"
        case .notFound: "Not Found"
        @unknown default: "Unknown"
        }
    }
}
