import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class NoticeComponentsTests: XCTestCase {
    func testNoticeItemsAndNoticeBarExposeUpstreamEvents() {
        var clicked: [String] = []
        let column = UPColumnNotice(notices: ["one", "two"], current: 0)
            .onClick { clicked.append($0) }
        XCTAssertEqual(column.current, 0)
        column.select(1)
        column.click("two")
        XCTAssertEqual(column.current, 1)
        XCTAssertEqual(clicked, ["two"])

        var closed = 0
        let bar = UPNoticeBar(text: "hello", mode: "closable")
            .onClose { closed += 1 }
        bar.close()
        XCTAssertTrue(bar.isClosed)
        XCTAssertEqual(closed, 1)
    }

    /// 上游没有 `closable` prop，关闭图标由 `mode == "closable"` 驱动。
    func testCloseRequiresClosableMode() {
        var closed = 0
        let plain = UPNoticeBar(text: "hello").onClose { closed += 1 }
        plain.close()
        XCTAssertFalse(plain.isClosed)
        XCTAssertEqual(closed, 0)

        XCTAssertFalse(UPNoticeBar(text: "hello").showsCloseIcon)
        XCTAssertTrue(UPNoticeBar(text: "hello", mode: "closable").showsCloseIcon)
        XCTAssertFalse(UPNoticeBar(text: "hello", mode: "link").showsCloseIcon)
        XCTAssertTrue(UPNoticeBar(text: "hello", mode: "link").showsLinkIcon)
        XCTAssertFalse(UPNoticeBar(text: "hello", mode: "closable").showsLinkIcon)
    }

    /// 上游 `click` 事件带当前索引。
    func testNoticeBarClickCarriesTheCurrentIndex() {
        var indexes: [Int] = []
        let bar = UPNoticeBar(text: ["一", "二"]).onClick { indexes.append($0) }

        bar.click()
        bar.select(1)
        bar.click()

        XCTAssertEqual(indexes, [0, 1])
    }

    /// 上游按 `direction`/`step` 决定内部委派给 column 还是 row 子组件。
    func testDirectionAndStepChooseTheDelegateVariant() {
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "row", step: false), "row")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "row", step: true), "column")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "column", step: false), "column")
        XCTAssertEqual(UPNoticeBar.resolvedVariant(direction: "unexpected", step: false), "row")
    }

    /// 上游 `u-notice-bar` 的 text 是 `Array | String`，单串按单条处理。
    func testTextAcceptsUpstreamArrayAndStringForms() {
        XCTAssertEqual(UPNoticeBar(text: "只有一条").texts, ["只有一条"])
        XCTAssertEqual(UPNoticeBar(text: ["一", "二"]).texts, ["一", "二"])
        XCTAssertEqual(UPNoticeBar(text: "").texts, [])
    }

    func testNoticeBarDefaultsMatchUpstream() {
        let bar = UPNoticeBar()

        XCTAssertEqual(bar.direction, "row")
        XCTAssertFalse(bar.step)
        XCTAssertEqual(bar.icon, "volume")
        XCTAssertEqual(bar.mode, "")
        XCTAssertEqual(bar.color, "#f9ae3d")
        XCTAssertEqual(bar.bgColor, "#fdf6ec")
        XCTAssertEqual(bar.speed, 80)
        XCTAssertEqual(bar.fontSize, 14)
        XCTAssertEqual(bar.duration, 2000)
        XCTAssertTrue(bar.disableTouch)
        XCTAssertEqual(bar.url, "")
        XCTAssertEqual(bar.linkType, "navigateTo")
        XCTAssertEqual(bar.justifyContent, "flex-start")
    }

    /// column 的 duration 默认 1500，与 notice-bar 的 2000 不同；row 没有 duration。
    func testChildVariantDefaultsMatchUpstream() {
        let column = UPColumnNotice()
        XCTAssertEqual(column.duration, 1500)
        XCTAssertEqual(column.fontSize, 14)
        XCTAssertEqual(column.speed, 80)
        XCTAssertFalse(column.step)
        XCTAssertEqual(column.justifyContent, "flex-start")

        let row = UPRowNotice()
        XCTAssertEqual(row.fontSize, 14)
        XCTAssertEqual(row.speed, 80)
        XCTAssertEqual(row.icon, "volume")
        XCTAssertEqual(row.color, "#f9ae3d")
        XCTAssertEqual(row.bgColor, "#fdf6ec")
    }

    /// 无参 `onClick` 是旧拼写，与带索引的新拼写重载共存，两者都要能触发。
    func testLegacyNoPayloadClickModifierStillFires() {
        var legacyCalls = 0
        let legacy = UPNoticeBar(text: "hello").onClick { legacyCalls += 1 }
        legacy.click()
        XCTAssertEqual(legacyCalls, 1)

        var indexes: [Int] = []
        let indexed = UPNoticeBar(text: "hello").onClick { (index: Int) in indexes.append(index) }
        indexed.click()
        XCTAssertEqual(indexes, [0])
    }

    /// 旧 `notices:`/`interval:` 初始化器保留，用于源兼容。
    func testLegacyInitializersRemainAvailable() {
        let column = UPColumnNotice(notices: ["一", "二"], current: 1, interval: 5_000)
        XCTAssertEqual(column.texts, ["一", "二"])
        XCTAssertEqual(column.current, 1)
        XCTAssertEqual(column.duration, 5_000)

        let row = UPRowNotice(notices: ["A", "B"])
        XCTAssertEqual(row.notices, ["A", "B"])
    }

    func testNotifyAndPopoverTrackPresentationAndActions() {
        var opened = 0
        var closed = 0
        let notify = UPNotify(show: false, message: "Saved")
            .onOpen { opened += 1 }
            .onClose { closed += 1 }
        notify.open()
        notify.close()
        XCTAssertFalse(notify.show)
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(closed, 1)

        var dismissed = 0
        let popover = UPPopover(show: true, placement: "bottom", closeOnClickOutside: true)
            .onClose { dismissed += 1 }
        popover.close()
        XCTAssertFalse(popover.show)
        XCTAssertEqual(dismissed, 1)
    }

    /// `u-notify` 的样式 prop 默认值来自上游 `notify.js`（`duration` 为 3000，非 2500）。
    func testNotifyStylePropsMatchUpstreamDefaults() {
        let notify = UPNotify()
        XCTAssertEqual(notify.message, "")
        XCTAssertEqual(notify.type, "primary")
        XCTAssertEqual(notify.duration, 3_000)
        XCTAssertEqual(notify.top, 0)
        XCTAssertEqual(notify.color, "#ffffff")
        XCTAssertEqual(notify.bgColor, "")
        XCTAssertEqual(notify.fontSize, 15)
        XCTAssertFalse(notify.safeAreaInsetTop)

        XCTAssertEqual(UPConfig.notify.top, 0)
        XCTAssertEqual(UPConfig.notify.type, "primary")
        XCTAssertEqual(UPConfig.notify.color, "#ffffff")
        XCTAssertEqual(UPConfig.notify.bgColor, "")
        XCTAssertEqual(UPConfig.notify.message, "")
        XCTAssertEqual(UPConfig.notify.duration, 3_000)
        XCTAssertEqual(UPConfig.notify.fontSize, 15)
        XCTAssertFalse(UPConfig.notify.safeAreaInsetTop)

        // 上游 `containerStyle` 把层级写死为 10076，不是 prop。
        XCTAssertEqual(UPNotify.overlayZIndex, 10_076)
    }

    /// 背景色只有在 `bgColor` 非空时才覆盖 `.u-notify--{type}` 的主题底色。
    func testNotifyBackgroundFollowsTypeUnlessBgColorProvided() {
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "", type: "primary"), "primary")
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "", type: "success"), "success")
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "", type: "error"), "error")
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "", type: "warning"), "warning")
        // 上游未匹配到 `.u-notify--{type}` 类时没有底色。
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "", type: ""), "")
        XCTAssertEqual(UPNotify.backgroundColorToken(bgColor: "#000000", type: "primary"), "#000000")
        XCTAssertEqual(UPNotify(bgColor: "#000").backgroundColorToken, "#000")
        XCTAssertEqual(UPNotify(type: "success").backgroundColorToken, "success")
    }

    /// 图标名与尺寸照抄上游 `icon` 计算属性与 `1.3 * fontSize`。
    func testNotifyIconAndUnitPropsMirrorUpstream() {
        XCTAssertEqual(UPNotify.iconName(for: "success"), "checkmark-circle")
        XCTAssertEqual(UPNotify.iconName(for: "error"), "close-circle")
        XCTAssertEqual(UPNotify.iconName(for: "warning"), "error-circle")
        XCTAssertEqual(UPNotify.iconName(for: "primary"), "")

        XCTAssertTrue(UPNotify(type: "warning").showsIcon)
        XCTAssertFalse(UPNotify(type: "primary").showsIcon)
        XCTAssertEqual(UPNotify().iconSize, 19.5, accuracy: 0.001)

        let scaled = UPNotify(top: "44px", fontSize: "20px")
        XCTAssertEqual(scaled.top, 44)
        XCTAssertEqual(scaled.fontSize, 20)
        XCTAssertEqual(scaled.iconSize, 26, accuracy: 0.001)
        XCTAssertEqual(UPNotify(top: 88).top, 88)
    }
}

