import Foundation

/// 上游 `u-markdown` 用 `marked@16` 把 Markdown 转成 HTML，再交给 `up-parse` 渲染。
/// 原生没有 marked，这里实现同一条链路里的转换环节：覆盖 CommonMark 的常用块级
/// 与行内语法，外加 GFM 的表格与删除线，产出的 HTML 交给 `UPParse` 消费。
///
/// 未覆盖的 marked 特性：脚注、任务列表、定义列表、HTML 直通（原样文本会被转义）、
/// 引用式链接（`[a][b]` + `[b]: url`）、行内 HTML 属性。
public enum UPMarkdownParser {
    /// 对应上游 `marked(content)` 之后再走 `handleCodeBlock`。
    public static func html(from markdown: String, showLineNumber: Bool = false) -> String {
        guard !markdown.isEmpty else { return "" }
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        return blocks(from: lines, showLineNumber: showLineNumber)
    }

    // MARK: - 块级

    private static func blocks(from lines: [String], showLineNumber: Bool) -> String {
        var html = ""
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if let fence = fenceInfo(trimmed) {
                var code: [String] = []
                index += 1
                while index < lines.count,
                      fenceInfo(lines[index].trimmingCharacters(in: .whitespaces))?.isClosing != true {
                    code.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 }
                html += codeBlock(code, language: fence.language, showLineNumber: showLineNumber)
                continue
            }

            if isThematicBreak(trimmed) {
                html += "<hr>"
                index += 1
                continue
            }

            if let heading = headingInfo(trimmed) {
                html += "<h\(heading.level)>\(inline(heading.text))</h\(heading.level)>"
                index += 1
                continue
            }

            if trimmed.hasPrefix(">") {
                var quoted: [String] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    guard candidate.hasPrefix(">") else { break }
                    var body = String(candidate.dropFirst())
                    if body.hasPrefix(" ") { body.removeFirst() }
                    quoted.append(body)
                    index += 1
                }
                html += "<blockquote>\(blocks(from: quoted, showLineNumber: showLineNumber))</blockquote>"
                continue
            }

            if let table = tableInfo(lines, from: index) {
                html += table.html
                index = table.next
                continue
            }

            if listMarker(line) != nil {
                let list = listBlock(lines, from: index, showLineNumber: showLineNumber)
                html += list.html
                index = list.next
                continue
            }

