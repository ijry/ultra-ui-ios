import Foundation

/// 上游 `u-parse/parser.js` 中 `Parser` 的原生移植：消费 `UPParseLexer` 的 token，
/// 产出可直接渲染的 `UPParseDocument`。
///
/// 未移植的上游逻辑都是 `rich-text` 专有的渲染优化，SwiftUI 侧没有对应概念：
/// - `node.c`（是否跳出 `rich-text` 单独渲染）连带 `node.t` / `node.f` / `node.w` /
///   `node.h` / `node.m` / `webp`：受它控制的样式改为无条件生效，即 `ul` / `ol` 的
///   `list-style-type`、`table` 的 `display:table` 与 `cellpadding` / `cellspacing` 默认 2。
/// - `mergeNodes`：把连续块级兄弟合并成一个 `div` 只为长列表提速，会破坏节点树语义。
/// - `tagSelector`：给节点挂 `_a` / `_img` 这类 class 供 `node.vue` 的 CSS 匹配，
///   原生侧这些默认样式直接内建在渲染层。
/// - `svg` 转图片、`plugins` 钩子，以及合并单元格表格的 `grid` 布局分支。
public struct UPParseBuilder: Sendable {
    /// 上游用 `uni.getSystemInfoSync().windowWidth` 判断「宽度是否超屏」，
    /// 原生侧沿用 `UPUnit` 的 375 设计基准，保证解析结果可脱离设备单测。
    public static let windowWidth: CGFloat = 375

    /// 栈上正在拼装的标签，对应上游压入 `this.stack` 的 node。
    private struct Frame {
        var name: String
        var attributes: [String: String]
        var children: [UPParseNode] = []
        var sources: [String] = []
        /// 对应上游 `node.pre`：该标签开启了空白符保留。
        var pre = false
        /// 对应上游 `node.flag`：子树里出现过 `colspan` / `rowspan`。
        var flag = false
        /// `<a>` 在 `links` 里的下标，出栈时回填 `innerText`。
        var linkIndex: Int?
    }

    private var options: UPParseOptions
    private let tagStyle: [String: String]
    private var stack: [Frame] = []
    private var nodes: [UPParseNode] = []
    private var imageList: [String] = []
    private var anchors: [String] = []
    private var links: [UPParseLink] = []
    private var title = ""
    /// 对应上游 `this.pre`：0 合并空白符，1 当前处于 `<pre>`，2 容器整体保留空白符。
    private var pre: Int
    /// 对应上游 `idIndex`，给没写 `id` 的 `<video>` 补一个。
    private var videoIndex = 0

    public init(options: UPParseOptions = UPParseOptions()) {
        self.options = options
        self.tagStyle = UPParseTags.resolvedTagStyle(options.tagStyle)
        self.pre = options.containerPre ? 2 : 0
    }

    public mutating func consume(_ content: String) {
        for token in UPParseLexer.tokenize(content) {
            switch token {
            case .text(let text):
                appendText(text)
            // `selfClosing` 只在上游的 xml（svg）模式里生效，HTML 模式一律看 `voidTags`。
            case .openTag(let name, let attributes, _):
                openTag(name: name, attributes: attributes)
            case .closeTag(let name):
                closeTag(name)
            }
        }
    }

    /// 对应上游 `parse()` 末尾的「出栈未闭合的标签」。
    public mutating func finish() -> UPParseDocument {
        while !stack.isEmpty { popNode() }
        return UPParseDocument(nodes: nodes,
                               title: title,
                               imageList: imageList,
                               anchors: anchors,
                               links: links)
    }

    // MARK: - 文本

    /// 对应上游 `onText`。
    private mutating func appendText(_ text: String) {
        var value = text
        if pre == 0 {
            var merged = ""
            var hasNewline = false
            for character in text {
                guard UPParseLexer.blankCharacters.contains(character) else {
                    merged.append(character)
                    continue
                }
                if merged.last != " " { merged.append(" ") }
                if character == "\n" { hasNewline = true }
            }
            if merged == " " {
                if hasNewline { return }
                // 上游 VUE3 分支：父标签名首字母是 `t`（table / tbody / tr / td / th）时也丢弃。
                if let parent = stack.last, parent.name.first == "t" { return }
            }
            value = merged
        }
        append(UPParseNode.text(UPParseDocument.decodeEntity(value)))
    }

