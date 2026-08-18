import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class TransitionTests: XCTestCase {
    func testDefaultsMirrorUviewPlusTransition() {
        let transition = UPTransition()

        XCTAssertFalse(transition.show)
        XCTAssertEqual(transition.mode, "fade")
        XCTAssertEqual(transition.duration, 300, accuracy: 0.001)
        XCTAssertEqual(transition.timingFunction, "ease-out")
        XCTAssertEqual(transition.customStyle, UPStyle())
    }

    func testBindingSlotAndCustomStylePreserveUpstreamProps() {
        var visible = true
        let binding = Binding(get: { visible }, set: { visible = $0 })
        let style = UPStyle([
            "background-color": "#ffffff",
            "border-radius": "12px"
        ])

        let transition = UPTransition(
            show: binding,
            mode: "fade-up",
            duration: "450",
            timingFunction: "linear",
            customStyle: style
        ) {
            Text("内容")
        }

        XCTAssertTrue(transition.show)
        XCTAssertEqual(transition.mode, "fade-up")
        XCTAssertEqual(transition.duration, 450, accuracy: 0.001)
        XCTAssertEqual(transition.timingFunction, "linear")
        XCTAssertEqual(transition.customStyle, style)
        XCTAssertTrue(transition.hasCustomContent)
    }

    func testDurationAcceptsStringAndNumericValuesAndNormalizesInvalidInput() {
        XCTAssertEqual(UPTransition(duration: "120ms").duration, 120, accuracy: 0.001)
        XCTAssertEqual(UPTransition(duration: 80).duration, 80, accuracy: 0.001)
        XCTAssertEqual(UPTransition(duration: -20).duration, 0, accuracy: 0.001)
        XCTAssertEqual(UPTransition(duration: "invalid").duration, 300, accuracy: 0.001)
        XCTAssertEqual(UPTransition.resolvedDuration(from: "0"), 0, accuracy: 0.001)
    }

    func testModeNormalizationAndAnimationSpecsMirrorUviewPlus() {
        let upstreamModes = [
            "none", "fade", "zoom", "fade-zoom",
            "fade-up", "fade-down", "fade-left", "fade-right",
            "slide-up", "slide-down", "slide-left", "slide-right"
        ]

        for mode in upstreamModes {
            XCTAssertEqual(UPTransition.normalizedMode(mode), mode)
        }

        XCTAssertEqual(UPTransition.normalizedMode("unsupported"), "fade")
        XCTAssertEqual(UPTransition.normalizedMode("slide-top"), "slide-down")
        XCTAssertEqual(UPTransition.normalizedMode("slide-bottom"), "slide-up")

        XCTAssertEqual(
            UPTransition.animationSpec(for: "fade-up"),
            UPTransitionSpec(opacity: 0, scale: nil, edge: .bottom)
        )
        XCTAssertEqual(
            UPTransition.animationSpec(for: "slide-left"),
            UPTransitionSpec(opacity: nil, scale: nil, edge: .leading)
        )
        XCTAssertEqual(
            UPTransition.animationSpec(for: "fade-zoom"),
            UPTransitionSpec(opacity: 0, scale: 0.95, edge: nil)
        )
        XCTAssertEqual(
            UPTransition.animationSpec(for: "none"),
            UPTransitionSpec(opacity: nil, scale: nil, edge: nil)
        )
    }

    func testTimingFunctionNormalizationUsesEaseOutFallback() {
        XCTAssertEqual(UPTransition.normalizedTimingFunction("ease-out"), "ease-out")
        XCTAssertEqual(UPTransition.normalizedTimingFunction("ease-in"), "ease-in")
        XCTAssertEqual(UPTransition.normalizedTimingFunction("ease-in-out"), "ease-in-out")
        XCTAssertEqual(UPTransition.normalizedTimingFunction("linear"), "linear")
        XCTAssertEqual(UPTransition.normalizedTimingFunction("unsupported"), "ease-out")
    }

    func testFluentEventModifiersReplaceHandlersWithoutMutatingOriginal() {
        let original = UPTransition()
        let configured = original
            .onClick {}
            .onBeforeEnter {}
            .onEnter {}
            .onAfterEnter {}
            .onBeforeLeave {}
            .onLeave {}
            .onAfterLeave {}

        XCTAssertNil(original.onClickHandler)
        XCTAssertNil(original.onBeforeEnterHandler)
        XCTAssertNil(original.onEnterHandler)
        XCTAssertNil(original.onAfterEnterHandler)
        XCTAssertNil(original.onBeforeLeaveHandler)
        XCTAssertNil(original.onLeaveHandler)
        XCTAssertNil(original.onAfterLeaveHandler)

        XCTAssertNotNil(configured.onClickHandler)
        XCTAssertNotNil(configured.onBeforeEnterHandler)
        XCTAssertNotNil(configured.onEnterHandler)
        XCTAssertNotNil(configured.onAfterEnterHandler)
        XCTAssertNotNil(configured.onBeforeLeaveHandler)
        XCTAssertNotNil(configured.onLeaveHandler)
        XCTAssertNotNil(configured.onAfterLeaveHandler)
    }

    func testClickHelperEmitsOnlyClickEvent() {
        var clicked = false
        UPTransition.performClick { clicked = true }
        XCTAssertTrue(clicked)

        clicked = false
        UPTransition.performClick(nil)
        XCTAssertFalse(clicked)
    }

    func testCoordinatorKeepsContentDuringLeaveAndEmitsLifecycleEvents() async throws {
        var events: [String] = []
        let coordinator = UPTransitionCoordinator()
        coordinator.mount(
            show: true,
            mode: "none",
            duration: 0,
            timingFunction: "linear",
            onBeforeEnter: { events.append("beforeEnter") },
            onEnter: { events.append("enter") },
            onAfterEnter: { events.append("afterEnter") },
            onBeforeLeave: { events.append("beforeLeave") },
            onLeave: { events.append("leave") },
            onAfterLeave: { events.append("afterLeave") }
        )

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(coordinator.isRendered)
        XCTAssertEqual(events, ["beforeEnter", "enter", "afterEnter"])

        coordinator.update(
            show: false,
            mode: "none",
            duration: 0,
            timingFunction: "linear",
            onBeforeEnter: nil,
            onEnter: nil,
            onAfterEnter: nil,
            onBeforeLeave: { events.append("beforeLeave") },
            onLeave: { events.append("leave") },
            onAfterLeave: { events.append("afterLeave") }
        )

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertFalse(coordinator.isRendered)
        XCTAssertEqual(
            events,
            ["beforeEnter", "enter", "afterEnter", "beforeLeave", "leave", "afterLeave"]
        )
    }

    #if os(macOS)
    func testTransitionCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPTransition(show: true, mode: "fade-zoom") {
                Text("transition")
            }
            .frame(width: 240, height: 80)
        )

        XCTAssertEqual(renderer.cgImage?.width, 240)
        XCTAssertEqual(renderer.cgImage?.height, 80)
    }
    #endif
}
