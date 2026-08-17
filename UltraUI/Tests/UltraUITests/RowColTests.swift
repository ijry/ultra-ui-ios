import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class RowColTests: XCTestCase {
    func testDefaultsMatchUviewPlusRowAndCol() {
        let row = UPRow()
        XCTAssertEqual(row.gutter, "0")
        XCTAssertEqual(row.justify, "start")
        XCTAssertEqual(row.align, "center")
        XCTAssertEqual(row.customClass, "")
        XCTAssertEqual(row.customStyle, UPStyle())
        XCTAssertEqual(row.resolvedGutter, 0)
        XCTAssertEqual(row.resolvedJustify, "flex-start")
        XCTAssertEqual(row.resolvedAlign, "center")

        let col = UPCol()
        XCTAssertEqual(col.span, "12")
        XCTAssertEqual(col.offset, "0")
        XCTAssertEqual(col.justify, "start")
        XCTAssertEqual(col.align, "stretch")
        XCTAssertEqual(col.textAlign, "left")
        XCTAssertEqual(col.customClass, "")
        XCTAssertEqual(col.customStyle, UPStyle())
        XCTAssertEqual(col.resolvedSpan, 12)
        XCTAssertEqual(col.resolvedOffset, 0)
        XCTAssertEqual(col.resolvedJustify, "flex-start")
        XCTAssertEqual(col.resolvedAlign, "stretch")
        XCTAssertEqual(col.resolvedTextAlignment, .leading)
    }

    func testStringAndNumberLayoutPropsNormalizeIndependently() {
        let style = UPStyle(["margin-top": "8px"])
        let row = UPRow(
            gutter: "24rpx",
            justify: "between",
            align: "bottom",
            customClass: "toolbar-row",
            customStyle: style
        ) {
            Text("row")
        }

        XCTAssertEqual(row.gutter, "24rpx")
        XCTAssertEqual(row.resolvedGutter, 24)
        XCTAssertEqual(row.resolvedJustify, "space-between")
        XCTAssertEqual(row.resolvedAlign, "flex-end")
        XCTAssertEqual(row.customClass, "toolbar-row")
        XCTAssertEqual(row.customStyle, style)

        let col = UPCol(
            span: 3,
            offset: "2",
            justify: "end",
            align: "top",
            textAlign: "center",
            customClass: "toolbar-col",
            customStyle: style
        ) {
            Text("col")
        }

        XCTAssertEqual(col.span, "3")
        XCTAssertEqual(col.offset, "2")
        XCTAssertEqual(col.resolvedSpan, 3)
        XCTAssertEqual(col.resolvedOffset, 2)
        XCTAssertEqual(col.resolvedJustify, "flex-end")
        XCTAssertEqual(col.resolvedAlign, "flex-start")
        XCTAssertEqual(col.resolvedTextAlignment, .center)
        XCTAssertEqual(col.customClass, "toolbar-col")
        XCTAssertEqual(col.customStyle, style)
    }

    func testGridMetricsUseTwelveColumnsAndHalfGutterPadding() {
        let metrics = UPGridItemMetrics(
            containerWidth: 360,
            span: 3,
            offset: 1,
            gutter: 20
        )

        XCTAssertEqual(metrics.spanWidth, 90, accuracy: 0.001)
        XCTAssertEqual(metrics.offsetWidth, 30, accuracy: 0.001)
        XCTAssertEqual(metrics.contentWidth, 70, accuracy: 0.001)
        XCTAssertEqual(metrics.leadingPadding, 10, accuracy: 0.001)
        XCTAssertEqual(metrics.trailingPadding, 10, accuracy: 0.001)

        let row = UPRow(gutter: 20)
        XCTAssertEqual(row.resolvedHorizontalMargin, -10, accuracy: 0.001)
    }

    func testJustifyAndAlignAliasesMapToNativeFlexValues() {
        XCTAssertEqual(UPRow(justify: "start").resolvedJustify, "flex-start")
        XCTAssertEqual(UPRow(justify: "flex-start").resolvedJustify, "flex-start")
        XCTAssertEqual(UPRow(justify: "end").resolvedJustify, "flex-end")
        XCTAssertEqual(UPRow(justify: "flex-end").resolvedJustify, "flex-end")
        XCTAssertEqual(UPRow(justify: "around").resolvedJustify, "space-around")
        XCTAssertEqual(UPRow(justify: "space-around").resolvedJustify, "space-around")
        XCTAssertEqual(UPRow(justify: "between").resolvedJustify, "space-between")
        XCTAssertEqual(UPRow(justify: "space-between").resolvedJustify, "space-between")

        XCTAssertEqual(UPRow(align: "top").resolvedAlign, "flex-start")
        XCTAssertEqual(UPRow(align: "center").resolvedAlign, "center")
        XCTAssertEqual(UPRow(align: "bottom").resolvedAlign, "flex-end")
        XCTAssertEqual(UPCol(align: "top").resolvedAlign, "flex-start")
        XCTAssertEqual(UPCol(align: "stretch").resolvedAlign, "stretch")
    }

    func testDefaultSlotInitializersAndClickModifiersRemainAvailable() {
        var rowClicked = false
        var colClicked = false

        let row = UPRow(onClick: { rowClicked = true }) {
            UPCol(span: 6, onClick: { colClicked = true }) {
                Text("content")
            }
        }
        let modifiedRow = UPRow { Text("content") }
            .onClick { rowClicked = true }
        let modifiedCol = UPCol { Text("content") }
            .onClick { colClicked = true }

        XCTAssertNotNil(row.onClick)
        XCTAssertNotNil(modifiedRow.onClick)
        XCTAssertNotNil(modifiedCol.onClick)
        XCTAssertFalse(rowClicked)
        XCTAssertFalse(colClicked)
    }

    func testColumnClickSuppressesTheNextRowClick() {
        var events: [String] = []
        let context = UPRowEventContext()

        context.handleColumnClick { events.append("column") }
        context.handleRowClick { events.append("row") }
        XCTAssertEqual(events, ["column"])

        context.handleRowClick { events.append("row") }
        XCTAssertEqual(events, ["column", "row"])
    }
}

#if os(macOS)
@MainActor
extension RowColTests {
    func testRowAndColCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPRow(gutter: 20) {
                UPCol(span: 6) { Color.red }
                UPCol(span: 6) { Color.blue }
            }
            .frame(width: 360, height: 80)
        )
        XCTAssertEqual(renderer.cgImage?.width, 360)
        XCTAssertEqual(renderer.cgImage?.height, 80)
    }
}
#endif
