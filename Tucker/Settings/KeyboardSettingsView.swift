import AppKit
import Carbon
import SwiftUI

struct KeyboardSettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var keyboardShortcutService: KeyboardShortcutService
    @StateObject private var recorder = ShortcutRecorderModel()

    var body: some View {
        Group {
            Section("Keyboard") {
                Toggle("Global shortcut", isOn: Binding(
                    get: { preferences.keyboardShortcutEnabled },
                    set: { enabled in
                        preferences.keyboardShortcutEnabled = enabled
                        keyboardShortcutService.refreshRegistration()
                    }
                ))

                HStack {
                    Text("Shortcut")
                    Spacer()
                    Button(recorder.isRecording ? "Press shortcut" : shortcutDescription) {
                        recorder.beginRecording(preferences: preferences, keyboardShortcutService: keyboardShortcutService)
                    }
                    .font(.system(.body, design: .monospaced))
                }

                Text("Tucker uses Carbon's public RegisterEventHotKey API, which works globally without Accessibility permission.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let message = keyboardShortcutService.lastErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear { recorder.stopRecording() }
    }

    private var shortcutDescription: String {
        "\(modifierDescription(preferences.shortcutModifiers))\(keyDescription(preferences.shortcutKeyCode))"
    }

}

@MainActor
private final class ShortcutRecorderModel: ObservableObject {
    @Published var isRecording = false
    private var eventMonitor: Any?

    func beginRecording(preferences: Preferences, keyboardShortcutService: KeyboardShortcutService) {
        stopRecording()
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak preferences, weak keyboardShortcutService] event in
            let modifiers = carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                NSSound.beep()
                return nil
            }

            preferences?.shortcutKeyCode = UInt32(event.keyCode)
            preferences?.shortcutModifiers = modifiers
            keyboardShortcutService?.refreshRegistration()
            self?.stopRecording()
            return nil
        }
    }

    func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        isRecording = false
    }
}

private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var modifiers: UInt32 = 0
    if flags.contains(.control) { modifiers |= UInt32(controlKey) }
    if flags.contains(.option) { modifiers |= UInt32(optionKey) }
    if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
    if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
    return modifiers
}

private func modifierDescription(_ modifiers: UInt32) -> String {
    var text = ""
    if modifiers & UInt32(controlKey) != 0 { text += "⌃" }
    if modifiers & UInt32(optionKey) != 0 { text += "⌥" }
    if modifiers & UInt32(shiftKey) != 0 { text += "⇧" }
    if modifiers & UInt32(cmdKey) != 0 { text += "⌘" }
    return text
}

private func keyDescription(_ keyCode: UInt32) -> String {
    let keys: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_Space): "Space", UInt32(kVK_Escape): "Esc"
    ]
    return keys[keyCode] ?? "Key \(keyCode)"
}
