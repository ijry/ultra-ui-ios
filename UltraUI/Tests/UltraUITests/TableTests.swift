import SwiftUI
import XCTest
@testable import UltraUI

@MainActor final class TableTests: XCTestCase {
    func testLegacyTableDefaultsMatchUpstream() {
        let table = UPTable { EmptyView() }
        XCTAssertEqual(table.borderColor, "#e4e7ed"); XCTAssertEqual(table.align, "center")
        XCTAssertEqual(table.padding, "5px 3px"); XCTAssertEqual(table.fontSize, "14px")
        XCTAssertEqual(table.color, "#606266"); XCTAssertEqual(table.bgColor, "#ffffff")
        XCTAssertEqual(UPTh(width: "30%") { Text("Name") }.width, "30%")
        let cell = UPTd(width: "120px", textAlign: "right", fontSize: "13px") { Text("1") }
        XCTAssertEqual(cell.width, "120px"); XCTAssertEqual(cell.textAlign, "right")
        _ = UPTr { EmptyView() }
    }

    /// 上游 u-th 在 mounted 时把父表的 align/padding/borderColor/thStyle 合并进自身。
    func testHeaderCellInheritsTheParentTableStyle() {
        let parent = UPTableStyleContext(
            borderColor: "#111111",
            align: "right",
            padding: "8px 4px",
            fontSize: "16px",
            color: "#222222",
            thStyle: UPStyle()
        )

        let resolved = UPTh<EmptyView>.resolvedStyle(width: "", parent: parent)

        XCTAssertEqual(resolved.align, "right")
        XCTAssertEqual(resolved.padding, "8px 4px")
        XCTAssertEqual(resolved.borderColor, "#111111")
        XCTAssertNil(resolved.fixedWidth)
    }

    /// 上游 `if (this.width) style.flex = '0 0 <width>'`：空串才自适应。
    func testHeaderCellWidthPinsTheColumnOnlyWhenSet() {
        let parent = UPTableStyleContext()

        XCTAssertNil(UPTh<EmptyView>.resolvedStyle(width: "", parent: parent).fixedWidth)
        XCTAssertEqual(
            UPTh<EmptyView>.resolvedStyle(width: "120px", parent: parent).fixedWidth,
            120
        )
    }

    /// 上游 u-td 先继承父表，再用非空的自身 props 覆盖。
    func testBodyCellInheritsParentThenSelfPropsOverride() {
        let parent = UPTableStyleContext(
            borderColor: "#111111",
            align: "center",
            padding: "8px 4px",
            fontSize: "16px",
            color: "#222222"
        )

        let inherited = UPTd<EmptyView>.resolvedStyle(
            width: "auto", textAlign: "", fontSize: "", borderColor: "", color: "", parent: parent
        )
        XCTAssertEqual(inherited.align, "center")
        XCTAssertEqual(inherited.fontSize, 16)
        XCTAssertEqual(inherited.color, "#222222")
        XCTAssertEqual(inherited.borderColor, "#111111")
        XCTAssertEqual(inherited.padding, "8px 4px")

        let overridden = UPTd<EmptyView>.resolvedStyle(
            width: "auto",
            textAlign: "right",
            fontSize: "13px",
            borderColor: "#333333",
            color: "#444444",
            parent: parent
        )
        XCTAssertEqual(overridden.align, "right")
        XCTAssertEqual(overridden.fontSize, 13)
        XCTAssertEqual(overridden.borderColor, "#333333")
        XCTAssertEqual(overridden.color, "#444444")
        // padding 没有自身 prop，始终继承父表。
        XCTAssertEqual(overridden.padding, "8px 4px")
    }

    /// 上游 `if (this.width != "auto") style.flex = ...`：只有 "auto" 自适应。
    func testBodyCellWidthPinsTheColumnUnlessAuto() {
        let parent = UPTableStyleContext()

        XCTAssertNil(
            UPTd<EmptyView>.resolvedStyle(
                width: "auto", textAlign: "", fontSize: "", borderColor: "", color: "", parent: parent
            ).fixedWidth
        )
        XCTAssertEqual(
            UPTd<EmptyView>.resolvedStyle(
                width: "90px", textAlign: "", fontSize: "", borderColor: "", color: "", parent: parent
            ).fixedWidth,
            90
        )
    }

