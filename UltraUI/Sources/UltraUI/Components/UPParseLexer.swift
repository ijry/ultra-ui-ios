import Foundation

/// 上游 `u-parse/parser.js` 里 `Lexer` 的三种回调，原生用 token 数组承载，
/// 这样词法分析可以脱离解析器单独测试。
public enum UPParseToken: Equatable, Sendable {
    case text(String)
    case openTag(name: String, attributes: [String: String], selfClosing: Bool)
    case closeTag(String)
}

/// 上游 `Lexer` 的逐字符状态机移植：`text` / `tagName` / `attrName` / `attrVal` /
/// `endTag` 五个状态加 `checkClose`，行为与 `parser.js` 一一对应。
public struct UPParseLexer {
    /// 上游 `blankChar = makeMap(' ,\r,\n,\t,\f')`。
    public static let blankCharacters: Set<Character> = [" ", "\r", "\n", "\t", "\u{0C}"]

    private enum State {
        case text
        case tagName
        case attributeName
        case attributeValue
        case endTag
    }

    private enum Emit {
        case tagName
        case attributeName
        case attributeValue
    }

    private let characters: [Character]
    private var index = 0
    private var start = 0
    private var state: State = .text
    private var stopped = false
    private var tokens: [UPParseToken] = []
    private var tagName = ""
    private var attributes: [String: String] = [:]
    private var attributeName: String?

    private init(_ content: String) {
        characters = Array(content)
    }

    public static func tokenize(_ content: String) -> [UPParseToken] {
        var lexer = UPParseLexer(content)
        lexer.run()
        return lexer.tokens
    }

    private mutating func run() {
        while !stopped, index < characters.count {
            switch state {
            case .text: scanText()
            case .tagName: scanTagName()
            case .attributeName: scanAttributeName()
            case .attributeValue: scanAttributeValue()
            case .endTag: scanEndTag()
            }
        }
    }

    // MARK: - 状态

    private mutating func scanText() {
        guard let position = firstIndex(of: "<", from: index) else {
            if start < characters.count {
                tokens.append(.text(String(characters[start...])))
            }
            stopped = true
            return
        }
        index = position
        let next = character(at: index + 1)
        if let next, next.isASCII, next.isLetter {
            if start != index {
                tokens.append(.text(String(characters[start..<index])))
            }
            index += 1
            start = index
            state = .tagName
            return
        }
        guard let next, next == "/" || next == "!" || next == "?" else {
            index += 1
            return
        }
        if start != index {
            tokens.append(.text(String(characters[start..<index])))
        }
        let following = character(at: index + 2)
        if next == "/", let following, following.isASCII, following.isLetter {
            index += 2
            start = index
            state = .endTag
            return
        }
        // 注释：只有 `<!--` 才找 `-->`，其余找最近的 `>`。
        let isComment = next == "!" && character(at: index + 2) == "-" && character(at: index + 3) == "-"
        let terminator: [Character] = isComment ? ["-", "-", ">"] : [">"]
        guard let closing = firstIndex(of: terminator, from: index) else {
            stopped = true
            return
        }
        index = closing + terminator.count
        start = index
    }

    private mutating func scanTagName() {
        if let current = character(at: index), Self.blankCharacters.contains(current) {
            onTagName(String(characters[start..<index]))
            index += 1
            skipBlanks()
            if index < characters.count, !checkClose(nil) {
                start = index
                state = .attributeName
            }
        } else if !checkClose(.tagName) {
            index += 1
        }
    }

    private mutating func scanAttributeName() {
        guard let current = character(at: index) else {
            stopped = true
            return
        }
        guard Self.blankCharacters.contains(current) || current == "=" else {
            if !checkClose(.attributeName) { index += 1 }
            return
        }
        onAttributeName(String(characters[start..<index]))
        var needsValue = current == "="
        index += 1
        while index < characters.count {
            guard let next = character(at: index) else { break }
            if !Self.blankCharacters.contains(next) {
                if checkClose(nil) { return }
                if needsValue {
                    start = index
                    state = .attributeValue
                    return
                }
                if next == "=" {
                    needsValue = true
                } else {
                    start = index
                    state = .attributeName
                    return
                }
            }
            index += 1
        }
        stopped = true
    }

