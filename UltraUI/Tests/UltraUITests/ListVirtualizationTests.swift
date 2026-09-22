import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ListVirtualizationTests: XCTestCase {
    func testListEmitsLoadAndScrollToLower() {
        var events: [String] = []
        let list = UPList(items: ["a", "b"], loadmore: true)
            .onLoad { events.append("load") }
            .onScrolltolower { events.append("lower") }
        list.load()
        list.reachBottom()
        XCTAssertEqual(events, ["load", "lower"])
        XCTAssertEqual(list.items, ["a", "b"])
    }

    /// `list.js`：`showScrollbar: false`、`lowerThreshold: 50`、`upperThreshold: 0`、
    /// `scrollTop: 0`、`offsetAccuracy: 10`、`enableFlex: false`、
    /// `pagingEnabled: false`、`scrollable: true`、`scrollIntoView: ''`、
    /// `scrollWithAnimation: false`、`enableBackToTop: false`、`height: 0`、
    /// `width: 0`、`preLoadScreen: 1`；5 个 `refresher*` 的默认值写在 `props.js`。
    func testListPropDefaultsMatchUpstream() {
        let list = UPList(items: [String]())
        XCTAssertFalse(list.showScrollbar)
        XCTAssertEqual(list.lowerThreshold, 50)
        XCTAssertEqual(list.upperThreshold, 0)
        XCTAssertEqual(list.scrollTop, 0)
        XCTAssertEqual(list.offsetAccuracy, 10)
        XCTAssertFalse(list.enableFlex)
        XCTAssertFalse(list.pagingEnabled)
        XCTAssertTrue(list.scrollable)
        XCTAssertEqual(list.scrollIntoView, "")
        XCTAssertFalse(list.scrollWithAnimation)
        XCTAssertFalse(list.enableBackToTop)
        XCTAssertEqual(list.height, 0)
        XCTAssertEqual(list.width, 0)
        XCTAssertEqual(list.preLoadScreen, 1)
        XCTAssertFalse(list.refresherEnabled)
        XCTAssertEqual(list.refresherThreshold, 45)
        XCTAssertEqual(list.refresherDefaultStyle, "black")
        XCTAssertEqual(list.refresherBackground, "#FFF")
        XCTAssertFalse(list.refresherTriggered)
        // 上游 `listStyle` 只在非 0 时写入尺寸。
        XCTAssertNil(list.resolvedWidth)
        XCTAssertNil(list.resolvedHeight)
    }

    /// 尺寸类 prop 都是 `String | Number`，走 `UPUnit` 解析。
    func testListAcceptsStringUnitProps() {
        let list = UPList(items: [String](),
                          lowerThreshold: "80",
                          upperThreshold: "20",
                          height: "360",
                          width: "300",
                          preLoadScreen: "1.5")
        XCTAssertEqual(list.lowerThreshold, 80)
        XCTAssertEqual(list.upperThreshold, 20)
        XCTAssertEqual(list.resolvedHeight, 360)
        XCTAssertEqual(list.resolvedWidth, 300)
        XCTAssertEqual(list.preLoadScreen, 1.5)
    }

    /// 上游 `onScroll` 记录 `innerScrollTop` 并转发 `scroll`，跨过阈值时
    /// 触发 `scrolltolower` / `scrolltoupper`。
    func testListScrollEmitsThresholdEventsOnce() {
        var offsets: [CGFloat] = []
        var lower = 0
        var upper = 0
        let list = UPList(items: Array(0..<50), lowerThreshold: 50, upperThreshold: 10)
            .onScroll { offsets.append($0) }
            .onScrolltolower { lower += 1 }
            .onScrolltoupper { upper += 1 }

        // 内容 1000pt、视口 400pt：可滚动区间 0…600。
        list.handleScroll(scrollTop: 100, contentHeight: 1_000, viewportHeight: 400)
        XCTAssertEqual(list.currentScrollTop, 100)
        XCTAssertEqual(list.distanceToBottom, 500)
        XCTAssertEqual(lower, 0)

        list.handleScroll(scrollTop: 580, contentHeight: 1_000, viewportHeight: 400)
        XCTAssertEqual(lower, 1)
        // 已经在阈值内，不重复抛。
        list.handleScroll(scrollTop: 600, contentHeight: 1_000, viewportHeight: 400)
        XCTAssertEqual(lower, 1)

        list.handleScroll(scrollTop: 5, contentHeight: 1_000, viewportHeight: 400)
        XCTAssertEqual(upper, 1)
        XCTAssertEqual(offsets, [100, 580, 600, 5])
    }

    /// `scrollable` 为假时上游的 `scroll-y` 关闭，滚动事件不会产生。
    func testListScrollEventsHonourScrollable() {
        var events = 0
        let list = UPList(items: Array(0..<10), scrollable: false)
            .onScrolltolower { events += 1 }
            .onScrolltoupper { events += 1 }
        list.reachBottom()
        list.reachTop()
        XCTAssertEqual(events, 0)
    }

    /// 原生扩展的加载更多守卫：`loadmore` 为真且已结束或正在加载时不再抛事件。
    func testListLoadmoreGuardStopsRepeatedRequests() {
        var events = 0
        UPList(items: Array(0..<10), loadmore: true, finished: true)
            .onScrolltolower { events += 1 }
            .reachBottom()
        UPList(items: Array(0..<10), loadmore: true, loading: true)
            .onScrolltolower { events += 1 }
            .reachBottom()
        XCTAssertEqual(events, 0)
        // 未开启 loadmore 时保持上游语义，不拦截。
        UPList(items: Array(0..<10), finished: true)
            .onScrolltolower { events += 1 }
            .reachBottom()
        XCTAssertEqual(events, 1)
    }

    /// 四个 `refresher*` 事件合并成带阶段的回调，`refresherEnabled` 为假时静默。
    func testListRefresherEventsRequireEnabledFlag() {
        var phases: [UPListRefreshPhase] = []
        let list = UPList(items: [String](), refresherEnabled: true)
            .onRefresher { phases.append($0) }
        list.emitRefresher(.pulling)
        list.emitRefresher(.refresh)
        list.emitRefresher(.restore)
        list.emitRefresher(.abort)
        XCTAssertEqual(phases, [.pulling, .refresh, .restore, .abort])

        var disabled: [UPListRefreshPhase] = []
        UPList(items: [String]()).onRefresher { disabled.append($0) }.emitRefresher(.refresh)
        XCTAssertTrue(disabled.isEmpty)
    }

    /// `u-list-item` 只有 `anchor`（`String | Number`），落成 SwiftUI 的 `.id(_:)`。
    func testListItemAnchorAcceptsStringAndNumber() {
        XCTAssertEqual(UPListItem().anchor, "")
        XCTAssertEqual(UPListItem(anchor: "top").anchor, "top")
        XCTAssertEqual(UPListItem(anchor: 3).anchor, "3")
    }

    /// 上游 `getVisibleRange()`：`startIndex = floor(scrollTop / itemHeight)`，
    /// 起点再往前退 `buffer / 2`，长度是 `remain + buffer`。
    /// 这里 offset 200 → startIndex 10，buffer 2 → start 9，
    /// remain = ceil(100 / 20) = 5，visibleCount = 7，end = 16，故区间 9…15。
    func testVirtualListCalculatesClampedVisibleRangeAndSpacer() {
        let list = UPVirtualList(items: Array(0..<100), itemHeight: 20, viewportHeight: 100, overscan: 2)
        XCTAssertEqual(list.remain, 5)
        XCTAssertEqual(list.visibleCount, 7)
        XCTAssertEqual(list.visibleRange(offset: 200), 9...15)
        XCTAssertEqual(list.topSpacer(offset: 200), 180)
        XCTAssertEqual(list.bottomSpacer(offset: 200), 1_680)
    }

    /// `u-virtual-list.vue` 的内联 props：`itemHeight: 50`、`height: '100%'`、
    /// `buffer: 4`、`keyField: 'id'`、`scrollTop: 0`。
    func testVirtualListPropDefaultsMatchUpstream() {
        let list = UPVirtualList(listData: Array(0..<10))
        XCTAssertEqual(list.itemHeight, 50)
        XCTAssertEqual(list.height, "100%")
        XCTAssertEqual(list.buffer, 4)
        XCTAssertEqual(list.keyField, "id")
        XCTAssertEqual(list.startIndex, 0)
        // `100%` 量不到容器时上游兜底 500。
        XCTAssertEqual(list.viewportHeight, 500)
        XCTAssertEqual(list.remain, 10)
        XCTAssertEqual(list.visibleCount, 14)
        XCTAssertEqual(UPVirtualList(listData: Array(0..<10), height: "300").viewportHeight, 300)
    }

    /// 对应上游 `handleScroll`：写回 `update:scrollTop` 并抛 `scroll`。
    func testVirtualListScrollWritesBackAndEmits() {
        var offset: CGFloat = 0
        var reported: [CGFloat] = []
        let list = UPVirtualList(listData: Array(0..<100),
                                 itemHeight: 20,
                                 height: "100",
                                 scrollTop: Binding(get: { offset }, set: { offset = $0 }))
            .onScroll { reported.append($0) }
        list.handleScroll(scrollTop: 200)
        XCTAssertEqual(offset, 200)
        XCTAssertEqual(reported, [200])
        XCTAssertEqual(list.startIndex, 10)
    }

    /// 上游 `getItemKey(item)` 取 `keyField`，取不到用下标。
    func testVirtualListItemKeyFallsBackToIndex() {
        let plain = UPVirtualList(listData: ["a", "b"])
        XCTAssertEqual(plain.itemKey("a", index: 3), "3")

        let keyed = UPVirtualList(listData: ["a", "b"], key: { "k-\($0)" })
        XCTAssertEqual(keyed.itemKey("a", index: 0), "k-a")
    }

    /// `u-refresh-virtual-list.vue` 就是 `u-pull-refresh` 包 `u-virtual-list`：
    /// 5 个列表 prop 透传，`threshold` 在模板里写死 50。
    func testRefreshVirtualListForwardsListProps() {
        let list = UPRefreshVirtualList(listData: Array(0..<20)) { item, index in
            Text("\(index)-\(item)")
        }
        XCTAssertEqual(list.itemHeight, 50)
        XCTAssertEqual(list.height, "100%")
        XCTAssertEqual(list.buffer, 4)
        XCTAssertEqual(list.keyField, "id")
        XCTAssertEqual(list.refresherThreshold, 50)
        XCTAssertEqual(UPRefreshVirtualList<Int, EmptyView>.threshold, 50)
        XCTAssertFalse(list.refreshing)
        XCTAssertEqual(list.scrollTop, 0)
    }

    /// 上游 `handleRefresh` / `finishRefresh` / `handleScroll` / `scrollTo`。
    func testRefreshVirtualListRefreshAndScrollMethods() {
        var refreshed = 0
        var offsets: [CGFloat] = []
        var refreshing = false
        let list = UPRefreshVirtualList(listData: Array(0..<20),
                                        refreshing: Binding(get: { refreshing },
                                                            set: { refreshing = $0 })) { item, _ in
            Text("\(item)")
        }
            .onRefresh { refreshed += 1 }
            .onScroll { offsets.append($0) }

        list.beginRefresh()
        XCTAssertTrue(refreshing)
        XCTAssertEqual(refreshed, 1)
        // 上游同一次刷新期间不重复触发。
        list.beginRefresh()
        XCTAssertEqual(refreshed, 1)
        list.finishRefresh()
        XCTAssertFalse(refreshing)

        list.handleScroll(120)
        XCTAssertEqual(list.scrollTop, 120)
        XCTAssertEqual(offsets, [120])
        list.scrollToTop()
        XCTAssertEqual(list.scrollTop, 0)
        list.scrollTo(-10)
        XCTAssertEqual(list.scrollTop, 0)
    }

    func testRefreshVirtualListTracksRefreshLifecycleAndLazyLoadThreshold() {
        var refreshed = 0
        let refresh = UPRefreshVirtualList(refreshing: false).onRefresh { refreshed += 1 }
        refresh.beginRefresh()
        XCTAssertTrue(refresh.refreshing)
        refresh.endRefresh()
        XCTAssertFalse(refresh.refreshing)
        XCTAssertEqual(refreshed, 1)

        var loaded = 0
        let lazy = UPLazyLoad(threshold: 10).onLoad { loaded += 1 }
        lazy.appear(distanceToBottom: 5)
        XCTAssertEqual(loaded, 1)
    }

    func testLazyLoadPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.lazyLoad.image, "")
        XCTAssertEqual(UPConfig.lazyLoad.imgMode, "widthFix")
        XCTAssertEqual(UPConfig.lazyLoad.threshold, 100)
        XCTAssertEqual(UPConfig.lazyLoad.duration, 500)
        XCTAssertEqual(UPConfig.lazyLoad.effect, "ease-in-out")
        XCTAssertTrue(UPConfig.lazyLoad.isEffect)
        XCTAssertEqual(UPConfig.lazyLoad.borderRadius, 0)
        XCTAssertEqual(UPConfig.lazyLoad.height, "200")

        let lazy = UPLazyLoad(image: "https://example.com/a.png")
        XCTAssertEqual(lazy.index, "")
        XCTAssertEqual(lazy.imgMode, "widthFix")
        XCTAssertEqual(lazy.threshold, UPUnit.rpx(CGFloat(100)))
        XCTAssertEqual(lazy.duration, 500)
        XCTAssertEqual(lazy.effect, "ease-in-out")
        XCTAssertTrue(lazy.isEffect)
        XCTAssertEqual(lazy.borderRadius, 0)
        XCTAssertEqual(lazy.height, "200")
        XCTAssertEqual(lazy.imgHeight, "200px")
    }

    func testLazyLoadThresholdKeepsSignLikeUpstream() {
        typealias Lazy = UPLazyLoad<EmptyView, EmptyView>
        // 上游 getThreshold：先 rpx2px(abs(threshold))，再按原符号还原。
        XCTAssertEqual(Lazy.resolveThreshold("100"), UPUnit.rpx(CGFloat(100)))
        XCTAssertEqual(Lazy.resolveThreshold("-450"), -UPUnit.rpx(CGFloat(450)))
        XCTAssertEqual(Lazy.resolveThreshold("0"), 0)
    }

    func testLazyLoadAddUnitMatchesUpstream() {
        typealias Lazy = UPLazyLoad<EmptyView, EmptyView>
        // 上游 addUnit：能当数值解析的补 px，auto 与带 % 的原样返回。
        XCTAssertEqual(Lazy.addUnit("200"), "200px")
        XCTAssertEqual(Lazy.addUnit("auto"), "auto")
        XCTAssertEqual(Lazy.addUnit("50%"), "50%")
    }

    func testLazyLoadStatusAdvancesInTwoStepsLikeUpstream() {
        var loads: [String] = []
        let lazy = UPLazyLoad(image: "https://example.com/a.png",
                              index: 3,
                              loadingImg: "https://example.com/loading.png")
            .onLoad { loads.append($0) }
        XCTAssertEqual(lazy.index, "3")
        XCTAssertEqual(lazy.loadStatus, .lazy)

        // 占位图那次只推进状态，不抛 load。
        lazy.imgLoaded()
        XCTAssertEqual(lazy.loadStatus, .lazyed)
        XCTAssertTrue(loads.isEmpty)

        // 真图那次才抛 load，负载是 index。
        lazy.imgLoaded()
        XCTAssertEqual(lazy.loadStatus, .loaded)
        XCTAssertEqual(loads, ["3"])

        // 上游 loaded 之后不再推进。
        lazy.imgLoaded()
        XCTAssertEqual(loads, ["3"])
    }

    func testLazyLoadSwapsSourceAndReportsClickedImage() {
        var clicks: [String] = []
        var errors: [String] = []
        let lazy = UPLazyLoad(image: "real.png",
                              index: "7",
                              loadingImg: "loading.png",
                              errorImg: "error.png")
            .onClick { clicks.append($0) }
            .onError { errors.append($0) }

        XCTAssertEqual(lazy.currentSource, "loading.png")
        XCTAssertEqual(lazy.clickedImage, .lazyImg)
        lazy.clickImg()
        XCTAssertEqual(clicks, ["7"])

        lazy.appear(distanceToBottom: 0)
        XCTAssertTrue(lazy.isShow)
        XCTAssertEqual(lazy.currentSource, "real.png")
        XCTAssertEqual(lazy.clickedImage, .realImg)

        lazy.loadError()
        XCTAssertEqual(lazy.currentSource, "error.png")
        XCTAssertEqual(lazy.clickedImage, .errorImg)
        lazy.errorImgLoaded()
        XCTAssertEqual(errors, ["7"])

        lazy.reset()
        XCTAssertFalse(lazy.isError)
        XCTAssertFalse(lazy.isShow)
    }

    func testLazyLoadEmptyImageStartsInErrorState() {
        // 上游 watch.image：传入空值直接标记为错误状态。
        let lazy = UPLazyLoad(image: "", errorImg: "error.png")
        XCTAssertTrue(lazy.isError)
        XCTAssertEqual(lazy.currentSource, "error.png")
    }

    func testLazyLoadEffectMapsToAnimationCurves() {
        typealias Lazy = UPLazyLoad<EmptyView, EmptyView>
        XCTAssertNotNil(Lazy.animation(effect: "linear", duration: 500))
        XCTAssertNotNil(Lazy.animation(effect: "ease-in-out", duration: 500))
        // 上游 time 会被归零一瞬间，此时没有动画。
        XCTAssertNil(Lazy.animation(effect: "ease-in-out", duration: 0))

        let disabled = UPLazyLoad(image: "a.png", isEffect: false)
        XCTAssertFalse(disabled.isEffect)
        XCTAssertEqual(disabled.opacity, 1)
    }
}
@MainActor
final class WaterfallTests: XCTestCase {
    func testWaterfallAssignsItemsToShortestColumnDeterministically() {
        let waterfall = UPWaterfall(columnCount: 2, columnGap: 8)
        XCTAssertEqual(waterfall.columnAssignments(heights: [100, 80, 60, 40]), [0, 1, 1, 0])
        XCTAssertEqual(waterfall.columnHeights(heights: [100, 80, 60, 40]), [148, 148])
    }

