import SwiftUI

public struct UPTableColumn: Identifiable, Equatable, Sendable {
    public let key: String; public let title: String; public let width: String
    public let align: String; public let sortable: Bool; public let type: String
    public init(key: String, title: String = "", width: String = "", align: String = "left",
                sortable: Bool = false, type: String = "") {
        self.key = key; self.title = title; self.width = width; self.align = align
        self.sortable = sortable; self.type = type
    }
    public var id: String { key }
}

public struct UPTableRow: Identifiable, Equatable, Sendable {
    public let id: String; public var values: [String: String]; public var children: [UPTableRow]
    public init(id: String, values: [String: String] = [:], children: [UPTableRow] = []) {
        self.id = id; self.values = values; self.children = children
    }
    public subscript(key: String) -> String { values[key] ?? "" }
}

public struct UPFlattenedTableRow: Equatable, Sendable {
    public let row: UPTableRow; public let level: Int
    public init(row: UPTableRow, level: Int) { self.row = row; self.level = level }
}

@MainActor
public struct UPTable2: View {
    public var data: [UPTableRow]; public var columns: [UPTableColumn]
    public var height: String; public var showHeader: Bool; public var fixedHeader: Bool
    public var border: Bool; public var stripe: Bool; public var rowKey: String
    public var expandedKeys: Set<String>; public var selectedKeys: Set<String>
    public var highlightCurrentRow: Bool; public var currentRow: String
    private var selectedBinding: Binding<Set<String>>?
    private var onRowClickHandler: ((UPTableRow) -> Void)?
    private var onSelectionChangeHandler: ((Set<String>) -> Void)?

    public init(data: [UPTableRow] = [], columns: [UPTableColumn] = [], height: String = "",
                showHeader: Bool = true, fixedHeader: Bool = false, border: Bool = true,
                stripe: Bool = false, rowKey: String = "id", expandedKeys: Set<String> = [],
                selectedKeys: Binding<Set<String>>? = nil, highlightCurrentRow: Bool = false,
                currentRow: String = "") {
        self.data = data; self.columns = columns; self.height = height; self.showHeader = showHeader
        self.fixedHeader = fixedHeader; self.border = border; self.stripe = stripe; self.rowKey = rowKey
        self.expandedKeys = expandedKeys; self.selectedKeys = selectedKeys?.wrappedValue ?? []
        self.selectedBinding = selectedKeys; self.highlightCurrentRow = highlightCurrentRow; self.currentRow = currentRow
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                if showHeader { rowView(columns.map { $0.title }, header: true) }
                ForEach(flattenedRows(expandedKeys: expandedKeys), id: \.row.id) { item in
                    rowView(columns.map { item.row[$0.key] }, header: false)
                        .padding(.leading, CGFloat(item.level * 12))
                }
            }.frame(minHeight: height.isEmpty ? nil : UPUnit.parse(height))
        }
        .border(border ? UPColor.parse("#ebeef5") : .clear)
    }

    @ViewBuilder private func rowView(_ values: [String], header: Bool) -> some View {
        HStack(spacing: 0) { ForEach(Array(values.enumerated()), id: \.offset) { index, value in
            Text(value).frame(minWidth: columns.indices.contains(index) && !columns[index].width.isEmpty ? UPUnit.parse(columns[index].width) : 100, alignment: .leading).padding(8)
                .background(stripe && !header && index % 2 == 0 ? Color.gray.opacity(0.05) : .clear)
        }}.font(.system(size: 14, weight: header ? .semibold : .regular))
    }

    public func sortedRows(key: String, ascending: Bool) -> [UPTableRow] {
        data.sorted { lhs, rhs in
            let result = lhs[key].localizedStandardCompare(rhs[key])
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }
    public func flattenedRows(expandedKeys: Set<String>) -> [UPFlattenedTableRow] {
        func walk(_ rows: [UPTableRow], level: Int) -> [UPFlattenedTableRow] {
            rows.flatMap { row in
                [UPFlattenedTableRow(row: row, level: level)] + (expandedKeys.contains(row.id) ? walk(row.children, level: level + 1) : [])
            }
        }
        return walk(data, level: 0)
    }
    public func toggleSelection(_ id: String) {
        var next = selectedBinding?.wrappedValue ?? selectedKeys
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        selectedBinding?.wrappedValue = next; onSelectionChangeHandler?(next)
    }
    public func onRowClick(_ action: @escaping (UPTableRow) -> Void) -> Self { var copy = self; copy.onRowClickHandler = action; return copy }
    public func onSelectionChange(_ action: @escaping (Set<String>) -> Void) -> Self { var copy = self; copy.onSelectionChangeHandler = action; return copy }
    public func triggerRowClick(_ row: UPTableRow) { onRowClickHandler?(row) }
}
