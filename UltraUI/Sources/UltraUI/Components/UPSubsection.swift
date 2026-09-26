import SwiftUI

public struct UPSubsectionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var activeColorKey: String?
    public var inactiveColorKey: String?

    public init(id: String? = nil, name: String, activeColorKey: String? = nil, inactiveColorKey: String? = nil) {
        self.id = id ?? name
        self.name = name
        self.activeColorKey = activeColorKey
        self.inactiveColorKey = inactiveColorKey
    }
}

public struct UPSubsectionChange: Equatable, Sendable {
    public var index: Int
    public var item: UPSubsectionItem

    public init(index: Int, item: UPSubsectionItem) {
        self.index = index
        self.item = item
    }
}

/// Native segmented control corresponding to uview-plus `u-subsection`.
@MainActor
public struct UPSubsection: View {
    public var list: [UPSubsectionItem]
    public var current: Int
    public var activeColor: String
    public var inactiveColor: String
    public var mode: String
    public var fontSize: CGFloat
    public var bold: Bool
    public var bgColor: String
    public var keyName: String
    public var activeColorKeyName: String
    public var inactiveColorKeyName: String
    public var disabled: Bool
    public var customStyle: UPStyle

    private var currentBinding: Binding<Int>?
    private var onChangeHandler: ((Int) -> Void)?
    private var onChangePayloadHandler: ((UPSubsectionChange) -> Void)?

    public init(
        list: [String] = [], current: Binding<Int>? = nil,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list.map { UPSubsectionItem(name: $0) }, current: current,
                  activeColor: activeColor, inactiveColor: inactiveColor, mode: mode,
                  fontSize: fontSize, bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
    }

    public init(
        list: [UPSubsectionItem], current: Binding<Int>? = nil,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list, current: current, activeColor: activeColor,
                  inactiveColor: inactiveColor, mode: mode, fontSize: fontSize,
                  bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
    }

    public init(
        list: [String] = [], current: Int,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list.map { UPSubsectionItem(name: $0) }, current: nil,
                  activeColor: activeColor, inactiveColor: inactiveColor, mode: mode,
                  fontSize: fontSize, bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
        self.current = current
    }

    /// 非受控（`current: Int`）＋对象数组列表。
    public init(
        list: [UPSubsectionItem], current: Int,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list, current: nil, activeColor: activeColor,
                  inactiveColor: inactiveColor, mode: mode, fontSize: fontSize,
                  bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
        self.current = current
    }

