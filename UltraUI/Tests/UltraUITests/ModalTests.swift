import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class ModalTests: XCTestCase {
    func testDefaults() {
        let modal = UPModal(show: .constant(false))
        XCTAssertEqual(modal.confirmText, "确定")
        XCTAssertEqual(modal.cancelText, "取消")
        XCTAssertTrue(modal.showConfirmButton)
        XCTAssertFalse(modal.showCancelButton)
        XCTAssertEqual(modal.width, "650rpx")
        XCTAssertEqual(modal.contentTextAlign, "left")
    }


    func testNamedConfirmButtonAndPopupBottomSlotsUseViewBuilders() {
        let modal = UPModal(show: .constant(true))
            .confirmButton {
                Text("retry")
            }
            .popupBottom {
                Text("modal footer")
            }

        XCTAssertTrue(modal.hasConfirmButtonSlot)
        XCTAssertTrue(modal.hasPopupBottomSlot)
    }

    func testStringAndNumberPropsAreNormalizedLikeUpstreamValues() {
        let modal = UPModal(
            show: .constant(false),
            negativeTop: "32.5",
            width: 320,
            duration: "550"
        )

        XCTAssertEqual(modal.negativeTop, 32.5)
        XCTAssertEqual(modal.width, "320")
        XCTAssertEqual(modal.duration, 550)
    }

    func testConfirmButtonShapeSuppressesDefaultCancelButton() {
        let modal = UPModal(
            show: .constant(true),
            showCancelButton: true,
            confirmButtonShape: "circle"
        )

        XCTAssertFalse(modal.shouldShowCancelButton)
        XCTAssertTrue(modal.shouldShowConfirmButton)
    }

    func testSynchronousConfirmHidesBeforeEmittingConfirm() {
        var visible = true
        var events: [String] = []
        let show = Binding<Bool>(
            get: { visible },
            set: {
                visible = $0
                events.append("binding: \($0)")
            }
        )

        let loading = UPModal<EmptyView>.applyConfirm(
            show: show,
            asyncClose: false,
            onConfirm: { events.append("confirm") }
        )

        XCTAssertFalse(loading)
        XCTAssertFalse(visible)
        XCTAssertEqual(events, ["binding: false", "confirm"])
    }

    func testAsynchronousConfirmKeepsVisibleAndEntersLoadingBeforeCallback() {
        var visible = true
        var events: [String] = []
        let show = Binding<Bool>(get: { visible }, set: { visible = $0 })

        let loading = UPModal<EmptyView>.applyConfirm(
            show: show,
            asyncClose: true,
            onLoadingChange: { events.append("loading: \($0)") },
            onConfirm: { events.append("confirm visible: \(visible)") }
        )

        XCTAssertTrue(loading)
        XCTAssertTrue(visible)
        XCTAssertEqual(events, ["loading: true", "confirm visible: true"])
    }

    func testAsyncConfirmCancellationKeepsModalVisibleAndEmitsBothEvents() {
        var visible = true
        var events: [String] = []
        let show = Binding(get: { visible }, set: { visible = $0 })

        let shouldShowAsyncCloseTip = UPModal<EmptyView>.applyCancel(
            show: show,
            asyncClose: true,
            isConfirming: true,
            asyncCancelClose: false,
            onCancel: { events.append("cancel") },
            onCancelOnAsync: { events.append("cancelOnAsync") }
        )

        XCTAssertTrue(shouldShowAsyncCloseTip)
        XCTAssertTrue(visible)
        XCTAssertEqual(events, ["cancelOnAsync", "cancel"])
    }
}
