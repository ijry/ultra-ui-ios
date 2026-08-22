import SwiftUI

// MARK: - 列与行模型

/// 上游 `sortable` 是 `[Boolean, String]`，且 `'custom'` 并不被特殊处理：
/// `isColumnSortable` 用 `!!column.sortable` 真值判断，所以 `'custom'`
/// 会照样走本地排序，没有「交给外部」的分支。
public enum UPTableSortable: Equatable, Sendable, ExpressibleByBooleanLiteral, ExpressibleByStringLiteral {
    case unset
    case flag(Bool)
    /// 保留上游原始字符串（含 `"custom"`），真值语义等同 `true`。
    case name(String)

    public init(booleanLiteral value: Bool) { self = .flag(value) }
    public init(stringLiteral value: String) { self = .name(value) }

    /// 上游 `!!column.sortable`。非空字符串一律为真。
    public var isTruthy: Bool {
        switch self {
        case .unset: return false
        case .flag(let flag): return flag
        case .name(let name): return !name.isEmpty
        }
    }

    var isSet: Bool { self != .unset }
}

/// 上游 `sortBy` 支持 Function / Array / String 三种形态。
public enum UPTableSortBy: Sendable {
    case none
    case key(String)
    case keys([String])
    case function(@Sendable (UPTableRow) -> String)
}

public struct UPTableColumn: Identifiable, Equatable, Sendable {
    public let key: String
    public let title: String
    public let width: String
    public let align: String
    /// 上游仅主表头读取，未设时回落 `align`。
    public let headerAlign: String
    public let sortable: UPTableSortable
    /// 上游列级 `sortOrders` 覆盖表级（需非空数组）。
    public let sortOrders: [String]
    public let sortBy: UPTableSortBy
    /// 上游只识别严格字符串 `"left"`；`true` 与 `"right"` 静默失效。
    public let fixed: String
    /// 上游 validator 限定 `default` / `selection` / `expand`，
    /// 但只有 `selection` 有实现，`expand` 通过校验却无渲染逻辑。
    public let type: String
    public let style: UPStyle
    /// 上游用 `typeof !== 'undefined'` 判断，所以显式 false 能覆盖表级 true。
    public let showOverflowTooltip: Bool?

    public init(key: String,
                title: String = "",
                width: String = "",
                align: String = "left",
                headerAlign: String = "",
                sortable: UPTableSortable = .unset,
                sortOrders: [String] = [],
                sortBy: UPTableSortBy = .none,
                fixed: String = "",
                type: String = "",
                style: UPStyle = UPStyle(),
                showOverflowTooltip: Bool? = nil) {
        self.key = key
        self.title = title
        self.width = width
        self.align = align
        self.headerAlign = headerAlign
        self.sortable = sortable
        self.sortOrders = sortOrders
        self.sortBy = sortBy
        self.fixed = fixed
        self.type = type
        self.style = style
        self.showOverflowTooltip = showOverflowTooltip
    }

    public var id: String { key }

    /// 上游只有严格 `'left'` 生效。
    public var isFixedLeft: Bool { fixed == "left" }

    /// 上游主表头 `headerAlign || align`。
    public var resolvedHeaderAlign: String { headerAlign.isEmpty ? align : headerAlign }

    public static func == (lhs: UPTableColumn, rhs: UPTableColumn) -> Bool {
        lhs.key == rhs.key
            && lhs.title == rhs.title
            && lhs.width == rhs.width
            && lhs.align == rhs.align
            && lhs.headerAlign == rhs.headerAlign
            && lhs.sortable == rhs.sortable
            && lhs.sortOrders == rhs.sortOrders
            && lhs.fixed == rhs.fixed
            && lhs.type == rhs.type
            && lhs.showOverflowTooltip == rhs.showOverflowTooltip
    }
}

public struct UPTableRow: Identifiable, Equatable, Sendable {
    public let id: String
    public var values: [String: String]
    public var children: [UPTableRow]
    /// 上游 `treeProps.hasChildren`：懒加载时用于在子行未到达前显示展开箭头。
    public var hasChildren: Bool