    private init(
        items: [UPSubsectionItem], current: Binding<Int>?, activeColor: String,
        inactiveColor: String, mode: String, fontSize: CGFloat, bold: Bool,
        bgColor: String, keyName: String, activeColorKeyName: String,
        inactiveColorKeyName: String, disabled: Bool, customStyle: UPStyle
    ) {
        self.list = items
        self.current = current?.wrappedValue ?? 0
        self.currentBinding = current
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.mode = mode
        self.fontSize = fontSize
        self.bold = bold
        self.bgColor = bgColor
        self.keyName = keyName
        self.activeColorKeyName = activeColorKeyName
        self.inactiveColorKeyName = inactiveColorKeyName
        self.disabled = disabled
        self.customStyle = customStyle
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - 主题回落色（对齐上游 resolved* computed）

    private static let defaultActiveColor = "#3c9cff"
    private static let defaultInactiveColor = "#303133"
    private static let defaultBgColor = "#eeeeef"

    /// 上游 `resolvedInactiveColor`：未显式传 inactiveColor 时按主题回落。
    public func resolvedInactiveColorValue(isDark: Bool) -> String {
        if inactiveColor != Self.defaultInactiveColor { return inactiveColor }
        return isDark ? "#d1d5db" : "#303133"
    }
    /// 上游 `resolvedButtonBgColor`。
    public func resolvedButtonBgColorValue(isDark: Bool) -> String {
        if bgColor != Self.defaultBgColor { return bgColor }
        return isDark ? "#2b2c30" : "#eeeeef"
    }
    /// 上游 `resolvedButtonBarColor`：禁用与常态分别回落。
    public func resolvedButtonBarColorValue(isDark: Bool) -> String {
        if disabled { return isDark ? "#3a3a3c" : "#f5f5f5" }
        return isDark ? "#3a3b40" : "#ffffff"
    }
    /// 上游 `resolvedDisabledTextColor`。
    public func resolvedDisabledTextColorValue(isDark: Bool) -> String {
        isDark ? "#6b7280" : "#c8c9cc"
    }
    /// 上游 `resolvedDisabledBorderColor`。
    public func resolvedDisabledBorderColorValue(isDark: Bool) -> String {
        isDark ? "#3a3a3c" : "#d4d4d4"
    }

    /// 上游 `textStyle`：禁用统一 disabled 文字色；否则 subsection 激活为白、
    /// button 激活为 activeColor，未激活为 resolvedInactiveColor；item 键名覆盖优先。
    public func textColorValue(index: Int, isDark: Bool) -> String {
        if disabled { return resolvedDisabledTextColorValue(isDark: isDark) }
        guard list.indices.contains(index) else { return resolvedInactiveColorValue(isDark: isDark) }
        let item = list[index]
        let active = index == selectedIndex
        if active {
            if let key = item.activeColorKey { return key }
            return mode == "subsection" ? "#ffffff" : activeColor
        } else {
            if let key = item.inactiveColorKey { return key }
            return resolvedInactiveColorValue(isDark: isDark)
        }
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        HStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                let active = index == selectedIndex
                Button { select(index) } label: {
                    Text(item.name)
                        .font(.system(size: fontSize, weight: bold && active ? .bold : .regular))
                        .foregroundColor(UPColor.parse(textColorValue(index: index, isDark: isDark)))
                        .frame(maxWidth: .infinity)
                        .frame(height: mode == "button" ? 28 : 32)
                        .background(itemBackground(active: active, isDark: isDark))
                        .overlay(itemBorder(index: index, isDark: isDark))
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
        }
        .padding(mode == "button" ? 3 : 0)
        .background(mode == "button" ? UPColor.parse(resolvedButtonBgColorValue(isDark: isDark)) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .upStyle(customStyle)
    }

    /// 激活项背景：button 模式是白色滑块（resolvedButtonBarColor），subsection 模式
    /// 是 activeColor（禁用时 disabledBorderColor）填充；未激活透明。
    @ViewBuilder
    private func itemBackground(active: Bool, isDark: Bool) -> some View {
        if active {
            if mode == "subsection" {
                let fill = disabled ? resolvedDisabledBorderColorValue(isDark: isDark) : activeColor
                UPColor.parse(fill)
            } else {
                UPColor.parse(resolvedButtonBarColorValue(isDark: isDark))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        } else {
            Color.clear
        }
    }

    /// subsection 模式的分段边框（activeColor / 禁用边框色）。button 模式无边框。
    @ViewBuilder
    private func itemBorder(index: Int, isDark: Bool) -> some View {
        if mode == "subsection" {
            let color = disabled ? resolvedDisabledBorderColorValue(isDark: isDark) : activeColor
            Rectangle()
                .stroke(UPColor.parse(color), lineWidth: 1)
        }
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onChangePayload(_ action: @escaping (UPSubsectionChange) -> Void) -> Self {
        var copy = self
        copy.onChangePayloadHandler = action
        return copy
    }

    public func select(_ index: Int) {
        guard !disabled, list.indices.contains(index), index != selectedIndex else { return }
        currentBinding?.wrappedValue = index
        onChangeHandler?(index)
        onChangePayloadHandler?(UPSubsectionChange(index: index, item: list[index]))
    }

    public var selectedIndex: Int {
        let raw = currentBinding?.wrappedValue ?? current
        guard !list.isEmpty else { return 0 }
        return Swift.min(Swift.max(raw, 0), list.count - 1)
    }

}
