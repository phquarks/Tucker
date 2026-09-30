import AppKit

@MainActor
final class StatusItemController: NSObject {
    let item: NSStatusItem
    private let onPrimaryClick: () -> Void
    private let onSecondaryClick: () -> Void

    init(onPrimaryClick: @escaping () -> Void, onSecondaryClick: @escaping () -> Void) {
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.onPrimaryClick = onPrimaryClick
        self.onSecondaryClick = onSecondaryClick
        super.init()

        item.autosaveName = "com.quarks.tucker.toggle"
        item.isVisible = true
        item.behavior = []
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.toolTip = "Tucker"
    }

    func setIconStyle(_ style: IconStyle, expanded: Bool) {
        let symbolName = expanded ? "rectangle.expand.vertical" : style.symbolName
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Tucker")
            ?? NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "Tucker")
        image?.isTemplate = true
        item.button?.image = image
        item.button?.imagePosition = .imageOnly
    }

    func remove() {
        NSStatusBar.system.removeStatusItem(item)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            onPrimaryClick()
            return
        }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            onSecondaryClick()
        } else {
            onPrimaryClick()
        }
    }
}
