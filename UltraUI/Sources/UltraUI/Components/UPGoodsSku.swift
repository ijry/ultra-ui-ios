import Observation
import SwiftUI

public struct UPGoodsSkuOption: Identifiable, Equatable, Sendable { public let id: String; public let name: String; public let values: [String]; public init(name: String, values: [String], id: String? = nil) { self.name = name; self.values = values; self.id = id ?? name } }
public struct UPGoodsSkuCombination: Equatable, Sendable {
    public let selections: [String: String]
    public let stock: Int
    public let price: Double?
    public init(selections: [String: String], stock: Int, price: Double? = nil) { self.selections = selections; self.stock = max(0, stock); self.price = price }
}
public struct UPGoodsSkuConfirmation: Sendable {
    public let selections: [String: String]
    public let combination: UPGoodsSkuCombination
    public let quantity: Int
    public init(selections: [String: String], combination: UPGoodsSkuCombination, quantity: Int) { self.selections = selections; self.combination = combination; self.quantity = quantity }
}

/// SwiftUI requires views to be value types, so the mutable selection and
/// quantity live in a small reference box rather than making the view a class.
@MainActor
@Observable
private final class UPGoodsSkuState {
    var selections: [String: String]
    var quantity: Int
    /// 对应上游 `data.show`。
    var show: Bool

    init(selections: [String: String], quantity: Int, show: Bool = false) {
        self.selections = selections
        self.quantity = quantity
        self.show = show
    }
}

/// Native SwiftUI counterpart of uview-plus `u-goods-sku`.
///
/// 上游是底部弹出的规格选择：头部显示图片/价格/库存/已选文案，中间按 `skuTree`
/// 铺各维度（不可组合的取值置灰），底部数量步进器与确认按钮；
/// `pageInline` 为真时 `created` 里直接 `show = true`，不再弹层。
///
/// 原生保留同一套组合校验与库存约束，并把 `skuTree` / `skuList` / `goodsInfo`
/// 三个数据 prop 落成强类型模型。
@MainActor
public struct UPGoodsSku: View {
    public let options: [UPGoodsSkuOption]
    public let combinations: [UPGoodsSkuCombination]
    public let maxBuy: Int
    public var goodsInfo: UPGoodsInfo
    /// 上游 `skuTree`：带 label 与叶子 id 的维度列表。
    public var skuTree: [UPGoodsSkuTreeItem]
    /// 上游 `skuList`：扁平的库存组合表。
    public var skuList: [UPGoodsSkuItem]
    public var confirmText: String
    public var closeable: Bool
    public var pageInline: Bool
    public var selections: [String: String] { state.selections }
    public var quantity: Int { state.quantity }
    /// 对应上游 `data.show`。
    public var show: Bool { state.show }

    @State private var state: UPGoodsSkuState
    @Environment(\.upTheme) private var theme
    private var quantityBinding: Binding<Int>?
    private var onChangeHandler: (([String: String]) -> Void)?
    private var onConfirmHandler: (([String: String]) -> Void)?
    private var onConfirmPayloadHandler: ((UPGoodsSkuConfirmation) -> Void)?
    private var onConfirmEventHandler: ((UPGoodsSkuConfirmEvent) -> Void)?
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    private var triggerSlot: AnyView?
    private var headerSlot: AnyView?

    public init(options: [UPGoodsSkuOption] = [], onChange: (([String: String]) -> Void)? = nil, onConfirm: (([String: String]) -> Void)? = nil) {
        self.options = options
        self.combinations = []
        self.maxBuy = UPConfig.goodsSku.maxBuy
        self.goodsInfo = UPGoodsInfo()
        self.skuTree = options.map { UPGoodsSkuTreeItem(name: $0.name,
                                                        children: $0.values.map { UPGoodsSkuLeaf(id: $0, name: $0) }) }
        self.skuList = []
        self.confirmText = UPConfig.goodsSku.confirmText
        self.closeable = UPConfig.goodsSku.closeable
        self.pageInline = UPConfig.goodsSku.pageInline
        self._state = State(initialValue: UPGoodsSkuState(selections: [:], quantity: 1))
        self.onChangeHandler = onChange
        self.onConfirmHandler = onConfirm
    }

