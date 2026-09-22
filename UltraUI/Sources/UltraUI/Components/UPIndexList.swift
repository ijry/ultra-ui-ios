import SwiftUI

/// Semantic alias for the `String | Number` `customNavHeight` prop and the
/// unit-bearing `itemMargin` string accepted by uview-plus `u-index-list`.
public typealias UPIndexListUnitValue = UPImageUnitValue

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
    public var indexList: [String]
    public var activeColor: String
    public var inactiveColor: String
    public var sticky: Bool
    /// Upstream subtracts the host navigation bar height from the scroll offset
    /// before matching anchors; kept as a parsed point value.
    public var customNavHeight: CGFloat
    /// Upstream only reads this inside `getIndexListLetter`, where the single
    /// use (`pageY = pageY + 34`) is commented out, so it has no effect on the
    /// letter hit test. Natively it appends a bottom safe-area spacer instead.
    public var safeBottomFix: Bool
    /// Extra bottom margin the host applies to every `u-index-item`; upstream
    /// adds it to the measured item height, so natively it is the stack spacing.
    public var itemMargin: CGFloat
    public var showSidebar: Bool
    public var activeIndex: String {
        activeIndexBinding?.wrappedValue ?? state.activeIndex
    }

    /// Upstream `uIndexList`: the explicit `indexList` when non-empty, otherwise
    /// the internally generated `A-Z` alphabet.
    public var anchors: [String] {
        indexList.isEmpty ? Self.alphabetIndexList : indexList
    }

    /// Upstream generates the fallback index characters from `'A'.charCodeAt(0)`.
    public static var alphabetIndexList: [String] {
        (0..<26).map { String(UnicodeScalar(UInt8(65 + $0))) }
    }

    /// `.u-index-list__letter__item` is 16×16 with `margin: 1px 0`.
    public static var letterItemSize: CGFloat { 16 }
    public static var letterItemMargin: CGFloat { 1 }
    public static var letterItemHeight: CGFloat { letterItemSize + letterItemMargin * 2 }

    /// Height of the whole letter column, used by the touch hit test.
    public var letterColumnHeight: CGFloat {
        CGFloat(anchors.count) * Self.letterItemHeight
    }

    /// Upstream treats the prop defaults as theme sentinels: `#5677fc` falls back
    /// to `--up-primary` and `#606266` to `--up-content-color`.
    public var resolvedActiveColor: String {
        activeColor == UPConfig.indexList.activeColor ? "primary" : activeColor
    }

    public var resolvedInactiveColor: String {
        inactiveColor == UPConfig.indexList.inactiveColor ? "content" : inactiveColor
    }

    /// Native stand-in for the commented-out upstream `safeBottomFix` branch.
    public var showsSafeBottom: Bool { safeBottomFix }

    private var activeIndexBinding: Binding<String>?
    private let state: UPIndexListState
    private let content: Content
    private var onChangeHandler: ((String) -> Void)?
    private var onSelectHandler: ((String) -> Void)?
    @State private var touchIndex: Int?

    public init(
        indexList: [String] = UPConfig.indexList.indexList,
        activeIndex: Binding<String>? = nil,
        activeColor: String = UPConfig.indexList.activeColor,
        inactiveColor: String = UPConfig.indexList.inactiveColor,
        sticky: Bool = UPConfig.indexList.sticky,
        customNavHeight: some UPIndexListUnitValue = UPConfig.indexList.customNavHeight,
        safeBottomFix: Bool = UPConfig.indexList.safeBottomFix,
        itemMargin: some UPIndexListUnitValue = UPConfig.indexList.itemMargin,
        showSidebar: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.indexList = indexList
        self.activeIndexBinding = activeIndex
        self.state = UPIndexListState(activeIndex: activeIndex?.wrappedValue ?? "")
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.sticky = sticky
        self.customNavHeight = UPUnit.parse(customNavHeight.upImageUnitValue)
        self.safeBottomFix = safeBottomFix
        self.itemMargin = UPUnit.parse(itemMargin.upImageUnitValue)
        self.showSidebar = showSidebar
        self.content = content()
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: itemMargin, pinnedViews: sticky ? [.sectionHeaders] : []) {
                        content

                        if showsSafeBottom { UPSafeBottom() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if showSidebar {
                    letterColumn(proxy: proxy)
                }

                if let touchIndex, anchors.indices.contains(touchIndex) {
                    indicator(anchors[touchIndex])
                        .offset(y: indicatorOffsetY(forIndex: touchIndex))
                        .padding(.trailing, 50)
                        .allowsHitTesting(false)
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

    /// Port of the upstream `scrollHandler`: item offsets accumulate
    /// `height + getPx(itemMargin)` on top of the header height, the scroll
    /// offset is shifted by `customNavHeight`, and offsets outside the first and
    /// last item clear the highlight (upstream `activeIndex = -1`).
    public func scrollActiveIndex(
        scrollTop: CGFloat,
        itemHeights: [CGFloat],
        headerHeight: CGFloat = 0,
        current: Int = -1
    ) -> Int {
        var top = headerHeight
        let children: [(height: CGFloat, top: CGFloat)] = itemHeights.map { height in
            let childHeight = height + itemMargin
            let child = (height: childHeight, top: top)
            top += childHeight
            return child
        }
        let offset = scrollTop + customNavHeight
        let count = children.count
        for index in 0..<count {
            let item = children[index]
            let next = index + 1 < count ? children[index + 1] : nil
            if offset <= children[0].top || offset >= children[count - 1].top + children[count - 1].height {
                return -1
            } else if next == nil {
                return count - 1
            } else if let next, offset > item.top, offset < next.top {
                return index
            }
        }
        return current
    }

    /// Port of the upstream `getIndexListLetter`: the touch offset inside the
    /// letter column is divided by the per-letter height, clamped at both ends
    /// because the finger may keep sliding past the first or last letter.
    public func letterIndex(forOffsetY offsetY: CGFloat) -> Int {
        let count = anchors.count
        guard count > 0 else { return -1 }
        if offsetY < 0 { return 0 }
        if offsetY >= letterColumnHeight { return count - 1 }
        return min(count - 1, max(0, Int((offsetY / Self.letterItemHeight).rounded(.down))))
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

    private func letterColumn(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: Self.letterItemMargin * 2) {
            ForEach(Array(anchors.enumerated()), id: \.offset) { offset, anchor in
                Text(anchor)
                    .font(.system(size: 12))
                    .foregroundStyle(anchor == activeIndex ? UPColor.parse("#ffffff") : UPColor.parse(resolvedInactiveColor))
                    .frame(width: Self.letterItemSize, height: Self.letterItemSize)
                    .background(
                        Circle().fill(anchor == activeIndex ? UPColor.parse(resolvedActiveColor) : .clear)
                    )
                    .contentShape(Rectangle())
                    .accessibilityLabel(anchor)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { scrub(to: offset, proxy: proxy) }
            }
        }
        .frame(width: 30)
        .padding(.horizontal, 6)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    scrub(to: letterIndex(forOffsetY: value.location.y), proxy: proxy)
                }
                .onEnded { _ in
                    // 上游 touchEnd 延时 300ms 再隐藏指示器，避免快速切换时闪烁。
                    let pending = touchIndex
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        if touchIndex == pending { touchIndex = nil }
                    }
                }
        )
    }

    private func indicator(_ anchor: String) -> some View {
        Text(anchor)
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(UPColor.parse("#ffffff"))
            .rotationEffect(.degrees(45))
            .frame(width: 50, height: 50)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 25,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 25
                )
                .fill(UPColor.parse("content"))
            )
            .rotationEffect(.degrees(-45))
    }

    private func indicatorOffsetY(forIndex index: Int) -> CGFloat {
        CGFloat(index) * Self.letterItemHeight + Self.letterItemHeight / 2 - letterColumnHeight / 2
    }

    private func scrub(to index: Int, proxy: ScrollViewProxy) {
        guard anchors.indices.contains(index) else { return }
        touchIndex = index
        let anchor = anchors[index]
        guard anchor != activeIndex else { return }
        select(anchor)
        proxy.scrollTo(anchor, anchor: .top)
    }
}

public extension UPIndexList where Content == EmptyView {
    init(
        indexList: [String] = UPConfig.indexList.indexList,
        activeIndex: Binding<String>? = nil,
        activeColor: String = UPConfig.indexList.activeColor,
        inactiveColor: String = UPConfig.indexList.inactiveColor,
        sticky: Bool = UPConfig.indexList.sticky,
        customNavHeight: some UPIndexListUnitValue = UPConfig.indexList.customNavHeight,
        safeBottomFix: Bool = UPConfig.indexList.safeBottomFix,
        itemMargin: some UPIndexListUnitValue = UPConfig.indexList.itemMargin,
        showSidebar: Bool = true
    ) {
        self.init(
            indexList: indexList,
            activeIndex: activeIndex,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            sticky: sticky,
            customNavHeight: customNavHeight,
            safeBottomFix: safeBottomFix,
            itemMargin: itemMargin,
            showSidebar: showSidebar,
            content: EmptyView.init
        )
    }
}
