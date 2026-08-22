import SwiftUI
import XCTest
@testable import UltraUI

/// 上游 u-table2 的选择级联、树形展开与懒加载语义。
@MainActor
final class Table2SelectionTreeTests: XCTestCase {
    /// 三层树：grand → parent → leaf，另有一个平级行。
    private var tree: [UPTableRow] {
        let leaf = UPTableRow(id: "leaf", values: ["name": "Leaf"])
        let parent = UPTableRow(id: "parent", values: ["name": "Parent"], children: [leaf])
        let grand = UPTableRow(id: "grand", values: ["name": "Grand"], children: [parent])
        return [grand, UPTableRow(id: "solo", values: ["name": "Solo"])]
    }

    private let columns = [UPTableColumn(key: "name", title: "姓名")]

    // MARK: - 选择级联

    /// 上游 selectChildren 递归选中全部后代，不止直接子行。
    func testSelectingARowCascadesToEveryDescendant() {
        let table = UPTable2(data: tree, columns: columns)

        let selected = table.selectionAfterToggling(tree[0], selected: [])

        XCTAssertEqual(Set(selected.map(\.id)), ["grand", "parent", "leaf"])
    }

    /// 取消选中同样递归清掉全部后代。
    func testDeselectingARowCascadesRemovalToEveryDescendant() {
        let table = UPTable2(data: tree, columns: columns)
        let all = table.selectionAfterToggling(tree[0], selected: [])

        let cleared = table.selectionAfterToggling(tree[0], selected: all)

        XCTAssertTrue(cleared.isEmpty)
    }

    /// 上游只向下级联，不向上更新父行——子行全选后父行不会自动打勾。
    func testSelectingAllChildrenDoesNotSelectTheParent() {
        let table = UPTable2(data: tree, columns: columns)

        // 直接勾选中间层，祖先不应被带上。
        let selected = table.selectionAfterToggling(tree[0].children[0], selected: [])

        XCTAssertEqual(Set(selected.map(\.id)), ["parent", "leaf"])
        XCTAssertFalse(selected.contains { $0.id == "grand" })
    }

    /// 上游 selectChildren 用 findIndex 去重，已选的后代不会重复入列。
    func testCascadeDoesNotDuplicateAlreadySelectedDescendants() {
        let table = UPTable2(data: tree, columns: columns)
        let leaf = tree[0].children[0].children[0]

        let selected = table.selectionAfterToggling(tree[0], selected: [leaf])

        XCTAssertEqual(selected.filter { $0.id == "leaf" }.count, 1)
    }

    /// 上游 856/857 行：selection-change 先于 select。顺序与 element-plus 相反。
    func testSelectionChangeIsEmittedBeforeSelect() {
        var order: [String] = []
        let table = UPTable2(data: tree, columns: columns)
            .onSelectionChangeRows { _ in order.append("selection-change") }
            .onSelect { _ in order.append("select") }

        table.toggleSelect(tree[0], selected: [])

        XCTAssertEqual(order, ["selection-change", "select"])
    }

    /// 上游 select 只传裸 row，不带 selection 数组。
    func testSelectCarriesOnlyTheRow() {
        var received: UPTableRow?
        let table = UPTable2(data: tree, columns: columns).onSelect { received = $0 }

        table.toggleSelect(tree[1], selected: [])

        XCTAssertEqual(received?.id, "solo")
    }

    // MARK: - 展开

    /// 上游 expand-change 载荷是 rowKey 数组，不是 (row, expanded)。
    func testExpandChangeCarriesTheKeyArray() {
        var payload: [String] = []
        let table = UPTable2(data: tree, columns: columns).onExpandChange { payload = $0 }

        let expanded = table.expansionAfterToggling(tree[0], expandedKeys: [])
        XCTAssertEqual(expanded, ["grand"])
        XCTAssertEqual(payload, ["grand"])

        // 再次切换移除该 key。
        XCTAssertTrue(table.expansionAfterToggling(tree[0], expandedKeys: ["grand"]).isEmpty)
        XCTAssertEqual(payload, [])
    }

    /// 上游 level 从 1 起算，缩进 16*(level-1)+2。
    func testLevelStartsAtOneAndIndentFollowsUpstreamFormula() {
        let table = UPTable2(data: tree, columns: columns)

        let flattened = table.flattenedRows(expandedKeys: ["grand", "parent"])

        XCTAssertEqual(flattened.map(\.row.id), ["grand", "parent", "leaf", "solo"])
        XCTAssertEqual(flattened.map(\.level), [1, 2, 3, 1])
        XCTAssertEqual(UPTable2.indent(level: 1), 2)
        XCTAssertEqual(UPTable2.indent(level: 2), 18)
        XCTAssertEqual(UPTable2.indent(level: 3), 34)
    }