    func testWaterfallPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.waterfall.addTime, 200)
        XCTAssertEqual(UPConfig.waterfall.idKey, "id")
        XCTAssertEqual(UPConfig.waterfall.columns, "2")
        XCTAssertEqual(UPConfig.waterfall.columnsMin, 2)
        XCTAssertEqual(UPConfig.waterfall.minColumnWidth, 230)

        let items = StringArrayBox([])
        let waterfall = UPWaterfall<String, EmptyView>(modelValue: items.binding)
        XCTAssertEqual(waterfall.addTime, 200)
        XCTAssertEqual(waterfall.idKey, "id")
        XCTAssertEqual(waterfall.columns, "2")
        XCTAssertEqual(waterfall.columnsMin, 2)
        XCTAssertEqual(waterfall.minColumnWidth, 230)
        XCTAssertEqual(waterfall.columnCount, 2)
        XCTAssertEqual(waterfall.columnGap, UPUnit.rpx(CGFloat(10)))
    }

    func testWaterfallParsesColumnsLikeUpstreamParseInt() {
        typealias Waterfall = UPWaterfall<String, EmptyView>
        XCTAssertEqual(Waterfall.parseColumns("3"), 3)
        XCTAssertEqual(Waterfall.parseColumns("4abc"), 4)
        // 上游 `parseInt(columns) || 2`：解析不出数字或解析出 0 都退回 2。
        XCTAssertEqual(Waterfall.parseColumns("abc"), 2)
        XCTAssertEqual(Waterfall.parseColumns("0"), 2)
    }

    func testWaterfallAutoColumnsFollowWindowWidthAndMinimum() {
        typealias Waterfall = UPWaterfall<String, EmptyView>
        // 上游：floor(windowWidth / (minColumnWidth + 7))，再抬到 columnsMin。
        XCTAssertEqual(Waterfall.autoColumnCount(windowWidth: 1200, minColumnWidth: 230, columnsMin: 2), 5)
        XCTAssertEqual(Waterfall.autoColumnCount(windowWidth: 375, minColumnWidth: 230, columnsMin: 2), 2)
        XCTAssertEqual(Waterfall.autoColumnCount(windowWidth: 1000, minColumnWidth: 230, columnsMin: 6), 6)

        let items = StringArrayBox([])
        let auto = UPWaterfall<String, EmptyView>(modelValue: items.binding, columns: "auto")
        XCTAssertEqual(auto.columns, "auto")
        XCTAssertEqual(auto.columnCount, 2)
    }

    func testWaterfallDetectsPureAppendLikeUpstream() {
        typealias Waterfall = UPWaterfall<String, EmptyView>
        XCTAssertTrue(Waterfall.isPureAppend(oldSignature: [], newSignature: ["a"]))
        XCTAssertTrue(Waterfall.isPureAppend(oldSignature: ["a"], newSignature: ["a", "b"]))
        XCTAssertFalse(Waterfall.isPureAppend(oldSignature: ["a", "b"], newSignature: ["a"]))
        XCTAssertFalse(Waterfall.isPureAppend(oldSignature: ["a", "b"], newSignature: ["b", "a"]))
    }

    func testWaterfallMinHeightColumnBreaksTiesByCount() {
        typealias Waterfall = UPWaterfall<String, EmptyView>
        XCTAssertEqual(Waterfall.minHeightColumnIndex(columnHeights: [120, 80], columnCounts: [2, 1]), 1)
        // 高度相同时按列数据量打散，避免全部落到第一列。
        XCTAssertEqual(Waterfall.minHeightColumnIndex(columnHeights: [0, 0, 0], columnCounts: [1, 0, 0]), 1)
        XCTAssertEqual(Waterfall.minHeightColumnIndex(columnHeights: [0, 0], columnCounts: [1, 1]), 0)
        XCTAssertEqual(Waterfall.minHeightColumnIndex(columnHeights: [50], columnCounts: [3]), 0)
    }

    func testWaterfallClearRemoveAndModifyWriteBackToModelValue() {
        let items = StringArrayBox(["a", "b", "c"])
        let waterfall = UPWaterfall<String, EmptyView>(modelValue: items.binding, key: { $0 })
        XCTAssertEqual(waterfall.itemKey("a"), "a")

        waterfall.remove("b")
        XCTAssertEqual(items.value, ["a", "c"])

        waterfall.clear(bak: false)
        XCTAssertEqual(items.value, ["a", "c"])

        waterfall.clear()
        XCTAssertEqual(items.value, [String]())
    }

    func testWaterfallExposesColumnAndLeftSlots() {
        let items = StringArrayBox([])
        let plain = UPWaterfall(modelValue: items.binding, content: { Text($0) })
        XCTAssertFalse(plain.hasColumnSlot)
        XCTAssertFalse(plain.hasLeftSlot)

        let slotted = plain
            .column { index, list in Text("\(index)-\(list.count)") }
            .left { index, list in Text("\(index)/\(list.count)") }
        XCTAssertTrue(slotted.hasColumnSlot)
        XCTAssertTrue(slotted.hasLeftSlot)
    }
}

