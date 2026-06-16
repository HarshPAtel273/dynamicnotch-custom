import SwiftUI

enum HudStyle: String, CaseIterable {
    case standard
    case compact
    case minimal
    case vertical
    case large

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.hud.style.standard"
        case .compact:
            return "settings.hud.style.compact"
        case .minimal:
            return "settings.hud.style.minimal"
        case .vertical:
            return "settings.hud.style.vertical"
        case .large:
            return "settings.hud.style.large"
        }
    }

    var symbolName: String {
        switch self {
        case .standard:
            return "rectangle.and.text.magnifyingglass"
        case .compact:
            return "rectangle.compress.vertical"
        case .minimal:
            return "minus.rectangle"
        case .vertical:
            return "square.split.2x1"
        case .large:
            return "square.split.1x2"
        }
    }
}
