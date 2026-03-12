import SwiftUI

struct NotchPinchDismissModifier: ViewModifier {
    let isEnabled: Bool
    let threshold: CGFloat
    let onDismiss: () -> Void

    @State private var pinchScale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(pinchScale, anchor: .top)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: pinchScale)
            .onChange(of: isEnabled) {
                if !isEnabled {
                    pinchScale = 1
                }
            }
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        guard isEnabled else { return }
                        pinchScale = max(0.82, min(1.0, value))
                    }
                    .onEnded { value in
                        guard isEnabled else {
                            pinchScale = 1
                            return
                        }

                        let shouldDismiss = value < threshold
                        pinchScale = 1

                        if shouldDismiss {
                            onDismiss()
                        }
                    }
            )
    }
}