@MainActor
final class IndexListTests: XCTestCase {
    func testIndexListSelectsAnchorAndEmitsActiveIndex() {
        var selected = ""
        let list = UPIndexList(indexList: ["A", "B", "C"]).onChange { selected = $0 }
        list.select("B")
        XCTAssertEqual(list.activeIndex, "B")
        XCTAssertEqual(selected, "B")
        XCTAssertEqual(list.index(of: "missing"), -1)
        XCTAssertEqual(UPIndexAnchor(index: "A").displayIndex, "A")
    }

    /// `u-index-list/indexList.js`: `inactiveColor: '#606266'`、`activeColor: '#5677fc'`、
    /// `indexList: []`、`sticky: true`、`customNavHeight: 0`、`safeBottomFix: false`、
    /// `itemMargin: '0rpx'`。
    func testIndexListPropsMatchUpstreamDefaults() {
        let list = UPIndexList()
        XCTAssertEqual(list.indexList, [])
        XCTAssertEqual(list.activeColor, "#5677fc")
        XCTAssertEqual(list.inactiveColor, "#606266")
        XCTAssertTrue(list.sticky)
        XCTAssertEqual(list.customNavHeight, 0)
        XCTAssertEqual(list.itemMargin, 0)
        XCTAssertFalse(list.safeBottomFix)
        XCTAssertEqual(UPConfig.indexList.activeColor, "#5677fc")
        XCTAssertEqual(UPConfig.indexList.inactiveColor, "#606266")
        XCTAssertEqual(UPConfig.indexList.itemMargin, "0rpx")
        XCTAssertTrue(UPConfig.indexList.indexList.isEmpty)
        XCTAssertEqual(UPIndexList(customNavHeight: "44px").customNavHeight, 44)
        XCTAssertEqual(UPIndexList(itemMargin: "20px").itemMargin, 20)
    }

