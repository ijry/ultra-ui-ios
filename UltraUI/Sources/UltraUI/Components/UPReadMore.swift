import SwiftUI

@MainActor
private final class UPReadMoreState {
    var expanded: Bool
    /// 上游 `toggleReadMore` 在 `toggle` 为 false 时把 `isLongContent` 置为 false，
    /// 展开之后不再渲染「收起」按钮。
    var toggleHidden = false

    init(_ expanded: Bool) { self.expanded = expanded }
}

/// Expandable text container corresponding to uview-plus `u-read-more`.
@MainActor
public struct UPReadMore<Content: View>: View {
    /// 上游 `.u-read-more__content` 的字号，`textIndent` 的 `em` 以此为基准。
    public static var contentFontSize: CGFloat { 15 }

    public var lines: Int
    public var isExpanded: Bool { state.expanded }
    public var showToggle: Bool
    /// 内容超过此高度才需要折叠，上游单位为 px。
    public var showHeight: CGFloat
    /// 展开后是否保留「收起」按钮，上游默认 false。
    public var toggle: Bool
    /// 折叠态的提示文字，上游 `closeText` 默认取 `up.readMore.expand`。
    public var closeText: String
    /// 展开态的提示文字，上游 `openText` 默认取 `up.readMore.fold`。
    public var openText: String
    /// 提示文字与箭头图标的颜色。
    public var color: String
    /// 提示文字大小，上游单位为 px。
    public var fontSize: CGFloat
    /// 折叠态下盖在内容底部的渐变遮罩样式。
    public var shadowStyle: UPStyle
    /// 段落首行缩进，上游默认 `2em`。
    public var textIndent: String
    /// open / close 事件回传的标识，上游为 `String | Number`。
    public var name: String
    private let state: UPReadMoreState
    private let content: Content
    private var onChangeHandler: ((Bool) -> Void)?
    private var onOpenHandler: ((String) -> Void)?
    private var onCloseHandler: ((String) -> Void)?
    @Environment(\.upTheme) private var theme

    public init(lines: Int = 3,
                expanded: Bool = false,
                showToggle: Bool = true,
                showHeight: some UPImageUnitValue = UPConfig.readMore.showHeight,
                toggle: Bool = UPConfig.readMore.toggle,
                closeText: String = UPConfig.readMore.closeText,
                openText: String = UPConfig.readMore.openText,
                color: String = UPConfig.readMore.color,
                fontSize: some UPImageUnitValue = UPConfig.readMore.fontSize,
                shadowStyle: UPStyle = UPConfig.readMore.shadowStyle,
                textIndent: String = UPConfig.readMore.textIndent,
                name: some UPTextValue = UPConfig.readMore.name,
                @ViewBuilder content: () -> Content) {
        self.lines = max(lines, 0)
        self.showToggle = showToggle
        self.showHeight = UPUnit.parse(showHeight.upImageUnitValue)
        self.toggle = toggle
        self.closeText = closeText
        self.openText = openText
        self.color = color
        self.fontSize = UPUnit.parse(fontSize.upImageUnitValue)
        self.shadowStyle = shadowStyle
        self.textIndent = textIndent
        self.name = name.upTextValue
        self.state = UPReadMoreState(expanded)
        self.content = content()
    }

    public init(lines: Int = 3,
                expanded: Bool = false,
                showToggle: Bool = true,
                showHeight: some UPImageUnitValue = UPConfig.readMore.showHeight,
                toggle: Bool = UPConfig.readMore.toggle,
                closeText: String = UPConfig.readMore.closeText,
                openText: String = UPConfig.readMore.openText,
                color: String = UPConfig.readMore.color,
                fontSize: some UPImageUnitValue = UPConfig.readMore.fontSize,
                shadowStyle: UPStyle = UPConfig.readMore.shadowStyle,
                textIndent: String = UPConfig.readMore.textIndent,
                name: some UPTextValue = UPConfig.readMore.name) where Content == EmptyView {
        self.init(lines: lines,
                  expanded: expanded,
                  showToggle: showToggle,
                  showHeight: showHeight,
                  toggle: toggle,
                  closeText: closeText,
                  openText: openText,
                  color: color,
                  fontSize: fontSize,
                  shadowStyle: shadowStyle,
                  textIndent: textIndent,
                  name: name) { EmptyView() }
    }

