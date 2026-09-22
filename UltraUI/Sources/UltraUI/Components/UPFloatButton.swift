import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-float-button` offset props.
public typealias UPFloatButtonUnitValue = UPImageUnitValue

/// 上游 `list` 数组里的一项。
///
/// 上游模板只读 `item.name`（图标名）与可选的 `backgroundColor` / `color` / `borderColor`
/// 三个配色覆盖，`item-click` 负载是 `{ ...item, index }`。
public struct UPFloatButtonItem: Identifiable, Equatable, Sendable {
    public let id: String
    /// 上游 `item.name`：图标名。
    public var name: String
    /// 仓库既有字段：子项文字。上游模板不渲染它。
    public var title: String
    /// 上游 `item?.backgroundColor`，为空时退回组件的 `backgroundColor`。
    public var backgroundColor: String
    /// 上游 `item?.color`，为空时退回组件的 `color`。
    public var color: String
    /// 上游 `item?.borderColor`，为空时退回组件的 `borderColor`。
    public var borderColor: String

    public init(id: String,
                name: String = "",
                title: String = "",
                backgroundColor: String = "",
                color: String = "",
                borderColor: String = "") {
        self.id = id
        self.name = name
        self.title = title
        self.backgroundColor = backgroundColor
        self.color = color
        self.borderColor = borderColor
    }

    /// 仓库既有签名：`icon` 是 `name` 的旧名。
    public init(id: String, title: String = "", icon: String = "") {
        self.init(id: id, name: icon, title: title)
    }

    /// 仓库既有名。
    public var icon: String { name }
}

/// 上游 `item-click` 的负载 `{ ...item, index }`。
public struct UPFloatButtonItemClickEvent: Equatable, Sendable {
    public var item: UPFloatButtonItem
    public var index: Int

    public init(item: UPFloatButtonItem, index: Int) {
        self.item = item
        self.index = index
    }
}

/// 对应上游 `data.showList`。
@MainActor
@Observable
private final class UPFloatButtonState {
    var showList = false
}

/// Native SwiftUI counterpart of uview-plus `u-float-button`.
///
/// 上游是 `position: fixed` 的圆形主按钮：`isMenu` 为真时点击切换 `showList`，
/// 展开后在主按钮上方纵向铺开 `list` 里的圆形子项，默认图标随展开状态旋转 45°。
/// 原生保留同一套结构与配色回退规则，定位交给调用方用 `.overlay` / `ZStack` 摆放。
@MainActor
public struct UPFloatButton: View {
    /// 上游 `backgroundColor`。
    public var backgroundColor: String
    /// 上游 `color`：图标与文字颜色。
    public var color: String
    /// 上游 `width`。
    public var width: String
    /// 上游 `height`。
    public var height: String
    /// 上游 `borderColor`：空串表示无边框。
    public var borderColor: String
    /// 上游 `right`。
    public var right: String
    /// 上游 `top`：空串表示不参与定位。
    public var top: String
    /// 上游 `bottom`：空串表示不参与定位。
    public var bottom: String
    /// 上游 `isMenu`：为假时点击只抛 `click`，不展开列表。
    public var isMenu: Bool
    /// 上游 `list`。
    public var list: [UPFloatButtonItem]
    /// 仓库既有属性：子项展开方向。
    public var direction: String

    private let state = UPFloatButtonState()
    private var onClickHandler: (() -> Void)?
    private var onItemClickHandler: ((UPFloatButtonItem) -> Void)?
    private var onItemClickEventHandler: ((UPFloatButtonItemClickEvent) -> Void)?
    private var defaultSlot: ((Bool) -> AnyView)?
    private var listSlot: AnyView?

    /// 与上游 `props` 对齐的初始化器。
    public init(backgroundColor: String = UPConfig.floatButton.backgroundColor,
                color: String = UPConfig.floatButton.color,
                width: String = UPConfig.floatButton.width,
                height: String = UPConfig.floatButton.height,
                borderColor: String = UPConfig.floatButton.borderColor,
                right: any UPFloatButtonUnitValue = UPConfig.floatButton.right,
                top: any UPFloatButtonUnitValue = UPConfig.floatButton.top,
                bottom: String = UPConfig.floatButton.bottom,
                isMenu: Bool = UPConfig.floatButton.isMenu,
                list: [UPFloatButtonItem] = [],
                direction: String = "up") {
        self.backgroundColor = backgroundColor
        self.color = color
        self.width = width
        self.height = height
        self.borderColor = borderColor
        self.right = right.upImageUnitValue
        self.top = top.upImageUnitValue
        self.bottom = bottom
        self.isMenu = isMenu
        self.list = list
        self.direction = direction
    }

    /// 仓库既有签名：`items` 是 `list` 的旧名，给了子项就默认按菜单用。
    public init(items: [UPFloatButtonItem], direction: String = "up") {
        self.init(isMenu: !items.isEmpty, list: items, direction: direction)
    }

    // MARK: - 解析后的呈现值

    /// 仓库既有名。
    public var items: [UPFloatButtonItem] { list }
    /// 上游 `showList`。
    public var showList: Bool { state.showList }
    /// 仓库既有名。
    public var expanded: Bool { state.showList }

    /// 上游 `.show-list { transform: rotate(45deg) }`：展开时默认图标转 45°。
    public var iconRotation: Double {
        state.showList ? UPConfig.floatButton.expandedRotation : 0
    }

    public var resolvedWidth: CGFloat { max(UPUnit.parse(width), 0) }
    public var resolvedHeight: CGFloat { max(UPUnit.parse(height), 0) }

    /// 上游 `item?.backgroundColor ? item?.backgroundColor : backgroundColor`。
    public func itemBackgroundColor(_ item: UPFloatButtonItem) -> String {
        item.backgroundColor.isEmpty ? backgroundColor : item.backgroundColor
    }

    /// 上游 `item?.color ? item?.color : color`。
    public func itemColor(_ item: UPFloatButtonItem) -> String {
        item.color.isEmpty ? color : item.color
    }

    /// 上游 `item?.borderColor ? item?.borderColor : borderColor`。
    public func itemBorderColor(_ item: UPFloatButtonItem) -> String {
        item.borderColor.isEmpty ? borderColor : item.borderColor
    }

    // MARK: - 上游 methods

    /// 上游 `clickHandler(e)`：`isMenu` 为真时先翻 `showList`，两条分支都抛 `click`。
    public func clickHandler() {
        if isMenu { state.showList.toggle() }
        onClickHandler?()
    }

    /// 仓库既有名：只切换展开状态，不抛事件。
    public func toggle() { state.showList.toggle() }

    public func close() { state.showList = false }

    /// 上游 `itemClick(item, index)`：负载是 `{ ...item, index }`。
    public func itemClick(_ item: UPFloatButtonItem, index: Int) {
        onItemClickHandler?(item)
        onItemClickEventHandler?(UPFloatButtonItemClickEvent(item: item, index: index))
    }

    /// 仓库既有方法：按 id 找子项后抛 `item-click`。
    public func select(_ id: String) {
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        itemClick(list[index], index: index)
    }

    // MARK: - 事件

    /// 对应上游 `click` 事件。
    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    /// 仓库既有签名：只关心子项本身。
    public func onItemClick(_ action: @escaping (UPFloatButtonItem) -> Void) -> Self {
        var copy = self
        copy.onItemClickHandler = action
        return copy
    }

    /// 对应上游 `item-click` 事件，负载带 `index`。
    public func onItemClick(_ action: @escaping (UPFloatButtonItemClickEvent) -> Void) -> Self {
        var copy = self
        copy.onItemClickEventHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游默认作用域插槽，参数是 `showList`。
    public func content<Slot: View>(@ViewBuilder _ builder: @escaping (Bool) -> Slot) -> Self {
        var copy = self
        copy.defaultSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游具名插槽 `list`。
    public func listContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.listSlot = AnyView(builder())
        return copy
    }

    public var hasDefaultSlot: Bool { defaultSlot != nil }
    public var hasListSlot: Bool { listSlot != nil }

    // MARK: - 视图

    public var body: some View {
        mainButton
            .overlay(alignment: listAlignment) {
                // 上游 `.u-float-button__list { position: absolute; bottom: height }`：
                // 列表挂在主按钮上方，不参与主按钮的布局尺寸。
                if state.showList {
                    // 把列表整体推到主按钮之外：向上展开时列表底边贴主按钮顶边。
                    listView.alignmentGuide(listGuide, computeValue: alignmentGuideValue)
                }
            }
            .zIndex(UPConfig.floatButton.zIndex)
    }

    private var mainButton: some View {
        circle(background: backgroundColor, border: borderColor) {
            if let defaultSlot {
                defaultSlot(state.showList)
            } else {
                UPIcon(name: UPConfig.floatButton.icon, color: color)
                    .rotationEffect(.degrees(iconRotation))
            }
        }
        .contentShape(Circle())
        .onTapGesture { clickHandler() }
    }

    private var listView: some View {
        VStack(spacing: UPConfig.floatButton.itemSpacing) {
            if let listSlot {
                listSlot
            } else {
                ForEach(Array(list.enumerated()), id: \.offset) { offset, item in
                    itemView(item, index: offset)
                }
            }
        }
    }

    private func itemView(_ item: UPFloatButtonItem, index: Int) -> some View {
        circle(background: itemBackgroundColor(item), border: itemBorderColor(item)) {
            UPIcon(name: item.name, color: itemColor(item))
        }
        .contentShape(Circle())
        .onTapGesture { itemClick(item, index: index) }
    }

    private func circle<Inner: View>(background: String,
                                     border: String,
                                     @ViewBuilder _ inner: () -> Inner) -> some View {
        inner()
            .frame(width: resolvedWidth, height: resolvedHeight)
            .background(UPColor.parse(background))
            .clipShape(Circle())
            .overlay {
                // 上游 `borderColor` 为空串时不画边框。
                if !border.isEmpty {
                    Circle().stroke(UPColor.parse(border), lineWidth: 1)
                }
            }
    }

    /// 仓库既有属性 `direction`：上游只有向上一种。
    private var listAlignment: Alignment {
        direction == "down" ? .bottom : .top
    }

    private var listGuide: VerticalAlignment {
        direction == "down" ? .bottom : .top
    }

    private var listAnchor: VerticalAlignment {
        direction == "down" ? .top : .bottom
    }

    /// `alignmentGuide` 的闭包是 Sendable 的，先把方向取出来再算，避免在闭包里碰 actor 隔离属性。
    private var alignmentGuideValue: @Sendable (ViewDimensions) -> CGFloat {
        let anchor: VerticalAlignment = direction == "down" ? .top : .bottom
        return { $0[anchor] }
    }
}