    /// 上游 `uIndexList` 计算属性：`indexList` 为空时回落到内部生成的 A-Z 字母表。
    func testIndexListFallsBackToAlphabetWhenIndexListIsEmpty() {
        let alphabet = UPIndexList<EmptyView>.alphabetIndexList
        XCTAssertEqual(UPIndexList().anchors, alphabet)
        XCTAssertEqual(alphabet.count, 26)
        XCTAssertEqual(alphabet.first, "A")
        XCTAssertEqual(alphabet.last, "Z")
        XCTAssertEqual(UPIndexList(indexList: ["↑", "☆"]).anchors, ["↑", "☆"])
    }

    /// 上游 `resolvedActiveColor` / `resolvedInactiveColor` 把默认值当哨兵，
    /// 命中默认时改取主题变量 `--up-primary` / `--up-content-color`。
    func testIndexListResolvesThemeSentinelColorsLikeUpstream() {
        XCTAssertEqual(UPIndexList().resolvedActiveColor, "primary")
        XCTAssertEqual(UPIndexList().resolvedInactiveColor, "content")
        XCTAssertEqual(UPIndexList(activeColor: "#ff0000").resolvedActiveColor, "#ff0000")
        XCTAssertEqual(UPIndexList(inactiveColor: "#000000").resolvedInactiveColor, "#000000")
    }

