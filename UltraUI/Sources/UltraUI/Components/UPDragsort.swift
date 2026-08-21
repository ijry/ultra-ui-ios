import SwiftUI

/// Drag-sort container corresponding to uview-plus `u-dragsort`.
@MainActor
public struct UPDragsort<Item: Equatable, Content: View>: View {
    public var items: [Item]
    public var disabled: Bool
    private let content: ((Item) -> Content)?
    private var onChangeHandler: (([Item]) -> Void)?
    private var onStartHandler: ((Int) -> Void)?
    private var onEndHandler: ((Int, Int) -> Void)?

    public init(items: [Item], disabled: Bool = false, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items; self.disabled = disabled; self.content = content
    }

    public init(items: [Item], disabled: Bool = false) where Content == EmptyView {
        self.items = items; self.disabled = disabled; self.content = nil
    }

    public var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                if let content { content(items[index]) } else { EmptyView() }
            }
        }
    }

    @discardableResult
    public func move(from source: Int, to destination: Int) -> [Item] {
        guard !disabled, items.indices.contains(source), !items.isEmpty else { return items }
        var result = items
        let item = result.remove(at: source)
        let target = min(max(destination, 0), result.count)
        result.insert(item, at: target)
        onChangeHandler?(result)
        onEndHandler?(source, target)
        return result
    }

    public func onChange(_ action: @escaping ([Item]) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onStart(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onStartHandler = action; return copy }
    public func onEnd(_ action: @escaping (Int, Int) -> Void) -> Self { var copy = self; copy.onEndHandler = action; return copy }
    public func begin(at index: Int) { guard items.indices.contains(index) else { return }; onStartHandler?(index) }
}
