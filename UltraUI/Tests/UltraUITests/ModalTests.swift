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
}
