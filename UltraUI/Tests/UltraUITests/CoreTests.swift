import XCTest
import SwiftUI
@testable import UltraUI

final class CoreTests: XCTestCase {
    private func rgba(_ color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        #if canImport(UIKit)
        let ui = UIColor(color)
        #else
        let ui = NSColor(color)
        #endif
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    private func assertColor(_ c1: Color, _ c2: Color, tolerance: CGFloat = 0.01, file: StaticString = #filePath, line: UInt = #line) {
        let a = rgba(c1), b = rgba(c2)
        XCTAssertEqual(a.r, b.r, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(a.g, b.g, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(a.b, b.b, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(a.a, b.a, accuracy: tolerance, file: file, line: line)
    }

    func testColorHex() {
        assertColor(UPColor.parse("#3c9cff"), Color(red: 0x3c / 255.0, green: 0x9c / 255.0, blue: 0xff / 255.0))
    }

    func testColorHexAlpha() {
        assertColor(UPColor.parse("#3c9cff80"), Color(red: 0x3c / 255.0, green: 0x9c / 255.0, blue: 0xff / 255.0, opacity: 0x80 / 255.0))
    }

    func testColorThemeName() {
        assertColor(UPColor.parse("primary"), UPTheme.default.primary)
    }

    func testColorInvalidFallsBack() {
        assertColor(UPColor.parse("not-a-color"), UPTheme.default.content)
    }

    func testRpx() {
        XCTAssertEqual(UPUnit.rpx(650), 650.0, accuracy: 0.001)
        XCTAssertEqual(UPUnit.rpx(325), 325.0, accuracy: 0.001)
    }

    func testUnitParse() {
        XCTAssertEqual(UPUnit.parse("650rpx"), 650.0, accuracy: 0.001)
        XCTAssertEqual(UPUnit.parse("20px"), 20.0, accuracy: 0.001)
        XCTAssertEqual(UPUnit.parse(15), 15.0, accuracy: 0.001)
    }

    func testConfigDefaults() {
        XCTAssertEqual(UPConfig.button.type, "info")
        XCTAssertEqual(UPConfig.modal.confirmText, "确认")
        XCTAssertEqual(UPConfig.popup.mode, "bottom")
        XCTAssertEqual(UPConfig.icon.size, "16px")
    }
}