    private mutating func append(_ node: UPParseNode) {
        if stack.isEmpty {
            nodes.append(node)
        } else {
            stack[stack.count - 1].children.append(node)
        }
    }

    // MARK: - 开始标签

    /// 对应上游 `onOpenTag`。
    private mutating func openTag(name rawName: String, attributes rawAttributes: [String: String]) {
        var name = rawName
        var attributes = rawAttributes
        // 上游在 `onAttrVal` 里就给含 `src` 的属性拼主域名，原生侧延后到这里，
        // 因为 `<base>` 会在解析途中改写 `options.domain`。
        for key in attributes.keys where key.contains("src") {
            guard let value = attributes[key], !value.isEmpty else { continue }
            attributes[key] = UPParseDocument.resolvedURL(value, domain: options.domain)
        }
        // 上游是在转换 `<embed>` 之前用原标签名取 `voidTags` 的。
        let isVoid = UPParseTags.void.contains(name)
        // `<embed>` 没有原生对应物，按上游非 H5 分支依后缀 / type 转成 video 或 audio。
        if name == "embed" {
            let src = attributes["src"] ?? ""
            let type = attributes["type"] ?? ""
            if src.contains(".mp4") || src.contains(".3gp") || src.contains(".m3u8") || type.contains("video") {
                name = "video"
            } else if src.contains(".mp3") || src.contains(".wav") || src.contains(".aac")
                        || src.contains(".m4a") || type.contains("audio") {
                name = "audio"
            }
            if attributes["autostart"] != nil { attributes["autoplay"] = "T" }
            attributes["controls"] = "T"
        }
        var sources: [String] = []
        if name == "video" || name == "audio" {
            if name == "video", attributes["id"] == nil {
                attributes["id"] = "v\(videoIndex)"
                videoIndex += 1
            }
            // 既没写 controls 也没写 autoplay 的自动补 controls。
            if attributes["controls"] == nil, attributes["autoplay"] == nil {
                attributes["controls"] = "T"
            }
            // 用数组存所有可用的 source，`<source>` 会继续往里追加。
            if let src = attributes.removeValue(forKey: "src"), !src.isEmpty {
                sources.append(src)
            }
        }

        guard isVoid else {
            if name == "a" {
                attributes["l"] = String(links.count)
            }
            var frame = Frame(name: name, attributes: attributes)
            frame.sources = sources
            if name == "a" {
                frame.linkIndex = links.count
                links.append(UPParseLink(href: UPParseDocument.normalizeHref(attributes["href"]),
                                         innerText: "",
                                         attributes: attributes))
            }
            // `<pre>` 或显式声明 `white-space: pre` 的标签内保留空白符。
            if pre != 2, name == "pre" || UPParseStyle(attributes["style"] ?? "").isPre {
                pre = 1
                frame.pre = true
            }
            stack.append(frame)
            return
        }

        if UPParseTags.ignore.contains(name) {
            // `<base>` 用来设置主域名。
            if name == "base", options.domain.isEmpty {
                options.domain = attributes["href"] ?? ""
            } else if name == "source", let parent = stack.last,
                      parent.name == "video" || parent.name == "audio",
                      let src = attributes["src"], !src.isEmpty {
                stack[stack.count - 1].sources.append(src)
            }
            return
        }

        var styleObject = parseStyle(name: name, attributes: &attributes)
        if name == "img" {
            resolveImage(attributes: &attributes, styleObject: &styleObject)
            if styleObject["display"] == "inline" { styleObject["display"] = nil }
            if attributes["ignore"] != nil, styleObject["max-width"] == nil {
                styleObject["max-width"] = "100%"
            }
            // 设定宽度超屏时高度转自动，避免变形。
            if let width = Self.parseInt(styleObject["width"]), width > Self.windowWidth {
                styleObject["height"] = nil
            }
        }
        append(UPParseNode(name: name,
                           attributes: attributes,
                           style: UPParseStyle(declarations: styleObject),
                           sources: sources))
    }

