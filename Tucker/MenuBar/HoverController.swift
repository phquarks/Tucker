import AppKit

@MainActor
final class HoverController {
    private weak var button: NSStatusBarButton?
    private var monitor: Any?
    var onEntered: (() -> Void)?
    var onExited: (() -> Void)?

    func attach(to button: NSStatusBarButton?) {
        self.button = button
        removeMonitor()
        guard button != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handle(event: event)
            return event
        }
    }

    func detach() {
        removeMonitor()
        button = nil
    }

    private var wasInside = false

    private func handle(event: NSEvent) {
        guard let button, let window = button.window else { return }
        let location = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        let inside = button.bounds.contains(button.convert(location, from: nil))
        guard inside != wasInside else { return }
        wasInside = inside
        inside ? onEntered?() : onExited?()
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
