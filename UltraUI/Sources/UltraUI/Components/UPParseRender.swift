import Foundation
import SwiftUI

/// 渲染期从父节点继承下来的文字属性，对应上游 `rich-text` 靠 CSS 继承拿到的那部分。
public struct UPParseTextStyle: Equatable, Sendable {
    /// uni-app 默认正文字号，`em` / `%` / `smaller` 都以此为基准。
    public static let baseFontSize: CGFloat = 16

    public var fontSize: CGFloat
    public var isBold: Bool
    public var isItalic: Bool
    public var isMonospaced: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var color: Color?
    public var alignment: UPTextAlignment
    public var isPre: Bool
    /// 嵌套层级，决定 `<ul>` 的项目符号：disc → circle → square。
    public var listDepth: Int
    /// `vertical-align` 折算出的基线偏移，用于 `<sub>` / `<sup>`。
    public var baselineOffset: CGFloat

    public init(fontSize: CGFloat = UPParseTextStyle.baseFontSize,
                isBold: Bool = false,
                isItalic: Bool = false,
                isMonospaced: Bool = false,
                underline: Bool = false,
                strikethrough: Bool = false,
                color: Color? = nil,
                alignment: UPTextAlignment = .leading,
                isPre: Bool = false,
                listDepth: Int = 0,
                baselineOffset: CGFloat = 0) {
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
        self.isMonospaced = isMonospaced
        self.underline = underline
        self.strikethrough = strikethrough
        self.color = color
        self.alignment = alignment
        self.isPre = isPre
        self.listDepth = listDepth
        self.baselineOffset = baselineOffset
    }

    /// 容器样式（上游 `containerStyle`）里可继承的部分。
    public static func root(_ containerStyle: UPStyle) -> UPParseTextStyle {
        var style = UPParseTextStyle()
        if let size = containerStyle.length(for: "font-size") { style.fontSize = size }
        if let color = containerStyle.foregroundColor.flatMap(UPParseColor.parse) { style.color = color }
        if let alignment = containerStyle.textAlignment { style.alignment = alignment }
        style.isPre = containerStyle.value(for: "white-space")?.contains("pre") ?? false
        return style
    }

    /// 把一个节点的声明表叠加到继承属性上。
    public func applying(_ declarations: UPParseStyle) -> UPParseTextStyle {
        var style = self
        if let size = declarations.fontSize(base: fontSize) { style.fontSize = size }
        if let bold = declarations.isBold { style.isBold = bold }
        if let italic = declarations.isItalic { style.isItalic = italic }
        if declarations.isMonospaced { style.isMonospaced = true }
        if let decoration = declarations.textDecoration {
            style.underline = decoration.underline
            style.strikethrough = decoration.strikethrough
        }
        if let color = declarations.foregroundColor { style.color = color }
        if let alignment = declarations.textAlignment { style.alignment = alignment }
        if declarations.isPre { style.isPre = true }
        switch declarations.value(for: "vertical-align")?.lowercased() {
        case "sub": style.baselineOffset = -style.fontSize * 0.3
        case "super": style.baselineOffset = style.fontSize * 0.3
        default: break
        }
        return style
    }

    var font: Font {
        var font = isMonospaced
            ? Font.system(size: fontSize, design: .monospaced)
            : Font.system(size: fontSize)
        if isBold { font = font.bold() }
        if isItalic { font = font.italic() }
        return font
    }
}

/// 渲染期需要的 props 与事件回调，对应上游传给 `<node>` 的 `opts` 数组。
@MainActor
struct UPParseContext {
    var loadingImg: String
    var errorImg: String
    var lazyLoad: Bool
    var showImgMenu: Bool
    var pauseVideo: Bool
    var media: UPParseMediaCoordinator
    var onImageTap: (UPParseNode) -> Void
    var onPlay: (UPParsePlayEvent) -> Void
    var onMediaError: (UPParseErrorEvent) -> Void
    var copy: (String) -> Void
}

/// 同一层级里连续的行内节点要合并成一个 `Text` 才能正确折行，
/// 对应上游 `node.vue` 用 `rich-text` 承载连续行内节点的效果。
enum UPParseFragment {
    case inline([UPParseNode])
    case block(UPParseNode)

    static func fragments(_ nodes: [UPParseNode]) -> [UPParseFragment] {
        var result: [UPParseFragment] = []
        for node in nodes {
            guard isInline(node) else {
                result.append(.block(node))
                continue
            }
            if case .inline(let pending)? = result.last {
                result[result.count - 1] = .inline(pending + [node])
            } else {
                result.append(.inline([node]))
            }
        }
        return result
    }

