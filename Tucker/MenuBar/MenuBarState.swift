import Foundation

enum MenuBarVisibilityState: String {
    case collapsed
    case expanded
}

enum ToggleSource: String {
    case click
    case hover
    case keyboardShortcut
    case menu
    case timer
    case displayChange
}

enum IconStyle: String, CaseIterable, Identifiable {
    case `default`
    case minimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "Default"
        case .minimal: "Minimal"
        }
    }

    var symbolName: String {
        switch self {
        case .default: "rectangle.compress.vertical"
        case .minimal: "chevron.left.forwardslash.chevron.right"
        }
    }
}

enum AutoHideDelay: Int, CaseIterable, Identifiable {
    case three = 3
    case five = 5
    case ten = 10
    case fifteen = 15
    case never = 0

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .three: "3 seconds"
        case .five: "5 seconds"
        case .ten: "10 seconds"
        case .fifteen: "15 seconds"
        case .never: "Never"
        }
    }

    var interval: TimeInterval? {
        rawValue == 0 ? nil : TimeInterval(rawValue)
    }
}
