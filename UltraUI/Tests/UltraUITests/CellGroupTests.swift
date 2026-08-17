import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CellGroupTests: XCTestCase {
    func testDefaultsMatchUviewPlusCellGroup() {
        let group = UPCellGroup()

        XCTAssertEqual(group.customClass, "")
        XCTAssertEqual(group.title, "")
        XCTAssertTrue(group.border)
        XCTAssertEqual(group.customStyle, UPStyle())
        XCTAssertFalse(group.hasTitleSlot)
        XCTAssertTrue(group.showsTopBorder)
        XCTAssertEqual(group.resolvedTitleFontSize, 15)
        XCTAssertEqual(group.resolvedTitlePadding, UPInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
    }

    func testDefaultAndNamedTitleSlotsRemainOnTheCompatibilitySurface() {
        let style = UPStyle([
            "background-color": "#ffffff",
            "margin-top": "8px"
        ])
        let group = UPCellGroup(
            customClass: "settings-group",
            title: "Settings",
            border: false,
            customStyle: style
        ) {
            UPCell(title: "Account")
        }
        .title {
            Text("Custom settings title")
        }

        XCTAssertEqual(group.customClass, "settings-group")
        XCTAssertEqual(group.title, "Settings")
        XCTAssertFalse(group.border)
        XCTAssertEqual(group.customStyle, style)
        XCTAssertFalse(group.showsTopBorder)
        XCTAssertTrue(group.hasTitleSlot)
    }

    func testTitleSlotPreservesUpstreamTitleVisibilityCondition() {
        let titleSlotWithoutTitle = UPCellGroup()
            .title {
                Text("This slot is intentionally hidden")
            }
        let titledGroup = UPCellGroup(title: "Visible")
            .title {
                Text("This slot replaces the built-in title")
            }

        XCTAssertTrue(titleSlotWithoutTitle.hasTitleSlot)
        XCTAssertFalse(titleSlotWithoutTitle.showsTitle)
        XCTAssertTrue(titledGroup.hasTitleSlot)
        XCTAssertTrue(titledGroup.showsTitle)
    }

    func testEmptyAndDefaultContentInitializersAreAvailable() {
        _ = UPCellGroup()
        _ = UPCellGroup(title: "Preferences") {
            Text("A cell-like child")
        }
    }
}
