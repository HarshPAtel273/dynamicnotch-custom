import SwiftUI

struct HudContentView: View {
    let image: String
    let text: String
    let level: Int
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        switch style {
        case .standard:
            HudStandardContentView(
                text: text,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .compact:
            HudCompactContentView(
                image: image,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .minimal:
            HudMinimalContentView(
                image: image,
                level: level,
                indicatorStyle: indicatorStyle
            )
        case .vertical:
            HudVerticalContentView(
                image: image,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .large:
            HudLargeContentView(
                image: image,
                text: text,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        }
    }
}


