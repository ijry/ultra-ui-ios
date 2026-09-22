import Observation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

/// 对应上游 `data` 里与列表相关的可变状态。
@MainActor
@Observable
final class UPShortVideoFeedState {
    var currentTab: Int
    var currentVideo: Int
    var items: [UPShortVideoItem]
    var showSpeedSheet = false
    var speedTargetIndex = 0

    init(currentTab: Int, currentVideo: Int, items: [UPShortVideoItem]) {
        self.currentTab = currentTab
        self.currentVideo = currentVideo
        self.items = items
    }
}

/// Native SwiftUI counterpart of uview-plus `u-short-video` 的「信息流」形态。
///
/// 上游组件本身就是一整屏短视频流：顶部 tabs、纵向 swiper 逐条切视频、
/// 右侧点赞/评论/分享/收藏、底部进度条与 tabbar，配 `menu` / `search` /
/// `actions` / `tabbar` 四个插槽。单条播放器仍是 `UPShortVideo`。
///
/// 原生用 `TabView(.page)` 做纵向翻页，播放交给 `UPShortVideo`；
/// 倍速弹窗、tabbar 这类壳层交给宿主（`tabbar` 插槽即可）。
@MainActor
public struct UPShortVideoFeed: View {
    public var tabsList: [String]
    public var videoList: [UPShortVideoItem] { state.items }
    public var currentTab: Int { state.currentTab }
    public var currentVideo: Int { state.currentVideo }
    /// 上游 `data.speedOptions`。
    public var speedOptions: [Double]

    @State private var state: UPShortVideoFeedState
    @Environment(\.upTheme) private var theme
    private var currentTabBinding: Binding<Int>?
    private var currentVideoBinding: Binding<Int>?
    private var onTabChangeHandler: ((Int) -> Void)?
    private var onVideoChangeHandler: ((Int) -> Void)?
    private var onLikeHandler: ((UPShortVideoAction) -> Void)?
    private var onCommentHandler: ((UPShortVideoAction) -> Void)?
    private var onShareHandler: ((UPShortVideoAction) -> Void)?
    private var onCollectHandler: ((UPShortVideoAction) -> Void)?
    private var onProgressChangingHandler: ((UPShortVideoProgress) -> Void)?
    private var onProgressChangeHandler: ((UPShortVideoProgress) -> Void)?
    private var onVideoPlayHandler: ((UPShortVideoPlayback) -> Void)?
    private var onVideoPauseHandler: ((UPShortVideoPlayback) -> Void)?
    private var menuSlot: AnyView?
    private var searchSlot: AnyView?
    private var actionsSlot: ((UPShortVideoItem, Int) -> AnyView)?
    private var tabbarSlot: AnyView?

    public init(tabsList: [String] = UPConfig.shortVideo.tabsList,
                videoList: [UPShortVideoItem] = UPConfig.shortVideo.videoList,
                currentTab: Int = UPConfig.shortVideo.currentTab,
                currentVideo: Int = UPConfig.shortVideo.currentVideo,
                speedOptions: [Double] = UPConfig.shortVideo.speedOptions) {
        self.tabsList = tabsList
        self.speedOptions = speedOptions
        self._state = State(initialValue: UPShortVideoFeedState(currentTab: currentTab,
                                                               currentVideo: currentVideo,
                                                               items: videoList))
    }

    /// `v-model` 风格：tab 与当前视频下标交给宿主。
    public init(tabsList: [String] = UPConfig.shortVideo.tabsList,
                videoList: [UPShortVideoItem] = UPConfig.shortVideo.videoList,
                currentTab: Binding<Int>,
                currentVideo: Binding<Int>,
                speedOptions: [Double] = UPConfig.shortVideo.speedOptions) {
        self.init(tabsList: tabsList,
                  videoList: videoList,
                  currentTab: currentTab.wrappedValue,
                  currentVideo: currentVideo.wrappedValue,
                  speedOptions: speedOptions)
        self.currentTabBinding = currentTab
        self.currentVideoBinding = currentVideo
    }

    // MARK: - 上游方法

    /// 对应上游 `handleTabChange(index)`。
    public func selectTab(_ index: Int) {
        guard tabsList.indices.contains(index) else { return }
        state.currentTab = index
        currentTabBinding?.wrappedValue = index
        onTabChangeHandler?(index)
    }

