import SwiftUI
import XCTest
@testable import UltraUI

@MainActor final class StepsTests: XCTestCase {
    func testStepsDefaultsAndStateResolution() {
        let steps = UPSteps { EmptyView() }
        XCTAssertEqual(steps.direction, "row"); XCTAssertEqual(steps.current, 0)
        XCTAssertEqual(steps.activeColor, "#3c9cff"); XCTAssertEqual(steps.inactiveColor, "#969799"); XCTAssertFalse(steps.dot)
        XCTAssertEqual(steps.state(for: 0), .current); XCTAssertEqual(steps.state(for: 1), .pending)
        let progressed = UPSteps(current: 2) { EmptyView() }
        XCTAssertEqual(progressed.state(for: 0), .finished); XCTAssertEqual(progressed.state(for: 2), .current)
    }

    func testStepsItemPropsAndClick() {
        var clicked = false
        let item = UPStepsItem(title: "支付", desc: "等待支付", iconSize: "19px", error: true) { EmptyView() }.onClick { clicked = true }
        XCTAssertEqual(item.title, "支付"); XCTAssertEqual(item.desc, "等待支付"); XCTAssertEqual(item.resolvedIconSize, 19); XCTAssertTrue(item.error)
        item.triggerClick(); XCTAssertTrue(clicked)
    }

    func testStepsClampsNegativeCurrentAndResolvesTextMetadata() {
        let steps = UPSteps(current: -2) { EmptyView() }
        let item = UPStepsItem(title: "1", desc: "2", iconSize: "20px")

        XCTAssertEqual(steps.current, 0)
        XCTAssertEqual(steps.state(for: 0), .current)
        XCTAssertEqual(item.title, "1")
        XCTAssertEqual(item.desc, "2")
        XCTAssertEqual(item.resolvedIconSize, 20)
    }

    func testStepsAcceptsStringCurrentNumber() {
        let steps = UPSteps(current: "2") { EmptyView() }

        XCTAssertEqual(steps.current, 2)
    }

    /// 上游 `libs/config/props/steps.js` 与 `stepsItem.js` 的默认值。
    func testStepsPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.steps.direction, "row")
        XCTAssertEqual(UPConfig.steps.current, "0")
        XCTAssertEqual(UPConfig.steps.activeColor, "#3c9cff")
        XCTAssertEqual(UPConfig.steps.inactiveColor, "#969799")
        XCTAssertEqual(UPConfig.steps.activeIcon, "")
        XCTAssertEqual(UPConfig.steps.inactiveIcon, "")
        XCTAssertFalse(UPConfig.steps.dot)

        XCTAssertEqual(UPConfig.stepsItem.title, "")
        XCTAssertEqual(UPConfig.stepsItem.desc, "")
        XCTAssertEqual(UPConfig.stepsItem.iconSize, "17")
        XCTAssertFalse(UPConfig.stepsItem.error)
        // 上游 statusColor 的 error 分支取 libs/config/color.js 的 color.error。
        XCTAssertEqual(UPConfig.stepsItem.errorColor, "#f56c6c")

        let item = UPStepsItem()
        XCTAssertEqual(item.resolvedIconSize, 17)
        XCTAssertFalse(item.error)
        XCTAssertFalse(item.hasIconSlot)
        XCTAssertFalse(item.hasTitleSlot)
        XCTAssertFalse(item.hasDescSlot)
        XCTAssertFalse(item.hasContentSlot)
    }

    /// 上游 `statusClass`：当前项失败算 error，非当前项自身 error 也算 error。
    func testStepsStatusClassMatchesUpstream() {
        typealias Steps = UPSteps<EmptyView>
        XCTAssertEqual(Steps.status(index: 1, current: 1, error: false), .process)
        XCTAssertEqual(Steps.status(index: 1, current: 1, error: true), .error)
        XCTAssertEqual(Steps.status(index: 0, current: 1, error: false), .finish)
        XCTAssertEqual(Steps.status(index: 2, current: 1, error: false), .wait)
        // 照抄上游：非当前项只要自身 error 为真就一律算 error，哪怕已经 finish。
        XCTAssertEqual(Steps.status(index: 0, current: 2, error: true), .error)

        let steps = UPSteps(current: 1) { EmptyView() }
        XCTAssertEqual(steps.status(for: 1), .process)
        XCTAssertEqual(steps.status(for: 0), .finish)
        XCTAssertEqual(steps.status(for: 1, error: true), .error)
    }

    /// 上游 `statusColor`：finish → activeColor、error → color.error、
    /// process → dot 时 activeColor 否则 transparent、wait → inactiveColor。
    func testStepsStatusColorMatchesUpstream() {
        let steps = UPSteps(current: 1) { EmptyView() }
        XCTAssertEqual(steps.statusColor(for: 0), "#3c9cff")
        XCTAssertEqual(steps.statusColor(for: 2), "#969799")
        XCTAssertEqual(steps.statusColor(for: 1, error: true), "#f56c6c")
        // 非 dot 模式下 process 是透明的（底色由 activeColor 填充）。
        XCTAssertEqual(steps.statusColor(for: 1), "transparent")

        let dotted = UPSteps(current: 1, dot: true) { EmptyView() }
        XCTAssertEqual(dotted.statusColor(for: 1), "#3c9cff")
    }

    /// 上游 `lineStyle.backgroundColor` 看的是**下一个**兄弟的 `error`。
    func testStepsLineColorLooksAtNextSiblingError() {
        let steps = UPSteps(current: 2) { EmptyView() }
        // index 0 已完成，下一个正常 → activeColor。
        XCTAssertEqual(steps.lineColor(for: 0, childErrors: [false, false, false]), "#3c9cff")
        // 下一个失败 → 整条线变红，哪怕自己已完成。
        XCTAssertEqual(steps.lineColor(for: 0, childErrors: [false, true, false]), "#f56c6c")
        // 未到达的线用 inactiveColor。
        XCTAssertEqual(steps.lineColor(for: 2, childErrors: [false, false, false, false]), "#969799")
        // 自己失败但下一个正常时线不变红。
        XCTAssertEqual(steps.lineColor(for: 0, childErrors: [true, false]), "#3c9cff")
    }

    /// 上游 `contentStyle`：dot 模式两个方向都是 2px，非 dot 是 6px。
    func testStepsItemContentSpacingFollowsDotMode() {
        XCTAssertEqual(UPConfig.stepsItem.dotContentSpacing, 2)
        XCTAssertEqual(UPConfig.stepsItem.circleContentSpacing, 6)
        // 未挂进 u-steps 时退回占位数据（dot 为 false）。
        XCTAssertEqual(UPStepsItem().contentSpacing, 6)
    }

    func testStepsItemExposesAllUpstreamSlots() {
        let plain = UPStepsItem(title: "支付")
        let slotted = plain
            .icon { Text("icon") }
            .titleContent { Text("title") }
            .descContent { Text("desc") }
            .stepContent { index in Text("\(index)") }
        XCTAssertTrue(slotted.hasIconSlot)
        XCTAssertTrue(slotted.hasTitleSlot)
        XCTAssertTrue(slotted.hasDescSlot)
        XCTAssertTrue(slotted.hasContentSlot)
    }
}
