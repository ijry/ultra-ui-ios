import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TabsTests: XCTestCase {
    func testTabsDefaultsMatchUpstreamAndSelectionUpdatesBinding() {
        let current = NavigationIntBox(0)
        var events: [UPTabsEvent] = []
        let tabs = UPTabs(
            list: [UPTabsItem(name: "推荐"), UPTabsItem(name: "关注")],
            current: current.binding
        ).onChange { events.append($0) }

        XCTAssertEqual(tabs.duration, 300)
        XCTAssertEqual(tabs.lineWidth, 20)
        XCTAssertEqual(tabs.lineHeight, 3)
        XCTAssertTrue(tabs.scrollable)
        XCTAssertEqual(tabs.keyName, "name")

        tabs.select(1)
        XCTAssertEqual(current.value, 1)
        XCTAssertEqual(events, [UPTabsEvent(item: tabs.list[1], index: 1)])
    }

    func testDisabledTabStillClicksButDoesNotChange() {
        let current = NavigationIntBox(0)
        var clicked: [Int] = []
        var changed: [Int] = []
        let tabs = UPTabs(
            list: [UPTabsItem(name: "可用"), UPTabsItem(name: "禁用", disabled: true)],
            current: current.binding
        )
        .onClick { clicked.append($0.index) }
        .onChange { changed.append($0.index) }

        tabs.select(1)

        XCTAssertEqual(clicked, [1])
        XCTAssertTrue(changed.isEmpty)
        XCTAssertEqual(current.value, 0)
    }

    func testTabsItemRetainsBadgeIconAndSlotCompatibleMetadata() {
        let item = UPTabsItem(name: "消息", badge: "3", icon: "chat", disabled: true)
        XCTAssertEqual(item.name, "消息")
        XCTAssertEqual(item.badge, "3")
        XCTAssertEqual(item.icon, "chat")
        XCTAssertTrue(item.disabled)
    }

    func testTabsAcceptsStringListAndTracksExternalBinding() {
        let current = NavigationIntBox(0)
        let tabs = UPTabs(list: ["推荐", "关注"], current: current.binding)

        current.value = 1

        XCTAssertEqual(tabs.list.map(\.name), ["推荐", "关注"])
        XCTAssertEqual(tabs.selectedIndex, 1)
    }

    func testUncontrolledTabsSelectionUpdatesAfterSelect() {
        let tabs = UPTabs(list: ["推荐", "关注"])

        tabs.select(1)

        XCTAssertEqual(tabs.selectedIndex, 1)
    }
}

@MainActor
final class NavigationIntBox {
    var value: Int
    init(_ value: Int) { self.value = value }
    var binding: Binding<Int> { Binding(get: { self.value }, set: { self.value = $0 }) }
}
