import SwiftUI

struct HudLargeContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    let image: String
    let text: String
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                iconView
                Text(verbatim: text)
                    .font(.system(size: isDynamicIsland ? 12 : 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            indicatorView
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }
    
    private var iconView: some View {
        Image(systemName: image)
            .font(.system(size: isDynamicIsland ? 16 : 18))
            .foregroundColor(.white)
    }
    
    private var indicatorView: some View {
        HudLevelIndicatorView(
            level: clampedLevel,
            indicatorStyle: indicatorStyle,
            tintStyle: indicatorTintStyle,
            showsGlow: showsIndicatorGlow,
            barWidth: barIndicatorWidth,
            barHeight: barIndicatorHeight,
            circleSize: circleIndicatorSize,
            circleLineWidth: circleIndicatorLineWidth
        )
    }
    
    private var verticalPadding: CGFloat {
        isDynamicIsland ? 6 : 8
    }
    
    private var horizontalPadding: CGFloat {
        isDynamicIsland ? 12 : 16
    }
    
    private var barIndicatorWidth: CGFloat {
        80
    }
    
    private var barIndicatorHeight: CGFloat {
        6
    }
    
    private var circleIndicatorSize: CGFloat {
        isDynamicIsland ? 16 : 20
    }
    
    private var circleIndicatorLineWidth: CGFloat {
        3
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
