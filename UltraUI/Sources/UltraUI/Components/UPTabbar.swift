import SwiftUI

public struct UPTabbarChange: Equatable, Sendable {
    public var name: String
    public var index: Int

    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}

@MainActor
private final class UPTabbarSelectionState {
    var value: String?
    init(_ value: String?) { self.value = value }
}

@MainActor
public struct UPTabbarItem: View, Identifiable {
    public let id: String
    public var name: String
    public var icon: String
    public var activeIcon: String
    public var inactiveIcon: String
    public var badge: String?
    public var dot: Bool
    public var text: String
    public var badgeStyle: UPStyle
    public var mode: String
    public var activeClass: String
    public var inactiveClass: String
    public var midButtonBgColor: String
    public var midButtonIconColor: String
    public var midButtonIconSize: CGFloat
    public var midButtonBoxShadow: String
    public var midButtonInnerBoxShadow: String
    public var midButtonOffsetY: CGFloat
    private var onClickHandler: ((String) -> Void)?

    public init(
        name: String = "", icon: String = "", activeIcon: String = "", inactiveIcon: String = "",
        badge: String? = nil, dot: Bool = false, text: String = "", badgeStyle: UPStyle = UPStyle(),
        mode: String = "", activeClass: String = "", inactiveClass: String = "",
        midButtonBgColor: String = "", midButtonIconColor: String = "",
        midButtonIconSize: some UPImageUnitValue = 26, midButtonBoxShadow: String = "",
        midButtonInnerBoxShadow: String = "", midButtonOffsetY: some UPImageUnitValue = -10
    ) {
        self.id = name
        self.name = name
        self.icon = icon
        self.activeIcon = activeIcon
        self.inactiveIcon = inactiveIcon
        self.badge = badge
        self.dot = dot
        self.text = text
        self.badgeStyle = badgeStyle
        self.mode = mode
        self.activeClass = activeClass
        self.inactiveClass = inactiveClass
        self.midButtonBgColor = midButtonBgColor
        self.midButtonIconColor = midButtonIconColor
        self.midButtonIconSize = UPUnit.parse(midButtonIconSize.upImageUnitValue)
        self.midButtonBoxShadow = midButtonBoxShadow
        self.midButtonInnerBoxShadow = midButtonInnerBoxShadow
        self.midButtonOffsetY = UPUnit.parse(midButtonOffsetY.upImageUnitValue)
    }

    public var body: some View {
        Button(action: triggerClick) {
            VStack(spacing: 3) {
                if !icon.isEmpty { Image(systemName: icon).font(.system(size: midButtonIconSize)) }
                if !text.isEmpty { Text(text).font(.caption) }
            }
            .offset(y: mode == "midButton" ? midButtonOffsetY : 0)
        }.buttonStyle(.plain)
    }

    public func onClick(_ action: @escaping (String) -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func triggerClick() { onClickHandler?(name) }
}

@MainActor
public struct UPTabbar: View {
    public var items: [UPTabbarItem]
    public var value: String?
    public var safeAreaInsetBottom: Bool
    public var border: Bool
    public var borderColor: String
    public var zIndex: CGFloat
    public var activeColor: String
    public var inactiveColor: String
    public var fixed: Bool
    public var placeholder: Bool
    public var backgroundColor: String
    public var styleType: String
    public var animationType: String
    public var activeBackgroundColor: String
    public var inactiveBackgroundColor: String
    public var itemShape: String
    public var iconScale: CGFloat
    public var textMode: String
    private var valueBinding: Binding<String>?
    private var onChangeHandler: ((String) -> Void)?
    private var onChangePayloadHandler: ((UPTabbarChange) -> Void)?
    private let uncontrolledState: UPTabbarSelectionState

    public init(
        items: [UPTabbarItem] = [], value: Binding<String>? = nil,
        safeAreaInsetBottom: Bool = true, border: Bool = true, borderColor: String = "",
        zIndex: some UPImageUnitValue = 1, activeColor: String = "#1989fa",
        inactiveColor: String = "#7d7e80", fixed: Bool = true, placeholder: Bool = true,
        backgroundColor: String = "", styleType: String = "default", animationType: String = "none",
        activeBackgroundColor: String = "", inactiveBackgroundColor: String = "",
        itemShape: String = "default", iconScale: CGFloat = 1.1, textMode: String = "always"
    ) {
        self.items = items
        self.valueBinding = value
        self.value = value?.wrappedValue
        self.uncontrolledState = UPTabbarSelectionState(value?.wrappedValue)
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.border = border
        self.borderColor = borderColor
        self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.fixed = fixed
        self.placeholder = placeholder
        self.backgroundColor = backgroundColor
        self.styleType = styleType
        self.animationType = animationType
        self.activeBackgroundColor = activeBackgroundColor
        self.inactiveBackgroundColor = inactiveBackgroundColor
        self.itemShape = itemShape
        self.iconScale = iconScale
        self.textMode = textMode
    }