    /// 对应上游 `handleSwiperChange`：暂停旧的、播放新的、抛 `videoChange`。
    public func selectVideo(_ index: Int) {
        guard state.items.indices.contains(index) else { return }
        state.currentVideo = index
        currentVideoBinding?.wrappedValue = index
        onVideoChangeHandler?(index)
    }

    /// 对应上游 `handleLike` / `handleComment` / `handleShare` / `handleCollect`。
    public func like(at index: Int) { emitAction(at: index, handler: onLikeHandler) }
    public func comment(at index: Int) { emitAction(at: index, handler: onCommentHandler) }
    public func share(at index: Int) { emitAction(at: index, handler: onShareHandler) }
    public func collect(at index: Int) { emitAction(at: index, handler: onCollectHandler) }

    private func emitAction(at index: Int, handler: ((UPShortVideoAction) -> Void)?) {
        guard state.items.indices.contains(index) else { return }
        handler?(UPShortVideoAction(item: state.items[index], index: index))
    }

    /// 对应上游 `onProgressChanging`：写进当前项并抛事件。
    public func progressChanging(_ value: Double) {
        updateProgress(value)
        onProgressChangingHandler?(UPShortVideoProgress(progress: value, index: currentVideo))
    }

    /// 对应上游 `onProgressChange`。
    public func progressChange(_ value: Double) {
        updateProgress(value)
        onProgressChangeHandler?(UPShortVideoProgress(progress: value, index: currentVideo))
    }

    private func updateProgress(_ value: Double) {
        guard state.items.indices.contains(currentVideo) else { return }
        state.items[currentVideo].progress = min(max(value, 0), 100)
    }

    /// 对应上游 `showSpeedOptions(index)` / `selectSpeed(action)`。
    public func showSpeedOptions(at index: Int) {
        state.speedTargetIndex = index
        state.showSpeedSheet = true
    }

    public func selectSpeed(_ rate: Double) {
        if state.items.indices.contains(state.speedTargetIndex) {
            state.items[state.speedTargetIndex].playbackRate = rate
        }
        state.showSpeedSheet = false
    }

    public var showSpeedSheet: Bool { state.showSpeedSheet }

    /// 对应上游 `onVideoPlay` / `onVideoPause`。
    public func videoPlay() {
        onVideoPlayHandler?(UPShortVideoPlayback(index: currentVideo))
    }

    public func videoPause() {
        onVideoPauseHandler?(UPShortVideoPlayback(index: currentVideo))
    }

    /// 当前项，便于宿主读取计数与进度。
    public var currentItem: UPShortVideoItem? {
        state.items.indices.contains(currentVideo) ? state.items[currentVideo] : nil
    }

    // MARK: - 事件与插槽

    public func onTabChange(_ action: @escaping (Int) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onTabChangeHandler = action
        return copy
    }

    public func onVideoChange(_ action: @escaping (Int) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onVideoChangeHandler = action
        return copy
    }

    public func onLike(_ action: @escaping (UPShortVideoAction) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onLikeHandler = action
        return copy
    }

    public func onComment(_ action: @escaping (UPShortVideoAction) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onCommentHandler = action
        return copy
    }

    public func onShare(_ action: @escaping (UPShortVideoAction) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onShareHandler = action
        return copy
    }

    public func onCollect(_ action: @escaping (UPShortVideoAction) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onCollectHandler = action
        return copy
    }

    public func onProgressChanging(_ action: @escaping (UPShortVideoProgress) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onProgressChangingHandler = action
        return copy
    }

    public func onProgressChange(_ action: @escaping (UPShortVideoProgress) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onProgressChangeHandler = action
        return copy
    }

    public func onVideoPlay(_ action: @escaping (UPShortVideoPlayback) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onVideoPlayHandler = action
        return copy
    }

    public func onVideoPause(_ action: @escaping (UPShortVideoPlayback) -> Void) -> UPShortVideoFeed {
        var copy = self
        copy.onVideoPauseHandler = action
        return copy
    }

    /// 对应上游 `#menu` / `#search` / `#actions` / `#tabbar` 插槽。
    public func menu<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPShortVideoFeed {
        var copy = self
        copy.menuSlot = AnyView(builder())
        return copy
    }

    public func search<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPShortVideoFeed {
        var copy = self
        copy.searchSlot = AnyView(builder())
        return copy
    }

