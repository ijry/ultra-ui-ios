import Foundation
import SwiftUI

/// `<table>`。上游在小程序端把表格转成 `display:table` 的嵌套 view，
/// 原生用 `Grid` 对齐列宽：`colspan` 走 `gridCellColumns(_:)`，
/// `rowspan` 没有对应能力（上游那边也要跳出 `rich-text` 改用 CSS grid 才支持）。
@MainActor
struct UPParseTableView: View {
    let node: UPParseNode
    let context: UPParseContext
    let style: UPParseStyle
    let inherited: UPParseTextStyle

    /// 上游 `border-spacing` 由 `cellspacing` 属性换算，解析层已经写进样式。
    private var spacing: CGFloat {
        style.length(for: "border-spacing", base: inherited.fontSize) ?? 0
    }

    var body: some View {
        let rows = Self.rows(in: node.children)
        VStack(alignment: inherited.alignment.stackAlignment, spacing: 0) {
            // `<caption>` 被解析层转成 `display:table-caption` 的 div。
            ForEach(Array(Self.extras(in: node.children).enumerated()), id: \.offset) { _, extra in
                UPParseBlockView(node: extra, context: context, style: inherited)
            }

            Grid(alignment: .center, horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(Self.cells(in: row).enumerated()), id: \.offset) { _, cell in
                            UPParseBlockView(node: cell, context: context, style: rowStyle(row))
                                .gridCellColumns(Self.columnSpan(cell))
                        }
                    }
                }
            }
        }
    }

    /// `<tr>` 自己的颜色等声明要继承给单元格文字。
    private func rowStyle(_ row: UPParseNode) -> UPParseTextStyle {
        inherited.applying(row.style)
    }

    /// 展平 `thead` / `tbody` / `tfoot`，只留下 `tr`。
    nonisolated static func rows(in nodes: [UPParseNode]) -> [UPParseNode] {
        nodes.flatMap { node -> [UPParseNode] in
            if node.name == "tr" { return [node] }
            if ["thead", "tbody", "tfoot"].contains(node.name) { return rows(in: node.children) }
            return []
        }
    }

    /// 既不是分组也不是行的子节点，例如标题。
    nonisolated static func extras(in nodes: [UPParseNode]) -> [UPParseNode] {
        nodes.filter { !["tr", "thead", "tbody", "tfoot"].contains($0.name) && !$0.isText }
    }

    nonisolated static func cells(in row: UPParseNode) -> [UPParseNode] {
        row.children.filter { $0.name == "td" || $0.name == "th" }
    }

    nonisolated static func columnSpan(_ cell: UPParseNode) -> Int {
        guard let raw = UPParseBuilder.parseInt(cell.attributes["colspan"]) else { return 1 }
        return max(Int(raw), 1)
    }
}

/// `<ul>` / `<ol>`。上游靠 `display:list-item` 交给平台画项目符号，
/// SwiftUI 没有 list-item，这里自己排一列标记。
@MainActor
struct UPParseListView: View {
    let node: UPParseNode
    let context: UPParseContext
    let style: UPParseStyle
    let inherited: UPParseTextStyle

    private var markerType: String {
        style.value(for: "list-style-type")?.lowercased() ?? Self.bulletType(depth: inherited.listDepth)
    }

    private var childStyle: UPParseTextStyle {
        var child = inherited
        child.listDepth = inherited.listDepth + 1
        // 嵌套列表上游用 `._ul ._ul { margin: 0 }` 去掉外边距。
        child.alignment = .leading
        return child
    }

    var body: some View {
        let items = node.children.filter { !$0.isText }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if item.name == "li" {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Self.marker(markerType, index: index, start: start))
                            .font(inherited.font)
                            .foregroundStyle(inherited.color ?? .primary)
                        UPParseNodesView(nodes: item.children,
                                         context: context,
                                         style: childStyle.applying(UPParseDefaults.resolvedStyle(for: item)))
                            .modifier(UPParseBlockModifier(style: item.style, base: inherited.fontSize))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    UPParseBlockView(node: item, context: context, style: childStyle)
                }
            }
        }
    }

    /// `<ol start>`，上游透传给平台的 list-item 计数。
    private var start: Int {
        UPParseBuilder.parseInt(node.attributes["start"]).map { Int($0) } ?? 1
    }

    /// 上游 `._ul { disc }`、`._ul ._ul { circle }`、`._ul ._ul ._ul { square }`。
    nonisolated static func bulletType(depth: Int) -> String {
        switch depth {
        case 0: return "disc"
        case 1: return "circle"
        default: return "square"
        }
    }

    nonisolated static func marker(_ type: String, index: Int, start: Int = 1) -> String {
        let number = start + index
        switch type {
        case "none": return ""
        case "circle": return "\u{25E6}"
        case "square": return "\u{25AA}"
        case "decimal": return "\(number)."
        case "lower-alpha", "lower-latin": return alpha(number).lowercased() + "."
        case "upper-alpha", "upper-latin": return alpha(number) + "."
        case "lower-roman": return roman(number).lowercased() + "."
        case "upper-roman": return roman(number) + "."
        default: return "\u{2022}"
        }
    }

    /// 1 → A、26 → Z、27 → AA。
    nonisolated static func alpha(_ value: Int) -> String {
        guard value > 0 else { return String(value) }
        var remaining = value
        var result = ""
        while remaining > 0 {
            let digit = (remaining - 1) % 26
            result = String(UnicodeScalar(UInt8(65 + digit))) + result
            remaining = (remaining - 1) / 26
        }
        return result
    }

    nonisolated static func roman(_ value: Int) -> String {
        guard value > 0, value < 4000 else { return String(value) }
        let table: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
            (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        var remaining = value
        var result = ""
        for (number, symbol) in table {
            while remaining >= number {
                result += symbol
                remaining -= number
            }
        }
        return result
    }
}
