import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class ToastTests: XCTestCase {
    func testTypeIcon() {
        XCTAssertEqual(UPToast.iconName(for: "success"), "uicon-checkmark")
        XCTAssertEqual(UPToast.iconName(for: "error"), "uicon-close")
        XCTAssertEqual(UPToast.iconName(for: "warning"), "uicon-info-circle")
        XCTAssertEqual(UPToast.iconName(for: "loading"), "")
        XCTAssertEqual(UPToast.iconName(for: "default"), "")
    }

    func testPositionAlignment() {
        XCTAssertEqual(UPToast.alignment(for: "top"), .top)
        XCTAssertEqual(UPToast.alignment(for: "bottom"), .bottom)
        XCTAssertEqual(UPToast.alignment(for: "center"), .center)
        XCTAssertEqual(UPToast.alignment(for: "unexpected"), .center)
    }

    func testCenterShowAndHide() {
        let center = UPToastCenter()
        center.show(message: "Saved", type: "success", position: "top", duration: 5_000)
        XCTAssertTrue(center.isShowing)
        XCTAssertEqual(center.message, "Saved")
        XCTAssertEqual(center.type, "success")
        XCTAssertEqual(center.position, "top")

        center.hide()
        XCTAssertFalse(center.isShowing)
    }
}