    /// 照抄上游 `scrollHandler`：逐个累加 `item.height + getPx(itemMargin)` 得到锚点
    /// 偏移，滚动值再加上 `customNavHeight`；越界时高亮清空为 -1，历遍到最后一项时
    /// 直接取末位。
    func testIndexListScrollActiveIndexFollowsUpstreamHandler() {
        let list = UPIndexList(indexList: ["A", "B", "C"])
        XCTAssertEqual(list.scrollActiveIndex(scrollTop: 0, itemHeights: [100, 100, 100], headerHeight: 50), -1)
        XCTAssertEqual(list.scrollActiveIndex(scrollTop: 200, itemHeights: [100, 100, 100], headerHeight: 50), 1)
        XCTAssertEqual(list.scrollActiveIndex(scrollTop: 400, itemHeights: [100, 100, 100], headerHeight: 50), -1)

        let navList = UPIndexList(indexList: ["A", "B", "C"], customNavHeight: 100)
        XCTAssertEqual(navList.scrollActiveIndex(scrollTop: 100, itemHeights: [100, 100, 100], headerHeight: 50), 1)

        let marginList = UPIndexList(indexList: ["A", "B", "C"], itemMargin: "20px")
        XCTAssertEqual(marginList.scrollActiveIndex(scrollTop: 200, itemHeights: [100, 100, 100], headerHeight: 50), 1)
        XCTAssertEqual(marginList.scrollActiveIndex(scrollTop: 300, itemHeights: [100, 100, 100], headerHeight: 50), 2)

        XCTAssertEqual(list.scrollActiveIndex(scrollTop: 10, itemHeights: [], headerHeight: 0, current: 3), 3)
    }

