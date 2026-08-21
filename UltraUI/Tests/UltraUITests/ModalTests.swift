import XCTest
import SwiftUI
@testable import UltraUI

@MainActor
final class ModalTests: XCTestCase {
    func testDefaults() {
        let modal = UPModal(show: .constant(false))
        XCTAssertEqual(modal.confirmText, "确认")
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
