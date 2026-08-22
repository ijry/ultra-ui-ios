import SwiftUI

/// Mirrors the upstream `String | Number` props on the notice family.
public typealias UPNoticeUnitValue = UPCheckboxUnitValue

/// Mirrors the upstream `Array | String` `text` prop on `u-notice-bar`.
public protocol UPNoticeTextValue {
    var upNoticeTexts: [String] { get }
}

extension String: UPNoticeTextValue {
    /// A single string is one notice; an empty string is none, matching the
    /// upstream default of `[]`.
    public var upNoticeTexts: [String] { isEmpty ? [] : [self] }
}

extension Array: UPNoticeTextValue where Element == String {
    public var upNoticeTexts: [String] { self }
}

@MainActor
private final class UPNoticeState {
    var current: Int
    var closed = false

    init(current: Int) {
        self.current = current
    }
}

/// Shared notice item model for the row and column notice variants.
public struct UPNoticeItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var text: String
    public var url: String

    public init(id: String? = nil, text: String, url: String = "") {
        self.id = id ?? text
        self.text = text
        self.url = url
    }
}

/// Shared behavior for the notice family's `mode` prop. Upstream has no
/// `closable` prop: the right-hand icon is chosen entirely by `mode`.
public enum UPNoticeMode {
    public static func resolved(_ mode: String) -> String {
        switch mode {
        case "link", "closable": return mode
        default: return ""
        }
    }

    public static func showsLinkIcon(_ mode: String) -> Bool {
        resolved(mode) == "link"
    }

    public static func showsCloseIcon(_ mode: String) -> Bool {
        resolved(mode) == "closable"
    }
}

/// Vertical notice carousel corresponding to uview-plus `u-column-notice`.
@MainActor
public struct UPColumnNotice: View {
    public var texts: [String]
    public var icon: String
    public var mode: String
    public var color: String
    public var bgColor: String
    public var fontSize: Double
    public var speed: Double
    public var step: Bool
    public var duration: Double
    public var disableTouch: Bool
    public var justifyContent: String

    /// Existing native shorthand retained for source compatibility.
    public var notices: [String] { texts }
    public var current: Int { state.current }
    public var isClosed: Bool { state.closed }
    public var showsLinkIcon: Bool { UPNoticeMode.showsLinkIcon(mode) }
    public var showsCloseIcon: Bool { UPNoticeMode.showsCloseIcon(mode) }

    private let state: UPNoticeState
    private var onClickHandler: ((String) -> Void)?
    private var onChangeHandler: ((Int) -> Void)?
    private var onCloseHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    public init(text: some UPNoticeTextValue = [String](),
                current: Int = 0,
                icon: String = UPConfig.columnNotice.icon,
                mode: String = UPConfig.columnNotice.mode,
                color: String = UPConfig.columnNotice.color,
                bgColor: String = UPConfig.columnNotice.bgColor,
                fontSize: some UPNoticeUnitValue = UPConfig.columnNotice.fontSize,
                speed: some UPNoticeUnitValue = UPConfig.columnNotice.speed,
                step: Bool = UPConfig.columnNotice.step,
                duration: some UPNoticeUnitValue = UPConfig.columnNotice.duration,
                disableTouch: Bool = UPConfig.columnNotice.disableTouch,
                justifyContent: String = UPConfig.columnNotice.justifyContent) {
        let texts = text.upNoticeTexts
        self.texts = texts
        self.icon = icon
        self.mode = mode
        self.color = color
        self.bgColor = bgColor
        self.fontSize = UPNoticeBar.dimension(fontSize, fallback: UPConfig.columnNotice.fontSize)
        self.speed = UPNoticeBar.dimension(speed, fallback: UPConfig.columnNotice.speed)
        self.step = step
        self.duration = UPNoticeBar.dimension(duration, fallback: UPConfig.columnNotice.duration)
        self.disableTouch = disableTouch
        self.justifyContent = UPFlexValue.justify(justifyContent)
        self.state = UPNoticeState(current: Self.clamp(current, count: texts.count))
    }

    /// Legacy initializer retained for source compatibility with the earlier
    /// UltraUI API, which used `notices`, `interval` and `autoplay`.
    public init(notices: [String], current: Int = 0, interval: Int = 3_000, autoplay: Bool = true) {
        self.init(
            text: notices,
            current: current,
            duration: Double(max(interval, 0)),
            disableTouch: !autoplay
        )
    }

    public var body: some View {
        UPNoticeRow(
            text: currentText,
            icon: icon,
            mode: mode,
            color: color,
            bgColor: bgColor,
            fontSize: fontSize,
            justifyContent: justifyContent,
            isClosed: isClosed,
            onTap: { click() },
            onClose: close
        )
    }

