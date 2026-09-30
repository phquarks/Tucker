import AppKit
@preconcurrency import ApplicationServices

@MainActor
final class HiddenItemsController {
    private let native = TKNativeVisibility()
    private var separator: NSStatusItem?
    private var operation = 0
    private var pending: Task<Void, Never>?
    private var timeout: Task<Void, Never>?
    private var didRequestPermission = false

    init() {
        if #available(macOS 27, *) { return }
        let item = NSStatusBar.system.statusItem(withLength: 20)
        item.autosaveName = "com.quarks.tucker.boundary-spacer"
        item.isVisible = true
        item.button?.title = "|"
        separator = item
    }

    func collapse(anchor: NSStatusBarButton?, requestPermission: Bool, completion: @escaping @MainActor @Sendable (String?) -> Void) {
        restore()
        if #available(macOS 27, *) {
            guard Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL.path == "/Applications/Tucker.app" else {
                completion("Run Tucker from /Applications/Tucker.app. The Xcode Run scheme installs it there before launch; a DerivedData copy can hide its own icon.")
                return
            }
            guard TKNativeVisibility.available else {
                completion("Menu bar hiding is unavailable on this macOS build.")
                return
            }
            guard AXIsProcessTrusted() else {
                if requestPermission && !didRequestPermission {
                    didRequestPermission = true
                    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                    _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
                }
                completion("Allow Tucker in System Settings > Privacy & Security > Accessibility, then try again.")
                return
            }
            guard let anchor, let window = anchor.window else {
                completion("Tucker's menu bar position is not available yet.")
                return
            }
            let frame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
            guard !frame.isEmpty else {
                completion("Tucker's menu bar position is not available yet.")
                return
            }
            let rightToLeft = NSApp.userInterfaceLayoutDirection == .rightToLeft
            let apps = NSWorkspace.shared.runningApplications.compactMap { app -> MenuBarApplication? in
                guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                      let bundle = app.bundleIdentifier, app.bundleURL?.pathExtension == "app" else { return nil }
                return MenuBarApplication(pid: app.processIdentifier, bundle: bundle)
            }
            let revision = operation
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(8)) } catch { return }
                guard let self, self.operation == revision else { return }
                self.restore()
                completion("The menu bar service did not respond. All icons have been restored; try again.")
            }
            pending = Task { [weak self] in
                let hidden = await Task.detached(priority: .userInitiated) {
                    MenuBarInventory.hiddenBundles(apps: apps, boundary: frame.midX, rightToLeft: rightToLeft)
                }.value
                guard let self, !Task.isCancelled, self.operation == revision else { return }
                guard !hidden.isEmpty else {
                    self.timeout?.cancel()
                    completion("No icons are in the hidden section. Hold Command and drag an app icon to the left of Tucker (right in a right-to-left menu bar).")
                    return
                }
                // Unknown or unreadable apps remain visible.
                var allowed = Set(apps.map(\.bundle)).subtracting(hidden)
                allowed.insert(Bundle.main.bundleIdentifier ?? "com.quarks.tucker")
                self.native.hideExceptBundles(Array(allowed)) { [weak self] error in
                    Task { @MainActor in
                        guard let self, self.operation == revision else { return }
                        self.timeout?.cancel()
                        completion(error)
                    }
                }
            }
        } else {
            let widest = NSScreen.screens.map(\.frame.width).max() ?? 1920
            separator?.length = min(10_000, max(500, widest * 2))
            completion(nil)
        }
    }

    func restore() {
        operation += 1
        timeout?.cancel()
        timeout = nil
        pending?.cancel()
        pending = nil
        native.restore()
        separator?.length = 20
    }

    func remove() {
        restore()
        if let separator { NSStatusBar.system.removeStatusItem(separator) }
        separator = nil
    }
}

private struct MenuBarApplication: Sendable {
    let pid: pid_t
    let bundle: String
}

enum HiddenItemSelection {
    static func hiddenBundles(positions: [(bundle: String, x: CGFloat?)], boundary: CGFloat, rightToLeft: Bool) -> Set<String> {
        var hidden = Set<String>()
        var visible = Set<String>()
        for item in positions {
            guard let x = item.x, x.isFinite else {
                visible.insert(item.bundle)
                continue
            }
            if rightToLeft ? x > boundary : x < boundary {
                hidden.insert(item.bundle)
            } else {
                visible.insert(item.bundle)
            }
        }
        return hidden.subtracting(visible)
    }
}

private enum MenuBarInventory {
    static func hiddenBundles(apps: [MenuBarApplication], boundary: CGFloat, rightToLeft: Bool) -> Set<String> {
        var positions: [(bundle: String, x: CGFloat?)] = []
        for app in apps {
            let application = AXUIElementCreateApplication(app.pid)
            AXUIElementSetMessagingTimeout(application, 0.15)
            guard let barValue = attribute(kAXExtrasMenuBarAttribute, of: application),
                  CFGetTypeID(barValue) == AXUIElementGetTypeID() else {
                positions.append((app.bundle, nil))
                continue
            }
            let bar = unsafeDowncast(barValue, to: AXUIElement.self)
            guard let children = attribute(kAXChildrenAttribute, of: bar) as? [AXUIElement] else {
                positions.append((app.bundle, nil))
                continue
            }
            for child in children {
                guard let value = attribute(kAXPositionAttribute, of: child),
                      CFGetTypeID(value) == AXValueGetTypeID() else {
                    positions.append((app.bundle, nil))
                    continue
                }
                let position = unsafeDowncast(value, to: AXValue.self)
                var point = CGPoint.zero
                guard AXValueGetValue(position, .cgPoint, &point), point.x.isFinite else {
                    positions.append((app.bundle, nil))
                    continue
                }
                positions.append((app.bundle, point.x))
            }
        }
        // Visibility is per app; an icon on the visible side keeps its app visible.
        return HiddenItemSelection.hiddenBundles(positions: positions, boundary: boundary, rightToLeft: rightToLeft)
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
}
