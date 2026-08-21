import Foundation
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CalendarComponentTests: XCTestCase {
    func testBusinessComponentsKeepLegacyEmptyInitializers() {
        _ = UPCalendar()
        _ = UPCalendarStrip()
        _ = UPGoodsSku()
        _ = UPTree()
    }

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

    func testCalendarSupportsRangeSelectionAndConfirmPayload() {
        var dates: [Date] = []
        var confirmed: UPCalendarSelection?
        let calendar = UPCalendar(mode: .range, selectedDates: Binding(get: { dates }, set: { dates = $0 }))
            .onConfirm { confirmed = $0 }

        calendar.select(Date(timeIntervalSince1970: 100))
        calendar.select(Date(timeIntervalSince1970: 200))
        XCTAssertEqual(dates, [Date(timeIntervalSince1970: 100), Date(timeIntervalSince1970: 200)])
        XCTAssertEqual(calendar.confirm()?.dates, dates)
        XCTAssertEqual(confirmed?.range?.lowerBound, Date(timeIntervalSince1970: 100))
    }

    func testCalendarEnforcesReadonlyAndMultipleMaximum() {
        let readonly = UPCalendar(mode: .single, readonly: true)
        readonly.select(Date(timeIntervalSince1970: 100))
        XCTAssertTrue(readonly.selectedDates.isEmpty)

        let multiple = UPCalendar(mode: .multiple, maxCount: 1)
        multiple.select(Date(timeIntervalSince1970: 100))
        multiple.select(Date(timeIntervalSince1970: 200))
        XCTAssertEqual(multiple.selectedDates, [Date(timeIntervalSince1970: 100)])
        XCTAssertTrue(multiple.multiple)
    }

    func testCalendarStripSupportsDateBindingAndDisabledDates() {
        var selected: Date? = nil
        var changed: UPCalendarStripChange?
        let disabled = Date(timeIntervalSince1970: 2)
        let strip = UPCalendarStrip(
            dates: [Date(timeIntervalSince1970: 1), disabled, Date(timeIntervalSince1970: 3)],
            modelValue: Binding(get: { selected }, set: { selected = $0 }),
            disabledDates: [disabled]
        ).onChangePayload { changed = $0 }

        strip.select(1)
        XCTAssertNil(selected)
        strip.select(2)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 3))
        XCTAssertEqual(changed?.date, selected)
    }

    func testCalendarStripRejectsDatesOutsideBounds() {
        var selected: Date?
        let strip = UPCalendarStrip(
            dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2), Date(timeIntervalSince1970: 3)],
            modelValue: Binding(get: { selected }, set: { selected = $0 }),
            minDate: Date(timeIntervalSince1970: 2),
            maxDate: Date(timeIntervalSince1970: 2)
        )

        strip.select(0)
        XCTAssertNil(selected)
        strip.select(1)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 2))
        strip.select(2)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 2))
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

    func testCouponMapsDisplayPropsAndSuppressesDisabledClick() {
        var clicks = 0
        let coupon = UPCoupon(amount: "20", unit: "¥", limit: "满100可用", title: "满减券",
                              desc: "全场通用", time: "2026-08-31", actionText: "使用", disabled: true)
            .onClick { clicks += 1 }

        coupon.click()
        XCTAssertEqual(clicks, 0)
        XCTAssertEqual(coupon.amount, "20")
        XCTAssertEqual(coupon.limit, "满100可用")
        _ = UPCoupon()
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

    func testGoodsSkuRejectsUnavailableCombinationAndBindsQuantity() {
        var quantity = 1
        let sku = UPGoodsSku(
            options: [
                UPGoodsSkuOption(name: "Color", values: ["Red", "Blue"]),
                UPGoodsSkuOption(name: "Size", values: ["S", "M"])
            ],
            combinations: [
                UPGoodsSkuCombination(selections: ["Color": "Red", "Size": "S"], stock: 2)
            ],
            quantity: Binding(get: { quantity }, set: { quantity = $0 }),
            maxBuy: 5
        )

        XCTAssertTrue(sku.isDisabled("Color", value: "Blue"))
        sku.select("Color", value: "Red")
        sku.select("Size", value: "S")
        XCTAssertTrue(sku.setQuantity(3) == false)
        XCTAssertEqual(quantity, 1)
        XCTAssertTrue(sku.setQuantity(2))
        XCTAssertEqual(quantity, 2)
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

    func testCateTabBindsCurrentAndEmitsStructuredChange() {
        var current = 0
        var change: UPCateTabChange?
        let tabs = UPCateTab(items: ["全部", "数码"], current: Binding(get: { current }, set: { current = $0 }))
            .onChangePayload { change = $0 }

        tabs.select(1)
        XCTAssertEqual(current, 1)
        XCTAssertEqual(change?.index, 1)
        XCTAssertEqual(change?.item.value, "数码")
    }

    func testTreeExpandsAndSelectsRecursiveNode() {
        let tree = UPTree(nodes: [UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "child", title: "Child")])])
        tree.toggle("root")
        XCTAssertTrue(tree.isExpanded("root"))
        tree.select("child")
        XCTAssertEqual(tree.selectedIDs, ["child"])
    }

    func testTreeSupportsDisabledMultipleSelectionAndCheckEvents() {
        var selected: [String] = []
        var checkedIDs: Set<String> = []
        var checked: (String, Bool)?
        var expansionEvents: [String] = []
        let tree = UPTree(
            nodes: [
                UPTreeNode(id: "root", title: "Root", children: [
                    UPTreeNode(id: "a", title: "A"),
                    UPTreeNode(id: "b", title: "B", disabled: true)
                ])
            ],
            multiple: true,
            selectedIDs: Binding(get: { selected }, set: { selected = $0 }),
            checkedIDs: Binding(get: { checkedIDs }, set: { checkedIDs = $0 }),
            showCheckbox: true
        ).onCheckChange { node, value in checked = (node.id, value) }
            .onExpand { expansionEvents.append("expand:\($0.id)") }
            .onCollapse { expansionEvents.append("collapse:\($0.id)") }

        tree.select("a")
        tree.select("root")
        XCTAssertEqual(selected, ["a", "root"])
        tree.select("b")
        XCTAssertEqual(selected, ["a", "root"])
        tree.check("a", checked: true)
        XCTAssertEqual(checked?.0, "a")
        XCTAssertEqual(checked?.1, true)
        XCTAssertEqual(checkedIDs, ["a"])
        tree.toggle("root")
        tree.toggle("root")
        XCTAssertEqual(expansionEvents, ["expand:root", "collapse:root"])
    }
}