@MainActor
final class GuideFloatAgreementTests: XCTestCase {
    func testGuideAdvancesAndFloatButtonEmitsItemSelection() {
        let suiteName = "UltraUI.GuideTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }
        let guide = UPGuide(steps: [UPGuideStep(id: "first"), UPGuideStep(id: "second")], storage: storage)
        XCTAssertEqual(guide.current, 0)
        XCTAssertTrue(guide.next())
        XCTAssertEqual(guide.current, 1)
        XCTAssertFalse(guide.next())
        guide.previous()
        XCTAssertEqual(guide.current, 0)

        var selected = ""
        let button = UPFloatButton(items: [UPFloatButtonItem(id: "add", title: "Add")])
            .onItemClick { selected = $0.id }
        button.toggle()
        button.select("add")
        XCTAssertTrue(button.expanded)
        XCTAssertEqual(selected, "add")
    }

    /// 上游 props 内联在 `.vue` 里：`backgroundColor: '#2979ff'`、`color: '#fff'`、
    /// `width` / `height` 都是 `'50px'`、`borderColor: ''`、`right: '30px'`、
    /// `top` / `bottom` 是空串、`isMenu: false`、`list: []`。
    func testFloatButtonPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.floatButton.backgroundColor, "#2979ff")
        XCTAssertEqual(UPConfig.floatButton.color, "#fff")
        XCTAssertEqual(UPConfig.floatButton.width, "50px")
        XCTAssertEqual(UPConfig.floatButton.height, "50px")
        XCTAssertEqual(UPConfig.floatButton.borderColor, "")
        XCTAssertEqual(UPConfig.floatButton.right, "30px")
        XCTAssertEqual(UPConfig.floatButton.top, "")
        XCTAssertEqual(UPConfig.floatButton.bottom, "")
        XCTAssertFalse(UPConfig.floatButton.isMenu)

        let button = UPFloatButton()
        XCTAssertEqual(button.backgroundColor, "#2979ff")
        XCTAssertEqual(button.color, "#fff")
        XCTAssertEqual(button.width, "50px")
        XCTAssertEqual(button.height, "50px")
        XCTAssertEqual(button.borderColor, "")
        XCTAssertEqual(button.right, "30px")
        XCTAssertEqual(button.top, "")
        XCTAssertEqual(button.bottom, "")
        XCTAssertFalse(button.isMenu)
        XCTAssertTrue(button.list.isEmpty)
        XCTAssertEqual(button.resolvedWidth, 50)
        XCTAssertEqual(button.resolvedHeight, 50)
    }

    /// 上游 `clickHandler`：`isMenu` 为真才切换 `showList`，两条分支都抛 `click`。
    func testFloatButtonClickHandlerOnlyTogglesInMenuMode() {
        var plainClicks = 0
        let plain = UPFloatButton().onClick { plainClicks += 1 }
        plain.clickHandler()
        XCTAssertEqual(plainClicks, 1)
        XCTAssertFalse(plain.showList)

        var menuClicks = 0
        let menu = UPFloatButton(isMenu: true, list: [UPFloatButtonItem(id: "a", name: "plus")])
            .onClick { menuClicks += 1 }
        menu.clickHandler()
        XCTAssertEqual(menuClicks, 1)
        XCTAssertTrue(menu.showList)
        XCTAssertEqual(menu.iconRotation, 45)

        menu.clickHandler()
        XCTAssertFalse(menu.showList)
        XCTAssertEqual(menu.iconRotation, 0)
    }

    /// 上游 `itemClick(item, index)` 负载是 `{ ...item, index }`。
    func testFloatButtonItemClickCarriesIndex() {
        var events: [UPFloatButtonItemClickEvent] = []
        let button = UPFloatButton(isMenu: true, list: [
            UPFloatButtonItem(id: "a", name: "plus"),
            UPFloatButtonItem(id: "b", name: "order")
        ])
        .onItemClick { (event: UPFloatButtonItemClickEvent) in events.append(event) }

        button.select("b")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.index, 1)
        XCTAssertEqual(events.first?.item.id, "b")

        // 找不到 id 时不抛事件。
        button.select("missing")
        XCTAssertEqual(events.count, 1)
    }

    /// 上游模板：子项的三个配色都是 `item?.x ? item?.x : x` 的回退。
    func testFloatButtonItemColorsFallBackToComponentValues() {
        let button = UPFloatButton(backgroundColor: "#111111",
                                   color: "#222222",
                                   borderColor: "#333333",
                                   isMenu: true,
                                   list: [])
        let inherited = UPFloatButtonItem(id: "a", name: "plus")
        XCTAssertEqual(button.itemBackgroundColor(inherited), "#111111")
        XCTAssertEqual(button.itemColor(inherited), "#222222")
        XCTAssertEqual(button.itemBorderColor(inherited), "#333333")

        let overridden = UPFloatButtonItem(id: "b",
                                          name: "order",
                                          backgroundColor: "#aaaaaa",
                                          color: "#bbbbbb",
                                          borderColor: "#cccccc")
        XCTAssertEqual(button.itemBackgroundColor(overridden), "#aaaaaa")
        XCTAssertEqual(button.itemColor(overridden), "#bbbbbb")
        XCTAssertEqual(button.itemBorderColor(overridden), "#cccccc")
    }

    func testFloatButtonExposesDefaultAndListSlots() {
        let plain = UPFloatButton()
        XCTAssertFalse(plain.hasDefaultSlot)
        XCTAssertFalse(plain.hasListSlot)

        let slotted = plain
            .content { showList in Text(showList ? "开" : "关") }
            .listContent { Text("list") }
        XCTAssertTrue(slotted.hasDefaultSlot)
        XCTAssertTrue(slotted.hasListSlot)
    }

    /// `libs/config/props/guide.js` 的默认值是 `showSkip: true`、`skipText: '跳过'`、
    /// `nextText: '下一步'`、`finishText: '立即体验'`，上游模板主按钮文字取
    /// `isLastPage() ? finishText : nextText`。
    func testGuideActionTextsMatchUpstreamProps() {
        let guide = UPGuide(steps: [UPGuideStep(id: "first"), UPGuideStep(id: "second")])
        XCTAssertTrue(guide.showSkip)
        XCTAssertEqual(guide.skipText, "跳过")
        XCTAssertEqual(guide.nextText, "下一步")
        XCTAssertEqual(guide.finishText, "立即体验")
        XCTAssertFalse(guide.isLastStep)
        XCTAssertEqual(guide.actionText, "下一步")

        XCTAssertTrue(guide.next())
        XCTAssertTrue(guide.isLastStep)
        XCTAssertEqual(guide.actionText, "立即体验")
    }

    /// 自定义文案与关闭跳过按钮时按属性透出，单页引导首屏即最后一屏。
    func testGuideHonoursCustomActionTextsAndSkipVisibility() {
        let custom = UPGuide(
            steps: [UPGuideStep(id: "only")],
            showSkip: false,
            skipText: "Skip",
            nextText: "Next",
            finishText: "Start"
        )
        XCTAssertFalse(custom.showSkip)
        XCTAssertEqual(custom.skipText, "Skip")
        XCTAssertEqual(custom.nextText, "Next")
        XCTAssertTrue(custom.isLastStep)
        XCTAssertEqual(custom.actionText, "Start")

        let empty = UPGuide()
        XCTAssertTrue(empty.isLastStep)
        XCTAssertEqual(empty.actionText, "立即体验")
    }

    /// `components/u-guide/guide.js` 的 13 个默认值，`props.js` 只暴露其中 11 个
    /// prop（`zIndex` 类型是 `[String, Number]`）。
    func testGuideConfigMatchesUpstreamDefaults() {
        XCTAssertFalse(UPConfig.guide.show)
        XCTAssertTrue(UPConfig.guide.list.isEmpty)
        XCTAssertEqual(UPConfig.guide.storageKey, "up-guide-default")
        XCTAssertTrue(UPConfig.guide.once)
        XCTAssertTrue(UPConfig.guide.showSkip)
        XCTAssertEqual(UPConfig.guide.skipText, "跳过")
        XCTAssertEqual(UPConfig.guide.nextText, "下一步")
        XCTAssertEqual(UPConfig.guide.finishText, "立即体验")
        XCTAssertTrue(UPConfig.guide.indicator)
        XCTAssertEqual(UPConfig.guide.bgColor, "#111111")
        XCTAssertEqual(UPConfig.guide.zIndex, 10075)
    }

    /// 上游根节点 `:style="{ zIndex: `${zIndex}` }"` 接受 String 或 Number，
    /// 页面背景取 `item.backgroundColor || bgColor`。
    func testGuideResolvesUpstreamZIndexAndBackgroundProps() {
        let plain = UPGuide(steps: [UPGuideStep(id: "only")], show: true)
        XCTAssertEqual(plain.zIndex, 10075)
        XCTAssertTrue(plain.indicator)
        XCTAssertEqual(plain.bgColor, "#111111")
        XCTAssertEqual(plain.currentBackgroundColor, "#111111")

        let custom = UPGuide(
            steps: [UPGuideStep(id: "only", backgroundColor: "#2979FF")],
            show: true,
            indicator: false,
            bgColor: "#000000",
            zIndex: "12000"
        )
        XCTAssertEqual(custom.zIndex, 12_000)
        XCTAssertFalse(custom.indicator)
        XCTAssertEqual(custom.currentBackgroundColor, "#2979FF")
        XCTAssertEqual(UPGuide(zIndex: 20).zIndex, 20)
    }

    /// 上游 list item 字段是 `image`/`title`/`desc`/`backgroundColor`；
    /// 原生保留既有的 `message`，`desc` 为空时回落到它。
    func testGuideStepExposesUpstreamItemFields() {
        let step = UPGuideStep(
            id: "first",
            title: "标题",
            image: "https://example.com/a.png",
            desc: "上游描述",
            backgroundColor: "#101010"
        )
        XCTAssertEqual(step.image, "https://example.com/a.png")
        XCTAssertEqual(step.desc, "上游描述")
        XCTAssertEqual(step.resolvedDesc, "上游描述")
        XCTAssertEqual(step.backgroundColor, "#101010")
        XCTAssertEqual(UPGuideStep(id: "second", message: "原生描述").resolvedDesc, "原生描述")
    }

    /// 上游 `mounted → bootstrap()`：空 list 直接 return，`once` 且已记忆时
    /// 关闭并回抛 `update:show=false`，否则 `innerShow = !!show`。
    func testGuideBootstrapHonoursEmptyListAndRememberedFlag() {
        let suiteName = "UltraUI.GuideTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        XCTAssertFalse(UPGuide(show: true, storage: storage).show)

        let steps = [UPGuideStep(id: "first"), UPGuideStep(id: "second")]
        XCTAssertTrue(UPGuide(steps: steps, show: true, storage: storage).show)
        XCTAssertFalse(UPGuide(steps: steps, storage: storage).show)

        storage.set(1, forKey: "up-guide-default")
        var updates: [Bool] = []
        let remembered = UPGuide(steps: steps, show: true, storage: storage)
            .onUpdateShow { updates.append($0) }
        XCTAssertTrue(remembered.readRemembered())
        XCTAssertFalse(remembered.show)
        remembered.bootstrap()
        XCTAssertEqual(updates, [false])

        storage.set(true, forKey: "up-guide-default")
        XCTAssertFalse(UPGuide(steps: steps, show: true, storage: storage).show)
        storage.set("1", forKey: "up-guide-default")
        XCTAssertFalse(UPGuide(steps: steps, show: true, storage: storage).show)
        storage.set("0", forKey: "up-guide-default")
        XCTAssertTrue(UPGuide(steps: steps, show: true, storage: storage).show)

        storage.set(1, forKey: "up-guide-default")
        XCTAssertTrue(UPGuide(steps: steps, show: true, once: false, storage: storage).show)
    }

    /// `resolvedStorageKey` 空串回落 `up-guide-default`，`writeRemembered()`
    /// 写入的是数字 `1`，`reset()` 通过 `removeStorageSync` 清键。
    func testGuideResolvesStorageKeyFallbackAndWritesUpstreamFlag() {
        let suiteName = "UltraUI.GuideTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(UPGuide(storageKey: "").resolvedStorageKey, "up-guide-default")
        let guide = UPGuide(
            steps: [UPGuideStep(id: "only")],
            show: true,
            storageKey: "guide-home",
            storage: storage
        )
        XCTAssertEqual(guide.resolvedStorageKey, "guide-home")
        guide.close()
        XCTAssertEqual(storage.object(forKey: "guide-home") as? Int, 1)
        XCTAssertTrue(guide.readRemembered())
        guide.reset()
        XCTAssertNil(storage.object(forKey: "guide-home"))
        XCTAssertFalse(guide.readRemembered())

        let volatile = UPGuide(
            steps: [UPGuideStep(id: "only")],
            show: true,
            storageKey: "guide-home",
            once: false,
            storage: storage
        )
        volatile.close()
        XCTAssertNil(storage.object(forKey: "guide-home"))
    }

    /// 上游 `onSkip()` 先派发 `skip` 再 `close(true)`，`close()` 的 `closing`
    /// 标记在同一 tick 内去重、`$nextTick` 后恢复。
    func testGuideSkipAndCloseEmitUpstreamEventsOnce() async throws {
        let suiteName = "UltraUI.GuideTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        var events: [String] = []
        var updates: [Bool] = []
        let guide = UPGuide(steps: [UPGuideStep(id: "first"), UPGuideStep(id: "second")], show: true, storage: storage)
            .onSkip { events.append("skip") }
            .onClose { events.append("close") }
            .onUpdateShow { updates.append($0) }
        XCTAssertTrue(guide.show)
        guide.skip()
        guide.close()
        XCTAssertEqual(events, ["skip", "close"])
        XCTAssertEqual(updates, [false])
        XCTAssertFalse(guide.show)

        try await Task.sleep(nanoseconds: 10_000_000)
        guide.close()
        XCTAssertEqual(events, ["skip", "close", "close"])
        XCTAssertEqual(updates, [false, false])
    }

    /// 上游 `open()` 只重置 `current` 与 `innerShow` 并派发 `update:show=true`，
    /// 不清除记忆；末屏主按钮先 `finish` 再 `close(true)`。
    func testGuideOpenAndFinishFollowUpstreamMethods() {
        let suiteName = "UltraUI.GuideTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        var finished = 0
        var updates: [Bool] = []
        var changes: [Int] = []
        let guide = UPGuide(steps: [UPGuideStep(id: "first"), UPGuideStep(id: "second")], show: true, storage: storage)
            .onChange { changes.append($0) }
            .onFinish { finished += 1 }
            .onUpdateShow { updates.append($0) }

        XCTAssertTrue(guide.next())
        XCTAssertEqual(changes, [1])
        XCTAssertFalse(guide.next())
        XCTAssertEqual(finished, 1)
        XCTAssertFalse(guide.show)
        XCTAssertEqual(updates, [false])
        XCTAssertTrue(guide.readRemembered())

        guide.open()
        XCTAssertEqual(guide.current, 0)
        XCTAssertTrue(guide.show)
        XCTAssertEqual(updates, [false, true])
        XCTAssertTrue(guide.readRemembered())
    }

    func testAgreementBindingAndChangeEvent() {
        var checked = false
        var eventValue = false
        let agreement = UPAgreement(checked: Binding(get: { checked }, set: { checked = $0 }))
            .onChange { eventValue = $0 }
        agreement.toggle()
        XCTAssertTrue(checked)
        XCTAssertTrue(eventValue)
        XCTAssertEqual(agreement.displayText, "我已阅读并同意")
    }

    /// `u-agreement.vue` 的内联 props：两个跳转地址。
    func testAgreementPropDefaultsMatchUpstream() {
        let agreement = UPAgreement()
        XCTAssertEqual(agreement.urlProtocol, "/pages/user_agreement/agreement/info?title=用户协议")
        XCTAssertEqual(agreement.urlPrivacy, "/pages/user_agreement/agreement/info?title=隐私政策")
        XCTAssertEqual(agreement.confirmText, "阅读并同意")
        XCTAssertFalse(agreement.show)
        XCTAssertFalse(agreement.hasDeclarationSlot)
        XCTAssertTrue(UPAgreement.defaultDeclaration.contains("隐私政策"))
    }

    /// 上游 `showModal()` / `confirm()`：确认后关窗并抛 `confirm(1)`。
    func testAgreementModalConfirmEmitsOne() {
        var checked = false
        var payloads: [Int] = []
        let agreement = UPAgreement(checked: Binding(get: { checked }, set: { checked = $0 }))
            .onConfirm { payloads.append($0) }
        agreement.showModal()
        XCTAssertTrue(agreement.show)
        agreement.confirm()
        XCTAssertFalse(agreement.show)
        XCTAssertEqual(payloads, [1])
        // 确认即视为已勾选。
        XCTAssertTrue(checked)
    }

    /// 上游取消分支是退出应用，iOS 没有合规 API，改为关窗并回调宿主。
    func testAgreementCancelClosesAndNotifiesHost() {
        var cancelled = 0
        let agreement = UPAgreement().onCancel { cancelled += 1 }
        agreement.showModal()
        agreement.cancel()
        XCTAssertFalse(agreement.show)
        XCTAssertEqual(cancelled, 1)
    }

    /// 上游 `urlClick(type)` 按 key 取地址。
    func testAgreementURLTapResolvesByKey() {
        var opened: [String] = []
        let agreement = UPAgreement(urlProtocol: "/a", urlPrivacy: "/b")
            .onURLTap { opened.append($0) }
        agreement.openAgreement("urlProtocol")
        agreement.openAgreement("urlPrivacy")
        XCTAssertEqual(opened, ["/a", "/b"])
        // 空地址不回调。
        UPAgreement(urlProtocol: "").onURLTap { opened.append($0) }.openAgreement("urlProtocol")
        XCTAssertEqual(opened.count, 2)
    }
}

