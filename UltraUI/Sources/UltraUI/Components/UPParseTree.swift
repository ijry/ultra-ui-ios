import Foundation

/// 上游 `u-parse/parse/parser.js` 的原生解析层。
///
/// 解析结果是纯值类型，可以脱离视图单测；渲染层 `UPParse` 只消费这里的节点树。
/// 命名与上游保持对应：`nodes` 即 `parser.nodes`，`imageList` 即 `imgList`。
public struct UPParseNode: Equatable, Sendable {
    /// 文本节点的标签名，对应上游 `node.type === 'text'`。
    public static let textName = "#text"

    public var name: String
    public var text: String
    public var attributes: [String: String]
    public var style: UPParseStyle
    /// 对应上游 `node.src`：`<video>` / `<audio>` 收集到的所有可用源。
    public var sources: [String]
    public var children: [UPParseNode]

    public init(name: String,
                text: String = "",
                attributes: [String: String] = [:],
                style: UPParseStyle = UPParseStyle(),
                sources: [String] = [],
                children: [UPParseNode] = []) {
        self.name = name
        self.text = text
        self.attributes = attributes
        self.style = style
        self.sources = sources
        self.children = children
    }

    public static func text(_ value: String) -> UPParseNode {
        UPParseNode(name: textName, text: value)
    }

    public var isText: Bool { name == Self.textName }

    /// 上游锚点是靠 `attrs.id` 暴露的，`useAnchor` 为假时 `parseStyle` 会清掉它。
    public var anchorID: String? {
        guard let id = attributes["id"], !id.isEmpty else { return nil }
        return id
    }

    /// `<img>` 在 `imgList` 中的下标，对应上游 `attrs.i`。
    public var imageIndex: Int? {
        guard let raw = attributes["i"] else { return nil }
        return Int(raw)
    }

    /// `<a>` 在 `UPParseDocument.links` 中的下标，原生新增，用于把点击事件还原成上游 `linktap` 负载。
    public var linkIndex: Int? {
        guard let raw = attributes["l"] else { return nil }
        return Int(raw)
    }
}

/// `<a>` 的解析结果，字段与上游 `linkTap` 的事件负载一致。
public struct UPParseLink: Equatable, Sendable {
    public let href: String
    public let innerText: String
    public let attributes: [String: String]

    public init(href: String, innerText: String, attributes: [String: String]) {
        self.href = href
        self.innerText = innerText
        self.attributes = attributes
    }
}

/// 解析期需要的 `u-parse` 配置子集，对应上游 `new Parser(options)` 收到的 props。
public struct UPParseOptions: Equatable, Sendable {
    public var domain: String
    public var tagStyle: [String: String]
    public var useAnchor: Bool
    public var setTitle: Bool
    /// 上游 `scrollTable` 会给 `<table>` 外面套一层 `overflow:auto` 的 `div`。
    public var scrollTable: Bool
    /// 上游 `previewImg === 'all'` 时连 base64 图片也进 `imgList`。
    public var previewImgAll: Bool
    /// 上游用 `containerStyle` 是否同时含 `white-space` 与 `pre` 决定 `this.pre = 2`。
    public var containerPre: Bool

    public init(domain: String = "",
                tagStyle: [String: String] = [:],
                useAnchor: Bool = false,
                setTitle: Bool = true,
                scrollTable: Bool = false,
                previewImgAll: Bool = false,
                containerPre: Bool = false) {
        self.domain = domain
        self.tagStyle = tagStyle
        self.useAnchor = useAnchor
        self.setTitle = setTitle
        self.scrollTable = scrollTable
        self.previewImgAll = previewImgAll
        self.containerPre = containerPre
    }
}

