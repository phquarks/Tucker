import Carbon
import Combine
import Foundation

@MainActor
final class Preferences: ObservableObject {
    enum Key {
        static let automaticallyHideItems = "automaticallyHideItems"
        static let autoHideDelay = "autoHideDelay"
        static let showOnHover = "showOnHover"
        static let showWhenCrowded = "showWhenCrowded"
        static let iconStyle = "iconStyle"
        static let keyboardShortcutEnabled = "keyboardShortcutEnabled"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func registerDefaults() {
        userDefaults.register(defaults: [
            Key.automaticallyHideItems: true,
            Key.autoHideDelay: AutoHideDelay.five.rawValue,
            Key.showOnHover: false,
            Key.showWhenCrowded: false,
            Key.iconStyle: IconStyle.default.rawValue,
            Key.keyboardShortcutEnabled: true,
            Key.shortcutKeyCode: UInt32(kVK_ANSI_T),
            Key.shortcutModifiers: UInt32(controlKey | optionKey)
        ])
        objectWillChange.send()
    }

    var automaticallyHideItems: Bool {
        get { userDefaults.bool(forKey: Key.automaticallyHideItems) }
        set { set(newValue, forKey: Key.automaticallyHideItems) }
    }

    var autoHideDelayRawValue: Int {
        get { userDefaults.integer(forKey: Key.autoHideDelay) }
        set { set(newValue, forKey: Key.autoHideDelay) }
    }

    var showOnHover: Bool {
        get { userDefaults.bool(forKey: Key.showOnHover) }
        set { set(newValue, forKey: Key.showOnHover) }
    }

    var showWhenCrowded: Bool {
        get { userDefaults.bool(forKey: Key.showWhenCrowded) }
        set { set(newValue, forKey: Key.showWhenCrowded) }
    }

    var iconStyleRawValue: String {
        get { userDefaults.string(forKey: Key.iconStyle) ?? IconStyle.default.rawValue }
        set { set(newValue, forKey: Key.iconStyle) }
    }

    var keyboardShortcutEnabled: Bool {
        get { userDefaults.bool(forKey: Key.keyboardShortcutEnabled) }
        set { set(newValue, forKey: Key.keyboardShortcutEnabled) }
    }

    var shortcutKeyCode: UInt32 {
        get { UInt32(userDefaults.integer(forKey: Key.shortcutKeyCode)) }
        set { set(Int(newValue), forKey: Key.shortcutKeyCode) }
    }

    var shortcutModifiers: UInt32 {
        get { UInt32(userDefaults.integer(forKey: Key.shortcutModifiers)) }
        set { set(Int(newValue), forKey: Key.shortcutModifiers) }
    }

    private func set<T>(_ value: T, forKey key: String) {
        objectWillChange.send()
        userDefaults.set(value, forKey: key)
    }
}
