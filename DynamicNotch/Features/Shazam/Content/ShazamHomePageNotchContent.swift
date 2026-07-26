//
//  ShazamHomePageNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamHomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let shazamViewModel: ShazamViewModel
    let notchViewModel: NotchViewModel
    let onRequestCollapse: (@MainActor () -> Void)?

    init(
        shazamViewModel: ShazamViewModel,
        notchViewModel: NotchViewModel,
        onRequestCollapse: (@MainActor () -> Void)? = nil
    ) {
        self.shazamViewModel = shazamViewModel
        self.notchViewModel = notchViewModel
        self.onRequestCollapse = onRequestCollapse
    }

    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 38)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight + 50)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 100, height: baseHeight + 50)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        if let result = shazamViewModel.matchedResult {
            return AnyView(
                ShazamMatchedView(
                    result: result,
                    shazamViewModel: shazamViewModel,
                    notchViewModel: notchViewModel,
                    onRequestCollapse: onRequestCollapse
                )
            )
        } else {
            return AnyView(
                ShazamHomePageView(
                    shazamViewModel: shazamViewModel,
                    notchViewModel: notchViewModel,
                    onRequestCollapse: onRequestCollapse
                )
            )
        }
    }
}
