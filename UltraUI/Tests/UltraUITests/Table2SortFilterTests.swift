import SwiftUI
import XCTest
@testable import UltraUI

/// 上游 u-table2 的排序与过滤语义。这些断言刻意照抄上游行为，
/// 包括几处反直觉的地方，注释里标明原因。
@MainActor
final class Table2SortFilterTests: XCTestCase {
    private let columns = [
        UPTableColumn(key: "name", title: "姓名", sortable: true),
        UPTableColumn(key: "score", title: "分数", sortable: true)
    ]

    private var rows: [UPTableRow] {
        [
            UPTableRow(id: "a", values: ["name": "Ada", "score": "8"]),
            UPTableRow(id: "b", values: ["name": "Bob", "score": "5"]),
            UPTableRow(id: "c", values: ["name": "Cy", "score": "12"])
        ]
    }

    // MARK: - sortable 真值判断

    /// 上游 `!!column.sortable`：`'custom'` 是真值，会走本地排序，
    /// 没有 element-plus 那种「custom = 交给外部」的分支。
    func testCustomSortableStillSortsLocally() {
        let column = UPTableColumn(key: "score", title: "分数", sortable: "custom")
        XCTAssertTrue(UPTable2.isColumnSortable(column, tableSortable: false))

        let unset = UPTableColumn(key: "score", title: "分数")
        XCTAssertFalse(UPTable2.isColumnSortable(unset, tableSortable: false))
        // 列级未设时回落表级。
        XCTAssertTrue(UPTable2.isColumnSortable(unset, tableSortable: true))
        // 列级显式 false 覆盖表级 true。
        XCTAssertFalse(
            UPTable2.isColumnSortable(
                UPTableColumn(key: "score", title: "分数", sortable: false),
                tableSortable: true
            )
        )
    }

    // MARK: - 三态轮转

    /// 上游轮转是 无 → ascending → descending → 删除条件（不是 order: null）。
    func testHeaderClickCyclesThroughAscendingDescendingThenRemovesTheCondition() {
        let column = columns[1]

        let first = UPTable2.nextSortConditions([], column: column, multiSort: false)
        XCTAssertEqual(first.map(\.field), ["score"])
        XCTAssertEqual(first.first?.order, "ascending")

        let second = UPTable2.nextSortConditions(first, column: column, multiSort: false)
        XCTAssertEqual(second.first?.order, "descending")

        // 第三次点击删除条件，而非把 order 置空。
        let third = UPTable2.nextSortConditions(second, column: column, multiSort: false)
        XCTAssertTrue(third.isEmpty)
    }

    /// 列级 sortOrders 覆盖表级，且 filter(Boolean) 会剔除空串。
    func testColumnSortOrdersOverrideAndDropEmptyEntries() {
        let column = UPTableColumn(
            key: "score", title: "分数", sortable: true, sortOrders: ["descending", "", "ascending"]
        )

        let first = UPTable2.nextSortConditions([], column: column, multiSort: false)
        XCTAssertEqual(first.first?.order, "descending")

        let second = UPTable2.nextSortConditions(first, column: column, multiSort: false)
        XCTAssertEqual(second.first?.order, "ascending")

        XCTAssertTrue(UPTable2.nextSortConditions(second, column: column, multiSort: false).isEmpty)
    }

    /// multiSort 为 false 时整体替换为单元素数组。
    func testSingleSortReplacesTheWholeConditionList() {
        let name = columns[0]
        let score = columns[1]

        let sortedByName = UPTable2.nextSortConditions([], column: name, multiSort: false)
        let switched = UPTable2.nextSortConditions(sortedByName, column: score, multiSort: false)

        XCTAssertEqual(switched.map(\.field), ["score"])
    }

    /// multiSort 为 true 时保留其他列并追加。
    func testMultiSortAppendsAndUpdatesInPlace() {
        let name = columns[0]
        let score = columns[1]

        let byName = UPTable2.nextSortConditions([], column: name, multiSort: true)
        let both = UPTable2.nextSortConditions(byName, column: score, multiSort: true)
        XCTAssertEqual(both.map(\.field), ["name", "score"])

        // 再点 name 应原地改它的 order，顺序不变。
        let updated = UPTable2.nextSortConditions(both, column: name, multiSort: true)
        XCTAssertEqual(updated.map(\.field), ["name", "score"])
        XCTAssertEqual(updated.first?.order, "descending")
    }

