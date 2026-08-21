import SwiftUI

/// Lazy native list with deterministic range calculations matching `u-virtual-list`.
@MainActor
public struct UPVirtualList<Item, Content: View>: View {
    public var items: [Item]
    public var itemHeight: CGFloat
    public var viewportHeight: CGFloat
    public var overscan: Int
    public var showScrollbar: Bool
    private let content: (Item) -> Content

    public init(
        items: [Item],
        itemHeight: CGFloat,
        viewportHeight: CGFloat,
        overscan: Int = 2,
        showScrollbar: Bool = true,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.itemHeight = max(itemHeight, 0)
        self.viewportHeight = max(viewportHeight, 0)
        self.overscan = max(overscan, 0)
        self.showScrollbar = showScrollbar
        self.content = content
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: showScrollbar) {
            LazyVStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    content(items[index]).frame(height: itemHeight)
                }
            }
        }
        .frame(height: viewportHeight)
    }

    public func visibleRange(offset: CGFloat) -> ClosedRange<Int> {
        guard !items.isEmpty, itemHeight > 0, viewportHeight > 0 else { return 0...0 }
        let safeOffset = min(max(offset, 0), max(totalHeight - viewportHeight, 0))
        let firstVisible = Int(floor(safeOffset / itemHeight))
        let visibleCount = max(Int(ceil(viewportHeight / itemHeight)), 1)
        let lower = max(firstVisible - overscan, 0)
        let upper = min(firstVisible + visibleCount + overscan - 1, items.count - 1)
        return lower...max(lower, upper)
    }

    public func topSpacer(offset: CGFloat) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return CGFloat(visibleRange(offset: offset).lowerBound) * itemHeight
    }

    public func bottomSpacer(offset: CGFloat) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let renderedCount = visibleRange(offset: offset).upperBound + 1
        return max(totalHeight - CGFloat(renderedCount) * itemHeight, 0)
    }

    private var totalHeight: CGFloat {
        CGFloat(items.count) * itemHeight
    }
}

public extension UPVirtualList where Content == EmptyView {
    init(
        items: [Item],
        itemHeight: CGFloat,
        viewportHeight: CGFloat,
        overscan: Int = 2,
        showScrollbar: Bool = true
    ) {
        self.init(
            items: items,
            itemHeight: itemHeight,
            viewportHeight: viewportHeight,
            overscan: overscan,
            showScrollbar: showScrollbar,
            content: { _ in EmptyView() }
        )
    }
}
