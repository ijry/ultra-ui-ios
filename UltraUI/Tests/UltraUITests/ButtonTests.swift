import XCTest
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
        XCTAssertEqual(UPButton.fontSize(for: "normal"), 15)
        XCTAssertEqual(UPButton.fontSize(for: "small"), 14)
        XCTAssertEqual(UPButton.fontSize(for: "mini"), 12)
    }
}
