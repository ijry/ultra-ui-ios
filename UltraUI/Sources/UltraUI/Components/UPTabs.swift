import SwiftUI

/// Item metadata used by ``UPTabs`` and the native counterpart of `u-tabs-item`.
public struct UPTabsItem: View, Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var badge: String
    public var icon: String
    public var disabled: Bool

    public init(id: String? = nil, name: String = "", badge: String = "", icon: String = "", disabled: Bool = false) {
        self.id = id ?? name
        self.name = name
        self.badge = badge
        self.icon = icon
        self.disabled = disabled
    }

    public var body: some View { Text(name) }
}

public struct UPTabsEvent: Equatable, Sendable {
    public var item: UPTabsItem
    public var index: Int

    public init(item: UPTabsItem, index: Int) {
        self.item = item
        self.index = index
    }
}

@MainActor
private final class UPTabsSelectionState {
    var index: Int
    init(_ index: Int) { self.index = index }
}

/// Scrollable native tab strip corresponding to uview-plus `u-tabs`.
@MainActor
public struct UPTabs: View {
    public var duration: Int
    public var list: [UPTabsItem]
    public var lineColor: String
    public var activeStyle: UPStyle
    public var inactiveStyle: UPStyle
    public var lineWidth: CGFloat
    public var lineHeight: CGFloat
    public var lineBgSize: String
    public var itemStyle: UPStyle
    public var scrollable: Bool
    public var current: Int
    public var keyName: String
    public var iconStyle: UPStyle
    public var shapeMode: String

    private var currentBinding: Binding<Int>?
    private var onClickHandler: ((UPTabsEvent) -> Void)?
    private var onLongPressHandler: ((UPTabsEvent) -> Void)?
    private var onChangeHandler: ((UPTabsEvent) -> Void)?
    private let uncontrolledState: UPTabsSelectionState

    public init(
        list: [UPTabsItem] = [], current: Binding<Int>? = nil, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(["color": "#303133"]),
        inactiveStyle: UPStyle = UPStyle(["color": "#606266"]),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = ""
    ) {
        self.list = list
        self.currentBinding = current
        self.current = current?.wrappedValue ?? 0
        self.uncontrolledState = UPTabsSelectionState(current?.wrappedValue ?? 0)
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
    }

    public init(
        list: [String], current: Binding<Int>? = nil, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(["color": "#303133"]),
        inactiveStyle: UPStyle = UPStyle(["color": "#606266"]),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = ""
    ) {
        self.init(list: list.map { UPTabsItem(name: $0) }, current: current, duration: duration,
                  lineColor: lineColor, activeStyle: activeStyle, inactiveStyle: inactiveStyle,
                  lineWidth: lineWidth, lineHeight: lineHeight, lineBgSize: lineBgSize,
                  itemStyle: itemStyle, scrollable: scrollable, keyName: keyName,
                  iconStyle: iconStyle, shapeMode: shapeMode)
    }

    public init(
        list: [UPTabsItem] = [], current: Int, duration: Int = 300,
        lineColor: String = "", activeStyle: UPStyle = UPStyle(["color": "#303133"]),
        inactiveStyle: UPStyle = UPStyle(["color": "#606266"]),
        lineWidth: some UPImageUnitValue = 20, lineHeight: some UPImageUnitValue = 3,
        lineBgSize: String = "cover", itemStyle: UPStyle = UPStyle(["height": "44px"]),
        scrollable: Bool = true, keyName: String = "name", iconStyle: UPStyle = UPStyle(),
        shapeMode: String = ""
    ) {
        self.init(list: list, current: nil, duration: duration, lineColor: lineColor,
                  activeStyle: activeStyle, inactiveStyle: inactiveStyle, lineWidth: lineWidth,
                  lineHeight: lineHeight, lineBgSize: lineBgSize, itemStyle: itemStyle,
                  scrollable: scrollable, keyName: keyName, iconStyle: iconStyle,
                  shapeMode: shapeMode)
        self.current = current
        self.uncontrolledState.index = current
    }

    /// 上游指示条默认背景 `var(--up-primary, #3c9cff)`：lineColor 为空回落 primary。
    public func resolvedLineColorValue() -> String { lineColor.isEmpty ? "#3c9cff" : lineColor }

    public var body: some View {
        Group {
            if scrollable {
                ScrollView(.horizontal, showsIndicators: false) { tabItems }
            } else {
                tabItems
            }
        }
    }

    private var tabItems: some View {
        HStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                Button { select(index) } label: {
                    VStack(spacing: 5) {
                        HStack(spacing: 4) {
                            if !item.icon.isEmpty { UPIcon(name: item.icon, size: "15px").upStyle(iconStyle) }
                            Text(item.name)
                            if !item.badge.isEmpty { Text(item.badge).font(.caption2) }
                        }
                        Capsule()
                            .fill(index == selectedIndex ? UPColor.parse(resolvedLineColorValue()) : .clear)
                            .frame(width: lineWidth, height: lineHeight)
                    }
                    .frame(maxWidth: scrollable ? nil : .infinity)
                    .upStyle(index == selectedIndex ? activeStyle : inactiveStyle)
                    .upStyle(itemStyle)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(LongPressGesture().onEnded { _ in longPress(index) })
            }
        }
    }

    public var selectedIndex: Int {
        guard !list.isEmpty else { return 0 }
        return min(max(currentBinding?.wrappedValue ?? uncontrolledState.index, 0), list.count - 1)
    }

    public func select(_ index: Int) {
        guard list.indices.contains(index) else { return }
        let event = UPTabsEvent(item: list[index], index: index)
        onClickHandler?(event)
        guard !list[index].disabled, index != selectedIndex else { return }
        uncontrolledState.index = index
        currentBinding?.wrappedValue = index
        onChangeHandler?(event)
    }

    public func longPress(_ index: Int) {
        guard list.indices.contains(index) else { return }
        onLongPressHandler?(UPTabsEvent(item: list[index], index: index))
    }

    public func onClick(_ action: @escaping (UPTabsEvent) -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func onLongPress(_ action: @escaping (UPTabsEvent) -> Void) -> Self { var copy = self; copy.onLongPressHandler = action; return copy }
    public func onChange(_ action: @escaping (UPTabsEvent) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
}