    public func select(_ index: Int) {
        let next = Self.clamp(index, count: texts.count)
        guard next != current else { return }
        state.current = next
        onChangeHandler?(next)
    }

    public func click(_ text: String? = nil) {
        guard let text = text ?? texts[safe: current] else { return }
        onClickHandler?(text)
    }

    public func close() {
        guard showsCloseIcon, !isClosed else { return }
        state.closed = true
        onCloseHandler?()
    }

    public func onClick(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onCloseHandler = action; return copy
    }

    private var currentText: String {
        texts[safe: current] ?? ""
    }

    private static func clamp(_ index: Int, count: Int) -> Int {
        count == 0 ? 0 : min(max(index, 0), count - 1)
    }
}

/// Horizontal notice carousel corresponding to uview-plus `u-row-notice`.
@MainActor
public struct UPRowNotice: View {
    public var texts: [String]
    public var icon: String
    public var mode: String
    public var color: String
    public var bgColor: String
    public var fontSize: Double
    public var speed: Double

    /// Existing native shorthand retained for source compatibility.
    public var notices: [String] { texts }
    public var current: Int { state.current }
    public var isClosed: Bool { state.closed }
    public var showsLinkIcon: Bool { UPNoticeMode.showsLinkIcon(mode) }
    public var showsCloseIcon: Bool { UPNoticeMode.showsCloseIcon(mode) }

    private let state: UPNoticeState
    private var onClickHandler: ((Int) -> Void)?
    private var onChangeHandler: ((Int) -> Void)?
    private var onCloseHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    public init(text: some UPNoticeTextValue = [String](),
                current: Int = 0,
                icon: String = UPConfig.rowNotice.icon,
                mode: String = UPConfig.rowNotice.mode,
                color: String = UPConfig.rowNotice.color,
                bgColor: String = UPConfig.rowNotice.bgColor,
                fontSize: some UPNoticeUnitValue = UPConfig.rowNotice.fontSize,
                speed: some UPNoticeUnitValue = UPConfig.rowNotice.speed) {
        let texts = text.upNoticeTexts
        self.texts = texts
        self.icon = icon
        self.mode = mode
        self.color = color
        self.bgColor = bgColor
        self.fontSize = UPNoticeBar.dimension(fontSize, fallback: UPConfig.rowNotice.fontSize)
        self.speed = UPNoticeBar.dimension(speed, fallback: UPConfig.rowNotice.speed)
        self.state = UPNoticeState(current: Self.clamp(current, count: texts.count))
    }

    /// Legacy initializer retained for source compatibility with the earlier
    /// UltraUI API.
    public init(notices: [String], current: Int = 0, interval: Int = 3_000, autoplay: Bool = true) {
        self.init(text: notices, current: current)
    }

    public var body: some View {
        UPNoticeRow(
            text: texts.joined(separator: "　"),
            icon: icon,
            mode: mode,
            color: color,
            bgColor: bgColor,
            fontSize: fontSize,
            justifyContent: "flex-start",
            isClosed: isClosed,
            onTap: { click() },
            onClose: close
        )
    }

    public func select(_ index: Int) {
        let next = Self.clamp(index, count: texts.count)
        guard next != current else { return }
        state.current = next
        onClickHandler?(next)
        onChangeHandler?(next)
    }

    public func click() {
        guard !texts.isEmpty else { return }
        onClickHandler?(current)
    }

    public func close() {
        guard showsCloseIcon, !isClosed else { return }
        state.closed = true
        onCloseHandler?()
    }

    public func onClick(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onCloseHandler = action; return copy
    }

    private static func clamp(_ index: Int, count: Int) -> Int {
        count == 0 ? 0 : min(max(index, 0), count - 1)
    }
}

/// Notice bar corresponding to uview-plus `u-notice-bar`. Upstream delegates to
/// `u-column-notice` when `direction` is `column` or `step` is set, and to
/// `u-row-notice` otherwise.
@MainActor
public struct UPNoticeBar: View {
    public var texts: [String]
    public var direction: String
    public var step: Bool
    public var icon: String
    public var mode: String
    public var color: String
    public var bgColor: String
    public var speed: Double
    public var fontSize: Double
    public var duration: Double
    public var disableTouch: Bool
    public var url: String
    public var linkType: String
    public var justifyContent: String

    /// Existing native shorthand retained for source compatibility.
    public var text: String { texts.first ?? "" }
    public var current: Int { state.current }
    public var isClosed: Bool { state.closed }
    public var showsLinkIcon: Bool { UPNoticeMode.showsLinkIcon(mode) }
    public var showsCloseIcon: Bool { UPNoticeMode.showsCloseIcon(mode) }
    /// Which child variant upstream would render for this configuration.
    public var variant: String { Self.resolvedVariant(direction: direction, step: step) }

