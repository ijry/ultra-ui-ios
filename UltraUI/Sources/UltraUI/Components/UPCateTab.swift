import SwiftUI

public struct UPCateTabItem: Identifiable, Equatable, Sendable { public let id: String; public let title: String; public var value: String; public init(title: String, value: String? = nil, id: String? = nil) { self.title = title; self.value = value ?? title; self.id = id ?? self.value } }

@MainActor
public final class UPCateTab: View {
    public var items: [UPCateTabItem]; public private(set) var current: Int; private var onChangeHandler: ((UPCateTabItem) -> Void)?
    public init(items: [String] = [], current: Int = 0, onChange: ((UPCateTabItem) -> Void)? = nil) { self.items = items.map { UPCateTabItem(title: $0) }; self.current = max(0, current); self.onChangeHandler = onChange }
    public init(items: [UPCateTabItem], current: Int = 0, onChange: ((UPCateTabItem) -> Void)? = nil) { self.items = items; self.current = max(0, current); self.onChangeHandler = onChange }
    public func select(_ index: Int) { guard items.indices.contains(index) else { return }; current = index; onChangeHandler?(items[index]) }
    public func onChange(_ action: @escaping (UPCateTabItem) -> Void) -> UPCateTab { onChangeHandler = action; return self }
    public var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(Array(self.items.enumerated()), id: \.element.id) { index, item in Button(item.title) { self.select(index) }.buttonStyle(.plain).foregroundStyle(index == self.current ? Color.accentColor : .primary) } } } }
}
