import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SkeletonTests: XCTestCase {
    func testDefaultsMatchUviewPlusSkeleton() {
        let skeleton = UPSkeleton()

        XCTAssertTrue(skeleton.loading)
        XCTAssertTrue(skeleton.animate)
        XCTAssertEqual(skeleton.rows, "0")
        XCTAssertEqual(skeleton.rowsWidth, .scalar("100%"))
        XCTAssertEqual(skeleton.rowsHeight, .scalar("18"))
        XCTAssertTrue(skeleton.title)
        XCTAssertEqual(skeleton.titleWidth, "50%")
        XCTAssertEqual(skeleton.titleHeight, "18")
        XCTAssertFalse(skeleton.avatar)
        XCTAssertEqual(skeleton.avatarSize, "32")
        XCTAssertEqual(skeleton.avatarShape, "circle")
        XCTAssertTrue(skeleton.showsSkeleton)
    }

    func testScalarStringOrNumberPropsRetainTheUpstreamLastRowFallback() {
        let skeleton = UPSkeleton(
            rows: "3",
            rowsWidth: "90%",
            rowsHeight: 20,
            titleWidth: 160,
            titleHeight: "16px",
            avatarSize: 40
        )

        XCTAssertEqual(skeleton.rows, "3")
        XCTAssertEqual(skeleton.rowsWidth, .scalar("90%"))
        XCTAssertEqual(skeleton.rowsHeight, .scalar("20"))
        XCTAssertEqual(skeleton.titleWidth, "160")
        XCTAssertEqual(skeleton.titleHeight, "16px")
        XCTAssertEqual(skeleton.avatarSize, "40")
        XCTAssertEqual(skeleton.rowsArray.map(\.width), ["90%", "90%", "70%"])
        XCTAssertEqual(skeleton.rowsArray.map(\.height), ["20", "20", "20"])
        XCTAssertEqual(skeleton.rowsArray.map(\.marginTop), ["20px", "12px", "12px"])
    }

    func testArrayRowsUseUviewPlusMissingValueFallbacksAndTitleSpacingRules() {
        let skeleton = UPSkeleton(
            rows: 4,
            rowsWidth: ["80%"],
            rowsHeight: [20],
            title: false
        )

        XCTAssertEqual(skeleton.rowsWidth, .array(["80%"]))
        XCTAssertEqual(skeleton.rowsHeight, .array(["20"]))
        XCTAssertEqual(skeleton.rowsArray.map(\.width), ["80%", "100%", "100%", "70%"])
        XCTAssertEqual(skeleton.rowsArray.map(\.height), ["20", "18px", "18px", "18px"])
        XCTAssertEqual(skeleton.rowsArray.map(\.marginTop), ["0", "12px", "12px", "12px"])
    }

    func testPercentageWidthsAndAvatarShapeResolveForNativeLayout() {
        let skeleton = UPSkeleton(
            rows: 2,
            rowsWidth: ["100%"],
            rowsHeight: ["20px"],
            titleWidth: "50%",
            titleHeight: "16px",
            avatar: true,
            avatarSize: "40rpx",
            avatarShape: "square"
        )

        XCTAssertEqual(skeleton.resolvedTitleWidth(in: 300), 150)
        XCTAssertEqual(skeleton.resolvedTitleHeight, 16)
        XCTAssertEqual(skeleton.rowsArray[0].resolvedWidth(in: 300), 300)
        XCTAssertEqual(skeleton.rowsArray[1].resolvedWidth(in: 300), 210)
        XCTAssertEqual(skeleton.rowsArray[0].resolvedHeight, 20)
        XCTAssertEqual(skeleton.resolvedAvatarSize, 40)
        XCTAssertEqual(skeleton.avatarCornerRadius, 4)
    }

    func testLoadingFalseUsesTheDefaultSlotInsteadOfSkeletonMarkup() {
        let loaded = UPSkeleton(loading: false, animate: false) {
            Text("已加载内容")
        }

        XCTAssertFalse(loaded.loading)
        XCTAssertFalse(loaded.animate)
        XCTAssertFalse(loaded.showsSkeleton)
    }

    func testSharedMixinAndAllIntegerNumberInputsRemainAvailable() {
        let rows: Int8 = 2
        let width: UInt16 = 80
        let height: Int16 = 16
        let style = UPStyle(["marginTop": "8px"])
        let skeleton = UPSkeleton(
            rows: rows,
            rowsWidth: [width],
            rowsHeight: height,
            customClass: "article-skeleton",
            customStyle: style
        )

        XCTAssertEqual(skeleton.rows, "2")
        XCTAssertEqual(skeleton.rowsWidth, .array(["80"]))
        XCTAssertEqual(skeleton.rowsHeight, .scalar("16"))
        XCTAssertEqual(skeleton.customClass, "article-skeleton")
        XCTAssertEqual(skeleton.customStyle, style)
    }

}
