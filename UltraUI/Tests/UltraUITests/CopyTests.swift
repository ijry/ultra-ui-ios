import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CopyTests: XCTestCase {
    func testDefaultsMatchUviewPlusCopy() {
        let copy = UPCopy()

        XCTAssertEqual(copy.content, "")
        XCTAssertEqual(copy.alertStyle, "toast")
        XCTAssertEqual(copy.notice, "复制成功")
    }

    func testPropsAndCustomSlotCanBeConstructed() {
        let copy = UPCopy(
            content: "hello",
            alertStyle: "modal",
            notice: "已复制",
            clipboardWriter: { _ in true }
        ) {
            Text("复制链接")
        }

        XCTAssertEqual(copy.content, "hello")
        XCTAssertEqual(copy.alertStyle, "modal")
        XCTAssertEqual(copy.notice, "已复制")
    }

    func testEmptyContentDoesNotWriteOrEmitSuccess() {
        var writtenValues: [String] = []
        var successCount = 0
        let copy = UPCopy(
            clipboardWriter: {
                writtenValues.append($0)
                return true
            }
        )
        .onSuccess { successCount += 1 }

        XCTAssertFalse(copy.performCopy())
        XCTAssertTrue(writtenValues.isEmpty)
        XCTAssertEqual(successCount, 0)
    }

    func testSuccessfulCopyWritesExactContentAndEmitsSuccessOnce() {
        var writtenValues: [String] = []
        var successCount = 0
        let copy = UPCopy(
            content: "https://example.com",
            clipboardWriter: {
                writtenValues.append($0)
                return true
            }
        )
        .onSuccess { successCount += 1 }

        XCTAssertTrue(copy.performCopy())
        XCTAssertEqual(writtenValues, ["https://example.com"])
        XCTAssertEqual(successCount, 1)
    }

    func testFailedClipboardWriteDoesNotEmitSuccess() {
        var successCount = 0
        let copy = UPCopy(
            content: "hello",
            clipboardWriter: { _ in false }
        )
        .onSuccess { successCount += 1 }

        XCTAssertFalse(copy.performCopy())
        XCTAssertEqual(successCount, 0)
    }

    func testOnSuccessPreservesCompatibilityProps() {
        let copy = UPCopy(
            content: "hello",
            alertStyle: "modal",
            notice: "done",
            clipboardWriter: { _ in true }
        )
        .onSuccess {}

        XCTAssertEqual(copy.content, "hello")
        XCTAssertEqual(copy.alertStyle, "modal")
        XCTAssertEqual(copy.notice, "done")
    }
}