    /// 照抄上游 `getIndexListLetter`：字母条每项 16px 高加上下各 1px 外边距，触点
    /// 超出两端时钳制到首尾字母。
    func testIndexListLetterTouchMapsOffsetToIndexLikeUpstream() {
        let list = UPIndexList(indexList: ["A", "B", "C"])
        XCTAssertEqual(UPIndexList<EmptyView>.letterItemHeight, 18)
        XCTAssertEqual(list.letterColumnHeight, 54)
        XCTAssertEqual(list.letterIndex(forOffsetY: -5), 0)
        XCTAssertEqual(list.letterIndex(forOffsetY: 20), 1)
        XCTAssertEqual(list.letterIndex(forOffsetY: 100), 2)
        XCTAssertEqual(UPIndexList().letterIndex(forOffsetY: 20), 1)
    }

    /// 上游 `safeBottomFix` 唯一使用处（`pageY = pageY + 34`）已被注释，故触点映射
    /// 不受其影响；原生改为在列表末尾补底部安全区留白。
    func testIndexListSafeBottomFixOnlyDrivesNativeBottomSpacer() {
        let fixed = UPIndexList(indexList: ["A", "B", "C"], safeBottomFix: true)
        XCTAssertTrue(fixed.showsSafeBottom)
        XCTAssertFalse(UPIndexList(indexList: ["A", "B", "C"]).showsSafeBottom)
        XCTAssertEqual(fixed.letterIndex(forOffsetY: 20), 1)
    }

