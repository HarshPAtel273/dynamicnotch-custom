//
//  extension+View.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/10/26.
//

import SwiftUI

extension View {
    func customNotchPressable(isPressed: Binding<Bool>, baseSize: CGSize) -> some View {
        modifier(NotchCustomScaleModifier(isPressed: isPressed, baseSize: baseSize))
    }

    func customNotchPinchToDismiss(
        isEnabled: Bool,
        threshold: CGFloat = 0.88,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            NotchPinchDismissModifier(
                isEnabled: isEnabled,
                threshold: threshold,
                onDismiss: onDismiss
            )
        )
    }
}
