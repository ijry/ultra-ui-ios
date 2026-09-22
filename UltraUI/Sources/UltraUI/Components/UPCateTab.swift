import Observation
import SwiftUI

/// 左侧栏目的一项。上游 `tabList` 是对象数组，用 `tabKeyName` 取标题、
/// `children` 取右侧内容，`children` 的每项用 `itemKeyName` 取名字、`icon` 取图。
public struct UPCateTabItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public var value: String
    public var children: [UPCateTabChild]

    public init(title: String,
                value: String? = nil,
                id: String? = nil,
                children: [UPCateTabChild] = []) {
        self.title = title
        self.value = value ?? title
        self.id = id ?? self.value
        self.children = children
    }

    /// 对应上游 `tabList` 的一个对象元素。
    public init?(object: [String: String],
                 tabKeyName: String = UPConfig.cateTab.tabKeyName,
                 children: [UPCateTabChild] = []) {
        guard let title = object[tabKeyName] else { return nil }
        self.init(title: title, value: object["value"] ?? title, children: children)
    }
}

/// 右侧栏目里的一项，对应上游 `item.children` 的元素。
public struct UPCateTabChild: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var icon: String

    public init(name: String, icon: String = "", id: String? = nil) {
        self.name = name
        self.icon = icon
        self.id = id ?? name
    }

    /// 对应上游用 `itemKeyName` 取名字、`icon` 取图片。
    public init?(object: [String: String], itemKeyName: String = UPConfig.cateTab.itemKeyName) {
        guard let name = object[itemKeyName] else { return nil }
        self.init(name: name, icon: object["icon"] ?? "")
    }
}

public struct UPCateTabChange: Sendable {
    public let index: Int
    public let item: UPCateTabItem

    public init(index: Int, item: UPCateTabItem) {
        self.index = index
        self.item = item
    }
}

/// SwiftUI requires views to be value types, so the mutable selection index lives
/// in a small reference box rather than making the view itself a class.
@MainActor
@Observable
private final class UPCateTabState {
    var current: Int

    init(current: Int) {
        self.current = current
    }
}

/// Native SwiftUI counterpart of uview-plus `u-cate-tab`.
///
/// 上游是「左侧栏目 + 右侧内容」的双列联动：`mode: 'follow'` 时右侧铺全部分组并
/// 随滚动反查高亮左侧（`rightScroll` 里比对每组的 `top`），`mode: 'tab'` 时右侧
/// 只渲染当前分组。原生用 `ScrollViewReader` 滚到对应分组，`follow` 模式下由
/// 滚动探针反查当前分组；`update:current` 落成 `current` 绑定与 `change` 回调。
@MainActor
public struct UPCateTab: View {
    public var items: [UPCateTabItem]
    public var mode: String
    /// 上游 `height` 是 CSS 值（默认 `'100%'`）。原生解析成具体高度，
    /// `100%` 这类百分比取 nil 交给父级决定。
    public var height: String
    public var tabKeyName: String
    public var itemKeyName: String

    public var current: Int { state.current }

    @State private var state: UPCateTabState
    @State private var offsets: [Int: CGFloat] = [:]
    @Environment(\.upTheme) private var theme
    private var currentBinding: Binding<Int>?
    private var onChangeHandler: ((UPCateTabItem) -> Void)?
    private var onChangePayloadHandler: ((UPCateTabChange) -> Void)?
    private var tabItemSlot: ((UPCateTabItem) -> AnyView)?
    private var rightTopSlot: AnyView?
    private var itemListSlot: ((UPCateTabItem) -> AnyView)?
    private var pageItemSlot: ((UPCateTabChild) -> AnyView)?

    private static var scrollSpace: String { "UPCateTab" }

    /// 与上游 `props` 对齐的初始化器。
    public init(tabList: [UPCateTabItem] = [],
                mode: String = UPConfig.cateTab.mode,
                height: String = UPConfig.cateTab.height,
                tabKeyName: String = UPConfig.cateTab.tabKeyName,
                itemKeyName: String = UPConfig.cateTab.itemKeyName,
                current: Int = UPConfig.cateTab.current) {
        self.items = tabList
        self.mode = mode
        self.height = height
        self.tabKeyName = tabKeyName
        self.itemKeyName = itemKeyName
        self._state = State(initialValue: UPCateTabState(current: max(0, current)))
    }

    /// 仓库既有签名一：字符串标题 + 值回调。
    public init(items: [String] = [],
                current: Int = UPConfig.cateTab.current,
                onChange: ((UPCateTabItem) -> Void)? = nil) {
        self.init(tabList: items.map { UPCateTabItem(title: $0) }, current: current)
        self.onChangeHandler = onChange
    }

