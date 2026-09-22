import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TabsProDefaultsTests: XCTestCase {
    func testDefaultsMatchUpstreamProps() {
        let pro = UPTabsPro()

        XCTAssertTrue(pro.list.isEmpty)
        XCTAssertEqual(pro.keyName, "name")
        XCTAssertEqual(pro.current, 0)
        XCTAssertEqual(pro.contentMode, "static")
        XCTAssertEqual(pro.lineColor, "")
        XCTAssertEqual(pro.lineWidth, 20)
        XCTAssertEqual(pro.lineHeight, 3)
        XCTAssertEqual(pro.lineBgSize, "cover")
        XCTAssertEqual(pro.itemStyle, UPStyle(["height": "44px"]))
        XCTAssertTrue(pro.scrollable)
        XCTAssertEqual(pro.duration, 300)
        XCTAssertEqual(pro.iconStyle, UPStyle())
        XCTAssertEqual(pro.shapeMode, "")
        XCTAssertTrue(pro.showContent)
        XCTAssertEqual(pro.contentClass, "")
        XCTAssertEqual(pro.contentStyle, UPStyle())
        XCTAssertEqual(pro.bindIndexRef, "")
        XCTAssertEqual(pro.customClass, "")
        XCTAssertEqual(pro.customStyle, UPStyle())
    }

    /// 上游 `u-tabs-pro` 把 `activeStyle`/`inactiveStyle` 默认成 `{}` 并显式下传，
    /// 于是 `u-tabs` 自己的 `#303133`/`#606266` 默认值被空对象覆盖。照抄该行为。
    func testEmptyActiveAndInactiveStyleOverrideTabsDefaults() {
        let pro = UPTabsPro()

        XCTAssertEqual(pro.activeStyle, UPStyle())
        XCTAssertEqual(pro.inactiveStyle, UPStyle())
        XCTAssertEqual(pro.innerTabs.activeStyle, UPStyle())
        XCTAssertEqual(pro.innerTabs.inactiveStyle, UPStyle())
        XCTAssertEqual(UPTabs().activeStyle, UPStyle(["color": "#303133"]))
        XCTAssertEqual(UPTabs().inactiveStyle, UPStyle(["color": "#606266"]))
    }

    func testResolvedLineColorIsNilWhenBlank() {
        let pro = UPTabsPro()

        XCTAssertNil(pro.resolvedLineColor)
        XCTAssertEqual(pro.innerTabs.lineColor, "")
    }

    func testResolvedLineColorKeepsCustomValue() {
        let pro = UPTabsPro(lineColor: "#ff0000")

        XCTAssertEqual(pro.resolvedLineColor, "#ff0000")
        XCTAssertEqual(pro.innerTabs.lineColor, "#ff0000")
    }

    func testInnerTabsForwardsRemainingProps() {
        let pro = UPTabsPro(
            list: [UPTabsItem(name: "推荐")], duration: 120,
            lineWidth: 30, lineHeight: 6, lineBgSize: "contain",
            itemStyle: UPStyle(["height": "60px"]), scrollable: false,
            keyName: "badge", iconStyle: UPStyle(["color": "#3c9cff"]), shapeMode: "circle"
        )
        let tabs = pro.innerTabs

        XCTAssertEqual(tabs.list.map(\.name), ["推荐"])
        XCTAssertEqual(tabs.duration, 120)
        XCTAssertEqual(tabs.lineWidth, 30)
        XCTAssertEqual(tabs.lineHeight, 6)
        XCTAssertEqual(tabs.lineBgSize, "contain")
        XCTAssertEqual(tabs.itemStyle, UPStyle(["height": "60px"]))
        XCTAssertFalse(tabs.scrollable)
        XCTAssertEqual(tabs.keyName, "badge")
        XCTAssertEqual(tabs.iconStyle, UPStyle(["color": "#3c9cff"]))
        XCTAssertEqual(tabs.shapeMode, "circle")
    }

    /// `contentMode` 与 `bindIndexRef` 在上游只被声明，模板和逻辑都没有引用，
    /// 因此不建模行为，只保留元数据并用测试固定。
    func testDeclaredOnlyPropNamesAreRetainedAsMetadata() {
        XCTAssertEqual(UPTabsPro<EmptyView>.declaredOnlyPropNames, ["bindIndexRef", "contentMode"])

        let pro = UPTabsPro(contentMode: "swiper", contentClass: "my-content", bindIndexRef: "tabRef")
        XCTAssertEqual(pro.contentMode, "swiper")
        XCTAssertEqual(pro.contentClass, "my-content")
        XCTAssertEqual(pro.bindIndexRef, "tabRef")
    }
}

