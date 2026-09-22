import SwiftUI

/// 上游 `u-tabs-pro` 默认插槽的 scope 变量，对应
/// `current` / `index` / `item` / `value` / `list`。
public struct UPTabsProContentContext: Equatable, Sendable {
    public var current: Int
    public var index: Int
    public var item: UPTabsItem?
    public var value: String?
    public var list: [UPTabsItem]

    public init(current: Int, index: Int, item: UPTabsItem?, value: String?, list: [UPTabsItem]) {
        self.current = current
        self.index = index
        self.item = item
        self.value = value
        self.list = list
    }
}

@MainActor
private final class UPTabsProSelectionState {
    var index: Int
    init(_ index: Int) { self.index = index }
}

/// `u-tabs-pro` 的原生实现：在 ``UPTabs`` 之上补一层 `current` 归一化与内容区插槽。
///
/// 与上游一致的两处反直觉行为已用测试固定：
/// 1. `activeStyle`/`inactiveStyle` 默认为空样式并显式下传，会覆盖 ``UPTabs`` 自己的
///    `#303133`/`#606266` 默认值；
/// 2. 上游同时绑定 `@update:current` 与 `@change`，而 `changeHandler` 内部又调了一次
///    `updateCurrent`，因此点击一次标签会 emit 两次 `update:current`。
///
/// 上游转发给 `u-tabs` 的 `left`/`icon`/`tab`/`content` 命名插槽在原生 ``UPTabs`` 上
/// 没有对应物，未建模；`contentClass` 无 CSS class 对应物，仅保留为迁移元数据。
@MainActor
public struct UPTabsPro<Content: View>: View {
    public var list: [UPTabsItem]
    public var current: Int
    public var duration: Int
    public var lineColor: String
    public var activeStyle: UPStyle
    public var inactiveStyle: UPStyle
    public var lineWidth: CGFloat
    public var lineHeight: CGFloat
    public var lineBgSize: String
    public var itemStyle: UPStyle
    public var scrollable: Bool
    public var keyName: String
    public var iconStyle: UPStyle
    public var shapeMode: String
    public var contentMode: String
    public var showContent: Bool
    public var contentClass: String
    public var contentStyle: UPStyle
    public var bindIndexRef: String
    public var customClass: String
    public var customStyle: UPStyle

    private var currentBinding: Binding<Int>?
    private var onClickHandler: ((UPTabsEvent) -> Void)?
    private var onLongPressHandler: ((UPTabsEvent) -> Void)?
    private var onChangeHandler: ((UPTabsEvent) -> Void)?
    private var onUpdateCurrentHandler: ((Int) -> Void)?
    private let uncontrolledState: UPTabsProSelectionState
    private let content: (UPTabsProContentContext) -> Content

    /// 上游 `props` 里声明但模板与逻辑从未引用的 prop，仅保留为迁移元数据。
    public static var declaredOnlyPropNames: [String] { ["bindIndexRef", "contentMode"] }

    public init(
        list: [UPTabsItem] = [], current: Binding<Int>? = nil, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(),
        inactiveStyle: UPStyle = UPStyle(),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = "", contentMode: String = "static", showContent: Bool = true,
        contentClass: String = "", contentStyle: UPStyle = UPStyle(), bindIndexRef: String = "",
        customClass: String = "", customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: @escaping (UPTabsProContentContext) -> Content
    ) {
        self.list = list
        self.currentBinding = current
        self.current = current?.wrappedValue ?? 0
        self.uncontrolledState = UPTabsProSelectionState(
            Self.normalizeCurrent(current?.wrappedValue ?? 0, count: list.count)
        )
        self.duration = duration
        self.lineColor = lineColor
        self.activeStyle = activeStyle
        self.inactiveStyle = inactiveStyle
        self.lineWidth = UPUnit.parse(lineWidth.upImageUnitValue)
        self.lineHeight = UPUnit.parse(lineHeight.upImageUnitValue)
        self.lineBgSize = lineBgSize
        self.itemStyle = itemStyle
        self.scrollable = scrollable
        self.keyName = keyName
        self.iconStyle = iconStyle
        self.shapeMode = shapeMode
        self.contentMode = contentMode
        self.showContent = showContent
        self.contentClass = contentClass
        self.contentStyle = contentStyle
        self.bindIndexRef = bindIndexRef
        self.customClass = customClass
        self.customStyle = customStyle
        self.content = content
    }