            // 段落：连续的非空行合并，遇到其它块级语法就停。
            var paragraph: [String] = []
            while index < lines.count {
                let candidate = lines[index]
                let candidateTrimmed = candidate.trimmingCharacters(in: .whitespaces)
                if candidateTrimmed.isEmpty
                    || fenceInfo(candidateTrimmed) != nil
                    || isThematicBreak(candidateTrimmed)
                    || headingInfo(candidateTrimmed) != nil
                    || candidateTrimmed.hasPrefix(">")
                    || listMarker(candidate) != nil {
                    break
                }
                paragraph.append(candidateTrimmed)
                index += 1
            }
            // marked 默认 `breaks: false`，段落内换行只当空格。
            html += "<p>\(inline(paragraph.joined(separator: " ")))</p>"
        }
        return html
    }

    /// ```lang / ~~~lang
    static func fenceInfo(_ line: String) -> (language: String, isClosing: Bool)? {
        for marker in ["```", "~~~"] where line.hasPrefix(marker) {
            let rest = String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
            return (rest, rest.isEmpty)
        }
        return nil
    }

    static func isThematicBreak(_ line: String) -> Bool {
        for marker in ["-", "*", "_"] {
            let stripped = line.replacingOccurrences(of: " ", with: "")
            if stripped.count >= 3, stripped.allSatisfy({ String($0) == marker }) { return true }
        }
        return false
    }

    static func headingInfo(_ line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard hashes >= 1, hashes <= 6 else { return nil }
        let rest = String(line.dropFirst(hashes))
        guard rest.isEmpty || rest.hasPrefix(" ") else { return nil }
        return (hashes, rest.trimmingCharacters(in: .whitespaces))
    }

    /// 列表标记：返回缩进宽度、是否有序、序号与正文。
    static func listMarker(_ line: String) -> (indent: Int, ordered: Bool, start: Int, text: String)? {
        let indent = line.prefix(while: { $0 == " " || $0 == "\t" })
            .reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
        let body = line.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return nil }
        for marker in ["- ", "* ", "+ "] where body.hasPrefix(marker) {
            return (indent, false, 1, String(body.dropFirst(marker.count)))
        }
        let digits = body.prefix(while: \.isNumber)
        guard !digits.isEmpty, let start = Int(digits) else { return nil }
        let rest = body.dropFirst(digits.count)
        guard rest.hasPrefix(". ") || rest.hasPrefix(") ") else { return nil }
        return (indent, true, start, String(rest.dropFirst(2)))
    }

    private static func listBlock(_ lines: [String],
                                  from start: Int,
                                  showLineNumber: Bool) -> (html: String, next: Int) {
        guard let first = listMarker(lines[start]) else { return ("", start + 1) }
        let baseIndent = first.indent
        var items: [[String]] = []
        var index = start
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }
            guard let marker = listMarker(line) else { break }
            if marker.indent < baseIndent { break }
            if marker.indent > baseIndent {
                // 缩进更深的行属于上一项的子内容。
                guard !items.isEmpty else { break }
                items[items.count - 1].append(String(line.dropFirst(min(baseIndent + 2, line.count))))
                index += 1
                continue
            }
            if marker.ordered != first.ordered { break }
            items.append([marker.text])
            index += 1
        }

        let body = items.map { item -> String in
            // 只有一行时按行内语法渲染，多行时递归成块（支持嵌套列表）。
            guard item.count > 1 else { return "<li>\(inline(item[0]))</li>" }
            let nested = blocks(from: Array(item.dropFirst()), showLineNumber: showLineNumber)
            return "<li>\(inline(item[0]))\(nested)</li>"
        }.joined()
        let tag = first.ordered ? "ol" : "ul"
        let attributes = first.ordered && first.start != 1 ? " start=\"\(first.start)\"" : ""
        return ("<\(tag)\(attributes)>\(body)</\(tag)>", index)
    }

    /// GFM 表格：表头 + `|---|` 分隔行 + 若干数据行。
    private static func tableInfo(_ lines: [String], from start: Int) -> (html: String, next: Int)? {
        guard start + 1 < lines.count else { return nil }
        let header = lines[start].trimmingCharacters(in: .whitespaces)
        let divider = lines[start + 1].trimmingCharacters(in: .whitespaces)
        guard header.contains("|"), isTableDivider(divider) else { return nil }
        let alignments = cells(of: divider).map { cell -> String in
            let left = cell.hasPrefix(":")
            let right = cell.hasSuffix(":")
            if left, right { return "center" }
            if right { return "right" }
            if left { return "left" }
            return ""
        }
        var html = "<table><thead><tr>"
        for (offset, cell) in cells(of: header).enumerated() {
            html += "<th\(alignmentAttribute(alignments, offset))>\(inline(cell))</th>"
        }
        html += "</tr></thead><tbody>"
        var index = start + 2
        while index < lines.count {
            let row = lines[index].trimmingCharacters(in: .whitespaces)
            guard row.contains("|"), !row.isEmpty else { break }
            html += "<tr>"
            for (offset, cell) in cells(of: row).enumerated() {
                html += "<td\(alignmentAttribute(alignments, offset))>\(inline(cell))</td>"
            }
            html += "</tr>"
            index += 1
        }
        return (html + "</tbody></table>", index)
    }

    private static func alignmentAttribute(_ alignments: [String], _ offset: Int) -> String {
        guard alignments.indices.contains(offset), !alignments[offset].isEmpty else { return "" }
        return " align=\"\(alignments[offset])\""
    }

    static func isTableDivider(_ line: String) -> Bool {
        let items = cells(of: line)
        guard !items.isEmpty else { return false }
        return items.allSatisfy { cell in
            let stripped = cell.replacingOccurrences(of: ":", with: "")
            return !stripped.isEmpty && stripped.allSatisfy { $0 == "-" }
        }
    }

    static func cells(of row: String) -> [String] {
        var line = row
        if line.hasPrefix("|") { line.removeFirst() }
        if line.hasSuffix("|") { line.removeLast() }
        return line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// 对应上游 `handleCodeBlock`：给代码块补 class，`showLineNumber` 时加行号。
    static func codeBlock(_ lines: [String], language: String, showLineNumber: Bool) -> String {
        let languageClass = language.isEmpty ? "" : " language-\(language)"
        var body = lines
        if showLineNumber {
            let width = String(body.count).count
            body = body.enumerated().map { offset, line in
                let number = String(offset + 1)
                let padding = String(repeating: " ", count: max(width - number.count, 0))
                // 上游把行号排成独立一列，原生的文本渲染器只能前置到每行。
                return "\(padding)\(number) | \(line)"
            }
        }
        let escaped = body.map(escape).joined(separator: "\n")
        return "<pre class=\"up-markdown-code\(languageClass)\">"
            + "<code class=\"code-lang\(languageClass)\">\(escaped)</code></pre>"
    }

    // MARK: - 行内

    /// 行内语法：图片、链接、粗体、斜体、删除线、行内代码。
    static func inline(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            switch character {
            case "`":
                if let closing = text.range(of: "`", range: text.index(after: index)..<text.endIndex) {
                    let code = String(text[text.index(after: index)..<closing.lowerBound])
                    result += "<code>\(escape(code))</code>"
                    index = closing.upperBound
                    continue
                }
            case "!":
                if let image = link(in: text, from: index, isImage: true) {
                    result += "<img src=\"\(escape(image.url))\" alt=\"\(escape(image.text))\">"
                    index = image.next
                    continue
                }
            case "[":
                if let anchor = link(in: text, from: index, isImage: false) {
                    result += "<a href=\"\(escape(anchor.url))\">\(inline(anchor.text))</a>"
                    index = anchor.next
                    continue
                }
            case "*", "_", "~":
                if let emphasis = emphasis(in: text, from: index) {
                    result += emphasis.html
                    index = emphasis.next
                    continue
                }
            default:
                break
            }
            result += escape(String(character))
            index = text.index(after: index)
        }
        return result
    }

    private static func link(in text: String,
                             from index: String.Index,
                             isImage: Bool) -> (text: String, url: String, next: String.Index)? {
        var cursor = index
        if isImage {
            cursor = text.index(after: cursor)
            guard cursor < text.endIndex, text[cursor] == "[" else { return nil }
        }
        guard let labelEnd = text.range(of: "](", range: cursor..<text.endIndex) else { return nil }
        guard let close = text.range(of: ")", range: labelEnd.upperBound..<text.endIndex) else { return nil }
        let label = String(text[text.index(after: cursor)..<labelEnd.lowerBound])
        let url = String(text[labelEnd.upperBound..<close.lowerBound])
        return (label, url, close.upperBound)
    }

    private static func emphasis(in text: String,
                                 from index: String.Index) -> (html: String, next: String.Index)? {
        let markers: [(token: String, open: String, close: String)] = [
            ("***", "<strong><em>", "</em></strong>"),
            ("~~", "<del>", "</del>"),
            ("**", "<strong>", "</strong>"),
            ("__", "<strong>", "</strong>"),
            ("*", "<em>", "</em>"),
            ("_", "<em>", "</em>")
        ]
        for marker in markers {
            guard text[index...].hasPrefix(marker.token) else { continue }
            let contentStart = text.index(index, offsetBy: marker.token.count)
            guard contentStart < text.endIndex,
                  let closing = text.range(of: marker.token, range: contentStart..<text.endIndex) else { continue }
            let content = String(text[contentStart..<closing.lowerBound])
            guard !content.isEmpty else { continue }
            return (marker.open + inline(content) + marker.close, closing.upperBound)
        }
        return nil
    }

    /// HTML 转义。`UPParse` 会把实体解码回来，所以只需处理这三个。
    static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