    /// 仓库既有签名二。
    public init(items: [UPCateTabItem],
                current: Int = UPConfig.cateTab.current,
                onChange: ((UPCateTabItem) -> Void)? = nil) {
        self.init(tabList: items, current: current)
        self.onChangeHandler = onChange
    }

    /// 仓库既有签名三：`current` 绑定 + 结构化回调。
    public init(items: [String] = [],
                current: Binding<Int>,
                mode: String = UPConfig.cateTab.mode,
                height: String = UPConfig.cateTab.height,
                onChange: ((UPCateTabChange) -> Void)? = nil) {
        self.init(tabList: items.map { UPCateTabItem(title: $0) },
                  mode: mode,
                  height: height,
                  current: current.wrappedValue)
        self.currentBinding = current
        self.onChangePayloadHandler = onChange
    }

    /// `tabList` 绑定版：对象数组按 `tabKeyName` / `itemKeyName` 取字段。
    public init(tabList: [[String: String]],
                children: [[[String: String]]] = [],
                mode: String = UPConfig.cateTab.mode,
                height: String = UPConfig.cateTab.height,
                tabKeyName: String = UPConfig.cateTab.tabKeyName,
                itemKeyName: String = UPConfig.cateTab.itemKeyName,
                current: Int = UPConfig.cateTab.current) {
        let items = tabList.enumerated().compactMap { index, object -> UPCateTabItem? in
            let group = children.indices.contains(index) ? children[index] : []
            return UPCateTabItem(object: object,
                                 tabKeyName: tabKeyName,
                                 children: group.compactMap { UPCateTabChild(object: $0, itemKeyName: itemKeyName) })
        }
        self.init(tabList: items,
                  mode: mode,
                  height: height,
                  tabKeyName: tabKeyName,
                  itemKeyName: itemKeyName,
                  current: current)
    }

    // MARK: - 状态

    /// `follow` 跟随联动、`tab` 只显示当前分组。
    public var isFollowMode: Bool { mode == UPConfig.cateTab.mode }

    /// `mode: 'tab'` 时右侧只铺当前分组。
    public var visibleItems: [UPCateTabItem] {
        guard !isFollowMode else { return items }
        return items.indices.contains(current) ? [items[current]] : []
    }

    /// 上游 `height` 支持 `100%` 这类百分比，此时交给父级。
    public var resolvedHeight: CGFloat? {
        guard !height.contains("%") else { return nil }
        let value = UPUnit.parse(height)
        return value > 0 ? value : nil
    }

    // MARK: - 上游方法

    /// 对应上游 `swichMenu(index)` + `leftMenuStatus(index)`。
    public func select(_ index: Int) {
        guard items.indices.contains(index) else { return }
        state.current = index
        currentBinding?.wrappedValue = index
        onChangeHandler?(items[index])
        onChangePayloadHandler?(UPCateTabChange(index: index, item: items[index]))
    }

    /// 对应上游 `rightScroll`：按每组的 `top` 反查当前分组。
    /// 上游用 `scrollTop + 1` 与相邻两组的 `top` 比较：
    /// `if (!height2 || scrollHeight >= height1 && scrollHeight <= height2)`。
    /// 注意 `!height2` 在 JS 里对 `0` 也成立，所以下一组偏移为 0（尚未量到）时
    /// 会直接选中当前这组；这里照抄该判断。
    public func syncCurrent(scrollTop: CGFloat) {
        guard isFollowMode, !items.isEmpty else { return }
        let tops = (0..<items.count).map { offsets[$0] ?? 0 }
        let position = scrollTop + 1
        for index in tops.indices {
            let lower = tops[index]
            let next = index + 1 < tops.count ? tops[index + 1] : 0
            if next == 0 || (position >= lower && position <= next) {
                select(index)
                return
            }
        }
    }

    // MARK: - 事件与插槽