    public init(
        items: [UPTabbarItem] = [], value: String,
        safeAreaInsetBottom: Bool = true, border: Bool = true, borderColor: String = "",
        zIndex: some UPImageUnitValue = 1, activeColor: String = "#1989fa",
        inactiveColor: String = "#7d7e80", fixed: Bool = true, placeholder: Bool = true,
        backgroundColor: String = "", styleType: String = "default", animationType: String = "none",
        activeBackgroundColor: String = "", inactiveBackgroundColor: String = "",
        itemShape: String = "default", iconScale: CGFloat = 1.1, textMode: String = "always"
        ) {
        self.init(items: items, value: nil, safeAreaInsetBottom: safeAreaInsetBottom,
                  border: border, borderColor: borderColor, zIndex: zIndex,
                  activeColor: activeColor, inactiveColor: inactiveColor, fixed: fixed,
                  placeholder: placeholder, backgroundColor: backgroundColor,
                  styleType: styleType, animationType: animationType,
                  activeBackgroundColor: activeBackgroundColor,
                  inactiveBackgroundColor: inactiveBackgroundColor, itemShape: itemShape,
                  iconScale: iconScale, textMode: textMode)
        self.value = value
        self.uncontrolledState.value = value
    }

    // MARK: - 主题回落色（对齐上游 tabbar-item resolvedActiveColor / resolvedInactiveColor）

    /// 上游 `resolvedActiveColor`：默认 #1989fa 映射主题 primary(#3c9cff)。
    public func resolvedActiveColorValue() -> String {
        (activeColor.isEmpty || activeColor == "#1989fa") ? "#3c9cff" : activeColor
    }
    /// 上游 `resolvedInactiveColor`：默认 #7d7e80 映射主题 content(#606266)。
    public func resolvedInactiveColorValue() -> String {
        (inactiveColor.isEmpty || inactiveColor == "#7d7e80") ? "#606266" : inactiveColor
    }
    /// 上游 `itemInlineStyle.backgroundColor`。
    public func itemBackgroundValue(active: Bool) -> String {
        let value = active ? activeBackgroundColor : inactiveBackgroundColor
        return value.isEmpty ? "transparent" : value
    }
    /// 上游 `textMode`：`none` 不显示文字（原生扩展），其余显示。
    public var showsText: Bool { textMode != "none" }
    /// 上游 `textClassNames`：`textMode == "active"` 且非激活时静音（淡化）。
    public func isTextMuted(active: Bool) -> Bool { textMode == "active" && !active }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(items) { item in
                let active = item.name == selectedValue
                Button { select(item.name); item.triggerClick() } label: {
                    VStack(spacing: 3) {
                        if !item.icon.isEmpty {
                            UPIcon(name: resolvedIcon(for: item),
                                   color: active ? resolvedActiveColorValue() : resolvedInactiveColorValue(),
                                   size: "\(Int(20 * iconScale))px")
                        }
                        if showsText {
                            Text(item.text)
                                .font(.system(size: 12))
                                .foregroundStyle(UPColor.parse(active ? resolvedActiveColorValue() : resolvedInactiveColorValue()))
                                .opacity(isTextMuted(active: active) ? 0.35 : 1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(itemBackgroundValue(active: active) == "transparent"
                                ? Color.clear
                                : UPColor.parse(itemBackgroundValue(active: active)))
                }.buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, safeAreaInsetBottom ? 6 : 0)
        .background(UPColor.parse(backgroundColor.isEmpty ? "#ffffff" : backgroundColor))
        .overlay(alignment: .top) { if border { Rectangle().fill(UPColor.parse(borderColor.isEmpty ? "#dadbde" : borderColor)).frame(height: 0.5) } }
        .zIndex(zIndex)
    }

    public var selectedValue: String? { valueBinding?.wrappedValue ?? uncontrolledState.value ?? value }
    private func resolvedIcon(for item: UPTabbarItem) -> String {
        if item.name == selectedValue, !item.activeIcon.isEmpty { return item.activeIcon }
        if item.name != selectedValue, !item.inactiveIcon.isEmpty { return item.inactiveIcon }
        return item.icon
    }
    public func select(_ name: String) {
        guard let index = items.firstIndex(where: { $0.name == name }), name != selectedValue else { return }
        uncontrolledState.value = name
        valueBinding?.wrappedValue = name
        onChangeHandler?(name)
        onChangePayloadHandler?(UPTabbarChange(name: name, index: index))
    }
    public func onChange(_ action: @escaping (String) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onChangePayload(_ action: @escaping (UPTabbarChange) -> Void) -> Self { var copy = self; copy.onChangePayloadHandler = action; return copy }
}