/// 上游 `parser.js` 里的标签表与实体表。
public enum UPParseTags {
    public static let trust: Set<String> = [
        "a", "abbr", "ad", "audio", "b", "blockquote", "br", "code", "col", "colgroup",
        "dd", "del", "dl", "dt", "div", "em", "fieldset", "h1", "h2", "h3", "h4", "h5",
        "h6", "hr", "i", "img", "ins", "label", "legend", "li", "ol", "p", "q", "ruby",
        "rt", "source", "span", "strong", "sub", "sup", "table", "tbody", "td", "tfoot",
        "th", "thead", "tr", "title", "ul", "video"
    ]

    public static let block: Set<String> = [
        "address", "article", "aside", "body", "caption", "center", "cite", "footer",
        "header", "html", "nav", "pre", "section"
    ]

    public static let ignore: Set<String> = [
        "area", "base", "canvas", "embed", "frame", "head", "iframe", "input", "link",
        "map", "meta", "param", "rp", "script", "source", "style", "textarea", "title",
        "track", "wbr"
    ]

    public static let void: Set<String> = [
        "area", "base", "br", "col", "circle", "ellipse", "embed", "frame", "hr", "img",
        "input", "line", "link", "meta", "param", "path", "polygon", "rect", "source",
        "track", "use", "wbr"
    ]

    public static let inline: Set<String> = [
        "abbr", "b", "big", "code", "del", "em", "i", "ins", "label", "q", "small",
        "span", "strong", "sub", "sup"
    ]

    /// 上游 `config.entities`，注意其中**没有** `amp`，`&amp;` 只在 `decodeEntity(str, true)` 时才解码。
    public static let entities: [String: String] = [
        "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "ensp": "\u{2002}",
        "emsp": "\u{2003}", "nbsp": "\u{A0}", "semi": ";", "ndash": "–", "mdash": "—",
        "middot": "·", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
        "bull": "•", "hellip": "…", "larr": "←", "uarr": "↑", "rarr": "→", "darr": "↓"
    ]

    /// 上游 `config.tagStyle`。
    public static let defaultTagStyle: [String: String] = [
        "address": "font-style:italic",
        "big": "display:inline;font-size:1.2em",
        "caption": "display:table-caption;text-align:center",
        "center": "text-align:center",
        "cite": "font-style:italic",
        "dd": "margin-left:40px",
        "mark": "background-color:yellow",
        "pre": "font-family:monospace;white-space:pre",
        "s": "text-decoration:line-through",
        "small": "display:inline;font-size:0.8em",
        "strike": "text-decoration:line-through",
        "u": "text-decoration:underline"
    ]

    /// 对应上游 `Object.assign({}, config.tagStyle, options.tagStyle)`。
    public static func resolvedTagStyle(_ overrides: [String: String]) -> [String: String] {
        var merged = defaultTagStyle
        for (key, value) in overrides {
            merged[key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = value
        }
        return merged
    }
}

/// 一次 `setContent` 的解析结果。
public struct UPParseDocument: Equatable, Sendable {
    public let nodes: [UPParseNode]
    /// `<title>` 的文本，仅在 `setTitle` 为真时收集，对应上游 `uni.setNavigationBarTitle`。
    public let title: String
    /// 对应上游 `imgList`，`previewImage` 的 `urls`。
    public let imageList: [String]
    /// 开启 `useAnchor` 后保留下来的 `id` 列表。
    public let anchors: [String]
    public let links: [UPParseLink]

    public static let empty = UPParseDocument(nodes: [], title: "", imageList: [], anchors: [], links: [])

    public init(nodes: [UPParseNode],
                title: String,
                imageList: [String],
                anchors: [String],
                links: [UPParseLink]) {
        self.nodes = nodes
        self.title = title
        self.imageList = imageList
        self.anchors = anchors
        self.links = links
    }

    public var isEmpty: Bool { nodes.isEmpty }

    public static func parse(_ content: String, options: UPParseOptions = UPParseOptions()) -> UPParseDocument {
        guard !content.isEmpty else { return .empty }
        var builder = UPParseBuilder(options: options)
        builder.consume(content)
        return builder.finish()
    }

