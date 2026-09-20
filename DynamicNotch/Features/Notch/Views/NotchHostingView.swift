import SwiftUI

final class NotchHostingView: NSHostingView<AnyView> {
    var allowsHitThroughEmptyAreas = false
    var isPointInsideInteractiveArea: ((NSPoint) -> Bool)?

    required init(rootView: AnyView) {
        super.init(rootView: rootView)
    }

    convenience init<Content: View>(rootView: Content) {
        self.init(rootView: AnyView(rootView))
    }

    @MainActor @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard allowsHitThroughEmptyAreas else {
            return super.hitTest(point)
        }

        if let isPointInsideInteractiveArea, isPointInsideInteractiveArea(point) == false {
            return nil
        }

        return super.hitTest(point) ?? self
    }
}
