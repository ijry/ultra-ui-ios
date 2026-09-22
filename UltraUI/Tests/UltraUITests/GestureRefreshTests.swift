import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class GestureRefreshTests: XCTestCase {
    /// 上游 `initialList` 是组件自己持有的 `data.list`，换序后 `list` 就地更新，
    /// 再把排好序的整个列表通过 `drag-end` 抛出。
    func testDragsortMovesItemsAndEmitsOrder() {
        var emitted: [String] = []
        var dragEnded: [String] = []
        let sort = UPDragsort(items: ["A", "B", "C"])
            .onChange { emitted = $0 }
            .onDragEnd { dragEnded = $0 }
        XCTAssertEqual(sort.move(from: 0, to: 2), ["B", "C", "A"])
        XCTAssertEqual(sort.items, ["B", "C", "A"])
        XCTAssertEqual(emitted, ["B", "C", "A"])
        XCTAssertEqual(dragEnded, ["B", "C", "A"])
    }

    /// `u-dragsort.vue` 的内联 props：`draggable: true`、`vibrate: true`、
    /// `direction: 'vertical'`、`columns: 3`；`direction` 有 validator。
    func testDragsortPropDefaultsMatchUpstream() {
        let sort = UPDragsort(initialList: ["A"]) { item, _ in Text(item) }
        XCTAssertTrue(sort.draggable)
        XCTAssertTrue(sort.vibrate)
        XCTAssertEqual(sort.direction, "vertical")
        XCTAssertEqual(sort.columns, 3)
        XCTAssertFalse(sort.disabled)
        XCTAssertNil(sort.draggingIndex)
        XCTAssertFalse(sort.hasHandlerSlot)
        // validator 之外的值回落默认。
        XCTAssertEqual(UPDragsort(initialList: ["A"], direction: "diagonal") { item, _ in Text(item) }.direction,
                       "vertical")
        XCTAssertEqual(UPDragsort(initialList: ["A"], columns: 0) { item, _ in Text(item) }.columns, 1)
    }

    /// 上游 `!draggable || item.draggable === false` 两级禁用。
    func testDragsortHonoursGlobalAndPerItemDraggable() {
        let global = UPDragsort(initialList: ["A", "B"], draggable: false) { item, _ in Text(item) }
        XCTAssertFalse(global.isDraggable("A"))
        global.begin(at: 0)
        XCTAssertNil(global.draggingIndex)
        XCTAssertEqual(global.move(from: 0, to: 1), ["A", "B"])

        let perItem = UPDragsort(initialList: ["A", "B"],
                                 vibrate: false,
                                 itemDraggable: { $0 != "B" }) { item, _ in Text(item) }
        XCTAssertTrue(perItem.isDraggable("A"))
        XCTAssertFalse(perItem.isDraggable("B"))
        perItem.begin(at: 1)
        XCTAssertNil(perItem.draggingIndex)
        perItem.begin(at: 0)
        XCTAssertEqual(perItem.draggingIndex, 0)
        perItem.end()
        XCTAssertNil(perItem.draggingIndex)
    }

    func testPullRefreshTracksThresholdAndLifecycle() {
        var calls = 0
        let refresh = UPPullRefresh(refreshing: false, threshold: 50).onRefresh { calls += 1 }
        XCTAssertFalse(refresh.pull(distance: 20))
        XCTAssertTrue(refresh.pull(distance: 60))
        XCTAssertTrue(refresh.refreshing)
        refresh.endRefresh()
        XCTAssertFalse(refresh.refreshing)
        XCTAssertEqual(calls, 1)
    }

    /// 上游 props 内联在 `.vue` 里：`refreshing: false`、`threshold: 80`、`damping: 0.4`、
    /// `maxDistance: 120`、`showLoadmore: false`、`loadmoreProps: { status: 'loadmore' }`、
    /// `useScrollView: true`、`enableBackToTop: false`、`lowerThreshold: 50`、`scrollTop: 0`。
    func testPullRefreshPropDefaultsMatchUpstream() {
        XCTAssertFalse(UPConfig.pullRefresh.refreshing)
        XCTAssertEqual(UPConfig.pullRefresh.threshold, 80)
        XCTAssertEqual(UPConfig.pullRefresh.damping, 0.4)
        XCTAssertEqual(UPConfig.pullRefresh.maxDistance, 120)
        XCTAssertFalse(UPConfig.pullRefresh.showLoadmore)
        XCTAssertTrue(UPConfig.pullRefresh.useScrollView)
        XCTAssertFalse(UPConfig.pullRefresh.enableBackToTop)
        XCTAssertEqual(UPConfig.pullRefresh.lowerThreshold, 50)
        XCTAssertEqual(UPConfig.pullRefresh.scrollTop, 0)
        XCTAssertEqual(UPConfig.pullRefresh.loadmoreStatus, "loadmore")
        // i18n/locales/zh-Hans.js 的 up.pullRefresh.* 三段文案。
        XCTAssertEqual(UPConfig.pullRefresh.pullText, "下拉刷新")
        XCTAssertEqual(UPConfig.pullRefresh.releaseText, "释放刷新")
        XCTAssertEqual(UPConfig.pullRefresh.refreshingText, "正在刷新")

        let box = PullRefreshBoolBox(false)
        let refresh = UPPullRefresh<EmptyView>(refreshing: box.binding)
        XCTAssertEqual(refresh.threshold, 80)
        XCTAssertEqual(refresh.damping, 0.4)
        XCTAssertEqual(refresh.maxDistance, 120)
        XCTAssertFalse(refresh.showLoadmore)
        XCTAssertTrue(refresh.useScrollView)
        XCTAssertFalse(refresh.enableBackToTop)
        XCTAssertEqual(refresh.lowerThreshold, 50)
        XCTAssertEqual(refresh.scrollTop, 0)
        XCTAssertEqual(refresh.loadmoreProps.status, "loadmore")
        XCTAssertEqual(refresh.refreshStatus, .pull)
    }

    /// 上游 `onTouchMove`：`min(diff * damping, maxDistance)`，越过 `threshold` 切 release。
    func testPullRefreshAppliesDampingAndMaxDistance() {
        let box = PullRefreshBoolBox(false)
        let refresh = UPPullRefresh<EmptyView>(refreshing: box.binding,
                                               threshold: 80,
                                               damping: 0.5,
                                               maxDistance: 120)

        refresh.onTouchStart(pageY: 100)
        refresh.onTouchMove(pageY: 200)
        XCTAssertEqual(refresh.refreshDistance, 50)
        XCTAssertEqual(refresh.contentTranslateY, 50)
        XCTAssertEqual(refresh.refreshStatus, .pull)

        refresh.onTouchMove(pageY: 300)
        XCTAssertEqual(refresh.refreshDistance, 100)
        XCTAssertEqual(refresh.refreshStatus, .release)

        // 夹到 maxDistance。
        refresh.onTouchMove(pageY: 1000)
        XCTAssertEqual(refresh.refreshDistance, 120)

        // 上游只在 diff > 0 时更新，往上拖不动。
        refresh.onTouchMove(pageY: 50)
        XCTAssertEqual(refresh.refreshDistance, 120)
    }

    /// 上游 `onTouchEnd`：越过阈值触发 refresh 并把距离钉在 threshold，否则回弹到 0。
    func testPullRefreshTouchEndTriggersOrBounces() {
        let box = PullRefreshBoolBox(false)
        var refreshes = 0
        let refresh = UPPullRefresh<EmptyView>(refreshing: box.binding, threshold: 80, damping: 1)
            .onRefresh { refreshes += 1 }

        refresh.onTouchStart(pageY: 0)
        refresh.onTouchMove(pageY: 40)
        refresh.onTouchEnd()
        XCTAssertEqual(refreshes, 0)
        XCTAssertEqual(refresh.refreshDistance, 0)
        XCTAssertFalse(box.value)

        refresh.onTouchStart(pageY: 0)
        refresh.onTouchMove(pageY: 100)
        refresh.onTouchEnd()
        XCTAssertEqual(refreshes, 1)
        XCTAssertTrue(box.value)
        XCTAssertEqual(refresh.refreshStatus, .refreshing)
        XCTAssertEqual(refresh.refreshDistance, 80)

        // 刷新中不再响应新的手势。
        refresh.onTouchStart(pageY: 0)
        refresh.onTouchMove(pageY: 200)
        XCTAssertEqual(refresh.refreshDistance, 80)

        refresh.finishRefresh()
        XCTAssertFalse(box.value)
        XCTAssertEqual(refresh.refreshStatus, .pull)
        XCTAssertEqual(refresh.contentTranslateY, 0)
    }

    /// 上游 `handleScrollToLower`：只有 showLoadmore 且状态是 loadmore 才抛。
    func testPullRefreshLoadmoreAndScrollEvents() {
        let box = PullRefreshBoolBox(false)
        var loadmores = 0
        var offsets: [CGFloat] = []

        let disabled = UPPullRefresh<EmptyView>(refreshing: box.binding)
            .onLoadmore { loadmores += 1 }
        disabled.handleScrollToLower()
        XCTAssertEqual(loadmores, 0)

        let loading = UPPullRefresh<EmptyView>(
            refreshing: box.binding,
            showLoadmore: true,
            loadmoreProps: UPPullRefreshLoadmoreProps(status: "loading")
        ).onLoadmore { loadmores += 1 }
        loading.handleScrollToLower()
        XCTAssertEqual(loadmores, 0)

        let ready = UPPullRefresh<EmptyView>(refreshing: box.binding, showLoadmore: true)
            .onLoadmore { loadmores += 1 }
            .onScroll { offsets.append($0) }
        ready.handleScrollToLower()
        XCTAssertEqual(loadmores, 1)

        ready.handleScroll(scrollTop: 120)
        XCTAssertEqual(offsets, [120])
    }

    func testPullRefreshExposesStatusSlots() {
        let box = PullRefreshBoolBox(false)
        let plain = UPPullRefresh<EmptyView>(refreshing: box.binding)
        XCTAssertFalse(plain.hasPullSlot)
        XCTAssertFalse(plain.hasReleaseSlot)
        XCTAssertFalse(plain.hasRefreshingSlot)

        let slotted = plain
            .pullContent { distance, threshold in Text("\(Int(distance))/\(Int(threshold))") }
            .releaseContent { _, _ in Text("release") }
            .refreshingContent { Text("refreshing") }
        XCTAssertTrue(slotted.hasPullSlot)
        XCTAssertTrue(slotted.hasReleaseSlot)
        XCTAssertTrue(slotted.hasRefreshingSlot)
    }
}

