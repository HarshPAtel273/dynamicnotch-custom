import SwiftUI

struct HudExpandedCompactContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    let image: String
    let level: Int
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                indicatorView
                
                HStack {
                    iconView
                    
                    Spacer()
                    
                    AnimatedLevelText(
                        level: clampedLevel,
                        fontSize: 14
                    )
                }
            }
        }
        .padding(.bottom, 10)
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
            indicatorStyle: .bar,
            tintStyle: indicatorTintStyle,
            showsGlow: showsIndicatorGlow,
            barWidth: 110,
            barHeight: 8
        )
    }
    
    private var horizontalPadding: CGFloat {
        isDynamicIsland ? 12 : 26
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