@MainActor
final class TabsProCurrentTests: XCTestCase {
    private let items = [UPTabsItem(name: "推荐"), UPTabsItem(name: "关注"), UPTabsItem(name: "热榜")]

    func testNormalizeCurrentClampsToListBounds() {
        let pro = UPTabsPro(list: items)

        XCTAssertEqual(pro.normalizeCurrent(-1), 0)
        XCTAssertEqual(pro.normalizeCurrent(1), 1)
        XCTAssertEqual(pro.normalizeCurrent(5), 2)
    }

    func testNormalizeCurrentReturnsZeroForEmptyList() {
        XCTAssertEqual(UPTabsPro().normalizeCurrent(3), 0)
        XCTAssertEqual(UPTabsPro().resolvedCurrent, 0)
    }

    func testCurrentPropIsClampedIntoResolvedCurrent() {
        XCTAssertEqual(UPTabsPro(list: items, current: 5).resolvedCurrent, 2)
        XCTAssertEqual(UPTabsPro(list: items, current: -2).resolvedCurrent, 0)
    }

    func testBindingDrivesResolvedCurrent() {
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding)

        box.value = 2
        XCTAssertEqual(pro.resolvedCurrent, 2)

        box.value = 9
        XCTAssertEqual(pro.resolvedCurrent, 2)
    }

    /// 上游 `updateCurrent` 无论值是否变化都会 emit `update:current`。
    func testUpdateCurrentAlwaysEmitsEvenWhenUnchanged() {
        var emitted: [Int] = []
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding).onUpdateCurrent { emitted.append($0) }

        pro.updateCurrent(0)

        XCTAssertEqual(emitted, [0])
        XCTAssertEqual(box.value, 0)
    }

    func testUpdateCurrentNormalizesAndWritesBackToBinding() {
        var emitted: [Int] = []
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding).onUpdateCurrent { emitted.append($0) }

        pro.updateCurrent(9)
        pro.updateCurrent(-4)

        XCTAssertEqual(emitted, [2, 0])
        XCTAssertEqual(box.value, 0)
    }

    func testUncontrolledUpdateCurrentTracksInternalState() {
        let pro = UPTabsPro(list: items, current: 0)

        pro.updateCurrent(2)

        XCTAssertEqual(pro.resolvedCurrent, 2)
    }

    /// 上游 `list` deep watch：clamp 后的值与原值不同才回写并 emit。
    func testSyncListEmitsUpdateCurrentWhenClampChanges() {
        var emitted: [Int] = []
        let box = NavigationIntBox(2)
        let pro = UPTabsPro(list: [items[0], items[1]], current: box.binding)
            .onUpdateCurrent { emitted.append($0) }

        XCTAssertTrue(pro.syncList())
        XCTAssertEqual(emitted, [1])
        XCTAssertEqual(box.value, 1)
    }

    func testSyncListReturnsFalseWhenClampUnchanged() {
        var emitted: [Int] = []
        let box = NavigationIntBox(1)
        let pro = UPTabsPro(list: items, current: box.binding).onUpdateCurrent { emitted.append($0) }

        XCTAssertFalse(pro.syncList())
        XCTAssertTrue(emitted.isEmpty)
        XCTAssertEqual(box.value, 1)
    }
}

@MainActor
final class TabsProEventTests: XCTestCase {
    private let items = [UPTabsItem(name: "推荐"), UPTabsItem(name: "关注"), UPTabsItem(name: "禁用", disabled: true)]

    /// 上游 `u-tabs` 点击时先 emit `update:current` 再 emit `change`，而 `u-tabs-pro`
    /// 同时绑定了这两个事件、且 `changeHandler` 内部又调了一次 `updateCurrent`，
    /// 于是每次点击会 emit 两次 `update:current`。照抄该顺序与次数。
    func testSelectEmitsClickThenTwoUpdateCurrentThenChange() {
        var log: [String] = []
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding)
            .onClick { log.append("click:\($0.index)") }
            .onUpdateCurrent { log.append("update:\($0)") }
            .onChange { log.append("change:\($0.index)") }

        pro.select(1)