    public init(id: String,
                values: [String: String] = [:],
                children: [UPTableRow] = [],
                hasChildren: Bool = false) {
        self.id = id
        self.values = values
        self.children = children
        self.hasChildren = hasChildren
    }

    public subscript(key: String) -> String { values[key] ?? "" }

    /// 上游 `hasExpandableChildren`：有非空 children 或 hasChildren 为真。
    public var hasExpandableChildren: Bool { !children.isEmpty || hasChildren }
}

/// 上游 `sortConditions` 的元素形状 `{field, order, column}`。
/// 注意 `sort-change` 事件抛出的是这个数组，而不是 element-plus 的
/// `{column, prop, order}` 单对象。
public struct UPTableSortCondition: Equatable, Sendable {
    public var field: String
    /// `"ascending"` 或 `"descending"`。上游没有 `null` 第三态——
    /// 第三次点击表头是把整条条件删掉。
    public var order: String
    public var column: UPTableColumn?

    public init(field: String, order: String, column: UPTableColumn? = nil) {
        self.field = field
        self.order = order
        self.column = column
    }
}

public struct UPFlattenedTableRow: Equatable, Sendable {
    public let row: UPTableRow
    /// 上游 `level` 从 1 起算，缩进公式 `16 * (level - 1) + 2`。
    public let level: Int
    /// 上游 `cell` slot 里父行的参数名是 `prow`。
    public let parentRow: UPTableRow?
    public let rowIndex: Int

    public init(row: UPTableRow, level: Int, parentRow: UPTableRow? = nil, rowIndex: Int = 0) {
        self.row = row
        self.level = level
        self.parentRow = parentRow
        self.rowIndex = rowIndex
    }
}

/// 上游 `load(row, treeNode, resolve)` 的第二个参数。`loading` 上游恒为
/// 字面量 `true`。
public struct UPTableTreeNode: Sendable {
    public let row: UPTableRow
    /// 从 1 起算，与 `UPFlattenedTableRow.level` 一致。
    public let level: Int
    public let expanded: Bool
    public let loading: Bool

    public init(row: UPTableRow, level: Int, expanded: Bool, loading: Bool = true) {
        self.row = row
        self.level = level
        self.expanded = expanded
        self.loading = loading
    }
}

// MARK: - 表格

@MainActor
public struct UPTable2: View {
    public var data: [UPTableRow]
    public var columns: [UPTableColumn]
    public var stripe: Bool
    public var border: Bool
    public var height: String
    /// 上游此处直接拼 `+ 'px'` 而不走 `addUnit`，所以传 `"50vh"` 会得到
    /// `"50vhpx"`。这是上游笔误，为保持行为一致而照抄。
    public var maxHeight: String
    public var showHeader: Bool
    public var highlightCurrentRow: Bool
    public var rowKey: String
    public var currentRowKey: String
    public var sortOrders: [String]
    public var sortable: UPTableSortable
    public var multiSort: Bool
    public var sortBy: UPTableSortBy
    public var filters: [String: String]
    /// 上游默认 true，即 sticky 表头默认开启。
    public var fixedHeader: Bool
    public var emptyText: String
    public var lazy: Bool
    public var defaultExpandAll: Bool
    public var expandRowKeys: [String]
    public var mainCol: String
    public var expandWidth: String
    public var rowHeight: String
    public var showOverflowTooltip: Bool

    /// 现有原生简写，保留作源兼容。
    public var expandedKeys: Set<String>
    public var selectedKeys: Set<String>
    public var currentRow: String

    private var selectedBinding: Binding<Set<String>>?
    private var sortMethodHandler: (@Sendable (UPTableRow, UPTableRow, String) -> Int)?
    private var loadHandler: ((UPTableRow, UPTableTreeNode, @escaping ([UPTableRow]) -> Void) -> Void)?
    private var onRowClickHandler: ((UPTableRow) -> Void)?
    private var onSelectionChangeHandler: ((Set<String>) -> Void)?
    private var onSelectionChangeRowsHandler: (([UPTableRow]) -> Void)?
    private var onSelectHandler: ((UPTableRow) -> Void)?
    private var onExpandChangeHandler: (([String]) -> Void)?
    private var onCurrentChangeHandler: ((UPTableRow, UPTableRow?) -> Void)?
    private var onSortChangeHandler: (([UPTableSortCondition]) -> Void)?

