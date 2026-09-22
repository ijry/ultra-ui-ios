import Observation
import SwiftUI

/// 上游 `options` 的一项：`keyName` 指定取值字段、`labelName` 指定显示字段。
public struct UPSelectOption: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    /// 对应上游 `options` 里的对象元素。
    public init?(object: [String: String],
                 keyName: String = UPConfig.select.keyName,
                 labelName: String = UPConfig.select.labelName) {
        guard let id = object[keyName] else { return nil }
        self.init(id: id, name: object[labelName] ?? id)
    }

    public static func options(_ objects: [[String: String]],
                               keyName: String = UPConfig.select.keyName,
                               labelName: String = UPConfig.select.labelName) -> [UPSelectOption] {
        objects.compactMap { UPSelectOption(object: $0, keyName: keyName, labelName: labelName) }
    }
}

/// 对应上游 `data.isOpen`。
@MainActor
@Observable
private final class UPSelectState {
    var isOpen = false
}

/// Native SwiftUI counterpart of uview-plus `u-select`.
///
/// 上游是一个「触发行 + 绝对定位下拉面板 + 透明遮罩」的轻量下拉：点触发行展开，
/// 点遮罩收起，选中后抛 `update:current` 与 `select(item)`。
/// 原生沿用同一结构（`overlay(alignment: .topLeading)` 承载面板），
/// 上游 `adjustOptionsWrapPosition` 用 `selectorQuery` 判断右侧是否超屏后左右翻转，
/// 原生交给 SwiftUI 自身的对齐，不做超屏重定位。
@MainActor
public struct UPSelect: View {
    public var options: [UPSelectOption]
    public var current: String
    public var maxHeight: String
    public var overlay: Bool
    public var overlayOpacity: Double
    public var overlayStyle: UPStyle
    public var duration: Double
    public var label: String
    public var keyName: String
    public var labelName: String
    public var showOptionsLabel: Bool
    public var zIndex: CGFloat
    public var itemColor: String
    public var iconColor: String
    public var iconSize: String
    public var disabled: Bool
    public var border: Bool
    public var optionsWidth: String

    @State private var state: UPSelectState
    @Environment(\.upTheme) private var theme
    private var currentBinding: Binding<String>?
    private var onSelectHandler: ((UPSelectOption) -> Void)?
    private var textSlot: ((String) -> AnyView)?
    private var iconSlot: AnyView?
    private var optionItemSlot: ((UPSelectOption) -> AnyView)?

    public init(options: [UPSelectOption] = [],
                current: Binding<String>? = nil,
                maxHeight: String = UPConfig.select.maxHeight,
                overlay: Bool = UPConfig.select.overlay,
                overlayOpacity: Double = UPConfig.select.overlayOpacity,
                overlayStyle: UPStyle = UPConfig.select.overlayStyle,
                duration: some UPImageUnitValue = UPConfig.select.duration,
                label: String = UPConfig.select.label,
                keyName: String = UPConfig.select.keyName,
                labelName: String = UPConfig.select.labelName,
                showOptionsLabel: Bool = UPConfig.select.showOptionsLabel,
                zIndex: some UPImageUnitValue = UPConfig.select.zIndex,
                itemColor: String = UPConfig.select.itemColor,
                iconColor: String = UPConfig.select.iconColor,
                iconSize: String = UPConfig.select.iconSize,
                disabled: Bool = UPConfig.select.disabled,
                border: Bool = UPConfig.select.border,
                optionsWidth: String = UPConfig.select.optionsWidth) {
        self.options = options
        self.currentBinding = current
        self.current = current?.wrappedValue ?? UPConfig.select.current
        self.maxHeight = maxHeight
        self.overlay = overlay
        self.overlayOpacity = overlayOpacity
        self.overlayStyle = overlayStyle
        self.duration = Double(UPUnit.parse(duration.upImageUnitValue))
        self.label = label
        self.keyName = keyName
        self.labelName = labelName
        self.showOptionsLabel = showOptionsLabel
        self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.itemColor = itemColor
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.disabled = disabled
        self.border = border
        self.optionsWidth = optionsWidth
        self._state = State(initialValue: UPSelectState())
    }

    /// 对象数组版：按 `keyName` / `labelName` 取字段。
    public init(options: [[String: String]],
                current: Binding<String>? = nil,
                label: String = UPConfig.select.label,
                keyName: String = UPConfig.select.keyName,
                labelName: String = UPConfig.select.labelName,
                showOptionsLabel: Bool = UPConfig.select.showOptionsLabel,
                disabled: Bool = UPConfig.select.disabled,
                border: Bool = UPConfig.select.border) {
        self.init(options: UPSelectOption.options(options, keyName: keyName, labelName: labelName),
                  current: current,
                  label: label,
                  keyName: keyName,
                  labelName: labelName,
                  showOptionsLabel: showOptionsLabel,
                  disabled: disabled,
                  border: border)
    }

    // MARK: - 状态

    public var isOpen: Bool { state.isOpen }

    /// 对应上游 `currentLabel`：按 `current` 在 `options` 里找显示文本。
    public var currentLabel: String {
        options.first { $0.id == (currentBinding?.wrappedValue ?? current) }?.name ?? ""
    }

    /// 上游 `showOptionsLabel` 为真时触发行显示选中项，否则一直显示 `label`。
    public var triggerText: String { showOptionsLabel ? currentLabel : label }