    public func actions<Slot: View>(
        @ViewBuilder _ builder: @escaping (UPShortVideoItem, Int) -> Slot
    ) -> UPShortVideoFeed {
        var copy = self
        copy.actionsSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    public func tabbar<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPShortVideoFeed {
        var copy = self
        copy.tabbarSlot = AnyView(builder())
        return copy
    }

    public var hasMenuSlot: Bool { menuSlot != nil }
    public var hasSearchSlot: Bool { searchSlot != nil }
    public var hasActionsSlot: Bool { actionsSlot != nil }
    public var hasTabbarSlot: Bool { tabbarSlot != nil }

    // MARK: - 视图

    public var body: some View {
        ZStack {
            Color.black

            pager

            VStack {
                header
                Spacer(minLength: 0)
                footer
            }
        }
    }

    /// 上游纵向 `swiper`，原生用 `TabView` 的翻页样式竖排
    /// （整体旋转 -90°、每页再转回 90°，是 SwiftUI 里做竖向分页的常规做法）。
    private var pager: some View {
        TabView(selection: Binding(get: { currentVideo }, set: { selectVideo($0) })) {
            ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                page(item, index: index)
                    .tag(index)
                    .rotationEffect(.degrees(90))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .rotationEffect(.degrees(-90))
        .modifier(UPShortVideoPagingStyle())
    }

    private func page(_ item: UPShortVideoItem, index: Int) -> some View {
        ZStack {
            UPShortVideo(src: item.videoUrl,
                         autoplay: index == currentVideo,
                         loop: true,
                         controls: false,
                         onPlay: { videoPlay() },
                         onPause: { videoPause() })

            VStack {
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    author(item)
                    Spacer(minLength: 0)
                    actionColumn(item, index: index)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 80)
            }
        }
    }

    private func author(_ item: UPShortVideoItem) -> some View {
        HStack(spacing: 10) {
            UPAvatar(src: item.author.avatar, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.author.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                Text(item.author.desc)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private func actionColumn(_ item: UPShortVideoItem, index: Int) -> some View {
        if let actionsSlot {
            actionsSlot(item, index)
        } else {
            VStack(spacing: 18) {
                actionButton(item.isLiked ? "uicon-thumb-up-fill" : "uicon-thumb-up",
                             count: item.likeCount) { like(at: index) }
                actionButton("uicon-chat", count: item.commentCount) { comment(at: index) }
                actionButton("uicon-share", count: item.shareCount) { share(at: index) }
                actionButton(item.isCollected ? "uicon-bookmark-fill" : "uicon-bookmark",
                             count: item.collectCount) { collect(at: index) }
            }
        }
    }

    private func actionButton(_ icon: String, count: Int, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            UPIcon(name: icon, color: "#eeeeee", size: "32")
            Text(String(count))
                .font(.system(size: 12))
                .foregroundStyle(Color.white)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    /// 上游顶部：左菜单、中间 tabs、右搜索。
    private var header: some View {
        HStack {
            if let menuSlot {
                menuSlot
            } else {
                UPIcon(name: "uicon-grid", color: "#ffffff", size: "24")
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                ForEach(Array(tabsList.enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .font(.system(size: 15, weight: index == currentTab ? .regular : .light))
                        .foregroundStyle(index == currentTab
                                         ? UPColor.parse("#dddddd")
                                         : UPColor.parse("#bbbbbb"))
                        .contentShape(Rectangle())
                        .onTapGesture { selectTab(index) }
                }
            }

            Spacer(minLength: 0)

            if let searchSlot {
                searchSlot
            } else {
                UPIcon(name: "uicon-search", color: "#ffffff", size: "24")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    /// 上游底部：细进度条 + tabbar。
    private var footer: some View {
        VStack(spacing: 0) {
            Slider(value: Binding(get: { currentItem?.progress ?? 0 },
                                  set: { progressChanging($0) }),
                   in: 0...100,
                   step: 1) { editing in
                if !editing { progressChange(currentItem?.progress ?? 0) }
            }
            .tint(Color.white.opacity(0.32))
            .padding(.horizontal, 12)

            if let tabbarSlot { tabbarSlot }
        }
    }
}

/// `.page` 分页样式只在 iOS 可用，macOS 下退化成默认样式。
private struct UPShortVideoPagingStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        content
        #endif
    }
}
