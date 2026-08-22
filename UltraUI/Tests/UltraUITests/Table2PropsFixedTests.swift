import SwiftUI
import XCTest
@testable import UltraUI

/// 上游 u-table2 的 props 默认值、固定列与空数据语义。
/// 其中数条刻意照抄上游的反直觉行为或笔误，注释标明。
@MainActor
final class Table2PropsFixedTests: XCTestCase {
    private let columns = [UPTableColumn(key: "name", title: "姓名")]

    // MARK: - props 默认值

    func testDefaultsMatchUpstream() {
        let table = UPTable2()

        XCTAssertFalse(table.stripe)
        XCTAssertEqual(table.height, "")
        XCTAssertEqual(table.maxHeight, "")
        XCTAssertTrue(table.showHeader)
        XCTAssertFalse(table.highlightCurrentRow)
        XCTAssertEqual(table.rowKey, "id")
        XCTAssertEqual(table.sortOrders, ["ascending", "descending"])
        XCTAssertFalse(table.multiSort)
        XCTAssertFalse(table.lazy)
        XCTAssertFalse(table.defaultExpandAll)
        XCTAssertEqual(table.mainCol, "")
        // 上游这三个默认值容易记错。
        XCTAssertTrue(table.fixedHeader, "上游 fixedHeader 默认 true，sticky 表头默认开启")
        XCTAssertEqual(table.emptyText, "暂无数据")
        XCTAssertEqual(table.expandWidth, "25px")
        XCTAssertEqual(table.rowHeight, "36px")
    }

    /// 上游 sortOrders 默认只有两态，没有 null 第三态。
    func testDefaultSortOrdersHaveNoNullThirdState() {
        XCTAssertEqual(UPTable2().sortOrders.count, 2)
        XCTAssertFalse(UPTable2().sortOrders.contains(""))
    }

    /// 上游 height 走 addUnit，maxHeight 却直接拼 'px'。
    /// 传 "50vh" 会得到 "50vhpx"——这是上游笔误，照抄以保持一致。
    func testMaxHeightConcatenatesPxWhileHeightUsesUnitParsing() {
        XCTAssertEqual(UPTable2.resolvedMaxHeight("300"), "300px")
        XCTAssertEqual(
            UPTable2.resolvedMaxHeight("50vh"),
            "50vhpx",
            "上游直接拼 px 不做单位判断，这里照抄该笔误"
        )
        XCTAssertEqual(UPTable2.resolvedMaxHeight(""), "")
    }

    // MARK: - 列字段

    /// 上游列字段是 key/title，不是 element-plus 的 prop/label。
    func testColumnUsesKeyAndTitleNotPropAndLabel() {
        let column = UPTableColumn(key: "score", title: "分数")
        XCTAssertEqual(column.key, "score")
        XCTAssertEqual(column.title, "分数")
        XCTAssertEqual(column.id, "score")
    }

    /// 上游 headerAlign 未设时回落 align。
    func testHeaderAlignFallsBackToAlign() {
        XCTAssertEqual(UPTableColumn(key: "a", align: "right").resolvedHeaderAlign, "right")
        XCTAssertEqual(
            UPTableColumn(key: "a", align: "right", headerAlign: "center").resolvedHeaderAlign,
            "center"
        )
    }

    /// 上游 showOverflowTooltip 用 typeof !== 'undefined' 判断，
    /// 所以列级显式 false 能覆盖表级 true。
    func testColumnOverflowTooltipCanOverrideTheTableLevelTruth() {
        let table = UPTable2(columns: columns, showOverflowTooltip: true)

        XCTAssertTrue(table.showsOverflowTooltip(UPTableColumn(key: "a")))
        XCTAssertFalse(
            table.showsOverflowTooltip(UPTableColumn(key: "a", showOverflowTooltip: false)),
            "列级显式 false 覆盖表级 true"
        )
    }

    // MARK: - 固定列

    /// 上游只识别严格字符串 "left"；true 与 "right" 静默失效。
    func testOnlyTheExactLeftStringPinsAColumn() {
        XCTAssertTrue(UPTableColumn(key: "a", fixed: "left").isFixedLeft)
        XCTAssertFalse(UPTableColumn(key: "a", fixed: "right").isFixedLeft, "上游无右固定")
        XCTAssertFalse(UPTableColumn(key: "a", fixed: "true").isFixedLeft)
        XCTAssertFalse(UPTableColumn(key: "a").isFixedLeft)
    }

    func testFixedLeftColumnsCollectOnlyLeftPinnedOnes() {
        let table = UPTable2(columns: [
            UPTableColumn(key: "a", fixed: "left"),
            UPTableColumn(key: "b", fixed: "right"),
            UPTableColumn(key: "c")
        ])

        XCTAssertEqual(table.fixedLeftColumns.map(\.key), ["a"])
    }

