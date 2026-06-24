import SwiftUI

enum NowPlayingProgressTintStyle: String, CaseIterable {
    case `default`
    case artwork
    case systemAccent

    var title: LocalizedStringKey {
        switch self {
        case .`default`:
            return "Default"
        case .artwork:
            return "Artwork cover"
        case .systemAccent:
            return "System accent"
        }
    }

    static func resolved(_ rawValue: String?) -> Self {
        rawValue.flatMap(Self.init(rawValue:)) ?? .`default`
    }
}
