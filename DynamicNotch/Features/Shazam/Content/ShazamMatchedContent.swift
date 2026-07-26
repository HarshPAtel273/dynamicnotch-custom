//
//  ShazamMatchedContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamMatchedContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Shazam.matched.id
    let result: ShazamResult
    let shazamViewModel: ShazamViewModel
    let notchViewModel: NotchViewModel?
    
    init(
        result: ShazamResult,
        shazamViewModel: ShazamViewModel,
        notchViewModel: NotchViewModel? = nil
    ) {
        self.result = result
        self.shazamViewModel = shazamViewModel
        self.notchViewModel = notchViewModel
    }
    
    var priority: Int { NotchContentRegistry.Shazam.matched.priority }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        .blue.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 80, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 140, height: baseHeight + 50)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 40)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 80, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 180, height: baseHeight + 50)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(ShazamNotchView(shazamViewModel: shazamViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            ShazamMatchedView(
                result: result,
                shazamViewModel: shazamViewModel,
                notchViewModel: notchViewModel,
                onRequestCollapse: { [weak notchViewModel] in
                    notchViewModel?.send(.hideLiveActivity(id: NotchContentRegistry.Shazam.matched.id))
                }
            )
        )
    }
}
