import XCTest
@testable import UltraUI

@MainActor
final class BasicComponentsTests: XCTestCase {
    func testLineDefaults() {
        let line = UPLine()
        XCTAssertEqual(line.color, "#d6d7d9")
        XCTAssertEqual(line.direction, "row")
        XCTAssertTrue(line.hairline)
    }
    func testLineLengthParsing() {
        XCTAssertEqual(UPLine.parsedLength("100%"), .fraction(1))
        XCTAssertEqual(UPLine.parsedLength("50%"), .fraction(0.5))
        XCTAssertEqual(UPLine.parsedLength("120px"), .points(120))
        XCTAssertEqual(UPLine.parsedLength("650rpx"), .points(650))
    }

    func testGapDefaults() {
        let gap = UPGap()
        XCTAssertEqual(gap.height, 20)
        XCTAssertEqual(gap.bgColor, "transparent")
    }
    func testLoadingDefaults() {
        let l = UPLoadingIcon()
        XCTAssertEqual(l.mode, "spinner")
        XCTAssertEqual(l.size, 24)
        XCTAssertEqual(l.color, "#909399")
    }
}
