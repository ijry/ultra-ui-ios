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
        XCTAssertFalse(UPOverlay.allowsHitTesting(show: false))
        XCTAssertTrue(UPOverlay.allowsHitTesting(show: true))
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