@MainActor
final class TooltipComponentsTests: XCTestCase {
    func testTooltipAndRowNoticeExposeVisibilityAndSelection() {
        let tooltip = UPTooltip(text: "More", show: false)
        tooltip.showTooltip()
        XCTAssertTrue(tooltip.show)
        tooltip.hideTooltip()
        XCTAssertFalse(tooltip.show)

        var selected = -1
        let row = UPRowNotice(notices: ["A", "B"]).onClick { selected = $0 }
        row.select(1)
        XCTAssertEqual(row.current, 1)
        XCTAssertEqual(selected, 1)
    }

    /// `tooltip.js`：`text: ''`、`copyText: ''`、`size: 14`、`color: '#606266'`、
    /// `bgColor: 'transparent'`、`direction: 'top'`、`zIndex: 10071`、
    /// `showCopy: true`、`buttons: []`、`overlay: true`、`showToast: true`、
    /// `popupBgColor: ''`、`triggerMode: 'longpress'`、`forcePosition: {}`、
    /// `show: false`、`singleton: false`。
    func testTooltipDefaultsMatchUpstreamProps() {
        let tooltip = UPTooltip()
        XCTAssertEqual(tooltip.text, "")
        XCTAssertEqual(tooltip.copyText, "")
        XCTAssertEqual(tooltip.size, 14)
        XCTAssertEqual(tooltip.color, "#606266")
        XCTAssertEqual(tooltip.bgColor, "transparent")
        XCTAssertEqual(tooltip.popupBgColor, "")
        XCTAssertEqual(tooltip.direction, "top")
        XCTAssertEqual(tooltip.zIndex, 10071)
        XCTAssertTrue(tooltip.showCopy)
        XCTAssertEqual(tooltip.buttons, [])
        XCTAssertTrue(tooltip.overlay)
        XCTAssertTrue(tooltip.showToast)
        XCTAssertEqual(tooltip.triggerMode, "longpress")
        XCTAssertEqual(tooltip.forcePosition, UPStyle())
        XCTAssertFalse(tooltip.show)
        XCTAssertFalse(tooltip.singleton)
        // `popupBgColor` 为空时沿用 CSS 的 `#060607`。
        XCTAssertEqual(tooltip.resolvedPopupBackground, "#060607")
        XCTAssertFalse(tooltip.hasTriggerSlot)
        XCTAssertFalse(tooltip.hasContentSlot)
    }

