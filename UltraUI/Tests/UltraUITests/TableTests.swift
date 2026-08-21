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
