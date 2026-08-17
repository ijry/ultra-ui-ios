import XCTest
@testable import UltraUI

@MainActor
final class LinkTests: XCTestCase {
    func testDefaultsMatchUviewPlusLink() {
        let link = UPLink()

        XCTAssertEqual(link.color, "#2979ff")
        XCTAssertEqual(link.fontSize, 15)
        XCTAssertFalse(link.underLine)
        XCTAssertEqual(link.href, "")
        XCTAssertEqual(link.lineColor, "")
        XCTAssertEqual(link.text, "")
    }

    func testStringOrNumberFontSizeAndSharedMixinSurfaceCanBeMixed() {
        let numericFontSize: Int = 18
        let style = UPStyle(["padding": "4px"])
        let numericLink = UPLink(fontSize: numericFontSize)
        let stringLink = UPLink(
            fontSize: "20px",
            customClass: "documentation-link",
            customStyle: style
        )

        XCTAssertEqual(numericLink.fontSize, 18)
        XCTAssertEqual(stringLink.fontSize, 20)
        XCTAssertEqual(stringLink.customClass, "documentation-link")
        XCTAssertEqual(stringLink.customStyle, style)
    }

}
