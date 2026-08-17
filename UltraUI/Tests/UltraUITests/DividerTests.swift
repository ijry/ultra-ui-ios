import XCTest
@testable import UltraUI

@MainActor
final class DividerTests: XCTestCase {
    func testDefaultsMatchUviewPlusDivider() {
        let divider = UPDivider()

        XCTAssertFalse(divider.dashed)
        XCTAssertTrue(divider.hairline)
        XCTAssertFalse(divider.dot)
        XCTAssertEqual(divider.textPosition, "center")
        XCTAssertEqual(divider.text, "")
        XCTAssertEqual(divider.textSize, 14)
        XCTAssertEqual(divider.textColor, "#909399")
        XCTAssertEqual(divider.lineColor, "#dcdfe6")
        XCTAssertEqual(divider.customClass, "")
        XCTAssertEqual(divider.customStyle, UPStyle())
    }


    func testStringOrNumberTextPropsAndSharedMixinSurfaceCanBeMixed() {
        let style = UPStyle(["padding": "4px"])
        let divider = UPDivider(
            text: 42,
            textSize: "18px",
            customClass: "section-divider",
            customStyle: style
        )

        XCTAssertEqual(divider.text, "42")
        XCTAssertEqual(divider.textSize, 18)
        XCTAssertEqual(divider.customClass, "section-divider")
        XCTAssertEqual(divider.customStyle, style)
    }
}
