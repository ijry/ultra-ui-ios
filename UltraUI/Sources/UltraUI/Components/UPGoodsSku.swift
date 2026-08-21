import SwiftUI

public struct UPGoodsSkuOption: Identifiable, Equatable, Sendable { public let id: String; public let name: String; public let values: [String]; public init(name: String, values: [String], id: String? = nil) { self.name = name; self.values = values; self.id = id ?? name } }

@MainActor
public final class UPGoodsSku: View {
    public let options: [UPGoodsSkuOption]; public private(set) var selections: [String: String] = [:]
    private var onChangeHandler: (([String: String]) -> Void)?; private var onConfirmHandler: (([String: String]) -> Void)?
    public init(options: [UPGoodsSkuOption] = [], onChange: (([String: String]) -> Void)? = nil, onConfirm: (([String: String]) -> Void)? = nil) { self.options = options; self.onChangeHandler = onChange; self.onConfirmHandler = onConfirm }
    public func select(_ name: String, value: String) { guard let option = options.first(where: { $0.name == name }), option.values.contains(value) else { return }; selections[name] = value; onChangeHandler?(selections) }
    public func onChange(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { onChangeHandler = action; return self }
    public func onConfirm(_ action: @escaping ([String: String]) -> Void) -> UPGoodsSku { onConfirmHandler = action; return self }
    @discardableResult public func confirm() -> Bool { guard options.allSatisfy({ selections[$0.name] != nil }) else { return false }; onConfirmHandler?(selections); return true }
    public var body: some View { VStack(alignment: .leading) { ForEach(self.options) { option in HStack { Text(option.name); ForEach(option.values, id: \.self) { value in Button(value) { self.select(option.name, value: value) }.buttonStyle(.bordered).tint(self.selections[option.name] == value ? .accentColor : .secondary) } } } } }
}
