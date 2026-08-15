import XCTest
@testable import UltraUI

final class IconTests: XCTestCase {
    func testGlyphExists() {
        XCTAssertFalse(UPIconMap.glyph(for: "uicon-checkmark").isEmpty)
        XCTAssertEqual(UPIconMap.glyphs.count, 213)
    }
    func testUnknownGlyphEmpty() {
        XCTAssertEqual(UPIconMap.glyph(for: "uicon-nope"), "")
    }
}
