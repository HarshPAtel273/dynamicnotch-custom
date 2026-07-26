//
//  ShazamNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Shazam.active.id
    let shazamViewModel: ShazamViewModel
    let notchViewModel: NotchViewModel?
    
    init(shazamViewModel: ShazamViewModel, notchViewModel: NotchViewModel? = nil) {
        self.shazamViewModel = shazamViewModel
        self.notchViewModel = notchViewModel
    }
    
    var priority: Int { NotchContentRegistry.Shazam.active.priority }
    
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        .blue.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 140, height: baseHeight + 60)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 40)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 30, height: baseHeight)
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
            ShazamExpandedNotchView(
                shazamViewModel: shazamViewModel,
                onRequestClose: { [weak shazamViewModel, weak notchViewModel] in
                    shazamViewModel?.stopListening()
                    notchViewModel?.send(.hideLiveActivity(id: NotchContentRegistry.Shazam.active.id))
                }
            )
        )
    }
}
