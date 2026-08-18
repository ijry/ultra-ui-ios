import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class UPBoxTests: XCTestCase {
    func testDefaultsMirrorUviewPlusBox() {
        let box = UPBox()

        XCTAssertEqual(box.bgColors, ["#EEFCFF", "#FCF8FF", "#FDF8F2"])
        XCTAssertEqual(box.height, "160px")
        XCTAssertEqual(box.borderRadius, "6px")
        XCTAssertEqual(box.gap, "15px")
        XCTAssertEqual(box.leftIcon, "")
        XCTAssertEqual(box.leftTitle, "左")
        XCTAssertEqual(box.rightTopIcon, "")
        XCTAssertEqual(box.rightTopTitle, "右上")
        XCTAssertEqual(box.rightBottomIcon, "")
        XCTAssertEqual(box.rightBottomTitle, "右下")
        XCTAssertEqual(box.customClass, "")
        XCTAssertEqual(box.customStyle, UPStyle())
        XCTAssertFalse(box.hasLeftSlot)
        XCTAssertFalse(box.hasRightTopSlot)
        XCTAssertFalse(box.hasRightBottomSlot)
    }

    func testStringAndNumericDimensionPropsNormalizeLikeUpstreamUnits() {
        let style = UPStyle(["padding": "4px"])
        let box = UPBox(
            bgColors: ["primary", "#ffffff", "success"],
            height: 200,
            borderRadius: 12.5,
            gap: "8px",
            leftIcon: "star",
            leftTitle: 42,
            rightTopIcon: "arrow-up",
            rightTopTitle: 3.5,
            rightBottomIcon: "arrow-down",
            rightBottomTitle: true,
            customClass: "dashboard-box",
            customStyle: style
        )

        XCTAssertEqual(box.bgColors, ["primary", "#ffffff", "success"])
        XCTAssertEqual(box.height, "200")
        XCTAssertEqual(box.borderRadius, "12.5")
        XCTAssertEqual(box.gap, "8px")
        XCTAssertEqual(box.leftTitle, "42")
        XCTAssertEqual(box.rightTopTitle, "3.5")
        XCTAssertEqual(box.rightBottomTitle, "true")
        XCTAssertEqual(box.resolvedHeight, 200, accuracy: 0.001)
        XCTAssertEqual(box.resolvedBorderRadius, 12.5, accuracy: 0.001)
        XCTAssertEqual(box.resolvedGap, 8, accuracy: 0.001)
        XCTAssertEqual(box.customClass, "dashboard-box")
        XCTAssertEqual(box.customStyle, style)
    }

    func testColorsAreAlwaysAvailableForTheThreeNativePanels() {
        XCTAssertEqual(
            UPBox.normalizedColors(["red"]),
            ["red", "#FCF8FF", "#FDF8F2"]
        )
        XCTAssertEqual(
            UPBox.normalizedColors(["red", "green", "blue", "ignored"]),
            ["red", "green", "blue"]
        )
        XCTAssertEqual(
            UPBox.normalizedColors([]),
            ["#EEFCFF", "#FCF8FF", "#FDF8F2"]
        )
    }

    func testNamedSlotsAreRetainedIndependently() {
        let box = UPBox(
            left: { Text("Left") },
            rightTop: { Text("Top") },
            rightBottom: { Text("Bottom") }
        )

        XCTAssertTrue(box.hasLeftSlot)
        XCTAssertTrue(box.hasRightTopSlot)
        XCTAssertTrue(box.hasRightBottomSlot)
    }

    func testEachNamedSlotCanBeProvidedIndependently() {
        let leftOnly = UPBox(left: { Text("Left") })
        let topOnly = UPBox(rightTop: { Text("Top") })
        let bottomOnly = UPBox(rightBottom: { Text("Bottom") })

        XCTAssertTrue(leftOnly.hasLeftSlot)
        XCTAssertFalse(leftOnly.hasRightTopSlot)
        XCTAssertFalse(leftOnly.hasRightBottomSlot)
        XCTAssertFalse(topOnly.hasLeftSlot)
        XCTAssertTrue(topOnly.hasRightTopSlot)
        XCTAssertFalse(topOnly.hasRightBottomSlot)
        XCTAssertFalse(bottomOnly.hasLeftSlot)
        XCTAssertFalse(bottomOnly.hasRightTopSlot)
        XCTAssertTrue(bottomOnly.hasRightBottomSlot)
    }

    func testNamedSlotPairsPreserveDefaultContentForTheUnspecifiedPanel() {
        let leftAndTop = UPBox(left: { Text("Left") }, rightTop: { Text("Top") })
        let leftAndBottom = UPBox(left: { Text("Left") }, rightBottom: { Text("Bottom") })
        let topAndBottom = UPBox(rightTop: { Text("Top") }, rightBottom: { Text("Bottom") })

        XCTAssertTrue(leftAndTop.hasLeftSlot)
        XCTAssertTrue(leftAndTop.hasRightTopSlot)
        XCTAssertFalse(leftAndTop.hasRightBottomSlot)
        XCTAssertTrue(leftAndBottom.hasLeftSlot)
        XCTAssertFalse(leftAndBottom.hasRightTopSlot)
        XCTAssertTrue(leftAndBottom.hasRightBottomSlot)
        XCTAssertFalse(topAndBottom.hasLeftSlot)
        XCTAssertTrue(topAndBottom.hasRightTopSlot)
        XCTAssertTrue(topAndBottom.hasRightBottomSlot)
    }

    #if os(macOS)
    func testBoxCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPBox(
                height: "120px",
                gap: "6px",
                left: { Text("Left") },
                rightTop: { Text("Top") },
                rightBottom: { Text("Bottom") }
            )
            .frame(width: 260, height: 120)
        )

        XCTAssertEqual(renderer.cgImage?.width, 260)
        XCTAssertEqual(renderer.cgImage?.height, 120)
    }
    #endif
}
