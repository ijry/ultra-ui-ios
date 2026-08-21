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

@MainActor
public final class UPGoodsSku: View {
    public let options: [UPGoodsSkuOption]
    public let combinations: [UPGoodsSkuCombination]
    public let maxBuy: Int
    public private(set) var selections: [String: String]
    public private(set) var quantity: Int
    private var quantityBinding: Binding<Int>?
    private var onChangeHandler: (([String: String]) -> Void)?
    private var onConfirmHandler: (([String: String]) -> Void)?
    private var onConfirmPayloadHandler: ((UPGoodsSkuConfirmation) -> Void)?

    public init(options: [UPGoodsSkuOption] = [], onChange: (([String: String]) -> Void)? = nil, onConfirm: (([String: String]) -> Void)? = nil) {
        self.options = options; self.combinations = []; self.maxBuy = 999; self.selections = [:]; self.quantity = 1; self.onChangeHandler = onChange; self.onConfirmHandler = onConfirm
    }
    public init(options: [UPGoodsSkuOption] = [], combinations: [UPGoodsSkuCombination] = [],
                selectedValues: [String: String] = [:], quantity: Binding<Int>? = nil,
                maxBuy: Int = 999, onChange: (([String: String]) -> Void)? = nil,
                onConfirm: ((UPGoodsSkuConfirmation) -> Void)? = nil) {
        self.options = options; self.combinations = combinations; self.maxBuy = max(1, maxBuy); self.selections = selectedValues; self.quantityBinding = quantity; self.quantity = max(1, quantity?.wrappedValue ?? 1); self.onChangeHandler = onChange; self.onConfirmPayloadHandler = onConfirm
    }
    public func select(_ name: String, value: String) { guard options.first(where: { $0.name == name })?.values.contains(value) == true, !isDisabled(name, value: value) else { return }; if selections[name] == value { selections.removeValue(forKey: name) } else { selections[name] = value }; onChangeHandler?(selections) }
    public func isDisabled(_ name: String, value: String) -> Bool { guard !combinations.isEmpty else { return false }; var candidate = selections; candidate[name] = value; return !combinations.contains { combination in combination.stock > 0 && candidate.allSatisfy { combination.selections[$0.key] == $0.value } } }
    public func setQuantity(_ value: Int) -> Bool { let limit = min(maxBuy, selectedCombination?.stock ?? 0); guard value >= 1, value <= limit else { return false }; quantity = value; quantityBinding?.wrappedValue = value; return true }
    public func onChange(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { onChangeHandler = action; return self }
    public func onConfirm(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { onConfirmHandler = action; return self }
    public func onConfirmPayload(_ action: @escaping (UPGoodsSkuConfirmation) -> Void) -> UPGoodsSku { onConfirmPayloadHandler = action; return self }
    @discardableResult public func confirm() -> Bool { guard let combination = selectedCombination, setQuantity(quantity) else { return false }; onConfirmHandler?(selections); onConfirmPayloadHandler?(UPGoodsSkuConfirmation(selections: selections, combination: combination, quantity: quantity)); return true }
    private var selectedCombination: UPGoodsSkuCombination? {
        if combinations.isEmpty {
            guard options.allSatisfy({ selections[$0.name] != nil }) else { return nil }
            return UPGoodsSkuCombination(selections: selections, stock: maxBuy)
        }
        return combinations.first { $0.selections.count == options.count && $0.selections == selections && $0.stock > 0 }
    }
    public var body: some View { VStack(alignment: .leading) { ForEach(self.options) { option in HStack { Text(option.name); ForEach(option.values, id: \.self) { value in Button(value) { self.select(option.name, value: value) }.buttonStyle(.bordered).tint(self.selections[option.name] == value ? .accentColor : .secondary).disabled(self.isDisabled(option.name, value: value)) } } } } }
}