    public init(options: [UPGoodsSkuOption] = [], combinations: [UPGoodsSkuCombination] = [],
                selectedValues: [String: String] = [:], quantity: Binding<Int>? = nil,
                maxBuy: Int = 999, onChange: (([String: String]) -> Void)? = nil,
                onConfirm: ((UPGoodsSkuConfirmation) -> Void)? = nil) {
        self.options = options
        self.combinations = combinations
        self.maxBuy = max(1, maxBuy)
        self.goodsInfo = UPGoodsInfo()
        self.skuTree = options.map { UPGoodsSkuTreeItem(name: $0.name,
                                                        children: $0.values.map { UPGoodsSkuLeaf(id: $0, name: $0) }) }
        self.skuList = combinations.map { UPGoodsSkuItem(selections: $0.selections, stock: $0.stock, price: $0.price) }
        self.confirmText = UPConfig.goodsSku.confirmText
        self.closeable = UPConfig.goodsSku.closeable
        self.pageInline = UPConfig.goodsSku.pageInline
        self._state = State(initialValue: UPGoodsSkuState(selections: selectedValues,
                                                        quantity: max(1, quantity?.wrappedValue ?? 1)))
        self.quantityBinding = quantity
        self.onChangeHandler = onChange
        self.onConfirmPayloadHandler = onConfirm
    }

    /// 与上游 `props` 对齐的初始化器。
    public init(goodsInfo: UPGoodsInfo = UPGoodsInfo(),
                skuTree: [UPGoodsSkuTreeItem] = [],
                skuList: [UPGoodsSkuItem] = [],
                maxBuy: Int = UPConfig.goodsSku.maxBuy,
                confirmText: String = UPConfig.goodsSku.confirmText,
                closeable: Bool = UPConfig.goodsSku.closeable,
                pageInline: Bool = UPConfig.goodsSku.pageInline,
                quantity: Binding<Int>? = nil) {
        self.options = skuTree.map { item in
            UPGoodsSkuOption(name: item.name, values: item.children.map(\.id), id: item.name)
        }
        self.combinations = skuList.map { UPGoodsSkuCombination(selections: $0.selections,
                                                              stock: $0.stock,
                                                              price: $0.price) }
        self.maxBuy = max(1, maxBuy)
        self.goodsInfo = goodsInfo
        self.skuTree = skuTree
        self.skuList = skuList
        self.confirmText = confirmText
        self.closeable = closeable
        self.pageInline = pageInline
        self.quantityBinding = quantity
        // 上游 `created`：`pageInline` 为真时直接展开。
        self._state = State(initialValue: UPGoodsSkuState(selections: [:],
                                                        quantity: max(1, quantity?.wrappedValue ?? 1),
                                                        show: pageInline))
    }

