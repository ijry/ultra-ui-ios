import SwiftUI

/// 上游 `list` 里的一项：字符串或对象，对象时目标路径取 `item[keyName]`。
public struct UPSwiperItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let source: String
    public let title: String
    /// 上游 `item.type`：显式指定 `image` / `video`，未给时按后缀嗅探。
    public let type: String
    /// 上游 `item.poster`：视频封面。
    public let poster: String

    public init(id: String? = nil,
                source: String,
                title: String = "",
                type: String = "",
                poster: String = "") {
        self.id = id ?? source
        self.source = source
        self.title = title
        self.type = type
        self.poster = poster
    }
}

/// 上游 `getItemType(item)` 的返回值。
public enum UPSwiperItemType: String, Equatable, Sendable {
    case image
    case video
}

public enum UPSwiperChangeSource: String, Equatable, Sendable {
    case user
    case programmatic
    case autoplay
}

public struct UPSwiperChange: Equatable, Sendable {
    public var index: Int
    public var item: UPSwiperItem
    public var source: UPSwiperChangeSource

    public init(index: Int, item: UPSwiperItem, source: UPSwiperChangeSource) {
        self.index = index
        self.item = item
        self.source = source
    }
}

@MainActor
public struct UPSwiper: View {
    public var items: [UPSwiperItem]; public var indicator: Bool; public var indicatorActiveColor: String; public var indicatorInactiveColor: String
    public var indicatorStyle: UPStyle; public var indicatorMode: String; public var autoplay: Bool; public var current: Int
    public var currentItemId: String
    public var interval: Int; public var duration: Int; public var circular: Bool; public var vertical: Bool
    public var previousMargin: String; public var nextMargin: String; public var acceleration: Bool; public var displayMultipleItems: Int
    public var easingFunction: String; public var keyName: String; public var imgMode: String; public var height: CGFloat; public var bgColor: String; public var radius: CGFloat; public var loading: Bool; public var showTitle: Bool
    private var currentBinding: Binding<Int>?; private var onChangeHandler: ((Int) -> Void)?; private var onChangePayloadHandler: ((UPSwiperChange) -> Void)?; private var onClickHandler: ((Int) -> Void)?
    private var itemSlot: ((UPSwiperItem, Int) -> AnyView)?
    private var indicatorSlot: AnyView?
    public init(list: [String] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Int = 0, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false) {
        self.init(list: list.map { UPSwiperItem(source: $0) }, indicator: indicator, indicatorActiveColor: indicatorActiveColor, indicatorInactiveColor: indicatorInactiveColor, indicatorStyle: indicatorStyle, indicatorMode: indicatorMode, autoplay: autoplay, current: current, currentItemId: currentItemId, interval: interval, duration: duration, circular: circular, vertical: vertical, previousMargin: previousMargin, nextMargin: nextMargin, acceleration: acceleration, displayMultipleItems: displayMultipleItems, easingFunction: easingFunction, keyName: keyName, imgMode: imgMode, height: height, bgColor: bgColor, radius: radius, loading: loading, showTitle: showTitle)
    }

    public init(list: [UPSwiperItem] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Binding<Int>, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false) {
        self.init(list: list, indicator: indicator, indicatorActiveColor: indicatorActiveColor, indicatorInactiveColor: indicatorInactiveColor, indicatorStyle: indicatorStyle, indicatorMode: indicatorMode, autoplay: autoplay, current: current.wrappedValue, currentItemId: currentItemId, interval: interval, duration: duration, circular: circular, vertical: vertical, previousMargin: previousMargin, nextMargin: nextMargin, acceleration: acceleration, displayMultipleItems: displayMultipleItems, easingFunction: easingFunction, keyName: keyName, imgMode: imgMode, height: height, bgColor: bgColor, radius: radius, loading: loading, showTitle: showTitle, current: current)
    }
    public init(list: [UPSwiperItem] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Int = 0, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false, current binding: Binding<Int>? = nil) {
        self.items = list; self.indicator = indicator; self.indicatorActiveColor = indicatorActiveColor; self.indicatorInactiveColor = indicatorInactiveColor; self.indicatorStyle = indicatorStyle; self.indicatorMode = indicatorMode; self.autoplay = autoplay; self.current = binding?.wrappedValue ?? current; self.currentBinding = binding; self.currentItemId = currentItemId; self.interval = interval; self.duration = duration; self.circular = circular; self.vertical = vertical; self.previousMargin = previousMargin.upImageUnitValue; self.nextMargin = nextMargin.upImageUnitValue; self.acceleration = acceleration; self.displayMultipleItems = max(1, displayMultipleItems); self.easingFunction = easingFunction; self.keyName = keyName; self.imgMode = imgMode; self.height = UPUnit.parse(height.upImageUnitValue); self.bgColor = bgColor; self.radius = UPUnit.parse(radius.upImageUnitValue); self.loading = loading; self.showTitle = showTitle
    }
    // MARK: - 上游 computed / methods

