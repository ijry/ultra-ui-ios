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

    /// CSS 简写 hex（`#fff`/`#000f`）在上游样式里直接可用，解析后与展开形式等价。
    func testColorShorthandHex() {
        assertColor(UPColor.parse("#fff"), .white)
        assertColor(UPColor.parse("#000"), Color(hex: 0x000000))
        assertColor(UPColor.parse("#39f"), Color(hex: 0x3399FF))
        assertColor(UPColor.parse("#39f8"), Color(red: 0x33 / 255.0, green: 0x99 / 255.0, blue: 0xff / 255.0, opacity: 0x88 / 255.0))
        assertColor(UPColor.parse("#zzz"), UPTheme.default.content)
    }

    func testColorThemeName() {
        assertColor(UPColor.parse("primary"), UPTheme.default.primary)
    }

    func testColorInvalidFallsBack() {
        assertColor(UPColor.parse("not-a-color"), UPTheme.default.content)
    }

    /// 上游样式里大量出现 `transparent`/`none`，应解析为全透明而非回落内容色。
    func testColorTransparentAndNone() {
        assertColor(UPColor.parse("transparent"), .clear)
        assertColor(UPColor.parse("none"), .clear)
        assertColor(UPColor.parse("  Transparent  "), .clear)
    }

    /// 上游 CSS 颜色常写成 `rgb()`/`rgba()`（如 toast 的 `rgb(255,255,255)`、
    /// navbar-mini 的 `rgba(0,0,0,.15)`），需要按 CSS 规则解析。
    func testColorRgbAndRgba() {
        assertColor(UPColor.parse("rgb(255, 255, 255)"), .white)
        assertColor(UPColor.parse("rgb(60,156,255)"), Color(red: 60/255.0, green: 156/255.0, blue: 255/255.0))
        assertColor(UPColor.parse("rgba(0, 0, 0, 0.15)"), Color(red: 0, green: 0, blue: 0, opacity: 0.15))
        // 省略前导 0 的小数透明度（`.15`）也要吃得下。
        assertColor(UPColor.parse("rgba(0,0,0,.5)"), Color(red: 0, green: 0, blue: 0, opacity: 0.5))
        // 百分比 alpha（CSS Color 4）。
        assertColor(UPColor.parse("rgba(255,255,255,50%)"), Color(red: 1, green: 1, blue: 1, opacity: 0.5))
    }

    /// 非法 rgb 串仍回落内容色，保持既有兜底行为。
    func testColorMalformedRgbFallsBack() {
        assertColor(UPColor.parse("rgb(1,2)"), UPTheme.default.content)
        assertColor(UPColor.parse("rgb()"), UPTheme.default.content)
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
        XCTAssertEqual(UPConfig.modal.confirmText, "确定")
        XCTAssertEqual(UPConfig.popup.mode, "bottom")
        XCTAssertEqual(UPConfig.icon.size, "16px")
    }
}
