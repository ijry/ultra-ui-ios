import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-dropdown` unit props.
public typealias UPDropdownUnitValue = UPImageUnitValue

/// 上游 `u-dropdown-item` 的 `options` 元素：`{ label, value }`。
public struct UPDropdownOption: Identifiable, Equatable, Sendable {
    public var value: String
    /// 上游模板用的是 `item.label`。仓库既有字段名是 `title`，两者互为别名。
    public var title: String
    public var id: String { value }

    public init(value: String, title: String) {
        self.value = value
        self.title = title
    }

    /// 上游字段名。
    public var label: String { title }

    public init(value: String, label: String) {
        self.init(value: value, title: label)
    }
}

/// 对应上游 `u-dropdown-item` 的 `data.active`。
@MainActor
@Observable
private final class UPDropdownItemState {
    var active = false
}

/// Native SwiftUI counterpart of uview-plus `u-dropdown-item`.
///
/// 上游子项只在 `active` 为真时渲染：没给默认插槽时铺一个 `scroll-view` + `cell-group`，
/// 选中项左侧文字换 `activeColor`、右侧补一个对勾；点某项后写回 `modelValue`、
/// 让父组件收起菜单、再抛 `change`。
@MainActor
public struct UPDropdownItem: View, Identifiable {
    public let id: String
    /// 上游 `title`。
    public var title: String
    /// 上游 `options`。
    public var options: [UPDropdownOption]
    /// 上游 `disabled`。
    public var disabled: Bool
    /// 上游 `height`：下拉面板高度，默认 `auto`。
    public var height: String
    /// 上游 `closeOnClickOverlay`。
    public var closeOnClickOverlay: Bool
    /// 上游 `init()` 里从父组件继承来的两个颜色。
    public var activeColor: String
    public var inactiveColor: String

    private var modelValue: Binding<String>?
    private let state = UPDropdownItemState()
    private var onChangeHandler: ((String) -> Void)?
    private var closeParent: (() -> Void)?
    private var contentSlot: AnyView?

    /// 与上游 `props` 对齐的初始化器。
    public init(title: String = UPConfig.dropdownItem.title,
                options: [UPDropdownOption] = [],
                modelValue: Binding<String>? = nil,
                disabled: Bool = UPConfig.dropdownItem.disabled,
                height: any UPDropdownUnitValue = UPConfig.dropdownItem.height,
                closeOnClickOverlay: Bool = UPConfig.dropdownItem.closeOnClickOverlay) {
        self.id = title
        self.title = title
        self.options = options
        self.modelValue = modelValue
        self.disabled = disabled
        self.height = height.upImageUnitValue
        self.closeOnClickOverlay = closeOnClickOverlay
        self.activeColor = UPConfig.dropdown.activeColor
        self.inactiveColor = UPConfig.dropdown.inactiveColor
    }

    // MARK: - 解析后的呈现值

    /// 上游 `data.active`。
    public var active: Bool { state.active }

    /// 上游 `propsChange`：`title`-`disabled` 拼串，变化时通知父组件重排。
    public var propsChange: String { "\(title)-\(disabled)" }

    /// 上游 `modelValue == item.value` 的判定。
    public func isSelected(_ option: UPDropdownOption) -> Bool {
        modelValue?.wrappedValue == option.value
    }

    /// 上游 `height` 是 `auto` 时交给内容自适应。
    public var resolvedHeight: CGFloat? {
        let parsed = UPUnit.parse(height)
        return parsed > 0 ? parsed : nil
    }

    // MARK: - 上游 methods

    /// 上游 `cellClick(value)`：写回 `modelValue` → 收起父菜单 → 抛 `change`。
    public func cellClick(_ value: String) {
        modelValue?.wrappedValue = value
        closeParent?()
        onChangeHandler?(value)
    }

    /// 仓库既有方法：多了一层「值必须在 options 里」的校验。
    public func select(_ value: String) {
        guard !disabled, options.contains(where: { $0.value == value }) else { return }
        cellClick(value)
    }

    public func setActive(_ value: Bool) { state.active = value }

    // MARK: - 事件与插槽

    /// 对应上游 `change` 事件。
    public func onChange(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游默认插槽：给了它就不再渲染内建的 cell 列表。
    public func content<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.contentSlot = AnyView(builder())
        return copy
    }

    public var hasContentSlot: Bool { contentSlot != nil }

    /// 父组件在渲染前注入自己的配色与关闭回调，对应上游 `init()` 里那段继承。
    func inheriting(activeColor: String,
                    inactiveColor: String,
                    close: @escaping () -> Void) -> UPDropdownItem {
        var copy = self
        copy.activeColor = activeColor
        copy.inactiveColor = inactiveColor
        copy.closeParent = close
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        Group {
            if let contentSlot {
                contentSlot
            } else {
                optionList
            }
        }
    }

    private var optionList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(options) { option in
                    // 上游 `<up-cell :arrow="false">`，原生对应 `isLink: false`（默认即是）。
                    UPCell(title: option.label,
                           titleStyle: UPStyle([
                               "color": isSelected(option) ? activeColor : inactiveColor
                           ]),
                           onTap: { cellClick(option.value) })
                    .overlay(alignment: .trailing) {
                        if isSelected(option) {
                            UPIcon(name: UPConfig.dropdownItem.checkedIcon,
                                   color: activeColor,
                                   size: UPConfig.dropdownItem.checkedIconSize)
                                .padding(.trailing, 15)
                        }
                    }
                }
            }
        }
        .frame(height: resolvedHeight)
        .background(UPColor.parse(UPConfig.dropdownItem.backgroundColor))
    }
}

/// 对应上游 `data`：`current` / `active` / `highlightIndexList` / 量出来的内容高度。
@MainActor
@Observable
private final class UPDropdownState {
    /// 上游 `current` 初始是 99999 而不是 -1。
    var current = UPConfig.dropdown.noneIndex
    var active = false
    var highlightIndexList: [Int] = []
    var contentHeight: CGFloat = 0
}

/// Native SwiftUI counterpart of uview-plus `u-dropdown`.
///
/// 上游是「标题栏 + 绝对定位的下拉内容 + 半透明遮罩」：点标题展开对应子项，
/// 内容区做 `translateY(-100%) → 0` 的下滑，遮罩高度取「窗口高度 - 标题栏底部」。
/// 原生保留同一套状态机（`current` 哨兵值、`closeOnClickSelf`、`highlight`），
/// 面板改用 `overlay` 挂在标题栏下方。
@MainActor
public struct UPDropdown: View {
    public var items: [UPDropdownItem]
    public var activeColor: String
    public var inactiveColor: String
    public var closeOnClickMask: Bool
    public var closeOnClickSelf: Bool
    /// 上游 `duration`，单位 ms。
    public var duration: Int
    public var height: CGFloat
    public var borderBottom: Bool
    public var titleSize: CGFloat
    public var borderRadius: CGFloat
    public var menuIcon: String
    public var menuIconSize: CGFloat

    @State private var state: UPDropdownState
    private var onOpenHandler: ((Int) -> Void)?
    private var onCloseHandler: ((Int) -> Void)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器。
    public init(items: [UPDropdownItem] = [],
                activeColor: String = UPConfig.dropdown.activeColor,
                inactiveColor: String = UPConfig.dropdown.inactiveColor,
                closeOnClickMask: Bool = UPConfig.dropdown.closeOnClickMask,
                closeOnClickSelf: Bool = UPConfig.dropdown.closeOnClickSelf,
                duration: Int = UPConfig.dropdown.duration,
                height: any UPDropdownUnitValue = UPConfig.dropdown.height,
                borderBottom: Bool = UPConfig.dropdown.borderBottom,
                titleSize: any UPDropdownUnitValue = UPConfig.dropdown.titleSize,
                borderRadius: any UPDropdownUnitValue = UPConfig.dropdown.borderRadius,
                menuIcon: String = UPConfig.dropdown.menuIcon,
                menuIconSize: any UPDropdownUnitValue = UPConfig.dropdown.menuIconSize) {
        self.items = items
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.closeOnClickMask = closeOnClickMask
        self.closeOnClickSelf = closeOnClickSelf
        self.duration = duration
        self.height = UPUnit.parse(height.upImageUnitValue)
        self.borderBottom = borderBottom
        self.titleSize = UPUnit.parse(titleSize.upImageUnitValue)
        self.borderRadius = UPUnit.parse(borderRadius.upImageUnitValue)
        self.menuIcon = menuIcon
        self.menuIconSize = UPUnit.parse(menuIconSize.upImageUnitValue)
        self._state = State(initialValue: UPDropdownState())
    }

    // MARK: - 解析后的呈现值

    /// 上游 `current`：未展开时是 99999。
    public var current: Int { state.current }
    /// 上游 `active`。
    public var active: Bool { state.active }
    /// 上游 `highlightIndexList`。
    public var highlightIndexList: [Int] { state.highlightIndexList }

    /// 上游 `menuList`：由各子项的 `title` / `disabled` 汇总而成。
    public var menuList: [(title: String, disabled: Bool)] {
        items.map { ($0.title, $0.disabled) }
    }

    /// 上游 `resolvedActiveColor`：命中默认值时改取主题的 `primary`。
    public var resolvedActiveColor: String {
        activeColor == UPConfig.dropdown.activeColor ? "primary" : activeColor
    }

    /// 上游 `resolvedInactiveColor`：命中默认值时改取主题的 `content`。
    public var resolvedInactiveColor: String {
        inactiveColor == UPConfig.dropdown.inactiveColor ? "content" : inactiveColor
    }

    /// 上游 `menuDisabledColor` 取 `--up-disabled-color`。
    public var menuDisabledColor: String { "disabled" }

    /// 上游模板里标题的取色顺序：禁用 → 激活或高亮 → 未激活。
    public func titleColor(at index: Int) -> String {
        if items.indices.contains(index), items[index].disabled { return menuDisabledColor }
        if index == state.current || state.highlightIndexList.contains(index) { return resolvedActiveColor }
        return resolvedInactiveColor
    }

    /// 上游模板里箭头的取色：只有激活或高亮才用激活色，其余一律用禁用色。
    ///
    /// 照抄上游这处反直觉：未激活项的箭头用的是 `menuDisabledColor` 而不是 `inactiveColor`。
    public func iconColor(at index: Int) -> String {
        index == state.current || state.highlightIndexList.contains(index)
            ? resolvedActiveColor
            : menuDisabledColor
    }

    /// 上游 `.u-dropdown__menu__item__arrow--rotate`：只有当前项转 180°。
    public func iconRotation(at index: Int) -> Double {
        index == state.current ? UPConfig.dropdown.arrowRotation : 0
    }

    /// 上游 `popupStyle.transform`：收起时整块往上位移 100%。
    public var popupOffsetRatio: CGFloat { state.active ? 0 : -1 }

    /// 上游 `contentStyle` 的 zIndex：展开 11、收起 -1。
    public var contentZIndex: Double { state.active ? 11 : -1 }

    /// 上游 `getContentHeight()`：`windowHeight - menu.bottom`。
    public var contentHeight: CGFloat {
        state.contentHeight > 0 ? state.contentHeight : UPConfig.dropdown.fallbackContentHeight
    }

    // MARK: - 上游 methods

    /// 上游 `menuClick(index)`：禁用项直接 return；点当前项且允许时收起，否则展开。
    public func menuClick(_ index: Int) {
        guard items.indices.contains(index), !items[index].disabled else { return }
        if index == state.current, closeOnClickSelf {
            close()
            return
        }
        open(index)
    }

    /// 上游 `open(index)`：置 active/current，并把匹配的子项标成激活。
    public func open(_ index: Int) {
        guard items.indices.contains(index), !items[index].disabled else { return }
        // 仓库既有语义：`open` 被当成「点菜单」用过，因此保留自身项的收起分支。
        if index == state.current, closeOnClickSelf {
            close()
            return
        }
        state.active = true
        state.current = index
        for (offset, item) in items.enumerated() {
            item.setActive(offset == index)
        }
        onOpenHandler?(index)
    }

    /// 上游 `close()`：先抛 `close`（带旧 current），再把 current 归位到哨兵值。
    public func close() {
        let index = state.current
        guard index != UPConfig.dropdown.noneIndex else { return }
        onCloseHandler?(index)
        state.active = false
        state.current = UPConfig.dropdown.noneIndex
        for item in items { item.setActive(false) }
    }

    /// 上游 `maskClick()`：`closeOnClickMask` 为假时什么都不做。
    public func maskClick() {
        guard closeOnClickMask else { return }
        close()
    }

    /// 上游 `highlight(indexParams)`：传数组就整组高亮，传单值就只高亮一个，
    /// 不传（`undefined`）则清空。
    public func highlight(_ indexes: [Int]?) {
        state.highlightIndexList = indexes ?? []
    }

    public func highlight(_ index: Int?) {
        state.highlightIndexList = index.map { [$0] } ?? []
    }

    // MARK: - 事件

    /// 对应上游 `open` 事件，负载是 `current`。
    public func onOpen(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onOpenHandler = action
        return copy
    }

    /// 对应上游 `close` 事件，负载是关闭前的 `current`。
    public func onClose(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        menuBar
            .overlay(alignment: .top) {
                if state.active { dropdownPanel.offset(y: height) }
            }
            .zIndex(11)
    }

    private var menuBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                menuItem(item, index: index)
            }
        }
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if borderBottom { UPLine() }
        }
        .background(heightProbe)
    }

    private func menuItem(_ item: UPDropdownItem, index: Int) -> some View {
        HStack(spacing: UPConfig.dropdown.arrowSpacing) {
            Text(item.title)
                .font(.system(size: titleSize))
                .foregroundStyle(UPColor.parse(titleColor(at: index), theme: theme))

            UPIcon(name: menuIcon,
                   color: iconColor(at: index),
                   size: String(describing: Double(menuIconSize)))
                .rotationEffect(.degrees(iconRotation(at: index)))
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { menuClick(index) }
    }

    private var dropdownPanel: some View {
        ZStack(alignment: .top) {
            // 上游 `__mask`：铺到屏幕底部的半透明遮罩，点它收起。
            Color.black.opacity(UPConfig.dropdown.maskOpacity)
                .frame(height: contentHeight)
                .contentShape(Rectangle())
                .onTapGesture { maskClick() }

            activeItem
                .clipShape(
                    // 上游 `popupStyle.borderRadius = 0 0 r r`。
                    UnevenRoundedRectangle(bottomLeadingRadius: borderRadius,
                                           bottomTrailingRadius: borderRadius)
                )
                .transition(.move(edge: .top))
        }
        .frame(maxHeight: contentHeight, alignment: .top)
        .clipped()
        .animation(.easeOut(duration: Double(duration) / 1000), value: state.active)
    }

    @ViewBuilder
    private var activeItem: some View {
        if items.indices.contains(state.current) {
            items[state.current].inheriting(activeColor: resolvedActiveColor,
                                            inactiveColor: resolvedInactiveColor,
                                            close: { close() })
        }
    }

    /// 上游 `getContentHeight()` 用 `$uGetRect` 量标题栏底部，原生用 GeometryReader。
    private var heightProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { applyContentHeight(proxy) }
                .onChange(of: proxy.frame(in: .global).maxY) { _, _ in applyContentHeight(proxy) }
        }
    }

    private func applyContentHeight(_ proxy: GeometryProxy) {
        #if canImport(UIKit)
        let windowHeight = UIScreen.main.bounds.height
        #else
        let windowHeight = UPConfig.dropdown.fallbackContentHeight
        #endif
        let bottom = proxy.frame(in: .global).maxY
        let available = windowHeight - bottom
        guard available > 0, available != state.contentHeight else { return }
        state.contentHeight = available
    }
}
