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
        let bar = UPNoticeBar(text: "hello", mode: "closable")
            .onClose { closed += 1 }
        bar.close()
        XCTAssertTrue(bar.isClosed)
        XCTAssertEqual(closed, 1)
    }

    /// 上游没有 `closable` prop，关闭图标由 `mode == "closable"` 驱动。
    func testCloseRequiresClosableMode() {
        var closed = 0
        let plain = UPNoticeBar(text: "hello").onClose { closed += 1 }
        plain.close()
        XCTAssertFalse(plain.isClosed)
        XCTAssertEqual(closed, 0)

        XCTAssertFalse(UPNoticeBar(text: "hello").showsCloseIcon)
        XCTAssertTrue(UPNoticeBar(text: "hello", mode: "closable").showsCloseIcon)
        XCTAssertFalse(UPNoticeBar(text: "hello", mode: "link").showsCloseIcon)
        XCTAssertTrue(UPNoticeBar(text: "hello", mode: "link").showsLinkIcon)
        XCTAssertFalse(UPNoticeBar(text: "hello", mode: "closable").showsLinkIcon)
    }

    /// 上游 `click` 事件带当前索引。
    func testNoticeBarClickCarriesTheCurrentIndex() {
        var indexes: [Int] = []
        let bar = UPNoticeBar(text: ["一", "二"]).onClick { indexes.append($0) }

        bar.click()
        bar.select(1)
        bar.click()

        XCTAssertEqual(indexes, [0, 1])
    }

    /// 上游按 `direction`/`step` 决定内部委派给 column 还是 row 子组件。
    func testDirectionAndStepChooseTheDelegateVariant() {
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "row", step: false), "row")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "row", step: true), "column")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "column", step: false), "column")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "unexpected", step: false), "row")
    }

    /// 上游 `u-notice-bar` 的 text 是 `Array | String`，单串按单条处理。
    func testTextAcceptsUpstreamArrayAndStringForms() {
        XCTAssertEqual(UPNoticeBar(text: "只有一条").texts, ["只有一条"])
        XCTAssertEqual(UPNoticeBar(text: ["一", "二"]).texts, ["一", "二"])
        XCTAssertEqual(UPNoticeBar(text: "").texts, [])
    }

    func testNoticeBarDefaultsMatchUpstream() {
        let bar = UPNoticeBar()

        XCTAssertEqual(bar.direction, "row")
        XCTAssertFalse(bar.step)
        XCTAssertEqual(bar.icon, "volume")
        XCTAssertEqual(bar.mode, "")
        XCTAssertEqual(bar.color, "#f9ae3d")
        XCTAssertEqual(bar.bgColor, "#fdf6ec")
        XCTAssertEqual(bar.speed, 80)
        XCTAssertEqual(bar.fontSize, 14)
        XCTAssertEqual(bar.duration, 2000)
        XCTAssertTrue(bar.disableTouch)
        XCTAssertEqual(bar.url, "")
        XCTAssertEqual(bar.linkType, "navigateTo")
        XCTAssertEqual(bar.justifyContent, "flex-start")
    }

    /// column 的 duration 默认 1500，与 notice-bar 的 2000 不同；row 没有 duration。
    func testChildVariantDefaultsMatchUpstream() {
        let column = UPColumnNotice()
        XCTAssertEqual(column.duration, 1500)
        XCTAssertEqual(column.fontSize, 14)
        XCTAssertEqual(column.speed, 80)
        XCTAssertFalse(column.step)
        XCTAssertEqual(column.justifyContent, "flex-start")

        let row = UPRowNotice()
        XCTAssertEqual(row.fontSize, 14)
        XCTAssertEqual(row.speed, 80)
        XCTAssertEqual(row.icon, "volume")
        XCTAssertEqual(row.color, "#f9ae3d")
        XCTAssertEqual(row.bgColor, "#fdf6ec")
    }

    /// 无参 `onClick` 是旧拼写，与带索引的新拼写重载共存，两者都要能触发。
    func testLegacyNoPayloadClickModifierStillFires() {
        var legacyCalls = 0
        let legacy = UPNoticeBar(text: "hello").onClick { legacyCalls += 1 }
        legacy.click()
        XCTAssertEqual(legacyCalls, 1)

        var indexes: [Int] = []
        let indexed = UPNoticeBar(text: "hello").onClick { (index: Int) in indexes.append(index) }
        indexed.click()
        XCTAssertEqual(indexes, [0])
    }

    /// 旧 `notices:`/`interval:` 初始化器保留，用于源兼容。
    func testLegacyInitializersRemainAvailable() {
        let column = UPColumnNotice(notices: ["一", "二"], current: 1, interval: 5_000)
        XCTAssertEqual(column.texts, ["一", "二"])
        XCTAssertEqual(column.current, 1)
        XCTAssertEqual(column.duration, 5_000)

        let row = UPRowNotice(notices: ["A", "B"])
        XCTAssertEqual(row.notices, ["A", "B"])
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
