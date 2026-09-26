import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class ButtonTests: XCTestCase {
    func testDefaults() {
        let button = UPButton()
        XCTAssertEqual(button.type, "info")
        XCTAssertEqual(button.size, "normal")
        XCTAssertEqual(button.shape, "square")
        XCTAssertFalse(button.plain)
        XCTAssertFalse(button.disabled)
        XCTAssertFalse(button.loading)
    }

    /// 上游 `baseColor`：默认 `type: "info"` 是「白底 + mainColor 文字 + 边框色」
    /// 的次要按钮，而非灰底。其余 type 为实心色底白字。
    func testResolvedColorsForInfoAndTypes() {
        let info = UPButton()
        XCTAssertEqual(info.resolvedBackgroundValue(isDark: false), "#ffffff")
        XCTAssertEqual(info.resolvedTextColorValue(isDark: false), "#303133")
        XCTAssertEqual(info.resolvedBorderColorValue(isDark: false), "#dadbde")

        let primary = UPButton(type: "primary")
        XCTAssertEqual(primary.resolvedBackgroundValue(isDark: false), "#3c9cff")
        XCTAssertEqual(primary.resolvedTextColorValue(isDark: false), "#ffffff")
        XCTAssertEqual(primary.resolvedBorderColorValue(isDark: false), "#3c9cff")

        let success = UPButton(type: "success")
        XCTAssertEqual(success.resolvedBackgroundValue(isDark: false), "#5ac725")
        // 未知 type 回落 info 语义。
        let unknown = UPButton(type: "weird")
        XCTAssertEqual(unknown.resolvedBackgroundValue(isDark: false), "#ffffff")
        XCTAssertEqual(unknown.resolvedTextColorValue(isDark: false), "#303133")
    }

    /// 上游 plain：透明底、文字/边框取类型色（info 用 mainColor/边框色）。
    func testResolvedColorsForPlain() {
        let plainPrimary = UPButton(type: "primary", plain: true)
        XCTAssertEqual(plainPrimary.resolvedBackgroundValue(isDark: false), "transparent")
        XCTAssertEqual(plainPrimary.resolvedTextColorValue(isDark: false), "#3c9cff")
        XCTAssertEqual(plainPrimary.resolvedBorderColorValue(isDark: false), "#3c9cff")

        let plainInfo = UPButton(plain: true)
        XCTAssertEqual(plainInfo.resolvedBackgroundValue(isDark: false), "transparent")
        XCTAssertEqual(plainInfo.resolvedTextColorValue(isDark: false), "#303133")
        XCTAssertEqual(plainInfo.resolvedBorderColorValue(isDark: false), "#dadbde")
    }

    /// 上游给了自定义 `color`：实心底用 color、文字白；plain 时透明底、文字取 color。
    func testResolvedColorsForExplicitColor() {
        let solid = UPButton(type: "primary", color: "#ff5500")
        XCTAssertEqual(solid.resolvedBackgroundValue(isDark: false), "#ff5500")
        XCTAssertEqual(solid.resolvedTextColorValue(isDark: false), "#ffffff")
        XCTAssertEqual(solid.resolvedBorderColorValue(isDark: false), "#ff5500")

        let plainColored = UPButton(plain: true, color: "#ff5500")
        XCTAssertEqual(plainColored.resolvedBackgroundValue(isDark: false), "transparent")
        XCTAssertEqual(plainColored.resolvedTextColorValue(isDark: false), "#ff5500")
    }

    /// 上游暗色回落：info 的白底/mainColor/边框在暗色分别为 #1c1c1e/#f5f5f5/#3a3a3c。
    func testResolvedColorsDarkFallback() {
        let info = UPButton()
        XCTAssertEqual(info.resolvedBackgroundValue(isDark: true), "#1c1c1e")
        XCTAssertEqual(info.resolvedTextColorValue(isDark: true), "#f5f5f5")
        XCTAssertEqual(info.resolvedBorderColorValue(isDark: true), "#3a3a3c")
    }

    /// 上游 `loadingColor`：plain 用 color/类型色；info 实心用 #c9c9c9(暗 #9ca3af)；
    /// 其余实心用 rgb(200, 200, 200)。
    func testResolvedLoadingColor() {
        XCTAssertEqual(UPButton(type: "primary").resolvedLoadingColorValue(isDark: false), "rgb(200, 200, 200)")
        XCTAssertEqual(UPButton().resolvedLoadingColorValue(isDark: false), "#c9c9c9")
        XCTAssertEqual(UPButton().resolvedLoadingColorValue(isDark: true), "#9ca3af")
        XCTAssertEqual(UPButton(type: "primary", plain: true).resolvedLoadingColorValue(isDark: false), "#3c9cff")
    }

    /// 上游 `iconColorCom`：显式 iconColor 优先；plain 取 color/类型色；
    /// 实心 info 用 mainColor、其余白色。
    func testResolvedIconColor() {
        XCTAssertEqual(UPButton(iconColor: "#123456").resolvedIconColorValue(isDark: false), "#123456")
        XCTAssertEqual(UPButton(type: "primary").resolvedIconColorValue(isDark: false), "#ffffff")
        XCTAssertEqual(UPButton().resolvedIconColorValue(isDark: false), "#303133")
        XCTAssertEqual(UPButton(type: "primary", plain: true).resolvedIconColorValue(isDark: false), "#3c9cff")
    }

    func testSizeHeights() {
        XCTAssertEqual(UPButton.height(for: "large"), 50)
        XCTAssertEqual(UPButton.height(for: "normal"), 40)
        XCTAssertEqual(UPButton.height(for: "small"), 30)
        XCTAssertEqual(UPButton.height(for: "mini"), 22)
        XCTAssertEqual(UPButton.height(for: "bad"), 40)
    }

    func testFontSizes() {
        XCTAssertEqual(UPButton.fontSize(for: "large"), 16)
        XCTAssertEqual(UPButton.fontSize(for: "normal"), 14)
        XCTAssertEqual(UPButton.fontSize(for: "small"), 12)
        XCTAssertEqual(UPButton.fontSize(for: "mini"), 10)
    }

    func testOnClickModifierRegistersHandler() {
        var callCount = 0
        let button = UPButton().onClick {
            callCount += 1
        }

        button.onClick?()
        XCTAssertEqual(callCount, 1)
    }

    func testDefaultSlotInitializerAcceptsCustomSwiftUIView() {
        let button = UPButton {
            Text("Custom label")
        }

        XCTAssertTrue(button.hasDefaultSlot)
    }

    func testStringAndNumberPropsAreNormalizedLikeUpstreamValues() {
        let button = UPButton(
            loadingText: 404,
            loadingSize: "18.5",
            throttleTime: "600",
            hoverStartTime: "25",
            hoverStayTime: 240,
            text: 7
        )

        XCTAssertEqual(button.loadingText, "404")
        XCTAssertEqual(button.loadingSize, 18.5)
        XCTAssertEqual(button.throttleTime, 600)
        XCTAssertEqual(button.hoverStartTime, 25)
        XCTAssertEqual(button.hoverStayTime, 240)
        XCTAssertEqual(button.text, "7")
    }

    func testNativeHostCanForwardOpenCapabilityEvents() {
        var events: [UPButtonOpenCapability] = []
        let button = UPButton(
            onGetPhoneNumber: { events.append(.getPhoneNumber) },
            onGetUserInfo: { events.append(.getUserInfo) },
            onError: { events.append(.error) },
            onOpenSetting: { events.append(.openSetting) },
            onLaunchApp: { events.append(.launchApp) },
            onAgreePrivacyAuthorization: { events.append(.agreePrivacyAuthorization) }
        )

        UPButtonOpenCapability.allCases.forEach(button.triggerOpenCapability)

        XCTAssertEqual(events, UPButtonOpenCapability.allCases)
    }

    func testThrottleAllowsLeadingTapRejectsTapInsideIntervalAndAllowsBoundary() {
        var throttle = UPButtonTapThrottle()
        let firstTap = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertTrue(throttle.acceptsTap(at: firstTap, throttleTime: 500))
        XCTAssertFalse(throttle.acceptsTap(at: firstTap.addingTimeInterval(0.499), throttleTime: 500))
        XCTAssertTrue(throttle.acceptsTap(at: firstTap.addingTimeInterval(0.5), throttleTime: 500))
    }
}