    public init(data: [UPTableRow] = [],
                columns: [UPTableColumn] = [],
                stripe: Bool = false,
                border: Bool = true,
                height: String = "",
                maxHeight: String = "",
                showHeader: Bool = true,
                highlightCurrentRow: Bool = false,
                rowKey: String = "id",
                currentRowKey: String = "",
                sortOrders: [String] = ["ascending", "descending"],
                sortable: UPTableSortable = .unset,
                multiSort: Bool = false,
                sortBy: UPTableSortBy = .none,
                filters: [String: String] = [:],
                fixedHeader: Bool = true,
                emptyText: String = "暂无数据",
                lazy: Bool = false,
                defaultExpandAll: Bool = false,
                expandRowKeys: [String] = [],
                mainCol: String = "",
                expandWidth: String = "25px",
                rowHeight: String = "36px",
                showOverflowTooltip: Bool = false,
                expandedKeys: Set<String> = [],
                selectedKeys: Binding<Set<String>>? = nil,
                currentRow: String = "") {
        self.data = data
        self.columns = columns
        self.stripe = stripe
        self.border = border
        self.height = height
        self.maxHeight = maxHeight
        self.showHeader = showHeader
        self.highlightCurrentRow = highlightCurrentRow
        self.rowKey = rowKey
        self.currentRowKey = currentRowKey
        self.sortOrders = sortOrders
        self.sortable = sortable
        self.multiSort = multiSort
        self.sortBy = sortBy
        self.filters = filters
        self.fixedHeader = fixedHeader
        self.emptyText = emptyText
        self.lazy = lazy
        self.defaultExpandAll = defaultExpandAll
        self.expandRowKeys = expandRowKeys
        self.mainCol = mainCol
        self.expandWidth = expandWidth
        self.rowHeight = rowHeight
        self.showOverflowTooltip = showOverflowTooltip
        self.expandedKeys = expandedKeys
        self.selectedKeys = selectedKeys?.wrappedValue ?? []
        self.selectedBinding = selectedKeys
        self.currentRow = currentRow
    }

    // MARK: 排序判定

    /// 上游 `isColumnSortable`：列级已设则用列级真值，否则回落表级。
    public static func isColumnSortable(_ column: UPTableColumn,
                                        tableSortable: UPTableSortable) -> Bool {
        column.sortable.isSet ? column.sortable.isTruthy : tableSortable.isTruthy
    }

    public func isColumnSortable(_ column: UPTableColumn) -> Bool {
        Self.isColumnSortable(column, tableSortable: sortable)
    }

    /// 上游 `getColumnSortOrders(column).filter(Boolean)`：列级非空则覆盖表级，
    /// 空串条目被剔除。
    public static func resolvedSortOrders(_ column: UPTableColumn,
                                          tableSortOrders: [String]) -> [String] {
        let raw = column.sortOrders.isEmpty ? tableSortOrders : column.sortOrders
        let filtered = raw.filter { !$0.isEmpty }
        return filtered.isEmpty ? ["ascending"] : filtered
    }

    /// 上游 `handleHeaderClick` 的轮转：未排序 → orders[0] → 下一个 →
    /// 越界时删除该条件（不是把 order 置为 null）。
    public static func nextSortConditions(_ conditions: [UPTableSortCondition],
                                          column: UPTableColumn,
                                          multiSort: Bool,
                                          tableSortOrders: [String] = ["ascending", "descending"]) -> [UPTableSortCondition] {
        let orders = resolvedSortOrders(column, tableSortOrders: tableSortOrders)
        var newOrder = orders[0]

        if let index = conditions.firstIndex(where: { $0.field == column.key }) {
            let currentOrder = conditions[index].order
            // 上游 `sortOrders.indexOf(currentOrder) + 1`，未命中时得 0，
            // 因而 `nextIndex > 0` 不成立，走删除分支。
            let nextIndex = (orders.firstIndex(of: currentOrder).map { $0 + 1 }) ?? 0
            if nextIndex > 0 && nextIndex < orders.count {
                newOrder = orders[nextIndex]
            } else {
                var removed = conditions
                removed.remove(at: index)
                return removed
            }

            if multiSort {
                var updated = conditions
                updated[index].order = newOrder
                updated[index].column = column
                return updated
            }
            return [UPTableSortCondition(field: column.key, order: newOrder, column: column)]
        }

        guard multiSort else {
            return [UPTableSortCondition(field: column.key, order: newOrder, column: column)]
        }
        return conditions + [UPTableSortCondition(field: column.key, order: newOrder, column: column)]
    }

