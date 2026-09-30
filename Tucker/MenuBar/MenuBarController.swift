import AppKit
import Combine
import os

@MainActor
final class MenuBarController {
    private let logger = Logger(subsystem: "com.quarks.tucker", category: "MenuBar")
    private let preferences: Preferences
    private let hoverController = HoverController()
    private var hiddenItemsController: HiddenItemsController?
    private var isCollapsing = false
    private var autoHideSuspended = true
    private var lastError: String?
    private var statusItemController: StatusItemController?
    private var cancellables = Set<AnyCancellable>()
    private var autoHideTimer: Timer?

    private(set) var state: MenuBarVisibilityState = .expanded

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func start() {
        let controller = StatusItemController(
            onPrimaryClick: { [weak self] in self?.toggle(source: .click) },
            onSecondaryClick: { [weak self] in self?.showContextMenu() }
        )
        statusItemController = controller
        hiddenItemsController = HiddenItemsController()
        hoverController.attach(to: controller.item.button)
        hoverController.onEntered = { [weak self] in self?.hoverEntered() }
        hoverController.onExited = { [weak self] in self?.hoverExited() }

        observePreferences()
        applyState(source: nil)
    }

    func stop() {
        cancelAutoHide()
        hoverController.detach()
        hiddenItemsController?.remove()
        isCollapsing = false
        statusItemController?.remove()
    }

    func toggle(source: ToggleSource) {
        if state == .collapsed || isCollapsing {
            if source == .keyboardShortcut {
                recover()
            } else {
                expand(source: source)
            }
        } else {
            collapse(source: source)
        }
    }

    func expand(source: ToggleSource) {
        cancelAutoHide()
        hiddenItemsController?.restore()
        isCollapsing = false
        lastError = nil
        state = .expanded
        applyState(source: source)
    }

    func recover() {
        autoHideSuspended = true
        expand(source: .menu)
        statusItemController?.item.isVisible = true
    }

    func collapse(source: ToggleSource) {
        cancelAutoHide()
        guard state != .collapsed, !isCollapsing else { return }
        isCollapsing = true
        let manual = source == .click || source == .menu || source == .keyboardShortcut
        if manual { autoHideSuspended = false }
        hiddenItemsController?.collapse(anchor: statusItemController?.item.button, requestPermission: manual) { [weak self] error in
            guard let self else { return }
            self.isCollapsing = false
            self.lastError = error
            self.state = error == nil ? .collapsed : .expanded
            self.applyState(source: source)
            if let error {
                self.logger.error("Cannot hide menu bar items: \(error)")
                if source == .click || source == .menu || source == .keyboardShortcut {
                    self.showContextMenu()
                }
            }
        }
    }

    func displayConfigurationDidChange() {
        logger.info("Display configuration changed.")
        expand(source: .displayChange)
    }

    private func applyState(source: ToggleSource?) {
        let style = IconStyle(rawValue: preferences.iconStyleRawValue) ?? .default
        statusItemController?.setIconStyle(style, expanded: state == .expanded)
        statusItemController?.item.button?.toolTip = lastError ?? "Tucker"
        rebuildMenu()

        if state == .expanded && lastError == nil && !isCollapsing {
            scheduleAutoHideIfNeeded()
        }
    }

    private func observePreferences() {
        preferences.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.applyState(source: nil) }
        }
        .store(in: &cancellables)
    }

    private func hoverEntered() {
        guard preferences.showOnHover else { return }
        expand(source: .hover)
    }

    private func hoverExited() {
        guard preferences.showOnHover else { return }
        scheduleAutoHideIfNeeded()
    }

    private func scheduleAutoHideIfNeeded() {
        cancelAutoHide()
        guard preferences.automaticallyHideItems, !autoHideSuspended else { return }
        let delay = AutoHideDelay(rawValue: preferences.autoHideDelayRawValue) ?? .five
        guard let interval = delay.interval else { return }
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.collapse(source: .timer)
            }
        }
    }

    private func cancelAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private func rebuildMenu() {
        statusItemController?.item.menu = nil
    }

    private func showContextMenu() {
        guard let item = statusItemController?.item else { return }
        let menu = NSMenu()
        if let lastError {
            let errorItem = menu.addItem(withTitle: lastError, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(.separator())
        }

        let toggleTitle = state == .expanded ? "Hide Hidden Items" : "Show Hidden Items"
        menu.addItem(withTitle: toggleTitle, action: #selector(contextToggle), keyEquivalent: "").target = self
        menu.addItem(.separator())

        menu.addItem(withTitle: "Settings...", action: #selector(contextSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())

        menu.addItem(withTitle: "About Tucker", action: #selector(contextAbout), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit Tucker", action: #selector(contextQuit), keyEquivalent: "q").target = self

        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func contextToggle() {
        toggle(source: .menu)
    }

    @objc private func contextSettings() {
        guard let delegate = NSApp.delegate else { return }
        NSApp.sendAction(#selector(AppDelegate.showSettings), to: delegate, from: nil)
    }

    @objc private func contextAbout() {
        guard let delegate = NSApp.delegate else { return }
        NSApp.sendAction(#selector(AppDelegate.showAbout), to: delegate, from: nil)
    }

    @objc private func contextQuit() {
        NSApp.terminate(nil)
    }
}