@MainActor
final class SwipeActionTests: XCTestCase {
    func testSwipeActionItemOpensAndInvokesAction() {
        var selected = ""
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "Delete")])
            .onAction { selected = $0.id }
        item.open()
        XCTAssertTrue(item.opened)
        item.trigger("delete")
        XCTAssertEqual(selected, "delete")
        item.close()
        XCTAssertFalse(item.opened)
    }

    func testSwipeActionTracksSingleOpenItem() {
        let action = UPSwipeAction(id: "archive", title: "Archive")
        let group = UPSwipeActionGroup().register("first").open("first")
        XCTAssertEqual(group.openedID, "first")
        XCTAssertEqual(action.title, "Archive")
        group.close()
        XCTAssertNil(group.openedID)
    }

    /// `libs/config/props/swipeActionItem.js` 的默认值是 `threshold: 20`
    /// （`u-swipe-action-item.vue` 注释里写的 30 是过期文档），`closeOnClick`
    /// 与 `autoClose` 默认 true，`show` / `disabled` 默认 false。
    func testSwipeActionItemDefaultsMatchUpstreamProps() {
        let item = UPSwipeActionItem(id: "row")
        XCTAssertEqual(item.threshold, 20)
        XCTAssertTrue(item.closeOnClick)
        XCTAssertFalse(item.disabled)
        XCTAssertFalse(item.opened)
    }

    /// 上游 `show` 是 v-model，初始为真时单元格直接处于展开态；`disabled` 会让
    /// 手势打开与按钮点击都失效（对应 watch 里的 `setScrolling(false)` 分支）。
    func testSwipeActionItemHonoursInitialShowAndDisabledState() {
        XCTAssertTrue(UPSwipeActionItem(id: "row", show: true).opened)

        var events: [String] = []
        let disabled = UPSwipeActionItem(
            id: "row",
            disabled: true,
            actions: [UPSwipeAction(id: "delete", title: "删除")]
        )
        .onOpen { events.append("open") }
        .onAction { events.append("action:\($0.id)") }
        disabled.open()
        XCTAssertFalse(disabled.opened)
        disabled.trigger("delete")
        XCTAssertEqual(events, [])
    }

    /// 上游 `buttonClickHandler` 先派发 click，再在 `closeOnClick` 为真时收起单元格。
    func testSwipeActionItemClosesAfterActionWhenCloseOnClickIsEnabled() {
        var log: [String] = []
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "删除")])
            .onAction { log.append("action:\($0.id)") }
            .onClose { log.append("close") }
        item.open()
        item.trigger("delete")
        XCTAssertFalse(item.opened)
        XCTAssertEqual(log, ["action:delete", "close"])

        let sticky = UPSwipeActionItem(
            id: "row",
            closeOnClick: false,
            actions: [UPSwipeAction(id: "delete", title: "删除")]
        )
        sticky.open()
        sticky.trigger("delete")
        XCTAssertTrue(sticky.opened)
    }

    /// `swipeAction.js` 只有 `autoClose`，`opendItem` 的默认值在 `props.js` 里被硬编码为
    /// `false`（不走 config）；`swipeActionItem.js` 给出子组件全部 9 个默认值。
    func testSwipeActionConfigMatchesUpstreamDefaults() {
        XCTAssertTrue(UPConfig.swipeAction.autoClose)
        XCTAssertFalse(UPConfig.swipeAction.opendItem)

        XCTAssertFalse(UPConfig.swipeActionItem.show)
        XCTAssertTrue(UPConfig.swipeActionItem.closeOnClick)
        XCTAssertEqual(UPConfig.swipeActionItem.name, "")
        XCTAssertFalse(UPConfig.swipeActionItem.disabled)
        XCTAssertEqual(UPConfig.swipeActionItem.threshold, 20)
        XCTAssertTrue(UPConfig.swipeActionItem.autoClose)
        XCTAssertFalse(UPConfig.swipeActionItem.scrolling)
        XCTAssertTrue(UPConfig.swipeActionItem.options.isEmpty)
        XCTAssertEqual(UPConfig.swipeActionItem.duration, 300)

        let item = UPSwipeActionItem(id: "row")
        XCTAssertEqual(item.name, "")
        XCTAssertTrue(item.autoClose)
        XCTAssertFalse(item.isScrolling)
        XCTAssertEqual(item.duration, "300")
        XCTAssertTrue(item.options.isEmpty)
    }

    /// 上游 `name` 是 `String | Number` 标识符，`options` 才是右侧按钮数组的官方
    /// prop 名（原生 `actions` 是同一份数据的别名）。
    func testSwipeActionItemAcceptsUpstreamNameAndOptionsProps() {
        let numbered = UPSwipeActionItem(id: "row", name: 3)
        XCTAssertEqual(numbered.name, 3)
        XCTAssertEqual(numbered.name.description, "3")

        let options = [UPSwipeAction(id: "delete", title: "删除")]
        let item = UPSwipeActionItem(id: "row", options: options)
        XCTAssertEqual(item.options, options)
        XCTAssertEqual(item.actions, options)
    }

    /// 上游 `getDuration` 以 30 为阈值推断单位：带 `ms` 取数值，带 `s` 乘 1000，
    /// 裸数字大于 30 视为毫秒、否则视为秒。
    func testSwipeActionItemResolvesDurationUnits() {
        XCTAssertEqual(UPSwipeActionItem(id: "row").resolvedDuration, 300)
        XCTAssertEqual(UPSwipeActionItem(id: "row", duration: "350ms").resolvedDuration, 350)
        XCTAssertEqual(UPSwipeActionItem(id: "row", duration: "0.3s").resolvedDuration, 300)
        XCTAssertEqual(UPSwipeActionItem(id: "row", duration: 300).resolvedDuration, 300)
        XCTAssertEqual(UPSwipeActionItem(id: "row", duration: 1).resolvedDuration, 1_000)
        XCTAssertEqual(UPSwipeActionItem(id: "row", duration: "").resolvedDuration, 300)
    }

    /// 上游 `setScrolling` 先对 `innerScrolling` 去重，再同时派发 `update:scrolling`
    /// 与 `scrolling`；`closeHandler` 收起前会把滑动状态复位，`disabled` 为真时
    /// watch 直接把滑动状态压成 false。
    func testSwipeActionItemDeduplicatesScrollingEvents() {
        var emitted: [Bool] = []
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "删除")])
            .onScrolling { emitted.append($0) }
        item.setScrolling(true)
        item.setScrolling(true)
        XCTAssertTrue(item.isScrolling)
        XCTAssertEqual(emitted, [true])

        item.open()
        item.close()
        XCTAssertFalse(item.isScrolling)
        XCTAssertEqual(emitted, [true, false])

        XCTAssertTrue(UPSwipeActionItem(id: "row", scrolling: true).isScrolling)
        XCTAssertFalse(UPSwipeActionItem(id: "row", disabled: true, scrolling: true).isScrolling)
    }

    /// 上游 `buttonClickHandler` 派发的 payload 是 `{ index, name }`。
    func testSwipeActionItemEmitsUpstreamClickPayload() {
        var events: [UPSwipeActionClickEvent] = []
        let item = UPSwipeActionItem(
            id: "row",
            name: "inbox",
            options: [
                UPSwipeAction(id: "favorite", title: "收藏"),
                UPSwipeAction(id: "delete", title: "删除")
            ]
        )
        .onClick { events.append($0) }
        item.open()
        item.trigger("delete")
        XCTAssertEqual(events, [UPSwipeActionClickEvent(index: 1, name: "inbox")])
    }

    /// 父组件 `closeOther` 只在 `autoClose` 为真时关闭其余单元格，`closeAll` 无条件
    /// 全部关闭；`opendItem` 被置为 false 时 watch 会调用 `closeAll`，而 `setOpendItem`
    /// 派发的是拼写反常的 `opendItem:update`（值恒为 true）。
    func testSwipeActionGroupHonoursAutoCloseAndOpendItem() {
        var updates: [Bool] = []
        let group = UPSwipeActionGroup(autoClose: false)
            .onOpendItemUpdate { updates.append($0) }
        group.register("first").register("second")
        group.open("first").open("second")
        XCTAssertEqual(group.openedIDs, ["first", "second"])
        group.closeOther("second")
        XCTAssertEqual(group.openedIDs, ["first", "second"])
        XCTAssertEqual(updates, [true, true])

        group.updateOpendItem(false)
        XCTAssertTrue(group.openedIDs.isEmpty)
        XCTAssertNil(group.openedID)
        XCTAssertFalse(group.opendItem)

        let exclusive = UPSwipeActionGroup()
        XCTAssertTrue(exclusive.autoClose)
        exclusive.register("first").register("second")
        exclusive.open("first").open("second")
        XCTAssertEqual(exclusive.openedIDs, ["second"])
        exclusive.closeOther("second")
        XCTAssertEqual(exclusive.openedIDs, ["second"])
        exclusive.close("second")
        XCTAssertTrue(exclusive.openedIDs.isEmpty)
    }

    /// 上游 `options` 的一项：`style.backgroundColor` / `color` / `fontSize` /
    /// `borderRadius` 四个键决定配色与形状，`iconSize` 优先于 `fontSize * 1.2`。
    func testSwipeActionResolvesUpstreamButtonStyle() {
        // 上游 defaultButtonBgColor 浅色回落 #C7C6CD，defaultButtonColor 回落白色。
        XCTAssertEqual(UPConfig.swipeActionItem.buttonBackgroundColor, "#c7c6cd")
        XCTAssertEqual(UPConfig.swipeActionItem.darkButtonBackgroundColor, "#4b5563")
        XCTAssertEqual(UPConfig.swipeActionItem.buttonColor, "#ffffff")
        XCTAssertEqual(UPConfig.swipeActionItem.buttonPadding, 15)
        XCTAssertEqual(UPConfig.swipeActionItem.buttonFontSize, 16)
        XCTAssertEqual(UPConfig.swipeActionItem.buttonIconSize, 17)

        let plain = UPSwipeAction(id: "a", title: "删除", color: "")
        XCTAssertEqual(plain.text, "删除")
        XCTAssertEqual(plain.resolvedBackgroundColor, "#c7c6cd")
        XCTAssertEqual(plain.resolvedTextColor, "#ffffff")
        XCTAssertEqual(plain.resolvedFontSize, 16)
        XCTAssertEqual(plain.resolvedCornerRadius, 0)
        XCTAssertFalse(plain.hasCornerRadius)
        // 没给 iconSize 也没给 fontSize 时兜底 17。
        XCTAssertEqual(plain.resolvedIconSize, 17)

        // 仓库既有的 color 字段落在 style.backgroundColor 的位置。
        XCTAssertEqual(UPSwipeAction(id: "a", title: "删除").resolvedBackgroundColor, "#f56c6c")

        let styled = UPSwipeAction(id: "b", title: "收藏", icon: "star", style: UPStyle([
            "backgroundColor": "#3c9cff",
            "color": "#000000",
            "fontSize": "20px",
            "borderRadius": "8px"
        ]))
        XCTAssertEqual(styled.resolvedBackgroundColor, "#3c9cff")
        XCTAssertEqual(styled.resolvedTextColor, "#000000")
        XCTAssertEqual(styled.resolvedFontSize, 20)
        XCTAssertEqual(styled.resolvedCornerRadius, 8)
        XCTAssertTrue(styled.hasCornerRadius)
        // 上游图标尺寸取 fontSize * 1.2。
        XCTAssertEqual(styled.resolvedIconSize, 24)

        // iconSize 优先于 fontSize * 1.2。
        let sized = UPSwipeAction(id: "c", title: "", icon: "star", iconSize: "30px",
                                  style: UPStyle(["fontSize": "20px"]))
        XCTAssertEqual(sized.resolvedIconSize, 30)
    }

    /// 上游 `touchmove`：横向位移小于纵向时判为页面滚动；位移夹在按钮总宽内。
    func testSwipeActionItemTouchMoveClampsOffset() {
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "删除")])
        item.recordButtonsWidth(80)
        XCTAssertEqual(item.buttonsWidth, 80)

        // 上游 touchmove 只在 touchstart 立起 moving 标记后才生效。
        item.touchMove(translation: CGSize(width: -30, height: 0))
        XCTAssertEqual(item.offset, 0)
        item.touchStart()
        XCTAssertTrue(item.isMoving)

        // 纵向位移更大时按页面滚动处理，不产生偏移。
        item.touchMove(translation: CGSize(width: -10, height: -40))
        XCTAssertEqual(item.offset, 0)

        item.touchMove(translation: CGSize(width: -30, height: -5))
        XCTAssertEqual(item.offset, -30)

        // 左滑不允许超过按钮总宽。
        item.touchMove(translation: CGSize(width: -200, height: 0))
        XCTAssertEqual(item.offset, -80)

        // 关闭态下右滑被忽略（夹成 0）。
        item.touchMove(translation: CGSize(width: 50, height: 0))
        XCTAssertEqual(item.offset, 0)

        // 上游 touchcancel 清掉 moving 并复位滑动状态。
        item.touchCancel()
        XCTAssertFalse(item.isMoving)
    }

    /// 上游 `touchend`：按 threshold 决定回弹或切换状态。
    func testSwipeActionItemTouchEndFollowsThreshold() {
        let item = UPSwipeActionItem(id: "row",
                                     threshold: 20,
                                     actions: [UPSwipeAction(id: "delete", title: "删除")])
        item.recordButtonsWidth(80)

        // 左滑不足阈值 → 保持关闭。
        item.touchStart()
        item.touchMove(translation: CGSize(width: -10, height: 0))
        item.touchEnd(translation: CGSize(width: -10, height: 0))
        XCTAssertFalse(item.opened)

        // 左滑越过阈值 → 展开并把内容钉在 -buttonsWidth。
        item.touchStart()
        item.touchMove(translation: CGSize(width: -40, height: 0))
        item.touchEnd(translation: CGSize(width: -40, height: 0))
        XCTAssertTrue(item.opened)
        XCTAssertEqual(item.offset, -80)

        // 展开态下右滑越过阈值 → 收起。
        item.touchStart()
        item.touchMove(translation: CGSize(width: 40, height: 0))
        item.touchEnd(translation: CGSize(width: 40, height: 0))
        XCTAssertFalse(item.opened)
        XCTAssertEqual(item.offset, 0)
    }

    /// 照抄上游：展开态下 `moveX == 0`（点了内容区）直接收起，`moveX < 0` 直接 return。
    func testSwipeActionItemTouchEndEdgeCasesMatchUpstream() {
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "删除")])
        item.recordButtonsWidth(80)
        item.open()
        XCTAssertTrue(item.opened)

        // 展开态点内容区（位移为 0）→ 收起。
        item.touchStart()
        item.touchMove(translation: CGSize(width: 1, height: 0))
        item.touchEnd(translation: CGSize(width: 0, height: 0))
        XCTAssertFalse(item.opened)

        // 展开态继续左滑 → 上游直接 return，状态不变。
        item.open()
        item.touchStart()
        item.touchMove(translation: CGSize(width: 1, height: 0))
        item.touchEnd(translation: CGSize(width: -30, height: 0))
        XCTAssertTrue(item.opened)

        // disabled 行的手势全程空转。
        let disabled = UPSwipeActionItem(id: "row", disabled: true,
                                         actions: [UPSwipeAction(id: "delete", title: "删除")])
        disabled.recordButtonsWidth(80)
        disabled.touchStart()
        XCTAssertFalse(disabled.isMoving)
        disabled.touchMove(translation: CGSize(width: -60, height: 0))
        disabled.touchEnd(translation: CGSize(width: -60, height: 0))
        XCTAssertFalse(disabled.opened)
        XCTAssertEqual(disabled.offset, 0)
    }

    func testSwipeActionItemExposesButtonSlot() {
        let item = UPSwipeActionItem(id: "row")
        XCTAssertFalse(item.hasButtonSlot)
        XCTAssertTrue(item.buttonContent { Text("自定义") }.hasButtonSlot)
    }
}

