import XCTest
@testable import UltraUI

@MainActor
final class BadgeTests: XCTestCase {
    func testDefaultsMatchUviewPlusBadge() {
        let badge = UPBadge()

        XCTAssertFalse(badge.isDot)
        XCTAssertEqual(badge.value, "")
        XCTAssertTrue(badge.show)
        XCTAssertEqual(badge.max, 999)
        XCTAssertEqual(badge.type, "error")
        XCTAssertFalse(badge.showZero)
        XCTAssertNil(badge.bgColor)
        XCTAssertNil(badge.color)
        XCTAssertEqual(badge.shape, "circle")
        XCTAssertEqual(badge.numberType, "overflow")
        XCTAssertEqual(badge.offset, [])
        XCTAssertFalse(badge.inverted)
        XCTAssertFalse(badge.absolute)
        XCTAssertEqual(badge.customClass, "")
        XCTAssertEqual(badge.customStyle, UPStyle())
    }


    func testStringAndNumberPropsCanBeMixedIndependently() {
        let badge = UPBadge(value: 1_200.5, modelValue: 7, max: "999")

        XCTAssertEqual(badge.value, "1200.5")
        XCTAssertEqual(badge.modelValue, "7")
        XCTAssertEqual(badge.max, 999)
        XCTAssertEqual(badge.displayValue, "999+")
    }


    func testCustomClassAndStyleRemainAvailableFromTheSharedMixinSurface() {
        let style = UPStyle(["padding": "3px"])
        let badge = UPBadge(customClass: "inbox-badge", customStyle: style)

        XCTAssertEqual(badge.customClass, "inbox-badge")
        XCTAssertEqual(badge.customStyle, style)
    }


    func testNumberTypeFormattingMatchesTheUpstreamBadgeRules() {
        XCTAssertEqual(UPBadge.formattedValue("1000", max: 999, numberType: "overflow"), "999+")
        XCTAssertEqual(UPBadge.formattedValue("1000", max: 999, numberType: "ellipsis"), "...")
        XCTAssertEqual(UPBadge.formattedValue("2200", max: 999, numberType: "limit"), "2.2k")
        XCTAssertEqual(UPBadge.formattedValue("33400", max: 999, numberType: "limit"), "3.34w")
    }
}
