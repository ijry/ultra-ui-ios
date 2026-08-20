import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class EmptyTests: XCTestCase {
    func testDefaultsMatchUviewPlusEmpty() {
        let empty = UPEmpty()

        XCTAssertEqual(empty.icon, "")
        XCTAssertEqual(empty.text, "")
        XCTAssertEqual(empty.textColor, "#c0c4cc")
        XCTAssertEqual(empty.textSize, "14")
        XCTAssertEqual(empty.iconColor, "#c0c4cc")
        XCTAssertEqual(empty.iconSize, "90")
        XCTAssertEqual(empty.mode, "data")
        XCTAssertEqual(empty.width, "160")
        XCTAssertEqual(empty.height, "160")
        XCTAssertTrue(empty.show)
        XCTAssertEqual(empty.marginTop, "0")
    }

    func testExplicitTextOverridesBuiltInModeText() {
        XCTAssertEqual(UPEmpty(mode: "list").displayText, "列表为空")
        XCTAssertEqual(UPEmpty(text: "暂无内容", mode: "list").displayText, "暂无内容")
    }

    func testIconNameFollowsUviewPlusModeMapping() {
        XCTAssertEqual(UPEmpty(mode: "data").iconName, "empty-data")
        XCTAssertEqual(UPEmpty(mode: "message").iconName, "chat")
        XCTAssertEqual(UPEmpty(mode: "comment").iconName, "empty-comment")
    }

    func testPathLikeIconUsesImagePresentationAndResolvesNativeUnits() {
        let empty = UPEmpty(
            icon: "https://example.com/images/empty.png",
            textSize: "16px",
            iconSize: "80rpx",
            width: "120rpx",
            height: "60px",
            marginTop: "12px"
        )

        XCTAssertTrue(empty.usesImageIcon)
        XCTAssertEqual(empty.resolvedWidth, 120)
        XCTAssertEqual(empty.resolvedHeight, 60)
        XCTAssertEqual(empty.resolvedTextSize, 16)
        XCTAssertEqual(empty.resolvedIconSize, 80)
        XCTAssertEqual(empty.resolvedMarginTop, 12)
    }

    func testNumericInitializerPreservesUviewPlusStringOrNumberProps() {
        let empty = UPEmpty(textSize: 16, iconSize: 80, width: 120, height: 60, marginTop: 12)

        XCTAssertEqual(empty.textSize, "16")
        XCTAssertEqual(empty.iconSize, "80")
        XCTAssertEqual(empty.width, "120")
        XCTAssertEqual(empty.height, "60")
        XCTAssertEqual(empty.marginTop, "12")
    }

    func testStringAndNumberPropsCanBeMixedIndependently() {
        let style = UPStyle(["opacity": "0.75"])
        let empty = UPEmpty(
            textSize: 15,
            iconSize: "88px",
            width: 120,
            height: "90rpx",
            marginTop: 24,
            customStyle: style
        ) { Text("重新加载") }

        XCTAssertEqual(empty.textSize, "15")
        XCTAssertEqual(empty.iconSize, "88px")
        XCTAssertEqual(empty.width, "120")
        XCTAssertEqual(empty.height, "90rpx")
        XCTAssertEqual(empty.marginTop, "24")
        XCTAssertEqual(empty.customStyle, style)
        XCTAssertEqual(empty.resolvedTextSize, 15)
        XCTAssertEqual(empty.resolvedIconSize, 88)
        XCTAssertEqual(empty.resolvedWidth, 120)
        XCTAssertEqual(empty.resolvedHeight, 90)
        XCTAssertEqual(empty.resolvedMarginTop, 24)
    }

    func testViewBuilderSlotAndShowAreAvailableOnTheCompatibilitySurface() {
        let visible = UPEmpty { Text("重新加载") }
        let hidden = UPEmpty(show: false) { Text("重新加载") }

        XCTAssertTrue(visible.show)
        XCTAssertFalse(hidden.show)
    }
}