@MainActor
final class ReadMoreTests: XCTestCase {
    func testReadMoreTogglesAndEmitsExpandedState() {
        var emitted = false
        let readMore = UPReadMore(lines: 2, expanded: false).onChange { emitted = $0 }
        XCTAssertFalse(readMore.isExpanded)
        readMore.toggleReadMore()
        XCTAssertTrue(readMore.isExpanded)
        XCTAssertTrue(emitted)
        readMore.collapse()
        XCTAssertFalse(readMore.isExpanded)
    }

    /// 上游 `props.js` 的 9 个 prop 默认值来自 `libs/config/props/readMore.js`。
    func testReadMorePropsMatchUpstreamDefaults() {
        XCTAssertEqual(UPConfig.readMore.showHeight, 400)
        XCTAssertFalse(UPConfig.readMore.toggle)
        XCTAssertEqual(UPConfig.readMore.closeText, "展开阅读全文")
        XCTAssertEqual(UPConfig.readMore.openText, "收起")
        XCTAssertEqual(UPConfig.readMore.color, "#2979ff")
        XCTAssertEqual(UPConfig.readMore.fontSize, 14)
        XCTAssertEqual(UPConfig.readMore.textIndent, "2em")
        XCTAssertEqual(UPConfig.readMore.name, "")

        let readMore = UPReadMore(lines: 3)
        XCTAssertEqual(readMore.showHeight, 400)
        XCTAssertFalse(readMore.toggle)
        XCTAssertEqual(readMore.color, "#2979ff")
        XCTAssertEqual(readMore.fontSize, 14)
        XCTAssertEqual(readMore.textIndent, "2em")
        XCTAssertEqual(readMore.name, "")
        XCTAssertEqual(readMore.shadowStyle, UPConfig.readMore.shadowStyle)

        let custom = UPReadMore(lines: 0, showHeight: "200px", toggle: true,
                                color: "#3c9cff", fontSize: "16", textIndent: "1em", name: 3)
        XCTAssertEqual(custom.showHeight, 200)
        XCTAssertTrue(custom.toggle)
        XCTAssertEqual(custom.color, "#3c9cff")
        XCTAssertEqual(custom.fontSize, 16)
        XCTAssertEqual(custom.textIndent, "1em")
        XCTAssertEqual(custom.name, "3")
    }