    /// 对应上游 `getText()`：文本节点还原 `&amp;`，块级标签补换行，单元格补制表符。
    public var plainText: String { Self.text(of: nodes) }

    public static func text(of nodes: [UPParseNode]) -> String {
        var result = ""
        func traverse(_ nodes: [UPParseNode]) {
            for node in nodes {
                if node.isText {
                    result += node.text.replacingOccurrences(of: "&amp;", with: "&")
                } else if node.name == "br" {
                    result += "\n"
                } else {
                    let isBlock = isBlockName(node.name)
                    if isBlock, let last = result.last, last != "\n" {
                        result += "\n"
                    }
                    traverse(node.children)
                    if isBlock, result.last != "\n" {
                        result += "\n"
                    } else if node.name == "td" || node.name == "th" {
                        result += "\t"
                    }
                }
            }
        }
        traverse(nodes)
        return result
    }

    /// 上游 `getText` 判定块级的方式：`p` / `div` / `tr` / `li` / `h1`–`h6`。
    static func isBlockName(_ name: String) -> Bool {
        if name == "p" || name == "div" || name == "tr" || name == "li" { return true }
        guard name.count >= 2, name.first == "h" else { return false }
        let second = name[name.index(after: name.startIndex)]
        return second > "0" && second < "7"
    }

    /// 对应上游 `normalizeHref`。
    public static func normalizeHref(_ href: String?) -> String {
        (href ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 对应上游 `isExternalLink`。
    public static func isExternalLink(_ href: String) -> Bool {
        (href.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first ?? "").contains("://")
    }

    /// 对应上游 `Parser.prototype.getUrl`：补协议、补域名，`data:` 与绝对地址原样返回。
    public static func resolvedURL(_ url: String, domain: String) -> String {
        guard !url.isEmpty else { return url }
        if url.hasPrefix("//") {
            let scheme = domain.isEmpty ? "http" : String(domain.prefix(while: { $0 != ":" }))
            return "\(scheme.isEmpty ? "http" : scheme):\(url)"
        }
        if url.hasPrefix("/") {
            return domain.isEmpty ? url : domain + url
        }
        if !url.contains("data:"), !url.contains("://"), !domain.isEmpty {
            return domain + "/" + url
        }
        return url
    }

    /// 对应上游 `decodeEntity(str, amp)`，含 `&#123;` / `&#x1F600;` 数字实体。
    public static func decodeEntity(_ input: String, amp: Bool = false) -> String {
        var chars = Array(input)
        var index = firstIndex(of: "&", in: chars, from: 0)
        while index != -1 {
            let end = firstIndex(of: ";", in: chars, from: index + 3)
            if end == -1 { break }
            if index + 1 < chars.count, chars[index + 1] == "#" {
                let isHex = index + 2 < chars.count && (chars[index + 2] == "x" || chars[index + 2] == "X")
                let start = index + 2 + (isHex ? 1 : 0)
                if start < end,
                   let code = UInt32(String(chars[start..<end]), radix: isHex ? 16 : 10),
                   let scalar = Unicode.Scalar(code) {
                    chars.replaceSubrange(index...end, with: [Character(scalar)])
                }
            } else {
                let name = String(chars[(index + 1)..<end])
                if let value = UPParseTags.entities[name] {
                    chars.replaceSubrange(index...end, with: Array(value))
                } else if name == "amp", amp {
                    chars.replaceSubrange(index...end, with: ["&"])
                }
            }
            index = firstIndex(of: "&", in: chars, from: index + 1)
        }
        return String(chars)
    }

    static func firstIndex(of char: Character, in chars: [Character], from start: Int) -> Int {
        guard start < chars.count else { return -1 }
        var index = max(start, 0)
        while index < chars.count {
            if chars[index] == char { return index }
            index += 1
        }
        return -1
    }
}
