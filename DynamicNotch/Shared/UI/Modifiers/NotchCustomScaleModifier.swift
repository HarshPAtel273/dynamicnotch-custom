//
//  NotchPressModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct NotchCustomScaleModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    @Binding var isPressed: Bool
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    private let tapTriggerDelay: TimeInterval = 0.12
    
    func body(content: Content) -> some View {
        let pressedHeight = baseSize.height * scaleFactor
        let pressedWidth = baseSize.width * scaleFactor
        let hitBounds = CGRect(origin: .zero, size: baseSize)
        
        content
            .frame(
                width: isPressed ? pressedWidth : baseSize.width,
                height: isPressed ? pressedHeight : baseSize.height
            )
            .frame(height: baseSize.height, alignment: .top)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let shouldAnimatePress = !notchViewModel.canExpandActiveLiveActivity
                        if !shouldAnimatePress {
                            if isPressed {
                                isPressed = false
                            }
                            return
                        }

                        let shouldBePressed = hitBounds.contains(value.location)
                        guard isPressed != shouldBePressed else { return }
                        isPressed = shouldBePressed
                    }
                    .onEnded { value in
                        let shouldAnimatePress = !notchViewModel.canExpandActiveLiveActivity
                        let shouldTriggerTap = hitBounds.contains(value.location)

                        if shouldAnimatePress {
                            guard isPressed || shouldTriggerTap else { return }
                            isPressed = false
                        } else if isPressed {
                            isPressed = false
                        }

                        guard shouldTriggerTap else { return }

                        if !shouldAnimatePress {
                            notchViewModel.handleActiveContentTap()
                            return
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + tapTriggerDelay) {
                            notchViewModel.handleActiveContentTap()
                        }
                    }
            )
    }
}
