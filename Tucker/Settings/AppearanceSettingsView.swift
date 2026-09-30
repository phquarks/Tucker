import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Menu bar icon", selection: Binding(
                    get: { preferences.iconStyleRawValue },
                    set: { preferences.iconStyleRawValue = $0 }
                )) {
                    ForEach(IconStyle.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