    public init(
        list: [UPTabsItem] = [], current: Int, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(),
        inactiveStyle: UPStyle = UPStyle(),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = "", contentMode: String = "static", showContent: Bool = true,
        contentClass: String = "", contentStyle: UPStyle = UPStyle(), bindIndexRef: String = "",
        customClass: String = "", customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: @escaping (UPTabsProContentContext) -> Content
    ) {
        self.init(
            list: list, current: nil, duration: duration, lineColor: lineColor,
            activeStyle: activeStyle, inactiveStyle: inactiveStyle, lineWidth: lineWidth,
            lineHeight: lineHeight, lineBgSize: lineBgSize, itemStyle: itemStyle,
            scrollable: scrollable, keyName: keyName, iconStyle: iconStyle,
            shapeMode: shapeMode, contentMode: contentMode, showContent: showContent,
            contentClass: contentClass, contentStyle: contentStyle, bindIndexRef: bindIndexRef,
            customClass: customClass, customStyle: customStyle, content: content
        )
        self.current = current
        self.uncontrolledState.index = Self.normalizeCurrent(current, count: list.count)
    }
}

// MARK: - 只读派生

public extension UPTabsPro {
    /// 对应上游 `resolvedLineColor`：空字符串下传 `undefined`，让 `u-tabs` 用自己的默认色。
    var resolvedLineColor: String? {
        lineColor.isEmpty ? nil : lineColor
    }

    /// 对应上游 `innerCurrent`。
    var resolvedCurrent: Int {
        normalizeCurrent(currentBinding?.wrappedValue ?? uncontrolledState.index)
    }

    /// 对应上游 `currentItem`。
    var currentItem: UPTabsItem? {
        let index = resolvedCurrent
        guard list.indices.contains(index) else { return nil }
        return list[index]
    }

    /// 对应上游 `currentValue`，即 `currentItem[keyName]`。
    var currentValue: String? {
        guard let item = currentItem else { return nil }
        return Self.value(of: item, forKey: keyName)
    }

    var contentContext: UPTabsProContentContext {
        let index = resolvedCurrent
        return UPTabsProContentContext(
            current: index, index: index, item: currentItem, value: currentValue, list: list
        )
    }

    /// 对应上游 `normalizeCurrent`。Swift 侧 `current` 是 `Int`，
    /// 上游 `Number.isFinite` 的非数字回落分支不可达，故只保留 clamp。
    func normalizeCurrent(_ value: Int) -> Int {
        Self.normalizeCurrent(value, count: list.count)
    }
}

extension UPTabsPro {
    static func normalizeCurrent(_ value: Int, count: Int) -> Int {
        let maxIndex = Swift.max(count - 1, 0)
        return Swift.min(Swift.max(value, 0), maxIndex)
    }

    /// `UPTabsItem` 只有 String 型成员可被 `keyName` 寻址，其余键与上游取不到属性一样返回 nil。
    static func value(of item: UPTabsItem, forKey key: String) -> String? {
        switch key {
        case "name": return item.name
        case "badge": return item.badge
        case "icon": return item.icon
        case "id": return item.id
        default: return nil
        }
    }

    var innerTabs: UPTabs {
        UPTabs(
            list: list, current: tabsBinding, duration: duration,
            lineColor: resolvedLineColor ?? "", activeStyle: activeStyle,
            inactiveStyle: inactiveStyle, lineWidth: lineWidth, lineHeight: lineHeight,
            lineBgSize: lineBgSize, itemStyle: itemStyle, scrollable: scrollable,
            keyName: keyName, iconStyle: iconStyle, shapeMode: shapeMode
        )
        .onClick { handleClick($0) }
        .onLongPress { handleLongPress($0) }
        .onChange { handleChange($0) }
    }

    private var tabsBinding: Binding<Int> {
        Binding(get: { self.resolvedCurrent }, set: { self.updateCurrent($0) })
    }
}

// MARK: - 行为

public extension UPTabsPro {
    /// 对应上游 `updateCurrent`：归一化后回写并 emit `update:current`，值未变也会 emit。
    func updateCurrent(_ value: Int) {
        let next = normalizeCurrent(value)
        uncontrolledState.index = next
        currentBinding?.wrappedValue = next
        onUpdateCurrentHandler?(next)
    }

