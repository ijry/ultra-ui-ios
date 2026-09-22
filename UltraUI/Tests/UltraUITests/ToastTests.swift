import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class ToastTests: XCTestCase {
    /// 上游 `iconName` 走 `type2icon`：primary/success/error/warning 有内建图标，
    /// info/loading/default/未知 回落空串。
    func testTypeIcon() {
        XCTAssertEqual(UPToast.iconName(for: "success"), "checkmark-circle")
        XCTAssertEqual(UPToast.iconName(for: "error"), "close-circle")
        XCTAssertEqual(UPToast.iconName(for: "warning"), "error-circle")
        XCTAssertEqual(UPToast.iconName(for: "primary"), "info-circle")
        XCTAssertEqual(UPToast.iconName(for: "info"), "")
        XCTAssertEqual(UPToast.iconName(for: "loading"), "")
        XCTAssertEqual(UPToast.iconName(for: "default"), "")
    }

    /// 上游 `iconName` computed 的完整判定：
    /// - icon 为空或 "none" → 空串
    /// - icon === true（配置默认）→ 仅 primary/success/error/warning 走 type2icon
    /// - icon 为具体字符串 → 原样返回
    func testResolvedIconNameMatchesUpstreamComputed() {
        XCTAssertEqual(UPToast.resolvedIconName(icon: "", type: "success"), "")
        XCTAssertEqual(UPToast.resolvedIconName(icon: "none", type: "success"), "")
        XCTAssertEqual(UPToast.resolvedIconName(icon: "true", type: "success"), "checkmark-circle")
        XCTAssertEqual(UPToast.resolvedIconName(icon: "true", type: "info"), "")
        XCTAssertEqual(UPToast.resolvedIconName(icon: "true", type: "default"), "")
        XCTAssertEqual(UPToast.resolvedIconName(icon: "star-fill", type: "success"), "star-fill")
    }

    func testPositionAlignment() {
        XCTAssertEqual(UPToast.alignment(for: "top"), .top)
        XCTAssertEqual(UPToast.alignment(for: "bottom"), .bottom)
        XCTAssertEqual(UPToast.alignment(for: "center"), .center)
        XCTAssertEqual(UPToast.alignment(for: "unexpected"), .center)
    }

    func testZeroDurationToastDismissesAndCompletesOnlyOnce() async {
        let center = UPToastCenter()
        let completed = expectation(description: "zero-duration toast completion")
        var callbackCount = 0

        center.show(UPToastOptions(
            message: "Saved",
            show: true,
            duration: 0,
            callback: {
                callbackCount += 1
                completed.fulfill()
            }
        ))

        await fulfillment(of: [completed], timeout: 1)
        XCTAssertFalse(center.isShowing)

        center.hide()
        XCTAssertEqual(callbackCount, 1)
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
