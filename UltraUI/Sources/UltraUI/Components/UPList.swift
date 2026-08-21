import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-list`.
@MainActor
public struct UPList<Item, Content: View>: View {
    public var items: [Item]
    public var loadmore: Bool
    public var finished: Bool
    public var loading: Bool
    public var lowerThreshold: CGFloat
    public var showScrollbar: Bool
    public var height: CGFloat?

    private let content: (Item) -> Content
    private var onLoadHandler: (() -> Void)?
    private var onScrolltolowerHandler: (() -> Void)?

    public init(
        items: [Item],
        loadmore: Bool = false,
        finished: Bool = false,
        loading: Bool = false,
        lowerThreshold: CGFloat = 50,
        showScrollbar: Bool = true,
        height: CGFloat? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.loadmore = loadmore
        self.finished = finished
        self.loading = loading
        self.lowerThreshold = max(lowerThreshold, 0)
        self.showScrollbar = showScrollbar
        self.height = height
        self.content = content
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: showScrollbar) {
            LazyVStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    content(items[index])
                }

                if loadmore && !finished {
                    Color.clear
                        .frame(height: 1)
                        .onAppear(perform: reachBottom)
                }
            }
        }
        .frame(height: height)
        .onAppear(perform: load)
    }

    public func load() {
        onLoadHandler?()
    }

    public func reachBottom() {
        guard loadmore, !finished, !loading else { return }
        onScrolltolowerHandler?()
    }

    public func onLoad(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    public func onScrolltolower(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onScrolltolowerHandler = action
        return copy
    }
}

public extension UPList where Content == EmptyView {
    init(
        items: [Item],
        loadmore: Bool = false,
        finished: Bool = false,
        loading: Bool = false,
        lowerThreshold: CGFloat = 50,
        showScrollbar: Bool = true,
        height: CGFloat? = nil
    ) {
        self.init(
            items: items,
            loadmore: loadmore,
            finished: finished,
            loading: loading,
            lowerThreshold: lowerThreshold,
            showScrollbar: showScrollbar,
            height: height,
            content: { _ in EmptyView() }
        )
    }
}
