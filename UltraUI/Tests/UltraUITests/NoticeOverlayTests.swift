import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class NoticeComponentsTests: XCTestCase {
    func testNoticeItemsAndNoticeBarExposeUpstreamEvents() {
        var clicked: [String] = []
        let column = UPColumnNotice(notices: ["one", "two"], current: 0)
            .onClick { clicked.append($0) }
        XCTAssertEqual(column.current, 0)
        column.select(1)
        column.click("two")
        XCTAssertEqual(column.current, 1)
        XCTAssertEqual(clicked, ["two"])

        var closed = 0
        let bar = UPNoticeBar(text: "hello", closable: true)
            .onClose { closed += 1 }
        bar.close()
        XCTAssertTrue(bar.isClosed)
        XCTAssertEqual(closed, 1)
    }

    func testNotifyAndPopoverTrackPresentationAndActions() {
        var opened = 0
        var closed = 0
        let notify = UPNotify(show: false, message: "Saved")
            .onOpen { opened += 1 }
            .onClose { closed += 1 }
        notify.open()
        notify.close()
        XCTAssertFalse(notify.show)
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(closed, 1)

        var dismissed = 0
        let popover = UPPopover(show: true, placement: "bottom", closeOnClickOutside: true)
            .onClose { dismissed += 1 }
        popover.dismiss()
        XCTAssertFalse(popover.show)
        XCTAssertEqual(dismissed, 1)
    }
}

@MainActor
final class GuideFloatAgreementTests: XCTestCase {
    func testGuideAdvancesAndFloatButtonEmitsItemSelection() {
        let guide = UPGuide(steps: [UPGuideStep(id: "first"), UPGuideStep(id: "second")])
        XCTAssertEqual(guide.current, 0)
        XCTAssertTrue(guide.next())
        XCTAssertEqual(guide.current, 1)
        XCTAssertFalse(guide.next())
        guide.previous()
        XCTAssertEqual(guide.current, 0)

        var selected = ""
        let button = UPFloatButton(items: [UPFloatButtonItem(id: "add", title: "Add")])
            .onItemClick { selected = $0.id }
        button.toggle()
        button.select("add")
        XCTAssertTrue(button.expanded)
        XCTAssertEqual(selected, "add")
    }

    func testAgreementBindingAndChangeEvent() {
        var checked = false
        var eventValue = false
        let agreement = UPAgreement(checked: Binding(get: { checked }, set: { checked = $0 }))
            .onChange { eventValue = $0 }
        agreement.toggle()
        XCTAssertTrue(checked)
        XCTAssertTrue(eventValue)
        XCTAssertEqual(agreement.displayText, "我已阅读并同意")
    }
}

@MainActor
final class TooltipComponentsTests: XCTestCase {
    func testTooltipAndRowNoticeExposeVisibilityAndSelection() {
        let tooltip = UPTooltip(text: "More", show: false)
        tooltip.showTooltip()
        XCTAssertTrue(tooltip.show)
        tooltip.hideTooltip()
        XCTAssertFalse(tooltip.show)

        var selected = -1
        let row = UPRowNotice(notices: ["A", "B"]).onClick { selected = $0 }
        row.select(1)
        XCTAssertEqual(row.current, 1)
        XCTAssertEqual(selected, 1)
    }
}
