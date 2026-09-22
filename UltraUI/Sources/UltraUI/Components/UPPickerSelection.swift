import SwiftUI

/// 上游 `options` 里的一个元素：`item[labelName]` 当显示文本、`item[valueName]` 当值。
public struct UPChooseOption: Identifiable, Equatable, Sendable {
    public var value: String
    public var title: String
    public var id: String { value }

    public init(value: String, title: String) {
        self.value = value
        self.title = title
    }
}

/// 对应上游 `data.currentIndex`。
@MainActor
@Observable
private final class UPChooseState {
    /// 上游 `currentIndex` 初始是空串，`watch.modelValue` 会把它直接改写成 `modelValue`。
    var currentIndex: Int?

    init(_ index: Int?) { self.currentIndex = index }
}

/// Native SwiftUI counterpart of uview-plus `u-choose`.
///
/// 上游是一排 `up-tag`：激活项实心 `primary`、其余描边 `info`，`wrap` 决定换行还是横向滚动。
/// 注意上游是**按下标**工作的：`change(index)` 往 `update:modelValue` 里写的是下标，
/// `custom-click` 抛出的也是下标。原生保留这套下标语义，同时保留仓库既有的按值接口。
@MainActor
public struct UPChoose: View {
    public var options: [UPChooseOption]
    /// 上游 `type`：声明为 `radio`，但代码里从未被读取。
    public var type: String
    public var itemWidth: String
    public var itemHeight: String
    public var itemPadding: String
    /// 上游 `labelName`：取显示文本的字段名，默认 `title`。
    public var labelName: String
    /// 上游 `valueName`：默认 `value`，但上游模板与方法里都没用到它。
    public var valueName: String
    /// 上游 `customClick`：为真时只抛 `custom-click`，不写回 `modelValue`。
    public var customClick: Bool
    /// 上游 `wrap`：真则折行，假则横向滚动。
    public var wrap: Bool

    private var modelValue: Binding<String>?
    private var indexBinding: Binding<Int>?
    @State private var state: UPChooseState
    private var onCustomClickHandler: ((String) -> Void)?
    private var onCustomClickIndexHandler: ((Int) -> Void)?
    private var onChangeHandler: ((Int) -> Void)?
    private var itemSlot: ((UPChooseOption, Int) -> AnyView)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器；`modelValue` 是仓库既有的按值绑定。
    public init(options: [UPChooseOption] = [],
                modelValue: Binding<String>? = nil,
                currentIndex: Binding<Int>? = nil,
                type: String = UPConfig.choose.type,
                itemWidth: String = UPConfig.choose.itemWidth,
                itemHeight: String = UPConfig.choose.itemHeight,
                itemPadding: String = UPConfig.choose.itemPadding,
                labelName: String = UPConfig.choose.labelName,
                valueName: String = UPConfig.choose.valueName,
                customClick: Bool = UPConfig.choose.customClick,
                wrap: Bool = UPConfig.choose.wrap) {
        self.options = options
        self.modelValue = modelValue
        self.indexBinding = currentIndex
        self.type = type
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.itemPadding = itemPadding
        self.labelName = labelName
        self.valueName = valueName
        self.customClick = customClick
        self.wrap = wrap
        // 上游 `watch.modelValue` 带 immediate，挂载时就把 currentIndex 同步成传入值。
        let seeded: Int?
        if let index = currentIndex?.wrappedValue {
            seeded = index
        } else if let value = modelValue?.wrappedValue,
                  let index = options.firstIndex(where: { $0.value == value }) {
            seeded = index
        } else {
            seeded = nil
        }
        self._state = State(initialValue: UPChooseState(seeded))
    }

    // MARK: - 解析后的呈现值

    /// 上游 `currentIndex`。
    public var currentIndex: Int? { state.currentIndex }

    /// 上游模板 `index == currentIndex`。
    public func isActive(_ index: Int) -> Bool { state.currentIndex == index }

    /// 上游默认插槽里 `up-tag` 的 `type`：激活 `primary`、其余 `info`。
    public func tagType(at index: Int) -> String {
        isActive(index) ? UPConfig.choose.activeType : UPConfig.choose.inactiveType
    }

    /// 上游 `:plain="index == currentIndex ? false : true"`。
    public func isPlain(at index: Int) -> Bool { !isActive(index) }

    /// 上游 `itemWidth` 是 `auto` 时交给内容自适应。
    public var resolvedItemWidth: CGFloat? {
        let parsed = UPUnit.parse(itemWidth)
        return parsed > 0 ? parsed : nil
    }

    public var resolvedItemHeight: CGFloat { max(UPUnit.parse(itemHeight), 0) }
    public var resolvedItemPadding: CGFloat { max(UPUnit.parse(itemPadding), 0) }

    // MARK: - 上游 methods

    /// 上游 `change(index)`：`customClick` 为真只抛 `custom-click`，否则写回下标。
    public func change(_ index: Int) {
        guard options.indices.contains(index) else { return }
        if customClick {
            onCustomClickIndexHandler?(index)
            onCustomClickHandler?(options[index].value)
            return
        }
        state.currentIndex = index
        indexBinding?.wrappedValue = index
        modelValue?.wrappedValue = options[index].value
        onChangeHandler?(index)
    }

    /// 仓库既有方法：按值选中。
    public func select(_ value: String) {
        guard let index = options.firstIndex(where: { $0.value == value }) else { return }
        change(index)
    }

    // MARK: - 事件

    /// 仓库既有签名：负载是选项值。
    public func onCustomClick(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onCustomClickHandler = action
        return copy
    }

    /// 对应上游 `custom-click` 事件，负载是下标。
    public func onCustomClick(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onCustomClickIndexHandler = action
        return copy
    }

    /// 对应上游 `update:modelValue`，负载是下标。
    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游默认作用域插槽，参数是 `item` 与 `index`。
    public func itemContent<Slot: View>(@ViewBuilder _ builder: @escaping (UPChooseOption, Int) -> Slot) -> Self {
        var copy = self
        copy.itemSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    public var hasItemSlot: Bool { itemSlot != nil }

    // MARK: - 视图

    public var body: some View {
        Group {
            if wrap {
                // 上游 `.up-choose-wrap { flex-wrap: wrap }`。
                UPAlbumWrapLayout(spacing: 8, lineSpacing: 8) { items }
            } else {
                // 上游 `scroll-x` 只在 `wrap === false` 时开启。
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) { items }
                }
            }
        }
    }

    private var items: some View {
        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
            if let itemSlot {
                itemSlot(option, index)
            } else {
                UPTag(type: tagType(at: index),
                      size: UPConfig.choose.tagSize,
                      text: option.title,
                      plain: isPlain(at: index),
                      height: itemHeight) {
                    change(index)
                }
                .frame(width: resolvedItemWidth)
                .padding(resolvedItemPadding)
            }
        }
    }
}
