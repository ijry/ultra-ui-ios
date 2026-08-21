import SwiftUI

@MainActor
private final class UPIndexListState {
    var activeIndex: String

    init(activeIndex: String) {
        self.activeIndex = activeIndex
    }
}

/// Indexed scrolling container corresponding to uview-plus `u-index-list`.
@MainActor
public struct UPIndexList<Content: View>: View {
    public var anchors: [String]
    public var activeColor: String
    public var inactiveColor: String
    public var sticky: Bool
    public var showSidebar: Bool
    public var activeIndex: String {
        activeIndexBinding?.wrappedValue ?? state.activeIndex
    }

    private var activeIndexBinding: Binding<String>?
    private let state: UPIndexListState
    private let content: Content
    private var onChangeHandler: ((String) -> Void)?
    private var onSelectHandler: ((String) -> Void)?

    public init(
        anchors: [String],
        activeIndex: Binding<String>? = nil,
        activeColor: String = "#3c9cff",
        inactiveColor: String = "#606266",
        sticky: Bool = true,
        showSidebar: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.anchors = anchors
        self.activeIndexBinding = activeIndex
        self.state = UPIndexListState(activeIndex: activeIndex?.wrappedValue ?? anchors.first ?? "")
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.sticky = sticky
        self.showSidebar = showSidebar
        self.content = content()
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: sticky ? [.sectionHeaders] : []) {
                        content
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if showSidebar {
                    VStack(spacing: 3) {
                        ForEach(anchors, id: \.self) { anchor in
                            Button {
                                select(anchor)
                                withAnimation { proxy.scrollTo(anchor, anchor: .top) }
                            } label: {
                                Text(anchor)
                                    .font(.caption2)
                                    .foregroundStyle(UPColor.parse(anchor == activeIndex ? activeColor : inactiveColor))
                                    .frame(minWidth: 20, minHeight: 18)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .environment(\.upIndexListContext, UPIndexListContext(activeIndex: activeIndex, select: select))
        }
    }

    public func index(of anchor: String) -> Int {
        anchors.firstIndex(of: anchor) ?? -1
    }

    public func select(_ anchor: String) {
        guard anchors.contains(anchor) else { return }
        let changed = activeIndex != anchor
        state.activeIndex = anchor
        activeIndexBinding?.wrappedValue = anchor
        onSelectHandler?(anchor)
        if changed { onChangeHandler?(anchor) }
    }

    public func onChange(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onSelect(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }
}

public extension UPIndexList where Content == EmptyView {
    init(
        anchors: [String],
        activeIndex: Binding<String>? = nil,
        activeColor: String = "#3c9cff",
        inactiveColor: String = "#606266",
        sticky: Bool = true,
        showSidebar: Bool = true
    ) {
        self.init(
            anchors: anchors,
            activeIndex: activeIndex,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            sticky: sticky,
            showSidebar: showSidebar,
            content: EmptyView.init
        )
    }
}
