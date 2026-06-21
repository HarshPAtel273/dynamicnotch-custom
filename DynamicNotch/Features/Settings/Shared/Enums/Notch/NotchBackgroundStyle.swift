import SwiftUI

enum NotchBackgroundStyle: String, CaseIterable {
    case black
    case ultraThickMaterial
    case liquidGlass

    static var availableOptions: [Self] {
        return Array(allCases)
    }

    var title: LocalizedStringKey {
        switch self {
        case .black:
            return "Black"
        case .ultraThickMaterial:
            return "Material"
        case .liquidGlass:
            return "Liquid Glass"
        }
    }

    var symbolName: String {
        switch self {
        case .black:
            return "circle.fill"
        case .ultraThickMaterial:
            return "square.stack.3d.up.fill"
        case .liquidGlass:
            return "sparkles"
        }
    }

    var isSupportedOnCurrentSystem: Bool {
        return true
    }

    static func resolved(_ rawValue: String?) -> NotchBackgroundStyle {
        guard let rawValue, let style = NotchBackgroundStyle(rawValue: rawValue) else {
            return .black
        }

        return style
    }
}
