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

    func testImageNamesAndAllLabelPositionsResolveLikeUViewPlus() {
        XCTAssertTrue(UPIcon.isImageName("https://example.com/icons/photo.png"))
        XCTAssertTrue(UPIcon.isImageName("/static/icons/photo.png"))
        XCTAssertFalse(UPIcon.isImageName("photo"))

        XCTAssertEqual(UPIcon.normalizedLabelPosition("left"), "left")
        XCTAssertEqual(UPIcon.normalizedLabelPosition("right"), "right")
        XCTAssertEqual(UPIcon.normalizedLabelPosition("top"), "top")
        XCTAssertEqual(UPIcon.normalizedLabelPosition("bottom"), "bottom")
        XCTAssertEqual(UPIcon.normalizedLabelPosition("unsupported"), "right")
    }

    func testImageModesMapToNativeFitOrFillSemantics() {
        XCTAssertFalse(UPIcon.usesAspectFill(for: "aspectFit"))
        XCTAssertFalse(UPIcon.usesAspectFill(for: "widthFix"))
        XCTAssertTrue(UPIcon.usesAspectFill(for: "aspectFill"))
        XCTAssertTrue(UPIcon.usesAspectFill(for: "scaleToFill"))
    }
}