    /// 上游 `getItemType(item)`：只有 `!item.type` 时才按后缀嗅探（`test.video`）。
    ///
    /// 照抄上游：`type` 一旦是真值就不再嗅探，且只认 `image` / `video`，
    /// 其余任何值（如 `'audio'`）都直接落回 `image`，哪怕后缀是 `.mp4`。
    public func itemType(_ item: UPSwiperItem) -> UPSwiperItemType {
        guard !item.type.isEmpty else {
            return UPUploadFile.isVideoSource(item.source) ? .video : .image
        }
        return item.type == "video" ? .video : .image
    }

    /// 上游 `getSource(item)`。原生 `UPSwiperItem` 已经把路径解析进 `source`。
    public func source(of item: UPSwiperItem) -> String { item.source }

    /// 上游 `getPoster(item)`：只有对象形态才可能有 poster。
    public func poster(of item: UPSwiperItem) -> String { item.poster }

    /// 上游 `itemStyle(index)`：只有同时设了前后边距才加圆角，且非当前项缩到 0.92。
    public func itemScale(at index: Int) -> Double {
        guard hasSideMargins, index != selectedIndex else { return 1 }
        return UPConfig.swiper.sideItemScale
    }

    /// 上游 `if (this.nextMargin && this.previousMargin)`：两个都为真值才生效。
    public var hasSideMargins: Bool {
        UPUnit.parse(previousMargin) > 0 && UPUnit.parse(nextMargin) > 0
    }

    /// 上游模板 `showTitle && testObject(item) && item.title && testImage(getSource(item))`。
    ///
    /// 照抄上游：标题只在**图片**项上显示，视频项的标题走 `<video :title>` 而不是这条。
    public func showsTitle(for item: UPSwiperItem) -> Bool {
        showTitle && !item.title.isEmpty && UPUploadFile.isImageSource(item.source)
    }

    /// 上游模板 `:displayMultipleItems="list.length > 0 ? displayMultipleItems : 0"`。
    public var resolvedDisplayMultipleItems: Int {
        items.isEmpty ? 0 : displayMultipleItems
    }

    /// 上游 `indicator && !showTitle`：开了标题就不画内建指示器。
    public var showsIndicator: Bool { !loading && indicator && !showTitle }

    // MARK: - 视图

    public var body: some View {
        Group {
            if loading {
                // 上游 `.u-swiper__loading` 里放一个 circle 模式的 loading-icon。
                UPLoadingIcon(mode: "circle")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                pager
            }
        }
        .frame(height: height)
        .background(UPColor.parse(bgColor))
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(alignment: .bottom) { indicatorLayer }
    }

    private var pager: some View {
        TabView(selection: selectionBinding) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                slide(item, index: index).tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .animation(.easeInOut(duration: Double(duration) / 1000), value: selectedIndex)
        .task(id: autoplayTaskID) { await runAutoplay() }
    }

    private var autoplayTaskID: String { "\(autoplay)|\(interval)|\(items.count)|\(selectedIndex)" }

    /// 上游把自动播放交给原生 `swiper` 的 `autoplay` + `interval`，原生用 Task 轮转。
    private func runAutoplay() async {
        guard autoplay, items.count > 1, interval > 0 else { return }
        try? await Task.sleep(for: .milliseconds(interval))
        guard !Task.isCancelled else { return }
        let next = nextIndex(from: selectedIndex)
        guard next != selectedIndex else { return }
        select(next, source: .autoplay)
    }

