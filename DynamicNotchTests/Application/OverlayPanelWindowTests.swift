import AppKit
import SwiftUI
import XCTest
@testable import DynamicNotch

final class OverlayPanelWindowTests: XCTestCase {
    func testOverlayPanelDoesNotStealMainWindowOrLieAboutKeyStatus() {
        let window = OverlayPanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        XCTAssertTrue(window.canBecomeKey)
        XCTAssertFalse(window.canBecomeMain)
        XCTAssertFalse(window.isKeyWindow)
    }

    @MainActor
    func testNotchHostingViewPassesClicksOutsideInteractiveArea() {
        let hostingView = NotchHostingView(rootView: Color.clear.frame(width: 200, height: 200))
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 200)
        hostingView.allowsHitThroughEmptyAreas = true
        hostingView.isPointInsideInteractiveArea = { point in
            NSRect(x: 75, y: 150, width: 50, height: 40).contains(point)
        }

        XCTAssertNil(hostingView.hitTest(NSPoint(x: 10, y: 10)))
        XCTAssertFalse(hostingView.acceptsFirstResponder)
    }
}
