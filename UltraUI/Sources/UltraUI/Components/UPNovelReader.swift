import Foundation
import Observation
import SwiftUI

// MARK: - 数值/文本工具

enum UPNovelReaderMath {
    static func clamp01(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    static func clampNumber(_ value: Double, minimum: Double, maximum: Double, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, minimum), maximum)
    }

    static func finiteIndex(_ value: Double) -> Int? {
        guard value.isFinite else { return nil }
        return Int(value)
    }

    /// 复刻 JS `parseFloat` 的前缀解析：`"600px"` → 600，`"bogus"` → nil。
    static func parseFloat(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var buffer = ""
        var seenDot = false
        var seenDigit = false
        for (offset, character) in trimmed.enumerated() {
            if offset == 0, character == "+" || character == "-" {
                buffer.append(character)
                continue
            }
            if character.isASCII, character.isNumber {
                buffer.append(character)
                seenDigit = true
                continue
            }
            if character == ".", !seenDot {
                buffer.append(character)
                seenDot = true
                continue
            }
            break
        }
        guard seenDigit else { return nil }
        return Double(buffer)
    }

    static func isCJK(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        let value = scalar.value
        return (0x3400...0x9FFF).contains(value)
            || (0x3040...0x30FF).contains(value)
            || (0xFF00...0xFFEF).contains(value)
    }

    static func splitLines(_ input: String) -> [String] {
        input
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }
}

// MARK: - 章节与正文

/// 章节数据，对应上游 `chapters` / `current-chapter` 的单项。
public struct UPNovelReaderChapter: Equatable, Sendable, Identifiable {
    public var id: String
    public var index: Double
    public var title: String
    public var content: String
    public var isLocked: Bool

    public init(id: String, index: Double, title: String = "", content: String = "", isLocked: Bool = false) {
        self.id = id
        self.index = index
        self.title = title
        self.content = content
        self.isLocked = isLocked
    }
}

/// 归一化后的段落，`startOffset` / `endOffset` 是整章全局字符偏移。
public struct UPNovelReaderParagraph: Equatable, Sendable, Identifiable {
    public var index: Int
    public var text: String
    public var startOffset: Int
    public var endOffset: Int

    public var id: Int { index }

    public init(index: Int, text: String, startOffset: Int, endOffset: Int) {
        self.index = index
        self.text = text
        self.startOffset = startOffset
        self.endOffset = endOffset
    }
}

/// 对应上游 `content-normalizer.js`：把字符串或字符串数组拆成段落并记录偏移。
public struct UPNovelReaderContent: Equatable, Sendable {
    public var paragraphs: [UPNovelReaderParagraph]
    public var text: String
    public var length: Int

    public static let empty = UPNovelReaderContent(paragraphs: [], text: "", length: 0)

    public init(paragraphs: [UPNovelReaderParagraph], text: String, length: Int) {
        self.paragraphs = paragraphs
        self.text = text
        self.length = length
    }

    public static func normalize(_ input: String) -> UPNovelReaderContent {
        normalize([input])
    }

    public static func normalize(_ input: [String]) -> UPNovelReaderContent {
        var parts: [String] = []
        for item in input {
            parts.append(contentsOf: UPNovelReaderMath.splitLines(item))
        }
        guard parts.contains(where: { !$0.isEmpty }) else { return .empty }

        var paragraphs: [UPNovelReaderParagraph] = []
        var offset = 0
        for (index, text) in parts.enumerated() {
            let end = offset + text.count
            paragraphs.append(UPNovelReaderParagraph(index: index, text: text, startOffset: offset, endOffset: end))
            offset = end + 1
        }
        let joined = parts.joined(separator: "\n")
        return UPNovelReaderContent(paragraphs: paragraphs, text: joined, length: joined.count)
    }
}

// MARK: - 阅读进度

/// 对应上游 `reader-core.js` 的 progress 载荷。
public struct UPNovelReaderProgress: Equatable, Sendable {
    public var chapterId: String
    public var chapterIndex: Int
    public var pageIndex: Int
    public var pageCount: Int
    public var charOffset: Int
    public var chapterProgress: Double
    public var totalProgress: Double
    public var scrollTop: Double
    public var updatedAt: Double

    public init(chapterId: String = "", chapterIndex: Int = 0, pageIndex: Int = 0, pageCount: Int = 0,
                charOffset: Int = 0, chapterProgress: Double = 0, totalProgress: Double = 0,
                scrollTop: Double = 0, updatedAt: Double = 0) {
        self.chapterId = chapterId
        self.chapterIndex = chapterIndex
        self.pageIndex = pageIndex
        self.pageCount = pageCount
        self.charOffset = charOffset
        self.chapterProgress = chapterProgress
        self.totalProgress = totalProgress
        self.scrollTop = scrollTop
        self.updatedAt = updatedAt
    }

    public static func normalize(_ progress: UPNovelReaderProgress?,
                                chapter: UPNovelReaderChapter?) -> UPNovelReaderProgress {
        let contentLength = UPNovelReaderContent.normalize(chapter?.content ?? "").length
        let charOffset = min(contentLength, max(0, progress?.charOffset ?? 0))
        let chapterIndex: Int
        if let index = chapter.flatMap({ UPNovelReaderMath.finiteIndex($0.index) }) {
            chapterIndex = index
        } else {
            chapterIndex = progress?.chapterIndex ?? 0
        }
        let chapterId: String
        if let requested = progress?.chapterId, !requested.isEmpty {
            chapterId = requested
        } else {
            chapterId = chapter?.id ?? ""
        }
        return UPNovelReaderProgress(
            chapterId: chapterId,
            chapterIndex: chapterIndex,
            pageIndex: max(0, progress?.pageIndex ?? 0),
            pageCount: max(0, progress?.pageCount ?? 0),
            charOffset: charOffset,
            chapterProgress: contentLength > 0
                ? UPNovelReaderMath.clamp01(Double(charOffset) / Double(contentLength))
                : 0,
            totalProgress: UPNovelReaderMath.clamp01(progress?.totalProgress ?? 0),
            scrollTop: max(0, progress?.scrollTop ?? 0),
            updatedAt: progress?.updatedAt ?? 0
        )
    }
}

// MARK: - 正文宽度

/// 对应上游 `contentWidth`：既支持百分比/像素字符串，也支持纯数字。
public enum UPNovelReaderContentWidth: Equatable, Sendable {
    case number(Double)
    case text(String)