    /// 上游 padding 是 CSS 简写字符串，需要拆成纵横两个值。
    func testPaddingShorthandResolvesToVerticalAndHorizontalInsets() {
        XCTAssertEqual(UPTableStyleContext.insets("5px 3px").vertical, 5)
        XCTAssertEqual(UPTableStyleContext.insets("5px 3px").horizontal, 3)

        // 单值同时作用于四边。
        XCTAssertEqual(UPTableStyleContext.insets("6px").vertical, 6)
        XCTAssertEqual(UPTableStyleContext.insets("6px").horizontal, 6)

        // 空串回落到上游默认的 5px 3px。
        XCTAssertEqual(UPTableStyleContext.insets("").vertical, 5)
        XCTAssertEqual(UPTableStyleContext.insets("").horizontal, 3)
    }

    /// 没有父表时（单独使用），落到上游默认值而不是崩溃或全零。
    func testCellsFallBackToUpstreamDefaultsWithoutAParentTable() {
        let resolved = UPTd<EmptyView>.resolvedStyle(
            width: "auto", textAlign: "", fontSize: "", borderColor: "", color: "", parent: nil
        )

        XCTAssertEqual(resolved.align, "center")
        XCTAssertEqual(resolved.fontSize, 14)
        XCTAssertEqual(resolved.color, "#606266")
        XCTAssertEqual(resolved.borderColor, "#e4e7ed")
    }

    /// 表格下发给子单元格的上下文必须逐项对应自身 props，否则继承会静默错配。
    func testTablePublishesItsOwnPropsAsTheCellContext() {
        let table = UPTable(
            borderColor: "#111111",
            align: "right",
            padding: "8px 4px",
            fontSize: "16px",
            color: "#222222",
            bgColor: "#333333"
        ) { EmptyView() }

        let context = table.styleContext

        XCTAssertEqual(context.borderColor, "#111111")
        XCTAssertEqual(context.align, "right")
        XCTAssertEqual(context.padding, "8px 4px")
        XCTAssertEqual(context.fontSize, "16px")
        XCTAssertEqual(context.color, "#222222")

        // 单元格从这份上下文解析出的结果应与直接构造一致。
        XCTAssertEqual(
            UPTd<EmptyView>.resolvedStyle(
                width: "auto", textAlign: "", fontSize: "", borderColor: "", color: "",
                parent: context
            ).align,
            "right"
        )
    }

    func testTable2SortSelectionAndFlattenedTreeRows() {
        let child = UPTableRow(id: "child", values: ["name": "Child", "score": "3"])
        let parent = UPTableRow(id: "parent", values: ["name": "Parent", "score": "8"], children: [child])
        let other = UPTableRow(id: "other", values: ["name": "Other", "score": "5"])
        let columns = [UPTableColumn(key: "name", title: "Name", sortable: true), UPTableColumn(key: "score", title: "Score", align: "right", sortable: true)]
        var selected = Set<String>()
        let table = UPTable2(data: [parent, other], columns: columns, selectedKeys: Binding(get: { selected }, set: { selected = $0 }))
        XCTAssertEqual(table.sortedRows(key: "score", ascending: true).map(\.id), ["other", "parent"])
        XCTAssertEqual(table.flattenedRows(expandedKeys: ["parent"]).map(\.row.id), ["parent", "child", "other"])
        table.toggleSelection("parent"); XCTAssertEqual(selected, ["parent"])
        table.toggleSelection("parent"); XCTAssertTrue(selected.isEmpty)
    }

    func testTable2DefaultsAndRowClickPayload() {
        let row = UPTableRow(id: "1", values: ["name": "Ada"]); var clicked: UPTableRow?
        let table = UPTable2(data: [row], columns: [UPTableColumn(key: "name", title: "Name")]).onRowClick { clicked = $0 }
        XCTAssertTrue(table.showHeader); XCTAssertTrue(table.border); XCTAssertEqual(table.rowKey, "id")
        table.triggerRowClick(row); XCTAssertEqual(clicked, row)
    }
}
