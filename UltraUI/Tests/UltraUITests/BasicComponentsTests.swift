import SwiftUI
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

    /// 上游 `margin` 是 `String | Number`（CSS margin 简写）。1/2/3/4 值分别按
    /// CSS 规则展开：all；上下/左右；上/左右/下；上/右/下/左。
    func testLineMarginAcceptsNumberAndCssShorthand() {
        XCTAssertEqual(UPLine.marginInsets("0"), EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        XCTAssertEqual(UPLine.marginInsets("10px"), EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        XCTAssertEqual(UPLine.marginInsets("20px 30px"), EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        XCTAssertEqual(UPLine.marginInsets("5px 10px 15px"), EdgeInsets(top: 5, leading: 10, bottom: 15, trailing: 10))
        XCTAssertEqual(UPLine.marginInsets("1px 2px 3px 4px"), EdgeInsets(top: 1, leading: 4, bottom: 3, trailing: 2))
        // 数字入参走 upImageUnitValue → 全边等距。
        XCTAssertEqual(UPLine(margin: 8).marginInsets, EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    /// 上游 `length` 是 `String | Number`；数字入参等价带默认单位。
    func testLineLengthAcceptsNumberInput() {
        XCTAssertEqual(UPLine.parsedLength(UPLine(length: 120).length), .points(120))
    }

    func testGapDefaults() {
        let gap = UPGap()
        XCTAssertEqual(gap.height, 20)
        XCTAssertEqual(gap.bgColor, "transparent")
        XCTAssertEqual(gap.marginTop, 0)
        XCTAssertEqual(gap.marginBottom, 0)
    }

    /// 上游 height/marginTop/marginBottom 均为 `String | Number`，走 `addUnit`。
    func testGapAcceptsStringAndNumberUnits() {
        XCTAssertEqual(UPGap(height: "40px").height, 40)
        XCTAssertEqual(UPGap(height: "650rpx").height, 650)
        XCTAssertEqual(UPGap(height: 30).height, 30)
        let spaced = UPGap(marginTop: "12px", marginBottom: 8)
        XCTAssertEqual(spaced.marginTop, 12)
        XCTAssertEqual(spaced.marginBottom, 8)
    }

    /// 上游 `gapStyle`：bgColor 为空/transparent 时回落 `--up-gap-bg-color`
    /// （亮 transparent / 暗 #111111）；给了非 transparent 颜色则原样用。
    func testGapBackgroundFollowsUpstreamThemeFallback() {
        XCTAssertEqual(UPGap().resolvedBackgroundValue(isDark: false), "transparent")
        XCTAssertEqual(UPGap().resolvedBackgroundValue(isDark: true), "#111111")
        XCTAssertEqual(UPGap(bgColor: "transparent").resolvedBackgroundValue(isDark: true), "#111111")
        XCTAssertEqual(UPGap(bgColor: "#3c9cff").resolvedBackgroundValue(isDark: false), "#3c9cff")
        XCTAssertEqual(UPGap(bgColor: "#3c9cff").resolvedBackgroundValue(isDark: true), "#3c9cff")
    }
    func testLoadingDefaults() {
        let l = UPLoadingIcon()
        XCTAssertEqual(l.mode, "spinner")
        XCTAssertEqual(l.size, 24)
        XCTAssertEqual(l.color, "#909399")
    }

    /// 上游 `libs/config/props/loadingIcon.js` 的默认值：`color` / `textColor`
    /// 都取 `config.color['u-tips-color']`（`#909399`）。
    func testLoadingIconPropDefaultsMatchUpstream() {
        XCTAssertTrue(UPConfig.loadingIcon.show)
        XCTAssertEqual(UPConfig.loadingIcon.textColor, "#909399")
        XCTAssertFalse(UPConfig.loadingIcon.vertical)
        XCTAssertEqual(UPConfig.loadingIcon.mode, "spinner")
        XCTAssertEqual(UPConfig.loadingIcon.size, 24)
        XCTAssertEqual(UPConfig.loadingIcon.textSize, 15)
        XCTAssertEqual(UPConfig.loadingIcon.text, "")
        XCTAssertEqual(UPConfig.loadingIcon.timingFunction, "ease-in-out")
        XCTAssertEqual(UPConfig.loadingIcon.duration, 1200)
        XCTAssertEqual(UPConfig.loadingIcon.inactiveColor, "")
        XCTAssertEqual(UPConfig.loadingIcon.spinnerDotCount, 12)

        let loading = UPLoadingIcon()
        XCTAssertEqual(loading.textColor, "#909399")
        XCTAssertFalse(loading.vertical)
        XCTAssertEqual(loading.textSize, 15)
        XCTAssertEqual(loading.duration, 1200)
        XCTAssertFalse(loading.showsText)
        XCTAssertTrue(loading.customStyle.properties.isEmpty)
        XCTAssertTrue(UPLoadingIcon(text: "加载中").showsText)
    }

    /// 上游 `otherBorderColor`：只有 circle 模式才有暗边，
    /// `inactiveColor` 优先，否则 `colorGradient(color, '#ffffff', 100)[80]`。
    func testLoadingIconOtherBorderColorMatchesUpstream() {
        // spinner / semicircle 一律 transparent。
        XCTAssertEqual(UPLoadingIcon().otherBorderColor, "transparent")
        XCTAssertEqual(UPLoadingIcon(mode: "semicircle").otherBorderColor, "transparent")

        // circle 且未给 inactiveColor 时往白色插值 80%。
        XCTAssertEqual(UPLoadingIcon(mode: "circle").otherBorderColor, "#e9e9eb")
        XCTAssertEqual(UPLoadingIcon(color: "#3c9cff", mode: "circle").otherBorderColor, "#d8ebff")

        // inactiveColor 优先。
        XCTAssertEqual(UPLoadingIcon(mode: "circle", inactiveColor: "#eeeeee").otherBorderColor, "#eeeeee")

        // 三位十六进制会先补全再插值。
        XCTAssertEqual(UPLoadingIcon.lightened("#000"), "#cccccc")
        // 非十六进制原样返回（上游 hexToRgb 对语义色名也无能为力）。
        XCTAssertEqual(UPLoadingIcon.lightened("primary"), "primary")
    }

    /// 上游 `.__dot:nth-of-type(i) { opacity: 1 - 0.0625 * (i - 1) }`。
    func testLoadingIconSpinnerDotOpacityMatchesUpstream() {
        XCTAssertEqual(UPLoadingIcon.dotOpacity(at: 0), 1)
        XCTAssertEqual(UPLoadingIcon.dotOpacity(at: 1), 0.9375)
        XCTAssertEqual(UPLoadingIcon.dotOpacity(at: 11), 0.3125, accuracy: 0.0001)
    }

    /// 上游 `.__spinner` 的 CSS 动画写死 `1s linear`，只有 circle / semicircle
    /// 会被内联 style 换成 `duration` + `timingFunction`。
    func testLoadingIconRotationAnimationDependsOnMode() {
        XCTAssertEqual(UPLoadingIcon(mode: "spinner").rotationAnimation,
                       .linear(duration: 1))
        XCTAssertEqual(UPLoadingIcon(mode: "circle", duration: 600).rotationAnimation,
                       UPLoadingIcon.animation(for: "ease-in-out", duration: 600))
        XCTAssertEqual(UPLoadingIcon(mode: "semicircle", timingFunction: "linear", duration: 800).rotationAnimation,
                       .linear(duration: 0.8))
    }
}
