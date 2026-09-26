import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class PopupTests: XCTestCase {
    func testOverlayDefaults() {
        let overlay = UPOverlay()
        XCTAssertEqual(overlay.opacity, 0.5)
        XCTAssertEqual(overlay.duration, 300)
    }

    func testHiddenOverlayDoesNotReceiveHitTesting() {
        XCTAssertFalse(UPOverlay<EmptyView>.allowsHitTesting(show: false))
        XCTAssertTrue(UPOverlay<EmptyView>.allowsHitTesting(show: true))
    }

    /// 上游 `libs/config/props/overlay.js`：`show: false`、`zIndex: 10070`、
    /// `duration: 300`、`opacity: 0.5`。
    func testOverlayPropDefaultsMatchUpstream() {
        XCTAssertFalse(UPConfig.overlay.show)
        XCTAssertEqual(UPConfig.overlay.zIndex, 10_070)
        XCTAssertEqual(UPConfig.overlay.duration, 300)
        XCTAssertEqual(UPConfig.overlay.opacity, 0.5)

        let overlay = UPOverlay()
        XCTAssertFalse(overlay.show)
        XCTAssertEqual(overlay.zIndex, 10_070)
        XCTAssertEqual(overlay.opacity, 0.5)
        // 隐藏时整层淡出（上游由 u-transition 负责）。
        XCTAssertEqual(overlay.resolvedOpacity, 0)
        XCTAssertEqual(UPOverlay(show: true).resolvedOpacity, 0.5)
        XCTAssertTrue(overlay.customStyle.properties.isEmpty)
    }

    /// `opacity` 是 `String | Number`，小数字符串要能解析且不丢精度。
    func testOverlayOpacityAcceptsStringAndNumber() {
        XCTAssertEqual(UPOverlay<EmptyView>.parseOpacity("0.8"), 0.8)
        XCTAssertEqual(UPOverlay<EmptyView>.parseOpacity("1"), 1)
        // 解析不出时回落上游默认值。
        XCTAssertEqual(UPOverlay<EmptyView>.parseOpacity("auto"), 0.5)

        XCTAssertEqual(UPOverlay(show: true, opacity: "0.8").resolvedOpacity, 0.8)
        XCTAssertEqual(UPOverlay(show: true, opacity: 0.2).resolvedOpacity, 0.2)
        // 超出 0...1 会被夹住。
        XCTAssertEqual(UPOverlay(show: true, opacity: 2).resolvedOpacity, 1)
    }

    /// 上游默认插槽渲染在遮罩之上，`customStyle` 走 deepMerge 可覆盖内建样式。
    func testOverlayAcceptsContentAndCustomStyle() {
        let overlay = UPOverlay(show: true, customStyle: UPStyle(["backgroundColor": "#00000080"])) {
            Text("弹窗内容")
        }
        XCTAssertEqual(overlay.customStyle["backgroundColor"], "#00000080")
        XCTAssertTrue(overlay.show)
    }

    func testPopupOnlyRendersOverlayWhileShown() {
        XCTAssertFalse(UPPopup<EmptyView>.shouldRenderOverlay(show: false, overlay: true))
        XCTAssertFalse(UPPopup<EmptyView>.shouldRenderOverlay(show: true, overlay: false))
        XCTAssertTrue(UPPopup<EmptyView>.shouldRenderOverlay(show: true, overlay: true))
    }


    func testPageInlinePopupSuppressesOverlay() {
        XCTAssertFalse(UPPopup<EmptyView>.shouldRenderOverlay(
            show: true,
            overlay: true,
            pageInline: true
        ))
        XCTAssertTrue(UPPopup<EmptyView>.shouldRenderOverlay(
            show: true,
            overlay: true,
            pageInline: false
        ))
    }

    func testCenterOverlayClickClosesPopupAndEmitsBothEvents() {
        let show = PopupBoolBox(true)
        var events: [String] = []

        UPPopup<EmptyView>.applyOverlayClick(
            show: show.binding,
            mode: "center",
            closeOnClickOverlay: true,
            onClickOverlay: { events.append("overlay") },
            onClick: { events.append("click") }
        )

        XCTAssertFalse(show.value)
        XCTAssertEqual(events, ["overlay", "click"])
    }

    func testNonCenterOverlayClickDoesNotEmitPopupClick() {
        let show = PopupBoolBox(true)
        var events: [String] = []

        UPPopup<EmptyView>.applyOverlayClick(
            show: show.binding,
            mode: "bottom",
            closeOnClickOverlay: true,
            onClickOverlay: { events.append("overlay") },
            onClick: { events.append("click") }
        )

        XCTAssertFalse(show.value)
        XCTAssertEqual(events, ["overlay"])
    }


    func testBottomSlotIsStoredThroughAViewBuilderModifier() {
        let popup = UPPopup(show: .constant(true)) {
            Text("popup content")
        }
        .bottom {
            Text("popup bottom")
        }

        XCTAssertTrue(popup.hasBottomSlot)
    }

    /// 上游按 mode 只圆化背离屏幕边缘的两个角：bottom→上两角、top→下两角、
    /// left→右两角、right→左两角、center→四角。
    func testPopupRoundedCornersFollowMode() {
        XCTAssertEqual(UPRectCorner.forPopup(mode: "bottom"), [.topLeft, .topRight])
        XCTAssertEqual(UPRectCorner.forPopup(mode: "top"), [.bottomLeft, .bottomRight])
        XCTAssertEqual(UPRectCorner.forPopup(mode: "left"), [.topRight, .bottomRight])
        XCTAssertEqual(UPRectCorner.forPopup(mode: "right"), [.topLeft, .bottomLeft])
        XCTAssertEqual(UPRectCorner.forPopup(mode: "center"), .all)
        // 未知 mode 回落 center 语义（全圆角）。
        XCTAssertEqual(UPRectCorner.forPopup(mode: "weird"), .all)
    }

    func testStringAndNumberPropsAreNormalizedLikeUpstreamValues() {
        let popup = UPPopup(
            show: .constant(true),
            duration: "450",
            zIndex: "12000",
            round: 24,
            overlayOpacity: "0.35"
        ) {
            EmptyView()
        }

        XCTAssertEqual(popup.duration, 450)
        XCTAssertEqual(popup.zIndex, 12_000)
        XCTAssertEqual(popup.round, "24")
        XCTAssertEqual(popup.overlayOpacity, 0.35)
    }

    func testClosedModifierRegistersLifecycleHandler() {
        var closed = false
        let popup = UPPopup(show: .constant(true)) { EmptyView() }
            .onClosed { closed = true }

        popup.onClosed?()

        XCTAssertTrue(closed)
    }

    func testExternalVisibilityChangeEmitsCloseWithoutDuplicatingInternalClose() {
        var events: [String] = []

        let externalCloseWasEmitted = UPPopup<EmptyView>.applyVisibilityChange(
            oldValue: true,
            newValue: false,
            closeWasEmitted: false,
            onClose: { events.append("close") }
        )
        XCTAssertFalse(externalCloseWasEmitted)
        XCTAssertEqual(events, ["close"])

        events.removeAll()
        let internalCloseWasEmitted = UPPopup<EmptyView>.applyVisibilityChange(
            oldValue: true,
            newValue: false,
            closeWasEmitted: true,
            onClose: { events.append("close") }
        )
        XCTAssertFalse(internalCloseWasEmitted)
        XCTAssertTrue(events.isEmpty)
    }

    func testPageInlineExternalCloseAlsoEmitsClosed() {
        var events: [String] = []

        _ = UPPopup<EmptyView>.applyVisibilityChange(
            oldValue: true,
            newValue: false,
            pageInline: true,
            closeWasEmitted: false,
            onClose: { events.append("close") },
            onClosed: { events.append("closed") }
        )

        XCTAssertEqual(events, ["close", "closed"])
    }

    func testNonInlineClosedIsScheduledAfterNativeTransition() async {
        let closed = expectation(description: "closed")

        UPPopup<EmptyView>.scheduleClosed(
            pageInline: false,
            duration: 0,
            onClosed: { closed.fulfill() }
        )

        await fulfillment(of: [closed], timeout: 0.2)
    }

    func testExplicitCloseUpdatesBindingBeforeEmittingClose() {
        var visible = true
        var events: [String] = []
        let show = Binding<Bool>(
            get: { visible },
            set: {
                visible = $0
                events.append("binding: \($0)")
            }
        )

        UPPopup<EmptyView>.applyClose(
            show: show,
            onClose: { events.append("close") }
        )

        XCTAssertFalse(visible)
        XCTAssertEqual(events, ["binding: false", "close"])
    }
}

@MainActor
private final class PopupBoolBox {
    var value: Bool

    init(_ value: Bool) {
        self.value = value
    }

    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