    /// `text` / `copyText` 是 `String | Number`，`size` / `zIndex` 同样。
    func testTooltipAcceptsStringAndNumberProps() {
        let tooltip = UPTooltip(text: 1, copyText: 2, size: "18", zIndex: "9")
        XCTAssertEqual(tooltip.text, "1")
        XCTAssertEqual(tooltip.copyText, "2")
        XCTAssertEqual(tooltip.size, 18)
        XCTAssertEqual(tooltip.zIndex, 9)
    }

    /// 上游 `triggerMode` 只处理 `click` 与 `longpress`；`manual` 靠 `watch.show`。
    func testTooltipTriggerModeGatesOpening() {
        var opened = 0
        let longpress = UPTooltip(text: "a").onOpen { opened += 1 }
        longpress.handleTriggerTap()
        XCTAssertFalse(longpress.show)
        longpress.handleTriggerLongPress()
        XCTAssertTrue(longpress.show)
        XCTAssertEqual(opened, 1)
        // 上游 `open()` 幂等。
        longpress.handleTriggerLongPress()
        XCTAssertEqual(opened, 1)

        let click = UPTooltip(text: "a", triggerMode: "click")
        click.handleTriggerLongPress()
        XCTAssertFalse(click.show)
        click.handleTriggerTap()
        XCTAssertTrue(click.show)

        let manual = UPTooltip(text: "a", triggerMode: "manual")
        manual.handleTriggerTap()
        manual.handleTriggerLongPress()
        XCTAssertFalse(manual.show)
        manual.applyManualVisibility(true)
        XCTAssertTrue(manual.show)
        manual.applyManualVisibility(false)
        XCTAssertFalse(manual.show)
        // 非 manual 模式忽略 `show` 变化。
        UPTooltip(text: "a").applyManualVisibility(true)
    }