    public func onChange(_ action: @escaping (UPCateTabItem) -> Void) -> UPCateTab {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onChangePayload(_ action: @escaping (UPCateTabChange) -> Void) -> UPCateTab {
        var copy = self
        copy.onChangePayloadHandler = action
        return copy
    }

    /// 对应上游 `#tabItem` 作用域插槽。
    public func tabItem<Slot: View>(@ViewBuilder _ builder: @escaping (UPCateTabItem) -> Slot) -> UPCateTab {
        var copy = self
        copy.tabItemSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游 `#rightTop` 插槽。
    public func rightTop<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPCateTab {
        var copy = self
        copy.rightTopSlot = AnyView(builder())
        return copy
    }

    /// 对应上游 `#itemList` 作用域插槽：整组内容自定义。
    public func itemList<Slot: View>(@ViewBuilder _ builder: @escaping (UPCateTabItem) -> Slot) -> UPCateTab {
        var copy = self
        copy.itemListSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游 `#pageItem` 作用域插槽：单个子项自定义。
    public func pageItem<Slot: View>(@ViewBuilder _ builder: @escaping (UPCateTabChild) -> Slot) -> UPCateTab {
        var copy = self
        copy.pageItemSlot = { AnyView(builder($0)) }
        return copy
    }

    public var hasTabItemSlot: Bool { tabItemSlot != nil }
    public var hasRightTopSlot: Bool { rightTopSlot != nil }
    public var hasItemListSlot: Bool { itemListSlot != nil }
    public var hasPageItemSlot: Bool { pageItemSlot != nil }

    // MARK: - 视图

    public var body: some View {
        HStack(spacing: 0) {
            menu
            rightBox
        }
        .frame(height: resolvedHeight)
    }

    /// 上游左栏：`width: 200rpx`，选中项换白底并在左侧描一条主题色竖线。
    private var menu: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        menuItem(item, index: index)
                            .id(index)
                    }
                }
            }
            .onChange(of: current) { _, index in
                withAnimation { proxy.scrollTo(index, anchor: .center) }
            }
        }
        .frame(width: UPUnit.rpx(CGFloat(UPConfig.cateTab.menuWidth)))
        .background(theme.bg)
    }

    private func menuItem(_ item: UPCateTabItem, index: Int) -> some View {
        let active = index == current
        return Group {
            if let tabItemSlot {
                tabItemSlot(item)
            } else {
                Text(item.title)
                    .font(.system(size: UPUnit.rpx(CGFloat(active ? 30 : 26)),
                                  weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? theme.main : theme.content)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UPUnit.rpx(CGFloat(UPConfig.cateTab.itemHeight)))
        .background(active ? Color.white : theme.bg)
        .overlay(alignment: .leading) {
            if active {
                Rectangle()
                    .fill(theme.primary)
                    .frame(width: 4, height: UPUnit.rpx(CGFloat(32)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { select(index) }
    }

    /// 上游右栏：`follow` 铺全部分组并随滚动反查高亮，`tab` 只铺当前分组。
    private var rightBox: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: UPUnit.rpx(CGFloat(30))) {
                    if let rightTopSlot { rightTopSlot }

                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { offset, item in
                        group(item, index: isFollowMode ? offset : current)
                    }
                }
                .padding(UPUnit.rpx(CGFloat(16)))
                .background(scrollProbe)
            }
            .coordinateSpace(.named(Self.scrollSpace))
            .onChange(of: current) { _, index in
                guard isFollowMode else { return }
                withAnimation { proxy.scrollTo(items.indices.contains(index) ? items[index].id : "", anchor: .top) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var scrollProbe: some View {
        GeometryReader { inner in
            Color.clear
                .onChange(of: Self.probeFrame(inner)) { _, frame in
                    syncCurrent(scrollTop: -frame.minY)
                }
        }
    }

    private static func probeFrame(_ proxy: GeometryProxy) -> CGRect {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return proxy.frame(in: space)
    }

    private func group(_ item: UPCateTabItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: UPUnit.rpx(CGFloat(20))) {
            if let itemListSlot {
                itemListSlot(item)
            } else {
                Text(item.title)
                    .font(.system(size: UPUnit.rpx(CGFloat(26)), weight: .bold))
                    .foregroundStyle(theme.main)

                UPAlbumWrapLayout(spacing: 0, lineSpacing: UPUnit.rpx(CGFloat(20))) {
                    ForEach(item.children) { child in
                        childCell(child)
                    }
                }
            }
        }
        .padding(UPUnit.rpx(CGFloat(16)))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay { RoundedRectangle(cornerRadius: UPUnit.rpx(CGFloat(8))).strokeBorder(theme.border, lineWidth: 1) }
        .clipShape(RoundedRectangle(cornerRadius: UPUnit.rpx(CGFloat(8))))
        .id(item.id)
        // 记录每组的顶部偏移，供 `syncCurrent` 反查（对应上游 `getMenuItemTop`）。
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { offsets[index] = proxy.frame(in: .named(Self.scrollSpace)).minY }
            }
        }
    }

    @ViewBuilder
    private func childCell(_ child: UPCateTabChild) -> some View {
        if let pageItemSlot {
            pageItemSlot(child)
        } else {
            VStack(spacing: 4) {
                UPImage(src: child.icon,
                        mode: "aspectFill",
                        width: UPUnit.rpx(CGFloat(120)),
                        height: UPUnit.rpx(CGFloat(120)))
                Text(child.name)
                    .font(.system(size: UPUnit.rpx(CGFloat(24))))
                    .foregroundStyle(theme.main)
                    .lineLimit(1)
            }
            .frame(width: UPUnit.rpx(CGFloat(120)) + 12)
        }
    }
}