    private mutating func scanAttributeValue() {
        guard let current = character(at: index) else {
            stopped = true
            return
        }
        if current == "\"" || current == "'" {
            index += 1
            start = index
            guard let closing = firstIndex(of: current, from: index) else {
                stopped = true
                return
            }
            index = closing
            onAttributeValue(String(characters[start..<index]))
        } else {
            while index < characters.count {
                if let next = character(at: index), Self.blankCharacters.contains(next) {
                    onAttributeValue(String(characters[start..<index]))
                    break
                }
                if checkClose(.attributeValue) { return }
                index += 1
            }
        }
        index += 1
        skipBlanks()
        if index < characters.count, !checkClose(nil) {
            start = index
            state = .attributeName
        }
    }

    private mutating func scanEndTag() {
        guard let current = character(at: index) else {
            stopped = true
            return
        }
        guard Self.blankCharacters.contains(current) || current == ">" || current == "/" else {
            index += 1
            return
        }
        tokens.append(.closeTag(String(characters[start..<index]).lowercased()))
        if current != ">" {
            guard let closing = firstIndex(of: ">", from: index) else {
                stopped = true
                return
            }
            index = closing
        }
        index += 1
        start = index
        state = .text
    }

    // MARK: - checkClose

    private mutating func checkClose(_ emit: Emit?) -> Bool {
        let current = character(at: index)
        let selfClosing = current == "/"
        guard current == ">" || (selfClosing && character(at: index + 1) == ">") else { return false }
        if let emit, start <= index {
            switch emit {
            case .tagName: onTagName(String(characters[start..<index]))
            case .attributeName: onAttributeName(String(characters[start..<index]))
            case .attributeValue: onAttributeValue(String(characters[start..<index]))
            }
        }
        index += selfClosing ? 2 : 1
        start = index
        tokens.append(.openTag(name: tagName, attributes: attributes, selfClosing: selfClosing))
        attributes = [:]
        attributeName = nil
        // 上游把 `<script>` 的内容整段跳到下一个 `</`。
        if tagName == "script" {
            guard let position = firstIndex(of: ["<", "/"], from: index) else {
                stopped = true
                return true
            }
            index = position + 2
            start = index
            state = .endTag
        } else {
            state = .text
        }
        return true
    }

    // MARK: - 处理器

    private mutating func onTagName(_ name: String) {
        tagName = name.lowercased()
    }

    private mutating func onAttributeName(_ name: String) {
        let lowered = name.lowercased()
        // 上游在 APP-PLUS 下会丢掉含 `?` / `;` 的属性名。
        if lowered.contains("?") || lowered.contains(";") {
            attributeName = nil
            return
        }
        guard lowered.hasPrefix("data-") else {
            attributeName = lowered
            attributes[lowered] = "T"
            return
        }
        if lowered == "data-src", attributes["src"] == nil {
            attributeName = "src"
        } else if tagName == "img" || tagName == "a" {
            attributeName = lowered
        } else {
            attributeName = nil
        }
    }

    private mutating func onAttributeValue(_ value: String) {
        guard let name = attributeName, !name.isEmpty else { return }
        // `style` / `href` / `*src*` 需要实体解码；域名拼接留给解析器，
        // 因为 `<base>` 会在解析途中改写主域名。
        if name == "style" || name == "href" || name.contains("src") {
            attributes[name] = UPParseDocument.decodeEntity(value, amp: true)
        } else {
            attributes[name] = value
        }
    }

    // MARK: - 工具

    private mutating func skipBlanks() {
        while let current = character(at: index), Self.blankCharacters.contains(current) {
            index += 1
        }
    }

    private func character(at position: Int) -> Character? {
        position >= 0 && position < characters.count ? characters[position] : nil
    }

    private func firstIndex(of character: Character, from position: Int) -> Int? {
        var cursor = max(position, 0)
        while cursor < characters.count {
            if characters[cursor] == character { return cursor }
            cursor += 1
        }
        return nil
    }

    private func firstIndex(of subsequence: [Character], from position: Int) -> Int? {
        guard !subsequence.isEmpty, characters.count >= subsequence.count else { return nil }
        var cursor = max(position, 0)
        while cursor + subsequence.count <= characters.count {
            if Array(characters[cursor..<(cursor + subsequence.count)]) == subsequence { return cursor }
            cursor += 1
        }
        return nil
    }
}