    public func nextSortConditions(_ conditions: [UPTableSortCondition],
                                   column: UPTableColumn) -> [UPTableSortCondition] {
        Self.nextSortConditions(
            conditions,
            column: column,
            multiSort: multiSort,
            tableSortOrders: sortOrders
        )
    }

    // MARK: 取值

    /// 上游 `getSortValueBy`：Function → 调用；非空 Array → `join("")`
    /// 字符串拼接（数字会按字符串比较）；非空 String → 该键；否则回落 field。
    public static func sortValue(_ row: UPTableRow, field: String, sortBy: UPTableSortBy) -> String {
        switch sortBy {
        case .function(let transform):
            return transform(row)
        case .keys(let keys) where !keys.isEmpty:
            return keys.map { row[$0] }.joined()
        case .key(let key) where !key.isEmpty:
            return row[key]
        default:
            return row[field]
        }
    }

    // MARK: 过滤

    /// 上游 `filteredData`：对每个 filter 做 `toString().includes()` 子串匹配，
    /// 空值视为不过滤。只作用于顶层 data，子行不参与。
    public var filteredData: [UPTableRow] {
        guard !filters.isEmpty else { return data }
        return data.filter { row in
            filters.allSatisfy { key, filter in
                guard !filter.isEmpty else { return true }
                return row[key].contains(filter)
            }
        }
    }

    // MARK: 排序

    /// 上游 `sortedData`：建立在 filteredData 之上，按 sortConditions 依次比较。
    public func sortedData(conditions: [UPTableSortCondition]) -> [UPTableRow] {
        let base = filteredData
        guard !conditions.isEmpty else { return base }

        return base.sorted { lhs, rhs in
            for condition in conditions {
                let resolvedSortBy = condition.column.map(columnSortBy) ?? sortBy
                let valueA = Self.sortValue(lhs, field: condition.field, sortBy: resolvedSortBy)
                let valueB = Self.sortValue(rhs, field: condition.field, sortBy: resolvedSortBy)
                let direction = condition.order == "ascending" ? 1 : -1

                // 上游只有 sortMethod 返回非 0 才采用，且返回值再乘方向系数；
                // 返回 0 时 fallthrough 到下面的内置比较。
                if let sortMethodHandler {
                    let result = sortMethodHandler(lhs, rhs, condition.field)
                    if result != 0 { return result * direction < 0 }
                }

                if valueA != valueB {
                    return (valueA < valueB) == (direction > 0)
                }
            }
            return false
        }
    }

    private func columnSortBy(_ column: UPTableColumn) -> UPTableSortBy {
        switch column.sortBy {
        case .none: return sortBy
        default: return column.sortBy
        }
    }

    // MARK: 选择

    /// 上游 `toggleSelect` 的纯函数形式：已选则移除该行并递归取消全部后代，
    /// 未选则加入并递归选中全部后代。上游只向下级联，不向上更新父行状态，
    /// 所以子行全选后父行不会自动打勾。
    public func selectionAfterToggling(_ row: UPTableRow,
                                       selected: [UPTableRow]) -> [UPTableRow] {
        if let index = selected.firstIndex(where: { $0.id == row.id }) {
            var next = selected
            next.remove(at: index)
            let descendants = Self.descendantIDs(of: row)
            next.removeAll { descendants.contains($0.id) }
            return next
        }

        var next = selected
        next.append(row)
        // 上游 selectChildren 用 findIndex 去重，已选后代不重复入列。
        for descendant in Self.descendants(of: row) where !next.contains(where: { $0.id == descendant.id }) {
            next.append(descendant)
        }
        return next
    }