    public static func normalize(_ value: UPNovelReaderContentWidth?) -> UPNovelReaderContentWidth {
        switch value {
        case let .number(number):
            return .number(UPNovelReaderMath.clampNumber(number, minimum: 40, maximum: 100, fallback: 92))
        case let .text(text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? .text("92%") : .text(trimmed)
        case nil:
            return .text("92%")
        }
    }

    public func resolve(containerWidth: Double) -> Double {
        switch self {
        case let .number(number):
            return number
        case let .text(text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasSuffix("%") {
                let percent = UPNovelReaderMath.clampNumber(
                    UPNovelReaderMath.parseFloat(trimmed) ?? 92, minimum: 40, maximum: 100, fallback: 92
                )
                return containerWidth * percent / 100
            }
            guard let parsed = UPNovelReaderMath.parseFloat(trimmed) else { return containerWidth }
            return min(containerWidth, max(1, parsed))
        }
    }
}

// MARK: - 阅读设置

/// 对应上游 `readerSettings` 的增量补丁，未设置的字段沿用上一层。
public struct UPNovelReaderSettingsPatch: Equatable, Sendable {
    public var theme: String?
    public var fontSize: Double?
    public var lineHeight: Double?
    public var paragraphSpacing: Double?
    public var contentWidth: UPNovelReaderContentWidth?
    public var fontFamily: String?
    public var fontWeight: Int?
    public var animation: Bool?

    public init(theme: String? = nil, fontSize: Double? = nil, lineHeight: Double? = nil,
                paragraphSpacing: Double? = nil, contentWidth: UPNovelReaderContentWidth? = nil,
                fontFamily: String? = nil, fontWeight: Int? = nil, animation: Bool? = nil) {
        self.theme = theme
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.paragraphSpacing = paragraphSpacing
        self.contentWidth = contentWidth
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.animation = animation
    }
}

/// 合并并夹紧后的最终阅读设置。
public struct UPNovelReaderSettings: Equatable, Sendable {
    public var theme: String
    public var fontSize: Double
    public var lineHeight: Double
    public var paragraphSpacing: Double
    public var contentWidth: UPNovelReaderContentWidth
    public var fontFamily: String
    public var fontWeight: Int
    public var animation: Bool

    public static let `default` = UPNovelReaderSettings(
        theme: "day", fontSize: 18, lineHeight: 1.8, paragraphSpacing: 16,
        contentWidth: .text("92%"), fontFamily: "system", fontWeight: 400, animation: true
    )

    public init(theme: String, fontSize: Double, lineHeight: Double, paragraphSpacing: Double,
                contentWidth: UPNovelReaderContentWidth, fontFamily: String, fontWeight: Int, animation: Bool) {
        self.theme = theme
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.paragraphSpacing = paragraphSpacing
        self.contentWidth = contentWidth
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.animation = animation
    }

    public static func merge(_ patches: [UPNovelReaderSettingsPatch?]) -> UPNovelReaderSettings {
        var merged = UPNovelReaderSettings.default
        for patch in patches.compactMap({ $0 }) {
            if let theme = patch.theme { merged.theme = theme }
            if let fontSize = patch.fontSize { merged.fontSize = fontSize }
            if let lineHeight = patch.lineHeight { merged.lineHeight = lineHeight }
            if let paragraphSpacing = patch.paragraphSpacing { merged.paragraphSpacing = paragraphSpacing }
            if let contentWidth = patch.contentWidth { merged.contentWidth = contentWidth }
            if let fontFamily = patch.fontFamily { merged.fontFamily = fontFamily }
            if let fontWeight = patch.fontWeight { merged.fontWeight = fontWeight }
            if let animation = patch.animation { merged.animation = animation }
        }
        merged.fontSize = UPNovelReaderMath.clampNumber(merged.fontSize, minimum: 12, maximum: 48, fallback: 18)
        merged.lineHeight = UPNovelReaderMath.clampNumber(merged.lineHeight, minimum: 1, maximum: 3, fallback: 1.8)
        merged.paragraphSpacing = UPNovelReaderMath.clampNumber(
            merged.paragraphSpacing, minimum: 0, maximum: 80, fallback: 16
        )
        merged.contentWidth = UPNovelReaderContentWidth.normalize(merged.contentWidth)
        merged.fontWeight = merged.fontWeight >= 600 ? 600 : 400
        return merged
    }
}

/// 对应上游 `mode`：滚动或翻页。
public enum UPNovelReaderMode: String, Equatable, Sendable {
    case scroll
    case page

    public static func normalize(_ value: String) -> UPNovelReaderMode {
        UPNovelReaderMode(rawValue: value) ?? .scroll
    }
}

/// 对应上游 `THEME_TOKENS`，非法主题回落 `day`。
public struct UPNovelReaderThemeTokens: Equatable, Sendable {
    public var theme: String
    public var background: String
    public var text: String
    public var muted: String
    public var toolbar: String
    public var border: String
    public var active: String
    public var disabled: String

    private static let tokens: [String: [String]] = [
        "day": ["#f7f8fa", "#303133", "#909399", "#ffffff", "rgba(48,49,51,0.12)", "#2979ff", "#c8c9cc"],
        "paper": ["#f3ead7", "#51483d", "#8f806d", "#f7efdf", "rgba(81,72,61,0.16)", "#9b7653", "#c7b9a3"],
        "green": ["#e7f1e4", "#3f5140", "#708371", "#eef6eb", "rgba(63,81,64,0.16)", "#4d8b55", "#b6c7b4"],
        "night": ["#202124", "#d6d7da", "#9ca0a8", "#292b30", "rgba(214,215,218,0.16)", "#7da7ff", "#62656d"],
        "dark": ["#111214", "#e5e7eb", "#9ca3af", "#1b1d21", "rgba(229,231,235,0.16)", "#8ab4ff", "#5f6368"]
    ]

    public static func resolve(_ theme: String) -> UPNovelReaderThemeTokens {
        let key = tokens[theme] == nil ? "day" : theme
        let values = tokens[key] ?? tokens["day"]!
        return UPNovelReaderThemeTokens(
            theme: key, background: values[0], text: values[1], muted: values[2],
            toolbar: values[3], border: values[4], active: values[5], disabled: values[6]
        )
    }
}

/// 书签，`id` 由 `chapterId` 与偏移拼成，保证幂等切换。
public struct UPNovelReaderBookmark: Equatable, Sendable, Identifiable {
    public var chapterId: String
    public var chapterIndex: Int
    public var charOffset: Int
    public var pageIndex: Int
    public var scrollTop: Double
    public var excerpt: String
    public var createdAt: Double

    public var id: String { "\(chapterId):\(max(0, charOffset))" }

    public init(chapterId: String, chapterIndex: Int, charOffset: Int, pageIndex: Int = 0,
                scrollTop: Double = 0, excerpt: String = "", createdAt: Double = 0) {
        self.chapterId = chapterId
        self.chapterIndex = chapterIndex
        self.charOffset = charOffset
        self.pageIndex = pageIndex
        self.scrollTop = scrollTop
        self.excerpt = excerpt
        self.createdAt = createdAt
    }

    public static func toggle(_ bookmarks: [UPNovelReaderBookmark],
                             bookmark: UPNovelReaderBookmark) -> [UPNovelReaderBookmark] {
        if bookmarks.contains(where: { $0.id == bookmark.id }) {
            return bookmarks.filter { $0.id != bookmark.id }
        }
        return bookmarks + [bookmark]
    }
}

/// 对应上游 `measure-adapter.js` 的等宽估算：CJK 占满字号，空白 0.28，其余 0.56。
public enum UPNovelReaderTextMeasure {
    public static func width(_ text: String, fontSize: Double) -> Double {
        var total: Double = 0
        for character in text {
            if UPNovelReaderMath.isCJK(character) {
                total += fontSize
            } else if character.isWhitespace {
                total += fontSize * 0.28
            } else {
                total += fontSize * 0.56
            }
        }
        return total
    }
}

// MARK: - 分页排版

/// 排版后的一行，偏移是整章全局字符偏移。
public struct UPNovelReaderLine: Equatable, Sendable {
    public var text: String
    public var startOffset: Int
    public var endOffset: Int
    public var paragraphIndex: Int

    public init(text: String, startOffset: Int, endOffset: Int, paragraphIndex: Int = 0) {
        self.text = text
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.paragraphIndex = paragraphIndex
    }
}

/// 翻页模式下的一页。
public struct UPNovelReaderPage: Equatable, Sendable, Identifiable {
    public var index: Int
    public var text: String
    public var lines: [UPNovelReaderLine]
    public var startOffset: Int
    public var endOffset: Int

    public var id: Int { index }

    public init(index: Int, text: String, lines: [UPNovelReaderLine], startOffset: Int, endOffset: Int) {
        self.index = index
        self.text = text
        self.lines = lines
        self.startOffset = startOffset
        self.endOffset = endOffset
    }
}

/// 字符偏移在分页结果中的落点。
public struct UPNovelReaderAnchor: Equatable, Sendable {
    public var pageIndex: Int
    public var localOffset: Int

    public init(pageIndex: Int, localOffset: Int) {
        self.pageIndex = pageIndex
        self.localOffset = localOffset
    }
}

/// 对应上游 `layout-engine.js`。
public struct UPNovelReaderLayout: Equatable, Sendable {
    public var pages: [UPNovelReaderPage]
    public var pageCount: Int

    public static let empty = UPNovelReaderLayout(pages: [], pageCount: 0)

    public init(pages: [UPNovelReaderPage], pageCount: Int) {
        self.pages = pages
        self.pageCount = pageCount
    }

    public func anchor(charOffset: Int) -> UPNovelReaderAnchor {
        guard !pages.isEmpty else { return UPNovelReaderAnchor(pageIndex: 0, localOffset: 0) }
        let offset = max(0, charOffset)
        let page = pages.first { offset <= $0.endOffset } ?? pages[pages.count - 1]
        let local = min(max(offset - page.startOffset, 0), page.text.count)
        return UPNovelReaderAnchor(pageIndex: page.index, localOffset: local)
    }

    private struct Token {
        var text: String
        var start: Int
    }

    private static func tokenize(_ text: String) -> [Token] {
        var tokens: [Token] = []
        var buffer = ""
        var bufferStart = 0
        for (index, character) in text.enumerated() {
            if UPNovelReaderMath.isCJK(character) || character.isWhitespace {
                if !buffer.isEmpty {
                    tokens.append(Token(text: buffer, start: bufferStart))
                    buffer = ""
                }
                tokens.append(Token(text: String(character), start: index))
                bufferStart = index + 1
            } else {
                if buffer.isEmpty { bufferStart = index }
                buffer.append(character)
            }
        }
        if !buffer.isEmpty { tokens.append(Token(text: buffer, start: bufferStart)) }
        return tokens
    }

    public static func wrapText(_ text: String, width: Double,
                               measure: (String) -> Double) -> [UPNovelReaderLine] {
        var units: [Token] = []
        for token in tokenize(text) {
            if measure(token.text) > width, token.text.count > 1 {
                for (offset, character) in token.text.enumerated() {
                    units.append(Token(text: String(character), start: token.start + offset))
                }
            } else {
                units.append(token)
            }
        }

        var lines: [UPNovelReaderLine] = []
        var current: [Token] = []

        func flush() {
            guard let first = current.first, let last = current.last else { return }
            lines.append(UPNovelReaderLine(
                text: current.map(\.text).joined(),
                startOffset: first.start,
                endOffset: last.start + last.text.count
            ))
            current = []
        }

        for unit in units {
            let candidateText = current.map(\.text).joined() + unit.text
            if !current.isEmpty, measure(candidateText) > width {
                flush()
                current = [unit]
            } else {
                current.append(unit)
            }
        }
        flush()

        if lines.isEmpty {
            return [UPNovelReaderLine(text: "", startOffset: 0, endOffset: 0)]
        }
        return lines
    }

    static func lineHeight(for settings: UPNovelReaderSettings) -> Double {
        let value = settings.lineHeight
        guard value.isFinite else { return max(1, settings.fontSize * 1.8) }
        return max(1, value <= 4 ? settings.fontSize * value : value)
    }

    public static func paginate(paragraphs: [UPNovelReaderParagraph], width: Double, height: Double,
                               settings: UPNovelReaderSettings,
                               measure: (String) -> Double) -> UPNovelReaderLayout {
        guard !paragraphs.isEmpty else { return .empty }
        let boxWidth = max(1, width.isFinite && width > 0 ? width : 320)
        let boxHeight = max(1, height.isFinite && height > 0 ? height : 500)
        let spacing = max(0, settings.paragraphSpacing.isFinite ? settings.paragraphSpacing : 0)
        let rowHeight = lineHeight(for: settings)

        var pages: [UPNovelReaderPage] = []
        var lines: [UPNovelReaderLine] = []
        var usedHeight: Double = 0

        func flushPage() {
            guard !lines.isEmpty else { return }
            pages.append(UPNovelReaderPage(
                index: pages.count,
                text: lines.map(\.text).joined(separator: "\n"),
                lines: lines,
                startOffset: lines[0].startOffset,
                endOffset: lines[lines.count - 1].endOffset
            ))
            lines = []
            usedHeight = 0
        }

        for paragraph in paragraphs {
            let wrapped = wrapText(paragraph.text, width: boxWidth, measure: measure).map { line in
                UPNovelReaderLine(
                    text: line.text,
                    startOffset: line.startOffset + paragraph.startOffset,
                    endOffset: line.endOffset + paragraph.startOffset,
                    paragraphIndex: paragraph.index
                )
            }

            if paragraph.index > 0, !lines.isEmpty {
                if usedHeight + spacing + rowHeight > boxHeight {
                    flushPage()
                } else {
                    usedHeight += spacing
                }
            }

            for line in wrapped {
                if !lines.isEmpty, usedHeight + rowHeight > boxHeight { flushPage() }
                lines.append(line)
                usedHeight += rowHeight
            }
        }
        flushPage()

        return UPNovelReaderLayout(pages: pages, pageCount: pages.count)
    }

    public static func layoutKey(chapterId: String, settings: UPNovelReaderSettings,
                                width: Double, height: Double) -> String {
        let contentWidth: String
        switch settings.contentWidth {
        case let .number(number): contentWidth = "n\(number)"
        case let .text(text): contentWidth = "t\(text)"
        }
        return [
            chapterId,
            "\(width)",
            "\(height)",
            "\(settings.fontSize)",
            "\(settings.lineHeight)",
            "\(settings.paragraphSpacing)",
            contentWidth,
            settings.fontFamily,
            "\(settings.fontWeight)"
        ].joined(separator: "|")
    }
}

// MARK: - 持久化

/// 章节请求失败时透传给上层的错误信息。
public struct UPNovelReaderError: Equatable, Sendable {
    public var message: String
    public init(message: String) { self.message = message }
}

/// 抽象存储层，方便单测注入内存实现。
public protocol UPNovelReaderStorage: AnyObject {
    func readData(forKey key: String) -> Data?
    func writeData(_ data: Data, forKey key: String)
    func removeData(forKey key: String)
}

extension UserDefaults: UPNovelReaderStorage {
    public func readData(forKey key: String) -> Data? { data(forKey: key) }
    public func writeData(_ data: Data, forKey key: String) { set(data, forKey: key) }
    public func removeData(forKey key: String) { removeObject(forKey: key) }
}

/// 内存存储，仅用于测试与预览。
public final class UPNovelReaderMemoryStorage: UPNovelReaderStorage {
    private var values: [String: Data] = [:]

    public init() {}

    public func readData(forKey key: String) -> Data? { values[key] }
    public func writeData(_ data: Data, forKey key: String) { values[key] = data }
    public func removeData(forKey key: String) { values.removeValue(forKey: key) }

    /// 直接写入原始 JSON 文本，用于构造脏数据场景。
    public func writeRaw(_ raw: String, forKey key: String) {
        values[key] = Data(raw.utf8)
    }
}

/// 落盘快照，对应上游 `persistence.js` 的 payload。
public struct UPNovelReaderPersistedState: Equatable, Sendable {
    public var progress: UPNovelReaderProgress?
    public var settings: UPNovelReaderSettingsPatch?
    public var bookmarks: [UPNovelReaderBookmark]
    public var readingTime: Double
    public var updatedAt: Double

    public static let empty = UPNovelReaderPersistedState()

    public init(progress: UPNovelReaderProgress? = nil, settings: UPNovelReaderSettingsPatch? = nil,
                bookmarks: [UPNovelReaderBookmark] = [], readingTime: Double = 0, updatedAt: Double = 0) {
        self.progress = progress
        self.settings = settings
        self.bookmarks = bookmarks
        self.readingTime = readingTime
        self.updatedAt = updatedAt
    }

    public static func storageKey(storageKey: String, bookId: String) -> String {
        let trimmedKey = storageKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty { return trimmedKey }
        let trimmedBookId = bookId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBookId.isEmpty else { return "" }
        return UPNovelReaderPersistence.keyPrefix + trimmedBookId
    }
}

/// 读写落盘快照，脏数据一律丢弃而不是抛错。
public enum UPNovelReaderPersistence {
    static let keyPrefix = "uview-plus:novel-reader:"
    static let storageVersion = 1

    public static func read(key: String, storage: any UPNovelReaderStorage) -> UPNovelReaderPersistedState? {
        guard !key.isEmpty, let data = storage.readData(forKey: key) else { return nil }
        guard let raw = try? JSONSerialization.jsonObject(with: data),
              let payload = raw as? [String: Any],
              numberValue(payload["version"]).map({ Int($0) }) == storageVersion else {
            storage.removeData(forKey: key)
            return nil
        }

        let readingTime = numberValue(payload["readingTime"]) ?? 0
        let updatedAt = numberValue(payload["updatedAt"]) ?? 0
        guard readingTime.isFinite, readingTime >= 0, updatedAt.isFinite, updatedAt >= 0 else {
            storage.removeData(forKey: key)
            return nil
        }

        return UPNovelReaderPersistedState(
            progress: decodeProgress(payload["progress"]),
            settings: decodeSettings(payload["settings"]),
            bookmarks: decodeBookmarks(payload["bookmarks"]),
            readingTime: readingTime,
            updatedAt: updatedAt
        )
    }

    public static func write(key: String, state: UPNovelReaderPersistedState,
                            storage: any UPNovelReaderStorage, updatedAt: Double) -> Bool {
        guard !key.isEmpty else { return false }
        var payload: [String: Any] = [
            "version": storageVersion,
            "readingTime": max(0, state.readingTime.isFinite ? state.readingTime : 0),
            "updatedAt": updatedAt,
            "bookmarks": state.bookmarks.map(encodeBookmark)
        ]
        if let progress = state.progress { payload["progress"] = encodeProgress(progress) }
        if let settings = state.settings { payload["settings"] = encodeSettings(settings) }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        storage.writeData(data, forKey: key)
        return true
    }

    private static func numberValue(_ value: Any?) -> Double? {
        // JSON 的 null 会解析成 NSNull，它不是 NSNumber，所以这里只需一次条件转换。
        guard let number = value as? NSNumber else { return nil }
        return number.doubleValue
    }

    private static func decodeProgress(_ value: Any?) -> UPNovelReaderProgress? {
        guard let dict = value as? [String: Any] else { return nil }
        var progress = UPNovelReaderProgress()
        if let chapterId = dict["chapterId"] as? String { progress.chapterId = chapterId }

        for field in ["chapterIndex", "pageIndex", "pageCount", "charOffset", "scrollTop"] {
            guard dict[field] != nil else { continue }
            guard let number = numberValue(dict[field]), number.isFinite, number >= 0 else { return nil }
            switch field {
            case "chapterIndex": progress.chapterIndex = Int(number)
            case "pageIndex": progress.pageIndex = Int(number)
            case "pageCount": progress.pageCount = Int(number)
            case "charOffset": progress.charOffset = Int(number)
            default: progress.scrollTop = number
            }
        }

        for field in ["chapterProgress", "totalProgress"] {
            guard dict[field] != nil else { continue }
            guard let number = numberValue(dict[field]), number.isFinite, number >= 0, number <= 1 else { return nil }
            if field == "chapterProgress" { progress.chapterProgress = number } else { progress.totalProgress = number }
        }

        if let updatedAt = numberValue(dict["updatedAt"]), updatedAt.isFinite { progress.updatedAt = updatedAt }
        return progress
    }

    private static func encodeProgress(_ progress: UPNovelReaderProgress) -> [String: Any] {
        [
            "chapterId": progress.chapterId,
            "chapterIndex": progress.chapterIndex,
            "pageIndex": progress.pageIndex,
            "pageCount": progress.pageCount,
            "charOffset": progress.charOffset,
            "chapterProgress": progress.chapterProgress,
            "totalProgress": progress.totalProgress,
            "scrollTop": progress.scrollTop,
            "updatedAt": progress.updatedAt
        ]
    }

    private static func decodeSettings(_ value: Any?) -> UPNovelReaderSettingsPatch? {
        guard let dict = value as? [String: Any] else { return nil }
        var contentWidth: UPNovelReaderContentWidth?
        if let text = dict["contentWidth"] as? String {
            contentWidth = .text(text)
        } else if let number = numberValue(dict["contentWidth"]) {
            contentWidth = .number(number)
        }
        return UPNovelReaderSettingsPatch(
            theme: dict["theme"] as? String,
            fontSize: numberValue(dict["fontSize"]),
            lineHeight: numberValue(dict["lineHeight"]),
            paragraphSpacing: numberValue(dict["paragraphSpacing"]),
            contentWidth: contentWidth,
            fontFamily: dict["fontFamily"] as? String,
            fontWeight: numberValue(dict["fontWeight"]).map { Int($0) },
            animation: dict["animation"] as? Bool
        )
    }

    private static func encodeSettings(_ patch: UPNovelReaderSettingsPatch) -> [String: Any] {
        var dict: [String: Any] = [:]
        if let theme = patch.theme { dict["theme"] = theme }
        if let fontSize = patch.fontSize { dict["fontSize"] = fontSize }
        if let lineHeight = patch.lineHeight { dict["lineHeight"] = lineHeight }
        if let paragraphSpacing = patch.paragraphSpacing { dict["paragraphSpacing"] = paragraphSpacing }
        switch patch.contentWidth {
        case let .number(number): dict["contentWidth"] = number
        case let .text(text): dict["contentWidth"] = text
        case nil: break
        }
        if let fontFamily = patch.fontFamily { dict["fontFamily"] = fontFamily }
        if let fontWeight = patch.fontWeight { dict["fontWeight"] = fontWeight }
        if let animation = patch.animation { dict["animation"] = animation }
        return dict
    }

    private static func decodeBookmarks(_ value: Any?) -> [UPNovelReaderBookmark] {
        guard let items = value as? [Any] else { return [] }
        return items.compactMap { item in
            guard let dict = item as? [String: Any],
                  let identifier = dict["id"] as? String, !identifier.isEmpty,
                  let chapterId = dict["chapterId"] as? String, !chapterId.isEmpty,
                  let charOffset = numberValue(dict["charOffset"]), charOffset.isFinite, charOffset >= 0 else {
                return nil
            }
            return UPNovelReaderBookmark(
                chapterId: chapterId,
                chapterIndex: Int(numberValue(dict["chapterIndex"]) ?? 0),
                charOffset: Int(charOffset),
                pageIndex: Int(numberValue(dict["pageIndex"]) ?? 0),
                scrollTop: numberValue(dict["scrollTop"]) ?? 0,
                excerpt: dict["excerpt"] as? String ?? "",
                createdAt: numberValue(dict["createdAt"]) ?? 0
            )
        }
    }

    private static func encodeBookmark(_ bookmark: UPNovelReaderBookmark) -> [String: Any] {
        [
            "id": bookmark.id,
            "chapterId": bookmark.chapterId,
            "chapterIndex": bookmark.chapterIndex,
            "charOffset": bookmark.charOffset,
            "pageIndex": bookmark.pageIndex,
            "scrollTop": bookmark.scrollTop,
            "excerpt": bookmark.excerpt,
            "createdAt": bookmark.createdAt
        ]
    }
}

// MARK: - 事件载荷

/// 需要上层拉取章节时的请求描述。
public struct UPNovelReaderChapterRequest: Equatable, Sendable {
    public var targetIndex: Int
    public var targetId: String
    public var direction: String
    public var requestId: String

    public init(targetIndex: Int, targetId: String, direction: String, requestId: String) {
        self.targetIndex = targetIndex
        self.targetId = targetId
        self.direction = direction
        self.requestId = requestId
    }
}

/// 临近章节末尾时的预取提示。
public struct UPNovelReaderChapterPrefetch: Equatable, Sendable {
    public var targetIndex: Int
    public var targetId: String
    public var direction: String

    public init(targetIndex: Int, targetId: String, direction: String) {
        self.targetIndex = targetIndex
        self.targetId = targetId
        self.direction = direction
    }
}

/// 版面测量完成后的回调载荷。
public struct UPNovelReaderLayoutReady: Equatable, Sendable {
    public var mode: UPNovelReaderMode
    public var width: Double
    public var height: Double
    public var pageCount: Int

    public init(mode: UPNovelReaderMode, width: Double, height: Double, pageCount: Int) {
        self.mode = mode
        self.width = width
        self.height = height
        self.pageCount = pageCount
    }
}

/// 工具栏显隐变化。
public struct UPNovelReaderToolbarChange: Equatable, Sendable {
    public var visible: Bool
    public var reason: String

    public init(visible: Bool, reason: String) {
        self.visible = visible
        self.reason = reason
    }
}

/// 阅读设置变化。
public struct UPNovelReaderSettingsChange: Equatable, Sendable {
    public var mode: UPNovelReaderMode
    public var settings: UPNovelReaderSettings

    public init(mode: UPNovelReaderMode, settings: UPNovelReaderSettings) {
        self.mode = mode
        self.settings = settings
    }
}

/// 阅读时长变化。
public struct UPNovelReaderReadingTime: Equatable, Sendable {
    public var readingTime: Double
    public var delta: Double
    public var updatedAt: Double

    public init(readingTime: Double, delta: Double, updatedAt: Double) {
        self.readingTime = readingTime
        self.delta = delta
        self.updatedAt = updatedAt
    }
}

/// 点击区域，对应上游左/中/右三段热区。
public enum UPNovelReaderTapZone: Equatable, Sendable {
    case left
    case center
    case right
}

struct UPNovelReaderViewport: Equatable, Sendable {
    var width: Double = 0
    var height: Double = 0
}

// MARK: - 可变状态

/// SwiftUI 的 View 必须是值类型，因此可变状态集中放在这个引用盒里。
@MainActor
@Observable
private final class UPNovelReaderStateBox {
    var pendingChapter: UPNovelReaderChapterRequest?
    var pageIndex: Int = 0
    var layout: UPNovelReaderLayout = .empty
    var localProgress: UPNovelReaderProgress?
    var localBookmarks: [UPNovelReaderBookmark] = []
    var localSettings: UPNovelReaderSettingsPatch?
    var readingTime: Double = 0
    var readingActive: Bool = false
    var readingLastActiveAt: Double = 0
    var scrollTop: Double = 0
    var scrollHeight: Double = 0
    var viewport = UPNovelReaderViewport()
    var controlsVisible: Bool = false
    var prefetchedTargets: Set<String> = []
    var refreshToken: Int = 0
    var showCatalog: Bool = false
    var showSettings: Bool = false

    init() {}
}

// MARK: - 组件

/// SwiftUI 版 uview-plus `u-novel-reader`：章节排版、进度、书签与阅读时长全部按上游语义复刻。
@MainActor
public struct UPNovelReader: View {
    public let chapters: [UPNovelReaderChapter]
    public let currentChapter: UPNovelReaderChapter?
    public let loading: Bool
    public let error: UPNovelReaderError?
    public let bookId: String
    public let storageKey: String
    public let persist: Bool
    public let initialProgress: UPNovelReaderProgress?
    public let progress: UPNovelReaderProgress?
    public let initialBookmarks: [UPNovelReaderBookmark]
    public let bookmarks: [UPNovelReaderBookmark]?
    public let defaultSettings: UPNovelReaderSettingsPatch?
    public let settings: UPNovelReaderSettingsPatch?
    public let mode: String
    public let showBack: Bool
    public let autoBack: Bool
    public let backIcon: String
    public let safeAreaInsetTop: Bool
    public let safeAreaInsetBottom: Bool
    public let preloadThreshold: Int
    public let pageAnimation: Bool
    public let controlsAutoHide: Int

    private let storage: any UPNovelReaderStorage
    private let clock: () -> Double

    @State private var state: UPNovelReaderStateBox

    private var onChapterRequestHandler: ((UPNovelReaderChapterRequest) -> Void)?
    private var onChapterPrefetchHandler: ((UPNovelReaderChapterPrefetch) -> Void)?
    private var onProgressChangeHandler: ((UPNovelReaderProgress) -> Void)?
    private var onSettingsChangeHandler: ((UPNovelReaderSettingsChange) -> Void)?
    private var onBookmarkChangeHandler: (([UPNovelReaderBookmark]) -> Void)?
    private var onReadingTimeChangeHandler: ((UPNovelReaderReadingTime) -> Void)?
    private var onBackHandler: (() -> Void)?
    private var onModeChangeHandler: ((UPNovelReaderMode) -> Void)?
    private var onToolbarChangeHandler: ((UPNovelReaderToolbarChange) -> Void)?
    private var onLayoutReadyHandler: ((UPNovelReaderLayoutReady) -> Void)?
    private var onRetryHandler: ((UPNovelReaderChapterRequest?) -> Void)?

    public init(chapters: [UPNovelReaderChapter] = [],
                currentChapter: UPNovelReaderChapter? = nil,
                loading: Bool = false,
                error: UPNovelReaderError? = nil,
                bookId: String = "",
                storageKey: String = "",
                persist: Bool = true,
                initialProgress: UPNovelReaderProgress? = nil,
                progress: UPNovelReaderProgress? = nil,
                initialBookmarks: [UPNovelReaderBookmark] = [],
                bookmarks: [UPNovelReaderBookmark]? = nil,
                defaultSettings: UPNovelReaderSettingsPatch? = nil,
                settings: UPNovelReaderSettingsPatch? = nil,
                mode: String = "scroll",
                showBack: Bool = true,
                autoBack: Bool = false,
                backIcon: String = "arrow-left",
                safeAreaInsetTop: Bool = true,
                safeAreaInsetBottom: Bool = true,
                preloadThreshold: Int = 2,
                pageAnimation: Bool = true,
                controlsAutoHide: Int = 0,
                storage: any UPNovelReaderStorage = UserDefaults.standard,
                clock: @escaping () -> Double = { Date().timeIntervalSince1970 * 1000 }) {
        self.chapters = chapters
        self.currentChapter = currentChapter
        self.loading = loading
        self.error = error
        self.bookId = bookId
        self.storageKey = storageKey
        self.persist = persist
        self.initialProgress = initialProgress
        self.progress = progress
        self.initialBookmarks = initialBookmarks
        self.bookmarks = bookmarks
        self.defaultSettings = defaultSettings
        self.settings = settings
        self.mode = mode
        self.showBack = showBack
        self.autoBack = autoBack
        self.backIcon = backIcon
        self.safeAreaInsetTop = safeAreaInsetTop
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.preloadThreshold = preloadThreshold
        self.pageAnimation = pageAnimation
        self.controlsAutoHide = controlsAutoHide
        self.storage = storage
        self.clock = clock

        let box = UPNovelReaderStateBox()
        let key = UPNovelReaderPersistedState.storageKey(storageKey: storageKey, bookId: bookId)
        let persisted = persist && !key.isEmpty
            ? UPNovelReaderPersistence.read(key: key, storage: storage)
            : nil
        if progress == nil { box.localProgress = initialProgress ?? persisted?.progress }
        if bookmarks == nil {
            box.localBookmarks = initialBookmarks.isEmpty ? (persisted?.bookmarks ?? []) : initialBookmarks
        }
        if settings == nil { box.localSettings = persisted?.settings }
        box.readingTime = persisted?.readingTime ?? 0
        self._state = State(initialValue: box)
    }
}

// MARK: - 派生状态

extension UPNovelReader {
    /// 归一化后的阅读模式，非法值回落 `scroll`。
    public var resolvedMode: UPNovelReaderMode { UPNovelReaderMode.normalize(mode) }

    /// 默认设置、本地设置与受控设置三层合并后的最终阅读设置。
    public var resolvedSettings: UPNovelReaderSettings {
        UPNovelReaderSettings.merge([defaultSettings, state.localSettings, settings])
    }

    /// 当前主题色板。
    public var themeTokens: UPNovelReaderThemeTokens { UPNovelReaderThemeTokens.resolve(resolvedSettings.theme) }

    /// 只有 `pageAnimation` 与设置里的 `animation` 同时开启才播放翻页动画。
    public var effectiveAnimation: Bool { pageAnimation && resolvedSettings.animation }

    /// 工具栏是否可见。
    public var controlsVisible: Bool { state.controlsVisible }

    /// 翻页模式下的最新分页结果，滚动模式恒为 `.empty`。
    public var layout: UPNovelReaderLayout { state.layout }

    /// 当前页码（翻页模式）。
    public var pageIndex: Int { state.pageIndex }

    /// 累计阅读时长（毫秒）。
    public var readingTime: Double { state.readingTime }

    /// 正在等待上层响应的章节请求。
    public var pendingChapter: UPNovelReaderChapterRequest? { state.pendingChapter }

    /// 实际使用的持久化键，`storageKey` 优先，其次由 `bookId` 拼接。
    public var resolvedStorageKey: String {
        UPNovelReaderPersistedState.storageKey(storageKey: storageKey, bookId: bookId)
    }

    /// 当前章节归一化后的正文。
    public var normalizedContent: UPNovelReaderContent {
        UPNovelReaderContent.normalize(currentChapter?.content ?? "")
    }

    /// 当前章节序号，`index` 非有限时回落到按 `id` 查表。
    public var currentChapterIndex: Int {
        if let index = currentChapter.flatMap({ UPNovelReaderMath.finiteIndex($0.index) }) { return index }
        guard let identifier = currentChapter?.id else { return -1 }
        return chapters.firstIndex { $0.id == identifier } ?? -1
    }

    /// 是否存在可跳转的上一章（锁定章节不计）。
    public var hasPreviousChapter: Bool {
        let current = currentChapterIndex
        return chapters.contains { chapter in
            guard !chapter.isLocked, let index = UPNovelReaderMath.finiteIndex(chapter.index) else { return false }
            return index < current
        }
    }

    /// 是否存在可跳转的下一章（锁定章节不计）。
    public var hasNextChapter: Bool {
        let current = currentChapterIndex
        return chapters.contains { chapter in
            guard !chapter.isLocked, let index = UPNovelReaderMath.finiteIndex(chapter.index) else { return false }
            return index > current
        }
    }

    /// 受控进度优先，其次是本地进度，最后按当前章节夹紧。
    public var currentProgress: UPNovelReaderProgress {
        UPNovelReaderProgress.normalize(progress ?? state.localProgress, chapter: currentChapter)
    }

    /// 受控书签优先，否则用本地书签。
    public var resolvedBookmarks: [UPNovelReaderBookmark] { bookmarks ?? state.localBookmarks }

    /// 当前阅读位置是否已加书签。
    public var isCurrentBookmarked: Bool {
        guard let chapterId = currentChapter?.id, !chapterId.isEmpty else { return false }
        let offset = currentProgress.charOffset
        return resolvedBookmarks.contains { $0.chapterId == chapterId && $0.charOffset == offset }
    }
}

// MARK: - 事件绑定

extension UPNovelReader {
    public func onChapterRequest(_ action: @escaping (UPNovelReaderChapterRequest) -> Void) -> UPNovelReader {
        var copy = self
        copy.onChapterRequestHandler = action
        return copy
    }

    public func onChapterPrefetch(_ action: @escaping (UPNovelReaderChapterPrefetch) -> Void) -> UPNovelReader {
        var copy = self
        copy.onChapterPrefetchHandler = action
        return copy
    }

    public func onProgressChange(_ action: @escaping (UPNovelReaderProgress) -> Void) -> UPNovelReader {
        var copy = self
        copy.onProgressChangeHandler = action
        return copy
    }

    public func onSettingsChange(_ action: @escaping (UPNovelReaderSettingsChange) -> Void) -> UPNovelReader {
        var copy = self
        copy.onSettingsChangeHandler = action
        return copy
    }

    public func onBookmarkChange(_ action: @escaping ([UPNovelReaderBookmark]) -> Void) -> UPNovelReader {
        var copy = self
        copy.onBookmarkChangeHandler = action
        return copy
    }

    public func onReadingTimeChange(_ action: @escaping (UPNovelReaderReadingTime) -> Void) -> UPNovelReader {
        var copy = self
        copy.onReadingTimeChangeHandler = action
        return copy
    }

    public func onBack(_ action: @escaping () -> Void) -> UPNovelReader {
        var copy = self
        copy.onBackHandler = action
        return copy
    }

    public func onModeChange(_ action: @escaping (UPNovelReaderMode) -> Void) -> UPNovelReader {
        var copy = self
        copy.onModeChangeHandler = action
        return copy
    }

    public func onToolbarChange(_ action: @escaping (UPNovelReaderToolbarChange) -> Void) -> UPNovelReader {
        var copy = self
        copy.onToolbarChangeHandler = action
        return copy
    }

    public func onLayoutReady(_ action: @escaping (UPNovelReaderLayoutReady) -> Void) -> UPNovelReader {
        var copy = self
        copy.onLayoutReadyHandler = action
        return copy
    }

    public func onRetry(_ action: @escaping (UPNovelReaderChapterRequest?) -> Void) -> UPNovelReader {
        var copy = self
        copy.onRetryHandler = action
        return copy
    }
}

// MARK: - 排版与滚动

extension UPNovelReader {
    /// 容器尺寸变化后重新测量：滚动模式只回调事件，翻页模式重新分页并对齐锚点。
    public func refreshLayout(width: Double, height: Double) {
        state.viewport = UPNovelReaderViewport(width: width, height: height)
        guard resolvedMode == .page else {
            state.layout = .empty
            onLayoutReadyHandler?(UPNovelReaderLayoutReady(mode: resolvedMode, width: width,
                                                           height: height, pageCount: 0))
            return
        }
        let settings = resolvedSettings
        let contentWidth = settings.contentWidth.resolve(containerWidth: width)
        state.layout = UPNovelReaderLayout.paginate(
            paragraphs: normalizedContent.paragraphs,
            width: contentWidth,
            height: max(1, height - 64),
            settings: settings,
            measure: { UPNovelReaderTextMeasure.width($0, fontSize: settings.fontSize) }
        )
        state.pageIndex = state.layout.anchor(charOffset: currentProgress.charOffset).pageIndex
        onLayoutReadyHandler?(UPNovelReaderLayoutReady(mode: .page, width: width, height: height,
                                                       pageCount: state.layout.pageCount))
    }

    /// 滚动模式下同步滚动位置并派发进度。
    public func handleScroll(scrollTop: Double, scrollHeight: Double? = nil) {
        activateReading()
        state.scrollTop = max(0, scrollTop.isFinite ? scrollTop : 0)
        let height = scrollHeight ?? state.scrollHeight
        state.scrollHeight = max(0, height.isFinite ? height : 0)
        emitProgress()
    }

    /// 左/中/右三段热区：中间开关工具栏，两侧在翻页模式下翻页。
    public func handleTapZone(_ zone: UPNovelReaderTapZone) {
        activateReading()
        if zone == .center {
            toggleControls(reason: "tap-center")
            return
        }
        guard resolvedMode == .page else { return }
        movePage(zone == .left ? -1 : 1)
    }

    /// 收起工具栏，已隐藏时不重复派发事件。
    public func hideControls() {
        guard state.controlsVisible else { return }
        state.controlsVisible = false
        onToolbarChangeHandler?(UPNovelReaderToolbarChange(visible: false, reason: "toolbar-action"))
    }

    func toggleControls(reason: String) {
        state.controlsVisible.toggle()
        onToolbarChangeHandler?(UPNovelReaderToolbarChange(visible: state.controlsVisible, reason: reason))
    }

    func movePage(_ offset: Int) {
        let next = state.pageIndex + offset
        guard next >= 0, next < state.layout.pageCount else {
            _ = requestChapter(direction: offset < 0 ? "previous" : "next")
            return
        }
        state.pageIndex = next
        emitProgress(pageIndex: next, charOffset: state.layout.pages[next].startOffset)
    }

    private func resolveScrollProgress() -> Double {
        guard state.scrollHeight > state.viewport.height else { return 0 }
        return UPNovelReaderMath.clamp01(state.scrollTop / max(1, state.scrollHeight - state.viewport.height))
    }

    private func emitProgress(pageIndex overridePageIndex: Int? = nil,
                              charOffset overrideCharOffset: Int? = nil,
                              scrollTop overrideScrollTop: Double? = nil) {
        let pages = state.layout.pages
        let page = pages.indices.contains(state.pageIndex) ? pages[state.pageIndex] : nil
        let pageCount = state.layout.pageCount
        let scrollProgress = resolveScrollProgress()
        let chapterProgress = pageCount > 0
            ? UPNovelReaderMath.clamp01(Double(state.pageIndex + 1) / Double(pageCount))
            : scrollProgress
        let derivedOffset = page?.startOffset
            ?? Int((Double(normalizedContent.length) * scrollProgress).rounded())
        let total = chapters.isEmpty
            ? 0
            : UPNovelReaderMath.clamp01((Double(currentChapterIndex) + chapterProgress) / Double(chapters.count))
        let result = UPNovelReaderProgress(
            chapterId: currentChapter?.id ?? "",
            chapterIndex: currentChapterIndex,
            pageIndex: overridePageIndex ?? state.pageIndex,
            pageCount: pageCount,
            charOffset: overrideCharOffset ?? derivedOffset,
            chapterProgress: chapterProgress,
            totalProgress: total,
            scrollTop: overrideScrollTop ?? state.scrollTop,
            updatedAt: clock()
        )
        if progress == nil { state.localProgress = result }
        onProgressChangeHandler?(result)
        queuePersist()
        emitPrefetchIfNeeded()
    }

    private func emitPrefetchIfNeeded() {
        guard resolvedMode == .page, state.layout.pageCount > 0 else { return }
        guard state.layout.pageCount - state.pageIndex <= max(0, preloadThreshold) else { return }
        let current = currentChapterIndex
        guard let target = chapters.first(where: { chapter in
            guard !chapter.isLocked, let index = UPNovelReaderMath.finiteIndex(chapter.index) else { return false }
            return index > current
        }) else { return }
        guard !state.prefetchedTargets.contains(target.id) else { return }
        state.prefetchedTargets.insert(target.id)
        onChapterPrefetchHandler?(UPNovelReaderChapterPrefetch(
            targetIndex: UPNovelReaderMath.finiteIndex(target.index) ?? current + 1,
            targetId: target.id,
            direction: "next"
        ))
    }
}

// MARK: - 章节调度

extension UPNovelReader {
    /// 请求切换章节，返回是否真的发出了请求。
    public func requestChapter(direction: String, targetIndex: Int? = nil) -> Bool {
        guard !loading, state.pendingChapter == nil else { return false }
        let nextIndex = targetIndex ?? currentChapterIndex + (direction == "previous" ? -1 : 1)
        guard let target = resolveChapter(at: nextIndex), !target.isLocked else { return false }
        let stamp = clock()
        state.refreshToken += 1
        let payload = UPNovelReaderChapterRequest(
            targetIndex: UPNovelReaderMath.finiteIndex(target.index) ?? nextIndex,
            targetId: target.id,
            direction: direction,
            requestId: "\(stamp.isFinite ? Int(stamp) : 0)-\(state.refreshToken)"
        )
        state.pendingChapter = payload
        _ = flushPersistence()
        onChapterRequestHandler?(payload)
        return true
    }

    /// 章节加载失败后重试，把上一次的请求原样交回上层。
    public func handleRetry() {
        let payload = state.pendingChapter
        state.pendingChapter = nil
        onRetryHandler?(payload)
    }

    /// 目录点选。
    public func selectChapter(_ chapter: UPNovelReaderChapter) {
        _ = requestChapter(direction: "catalog", targetIndex: UPNovelReaderMath.finiteIndex(chapter.index))
    }

    /// 书签点选：同章直接跳位置，跨章走目录请求。
    public func selectBookmark(_ bookmark: UPNovelReaderBookmark) {
        guard bookmark.chapterId == currentChapter?.id else {
            _ = requestChapter(direction: "catalog", targetIndex: bookmark.chapterIndex)
            return
        }
        state.pageIndex = max(0, bookmark.pageIndex)
        state.scrollTop = max(0, bookmark.scrollTop)
        emitProgress(charOffset: max(0, bookmark.charOffset), scrollTop: max(0, bookmark.scrollTop))
    }

    private func resolveChapter(at index: Int) -> UPNovelReaderChapter? {
        if let matched = chapters.first(where: { UPNovelReaderMath.finiteIndex($0.index) == index }) { return matched }
        guard index >= 0, index < chapters.count else { return nil }
        return chapters[index]
    }
}

// MARK: - 书签、设置与阅读时长

extension UPNovelReader {
    /// 在当前位置增删书签。
    public func toggleBookmark() {
        guard let chapterId = currentChapter?.id, !chapterId.isEmpty else { return }
        let offset = currentProgress.charOffset
        let bookmark = UPNovelReaderBookmark(
            chapterId: chapterId,
            chapterIndex: currentChapterIndex,
            charOffset: offset,
            pageIndex: state.pageIndex,
            scrollTop: state.scrollTop,
            excerpt: excerpt(around: offset),
            createdAt: clock()
        )
        let list = UPNovelReaderBookmark.toggle(resolvedBookmarks, bookmark: bookmark)
        if bookmarks == nil { state.localBookmarks = list }
        onBookmarkChangeHandler?(list)
        queuePersist()
    }

    /// 写入阅读设置增量并重新排版。
    public func applySettings(_ patch: UPNovelReaderSettingsPatch) {
        state.localSettings = patch
        onSettingsChangeHandler?(UPNovelReaderSettingsChange(
            mode: resolvedMode,
            settings: UPNovelReaderSettings.merge([patch])
        ))
        queuePersist()
        refreshLayout(width: state.viewport.width, height: state.viewport.height)
    }

    /// 开始计时，加载中或报错时不计。
    public func activateReading() {
        guard !loading, error == nil, currentChapter != nil else { return }
        guard !state.readingActive else { return }
        state.readingActive = true
        state.readingLastActiveAt = clock()
    }

    /// 结束计时并累加时长。
    public func pauseReading() {
        guard state.readingActive else { return }
        let now = clock()
        let delta = max(0, now - state.readingLastActiveAt)
        state.readingTime += delta
        state.readingActive = false
        state.readingLastActiveAt = 0
        onReadingTimeChangeHandler?(UPNovelReaderReadingTime(readingTime: state.readingTime,
                                                             delta: delta, updatedAt: now))
        queuePersist()
    }

    /// 返回按钮。
    public func handleBack() {
        onBackHandler?()
    }

    /// 阅读模式变化后重新排版并回调。
    public func syncMode() {
        refreshLayout(width: state.viewport.width, height: state.viewport.height)
        onModeChangeHandler?(resolvedMode)
    }

    /// 立即落盘，返回是否真的写入。
    public func flushPersistence() -> Bool {
        let key = resolvedStorageKey
        guard persist, !key.isEmpty else { return false }
        let settings = resolvedSettings
        let snapshot = UPNovelReaderPersistedState(
            progress: currentProgress,
            settings: UPNovelReaderSettingsPatch(
                theme: settings.theme,
                fontSize: settings.fontSize,
                lineHeight: settings.lineHeight,
                paragraphSpacing: settings.paragraphSpacing,
                contentWidth: settings.contentWidth,
                fontFamily: settings.fontFamily,
                fontWeight: settings.fontWeight,
                animation: settings.animation
            ),
            bookmarks: resolvedBookmarks,
            readingTime: state.readingTime
        )
        return UPNovelReaderPersistence.write(key: key, state: snapshot, storage: storage, updatedAt: clock())
    }

    private func queuePersist() {
        _ = flushPersistence()
    }

    private func excerpt(around offset: Int) -> String {
        let text = normalizedContent.text
        guard !text.isEmpty else { return "" }
        let length = text.count
        let lower = min(max(0, offset - 12), length)
        let upper = min(max(0, offset + 28), length)
        guard lower < upper else { return "" }
        let start = text.index(text.startIndex, offsetBy: lower)
        let end = text.index(text.startIndex, offsetBy: upper)
        return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 视图

extension UPNovelReader {
    private static let scrollSpace = "up-novel-reader-scroll"

    private var titleText: String {
        let title = currentChapter?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "小说阅读" : title
    }

    private var contentBoxWidth: CGFloat? {
        let width = state.viewport.width
        guard width > 0 else { return nil }
        return CGFloat(resolvedSettings.contentWidth.resolve(containerWidth: width))
    }

    private var bodyFont: Font {
        let settings = resolvedSettings
        return .system(size: CGFloat(settings.fontSize),
                       weight: settings.fontWeight >= 600 ? .semibold : .regular)
    }

    private var bodyLineSpacing: CGFloat {
        let settings = resolvedSettings
        return CGFloat(max(0, UPNovelReaderLayout.lineHeight(for: settings) - settings.fontSize))
    }

    private var separatorColor: Color {
        UPColor.parse(themeTokens.text).opacity(0.12)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                UPColor.parse(themeTokens.background).ignoresSafeArea()
                contentLayer
                if resolvedMode == .page { tapZoneLayer }
                if controlsVisible { controlsLayer }
            }
            .onAppear {
                refreshLayout(width: Double(proxy.size.width), height: Double(proxy.size.height))
                activateReading()
            }
            .onDisappear { pauseReading() }
            .onChange(of: proxy.size) { _, size in
                refreshLayout(width: Double(size.width), height: Double(size.height))
            }
            .onChange(of: resolvedMode) { _, _ in syncMode() }
            .onChange(of: currentChapter?.id) { _, _ in
                state.pendingChapter = nil
                state.prefetchedTargets.removeAll()
                state.scrollTop = 0
                refreshLayout(width: Double(proxy.size.width), height: Double(proxy.size.height))
            }
        }
        .foregroundStyle(UPColor.parse(themeTokens.text))
        .overlay(catalogPopup)
        .overlay(settingsPopup)
    }

    @ViewBuilder
    private var contentLayer: some View {
        if loading {
            placeholder("章节加载中…")
        } else if let error {
            VStack(spacing: 12) {
                Text(error.message)
                    .font(.system(size: 14))
                    .foregroundStyle(UPColor.parse(themeTokens.muted))
                    .multilineTextAlignment(.center)
                Button("重试") { handleRetry() }
                    .font(.system(size: 14))
                    .foregroundStyle(UPColor.parse(themeTokens.active))
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if normalizedContent.paragraphs.isEmpty {
            placeholder("暂无正文")
        } else if resolvedMode == .page {
            pageContent
        } else {
            scrollContent
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(UPColor.parse(themeTokens.muted))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var currentPageText: String {
        let pages = state.layout.pages
        guard pages.indices.contains(state.pageIndex) else { return "" }
        return pages[state.pageIndex].text
    }

    private var pageContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(currentPageText)
                .font(bodyFont)
                .lineSpacing(bodyLineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .frame(width: contentBoxWidth)
        .padding(.vertical, 52)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(effectiveAnimation ? .easeInOut(duration: 0.2) : nil, value: state.pageIndex)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CGFloat(resolvedSettings.paragraphSpacing)) {
                Text(titleText)
                    .font(.system(size: CGFloat(resolvedSettings.fontSize + 4), weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(normalizedContent.paragraphs) { paragraph in
                    Text(paragraph.text)
                        .font(bodyFont)
                        .lineSpacing(bodyLineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: contentBoxWidth)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(scrollProbe)
        }
        .coordinateSpace(.named(Self.scrollSpace))
        .contentShape(Rectangle())
        .onTapGesture { handleTapZone(.center) }
    }

    private var scrollProbe: some View {
        GeometryReader { inner in
            Color.clear
                .onChange(of: Self.probeFrame(inner)) { _, frame in
                    handleScroll(scrollTop: Double(-frame.minY), scrollHeight: Double(frame.height))
                }
        }
    }

    private static func probeFrame(_ proxy: GeometryProxy) -> CGRect {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return proxy.frame(in: space)
    }

    private var tapZoneLayer: some View {
        HStack(spacing: 0) {
            tapZone(.left)
            tapZone(.center)
            tapZone(.right)
        }
    }

    private func tapZone(_ zone: UPNovelReaderTapZone) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { handleTapZone(zone) }
    }
}

// MARK: - 工具栏

extension UPNovelReader {
    private var controlsLayer: some View {
        VStack(spacing: 0) {
            topToolbar
            Spacer(minLength: 0)
            bottomToolbar
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 16) {
            if showBack {
                UPIcon(name: backIcon, color: themeTokens.text, size: "20", onTap: { handleBack() })
            }
            Text(titleText)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            UPIcon(name: "list", color: themeTokens.text, size: "20", onTap: { state.showCatalog = true })
            UPIcon(name: "bookmark",
                   color: isCurrentBookmarked ? themeTokens.active : themeTokens.text,
                   size: "20",
                   onTap: { toggleBookmark() })
            UPIcon(name: "close", color: themeTokens.text, size: "20", onTap: { hideControls() })
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(UPColor.parse(themeTokens.toolbar))
        .overlay(alignment: .bottom) { separatorColor.frame(height: 0.5) }
    }

    private var progressLabel: String {
        let percent = Int((currentProgress.chapterProgress * 100).rounded())
        let pageCount = state.layout.pageCount
        guard resolvedMode == .page, pageCount > 0 else { return "\(percent)%" }
        return "\(min(state.pageIndex + 1, pageCount))/\(pageCount) · \(percent)%"
    }

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            UPIcon(name: "arrow-left",
                   color: hasPreviousChapter ? themeTokens.text : themeTokens.disabled,
                   size: "20",
                   onTap: { _ = requestChapter(direction: "previous") })
            Text(progressLabel)
                .font(.system(size: 13))
                .foregroundStyle(UPColor.parse(themeTokens.muted))
                .frame(maxWidth: .infinity)
            UPIcon(name: "arrow-right",
                   color: hasNextChapter ? themeTokens.text : themeTokens.disabled,
                   size: "20",
                   onTap: { _ = requestChapter(direction: "next") })
            UPIcon(name: "setting", color: themeTokens.text, size: "20", onTap: { state.showSettings = true })
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(UPColor.parse(themeTokens.toolbar))
        .overlay(alignment: .top) { separatorColor.frame(height: 0.5) }
    }
}

// MARK: - 目录与设置弹层

extension UPNovelReader {
    private var catalogBinding: Binding<Bool> {
        Binding(get: { state.showCatalog }, set: { state.showCatalog = $0 })
    }

    private var settingsBinding: Binding<Bool> {
        Binding(get: { state.showSettings }, set: { state.showSettings = $0 })
    }

    private var catalogPopup: some View {
        UPPopup(show: catalogBinding, mode: "left", closeable: true) {
            catalogBody
        }
    }

    private var catalogBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("目录")
                ForEach(chapters) { chapter in
                    catalogRow(chapter)
                    separatorColor.frame(height: 0.5)
                }
                if !resolvedBookmarks.isEmpty {
                    sectionTitle("书签")
                    ForEach(resolvedBookmarks) { bookmark in
                        bookmarkRow(bookmark)
                        separatorColor.frame(height: 0.5)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 260)
        .frame(maxHeight: .infinity)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(UPColor.parse(themeTokens.text))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private func catalogRow(_ chapter: UPNovelReaderChapter) -> some View {
        Button {
            state.showCatalog = false
            selectChapter(chapter)
        } label: {
            HStack(spacing: 8) {
                Text(chapter.title.isEmpty ? "未命名章节" : chapter.title)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if chapter.isLocked {
                    UPIcon(name: "lock", color: themeTokens.muted, size: "14")
                } else if chapter.id == currentChapter?.id {
                    UPIcon(name: "checkmark", color: themeTokens.active, size: "14")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(chapter.isLocked)
        .foregroundStyle(UPColor.parse(chapter.isLocked ? themeTokens.disabled : themeTokens.text))
    }

    private func bookmarkRow(_ bookmark: UPNovelReaderBookmark) -> some View {
        Button {
            state.showCatalog = false
            selectBookmark(bookmark)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("第 \(bookmark.chapterIndex + 1) 章 · \(bookmark.charOffset) 字")
                    .font(.system(size: 12))
                    .foregroundStyle(UPColor.parse(themeTokens.muted))
                Text(bookmark.excerpt.isEmpty ? "无摘要" : bookmark.excerpt)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(UPColor.parse(themeTokens.text))
    }
}

// MARK: - 阅读设置弹层

extension UPNovelReader {
    private static let themeOptions: [(key: String, label: String)] = [
        ("day", "日间"), ("paper", "护眼"), ("green", "豆沙"), ("night", "夜间"), ("dark", "深色")
    ]

    private var settingsPopup: some View {
        UPPopup(show: settingsBinding, mode: "bottom", closeable: true) {
            settingsBody
        }
    }

    private var contentWidthPercent: Int {
        let raw: Double
        switch resolvedSettings.contentWidth {
        case let .number(number):
            raw = number
        case let .text(text):
            raw = UPNovelReaderMath.parseFloat(text) ?? 92
        }
        return Int(UPNovelReaderMath.clampNumber(raw, minimum: 40, maximum: 100, fallback: 92).rounded())
    }

    private func patched(theme: String? = nil, fontSize: Double? = nil, lineHeight: Double? = nil,
                         paragraphSpacing: Double? = nil, contentWidth: UPNovelReaderContentWidth? = nil,
                         fontWeight: Int? = nil) -> UPNovelReaderSettingsPatch {
        let settings = resolvedSettings
        return UPNovelReaderSettingsPatch(
            theme: theme ?? settings.theme,
            fontSize: fontSize ?? settings.fontSize,
            lineHeight: lineHeight ?? settings.lineHeight,
            paragraphSpacing: paragraphSpacing ?? settings.paragraphSpacing,
            contentWidth: contentWidth ?? settings.contentWidth,
            fontFamily: settings.fontFamily,
            fontWeight: fontWeight ?? settings.fontWeight,
            animation: settings.animation
        )
    }

    private var settingsBody: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("阅读设置")
                .font(.system(size: 15, weight: .semibold))
            HStack(spacing: 8) {
                ForEach(Self.themeOptions, id: \.key) { option in
                    themeChip(option.key, label: option.label)
                }
            }
            stepperRow("字号", value: "\(Int(resolvedSettings.fontSize))",
                       onMinus: { applySettings(patched(fontSize: resolvedSettings.fontSize - 2)) },
                       onPlus: { applySettings(patched(fontSize: resolvedSettings.fontSize + 2)) })
            stepperRow("行高", value: String(format: "%.1f", resolvedSettings.lineHeight),
                       onMinus: { applySettings(patched(lineHeight: resolvedSettings.lineHeight - 0.1)) },
                       onPlus: { applySettings(patched(lineHeight: resolvedSettings.lineHeight + 0.1)) })
            stepperRow("段距", value: "\(Int(resolvedSettings.paragraphSpacing))",
                       onMinus: { applySettings(patched(paragraphSpacing: resolvedSettings.paragraphSpacing - 4)) },
                       onPlus: { applySettings(patched(paragraphSpacing: resolvedSettings.paragraphSpacing + 4)) })
            stepperRow("宽度", value: "\(contentWidthPercent)%",
                       onMinus: { applySettings(patched(contentWidth: .text("\(contentWidthPercent - 4)%"))) },
                       onPlus: { applySettings(patched(contentWidth: .text("\(contentWidthPercent + 4)%"))) })
            HStack(spacing: 12) {
                Text("加粗").font(.system(size: 14))
                Spacer(minLength: 0)
                Button(resolvedSettings.fontWeight >= 600 ? "已开启" : "已关闭") {
                    applySettings(patched(fontWeight: resolvedSettings.fontWeight >= 600 ? 400 : 600))
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(UPColor.parse(
                    resolvedSettings.fontWeight >= 600 ? themeTokens.active : themeTokens.muted
                ))
            }
            HStack(spacing: 12) {
                Text("排版模式").font(.system(size: 14))
                Spacer(minLength: 0)
                Text(resolvedMode == .page ? "翻页" : "滚动")
                    .font(.system(size: 13))
                    .foregroundStyle(UPColor.parse(themeTokens.muted))
            }
        }
        .foregroundStyle(UPColor.parse(themeTokens.text))
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
    }

    private func themeChip(_ key: String, label: String) -> some View {
        let active = resolvedSettings.theme == key
        return Button(label) { applySettings(patched(theme: key)) }
            .buttonStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(active ? Color.white : UPColor.parse(themeTokens.text))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(UPColor.parse(active ? themeTokens.active : themeTokens.toolbar))
            )
    }

    private func stepperRow(_ title: String, value: String,
                            onMinus: @escaping () -> Void,
                            onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.system(size: 14))
            Spacer(minLength: 0)
            UPIcon(name: "minus", color: themeTokens.text, size: "16", onTap: onMinus)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(UPColor.parse(themeTokens.muted))
                .frame(minWidth: 46)
            UPIcon(name: "plus", color: themeTokens.text, size: "16", onTap: onPlus)
        }
    }
}
