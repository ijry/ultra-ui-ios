import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class GridTests: XCTestCase {
    func testDefaultsMirrorUviewPlusGridAndGridItem() {
        let grid = UPGrid()
        XCTAssertEqual(grid.col, "3")
        XCTAssertFalse(grid.border)
        XCTAssertEqual(grid.align, "left")
        XCTAssertEqual(grid.gap, "0px")
        XCTAssertEqual(grid.resolvedColumnCount, 3)
        XCTAssertEqual(grid.resolvedGap, 0, accuracy: 0.001)
        XCTAssertEqual(grid.resolvedAlignment, .leading)

        let item = UPGridItem()
        XCTAssertNil(item.name)
        XCTAssertEqual(item.bgColor, "transparent")
    }

    func testStringAndNumberPropsNormalizeAndPreserveUpstreamValues() {
        let grid = UPGrid(
            col: 4,
            border: true,
            align: "right",
            gap: "12rpx"
        )
        XCTAssertEqual(grid.col, "4")
        XCTAssertTrue(grid.border)
        XCTAssertEqual(grid.align, "right")
        XCTAssertEqual(grid.gap, "12rpx")
        XCTAssertEqual(grid.resolvedColumnCount, 4)
        XCTAssertEqual(grid.resolvedGap, 12, accuracy: 0.001)
        XCTAssertEqual(grid.resolvedAlignment, .trailing)

        let invalid = UPGrid(col: "0", align: "unsupported", gap: "bad")
        XCTAssertEqual(invalid.resolvedColumnCount, 3)
        XCTAssertEqual(invalid.resolvedAlignment, .leading)
        XCTAssertEqual(invalid.resolvedGap, 0, accuracy: 0.001)

        let item = UPGridItem(name: 42, bgColor: "#2979ff")
        XCTAssertEqual(item.name, .number(42))
        XCTAssertEqual(item.bgColor, "#2979ff")
    }

    func testLayoutMetricsUseColumnsAndGapForIncompleteRows() {
        let metrics = UPGridLayoutMetrics(
            containerWidth: 320,
            columns: 3,
            gap: 8,
            itemCount: 5
        )

        XCTAssertEqual(metrics.itemWidth, 101.333, accuracy: 0.001)
        XCTAssertEqual(metrics.rowCount, 2)
        XCTAssertEqual(metrics.lastRowItemCount, 2)
        XCTAssertEqual(metrics.lastRowLeadingOffset(for: .leading), 0, accuracy: 0.001)
        XCTAssertEqual(metrics.lastRowLeadingOffset(for: .center), 54.667, accuracy: 0.001)
        XCTAssertEqual(metrics.lastRowLeadingOffset(for: .trailing), 109.333, accuracy: 0.001)
    }

    func testAlignmentAndEventHelpersNormalizeAliases() {
        XCTAssertEqual(UPGrid(align: "left").resolvedAlignment, .leading)
        XCTAssertEqual(UPGrid(align: "center").resolvedAlignment, .center)
        XCTAssertEqual(UPGrid(align: "right").resolvedAlignment, .trailing)
        XCTAssertEqual(UPGrid(align: "unsupported").resolvedAlignment, .leading)

        var itemClicked: UPGridName?
        var gridClicked: UPGridName?
        UPGridEventContext.performClick(
            name: .string("home"),
            itemAction: { itemClicked = $0 },
            gridAction: { gridClicked = $0 }
        )
        XCTAssertEqual(itemClicked, .string("home"))
        XCTAssertEqual(gridClicked, .string("home"))

        itemClicked = nil
        gridClicked = nil
        UPGridEventContext.performClick(
            name: nil,
            itemAction: nil,
            gridAction: { gridClicked = $0 }
        )
        XCTAssertNil(itemClicked)
        XCTAssertNil(gridClicked)
    }

    func testFluentClickModifiersDoNotMutateOriginalValues() {
        let originalGrid = UPGrid()
        let configuredGrid = originalGrid.onClick { _ in }
        XCTAssertNil(originalGrid.onClickHandler)
        XCTAssertNotNil(configuredGrid.onClickHandler)

        let originalItem = UPGridItem(name: "one")
        let configuredItem = originalItem.onClick { _ in }
        XCTAssertNil(originalItem.onClickHandler)
        XCTAssertNotNil(configuredItem.onClickHandler)
    }

    #if os(macOS)
    func testGridCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPGrid(col: 2, border: true, gap: "8px") {
                UPGridItem(name: "one") {
                    Text("One")
                        .frame(height: 40)
                }
                UPGridItem(name: "two") {
                    Text("Two")
                        .frame(height: 40)
                }
            }
            .frame(width: 240, height: 100)
        )

        XCTAssertEqual(renderer.cgImage?.width, 240)
        XCTAssertEqual(renderer.cgImage?.height, 100)
    }
    #endif
}