    /// 上游 856/857 行的顺序：`selection-change` 先，`select` 后。
    /// 这与 element-plus 的直觉相反，故意保留。
    @discardableResult
    public func toggleSelect(_ row: UPTableRow, selected: [UPTableRow]) -> [UPTableRow] {
        let next = selectionAfterToggling(row, selected: selected)
        onSelectionChangeRowsHandler?(next)
        onSelectHandler?(row)
        return next
    }

    private static func descendants(of row: UPTableRow) -> [UPTableRow] {
        row.children.flatMap { [$0] + descendants(of: $0) }
    }

    private static func descendantIDs(of row: UPTableRow) -> Set<String> {
        Set(descendants(of: row).map(\.id))
    }

    // MARK: 展开

    /// 上游 `toggleExpand`：不在则 push 并触发懒加载，在则 splice 移除，
    /// 两条路径最后都 emit `expand-change`，载荷是 key 数组。
    @discardableResult
    public func expansionAfterToggling(_ row: UPTableRow,
                                       expandedKeys: [String]) -> [String] {
        var next = expandedKeys
        if let index = next.firstIndex(of: row.id) {
            next.remove(at: index)
        } else {
            next.append(row.id)
        }
        onExpandChangeHandler?(next)
        return next
    }

    /// 上游对 mainCol 列设 `paddingLeft = 16 * (level - 1) + 2`，level 从 1 起算。
    public static func indent(level: Int) -> CGFloat {
        CGFloat(16 * max(0, level - 1) + 2)
    }

    /// 上游 `hasTree` 只检查 `sortedData` 的第一层是否有非空 children。
    /// 后果是纯 `hasChildren` 占位的懒加载树拿不到展开箭头——这是上游局限，
    /// 照抄以保持行为一致。
    public var hasTree: Bool {
        data.contains { !$0.children.isEmpty }
    }

    /// 上游 `computedMainCol`：显式 `mainCol` 优先，否则取首个没有 `type` 的列，
    /// 因此 selection 列会被自动跳过。
    public var computedMainCol: String {
        if !mainCol.isEmpty { return mainCol }
        return columns.first { $0.type.isEmpty }?.key ?? ""
    }

    /// 上游 `initDefaultExpandAll`：收集所有「可展开」行的 key，与现有
    /// `expandedKeys` 取并集。是 merge 而非替换，所以永不移除已展开项，
    /// `defaultExpandAll` 从 true 改回 false 也不会收起任何行。
    public func defaultExpandedKeys(merging existing: [String]) -> [String] {
        guard defaultExpandAll else { return existing }

        var keys: [String] = []
        func walk(_ rows: [UPTableRow]) {
            for row in rows {
                if row.hasExpandableChildren { keys.append(row.id) }
                walk(row.children)
            }
        }
        walk(data)

        var merged = existing
        for key in keys where !merged.contains(key) {
            merged.append(key)
        }
        return merged
    }

    // MARK: 懒加载

    /// 上游 `loadLazyChildren`：仅当 `lazy` 为真且 `load` 存在时调用，
    /// resolve 时原地把子行写回该行。
    public func loadLazyChildren(_ row: UPTableRow,
                                 level: Int,
                                 resolve: @escaping ([UPTableRow]) -> Void) {
        guard lazy, let loadHandler else { return }
        let node = UPTableTreeNode(row: row, level: level, expanded: true)
        loadHandler(row, node, resolve)
    }

    // MARK: 尺寸与列可见性

    /// 上游 `height` 走 `addUnit`，但 `maxHeight` 直接拼 `+ 'px'`。
    /// 于是传 `"50vh"` 得到 `"50vhpx"`。这是上游笔误，为保持行为一致而照抄，
    /// 不在 Swift 侧「修好」——否则迁移时会出现难查的差异。
    public static func resolvedMaxHeight(_ maxHeight: String) -> String {
        maxHeight.isEmpty ? "" : maxHeight + "px"
    }

    /// 上游表级 `showOverflowTooltip` 可被列级覆盖，判断用
    /// `typeof !== 'undefined'`，所以列级显式 false 能压过表级 true。
    public func showsOverflowTooltip(_ column: UPTableColumn) -> Bool {
        column.showOverflowTooltip ?? showOverflowTooltip
    }