    private let state = UPNoticeState(current: 0)
    private var onClickHandler: ((Int) -> Void)?
    private var onCloseHandler: (() -> Void)?
    /// Earlier native modifier hook, which carried no index.
    private var onLegacyClickHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    public init(text: some UPNoticeTextValue = [String](),
                direction: String = UPConfig.noticeBar.direction,
                step: Bool = UPConfig.noticeBar.step,
                icon: String = UPConfig.noticeBar.icon,
                mode: String = UPConfig.noticeBar.mode,
                color: String = UPConfig.noticeBar.color,
                bgColor: String = UPConfig.noticeBar.bgColor,
                speed: some UPNoticeUnitValue = UPConfig.noticeBar.speed,
                fontSize: some UPNoticeUnitValue = UPConfig.noticeBar.fontSize,
                duration: some UPNoticeUnitValue = UPConfig.noticeBar.duration,
                disableTouch: Bool = UPConfig.noticeBar.disableTouch,
                url: String = UPConfig.noticeBar.url,
                linkType: String = UPConfig.noticeBar.linkType,
                justifyContent: String = UPConfig.noticeBar.justifyContent) {
        self.texts = text.upNoticeTexts
        self.direction = Self.resolvedDirection(direction)
        self.step = step
        self.icon = icon
        self.mode = mode
        self.color = color
        self.bgColor = bgColor
        self.speed = Self.dimension(speed, fallback: UPConfig.noticeBar.speed)
        self.fontSize = Self.dimension(fontSize, fallback: UPConfig.noticeBar.fontSize)
        self.duration = Self.dimension(duration, fallback: UPConfig.noticeBar.duration)
        self.disableTouch = disableTouch
        self.url = url
        self.linkType = linkType
        self.justifyContent = UPFlexValue.justify(justifyContent)
    }

    public var body: some View {
        UPNoticeRow(
            text: displayText,
            icon: icon,
            mode: mode,
            color: color,
            bgColor: bgColor,
            fontSize: fontSize,
            justifyContent: justifyContent,
            isClosed: isClosed,
            onTap: { click() },
            onClose: close
        )
    }

    public static func resolvedDirection(_ direction: String) -> String {
        direction == "column" ? "column" : "row"
    }

    /// Upstream renders the column variant for `direction: column`, and also for
    /// `direction: row` combined with `step`.
    public static func resolvedVariant(direction: String, step: Bool) -> String {
        resolvedDirection(direction) == "column" || step ? "column" : "row"
    }

    static func dimension(_ value: some UPNoticeUnitValue, fallback: Double) -> Double {
        let parsed = Double(UPUnit.parse(value.upCheckboxUnitValue))
        return parsed > 0 ? parsed : fallback
    }

    public func select(_ index: Int) {
        let next = texts.isEmpty ? 0 : min(max(index, 0), texts.count - 1)
        guard next != current else { return }
        state.current = next
    }

    /// Upstream emits `click` with the current index, then follows `url` when set.
    public func click() {
        onClickHandler?(current)
        onLegacyClickHandler?()
    }

    public func close() {
        guard showsCloseIcon, !isClosed else { return }
        state.closed = true
        onCloseHandler?()
    }

    public func onClick(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    /// Earlier no-payload spelling, retained for source compatibility.
    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onLegacyClickHandler = action; return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onCloseHandler = action; return copy
    }

    private var displayText: String {
        if variant == "column" {
            return texts[safe: current] ?? ""
        }
        return texts.joined(separator: "　")
    }
}

/// The shared row rendering used by all three notice variants: volume icon,
/// scrolling text, and the `mode`-driven right-hand icon.
@MainActor
private struct UPNoticeRow: View {
    var text: String
    var icon: String
    var mode: String
    var color: String
    var bgColor: String
    var fontSize: Double
    var justifyContent: String
    var isClosed: Bool
    var onTap: () -> Void
    var onClose: () -> Void

    @Environment(\.upTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            if !icon.isEmpty {
                UPIcon(name: icon, color: color, size: "\(fontSize)px")
            }

            Text(text)
                .font(.system(size: fontSize))
                .foregroundStyle(UPColor.parse(color, theme: theme))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: textAlignment)

            if UPNoticeMode.showsLinkIcon(mode) {
                UPIcon(name: "arrow-right", color: color, size: "\(fontSize)px")
            }

            if UPNoticeMode.showsCloseIcon(mode) {
                Button(action: onClose) {
                    UPIcon(name: "close", color: color, size: "\(fontSize)px")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭公告")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(UPColor.parse(bgColor, theme: theme))
        .opacity(isClosed ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var textAlignment: Alignment {
        switch justifyContent {
        case "center": return .center
        case "flex-end": return .trailing
        default: return .leading
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
