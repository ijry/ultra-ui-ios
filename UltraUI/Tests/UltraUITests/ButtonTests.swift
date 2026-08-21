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