    /// 对应上游 `node.vue` 的 wxs `isInline`，差别是 `inline-block` 归块级：
    /// 上游那边靠 `_block` 容器兜住宽度，原生要它自己收缩才能被父级居中。
    static func isInline(_ node: UPParseNode) -> Bool {
        if node.isText || node.name == "br" { return true }
        if ["img", "video", "audio", "table", "hr", "li", "ul", "ol"].contains(node.name) { return false }
        if let display = node.style.display {
            if display.contains("inline-block") { return false }
            return display.contains("inline")
        }
        return UPParseTags.inline.contains(node.name)
    }
}

/// 上游 `node/node.vue` 里靠 `_xxx` class 提供的默认样式，原生直接内建。
enum UPParseDefaults {
    static func style(for node: UPParseNode) -> UPParseStyle {
        switch node.name {
        case "a":
            return UPParseStyle((node.attributes["href"] ?? "").isEmpty ? "" : "color:#366092")
        case "b", "strong": return UPParseStyle("font-weight:bold")
        case "code": return UPParseStyle("font-family:monospace")
        case "del": return UPParseStyle("text-decoration:line-through")
        case "em", "i": return UPParseStyle("font-style:italic")
        case "h1": return UPParseStyle("font-size:2em;font-weight:bold")
        case "h2": return UPParseStyle("font-size:1.5em;font-weight:bold")
        case "h3": return UPParseStyle("font-size:1.17em;font-weight:bold")
        case "h4": return UPParseStyle("font-weight:bold")
        case "h5": return UPParseStyle("font-size:0.83em;font-weight:bold")
        case "h6": return UPParseStyle("font-size:0.67em;font-weight:bold")
        case "ins": return UPParseStyle("text-decoration:underline")
        case "sub": return UPParseStyle("font-size:smaller;vertical-align:sub")
        case "sup": return UPParseStyle("font-size:smaller;vertical-align:super")
        case "th": return UPParseStyle("font-weight:bold;text-align:center")
        case "ol": return UPParseStyle("list-style-type:decimal;padding-left:40px;margin:1em 0")
        case "ul": return UPParseStyle("padding-left:40px;margin:1em 0")
        case "video": return UPParseStyle("width:300px;height:225px")
        default: return UPParseStyle()
        }
    }

    /// 内建默认样式在前，节点自己的声明覆盖它。
    static func resolvedStyle(for node: UPParseNode) -> UPParseStyle {
        style(for: node).merging(node.style)
    }
}

/// 一层子节点的渲染：行内合并成 `Text`，块级各占一行。
@MainActor
struct UPParseNodesView: View {
    let nodes: [UPParseNode]
    let context: UPParseContext
    let style: UPParseTextStyle
    var lazy = false

    var body: some View {
        let fragments = UPParseFragment.fragments(nodes)
        if lazy {
            LazyVStack(alignment: style.alignment.stackAlignment, spacing: 0) { rows(fragments) }
        } else {
            VStack(alignment: style.alignment.stackAlignment, spacing: 0) { rows(fragments) }
        }
    }

    @ViewBuilder
    private func rows(_ fragments: [UPParseFragment]) -> some View {
        ForEach(Array(fragments.enumerated()), id: \.offset) { _, fragment in
            switch fragment {
            case .inline(let inlineNodes):
                UPParseInlineText(nodes: inlineNodes, style: style)
                    .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
            case .block(let node):
                UPParseBlockView(node: node, context: context, style: style)
                    .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
            }
        }
    }
}

/// 连续行内节点拼成的一段富文本。
@MainActor
struct UPParseInlineText: View {
    let nodes: [UPParseNode]
    let style: UPParseTextStyle

    var body: some View {
        Text(Self.attributed(nodes, style: style))
            .multilineTextAlignment(style.alignment.swiftUIValue)
    }

    /// 把行内节点树折叠成 `AttributedString`。链接写成内部 scheme，
    /// 由 `UPParse` 的 `openURL` 拦截后还原成上游 `linktap`。
    nonisolated static func attributed(_ nodes: [UPParseNode], style: UPParseTextStyle) -> AttributedString {
        var result = AttributedString()
        for node in nodes {
            if node.isText {
                result += attributedText(node.text, style: style)
                continue
            }
            if node.name == "br" {
                result += AttributedString("\n")
                continue
            }
            let resolved = UPParseDefaults.resolvedStyle(for: node)
            guard resolved.display != "none" else { continue }
            let inherited = style.applying(resolved)
            // 上游 `._q::before` / `._q::after` 给 `<q>` 补一对引号。
            let children = node.name == "q"
                ? [UPParseNode.text("\u{201C}")] + node.children + [UPParseNode.text("\u{201D}")]
                : node.children
            var fragment = attributed(children, style: inherited)
            if node.name == "a",
               !(node.attributes["href"] ?? "").isEmpty,
               let index = node.linkIndex,
               let url = UPParse.linkURL(index: index) {
                fragment.link = url
            }
            result += fragment
        }
        return result
    }