    /// 上游模板按 `status` 切换箭头图标，图标尺寸固定为 `fontSize + 2`。
    func testReadMoreToggleIconAndShadowFollowStatus() {
        let collapsed = UPReadMore(lines: 3, expanded: false)
        XCTAssertEqual(collapsed.toggleIconName, "arrow-down")
        XCTAssertEqual(collapsed.toggleIconSize, 16)
        XCTAssertEqual(collapsed.innerShadowStyle, UPConfig.readMore.shadowStyle)

        let expanded = UPReadMore(lines: 3, expanded: true, fontSize: 20)
        XCTAssertEqual(expanded.toggleIconName, "arrow-up")
        XCTAssertEqual(expanded.toggleIconSize, 22)
        XCTAssertEqual(expanded.innerShadowStyle, UPStyle())

        XCTAssertEqual(UPConfig.readMore.shadowStyle.padding.top, 100)
        XCTAssertEqual(UPConfig.readMore.shadowStyle.margin.top, -100)
        XCTAssertEqual(collapsed.shadowFadeColor, "#fff")
        XCTAssertEqual(collapsed.shadowFadeHeight, 100)
        XCTAssertEqual(expanded.shadowFadeHeight, 0)
        XCTAssertEqual(UPReadMore(lines: 3, shadowStyle: UPStyle(["background": "#000"])).shadowFadeColor, "#000")
        XCTAssertEqual(UPReadMore(lines: 3, shadowStyle: UPStyle()).shadowFadeColor, "#ffffff")

        XCTAssertTrue(collapsed.isLongContent(contentHeight: 401))
        XCTAssertFalse(collapsed.isLongContent(contentHeight: 400))

        XCTAssertEqual(collapsed.textIndentLength, 30)
        XCTAssertEqual(UPReadMore(lines: 3, textIndent: "12px").textIndentLength, 12)
        XCTAssertEqual(UPReadMore(lines: 3, textIndent: "").textIndentLength, 0)
    }

