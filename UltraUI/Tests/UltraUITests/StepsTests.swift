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
}
