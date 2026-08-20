import XCTest
@testable import UltraUI

@MainActor
final class TextTests: XCTestCase {
    func testDefaultsMatchUviewPlusText() {
        let text = UPText()

        XCTAssertEqual(text.type, "")
        XCTAssertTrue(text.show)
        XCTAssertEqual(text.text, "")
        XCTAssertEqual(text.mode, "")
        XCTAssertEqual(text.size, "15")
        XCTAssertEqual(text.resolvedSize, 15)
        XCTAssertEqual(text.align, "left")
        XCTAssertFalse(text.bold)
    }

    func testValueFormattingMatchesUviewPlusModes() {
        XCTAssertEqual(UPText(text: "12.5", mode: "price").displayText, "12.50")
        XCTAssertEqual(UPText(text: "13812345678", mode: "phone", format: "encrypt").displayText, "138****5678")
        XCTAssertEqual(UPText(text: "张三", mode: "name", format: "encrypt").displayText, "张*")
        XCTAssertEqual(UPText(text: "欧阳小明", mode: "name", format: "encrypt").displayText, "欧**明")
    }

    func testFormatterClosureOverridesBuiltInModeFormatting() {
        let text = UPText(
            text: "12.5",
            mode: "price",
            formatter: { "USD \($0)" }
        )

        XCTAssertEqual(text.displayText, "USD 12.5")
    }


    func testDateModeUsesUviewPlusTokensAndDefaultFormat() {
        XCTAssertEqual(
            UPText(text: "2024-05-06 07:08:09", mode: "date").displayText,
            "2024-05-06"
        )
        XCTAssertEqual(
            UPText(
                text: "2024-05-06 07:08:09",
                mode: "date",
                format: "yyyy年mm月dd日 hh时MM分"
            ).displayText,
            "2024年05月06日 07时08分"
        )
    }

    func testStringOrNumberPropsPreserveUviewPlusCompatibility() {
        let numericText = UPText(
            text: 1234,
            lines: 2,
            size: "16px",
            margin: "4px 8px",
            lineHeight: 24
        )

        XCTAssertEqual(numericText.text, "1234")
        XCTAssertEqual(numericText.lines, "2")
        XCTAssertEqual(numericText.size, "16px")
        XCTAssertEqual(numericText.margin, "4px 8px")
        XCTAssertEqual(numericText.lineHeight, "24")
        XCTAssertEqual(numericText.resolvedSize, 16)
        XCTAssertEqual(numericText.resolvedLineLimit, 2)
        XCTAssertEqual(numericText.resolvedMargin, UPInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        XCTAssertEqual(numericText.resolvedLineSpacing, 8)
    }

}