    /// 转交内层 ``UPTabs`` 处理点击，事件顺序与上游 `u-tabs` 一致。
    func select(_ index: Int) {
        innerTabs.select(index)
    }

    func longPress(_ index: Int) {
        innerTabs.longPress(index)
    }

    /// 对应上游对 `list` 的 deep watch：clamp 后的值与原值不同才回写并 emit。
    @discardableResult
    func syncList() -> Bool {
        let raw = currentBinding?.wrappedValue ?? uncontrolledState.index
        let next = normalizeCurrent(raw)
        guard next != raw else { return false }
        uncontrolledState.index = next
        currentBinding?.wrappedValue = next
        onUpdateCurrentHandler?(next)
        return true
    }
}

extension UPTabsPro {
    func handleClick(_ event: UPTabsEvent) {
        onClickHandler?(event)
    }

    func handleLongPress(_ event: UPTabsEvent) {
        onLongPressHandler?(event)
    }

    /// 对应上游 `changeHandler`：先 `updateCurrent` 再 emit `change`。
    func handleChange(_ event: UPTabsEvent) {
        updateCurrent(event.index)
        onChangeHandler?(event)
    }
}

// MARK: - 事件

public extension UPTabsPro {
    func onClick(_ action: @escaping (UPTabsEvent) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    func onLongPress(_ action: @escaping (UPTabsEvent) -> Void) -> Self {
        var copy = self; copy.onLongPressHandler = action; return copy
    }

    func onChange(_ action: @escaping (UPTabsEvent) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }

    func onUpdateCurrent(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onUpdateCurrentHandler = action; return copy
    }
}

// MARK: - 视图

public extension UPTabsPro {
    var body: some View {
        VStack(spacing: 0) {
            innerTabs
            if showContent {
                content(contentContext)
                    .frame(maxWidth: .infinity)
                    .upStyle(contentStyle)
            }
        }
        .frame(maxWidth: .infinity)
        .upStyle(customStyle)
        .onChange(of: list) { _, _ in syncList() }
    }
}

public extension UPTabsPro where Content == EmptyView {
    init(
        list: [UPTabsItem] = [], current: Binding<Int>? = nil, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(),
        inactiveStyle: UPStyle = UPStyle(),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = "", contentMode: String = "static", showContent: Bool = true,
        contentClass: String = "", contentStyle: UPStyle = UPStyle(), bindIndexRef: String = "",
        customClass: String = "", customStyle: UPStyle = UPStyle()
    ) {
        self.init(
            list: list, current: current, duration: duration, lineColor: lineColor,
            activeStyle: activeStyle, inactiveStyle: inactiveStyle, lineWidth: lineWidth,
            lineHeight: lineHeight, lineBgSize: lineBgSize, itemStyle: itemStyle,
            scrollable: scrollable, keyName: keyName, iconStyle: iconStyle,
            shapeMode: shapeMode, contentMode: contentMode, showContent: showContent,
            contentClass: contentClass, contentStyle: contentStyle, bindIndexRef: bindIndexRef,
            customClass: customClass, customStyle: customStyle, content: { _ in EmptyView() }
        )
    }

    init(
        list: [UPTabsItem] = [], current: Int, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(),
        inactiveStyle: UPStyle = UPStyle(),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = "", contentMode: String = "static", showContent: Bool = true,
        contentClass: String = "", contentStyle: UPStyle = UPStyle(), bindIndexRef: String = "",
        customClass: String = "", customStyle: UPStyle = UPStyle()
    ) {
        self.init(
            list: list, current: current, duration: duration, lineColor: lineColor,
            activeStyle: activeStyle, inactiveStyle: inactiveStyle, lineWidth: lineWidth,
            lineHeight: lineHeight, lineBgSize: lineBgSize, itemStyle: itemStyle,
            scrollable: scrollable, keyName: keyName, iconStyle: iconStyle,
            shapeMode: shapeMode, contentMode: contentMode, showContent: showContent,
            contentClass: contentClass, contentStyle: contentStyle, bindIndexRef: bindIndexRef,
            customClass: customClass, customStyle: customStyle, content: { _ in EmptyView() }
        )
    }
}
