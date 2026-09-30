import SwiftUI

struct SettingsView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Form {
            GeneralSettingsView(preferences: environment.preferences, launchAtLoginService: environment.launchAtLoginService)
            BehaviorSettingsView(preferences: environment.preferences)
            KeyboardSettingsView(preferences: environment.preferences, keyboardShortcutService: environment.keyboardShortcutService)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(
            minWidth: 460,
            idealWidth: 580,
            maxWidth: .infinity,
            minHeight: 440,
            idealHeight: 560,
            maxHeight: .infinity
        )
    }
}
