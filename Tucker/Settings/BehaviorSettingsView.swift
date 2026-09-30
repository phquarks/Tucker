import SwiftUI

struct BehaviorSettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Section("Behavior") {
            Toggle("Show hidden items on hover", isOn: Binding(
                get: { preferences.showOnHover },
                set: { preferences.showOnHover = $0 }
            ))

            Toggle("Show when menu bar is crowded", isOn: Binding(
                get: { preferences.showWhenCrowded },
                set: { preferences.showWhenCrowded = $0 }
            ))
            .disabled(true)

            Text("Crowded menu bar detection is unavailable on this version of macOS.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
