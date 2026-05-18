//
//  HomePageNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

struct HomePageNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.HomePage.active.id
    let notchViewModel: NotchViewModel
    
    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        if notchViewModel.isDisplayingExpandedLiveActivity {
            return .white.opacity(0.2)
        }
        return .white.opacity(0)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 150, height: baseHeight + 200)
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(HomePageNotchView())
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
