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

    /// 上游 `libs/config/props/icon.js` 的默认值。`color` / `labelColor` 都取
    /// `config.color['u-content-color']`（`#606266`）。
    func testIconPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.icon.name, "")
        XCTAssertEqual(UPConfig.icon.color, "#606266")
        XCTAssertEqual(UPConfig.icon.size, "16px")
        XCTAssertFalse(UPConfig.icon.bold)
        XCTAssertEqual(UPConfig.icon.index, "")
        XCTAssertEqual(UPConfig.icon.hoverClass, "")
        XCTAssertEqual(UPConfig.icon.customPrefix, "uicon")
        XCTAssertEqual(UPConfig.icon.label, "")
        XCTAssertEqual(UPConfig.icon.labelPos, "right")
        XCTAssertEqual(UPConfig.icon.labelSize, "15px")
        XCTAssertEqual(UPConfig.icon.labelColor, "#606266")
        XCTAssertEqual(UPConfig.icon.space, "3px")
        XCTAssertEqual(UPConfig.icon.imgMode, "")
        XCTAssertEqual(UPConfig.icon.width, "")
        XCTAssertEqual(UPConfig.icon.height, "")
        XCTAssertEqual(UPConfig.icon.top, "0")
        XCTAssertFalse(UPConfig.icon.stop)

        let icon = UPIcon()
        XCTAssertEqual(icon.color, "#606266")
        XCTAssertEqual(icon.size, "16px")
        XCTAssertEqual(icon.customPrefix, "uicon")
        XCTAssertEqual(icon.labelPos, "right")
        XCTAssertEqual(icon.space, "3px")
        XCTAssertTrue(icon.customStyle.properties.isEmpty)
    }

    /// 上游模板 `v-if="label !== ''"`：判定是严格不等于空串，
    /// 因此传 `"0"` 这种「假值样子的字符串」也会显示。
    func testIconLabelVisibilityUsesStrictEmptyCheck() {
        XCTAssertFalse(UPIcon().showsLabel)
        XCTAssertTrue(UPIcon(label: "0").showsLabel)
        XCTAssertTrue(UPIcon(label: "收藏").showsLabel)
        // 空格不是空串，照抄上游同样显示。
        XCTAssertTrue(UPIcon(label: " ").showsLabel)
    }

    /// 上游 `customStyle` 会叠在字形与图片两个分支上。
    func testIconAcceptsCustomStyle() {
        let icon = UPIcon(name: "photo", customStyle: UPStyle(["opacity": "0.5"]))
        XCTAssertEqual(icon.customStyle["opacity"], "0.5")
    }
}
