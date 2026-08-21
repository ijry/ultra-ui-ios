import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class NavbarScrollStickyTests: XCTestCase {
    func testNavbarDefaultsDimensionsAndEvents() {
        var events: [String] = []
        let navbar = UPNavbar(title: "详情")
            .onLeftClick { events.append("left") }
            .onRightClick { events.append("right") }

        XCTAssertTrue(navbar.safeAreaInsetTop)
        XCTAssertTrue(navbar.fixed)
        XCTAssertFalse(navbar.placeholder)
        XCTAssertEqual(navbar.leftIcon, "arrow-left")
        XCTAssertEqual(navbar.resolvedHeight, 44)
        XCTAssertEqual(navbar.resolvedTitleWidth, 400)

        navbar.triggerLeftClick()
        navbar.triggerRightClick()
        XCTAssertEqual(events, ["left", "right"])
    }

    func testNavbarMiniMatchesUpstreamDefaults() {
        var clicks = 0
        let navbar = UPNavbarMini().onLeftClick { clicks += 1 }
        XCTAssertTrue(navbar.safeAreaInsetTop)
        XCTAssertTrue(navbar.fixed)
        XCTAssertEqual(navbar.leftIcon, "arrow-leftward")
        XCTAssertEqual(navbar.resolvedHeight, 32)
        XCTAssertEqual(navbar.resolvedIconSize, 20)
        XCTAssertTrue(navbar.autoBack)
        navbar.triggerLeftClick()
        XCTAssertEqual(clicks, 1)
    }

    func testScrollListCalculatesIndicatorAndBoundaryEvents() {
        var events: [String] = []
        let list = UPScrollList(contentWidth: 500, viewportWidth: 200)
            .onLeft { events.append("left") }
            .onRight { events.append("right") }

        XCTAssertEqual(list.indicatorWidth, 50)
        XCTAssertEqual(list.indicatorBarWidth, 20)
        XCTAssertEqual(list.indicatorOffset(scrollOffset: 150), 15, accuracy: 0.001)
        list.reportScroll(offset: 0)
        list.reportScroll(offset: 300)
        XCTAssertEqual(events, ["left", "right"])
    }

    func testStickyResolvesNativePinOffsetAndChangePayload() {
        var payloads: [UPStickyChange] = []
        let sticky = UPSticky(offsetTop: 12, customNavHeight: 44, index: "section-2")
            .onFixed { payloads.append($0) }

        XCTAssertFalse(sticky.disabled)
        XCTAssertEqual(sticky.pinOffset, 56)
        XCTAssertFalse(sticky.isFixed(minY: 57))
        XCTAssertTrue(sticky.isFixed(minY: 55))
        sticky.report(minY: 55)
        XCTAssertEqual(payloads, [UPStickyChange(index: "section-2", isFixed: true)])
    }
}
