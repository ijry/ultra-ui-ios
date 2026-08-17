import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class LineProgressTests: XCTestCase {
    func testDefaultsMatchUviewPlusLineProgress() {
        let progress = UPLineProgress()

        XCTAssertEqual(progress.activeColor, "#19be6b")
        XCTAssertEqual(progress.inactiveColor, "#ececec")
        XCTAssertEqual(progress.percentage, "0")
        XCTAssertTrue(progress.showText)
        XCTAssertEqual(progress.height, "12")
        XCTAssertFalse(progress.fromRight)
        XCTAssertEqual(progress.customStyle, UPStyle())
        XCTAssertEqual(progress.innserPercentage, 0)
        XCTAssertFalse(progress.showsDefaultText)
        XCTAssertFalse(progress.hasDefaultSlot)
    }

    func testStringOrNumberPropsNormalizeAndClampTheMeasuredLineWidth() {
        let progress = UPLineProgress(percentage: "72.5", height: 16)
        let capped = UPLineProgress(percentage: 130, height: "8px")
        let belowRange = UPLineProgress(percentage: -5)

        XCTAssertEqual(progress.percentage, "72.5")
        XCTAssertEqual(progress.height, "16")
        XCTAssertEqual(progress.innserPercentage, 72.5)
        XCTAssertEqual(progress.resolvedHeight, 16)
        XCTAssertEqual(progress.resolvedLineWidth(in: 200), 145)
        XCTAssertEqual(progress.defaultText, "72.5%")

        XCTAssertEqual(capped.innserPercentage, 100)
        XCTAssertEqual(capped.resolvedLineWidth(in: 240), 240)
        XCTAssertEqual(capped.resolvedHeight, 8)
        XCTAssertEqual(capped.defaultText, "100%")

        XCTAssertEqual(belowRange.innserPercentage, 0)
        XCTAssertEqual(belowRange.resolvedLineWidth(in: 240), 0)
    }

    func testDefaultTextUsesRawPercentageThresholdFromUpstreamTemplate() {
        let nine = UPLineProgress(percentage: 9)
        let ten = UPLineProgress(percentage: 10)
        let hidden = UPLineProgress(percentage: 80, showText: false)

        XCTAssertFalse(nine.showsDefaultText)
        XCTAssertTrue(ten.showsDefaultText)
        XCTAssertEqual(ten.defaultText, "10%")
        XCTAssertFalse(hidden.showsDefaultText)
    }

    func testDefaultSlotCustomStyleAndFromRightRemainOnTheCompatibilitySurface() {
        let style = UPStyle(["marginTop": "8px", "backgroundColor": "#ffffff"])
        let progress = UPLineProgress(
            percentage: 50,
            fromRight: true,
            customStyle: style
        ) {
            Image(systemName: "checkmark")
        }

        XCTAssertTrue(progress.fromRight)
        XCTAssertEqual(progress.customStyle, style)
        XCTAssertTrue(progress.hasDefaultSlot)
        XCTAssertEqual(progress.resolvedLineWidth(in: 320), 160)
    }

    func testSharedMixinAndAllIntegerNumberPropsRemainAvailable() {
        let percentage: Int8 = 50
        let height: UInt16 = 6
        let style = UPStyle(["marginTop": "8px"])
        let progress = UPLineProgress(
            percentage: percentage,
            height: height,
            customClass: "upload-progress",
            customStyle: style
        )

        XCTAssertEqual(progress.percentage, "50")
        XCTAssertEqual(progress.height, "6")
        XCTAssertEqual(progress.customClass, "upload-progress")
        XCTAssertEqual(progress.customStyle, style)
    }

}
