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

    /// 上游 `resolvedActiveColor`/`resolvedInactiveColor`：默认 #1989fa 映射主题
    /// primary(#3c9cff)、默认 #7d7e80 映射 content(#606266)；显式非默认色原样用。
    func testTabbarResolvedThemeColors() {
        let def = UPTabbar(items: [UPTabbarItem(name: "a", text: "A")])
        XCTAssertEqual(def.resolvedActiveColorValue(), "#3c9cff")
        XCTAssertEqual(def.resolvedInactiveColorValue(), "#606266")

        let custom = UPTabbar(items: [UPTabbarItem(name: "a", text: "A")],
                              activeColor: "#ff0000", inactiveColor: "#00ff00")
        XCTAssertEqual(custom.resolvedActiveColorValue(), "#ff0000")
        XCTAssertEqual(custom.resolvedInactiveColorValue(), "#00ff00")
    }

    /// 上游 `itemInlineStyle.backgroundColor`：激活/未激活分别取对应背景，空则透明。
    func testTabbarItemBackgroundValue() {
        let def = UPTabbar(items: [UPTabbarItem(name: "a", text: "A")])
        XCTAssertEqual(def.itemBackgroundValue(active: true), "transparent")
        XCTAssertEqual(def.itemBackgroundValue(active: false), "transparent")

        let bg = UPTabbar(items: [UPTabbarItem(name: "a", text: "A")],
                          activeBackgroundColor: "#eef", inactiveBackgroundColor: "#f5f5f5")
        XCTAssertEqual(bg.itemBackgroundValue(active: true), "#eef")
        XCTAssertEqual(bg.itemBackgroundValue(active: false), "#f5f5f5")
    }

    /// 上游 `textMode`：none 隐藏文字；active 时仅激活项显示（其余静音）。
    func testTabbarTextModeSemantics() {
        XCTAssertTrue(UPTabbar(items: [UPTabbarItem(name: "a", text: "A")]).showsText)
        XCTAssertFalse(UPTabbar(items: [UPTabbarItem(name: "a", text: "A")], textMode: "none").showsText)

        let activeMode = UPTabbar(items: [UPTabbarItem(name: "a", text: "A")], textMode: "active")
        XCTAssertTrue(activeMode.isTextMuted(active: false))
        XCTAssertFalse(activeMode.isTextMuted(active: true))
        // always 模式从不静音。
        XCTAssertFalse(UPTabbar(items: [UPTabbarItem(name: "a", text: "A")]).isTextMuted(active: false))
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