    /// 上游 `toggle` 为 false 时展开后隐藏收起按钮，为 true 时保留。
    func testReadMoreToggleFlagControlsCollapseButton() {
        let hidesAfterOpen = UPReadMore(lines: 3, expanded: false)
        XCTAssertTrue(hidesAfterOpen.showsToggleRow)
        hidesAfterOpen.toggleReadMore()
        XCTAssertFalse(hidesAfterOpen.showsToggleRow)

        let keepsToggle = UPReadMore(lines: 3, expanded: false, toggle: true)
        keepsToggle.toggleReadMore()
        XCTAssertTrue(keepsToggle.showsToggleRow)

        let hidden = UPReadMore(lines: 3, showToggle: false, toggle: true)
        XCTAssertFalse(hidden.showsToggleRow)
    }

    /// 上游 `toggleReadMore` 用 `$emit(status, name)` 回传 `name`。
    func testReadMoreEmitsUpstreamOpenAndCloseWithName() {
        var opened: [String] = []
        var closed: [String] = []
        let readMore = UPReadMore(lines: 3, toggle: true, name: "poem")
            .onOpen { opened.append($0) }
            .onClose { closed.append($0) }

        readMore.toggleReadMore()
        XCTAssertEqual(opened, ["poem"])
        XCTAssertTrue(closed.isEmpty)

        readMore.toggleReadMore()
        XCTAssertEqual(closed, ["poem"])
        XCTAssertEqual(opened, ["poem"])
    }
}

@MainActor final class PullRefreshBoolBox {
    var value: Bool
    init(_ value: Bool) { self.value = value }
    var binding: Binding<Bool> { Binding(get: { self.value }, set: { self.value = $0 }) }
}