    /// 上游浮层只在 scrollLeft > 0 时出现，必须先横向滚动；滚回 0 时消失。
    func testFixedColumnOverlayNeedsHorizontalScrollFirst() {
        let table = UPTable2(columns: [UPTableColumn(key: "a", fixed: "left")])

        XCTAssertFalse(table.showsFixedColumnShadow(scrollLeft: 0))
        XCTAssertTrue(table.showsFixedColumnShadow(scrollLeft: 1))

        // 没有固定列时永不出现。
        let plain = UPTable2(columns: columns)
        XCTAssertFalse(plain.showsFixedColumnShadow(scrollLeft: 50))
    }

    /// 上游 visibleFixedLeftColumns 在 scrollLeft <= 0 时返回空，
    /// 否则按累计宽度判断，缺省列宽按 100px 估算。
    func testVisibleFixedColumnsUseTheHundredPixelWidthEstimate() {
        let table = UPTable2(columns: [
            UPTableColumn(key: "a", width: "80px", fixed: "left"),
            UPTableColumn(key: "b"),
            UPTableColumn(key: "c", fixed: "left")
        ])

        XCTAssertTrue(table.visibleFixedLeftColumns(scrollLeft: 0).isEmpty)

        // scrollLeft 为 1 时首个固定列已可见（1 > 0 - 0）。
        XCTAssertEqual(table.visibleFixedLeftColumns(scrollLeft: 1).map(\.key), ["a"])

        // 滚过足够距离后第二个固定列也进入可见范围。
        XCTAssertEqual(
            table.visibleFixedLeftColumns(scrollLeft: 200).map(\.key),
            ["a", "c"]
        )
    }

    // MARK: - 空数据

    /// 上游判空用原始 data，不是 filteredData——过滤后为空时不显示 emptyText，
    /// 只留空白表体。照抄该行为。
    func testEmptyTextUsesTheRawDataNotTheFilteredResult() {
        let rows = [UPTableRow(id: "a", values: ["name": "Ada"])]

        XCTAssertTrue(UPTable2(data: [], columns: columns).showsEmptyText)

        // 过滤后为空，但原始 data 非空 → 上游不显示空文案。
        let filteredEmpty = UPTable2(data: rows, columns: columns, filters: ["name": "zzz"])
        XCTAssertTrue(filteredEmpty.filteredData.isEmpty)
        XCTAssertFalse(
            filteredEmpty.showsEmptyText,
            "上游判空用原始 data，过滤后为空不显示 emptyText"
        )
    }

    // MARK: - 死声明事件

    /// 上游 emits 声明 11 个，实际只 emit 5 个。这里固定「实现了哪 5 个」，
    /// 以免日后误加上游不会触发的事件。
    func testOnlyTheFiveActuallyEmittedEventsAreModelled() {
        XCTAssertEqual(
            UPTable2.emittedEventNames.sorted(),
            ["current-change", "expand-change", "row-click", "select", "selection-change", "sort-change"].sorted()
        )
        XCTAssertEqual(
            UPTable2.declaredButNeverEmittedEventNames.sorted(),
            ["cell-click", "filter-change", "header-click", "row-dblclick", "select-all"].sorted()
        )
    }

    /// 上游 handleHeaderClick 对非排序列直接 return，不发任何事件。
    func testHeaderClickOnANonSortableColumnEmitsNothing() {
        var fired = false
        let table = UPTable2(columns: columns).onSortChange { _ in fired = true }

        let unchanged = table.triggerHeaderClick(UPTableColumn(key: "name"), conditions: [])

        XCTAssertTrue(unchanged.isEmpty)
        XCTAssertFalse(fired)
    }

    /// 上游 current-change 仅在 highlightCurrentRow 为真时 emit。
    func testCurrentChangeOnlyFiresWhenHighlightIsEnabled() {
        let row = UPTableRow(id: "a", values: ["name": "Ada"])
        var currentChanges = 0
        var rowClicks = 0

        let plain = UPTable2(data: [row], columns: columns)
            .onCurrentChange { _, _ in currentChanges += 1 }
            .onRowClick { _ in rowClicks += 1 }
        plain.triggerRowClick(row)
        XCTAssertEqual(currentChanges, 0)
        XCTAssertEqual(rowClicks, 1, "row-click 不受 highlightCurrentRow 影响")

        let highlighted = UPTable2(data: [row], columns: columns, highlightCurrentRow: true)
            .onCurrentChange { _, _ in currentChanges += 1 }
        highlighted.triggerRowClick(row)
        XCTAssertEqual(currentChanges, 1)
    }

    /// 上游 current-change 是两个位置参数 (row, oldRow)。
    func testCurrentChangeCarriesTheNewAndOldRow() {
        let previous = UPTableRow(id: "a", values: ["name": "Ada"])
        let next = UPTableRow(id: "b", values: ["name": "Bob"])
        var payload: (UPTableRow, UPTableRow?)?

        let table = UPTable2(data: [previous, next], columns: columns, highlightCurrentRow: true)
            .onCurrentChange { row, old in payload = (row, old) }

        table.triggerRowClick(next, previous: previous)

        XCTAssertEqual(payload?.0.id, "b")
        XCTAssertEqual(payload?.1?.id, "a")
    }
}