    /// `libs/config/props/indexAnchor.js`: `text: ''`、`color: '#606266'`、
    /// `size: 14`、`bgColor: '#f1f1f1'`、`height: 32`。
    func testIndexAnchorStyleDefaultsMatchUpstreamProps() {
        let anchor = UPIndexAnchor(index: "A")
        XCTAssertEqual(anchor.text, "")
        XCTAssertEqual(anchor.color, "#606266")
        XCTAssertEqual(anchor.size, 14)
        XCTAssertEqual(anchor.bgColor, "#f1f1f1")
        XCTAssertEqual(anchor.height, 32)
        XCTAssertEqual(UPConfig.indexAnchor.color, "#606266")
        XCTAssertEqual(UPConfig.indexAnchor.bgColor, "#f1f1f1")
    }

    /// 上游模板渲染 `{{ text.name || text }}`，所以显式 `text` 优先于锚点标识；
    /// `text` 为空串时回落到 `index`，保持既有行为。
    func testIndexAnchorPrefersExplicitTextOverIndex() {
        XCTAssertEqual(UPIndexAnchor(index: "A", text: "热门").displayIndex, "热门")
        XCTAssertEqual(UPIndexAnchor(index: "A", text: "").displayIndex, "A")
    }

    /// `size` / `height` 走 `addUnit`，所以字符串带单位与裸数值等价。
    func testIndexAnchorParsesSizeAndHeightUnits() {
        let anchor = UPIndexAnchor(index: "A", size: "16px", height: "40")
        XCTAssertEqual(anchor.size, 16)
        XCTAssertEqual(anchor.height, 40)
    }
}
