import XCTest
@testable import UltraUI

final class BasicComponentsTests: XCTestCase {
    func testLineDefaults() {
        let line = UPLine()
        XCTAssertEqual(line.color, "#d6d7d9")
        XCTAssertEqual(line.direction, "row")
        XCTAssertTrue(line.hairline)
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
