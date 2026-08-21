import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TabbarTests: XCTestCase {
    func testTabbarDefaultsAndSelectionSemantics() {
        let value = NavigationStringBox("home")
        var changes: [String] = []
        let tabbar = UPTabbar(
            items: [
                UPTabbarItem(name: "home", icon: "home", text: "首页"),
                UPTabbarItem(name: "mine", icon: "account", text: "我的")
            ],
            value: value.binding
        ).onChange { changes.append($0) }

        XCTAssertTrue(tabbar.safeAreaInsetBottom)
        XCTAssertTrue(tabbar.border)
        XCTAssertTrue(tabbar.fixed)
        XCTAssertTrue(tabbar.placeholder)
        XCTAssertEqual(tabbar.activeColor, "#1989fa")
        XCTAssertEqual(tabbar.inactiveColor, "#7d7e80")

        tabbar.select("mine")
        tabbar.select("mine")
        XCTAssertEqual(value.value, "mine")
        XCTAssertEqual(changes, ["mine"])
    }

    func testTabbarItemClickAndMidButtonProps() {
        var clicks: [String] = []
        let item = UPTabbarItem(
            name: "add", icon: "plus", badge: "9", dot: false, text: "发布",
            mode: "midButton", midButtonIconSize: 30, midButtonOffsetY: -12
        ).onClick { clicks.append($0) }

        XCTAssertEqual(item.badge, "9")
        XCTAssertEqual(item.midButtonIconSize, 30)
        XCTAssertEqual(item.midButtonOffsetY, -12)
        item.triggerClick()
        XCTAssertEqual(clicks, ["add"])
    }

    func testTabbarAcceptsUncontrolledValueAndEmitsStructuredChange() {
        var changes: [UPTabbarChange] = []
        let tabbar = UPTabbar(
            items: [
                UPTabbarItem(name: "home", text: "首页"),
                UPTabbarItem(name: "mine", text: "我的")
            ],
            value: "home"
        ).onChangePayload { changes.append($0) }

        tabbar.select("mine")
        tabbar.select("missing")

        XCTAssertEqual(tabbar.selectedValue, "mine")
        XCTAssertEqual(changes, [UPTabbarChange(name: "mine", index: 1)])
    }
}

@MainActor
private final class NavigationStringBox {
    var value: String
    init(_ value: String) { self.value = value }
    var binding: Binding<String> { Binding(get: { self.value }, set: { self.value = $0 }) }
}
