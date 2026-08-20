import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class BackTopTests: XCTestCase {
    func testDefaultsMirrorUviewPlusBackTop() {
        let backTop = UPBackTop()

        XCTAssertEqual(backTop.mode, "circle")
        XCTAssertEqual(backTop.icon, "arrow-upward")
        XCTAssertEqual(backTop.text, "")
        XCTAssertEqual(backTop.duration, "100")
        XCTAssertEqual(backTop.scrollTop, "0")
        XCTAssertEqual(backTop.top, "400")
        XCTAssertEqual(backTop.bottom, "100")
        XCTAssertEqual(backTop.right, "20")
        XCTAssertEqual(backTop.zIndex, "9")
        XCTAssertEqual(
            backTop.iconStyle,
            UPStyle(["color": "#909399", "font-size": "19px"])
        )
        XCTAssertEqual(backTop.customClass, "")
        XCTAssertEqual(backTop.customStyle, UPStyle())
        XCTAssertFalse(backTop.isVisible)
        XCTAssertFalse(backTop.hasContentSlot)
    }

    func testStringAndNumberPropsPreserveCompatibilityAndResolveNativeMetrics() {
        let backTop = UPBackTop(
            mode: "square",
            icon: "arrow-up",
            text: "返回",
            duration: "250ms",
            scrollTop: "601px",
            top: 600,
            bottom: "48px",
            right: 16.5,
            zIndex: 99,
            iconStyle: UPStyle(["fontSize": "24px", "color": "primary"]),
            customClass: "page-back-top",
            customStyle: UPStyle(["backgroundColor": "#ffffff"])
        )

        XCTAssertEqual(backTop.duration, "250ms")
        XCTAssertEqual(backTop.scrollTop, "601px")
        XCTAssertEqual(backTop.top, "600")
        XCTAssertEqual(backTop.bottom, "48px")
        XCTAssertEqual(backTop.right, "16.5")
        XCTAssertEqual(backTop.zIndex, "99")
        XCTAssertEqual(backTop.resolvedDuration, 250, accuracy: 0.001)
        XCTAssertEqual(backTop.resolvedScrollTop, 601, accuracy: 0.001)
        XCTAssertEqual(backTop.resolvedTop, 600, accuracy: 0.001)
        XCTAssertEqual(backTop.resolvedBottom, 48, accuracy: 0.001)
        XCTAssertEqual(backTop.resolvedRight, 16.5, accuracy: 0.001)
        XCTAssertEqual(backTop.resolvedZIndex, 99, accuracy: 0.001)
        XCTAssertTrue(backTop.isVisible)
        XCTAssertEqual(backTop.resolvedMode, "square")
        XCTAssertEqual(backTop.resolvedCornerRadius, 4, accuracy: 0.001)
    }

    func testVisibilityUsesStrictUpstreamThresholdAndInvalidValuesFallBack() {
        XCTAssertFalse(UPBackTop(scrollTop: 400, top: 400).isVisible)
        XCTAssertTrue(UPBackTop(scrollTop: 400.1, top: 400).isVisible)

        let invalid = UPBackTop(
            mode: "unsupported",
            duration: "invalid",
            scrollTop: "invalid",
            top: "invalid",
            bottom: "invalid",
            right: "invalid",
            zIndex: "invalid"
        )

        XCTAssertEqual(invalid.resolvedMode, "square")
        XCTAssertEqual(invalid.resolvedDuration, 100, accuracy: 0.001)
        XCTAssertEqual(invalid.resolvedScrollTop, 0, accuracy: 0.001)
        XCTAssertEqual(invalid.resolvedTop, 400, accuracy: 0.001)
        XCTAssertEqual(invalid.resolvedBottom, 100, accuracy: 0.001)
        XCTAssertEqual(invalid.resolvedRight, 20, accuracy: 0.001)
        XCTAssertEqual(invalid.resolvedZIndex, 9, accuracy: 0.001)
        XCTAssertFalse(invalid.isVisible)
    }

    func testDefaultSlotAndClickEventMapToSwiftUI() {
        var clickCount = 0
        let original = UPBackTop(scrollTop: 500) {
            Text("顶部")
        }
        let configured = original.onClick { clickCount += 1 }

        XCTAssertTrue(original.hasContentSlot)
        XCTAssertNil(original.onClickHandler)
        XCTAssertNotNil(configured.onClickHandler)

        configured.triggerClick()
        XCTAssertEqual(clickCount, 1)
    }

    #if os(macOS)
    func testVisibleBackTopRendersInANativeOverlayCanvas() {
        let renderer = ImageRenderer(
            content: UPBackTop(scrollTop: 500)
                .frame(width: 320, height: 640)
        )

        XCTAssertEqual(renderer.cgImage?.width, 320)
        XCTAssertEqual(renderer.cgImage?.height, 640)
    }
    #endif
}
