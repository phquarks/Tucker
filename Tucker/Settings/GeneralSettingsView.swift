import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var launchAtLoginService: LaunchAtLoginService

    var body: some View {
        Group {
            Section("General") {
                Toggle("Launch Tucker at login", isOn: Binding(
                    get: { launchAtLoginService.isEnabled },
                    set: { enabled in
                        do {
                            try launchAtLoginService.setEnabled(enabled)
                        } catch {
                            launchAtLoginService.lastErrorMessage = error.localizedDescription
                        }
                    }
                ))

                Toggle("Automatically hide items", isOn: Binding(
                    get: { preferences.automaticallyHideItems },
                    set: { preferences.automaticallyHideItems = $0 }
                ))

                Picker("Hide after", selection: Binding(
                    get: { preferences.autoHideDelayRawValue },
                    set: { preferences.autoHideDelayRawValue = $0 }
                )) {
                    ForEach(AutoHideDelay.allCases) { delay in
                        Text(delay.title).tag(delay.rawValue)
                    }
                }
            }

            if let message = launchAtLoginService.lastErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if launchAtLoginService.statusDescription == "Requires Approval" {
                Button("Open Login Items Settings") {
                    launchAtLoginService.openSystemSettings()
                }
            }
        }
        .onAppear { launchAtLoginService.refreshStatus() }
    }
}
