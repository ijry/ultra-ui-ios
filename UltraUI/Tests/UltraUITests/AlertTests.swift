import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class AlertTests: XCTestCase {
    func testDefaultsMatchUviewPlusAlert() {
        let alert = UPAlert()

        XCTAssertEqual(alert.title, "")
        XCTAssertEqual(alert.type, "warning")
        XCTAssertEqual(alert.description, "")
        XCTAssertFalse(alert.closable)
        XCTAssertFalse(alert.showIcon)
        XCTAssertEqual(alert.effect, "light")
        XCTAssertFalse(alert.center)
        XCTAssertEqual(alert.fontSize, 14)
        XCTAssertEqual(alert.transitionMode, "fade")
        XCTAssertEqual(alert.duration, 0)
        XCTAssertEqual(alert.icon, "")
        XCTAssertTrue(alert.modelValue.wrappedValue)
    }

    func testModelValueAndShowInitializersExposeTheSameProps() {
        var modelValue = false
        let modelBinding = Binding(get: { modelValue }, set: { modelValue = $0 })
        let modelAlert = UPAlert(
            modelValue: modelBinding,
            title: "标题",
            type: "success",
            description: "描述",
            closable: true,
            showIcon: true,
            effect: "dark",
            center: true,
            fontSize: 16,
            transitionMode: "slide-left",
            duration: 1200,
            icon: "star"
        )

        var shown = true
        let showBinding = Binding(get: { shown }, set: { shown = $0 })
        let showAlert = UPAlert(show: showBinding, title: "标题")

        XCTAssertFalse(modelAlert.modelValue.wrappedValue)
        XCTAssertEqual(modelAlert.title, "标题")
        XCTAssertEqual(modelAlert.type, "success")
        XCTAssertEqual(modelAlert.description, "描述")
        XCTAssertTrue(modelAlert.closable)
        XCTAssertTrue(modelAlert.showIcon)
        XCTAssertEqual(modelAlert.effect, "dark")
        XCTAssertTrue(modelAlert.center)
        XCTAssertEqual(modelAlert.fontSize, 16)
        XCTAssertEqual(modelAlert.transitionMode, "slide-left")
        XCTAssertEqual(modelAlert.duration, 1200)
        XCTAssertEqual(modelAlert.icon, "star")
        XCTAssertTrue(showAlert.modelValue.wrappedValue)
    }

    func testIconAndColorResolutionMatchesUviewPlus() {
        XCTAssertEqual(UPAlert.iconName(for: "success", customIcon: ""), "checkmark-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "error", customIcon: ""), "close-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "warning", customIcon: ""), "error-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "info", customIcon: ""), "info-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "primary", customIcon: ""), "more-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "unknown", customIcon: ""), "error-circle-fill")
        XCTAssertEqual(UPAlert.iconName(for: "success", customIcon: "star"), "star")

        XCTAssertEqual(UPAlert.iconColorToken(type: "success", effect: "light"), "success")
        XCTAssertEqual(UPAlert.iconColorToken(type: "success", effect: "dark"), "#fff")
        XCTAssertEqual(UPAlert.backgroundColorToken(type: "warning", effect: "light"), "warningLight")
        XCTAssertEqual(UPAlert.backgroundColorToken(type: "warning", effect: "dark"), "warning")
        XCTAssertEqual(UPAlert.textColorToken(type: "error", effect: "light"), "error")
        XCTAssertEqual(UPAlert.textColorToken(type: "error", effect: "dark"), "#fff")
    }

    func testPropValuesNormalizeForSwiftUI() {
        let alert = UPAlert(fontSize: "18px")
        XCTAssertEqual(alert.resolvedFontSize, 18, accuracy: 0.001)
        XCTAssertEqual(UPAlert.resolvedFontSize(from: "20rpx"), 20, accuracy: 0.001)
        XCTAssertEqual(UPAlert.resolvedFontSize(from: "invalid"), 14, accuracy: 0.001)
        XCTAssertEqual(UPAlert.normalizedEffect("other"), "light")
        XCTAssertEqual(UPAlert.normalizedType("other"), "warning")
        XCTAssertTrue(UPAlert.shouldRender(show: true))
        XCTAssertFalse(UPAlert.shouldRender(show: false))
    }

    func testTransitionModesMirrorUviewPlus() {
        let upstreamModes = [
            "none", "fade", "fade-up", "fade-down", "fade-left", "fade-right",
            "slide-up", "slide-down", "slide-left", "slide-right", "zoom", "fade-zoom"
        ]

        for mode in upstreamModes {
            XCTAssertEqual(UPAlert.normalizedTransitionMode(mode), mode)
        }

        // Keep the older native aliases usable without changing the upstream surface.
        XCTAssertEqual(UPAlert.normalizedTransitionMode("slide-top"), "slide-down")
        XCTAssertEqual(UPAlert.normalizedTransitionMode("slide-bottom"), "slide-up")
        XCTAssertEqual(UPAlert.normalizedTransitionMode("zoom-in"), "zoom")
        XCTAssertEqual(UPAlert.normalizedTransitionMode("zoom-out"), "fade-zoom")
        XCTAssertEqual(UPAlert.normalizedTransitionMode("unsupported"), "fade")
        XCTAssertEqual(UPAlert.transitionAnimationDuration, 0.3, accuracy: 0.001)
    }

    func testClickOnlyEmitsClick() {
        var events: [String] = []

        UPAlert.performClick { events.append("click") }

        XCTAssertEqual(events, ["click"])
    }

    func testCloseUpdatesBindingBeforeCloseAndClosedWhenDurationIsEnabled() {
        var shown = true
        var events: [String] = []
        let binding = Binding(
            get: { shown },
            set: { shown = $0; events.append("show:\($0)") }
        )

        UPAlert.performClose(
            modelValue: binding,
            duration: 600,
            onUpdateModelValue: { events.append("update:\($0)") },
            onClose: { events.append("close") },
            onClosed: { events.append("closed") }
        )

        XCTAssertEqual(events, ["show:false", "update:false", "close", "closed"])
        XCTAssertFalse(shown)
    }

    func testCloseWithZeroDurationDoesNotEmitClosed() {
        var shown = true
        var closed = false
        let binding = Binding(get: { shown }, set: { shown = $0 })

        UPAlert.performClose(
            modelValue: binding,
            duration: 0,
            onUpdateModelValue: nil,
            onClose: { closed = true },
            onClosed: { XCTFail("closed should not be emitted for duration 0") }
        )

        XCTAssertFalse(shown)
        XCTAssertTrue(closed)
    }

    func testFluentEventModifiersReplaceHandlersWithoutMutatingOriginal() {
        let original = UPAlert()
        let clicked = original.onClick {}
        let closed = clicked.onClose {}
        let fullyConfigured = closed.onClosed {}.onUpdateModelValue { _ in }

        XCTAssertNil(original.onClickHandler)
        XCTAssertNil(original.onCloseHandler)
        XCTAssertNil(original.onClosedHandler)
        XCTAssertNil(original.onUpdateModelValueHandler)
        XCTAssertNotNil(clicked.onClickHandler)
        XCTAssertNil(clicked.onCloseHandler)
        XCTAssertNotNil(closed.onCloseHandler)
        XCTAssertNotNil(fullyConfigured.onClosedHandler)
        XCTAssertNotNil(fullyConfigured.onUpdateModelValueHandler)
    }

    func testCustomCloseContentSuppressesDefaultCloseIcon() {
        let alert = UPAlert(closable: true) {
            Text("自定义关闭")
        }

        XCTAssertTrue(alert.hasCustomCloseContent)
        XCTAssertTrue(alert.shouldRenderCloseButton)
    }

    func testShowInitializerCanUseCustomCloseContent() {
        let alert = UPAlert(show: .constant(true), closable: true) {
            Text("关闭")
        }

        XCTAssertTrue(alert.modelValue.wrappedValue)
        XCTAssertTrue(alert.hasCustomCloseContent)
        XCTAssertTrue(alert.shouldRenderCloseButton)
    }

    func testIconRenderColorUsesFullHexForNativeIconFont() {
        let alert = UPAlert(type: "success", showIcon: true, effect: "dark")

        XCTAssertEqual(alert.iconColorToken, "#fff")
        XCTAssertEqual(alert.iconRenderColorToken, "#ffffff")
    }

    #if os(macOS)
    func testAlertCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPAlert(
                title: "提示",
                description: "这是一条说明",
                closable: true,
                showIcon: true
            )
            .frame(width: 360, height: 100)
        )

        XCTAssertEqual(renderer.cgImage?.width, 360)
        XCTAssertEqual(renderer.cgImage?.height, 100)
    }
    #endif
}
