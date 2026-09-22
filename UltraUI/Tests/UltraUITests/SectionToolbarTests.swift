import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SectionToolbarTests: XCTestCase {
    func testSectionDefaultsAndClick() {
        var clicks = 0
        let section = UPSection().onClick { clicks += 1 }

        XCTAssertEqual(section.title, "")
        XCTAssertEqual(section.subTitle, "更多")
        XCTAssertTrue(section.right)
        XCTAssertEqual(section.fontSize, 15)
        XCTAssertTrue(section.bold)
        XCTAssertTrue(section.showLine)
        XCTAssertTrue(section.arrow)
        section.triggerClick()
        XCTAssertEqual(clicks, 1)
    }

    func testToolbarDefaultsAndEvents() {
        var events: [String] = []
        let toolbar = UPToolbar(title: "选择")
            .onCancel { events.append("cancel") }
            .onConfirm { events.append("confirm") }

        XCTAssertTrue(toolbar.show)
        XCTAssertEqual(toolbar.cancelText, "取消")
        XCTAssertEqual(toolbar.confirmText, "确定")
        toolbar.triggerCancel()
        toolbar.triggerConfirm()
        XCTAssertEqual(events, ["cancel", "confirm"])
    }
}