        XCTAssertEqual(log, ["click:1", "update:1", "update:1", "change:1"])
        XCTAssertEqual(box.value, 1)
        XCTAssertEqual(pro.resolvedCurrent, 1)
    }

    func testDisabledTabEmitsClickOnly() {
        var log: [String] = []
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding)
            .onClick { log.append("click:\($0.index)") }
            .onUpdateCurrent { log.append("update:\($0)") }
            .onChange { log.append("change:\($0.index)") }

        pro.select(2)

        XCTAssertEqual(log, ["click:2"])
        XCTAssertEqual(box.value, 0)
    }

    func testSelectingCurrentTabEmitsClickOnly() {
        var log: [String] = []
        let box = NavigationIntBox(1)
        let pro = UPTabsPro(list: items, current: box.binding)
            .onClick { log.append("click:\($0.index)") }
            .onUpdateCurrent { log.append("update:\($0)") }
            .onChange { log.append("change:\($0.index)") }

        pro.select(1)

        XCTAssertEqual(log, ["click:1"])
        XCTAssertEqual(box.value, 1)
    }

    func testSelectOutOfRangeEmitsNothing() {
        var log: [String] = []
        let pro = UPTabsPro(list: items, current: 0)
            .onClick { log.append("click:\($0.index)") }
            .onUpdateCurrent { log.append("update:\($0)") }
            .onChange { log.append("change:\($0.index)") }

        pro.select(9)

        XCTAssertTrue(log.isEmpty)
        XCTAssertEqual(pro.resolvedCurrent, 0)
    }

    func testLongPressForwardsWithoutChangingCurrent() {
        var events: [UPTabsEvent] = []
        var updated: [Int] = []
        let box = NavigationIntBox(0)
        let pro = UPTabsPro(list: items, current: box.binding)
            .onLongPress { events.append($0) }
            .onUpdateCurrent { updated.append($0) }

        pro.longPress(1)

        XCTAssertEqual(events, [UPTabsEvent(item: items[1], index: 1)])
        XCTAssertTrue(updated.isEmpty)
        XCTAssertEqual(box.value, 0)
    }

    func testChangeHandlerUpdatesCurrentBeforeEmittingChange() {
        var log: [String] = []
        let pro = UPTabsPro(list: items, current: 0)
            .onUpdateCurrent { log.append("update:\($0)") }
            .onChange { log.append("change:\($0.index)") }

        pro.handleChange(UPTabsEvent(item: items[1], index: 1))

        XCTAssertEqual(log, ["update:1", "change:1"])
        XCTAssertEqual(pro.resolvedCurrent, 1)
    }
}

@MainActor
final class TabsProContentTests: XCTestCase {
    private let items = [UPTabsItem(name: "推荐"), UPTabsItem(name: "关注", badge: "3", icon: "chat")]

    func testContentContextExposesCurrentItemValueAndList() {
        let context = UPTabsPro(list: items, current: 1).contentContext

        XCTAssertEqual(context.current, 1)
        XCTAssertEqual(context.index, 1)
        XCTAssertEqual(context.item, items[1])
        XCTAssertEqual(context.value, "关注")
        XCTAssertEqual(context.list, items)
    }

    func testCurrentItemAndValueAreNilForEmptyList() {
        let pro = UPTabsPro()

        XCTAssertNil(pro.currentItem)
        XCTAssertNil(pro.currentValue)
        XCTAssertNil(pro.contentContext.item)
    }

    func testCurrentValueFollowsKeyName() {
        XCTAssertEqual(UPTabsPro(list: items, current: 1, keyName: "badge").currentValue, "3")
        XCTAssertEqual(UPTabsPro(list: items, current: 1, keyName: "icon").currentValue, "chat")
    }

    /// `UPTabsItem` 只有 String 型成员可被 `keyName` 寻址，其余键返回 nil。
    func testCurrentValueIsNilForUnsupportedKeyName() {
        XCTAssertNil(UPTabsPro(list: items, current: 1, keyName: "disabled").currentValue)
        XCTAssertNil(UPTabsPro(list: items, current: 1, keyName: "").currentValue)
    }

    func testShowContentAndContentStyleAreRetained() {
        let pro = UPTabsPro(showContent: false, contentStyle: UPStyle(["padding": "12px"]))

        XCTAssertFalse(pro.showContent)
        XCTAssertEqual(pro.contentStyle, UPStyle(["padding": "12px"]))
    }

    func testContentBuilderReceivesResolvedContext() {
        var seen: UPTabsProContentContext?
        let pro = UPTabsPro(list: items, current: 1) { context in
            Text(context.value ?? "")
        }
        seen = pro.contentContext

        XCTAssertEqual(seen?.value, "关注")
        XCTAssertEqual(seen?.index, 1)
    }

    func testTabsProIsAValueTypeView() {
        let displayStyle = Mirror(reflecting: UPTabsPro(list: items)).displayStyle
        XCTAssertTrue(displayStyle == .struct || displayStyle == .enum)
    }
}