    /// 对应上游 `onOpenTag` 里的 `<img>` 分支：收集 `imgList` 并标记不可预览的图片。
    private mutating func resolveImage(attributes: inout [String: String],
                                       styleObject: inout [String: String]) {
        guard let src = attributes["src"], !src.isEmpty else { return }
        // data url 图片没写 original-src 时默认当作不可预览的小图。
        if src.contains("data:"), !options.previewImgAll, attributes["original-src"] == nil {
            attributes["ignore"] = "T"
        }
        guard attributes["ignore"] == nil else { return }
        // 对应上游 `node.a = item.attrs`：祖先是 `<a>` 时点击图片要转成 linktap。
        if attributes["l"] == nil, let index = stack.last(where: { $0.name == "a" })?.linkIndex {
            attributes["l"] = String(index)
        }
        attributes["i"] = String(imageList.count)
        imageList.append(attributes["original-src"] ?? src)
    }

    // MARK: - 样式

    /// 对应上游 `parseStyle`：`tagStyle[name]` 与行内 `style` 依次合并，
    /// 顺带把 `id` / `width` / `height` 这些属性转成样式。
    ///
    /// 上游会把「兼容性 css」（`-webkit-` 前缀、含 `safe` 的值）单独留在 `attrs.style`
    /// 里不做压缩，原生侧没有字符串压缩这一步，统一并进声明表。
    private mutating func parseStyle(name: String, attributes: inout [String: String]) -> [String: String] {
        var styleObject: [String: String] = [:]
        if let id = attributes["id"], !id.isEmpty {
            if options.useAnchor {
                if !anchors.contains(id) { anchors.append(id) }
            } else if name != "img", name != "a", name != "video", name != "audio" {
                attributes["id"] = nil
            }
        }
        // 转换 width 和 height 属性。
        for key in ["width", "height"] {
            guard let raw = attributes[key], !raw.isEmpty else { continue }
            attributes[key] = nil
            guard let value = Self.parseFloat(raw) else { continue }
            styleObject[key] = Self.numberText(value) + (raw.contains("%") ? "%" : "px")
        }
        for css in [tagStyle[name] ?? "", attributes["style"] ?? ""] {
            for declaration in css.split(separator: ";") {
                guard let separator = declaration.firstIndex(of: ":") else { continue }
                let key = declaration[declaration.startIndex..<separator]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                var value = declaration[declaration.index(after: separator)...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty, !value.isEmpty else { continue }
                // 已有 `!important` 的声明不会被普通声明覆盖。
                if let existing = styleObject[key], existing.contains("import"), !value.contains("import") {
                    continue
                }
                if value.contains("url") {
                    value = filledURL(value)
                }
                // 上游此处会把 `rpx` 折算成 `px`（`rich-text` 不认 rpx），
                // 原生渲染层的 `UPParseStyle` 直接走 `UPUnit` 解析 rpx，故原样保留。
                styleObject[key] = value
            }
        }
        attributes["style"] = nil
        for (key, value) in styleObject {
            styleObject[key] = value.replacingOccurrences(of: " !important", with: "")
        }
        return styleObject
    }

    /// 对应上游 `parseStyle` 里的 `url(...)` 补域名。
    private func filledURL(_ value: String) -> String {
        guard let open = value.firstIndex(of: "(") else { return value }
        var cursor = value.index(after: open)
        while cursor < value.endIndex,
              value[cursor] == "\"" || value[cursor] == "'" || UPParseLexer.blankCharacters.contains(value[cursor]) {
            cursor = value.index(after: cursor)
        }
        return String(value[value.startIndex..<cursor])
            + UPParseDocument.resolvedURL(String(value[cursor...]), domain: options.domain)
    }

    // MARK: - 结束标签

    /// 对应上游 `onCloseTag`：依次出栈到匹配为止；未匹配的 `p` / `br` 补一个空标签。
    private mutating func closeTag(_ name: String) {
        if let index = stack.lastIndex(where: { $0.name == name }) {
            while stack.count > index { popNode() }
        } else if name == "p" || name == "br" {
            append(UPParseNode(name: name, style: UPParseStyle(tagStyle[name] ?? "")))
        }
    }

    /// 对应上游 `popNode`。
    private mutating func popNode() {
        guard var frame = stack.popLast() else { return }
        var attributes = frame.attributes
        var children = frame.children

        if UPParseTags.ignore.contains(frame.name) {
            // `<title>` 同时在 trustTags 与 ignoreTags 里，只用来取导航栏标题。
            if frame.name == "title", options.setTitle, let first = children.first, first.isText {
                title = first.text
            }
            return
        }

        if frame.pre, pre != 2 {
            pre = stack.contains(where: { $0.pre }) ? 1 : 0
        }

        var styleObject: [String: String] = [:]
        // 转换 align 属性。
        if let align = attributes.removeValue(forKey: "align") {
            if frame.name == "table" {
                if align == "center" {
                    styleObject["margin-inline-start"] = "auto"
                    styleObject["margin-inline-end"] = "auto"
                } else {
                    styleObject["float"] = align
                }
            } else {
                styleObject["text-align"] = align
            }
        }
        // 转换 dir 属性。
        if let dir = attributes.removeValue(forKey: "dir") {
            styleObject["direction"] = dir
        }
        // 转换 font 标签的属性。
        if frame.name == "font" {
            if let color = attributes.removeValue(forKey: "color") {
                styleObject["color"] = color
            }
            if let face = attributes.removeValue(forKey: "face") {
                styleObject["font-family"] = face
            }
            if let raw = attributes.removeValue(forKey: "size"), let value = Self.parseInt(raw) {
                let size = min(max(Int(value), 1), 7)
                styleObject["font-size"] = [
                    "x-small", "small", "medium", "large", "x-large", "xx-large", "xxx-large"
                ][size - 1]
            }
        }
        // 一些编辑器的自带 class。
        if (attributes["class"] ?? "").contains("align-center") {
            styleObject["text-align"] = "center"
        }
        for (key, value) in parseStyle(name: frame.name, attributes: &attributes) {
            styleObject[key] = value
        }
        if frame.name != "table", let width = Self.parseInt(styleObject["width"]), width > Self.windowWidth {
            styleObject["max-width"] = "100%"
            styleObject["box-sizing"] = "border-box"
        }

        var name = frame.name
        if UPParseTags.block.contains(name) {
            name = "div"
        } else if !UPParseTags.trust.contains(name) {
            // 未知标签转为 span，避免无法显示。
            name = "span"
        }

        var wrapsScrollTable = false
        switch name {
        case "video":
            if (styleObject["height"] ?? "").contains("auto") { styleObject["height"] = nil }
        case "ul", "ol":
            let types = ["a": "lower-alpha", "A": "upper-alpha", "i": "lower-roman", "I": "upper-roman"]
            if let type = attributes["type"], let style = types[type] {
                styleObject["list-style-type"] = style
                attributes["type"] = nil
            }
        case "table":
            let border = Self.parseFloat(attributes["border"]) ?? 0
            let borderStyle = styleObject["border-style"] ?? "solid"
            let borderColor = styleObject["border-color"] ?? "gray"
            // 上游只在表格需要跳出 rich-text 时才给 padding / spacing 兜底 2，
            // 原生没有 rich-text 这一层，故无条件生效。
            let padding = Self.parseFloat(attributes["cellpadding"]) ?? 2
            let spacing = Self.parseFloat(attributes["cellspacing"]) ?? 2
            if border > 0, styleObject["border"] == nil {
                styleObject["border"] = "\(Self.numberText(border))px \(borderStyle) \(borderColor)"
            }
            styleObject["display"] = styleObject["display"] ?? "table"
            styleObject["border-spacing"] = "\(Self.numberText(spacing))px"
            if border > 0 || padding > 0 {
                let cellBorder = border > 0
                    ? "\(Self.numberText(border))px \(borderStyle) \(borderColor)"
                    : nil
                children = Self.decorateCells(children,
                                              border: cellBorder,
                                              padding: padding > 0 ? Self.numberText(padding) + "px" : nil)
            }
            wrapsScrollTable = options.scrollTable && !(styleObject["display"] ?? "").contains("inline")
        case "tbody", "tr":
            if frame.flag {
                frame.flag = false
                // 颜色样式下沉到单元格，避免跨行丢失。
                let inherited = ["color", "background", "background-color"].reduce(into: [String: String]()) { result, key in
                    if let value = styleObject[key] { result[key] = value }
                }
                if !inherited.isEmpty {
                    children = Self.descendStyles(children, declarations: inherited)
                }
            }
        case "td", "th":
            if attributes["colspan"] != nil || attributes["rowspan"] != nil {
                for index in stack.indices where ["table", "tbody", "tr"].contains(stack[index].name) {
                    stack[index].flag = true
                }
            }
        case "ruby":
            name = "span"
            children = Self.mergedRuby(children)
        default:
            break
        }

        if let index = frame.linkIndex, index < links.count {
            links[index] = UPParseLink(href: UPParseDocument.normalizeHref(attributes["href"]),
                                       innerText: UPParseDocument.text(of: children),
                                       attributes: attributes)
        }

        let node = UPParseNode(name: name,
                               attributes: attributes,
                               style: UPParseStyle(declarations: styleObject),
                               sources: frame.sources,
                               children: children)
        // 给表格添加一个单独的横向滚动层。
        if wrapsScrollTable {
            append(UPParseNode(name: "div",
                               style: UPParseStyle("overflow:auto"),
                               children: [node]))
        } else {
            append(node)
        }
    }

    // MARK: - 工具

    /// 对应上游 `table` 分支里给所有 `th` / `td` 前置 border / padding 的递归。
    private static func decorateCells(_ nodes: [UPParseNode],
                                      border: String?,
                                      padding: String?) -> [UPParseNode] {
        nodes.map { node in
            var node = node
            guard node.name == "th" || node.name == "td" else {
                node.children = decorateCells(node.children, border: border, padding: padding)
                return node
            }
            var declarations: [String: String] = [:]
            if let border { declarations["border"] = border }
            if let padding { declarations["padding"] = padding }
            node.style = UPParseStyle(declarations: declarations).merging(node.style)
            return node
        }
    }

    private static func descendStyles(_ nodes: [UPParseNode],
                                      declarations: [String: String]) -> [UPParseNode] {
        nodes.map { node in
            var node = node
            guard node.name == "td" else {
                node.children = descendStyles(node.children, declarations: declarations)
                return node
            }
            node.style = UPParseStyle(declarations: declarations).merging(node.style)
            return node
        }
    }

    /// 对应上游 `ruby` 分支：文本与紧随的 `<rt>` 合成上下两行居中排版。
    private static func mergedRuby(_ nodes: [UPParseNode]) -> [UPParseNode] {
        var result = nodes
        var index = 0
        while index + 1 < result.count {
            guard result[index].isText, result[index + 1].name == "rt" else {
                index += 1
                continue
            }
            let annotation = UPParseNode(name: "div",
                                         style: UPParseStyle("font-size:50%").merging(result[index + 1].style),
                                         children: result[index + 1].children)
            result[index] = UPParseNode(name: "div",
                                        style: UPParseStyle("display:inline-block;text-align:center"),
                                        children: [annotation, result[index]])
            result.remove(at: index + 1)
            index += 1
        }
        return result
    }

    /// JS `parseFloat` 语义：取前缀数字，取不到返回 nil。
    static func parseFloat(_ raw: String?) -> CGFloat? {
        guard let raw else { return nil }
        var text = ""
        for character in raw.trimmingCharacters(in: .whitespacesAndNewlines) {
            if character.isNumber || character == "." || (text.isEmpty && (character == "-" || character == "+")) {
                text.append(character)
            } else {
                break
            }
        }
        guard let value = Double(text), value.isFinite else { return nil }
        return CGFloat(value)
    }

    /// JS `parseInt` 语义：截断到整数。
    static func parseInt(_ raw: String?) -> CGFloat? {
        parseFloat(raw).map { $0 < 0 ? $0.rounded(.up) : $0.rounded(.down) }
    }

    /// JS 数字转字符串：整数不带小数点。
    static func numberText(_ value: CGFloat) -> String {
        value == value.rounded() ? String(Int(value)) : String(describing: Double(value))
    }
}