    // MARK: - sortBy 取值

    /// 上游 getSortValueBy 的四个分支。
    func testSortByResolvesFunctionArrayStringThenFallsBackToField() {
        let row = UPTableRow(id: "a", values: ["name": "Ada", "score": "8", "alt": "9"])

        XCTAssertEqual(
            UPTable2.sortValue(row, field: "score", sortBy: .function { $0["name"] }),
            "Ada"
        )
        // 数组是 join("") 字符串拼接，不是数值比较。
        XCTAssertEqual(
            UPTable2.sortValue(row, field: "score", sortBy: .keys(["name", "score"])),
            "Ada8"
        )
        XCTAssertEqual(UPTable2.sortValue(row, field: "score", sortBy: .key("alt")), "9")
        // 空串与空数组都回落到 field。
        XCTAssertEqual(UPTable2.sortValue(row, field: "score", sortBy: .key("")), "8")
        XCTAssertEqual(UPTable2.sortValue(row, field: "score", sortBy: .keys([])), "8")
        XCTAssertEqual(UPTable2.sortValue(row, field: "score", sortBy: .none), "8")
    }

    /// 数组 join("") 的直接后果：数字按字符串比，"12" < "8"。
    func testArraySortByComparesNumbersAsStrings() {
        let table = UPTable2(
            data: rows,
            columns: [UPTableColumn(key: "score", title: "分数", sortable: true, sortBy: .keys(["score"]))]
        )

        let ordered = table.sortedData(
            conditions: [UPTableSortCondition(field: "score", order: "ascending")]
        )

        XCTAssertEqual(ordered.map(\.id), ["c", "b", "a"])
    }

    // MARK: - sortMethod

    /// 上游 sortMethod 返回 0 时不接管，会 fallthrough 到内置比较；
    /// 非 0 时返回值还会再乘方向系数。
    func testSortMethodFallsThroughOnZeroAndIsMultipliedByDirection() {
        var table = UPTable2(data: rows, columns: columns)
        // 只对 name 为 Ada 的比较给出结果，其余返回 0 交回内置比较。
        table = table.sortMethod { lhs, rhs, _ in
            if lhs["name"] == "Ada" { return -1 }
            if rhs["name"] == "Ada" { return 1 }
            return 0
        }

        let ascending = table.sortedData(
            conditions: [UPTableSortCondition(field: "score", order: "ascending")]
        )
        XCTAssertEqual(ascending.first?.id, "a")

        // 降序时 -1 乘以 -1 变成 1，Ada 落到末尾。
        let descending = table.sortedData(
            conditions: [UPTableSortCondition(field: "score", order: "descending")]
        )
        XCTAssertEqual(descending.last?.id, "a")
    }

    // MARK: - filters

    /// 上游 filters 是子串包含匹配，且只作用于顶层 data。
    func testFiltersUseSubstringContainmentOnTopLevelRowsOnly() {
        let child = UPTableRow(id: "child", values: ["name": "Zed"])
        let parent = UPTableRow(id: "parent", values: ["name": "Ada"], children: [child])
        let table = UPTable2(data: [parent], columns: columns, filters: ["name": "d"])

        // 父行 Ada 含 "d" 被保留，子行不参与过滤。
        XCTAssertEqual(table.filteredData.map(\.id), ["parent"])
        XCTAssertEqual(table.filteredData.first?.children.map(\.id), ["child"])

        // 空过滤值视为不过滤。
        XCTAssertEqual(
            UPTable2(data: rows, columns: columns, filters: ["name": ""]).filteredData.count,
            3
        )
    }

    /// 排序建立在过滤之后。
    func testSortingAppliesAfterFiltering() {
        let table = UPTable2(data: rows, columns: columns, filters: ["name": "A"])

        let ordered = table.sortedData(
            conditions: [UPTableSortCondition(field: "score", order: "ascending")]
        )

        XCTAssertEqual(ordered.map(\.id), ["a"])
    }

    /// 无排序条件时原样返回过滤结果。
    func testNoConditionsReturnsFilteredOrder() {
        let table = UPTable2(data: rows, columns: columns)
        XCTAssertEqual(table.sortedData(conditions: []).map(\.id), ["a", "b", "c"])
    }
}