    /// 上游 `resolvedItemColor` / `resolvedIconColor`：为空时取主题色。
    public var resolvedItemColor: String { itemColor.isEmpty ? "#303133" : itemColor }
    public var resolvedIconColor: String { iconColor.isEmpty ? "#606266" : iconColor }

    /// 上游 `normalizedOptionsWidth`：数字补 `px`，空串表示不限制。
    public var resolvedOptionsWidth: CGFloat? {
        guard !optionsWidth.isEmpty, !optionsWidth.contains("%") else { return nil }
        let value = UPUnit.parse(optionsWidth)
        return value > 0 ? value : nil
    }

    /// 上游 `maxHeight` 默认 `90vh`，视口单位交给父级。
    public var resolvedMaxHeight: CGFloat? {
        guard !maxHeight.contains("vh"), !maxHeight.contains("%") else { return nil }
        let value = UPUnit.parse(maxHeight)
        return value > 0 ? value : nil
    }

    // MARK: - 上游方法

    /// 对应上游 `openSelect()`：`disabled` 时不展开。
    public func openSelect() {
        guard !disabled else { return }
        state.isOpen = true
    }

    /// 对应上游 `closeSelect()` / `overlayClick()`。
    public func closeSelect() { state.isOpen = false }

    /// 对应上游 `selectItem(item)`：收起、抛 `update:current` 与 `select`。
    public func select(_ id: String) {
        guard !disabled, let option = options.first(where: { $0.id == id }) else { return }
        state.isOpen = false
        currentBinding?.wrappedValue = id
        onSelectHandler?(option)
    }

    // MARK: - 事件与插槽

    public func onSelect(_ action: @escaping (UPSelectOption) -> Void) -> UPSelect {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    /// 对应上游 `#text` 作用域插槽（参数是 `currentLabel`）。
    public func text<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPSelect {
        var copy = self
        copy.textSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游 `#icon` 插槽。
    public func icon<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPSelect {
        var copy = self
        copy.iconSlot = AnyView(builder())
        return copy
    }

    /// 对应上游 `#optionItem` 作用域插槽。
    public func optionItem<Slot: View>(@ViewBuilder _ builder: @escaping (UPSelectOption) -> Slot) -> UPSelect {
        var copy = self
        copy.optionItemSlot = { AnyView(builder($0)) }
        return copy
    }

    public var hasTextSlot: Bool { textSlot != nil }
    public var hasIconSlot: Bool { iconSlot != nil }
    public var hasOptionItemSlot: Bool { optionItemSlot != nil }

    // MARK: - 视图

    public var body: some View {
        trigger
            .opacity(disabled ? 0.6 : 1)
            .overlay { dismissLayer }
            .overlay(alignment: .topLeading) { panel }
            .animation(.easeInOut(duration: duration / 1_000), value: isOpen)
    }

    /// 上游 `.u-select__label`：左文右箭头，`border` 时补边框与内边距。
    private var trigger: some View {
        HStack(spacing: 2) {
            if let textSlot {
                textSlot(currentLabel)
            } else {
                Text(triggerText)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.main)
            }

            Spacer(minLength: 0)

            if let iconSlot {
                iconSlot
            } else {
                UPIcon(name: "uicon-arrow-down",
                       color: resolvedIconColor,
                       size: iconSize)
            }
        }
        .padding(border ? EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10) : EdgeInsets())
        .frame(minHeight: border ? 36 : nil)
        .background(border ? Color.white : Color.clear)
        .overlay {
            if border {
                RoundedRectangle(cornerRadius: 4).strokeBorder(theme.border, lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openSelect() }
    }

    /// 上游用 `u-overlay` 拦截外部点击（默认透明度 0.01）。
    @ViewBuilder
    private var dismissLayer: some View {
        if isOpen, overlay {
            Color.black.opacity(overlayOpacity)
                .frame(width: UPTooltip<EmptyView>.dismissLayerSide,
                       height: UPTooltip<EmptyView>.dismissLayerSide)
                .contentShape(Rectangle())
                .upStyle(overlayStyle)
                .onTapGesture { closeSelect() }
                .zIndex(zIndex)
        }
    }

    /// 上游 `.u-select__options__wrap`：`top: calc(100% + 4px)` 的绝对定位面板。
    @ViewBuilder
    private var panel: some View {
        if isOpen {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(options) { option in
                        optionRow(option)
                    }
                }
            }
            .frame(width: resolvedOptionsWidth)
            .frame(minWidth: 100, maxHeight: resolvedMaxHeight)
            .fixedSize(horizontal: resolvedOptionsWidth == nil, vertical: resolvedMaxHeight == nil)
            .background(Color.white)
            .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(theme.border, lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .alignmentGuide(.top) { $0[.bottom] + 4 }
            .zIndex(zIndex + 1)
            .transition(.opacity)
        }
    }

    private func optionRow(_ option: UPSelectOption) -> some View {
        let active = option.id == (currentBinding?.wrappedValue ?? current)
        return Group {
            if let optionItemSlot {
                optionItemSlot(option)
            } else {
                Text(option.name)
                    .font(.system(size: 14))
                    .foregroundStyle(UPColor.parse(resolvedItemColor, theme: theme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(active ? theme.bg : Color.white)
        .contentShape(Rectangle())
        .onTapGesture { select(option.id) }
    }
}