    /// 上游 `fixedLeftColumns`：只收严格 `fixed === 'left'` 的列。
    public var fixedLeftColumns: [UPTableColumn] {
        columns.filter(\.isFixedLeft)
    }

    /// 上游 `onScroll` 里才更新阴影标志，且要求有固定列。
    /// 因此浮层初始不可见，必须先横向滚动；滚回 0 时消失。
    public func showsFixedColumnShadow(scrollLeft: CGFloat) -> Bool {
        guard !fixedLeftColumns.isEmpty else { return false }
        return scrollLeft > 0
    }

    /// 上游 `visibleFixedLeftColumns`：`scrollLeft <= 0` 返回空；否则遍历全部列，
    /// 按累计宽度判断固定列是否已被滚出。缺省列宽按 100px 估算，
    /// 所以列宽是 flex 自适应时会算错——上游行为，照抄。
    public func visibleFixedLeftColumns(scrollLeft: CGFloat) -> [UPTableColumn] {
        guard scrollLeft > 0 else { return [] }

        var totalWidth: CGFloat = 0
        var fixedWidth: CGFloat = 0
        var visible: [UPTableColumn] = []

        for column in columns {
            let columnWidth = column.width.isEmpty ? 100 : UPUnit.parse(column.width)
            if column.isFixedLeft, scrollLeft > totalWidth - fixedWidth {
                visible.append(column)
                fixedWidth += columnWidth
            }
            totalWidth += columnWidth
        }
        return visible
    }

    /// 上游判空用原始 `data`，不是 `filteredData`。过滤后为空时只留空白表体，
    /// 不显示 `emptyText`。照抄该行为。
    public var showsEmptyText: Bool { data.isEmpty }

    // MARK: 事件清单

    /// 上游实际会 emit 的事件名。
    public static let emittedEventNames = [
        "row-click", "current-change", "sort-change",
        "selection-change", "select", "expand-change"
    ]

    /// 上游 `emits` 里声明但代码中从未 emit 的事件名。`header-click` 尤其误导：
    /// `handleHeaderClick` 存在且已绑定在表头，但它只做排序，从不 emit。
    /// 这些不建模，以免暴露永不触发的接口。
    public static let declaredButNeverEmittedEventNames = [
        "select-all", "cell-click", "row-dblclick", "header-click", "filter-change"
    ]

    // MARK: 视图

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                if showHeader { rowView(columns.map(\.title), header: true) }
                ForEach(flattenedRows(expandedKeys: expandedKeys), id: \.row.id) { item in
                    rowView(columns.map { item.row[$0.key] }, header: false)
                        // 上游缩进公式，level 从 1 起算。
                        .padding(.leading, CGFloat(16 * max(0, item.level - 1) + 2))
                }
                // 上游判空用原始 data，过滤后为空时不显示 emptyText。
                if showsEmptyText {
                    Text(emptyText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .frame(minHeight: height.isEmpty ? nil : UPUnit.parse(height))
        }
        .frame(maxHeight: resolvedMaxHeightValue)
        .border(border ? UPColor.parse("#ebeef5") : .clear)
    }

    /// `maxHeight` 经上游那条直拼 `px` 的路径后再解析回数值；
    /// `"50vh"` 变成 `"50vhpx"`，`UPUnit.parse` 得 0，故此处回落 `.infinity`。
    private var resolvedMaxHeightValue: CGFloat {
        let parsed = UPUnit.parse(Self.resolvedMaxHeight(maxHeight))
        return parsed > 0 ? parsed : .infinity
    }

