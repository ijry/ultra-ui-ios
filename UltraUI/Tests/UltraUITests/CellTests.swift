import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CellTests: XCTestCase {
    func testDefaultsMatchUviewPlusCell() {
        let cell = UPCell()

        XCTAssertEqual(cell.title, "")
        XCTAssertEqual(cell.label, "")
        XCTAssertEqual(cell.value, "")
        XCTAssertEqual(cell.icon, "")
        XCTAssertFalse(cell.disabled)
        XCTAssertTrue(cell.border)
        XCTAssertFalse(cell.center)
        XCTAssertEqual(cell.url, "")
        XCTAssertEqual(cell.linkType, "navigateTo")
        XCTAssertFalse(cell.clickable)
        XCTAssertFalse(cell.isLink)
        XCTAssertFalse(cell.required)
        XCTAssertEqual(cell.rightIcon, "arrow-right")
        XCTAssertEqual(cell.arrowDirection, "")
        XCTAssertEqual(cell.iconStyle, UPStyle())
        XCTAssertEqual(cell.rightIconStyle, UPStyle())
        XCTAssertEqual(cell.titleStyle, UPStyle())
        XCTAssertEqual(cell.size, "")
        XCTAssertTrue(cell.stop)
        XCTAssertEqual(cell.name, "")
        XCTAssertFalse(cell.effectiveClickable)
        XCTAssertFalse(cell.showsRightIcon)
        XCTAssertFalse(cell.hasVisibleValue)
    }

    func testTextAndNamePropsAcceptStringAndNumberInputs() {
        let cell = UPCell(
            title: 42,
            label: 3.5,
            value: 0,
            isLink: true,
            arrowDirection: "down",
            size: "large",
            name: 7
        )

        XCTAssertEqual(cell.title, "42")
        XCTAssertEqual(cell.label, "3.5")
        XCTAssertEqual(cell.value, "0")
        XCTAssertEqual(cell.name, 7)
        XCTAssertTrue(cell.hasVisibleValue)
        XCTAssertTrue(cell.showsRightIcon)
        XCTAssertEqual(cell.resolvedTitleFontSize, 16)
        XCTAssertEqual(cell.resolvedLabelFontSize, 14)
        XCTAssertEqual(cell.resolvedValueFontSize, 15)
        XCTAssertEqual(cell.rightIconRotation, 90)
    }

    func testClickCallbackMirrorsTheUpstreamNamePayloadAndDisabledSuppressesIt() {
        var receivedName: UPCellName?
        let enabled = UPCell(name: "settings", onClick: { receivedName = $0 })
        let disabled = UPCell(disabled: true, name: "blocked", onClick: { receivedName = $0 })

        enabled.triggerClick()
        XCTAssertEqual(receivedName, "settings")

        disabled.triggerClick()
        XCTAssertEqual(receivedName, "settings")
    }

    func testNamedSlotsAndCustomStylesRemainOnTheCompatibilitySurface() {
        let style = UPStyle(["color": "#2979ff", "marginTop": "8px"])
        let cell = UPCell(
            title: "Title",
            iconStyle: style,
            rightIconStyle: style,
            titleStyle: style,
            customStyle: style
        )
        .icon {
            Image(systemName: "star.fill")
        }
        .title {
            Text("Custom title")
        }
        .label {
            Text("Custom label")
        }
        .value {
            Text("Custom value")
        }
        .rightIcon {
            Image(systemName: "chevron.right")
        }
        .righticon {
            Image(systemName: "ellipsis")
        }

        XCTAssertEqual(cell.iconStyle, style)
        XCTAssertEqual(cell.rightIconStyle, style)
        XCTAssertEqual(cell.titleStyle, style)
        XCTAssertEqual(cell.customStyle, style)
        XCTAssertTrue(cell.hasIconSlot)
        XCTAssertTrue(cell.hasTitleSlot)
        XCTAssertTrue(cell.hasLabelSlot)
        XCTAssertTrue(cell.hasValueSlot)
        XCTAssertTrue(cell.hasRightIconSlot)
        XCTAssertTrue(cell.hasLegacyRightIconSlot)
    }

    func testArrowDirectionUsesNativeEquivalentOrientation() {
        XCTAssertEqual(UPCell(arrowDirection: "").rightIconRotation, 0)
        XCTAssertEqual(UPCell(arrowDirection: "up").rightIconRotation, -90)
        XCTAssertEqual(UPCell(arrowDirection: "down").rightIconRotation, 90)
        XCTAssertEqual(UPCell(arrowDirection: "left").rightIconRotation, 180)
        XCTAssertEqual(UPCell(arrowDirection: "unsupported").rightIconRotation, 0)
    }
}
