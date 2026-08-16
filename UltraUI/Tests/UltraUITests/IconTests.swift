import XCTest
@testable import UltraUI

@MainActor
final class IconTests: XCTestCase {
    func testGlyphExists() {
        XCTAssertFalse(UPIconMap.glyph(for: "uicon-checkmark").isEmpty)
        XCTAssertEqual(UPIconMap.glyphs.count, 213)
    }
    func testUsesBundledFontPostScriptName() {
        XCTAssertEqual(UPIcon.fontName, "iconfont")
    }

    func testUnknownGlyphEmpty() {
        XCTAssertEqual(UPIconMap.glyph(for: "uicon-nope"), "")
    }
}
