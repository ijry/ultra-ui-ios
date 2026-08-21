import Foundation
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CalendarComponentTests: XCTestCase {
    func testCalendarSelectsDateWithinRangeAndEmitsChange() {
        var selected: Date?
        var changed: Date?
        let calendar = UPCalendar(selectedDate: Binding(get: { selected }, set: { selected = $0 }),
                                  minDate: Date(timeIntervalSince1970: 100), maxDate: Date(timeIntervalSince1970: 300))
            .onChange { changed = $0 }
        calendar.select(Date(timeIntervalSince1970: 200))
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(changed, selected)
        calendar.select(Date(timeIntervalSince1970: 400))
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 200))
    }

    func testCalendarStripExposesVisibleDatesAndSelection() {
        var index = 0
        let strip = UPCalendarStrip(dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)],
                                    current: Binding(get: { index }, set: { index = $0 }))
        strip.select(1)
        XCTAssertEqual(index, 1)
        XCTAssertEqual(strip.selectedDate, Date(timeIntervalSince1970: 2))
    }
}

@MainActor
final class CommerceComponentTests: XCTestCase {
    func testCouponClaimUpdatesStateAndEmitsEvent() {
        var claimed = ""
        let coupon = UPCoupon(id: "c1", title: "10 off", value: 10).onClaim { claimed = $0.id }
        XCTAssertFalse(coupon.isClaimed)
        coupon.claim()
        XCTAssertTrue(coupon.isClaimed)
        XCTAssertEqual(claimed, "c1")
    }

    func testGoodsSkuOnlyConfirmsCompleteSelection() {
        var confirmed: [String: String] = [:]
        let sku = UPGoodsSku(options: [
            UPGoodsSkuOption(name: "Color", values: ["Red", "Blue"]),
            UPGoodsSkuOption(name: "Size", values: ["S", "M"])
        ]).onConfirm { confirmed = $0 }
        sku.select("Color", value: "Red")
        XCTAssertFalse(sku.confirm())
        sku.select("Size", value: "M")
        XCTAssertTrue(sku.confirm())
        XCTAssertEqual(confirmed["Color"], "Red")
    }
}

@MainActor
final class NavigationBusinessTests: XCTestCase {
    func testCateTabSelectionEmitsIndexAndValue() {
        var selected = ""
        let tabs = UPCateTab(items: ["全部", "数码"]).onChange { selected = $0.value }
        tabs.select(1)
        XCTAssertEqual(tabs.current, 1)
        XCTAssertEqual(selected, "数码")
    }

    func testTreeExpandsAndSelectsRecursiveNode() {
        let tree = UPTree(nodes: [UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "child", title: "Child")])])
        tree.toggle("root")
        XCTAssertTrue(tree.isExpanded("root"))
        tree.select("child")
        XCTAssertEqual(tree.selectedIDs, ["child"])
    }
}