    @ViewBuilder
    private func rowView(_ values: [String], header: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Text(value)
                    .frame(
                        minWidth: columns.indices.contains(index) && !columns[index].width.isEmpty
                            ? UPUnit.parse(columns[index].width)
                            : 100,
                        alignment: .leading
                    )
                    .padding(8)
                    .background(
                        stripe && !header && index % 2 == 0
                            ? Color.gray.opacity(0.05)
                            : .clear
                    )
            }
        }
        .font(.system(size: 14, weight: header ? .semibold : .regular))
    }

    // MARK: 树形

    /// 上游 `flattenedSortedData`：level 从 1 起算，带父行与行内索引。
    public func flattenedRows(expandedKeys: Set<String>) -> [UPFlattenedTableRow] {
        func walk(_ rows: [UPTableRow], parentRow: UPTableRow?, level: Int) -> [UPFlattenedTableRow] {
            rows.enumerated().flatMap { rowIndex, row -> [UPFlattenedTableRow] in
                let entry = UPFlattenedTableRow(
                    row: row,
                    level: level,
                    parentRow: parentRow,
                    rowIndex: rowIndex
                )
                guard !row.children.isEmpty, expandedKeys.contains(row.id) else { return [entry] }
                return [entry] + walk(row.children, parentRow: row, level: level + 1)
            }
        }
        return walk(data, parentRow: nil, level: 1)
    }

    // MARK: 源兼容

    /// 早期原生接口，保留。
    public func sortedRows(key: String, ascending: Bool) -> [UPTableRow] {
        data.sorted { lhs, rhs in
            let result = lhs[key].localizedStandardCompare(rhs[key])
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    public func toggleSelection(_ id: String) {
        var next = selectedBinding?.wrappedValue ?? selectedKeys
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        selectedBinding?.wrappedValue = next
        onSelectionChangeHandler?(next)
    }

    public func sortMethod(_ method: @escaping @Sendable (UPTableRow, UPTableRow, String) -> Int) -> Self {
        var copy = self
        copy.sortMethodHandler = method
        return copy
    }

    /// 上游 `load(row, treeNode, resolve)`。
    public func load(_ handler: @escaping (UPTableRow, UPTableTreeNode, @escaping ([UPTableRow]) -> Void) -> Void) -> Self {
        var copy = self
        copy.loadHandler = handler
        return copy
    }

    /// 上游 `select`：载荷只有裸 row，不含 selection 数组。
    public func onSelect(_ action: @escaping (UPTableRow) -> Void) -> Self {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    /// 上游 `selection-change`：载荷是 selectedRows 数组。
    public func onSelectionChangeRows(_ action: @escaping ([UPTableRow]) -> Void) -> Self {
        var copy = self
        copy.onSelectionChangeRowsHandler = action
        return copy
    }

    /// 上游 `expand-change`：载荷是 rowKey 数组，不是 (row, expanded)。
    public func onExpandChange(_ action: @escaping ([String]) -> Void) -> Self {
        var copy = self
        copy.onExpandChangeHandler = action
        return copy
    }

    /// 上游 `current-change`：两个位置参数，且仅在 highlightCurrentRow 为真时 emit。
    public func onCurrentChange(_ action: @escaping (UPTableRow, UPTableRow?) -> Void) -> Self {
        var copy = self
        copy.onCurrentChangeHandler = action
        return copy
    }

    /// 上游 `sort-change`：载荷是整个条件数组，不是单个 {column, prop, order}。
    public func onSortChange(_ action: @escaping ([UPTableSortCondition]) -> Void) -> Self {
        var copy = self
        copy.onSortChangeHandler = action
        return copy
    }

    public func onRowClick(_ action: @escaping (UPTableRow) -> Void) -> Self {
        var copy = self
        copy.onRowClickHandler = action
        return copy
    }

    public func onSelectionChange(_ action: @escaping (Set<String>) -> Void) -> Self {
        var copy = self
        copy.onSelectionChangeHandler = action
        return copy
    }

    /// 上游 `handleRowClick`：先在 highlightCurrentRow 为真时 emit
    /// `current-change`，再 emit `row-click`。
    public func triggerRowClick(_ row: UPTableRow, previous: UPTableRow? = nil) {
        if highlightCurrentRow {
            onCurrentChangeHandler?(row, previous)
        }
        onRowClickHandler?(row)
    }

    /// 上游 `handleHeaderClick`：非排序列直接 return，不发任何事件
    /// （`header-click` 是死声明，从不触发）。
    @discardableResult
    public func triggerHeaderClick(_ column: UPTableColumn,
                                   conditions: [UPTableSortCondition]) -> [UPTableSortCondition] {
        guard isColumnSortable(column) else { return conditions }
        let next = nextSortConditions(conditions, column: column)
        onSortChangeHandler?(next)
        return next
    }
}