    /// 上游模板按 `status === 'close' ? closeText : openText` 取文案。
    public var toggleText: String { isExpanded ? openText : closeText }

    /// 上游模板按 `status` 在 `arrow-down` 与 `arrow-up` 之间切换。
    public var toggleIconName: String { isExpanded ? "arrow-up" : "arrow-down" }

    /// 上游图标尺寸固定为 `fontSize + 2`。
    public var toggleIconSize: CGFloat { fontSize + 2 }

    /// 上游 `innerShadowStyle`：展开后无需阴影。
    public var innerShadowStyle: UPStyle { isExpanded ? UPStyle() : shadowStyle }

    /// 渐变遮罩的落地色，取 `background` 或 `backgroundImage` 里的最后一个颜色。
    public var shadowFadeColor: String { Self.fadeColor(from: shadowStyle) }

    /// 遮罩高度对应上游 `shadowStyle.paddingTop`（默认 100px）。
    public var shadowFadeHeight: CGFloat { max(innerShadowStyle.padding.top, 0) }

    /// 上游 `textIndent` 支持 `em`，此处以内容字号为基准换算成 pt。
    public var textIndentLength: CGFloat {
        let trimmed = textIndent.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasSuffix("em") else { return UPUnit.parse(trimmed) }
        return CGFloat(Double(trimmed.dropLast(2)) ?? 0) * Self.contentFontSize
    }

    /// 上游 `init()` 用真实内容高度与 `showHeight` 比较来决定是否需要折叠。
    public func isLongContent(contentHeight: CGFloat) -> Bool { contentHeight > showHeight }

    /// 上游 `isLongContent` 为 false 时整行按钮都不渲染。
    public var showsToggleRow: Bool { showToggle && !state.toggleHidden }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentView
            if showsToggleRow { toggleRow }
        }
    }

    /// 上游内容区固定 15px、`$u-content-color`，折叠时按 `showHeight` 截断。
    private var contentView: some View {
        content
            .font(.system(size: Self.contentFontSize))
            .foregroundStyle(UPColor.parse("content", theme: theme))
            .lineLimit(isExpanded || lines == 0 ? nil : lines)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: isExpanded ? nil : showHeight, alignment: .top)
            .overlay(alignment: .bottom) { shadowFade }
            .clipped()
    }

    @ViewBuilder
    private var shadowFade: some View {
        if showsToggleRow, !isExpanded, shadowFadeHeight > 0 {
            let fade = UPColor.parse(shadowFadeColor, theme: theme)
            LinearGradient(colors: [fade.opacity(0), fade], startPoint: .top, endPoint: .bottom)
                .frame(height: shadowFadeHeight)
                .allowsHitTesting(false)
        }
    }

    private var toggleRow: some View {
        Button(action: toggleReadMore) {
            HStack(spacing: 0) {
                UPText(text: toggleText, color: color, size: fontSize, margin: "0 5px 0 0", lineHeight: fontSize)
                UPIcon(name: toggleIconName, color: color, size: "\(toggleIconSize)px")
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 5)
        .frame(maxWidth: .infinity)
    }

    /// 上游 `toggleReadMore`：翻转状态，`toggle` 为 false 时顺手隐藏按钮行。
    public func toggleReadMore() {
        state.expanded.toggle()
        if !toggle { state.toggleHidden = true }
        emit()
    }

    public func expand() { guard !isExpanded else { return }; state.expanded = true; emit() }
    public func collapse() { guard isExpanded else { return }; state.expanded = false; emit() }

    public func onChange(_ action: @escaping (Bool) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    /// 上游 `@open` 回调，参数为 `name`。
    public func onOpen(_ action: @escaping (String) -> Void) -> Self { var copy = self; copy.onOpenHandler = action; return copy }
    /// 上游 `@close` 回调，参数为 `name`。
    public func onClose(_ action: @escaping (String) -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }

    private func emit() {
        onChangeHandler?(state.expanded)
        if state.expanded { onOpenHandler?(name) } else { onCloseHandler?(name) }
    }

    nonisolated private static func fadeColor(from style: UPStyle) -> String {
        if let background = style.backgroundColor, !background.isEmpty { return background }
        if let image = style.value(for: "background-image"),
           let last = image.matches(of: /#[0-9a-fA-F]{3,8}/).last {
            return String(image[last.range])
        }
        return "#ffffff"
    }
}
