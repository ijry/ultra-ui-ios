import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class NavbarScrollStickyTests: XCTestCase {
    func testNavbarDefaultsDimensionsAndEvents() {
        var events: [String] = []
        let navbar = UPNavbar(title: "详情")
            .onLeftClick { events.append("left") }
            .onRightClick { events.append("right") }

        XCTAssertTrue(navbar.safeAreaInsetTop)
        XCTAssertTrue(navbar.fixed)
        XCTAssertFalse(navbar.placeholder)
        XCTAssertEqual(navbar.leftIcon, "arrow-left")
        XCTAssertEqual(navbar.resolvedHeight, 44)
        XCTAssertEqual(navbar.resolvedTitleWidth, 400)

        navbar.triggerLeftClick()
        navbar.triggerRightClick()
        XCTAssertEqual(events, ["left", "right"])
    }

    func testNavbarMiniMatchesUpstreamDefaults() {
        var clicks = 0
        let navbar = UPNavbarMini().onLeftClick { clicks += 1 }
        XCTAssertTrue(navbar.safeAreaInsetTop)
        XCTAssertTrue(navbar.fixed)
        XCTAssertEqual(navbar.leftIcon, "arrow-leftward")
        XCTAssertEqual(navbar.resolvedHeight, 32)
        XCTAssertEqual(navbar.resolvedIconSize, 20)
        XCTAssertTrue(navbar.autoBack)
        navbar.triggerLeftClick()
        XCTAssertEqual(clicks, 1)
    }

    /// 上游 `emits: ["leftClick", "homeClick"]`，右半区点击走 `homeClick`。
    func testNavbarMiniEmitsHomeClickAndExposesSlots() {
        var homeClicks = 0
        let navbar = UPNavbarMini(homeUrl: "/pages/index/index")
            .onHomeClick { homeClicks += 1 }
        XCTAssertEqual(navbar.homeUrl, "/pages/index/index")
        XCTAssertFalse(navbar.hasLeftSlot)
        XCTAssertFalse(navbar.hasCenterSlot)

        navbar.triggerHomeClick()
        XCTAssertEqual(homeClicks, 1)

        let slotted = navbar
            .left { Text("back") }
            .center { Text("home") }
        XCTAssertTrue(slotted.hasLeftSlot)
        XCTAssertTrue(slotted.hasCenterSlot)
    }

    /// 上游 `navbarBgColor`/`navbarTitleColor`/`navbarLeftIconColor`/`navbarRightColor`
    /// 未显式设色时分别回落到 `#ffffff` 与 `#303133`（mainColor）。
    func testNavbarResolvesUpstreamColorFallbacks() {
        let navbar = UPNavbar(title: "详情")
        XCTAssertEqual(navbar.resolvedBgColorValue, "#ffffff")
        XCTAssertEqual(navbar.resolvedTitleColorValue, "#303133")
        XCTAssertEqual(navbar.resolvedLeftIconColorValue, "#303133")
        XCTAssertEqual(navbar.resolvedRightColorValue, "#303133")
    }

    func testNavbarHonoursExplicitColors() {
        let navbar = UPNavbar(
            title: "详情", titleColor: "#ff0000", bgColor: "#000000", leftIconColor: "#00ff00"
        )
        XCTAssertEqual(navbar.resolvedBgColorValue, "#000000")
        XCTAssertEqual(navbar.resolvedTitleColorValue, "#ff0000")
        XCTAssertEqual(navbar.resolvedLeftIconColorValue, "#00ff00")
        // 右侧颜色上游恒为 mainColor，不受 leftIconColor 影响。
        XCTAssertEqual(navbar.resolvedRightColorValue, "#303133")
    }

    /// 上游 `statusBarBgColor` 为空时回落到 `bgColor`（再回落到 navbarBgColor）。
    func testNavbarStatusBarColorFallsBackToBackground() {
        XCTAssertEqual(UPNavbar(title: "详情").resolvedStatusBarColorValue, "#ffffff")
        XCTAssertEqual(UPNavbar(title: "详情", bgColor: "#123456").resolvedStatusBarColorValue, "#123456")
        XCTAssertEqual(
            UPNavbar(title: "详情", bgColor: "#123456", statusBarBgColor: "#abcdef").resolvedStatusBarColorValue,
            "#abcdef"
        )
    }

    /// 上游右侧区域 `v-if="$slots.right || rightIcon || rightText"`。
    func testNavbarRightAreaVisibility() {
        XCTAssertFalse(UPNavbar(title: "详情").showsRightArea)
        XCTAssertTrue(UPNavbar(rightText: "更多", title: "详情").showsRightArea)
        XCTAssertTrue(UPNavbar(rightIcon: "more-dot-fill", title: "详情").showsRightArea)
        XCTAssertTrue(UPNavbar(title: "详情").right { Text("s") }.showsRightArea)
    }

    /// 上游占位块 `v-if="fixed && placeholder"`。
    func testNavbarPlaceholderVisibility() {
        XCTAssertFalse(UPNavbar(title: "详情").showsPlaceholder)
        XCTAssertFalse(UPNavbar(placeholder: true, fixed: false, title: "详情").showsPlaceholder)
        XCTAssertTrue(UPNavbar(placeholder: true, fixed: true, title: "详情").showsPlaceholder)
    }

    func testNavbarExposesSlots() {
        let navbar = UPNavbar(title: "详情")
        XCTAssertFalse(navbar.hasLeftSlot)
        XCTAssertFalse(navbar.hasCenterSlot)
        XCTAssertFalse(navbar.hasRightSlot)
        let slotted = navbar
            .left { Text("l") }
            .center { Text("c") }
            .right { Text("r") }
        XCTAssertTrue(slotted.hasLeftSlot)
        XCTAssertTrue(slotted.hasCenterSlot)
        XCTAssertTrue(slotted.hasRightSlot)
    }

    /// 上游 `leftClick` 先 `$emit`，无拦截器时按 `autoBack` 决定是否 `navigateBack`。
    func testNavbarLeftClickTriggersAutoBack() {
        var backs = 0
        let navbar = UPNavbar(title: "详情", autoBack: true)
            .onNavigateBack { backs += 1 }
        navbar.triggerLeftClick()
        XCTAssertEqual(backs, 1)

        var noBacks = 0
        let noAuto = UPNavbar(title: "详情", autoBack: false)
            .onNavigateBack { noBacks += 1 }
        noAuto.triggerLeftClick()
        XCTAssertEqual(noBacks, 0)
    }

    func testScrollListCalculatesIndicatorAndBoundaryEvents() {
        var events: [String] = []
        let list = UPScrollList(contentWidth: 500, viewportWidth: 200)
            .onLeft { events.append("left") }
            .onRight { events.append("right") }

        XCTAssertEqual(list.indicatorWidth, 50)
        XCTAssertEqual(list.indicatorBarWidth, 20)
        XCTAssertEqual(list.indicatorOffset(scrollOffset: 150), 15, accuracy: 0.001)
        list.reportScroll(offset: 0)
        list.reportScroll(offset: 300)
        XCTAssertEqual(events, ["left", "right"])
    }

    /// 上游 `libs/config/props/scrollList.js`：`indicatorWidth: 50`、
    /// `indicatorBarWidth: 20`、`indicator: true`、`indicatorColor: '#f2f2f2'`、
    /// `indicatorActiveColor: '#3c9cff'`、`indicatorStyle: ''`。
    func testScrollListPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.scrollList.indicatorWidth, "50")
        XCTAssertEqual(UPConfig.scrollList.indicatorBarWidth, "20")
        XCTAssertTrue(UPConfig.scrollList.indicator)
        XCTAssertEqual(UPConfig.scrollList.indicatorColor, "#f2f2f2")
        XCTAssertEqual(UPConfig.scrollList.indicatorActiveColor, "#3c9cff")

        let list = UPScrollList()
        XCTAssertEqual(list.indicatorWidth, 50)
        XCTAssertEqual(list.indicatorBarWidth, 20)
        XCTAssertTrue(list.indicator)
        XCTAssertEqual(list.indicatorColor, "#f2f2f2")
        XCTAssertEqual(list.indicatorActiveColor, "#3c9cff")
        XCTAssertTrue(list.indicatorStyle.properties.isEmpty)
        // 上游 barAllMoveWidth = indicatorWidth - indicatorBarWidth。
        XCTAssertEqual(list.barTravel, 30)
        XCTAssertEqual(list.scrollLeft, 0)
    }

    /// 上游 `scrolltoupperHandler` / `scrolltolowerHandler` 除了抛事件，还会改写 scrollLeft。
    func testScrollListEdgeHandlersAdjustScrollLeft() {
        var events: [String] = []
        let list = UPScrollList(contentWidth: 500, viewportWidth: 200)
            .onLeft { events.append("left") }
            .onRight { events.append("right") }

        list.scrollHandler(scrollLeft: 120)
        XCTAssertEqual(list.scrollLeft, 120)

        list.scrollToUpper()
        XCTAssertEqual(events, ["left"])
        XCTAssertEqual(list.scrollLeft, 0)

        list.scrollToLower()
        XCTAssertEqual(events, ["left", "right"])
        // 照抄上游：这里塞的是指示器坐标系的 indicatorWidth - indicatorBarWidth。
        XCTAssertEqual(list.scrollLeft, 30)
    }

    /// 上游 `barStyle` 的比例公式；容器宽由 `getComponentWidth()` 量到。
    func testScrollListIndicatorOffsetUsesMeasuredWidths() {
        let list = UPScrollList()
        // 还没量到宽度时没有可滚动距离，位移恒为 0。
        XCTAssertEqual(list.indicatorOffset(scrollOffset: 100), 0)

        list.scrollHandler(scrollLeft: 0, scrollWidth: 500)
        list.recordComponentWidth(200)
        XCTAssertEqual(list.indicatorOffset(scrollOffset: 150), 15, accuracy: 0.001)
        // 超出范围会被夹到满格。
        XCTAssertEqual(list.indicatorOffset(scrollOffset: 1_000), 30, accuracy: 0.001)
        XCTAssertEqual(list.indicatorOffset(scrollOffset: -50), 0, accuracy: 0.001)
    }

    func testStickyResolvesNativePinOffsetAndChangePayload() {
        var payloads: [UPStickyChange] = []
        let sticky = UPSticky(offsetTop: 12, customNavHeight: 44, index: "section-2")
            .onFixed { payloads.append($0) }

        XCTAssertFalse(sticky.disabled)
        XCTAssertEqual(sticky.pinOffset, 56)
        XCTAssertFalse(sticky.isFixed(minY: 57))
        XCTAssertTrue(sticky.isFixed(minY: 55))
        sticky.report(minY: 55)
        XCTAssertEqual(payloads, [UPStickyChange(index: "section-2", isFixed: true)])
    }

    /// 上游 `libs/config/props/sticky.js`：`offsetTop: 0`、`customNavHeight: 0`、
    /// `disabled: false`、`bgColor: 'transparent'`、`zIndex: ''`、`index: ''`。
    func testStickyPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.sticky.offsetTop, "0")
        XCTAssertEqual(UPConfig.sticky.customNavHeight, "0")
        XCTAssertFalse(UPConfig.sticky.disabled)
        XCTAssertEqual(UPConfig.sticky.bgColor, "transparent")
        XCTAssertEqual(UPConfig.sticky.zIndex, "")
        XCTAssertEqual(UPConfig.sticky.index, "")
        // H5 端 customNavHeight 默认 44。
        XCTAssertEqual(UPConfig.sticky.h5CustomNavHeight, 44)

        let sticky = UPSticky()
        XCTAssertEqual(sticky.offsetTop, 0)
        XCTAssertEqual(sticky.customNavHeight, 0)
        XCTAssertFalse(sticky.disabled)
        XCTAssertEqual(sticky.bgColor, "transparent")
        XCTAssertEqual(sticky.zIndex, "")
        XCTAssertEqual(sticky.index, "")
        XCTAssertEqual(sticky.stickyTop, 0)
        // 上游 uZindex：zIndex 为假值时回落 zIndex.sticky（970）。
        XCTAssertEqual(sticky.resolvedZIndex, 970)
        XCTAssertEqual(UPSticky(zIndex: 1_200).resolvedZIndex, 1_200)
        XCTAssertFalse(sticky.fixed)
        XCTAssertNil(sticky.placeholderHeight)
    }

    /// 上游 `setFixed(top)` 只在跨过阈值时改标记；`disabled` 时恒不吸顶。
    func testStickySetFixedTogglesAtThreshold() {
        var payloads: [UPStickyChange] = []
        let sticky = UPSticky(offsetTop: 10, customNavHeight: 20, index: "a")
            .onFixed { payloads.append($0) }
        XCTAssertEqual(sticky.stickyTop, 30)

        sticky.setFixed(top: 40)
        XCTAssertFalse(sticky.fixed)
        // 状态没变时不重复抛事件。
        XCTAssertTrue(payloads.isEmpty)

        sticky.setFixed(top: 30)
        XCTAssertTrue(sticky.fixed)
        XCTAssertEqual(payloads, [UPStickyChange(index: "a", isFixed: true)])

        sticky.setFixed(top: 30)
        XCTAssertEqual(payloads.count, 1)

        sticky.setFixed(top: 100)
        XCTAssertFalse(sticky.fixed)
        XCTAssertEqual(payloads.count, 2)

        let disabled = UPSticky(offsetTop: 10, disabled: true)
        disabled.setFixed(top: -100)
        XCTAssertFalse(disabled.fixed)
    }

    /// 上游 js 模式会把量到的宽高回填给父元素，防止吸顶时塌陷。
    func testStickyRecordsContentSizeForPlaceholder() {
        let sticky = UPSticky(offsetTop: 0, index: "a")
        XCTAssertNil(sticky.contentWidth)

        sticky.recordContentSize(CGSize(width: 320, height: 48), left: 12)
        XCTAssertEqual(sticky.contentWidth, 320)
        // 未吸顶时上游给父元素的是 auto，原生返回 nil。
        XCTAssertNil(sticky.placeholderHeight)

        sticky.report(minY: -10)
        XCTAssertTrue(sticky.fixed)
        XCTAssertEqual(sticky.placeholderHeight, 48)
    }
}