    /// 上游 flattenedSortedData 带父行（cell slot 里叫 prow）。
    func testFlattenedRowsCarryTheParentRow() {
        let table = UPTable2(data: tree, columns: columns)

        let flattened = table.flattenedRows(expandedKeys: ["grand"])

        XCTAssertNil(flattened.first?.parentRow)
        XCTAssertEqual(flattened[1].parentRow?.id, "grand")
    }

    /// 上游 hasTree 只看第一层是否有非空 children——纯 hasChildren 的懒加载树
    /// 拿不到展开箭头。这是上游已知局限，照抄并在此固定。
    func testHasTreeOnlyInspectsTheFirstLevelChildren() {
        XCTAssertTrue(UPTable2(data: tree, columns: columns).hasTree)

        // 第一层只有 hasChildren 占位，没有 children 数组。
        let lazyOnly = [UPTableRow(id: "root", values: ["name": "Root"], hasChildren: true)]
        XCTAssertFalse(UPTable2(data: lazyOnly, columns: columns).hasTree)

        // 子层有 children 也不算——只看第一层。
        let nestedOnly = [
            UPTableRow(
                id: "root",
                values: ["name": "Root"],
                children: []
            )
        ]
        XCTAssertFalse(UPTable2(data: nestedOnly, columns: columns).hasTree)
    }

    /// 上游 computedMainCol：mainCol 优先，否则取首个无 type 的列。
    func testMainColumnSkipsTypedColumns() {
        let withSelection = [
            UPTableColumn(key: "check", type: "selection"),
            UPTableColumn(key: "name", title: "姓名"),
            UPTableColumn(key: "score", title: "分数")
        ]
        XCTAssertEqual(UPTable2(data: tree, columns: withSelection).computedMainCol, "name")

        // 显式 mainCol 覆盖推断。
        XCTAssertEqual(
            UPTable2(data: tree, columns: withSelection, mainCol: "score").computedMainCol,
            "score"
        )

        // 全是 typed 列时为空串。
        XCTAssertEqual(
            UPTable2(data: tree, columns: [UPTableColumn(key: "check", type: "selection")]).computedMainCol,
            ""
        )
    }

    /// 上游 initDefaultExpandAll 是 merge 而非替换，且永不移除已展开项。
    func testDefaultExpandAllMergesAndNeverRemoves() {
        let table = UPTable2(data: tree, columns: columns, defaultExpandAll: true)

        // 只有「可展开」的行入列，叶子与无子行不入列。
        XCTAssertEqual(table.defaultExpandedKeys(merging: []), ["grand", "parent"])

        // 已有的 key 保留，即使它不在本次计算结果里。
        XCTAssertEqual(
            Set(table.defaultExpandedKeys(merging: ["stale"])),
            ["stale", "grand", "parent"]
        )

        // defaultExpandAll 为 false 时原样返回，不收起也不新增。
        let off = UPTable2(data: tree, columns: columns, defaultExpandAll: false)
        XCTAssertEqual(off.defaultExpandedKeys(merging: ["grand"]), ["grand"])
    }

    /// 上游 hasExpandableChildren：非空 children 或 hasChildren 占位。
    func testExpandableDetectionAcceptsChildrenOrThePlaceholderFlag() {
        XCTAssertTrue(tree[0].hasExpandableChildren)
        XCTAssertFalse(tree[1].hasExpandableChildren)
        XCTAssertTrue(UPTableRow(id: "x", hasChildren: true).hasExpandableChildren)
    }

    // MARK: - 懒加载

    /// 上游 loadLazyChildren 只在 lazy 为真且 load 存在时触发，
    /// resolve 后原地把子行写回该行。
    func testLazyLoadResolvesChildrenIntoTheRow() {
        var requestedLevels: [Int] = []
        let table = UPTable2(data: tree, columns: columns, lazy: true)
            .load { _, context, resolve in
                requestedLevels.append(context.level)
                resolve([UPTableRow(id: "loaded", values: ["name": "Loaded"])])
            }

        var resolved: [UPTableRow] = []
        table.loadLazyChildren(tree[1], level: 2) { resolved = $0 }

        XCTAssertEqual(requestedLevels, [2])
        XCTAssertEqual(resolved.map(\.id), ["loaded"])
    }

    /// lazy 为 false 时不调用 load。
    func testLazyLoadIsSkippedWhenLazyIsOff() {
        var called = false
        let table = UPTable2(data: tree, columns: columns, lazy: false)
            .load { _, _, resolve in
                called = true
                resolve([])
            }

        table.loadLazyChildren(tree[1], level: 1) { _ in }

        XCTAssertFalse(called)
    }
}