    /// 上游 `setClipboardData()`：先关闭、抛 `click(0)`，`copyText` 优先于 `text`。
    func testTooltipCopyUsesCopyTextAndEmitsZeroIndex() {
        var copied: [String] = []
        var clicks: [Int] = []
        let tooltip = UPTooltip(text: "text", copyText: "copy", triggerMode: "click")
            .onClick { clicks.append($0) }
            .clipboard { copied.append($0); return true }
        tooltip.handleTriggerTap()
        tooltip.copy()
        XCTAssertFalse(tooltip.show)
        XCTAssertEqual(copied, ["copy"])
        XCTAssertEqual(clicks, [0])

        let fallback = UPTooltip(text: "text").clipboard { copied.append($0); return true }
        fallback.copy()
        XCTAssertEqual(copied, ["copy", "text"])
    }

    /// 上游 `btnClickHandler`：`showCopy` 为真时扩展按钮下标加 1。
    func testTooltipButtonIndexAccountsForCopyButton() {
        var clicks: [Int] = []
        let withCopy = UPTooltip(text: "a", buttons: ["编辑", "删除"]).onClick { clicks.append($0) }
        withCopy.tapButton(1)
        XCTAssertEqual(clicks, [2])

        let withoutCopy = UPTooltip(text: "a", showCopy: false, buttons: ["编辑", "删除"])
            .onClick { clicks.append($0) }
        withoutCopy.tapButton(1)
        XCTAssertEqual(clicks, [2, 1])
        // 越界不抛事件。
        withoutCopy.tapButton(5)
        XCTAssertEqual(clicks.count, 2)
    }