    @ViewBuilder
    private func slide(_ item: UPSwiperItem, index: Int) -> some View {
        if let itemSlot {
            itemSlot(item, index)
        } else {
            ZStack(alignment: .bottom) {
                media(item, index: index)

                if showsTitle(for: item) { titleBar(item) }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: hasSideMargins ? radius : 0))
            .scaleEffect(itemScale(at: index))
            .contentShape(Rectangle())
            .onTapGesture { triggerClick(index) }
        }
    }

    @ViewBuilder
    private func media(_ item: UPSwiperItem, index: Int) -> some View {
        switch itemType(item) {
        case .image:
            UPImage(src: source(of: item),
                    mode: imgMode,
                    width: slideWidth,
                    height: height,
                    radius: radius)
        case .video:
            // 上游用 `<video controls :poster>`；原生复用 UPShortVideo 承载播放，
            // poster 只在未起播时兜底显示（上游由原生 video 组件自己处理）。
            ZStack {
                if !poster(of: item).isEmpty {
                    UPImage(src: poster(of: item),
                            mode: imgMode,
                            width: slideWidth,
                            height: height,
                            radius: radius)
                }

                UPShortVideo(src: source(of: item), controls: true)
            }
            .frame(height: height)
        }
    }

    /// 上游 `<image>` 在 nvue 里要靠 `flex: 1` 撑开，原生按容器宽度给一个大值。
    private var slideWidth: CGFloat {
        #if canImport(UIKit)
        return UIScreen.main.bounds.width
        #else
        return 375
        #endif
    }

    /// 上游 `.__title`：半透明底 + 单行省略。
    private func titleBar(_ item: UPSwiperItem) -> some View {
        Text(item.title)
            .font(.system(size: UPConfig.swiper.titleFontSize))
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, UPUnit.rpx(CGFloat(24)))
            .frame(height: UPConfig.swiper.titleHeight)
            .background(UPColor.parse(UPConfig.swiper.titleBackgroundColor))
    }

    /// 上游 `.u-swiper__indicator` 包着 `indicator` 插槽或内建 `u-swiper-indicator`。
    @ViewBuilder
    private var indicatorLayer: some View {
        if let indicatorSlot {
            indicatorSlot.upStyle(indicatorStyle)
        } else if showsIndicator {
            UPSwiperIndicator(length: items.count,
                              current: selectedIndex,
                              indicatorActiveColor: indicatorActiveColor,
                              indicatorInactiveColor: indicatorInactiveColor,
                              indicatorMode: indicatorMode)
                .padding(.bottom, 10)
                .upStyle(indicatorStyle)
        }
    }

    // MARK: - 插槽

    /// 对应上游默认作用域插槽，参数是 `item` 与 `index`。
    public func itemContent<Slot: View>(@ViewBuilder _ builder: @escaping (UPSwiperItem, Int) -> Slot) -> Self {
        var copy = self
        copy.itemSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游具名插槽 `indicator`。
    public func indicatorContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.indicatorSlot = AnyView(builder())
        return copy
    }

    public var hasItemSlot: Bool { itemSlot != nil }
    public var hasIndicatorSlot: Bool { indicatorSlot != nil }
    public var selectedIndex: Int {
        if !currentItemId.isEmpty, let index = items.firstIndex(where: { $0.id == currentItemId }) { return index }
        let raw = currentBinding?.wrappedValue ?? current
        return items.isEmpty ? 0 : min(max(raw, 0), items.count - 1)
    }
    public var selectionBinding: Binding<Int> { Binding(get: { selectedIndex }, set: { select($0, source: .user) }) }
    public func select(_ index: Int) { select(index, source: .programmatic) }
    public func select(_ index: Int, source: UPSwiperChangeSource) {
        guard items.indices.contains(index), index != selectedIndex else { return }
        currentBinding?.wrappedValue = index
        onChangeHandler?(index)
        onChangePayloadHandler?(UPSwiperChange(index: index, item: items[index], source: source))
    }
    public func nextIndex(from index: Int) -> Int { guard !items.isEmpty else { return 0 }; if index + 1 < items.count { return index + 1 }; return circular ? 0 : index }
    public func previousIndex(from index: Int) -> Int { guard !items.isEmpty else { return 0 }; if index > 0 && index < items.count { return index - 1 }; return circular ? items.count - 1 : max(0, min(index, items.count - 1)) }
    public func onChange(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onChangePayload(_ action: @escaping (UPSwiperChange) -> Void) -> Self { var copy = self; copy.onChangePayloadHandler = action; return copy }
    public func onClick(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func triggerClick(_ index: Int) { guard items.indices.contains(index) else { return }; onClickHandler?(index) }
}

/// Native SwiftUI counterpart of uview-plus `u-swiper-indicator`.
///
/// 上游有两种形态：`line` 是一条 `lineWidth * length` 宽的底槽，里面一个 22pt 的滑块
/// 按 `translateX(current * 22)` 平移；`dot` 是一串 5pt 圆点，激活项宽度变 12pt。
@MainActor
public struct UPSwiperIndicator: View {
    public var length: String
    public var current: String
    public var indicatorActiveColor: String
    public var indicatorInactiveColor: String
    /// 上游 `indicatorMode`：`line` / `dot`。
    public var indicatorMode: String

    @Environment(\.upTheme) private var theme

    public init(length: some UPImageUnitValue = UPConfig.swiperIndicator.length,
                current: some UPImageUnitValue = UPConfig.swiperIndicator.current,
                indicatorActiveColor: String = UPConfig.swiperIndicator.indicatorActiveColor,
                indicatorInactiveColor: String = UPConfig.swiperIndicator.indicatorInactiveColor,
                indicatorMode: String = UPConfig.swiperIndicator.indicatorMode) {
        self.length = length.upImageUnitValue
        self.current = current.upImageUnitValue
        self.indicatorActiveColor = indicatorActiveColor
        self.indicatorInactiveColor = indicatorInactiveColor
        self.indicatorMode = indicatorMode
    }

    public var resolvedLength: Int { max(0, Int(UPUnit.parse(length))) }

    public var resolvedCurrent: Int {
        resolvedLength == 0 ? 0 : min(max(Int(UPUnit.parse(current)), 0), resolvedLength - 1)
    }

    /// 上游 `lineStyle.transform = translateX(current * lineWidth)`。
    public var lineOffset: CGFloat {
        CGFloat(resolvedCurrent) * UPConfig.swiperIndicator.lineWidth
    }

    /// 上游 `.--line` 的底槽宽度：`lineWidth * length`。
    public var lineTrackWidth: CGFloat {
        CGFloat(resolvedLength) * UPConfig.swiperIndicator.lineWidth
    }

    /// 上游 `dotStyle(index)` 的取色。
    public func dotColor(at index: Int) -> String {
        index == resolvedCurrent ? indicatorActiveColor : indicatorInactiveColor
    }

    /// 上游 `.__dot--active { width: 12px }`。
    public func dotWidth(at index: Int) -> CGFloat {
        index == resolvedCurrent
            ? UPConfig.swiperIndicator.activeDotWidth
            : UPConfig.swiperIndicator.dotSize
    }

    public var body: some View {
        Group {
            if indicatorMode == "line" { lineIndicator } else if indicatorMode == "dot" { dotIndicator }
        }
    }

    private var lineIndicator: some View {
        Capsule()
            .fill(UPColor.parse(indicatorInactiveColor, theme: theme))
            .frame(width: lineTrackWidth, height: UPConfig.swiperIndicator.lineHeight)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(UPColor.parse(indicatorActiveColor, theme: theme))
                    .frame(width: UPConfig.swiperIndicator.lineWidth,
                           height: UPConfig.swiperIndicator.lineHeight)
                    .offset(x: lineOffset)
                    // 上游 `.--line__bar { transition: transform 0.3s }`。
                    .animation(.easeInOut(duration: 0.3), value: lineOffset)
            }
    }

    private var dotIndicator: some View {
        HStack(spacing: UPConfig.swiperIndicator.dotSpacing * 2) {
            ForEach(Array(0..<resolvedLength), id: \.self) { index in
                Capsule()
                    .fill(UPColor.parse(dotColor(at: index), theme: theme))
                    .frame(width: dotWidth(at: index), height: UPConfig.swiperIndicator.dotSize)
            }
        }
    }
}