    private nonisolated static func attributedText(_ text: String, style: UPParseTextStyle) -> AttributedString {
        var fragment = AttributedString(text)
        fragment.font = style.font
        if let color = style.color { fragment.foregroundColor = color }
        if style.underline { fragment.underlineStyle = .single }
        if style.strikethrough { fragment.strikethroughStyle = .single }
        if style.baselineOffset != 0 { fragment.baselineOffset = style.baselineOffset }
        return fragment
    }
}

/// 单个块级节点。`body` 显式擦成 `AnyView`，否则递归的视图类型会自引用。
@MainActor
struct UPParseBlockView: View {
    let node: UPParseNode
    let context: UPParseContext
    let style: UPParseTextStyle

    var body: AnyView {
        let resolved = UPParseDefaults.resolvedStyle(for: node)
        guard resolved.display != "none" else { return AnyView(EmptyView()) }
        let inherited = style.applying(resolved)
        return AnyView(
            anchored(
                content(resolved: resolved, inherited: inherited)
                    .modifier(UPParseBlockModifier(style: resolved, base: style.fontSize))
                    .frame(maxWidth: (resolved.display ?? "").contains("inline-block") ? nil : .infinity,
                           alignment: inherited.alignment.frameAlignment)
            )
        )
    }

    /// 保留 `useAnchor` 留下来的 `id`，让宿主的 `ScrollViewReader` 能滚到这里。
    /// 只有块级节点能拿到 `.id(_:)`：行内节点已经被合并进同一段 `Text`。
    @ViewBuilder
    private func anchored(_ view: some View) -> some View {
        if let anchor = node.anchorID {
            view.id(anchor)
        } else {
            view
        }
    }

    @ViewBuilder
    private func content(resolved: UPParseStyle, inherited: UPParseTextStyle) -> some View {
        switch node.name {
        case "img":
            UPParseImageView(node: node, context: context, base: style.fontSize)
        case "video", "audio":
            UPParseMediaView(node: node, context: context, style: resolved, base: style.fontSize)
        case "hr":
            Divider()
        case "table":
            UPParseTableView(node: node, context: context, style: resolved, inherited: inherited)
        case "ul", "ol":
            UPParseListView(node: node, context: context, style: resolved, inherited: inherited)
        default:
            children(resolved: resolved, inherited: inherited)
        }
    }

    /// `scrollTable` 生成的 `div{overflow:auto}` 在这里变成横向滚动容器。
    @ViewBuilder
    private func children(resolved: UPParseStyle, inherited: UPParseTextStyle) -> some View {
        let nodes = UPParseNodesView(nodes: node.children, context: context, style: inherited)
        if (resolved.value(for: "overflow") ?? resolved.value(for: "overflow-x") ?? "").contains("auto")
            || (resolved.value(for: "overflow") ?? "").contains("scroll") {
            ScrollView(.horizontal, showsIndicators: false) { nodes }
        } else {
            nodes
        }
    }
}

/// 块级盒模型：padding / margin / 背景 / 圆角 / 边框 / 绝对宽高。
/// 百分比宽高交给 SwiftUI 的自适应布局，不做换算。
struct UPParseBlockModifier: ViewModifier {
    let style: UPParseStyle
    let base: CGFloat

    func body(content: Content) -> some View {
        let padding = style.insets(for: "padding", base: base)
        let margin = style.insets(for: "margin", base: base)
        return content
            .padding(EdgeInsets(top: padding.top,
                                leading: padding.leading,
                                bottom: padding.bottom,
                                trailing: padding.trailing))
            .frame(width: absoluteLength("width"), height: absoluteLength("height"))
            .background { style.backgroundColor }
            .clipShape(RoundedRectangle(cornerRadius: absoluteLength("border-radius") ?? 0))
            .overlay { borders }
            .padding(EdgeInsets(top: margin.top,
                                leading: margin.leading,
                                bottom: margin.bottom,
                                trailing: margin.trailing))
    }

    @ViewBuilder
    private var borders: some View {
        ZStack {
            border("top").frame(maxHeight: .infinity, alignment: .top)
            border("bottom").frame(maxHeight: .infinity, alignment: .bottom)
            border("left").frame(maxWidth: .infinity, alignment: .leading)
            border("right").frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func border(_ side: String) -> some View {
        if let border = style.border(for: side) {
            let color = border.color ?? Color.gray
            if side == "top" || side == "bottom" {
                Rectangle().fill(color).frame(height: border.width)
            } else {
                Rectangle().fill(color).frame(width: border.width)
            }
        }
    }

    private func absoluteLength(_ key: String) -> CGFloat? {
        guard let raw = style.value(for: key), !raw.contains("%") else { return nil }
        return UPParseStyle.length(raw, base: base)
    }
}

extension UPTextAlignment {
    var stackAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