    public func select(_ name: String, value: String) { guard options.first(where: { $0.name == name })?.values.contains(value) == true, !isDisabled(name, value: value) else { return }; if state.selections[name] == value { state.selections.removeValue(forKey: name) } else { state.selections[name] = value }; onChangeHandler?(selections) }
    public func isDisabled(_ name: String, value: String) -> Bool { guard !combinations.isEmpty else { return false }; var candidate = selections; candidate[name] = value; return !combinations.contains { combination in combination.stock > 0 && candidate.allSatisfy { combination.selections[$0.key] == $0.value } } }
    public func setQuantity(_ value: Int) -> Bool { let limit = min(maxBuy, selectedCombination?.stock ?? 0); guard value >= 1, value <= limit else { return false }; state.quantity = value; quantityBinding?.wrappedValue = value; return true }
    public func onChange(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { var copy = self; copy.onChangeHandler = action; return copy }
    public func onConfirm(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { var copy = self; copy.onConfirmHandler = action; return copy }
    public func onConfirmPayload(_ action: @escaping (UPGoodsSkuConfirmation) -> Void) -> UPGoodsSku { var copy = self; copy.onConfirmPayloadHandler = action; return copy }

    /// 对应上游 `confirm` 事件（负载 `{ sku, goodsInfo, num, selectedText }`）。
    public func onConfirmEvent(_ action: @escaping (UPGoodsSkuConfirmEvent) -> Void) -> UPGoodsSku {
        var copy = self
        copy.onConfirmEventHandler = action
        return copy
    }

    public func onOpen(_ action: @escaping () -> Void) -> UPGoodsSku {
        var copy = self
        copy.onOpenHandler = action
        return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> UPGoodsSku {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    public func onClosed(_ action: @escaping () -> Void) -> UPGoodsSku {
        var copy = self
        copy.onClosedHandler = action
        return copy
    }

    /// 对应上游 `#trigger` / `#header` 插槽。
    public func trigger<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPGoodsSku {
        var copy = self
        copy.triggerSlot = AnyView(builder())
        return copy
    }

    public func header<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPGoodsSku {
        var copy = self
        copy.headerSlot = AnyView(builder())
        return copy
    }

    public var hasTriggerSlot: Bool { triggerSlot != nil }
    public var hasHeaderSlot: Bool { headerSlot != nil }

    /// 对应上游 `open()` / `close()`。
    public func open() {
        state.show = true
        onOpenHandler?()
    }

    public func close() {
        state.show = false
        onCloseHandler?()
        onClosedHandler?()
    }

    /// 对应上游 `reset()`。
    public func reset() {
        state.selections = [:]
        state.quantity = 1
        quantityBinding?.wrappedValue = 1
    }

    /// 上游 `price`：选中组合优先，其次商品价。
    public var price: Double {
        selectedSkuItem?.price ?? goodsInfo.price
    }

    /// 上游 `stock`：选中组合优先，其次商品库存。
    public var stock: Int {
        selectedSkuItem?.stock ?? goodsInfo.stock
    }

    /// 上游 `maxBuyNum = stock > maxBuy ? maxBuy : stock`。
    public var maxBuyNum: Int { min(stock, maxBuy) }

    /// 上游 `canBuy`：所有维度都选了、数量为正、库存为正。
    public var canBuy: Bool {
        let chosen = selections.values.filter { !$0.isEmpty }.count
        return chosen == options.count && !options.isEmpty && quantity > 0 && stock > 0
    }

    /// 上游 `selectedSkuText`：把选中的叶子名拼起来。
    public var selectedSkuText: String {
        skuTree.compactMap { item -> String? in
            guard let id = selections[item.name], !id.isEmpty else { return nil }
            return item.children.first { $0.id == id }?.name
        }.joined(separator: ", ")
    }

    /// 当前选中的库存组合（`skuList` 形态）。
    public var selectedSkuItem: UPGoodsSkuItem? {
        guard let combination = selectedCombination else { return nil }
        return UPGoodsSkuItem(selections: combination.selections,
                              stock: combination.stock,
                              price: combination.price)
    }

    @discardableResult public func confirm() -> Bool {
        guard let combination = selectedCombination, setQuantity(quantity) else { return false }
        onConfirmHandler?(selections)
        onConfirmPayloadHandler?(UPGoodsSkuConfirmation(selections: selections,
                                                      combination: combination,
                                                      quantity: quantity))
        onConfirmEventHandler?(UPGoodsSkuConfirmEvent(sku: selectedSkuItem,
                                                    goodsInfo: goodsInfo,
                                                    num: quantity,
                                                    selectedText: selectedSkuText))
        return true
    }

    private var selectedCombination: UPGoodsSkuCombination? {
        if combinations.isEmpty {
            guard options.allSatisfy({ selections[$0.name] != nil }) else { return nil }
            return UPGoodsSkuCombination(selections: selections, stock: maxBuy)
        }
        return combinations.first { $0.selections.count == options.count && $0.selections == selections && $0.stock > 0 }
    }

    public var body: some View {
        Group {
            if let triggerSlot {
                triggerSlot
                    .contentShape(Rectangle())
                    .onTapGesture { open() }
            }
        }
        .overlay { panel }
    }

    @ViewBuilder
    private var panel: some View {
        UPPopup(show: Binding(get: { show }, set: { if !$0 { close() } }),
                mode: "bottom",
                closeable: pageInline ? false : closeable,
                round: "20px",
                pageInline: pageInline) {
            VStack(alignment: .leading, spacing: 12) {
                headerView
                dimensions
                quantityRow
                UPButton(type: "primary", disabled: !canBuy, text: confirmText, block: true) {
                    _ = confirm()
                }
            }
            .padding(pageInline ? 0 : 16)
        }
    }

    /// 上游 `#header`：图 + 价 + 库存 + 已选。
    @ViewBuilder
    private var headerView: some View {
        if let headerSlot {
            headerSlot
        } else {
            HStack(spacing: 12) {
                UPImage(src: goodsInfo.image, mode: "aspectFill", width: 80, height: 80, radius: 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("¥").font(.system(size: 13)).foregroundStyle(theme.error)
                        Text(String(format: "%g", price)).font(.system(size: 20)).foregroundStyle(theme.error)
                    }
                    Text("库存 \(stock) 件").font(.system(size: 13)).foregroundStyle(theme.tips)
                    Text("已选: \(selectedSkuText)").font(.system(size: 13)).foregroundStyle(theme.content)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var dimensions: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(skuTree) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.main)

                    UPAlbumWrapLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(item.children) { leaf in
                            leafCell(item, leaf)
                        }
                    }
                }
            }
        }
    }

    private func leafCell(_ item: UPGoodsSkuTreeItem, _ leaf: UPGoodsSkuLeaf) -> some View {
        let active = selections[item.name] == leaf.id
        let disabled = isDisabled(item.name, value: leaf.id)
        return Text(leaf.name)
            .font(.system(size: 13))
            .foregroundStyle(active ? Color.white : (disabled ? theme.disabled : theme.main))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(active ? theme.primary : theme.bg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
            .onTapGesture { select(item.name, value: leaf.id) }
    }

    private var quantityRow: some View {
        HStack {
            Text("购买数量")
                .font(.system(size: 14))
                .foregroundStyle(theme.main)
            Spacer(minLength: 0)
            UPNumberBox(modelValue: Binding(get: { quantity }, set: { _ = setQuantity($0) }),
                        min: 1,
                        max: maxBuyNum,
                        disabled: !canBuy)
        }
    }
}
