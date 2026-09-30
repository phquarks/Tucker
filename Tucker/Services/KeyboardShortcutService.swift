import Carbon
import Combine
import Foundation
import os

@MainActor
final class KeyboardShortcutService: ObservableObject {
    @Published var lastErrorMessage: String?

    var onToggle: (() -> Void)?

    private let logger = Logger(subsystem: "com.quarks.tucker", category: "KeyboardShortcut")
    private let preferences: Preferences
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(UInt32(bigEndian: 0x5455434B)), id: 1)

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func start() {
        installHandlerIfNeeded()
        refreshRegistration()
    }

    func stop() {
        unregisterHotKey()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    func refreshRegistration() {
        unregisterHotKey()
        guard preferences.keyboardShortcutEnabled else { return }

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            preferences.shortcutKeyCode,
            preferences.shortcutModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )

        if status == noErr {
            hotKeyRef = ref
            lastErrorMessage = nil
        } else {
            lastErrorMessage = "Could not register global shortcut (OSStatus \(status))."
            logger.error("RegisterEventHotKey failed: \(status)")
        }
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var hotKeyID = EventHotKeyID()
                let error = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard error == noErr, hotKeyID.id == 1 else { return noErr }
                let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    service.onToggle?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        if status != noErr {
            lastErrorMessage = "Could not install hotkey handler (OSStatus \(status))."
            logger.error("InstallEventHandler failed: \(status)")
        }
    }
}