    /// 上游 `v-if="showCopy || buttons.length"` 才画三角指示器。
    func testTooltipIndicatorVisibilityFollowsButtons() {
        XCTAssertTrue(UPTooltip(text: "a").showsIndicator)
        XCTAssertTrue(UPTooltip(text: "a", showCopy: false, buttons: ["编辑"]).showsIndicator)
        XCTAssertFalse(UPTooltip(text: "a", showCopy: false).showsIndicator)
    }

    /// 上游模块级 `activeSingletonTooltip`：`singleton` 为真时同页只留一个展开。
    func testTooltipSingletonClosesPreviousInstance() {
        var closes = 0
        let first = UPTooltip(text: "1", triggerMode: "click", singleton: true).onClose { closes += 1 }
        let second = UPTooltip(text: "2", triggerMode: "click", singleton: true)
        first.open()
        second.open()
        XCTAssertFalse(first.show)
        XCTAssertTrue(second.show)
        XCTAssertEqual(closes, 1)
        second.close()
        XCTAssertFalse(UPTooltipCenter.shared.hasActive)

        // singleton 为假的实例互不影响。
        let a = UPTooltip(text: "a", triggerMode: "click")
        let b = UPTooltip(text: "b", triggerMode: "click")
        a.open()
        b.open()
        XCTAssertTrue(a.show)
        XCTAssertTrue(b.show)
    }

    /// 上游 `bgColor` 只在没有 `#trigger` 插槽且气泡展开时给兜底文本上底色。
    func testTooltipTriggerBackgroundOnlyAppliesWhileVisible() {
        let tooltip = UPTooltip(text: "a", bgColor: "#f00", triggerMode: "click")
        XCTAssertNil(tooltip.resolvedTriggerBackground)
        tooltip.open()
        XCTAssertEqual(tooltip.resolvedTriggerBackground, "#f00")
        // 默认 `transparent` 不上色。
        let transparent = UPTooltip(text: "a", triggerMode: "click")
        transparent.open()
        XCTAssertNil(transparent.resolvedTriggerBackground)
    }

    /// 上游四方向的 `marginTop/marginBottom: -10px` 与 `triggerInfo.width + indicatorWidth`；
    /// `forcePosition` 整体覆盖计算结果。
    func testTooltipDirectionOffsetsAndForcePosition() {
        XCTAssertEqual(UPTooltip<EmptyView>.baseOffset(direction: "top"), CGSize(width: 0, height: -10))
        XCTAssertEqual(UPTooltip<EmptyView>.baseOffset(direction: "bottom"), CGSize(width: 0, height: 10))
        XCTAssertEqual(UPTooltip<EmptyView>.baseOffset(direction: "left"), CGSize(width: -14, height: 0))
        XCTAssertEqual(UPTooltip<EmptyView>.baseOffset(direction: "right"), CGSize(width: 14, height: 0))
        XCTAssertEqual(UPTooltip<EmptyView>.resolvedDirection("hover"), "top")
        XCTAssertEqual(UPTooltip<EmptyView>.overlayAlignment(for: "bottom"), .bottom)

        let forced = UPTooltip(text: "a", forcePosition: UPStyle(["left": "20", "bottom": "8"]))
        XCTAssertEqual(forced.bubbleOffset, CGSize(width: 20, height: -8))
    }

