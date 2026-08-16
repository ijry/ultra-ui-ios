import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class PopupTests: XCTestCase {
    func testOverlayDefaults() {
        let overlay = UPOverlay()
        XCTAssertEqual(overlay.opacity, 0.5)
        XCTAssertEqual(overlay.duration, 300)
    }

    func testHiddenOverlayDoesNotReceiveHitTesting() {
        XCTAssertFalse(UPOverlay.allowsHitTesting(show: false))
        XCTAssertTrue(UPOverlay.allowsHitTesting(show: true))
    }

    func testPopupOnlyRendersOverlayWhileShown() {
        XCTAssertFalse(UPPopup<EmptyView>.shouldRenderOverlay(show: false, overlay: true))
        XCTAssertFalse(UPPopup<EmptyView>.shouldRenderOverlay(show: true, overlay: false))
        XCTAssertTrue(UPPopup<EmptyView>.shouldRenderOverlay(show: true, overlay: true))
    }
}