    /// 上游透明遮罩点击必定关闭；`overlay` 为假时不渲染遮罩。
    func testTooltipOverlayTapClosesBubble() {
        let tooltip = UPTooltip(text: "a", triggerMode: "click")
        tooltip.open()
        tooltip.handleOutsideTap()
        XCTAssertFalse(tooltip.show)
        XCTAssertFalse(UPTooltip(text: "a", overlay: false).overlay)
    }
}

@MainActor
final class PopoverComponentsTests: XCTestCase {
    /// 上游没有 `popover.js`，`props.js` 的字面量即默认值。
    func testPopoverDefaultsMatchUpstreamProps() {
        XCTAssertEqual(UPConfig.popover.text, "")
        XCTAssertEqual(UPConfig.popover.color, "#333")
        XCTAssertEqual(UPConfig.popover.bgColor, "#f7f7f7")
        XCTAssertEqual(UPConfig.popover.popupBgColor, "#f7f7f7")
        XCTAssertEqual(UPConfig.popover.placement, "top")
        XCTAssertEqual(UPConfig.popover.triggerMode, "click")
        XCTAssertFalse(UPConfig.popover.show)
        XCTAssertEqual(UPConfig.popover.zIndex, 10070)
        XCTAssertEqual(UPConfig.popover.forcePosition, UPStyle())
        XCTAssertEqual(UPConfig.popover.direction, "top")

        let popover = UPPopover()
        XCTAssertEqual(popover.text, "")
        XCTAssertEqual(popover.color, "#333")
        XCTAssertEqual(popover.bgColor, "#f7f7f7")
        XCTAssertEqual(popover.popupBgColor, "#f7f7f7")
        XCTAssertEqual(popover.placement, "top")
        XCTAssertEqual(popover.triggerMode, "click")
        XCTAssertEqual(popover.zIndex, 10070)
        XCTAssertEqual(popover.forcePosition, UPStyle())
        XCTAssertEqual(popover.direction, "top")
        XCTAssertFalse(popover.show)
    }

    /// 上游只为四个方向计算定位，其余取值原生统一回落到 `top`。
    func testPopoverDirectionFallsBackToTop() {
        for direction in ["top", "bottom", "left", "right"] {
            XCTAssertEqual(UPPopover<EmptyView>.resolvedDirection(direction), direction)
        }
        XCTAssertEqual(UPPopover<EmptyView>.resolvedDirection("top-start"), "top")
        XCTAssertEqual(UPPopover<EmptyView>.resolvedDirection(""), "top")
        XCTAssertEqual(UPPopover(direction: "unknown").resolvedDirection, "top")
    }

    /// `top`/`bottom` 复刻上游 `∓10px` 外边距，`left`/`right` 复刻 `indicatorWidth` 间距。
    func testPopoverBaseOffsetPerDirection() {
        XCTAssertEqual(UPPopover<EmptyView>.baseOffset(direction: "top"), CGSize(width: 0, height: -10))
        XCTAssertEqual(UPPopover<EmptyView>.baseOffset(direction: "bottom"), CGSize(width: 0, height: 10))
        XCTAssertEqual(UPPopover<EmptyView>.baseOffset(direction: "left"), CGSize(width: -14, height: 0))
        XCTAssertEqual(UPPopover<EmptyView>.baseOffset(direction: "right"), CGSize(width: 14, height: 0))
        XCTAssertEqual(UPPopover<EmptyView>.baseOffset(direction: "nope"),
                       UPPopover<EmptyView>.baseOffset(direction: "top"))
        XCTAssertEqual(UPPopover<EmptyView>.indicatorSide, 14)
    }

    /// 上游 `tooltipStyleCpu` 末尾展开 `forcePosition`，因此它会覆盖算出来的定位。
    func testPopoverForcePositionOverridesBaseOffset() {
        let forced = UPPopover(forcePosition: UPStyle(["right": "108px", "top": "0px"]), direction: "left")
        XCTAssertEqual(forced.bubbleOffset, CGSize(width: -108, height: 0))

        let leftTop = UPPopover(forcePosition: UPStyle(["left": "20px", "bottom": "12px"]), direction: "bottom")
        XCTAssertEqual(leftTop.bubbleOffset, CGSize(width: 20, height: -12))

        // 百分比无法换算成 pt，`UPStyle.length(for:)` 返回 nil，定位保持基线值。
        let percentage = UPPopover(forcePosition: UPStyle(["left": "50%"]), direction: "right")
        XCTAssertEqual(percentage.bubbleOffset, CGSize(width: 14, height: 0))

        XCTAssertEqual(UPPopover(direction: "bottom").bubbleOffset, CGSize(width: 0, height: 10))
    }

    /// 上游 `clickHander` 只在 `click` 下开、`longpressHandler` 只在 `longpress` 下开，
    /// `hover` 没有任何处理器，`manual` 只走 `watch.show`。
    func testPopoverTriggerModeGating() {
        XCTAssertTrue(UPPopover<EmptyView>.opensOnTap(triggerMode: "click"))
        XCTAssertFalse(UPPopover<EmptyView>.opensOnTap(triggerMode: "longpress"))
        XCTAssertTrue(UPPopover<EmptyView>.opensOnLongPress(triggerMode: "longpress"))
        XCTAssertFalse(UPPopover<EmptyView>.opensOnLongPress(triggerMode: "click"))
        XCTAssertTrue(UPPopover<EmptyView>.respondsToShowProp(triggerMode: "manual"))
        XCTAssertFalse(UPPopover<EmptyView>.respondsToShowProp(triggerMode: "click"))

        for mode in ["hover", "manual"] {
            XCTAssertFalse(UPPopover<EmptyView>.opensOnTap(triggerMode: mode))
            XCTAssertFalse(UPPopover<EmptyView>.opensOnLongPress(triggerMode: mode))
        }
    }

    /// 上游 `open()`/`close()` 都有幂等 guard，事件只在状态真正翻转时 emit。
    func testPopoverOpenAndCloseAreIdempotent() {
        var opened = 0
        var closed = 0
        let popover = UPPopover(text: "提示")
            .onOpen { opened += 1 }
            .onClose { closed += 1 }

        popover.close()
        XCTAssertEqual(closed, 0)

        popover.open()
        popover.open()
        XCTAssertTrue(popover.show)
        XCTAssertEqual(opened, 1)

        popover.close()
        popover.close()
        XCTAssertFalse(popover.show)
        XCTAssertEqual(closed, 1)
    }

    /// `click` 模式点击触发器先转发 `click` 再展开；长按不响应。
    func testPopoverTriggerHandlersFollowTriggerMode() {
        var clicks = 0
        let clickMode = UPPopover(triggerMode: "click").onClick { clicks += 1 }
        clickMode.handleTriggerLongPress()
        XCTAssertFalse(clickMode.show)
        clickMode.handleTriggerTap()
        XCTAssertEqual(clicks, 1)
        XCTAssertTrue(clickMode.show)

        let longpressMode = UPPopover(triggerMode: "longpress")
        longpressMode.handleTriggerTap()
        XCTAssertFalse(longpressMode.show)
        longpressMode.handleTriggerLongPress()
        XCTAssertTrue(longpressMode.show)

        let hoverMode = UPPopover(triggerMode: "hover")
        hoverMode.handleTriggerTap()
        hoverMode.handleTriggerLongPress()
        XCTAssertFalse(hoverMode.show)
    }

    /// 上游 `watch.show` 里判断 `triggerMode === 'manual'` 才开合。
    func testPopoverManualVisibilityOnlyAppliesInManualMode() {
        let manual = UPPopover(triggerMode: "manual")
        manual.applyManualVisibility(true)
        XCTAssertTrue(manual.show)
        manual.applyManualVisibility(false)
        XCTAssertFalse(manual.show)

        let click = UPPopover(triggerMode: "click")
        click.applyManualVisibility(true)
        XCTAssertFalse(click.show)
    }

    /// 上游 `overlayClickHandler` 必定关闭；原生保留 `closeOnClickOutside` 开关。
    func testPopoverOutsideTapRespectsCloseSwitch() {
        var closed = 0
        let closable = UPPopover(show: true, triggerMode: "manual").onClose { closed += 1 }
        closable.handleOutsideTap()
        XCTAssertFalse(closable.show)
        XCTAssertEqual(closed, 1)

        let sticky = UPPopover(show: true, triggerMode: "manual", closeOnClickOutside: false)
        sticky.handleOutsideTap()
        XCTAssertTrue(sticky.show)
    }

    /// `zIndex` 上游类型是 `[String, Number]`。
    func testPopoverZIndexAcceptsStringAndNumber() {
        XCTAssertEqual(UPPopover(zIndex: "12000").zIndex, 12_000)
        XCTAssertEqual(UPPopover(zIndex: 20).zIndex, 20)
        XCTAssertEqual(UPPopover(zIndex: "40rpx").zIndex, 40)
        XCTAssertEqual(UPPopover(zIndex: "").zIndex, 10070)
    }

    /// `text` 上游类型是 `[String, Number]`。
    func testPopoverTextAcceptsNumbers() {
        XCTAssertEqual(UPPopover(text: 42).text, "42")
        XCTAssertEqual(UPPopover(text: 3.5).text, "3.5")
    }

    /// 插槽存在性对应上游 `$slots['trigger']` / `$slots['content']`。
    func testPopoverSlotDetection() {
        let bare = UPPopover(text: "提示")
        XCTAssertFalse(bare.hasTriggerSlot)
        XCTAssertFalse(bare.hasContentSlot)

        let withContent = bare.content { Text("自定义内容") }
        XCTAssertTrue(withContent.hasContentSlot)
        XCTAssertFalse(withContent.hasTriggerSlot)

        let withTrigger = UPPopover(text: "提示") { Text("点击") }
        XCTAssertTrue(withTrigger.hasTriggerSlot)
    }

    /// 上游 `bgColor && showTooltip` 才给兜底触发文本上底色。
    func testPopoverTriggerBackgroundOnlyWhenVisibleWithoutTriggerSlot() {
        XCTAssertEqual(UPPopover(show: true, text: "提示", triggerMode: "manual").resolvedTriggerBackground, "#f7f7f7")
        XCTAssertNil(UPPopover(text: "提示").resolvedTriggerBackground)
        XCTAssertNil(UPPopover(show: true, text: "提示", bgColor: "", triggerMode: "manual").resolvedTriggerBackground)
        XCTAssertNil(UPPopover(show: true, text: "提示", bgColor: "transparent", triggerMode: "manual").resolvedTriggerBackground)

        let slotted = UPPopover(show: true, triggerMode: "manual") { Text("点击") }
        XCTAssertNil(slotted.resolvedTriggerBackground)
    }

    /// 上游把 `placement` 透传给了没有该 prop 的 `u-tooltip`，真正定位靠 `direction`。
    func testPopoverPlacementIsRecordedButNotUsedForPositioning() {
        let popover = UPPopover(placement: "bottom", direction: "left")
        XCTAssertEqual(popover.placement, "bottom")
        XCTAssertEqual(popover.resolvedDirection, "left")
        XCTAssertEqual(popover.bubbleOffset, CGSize(width: -14, height: 0))

        XCTAssertEqual(UPPopover<EmptyView>.overlayAlignment(for: "top"), .top)
        XCTAssertEqual(UPPopover<EmptyView>.overlayAlignment(for: "bottom"), .bottom)
        XCTAssertEqual(UPPopover<EmptyView>.overlayAlignment(for: "left"), .leading)
        XCTAssertEqual(UPPopover<EmptyView>.overlayAlignment(for: "right"), .trailing)
        XCTAssertEqual(UPPopover<EmptyView>.overlayAlignment(for: "bottom-end"), .top)
    }
}
