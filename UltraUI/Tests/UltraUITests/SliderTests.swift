import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SliderTests: XCTestCase {
    func testDefaultsMatchUpstream() {
        let slider = UPSlider()

        XCTAssertEqual(slider.value, 0)
        XCTAssertEqual(slider.blockSize, 18)
        XCTAssertEqual(slider.min, 0)
        XCTAssertEqual(slider.max, 100)
        XCTAssertEqual(slider.step, 1)
        XCTAssertFalse(slider.showValue)
        XCTAssertFalse(slider.disabled)
        XCTAssertFalse(slider.vertical)
        XCTAssertFalse(slider.isRange)
    }

    func testSingleValueClampsRoundsAndOrdersEvents() {
        let box = SliderBox(0.0)
        var events: [String] = []
        let slider = UPSlider(modelValue: box.binding, min: 0, max: 10, step: 2)
            .onStart { events.append("start") }
            .onChanging { events.append("changing:\($0)") }
            .onChange { events.append("change:\($0)") }

        slider.startInteraction()
        slider.changeInteraction(to: 7.1)
        slider.endInteraction()

        XCTAssertEqual(box.value, 8)
        XCTAssertEqual(events, ["start", "changing:8.0", "change:8.0"])
    }

    func testRangeKeepsThumbsOneStepApart() {
        let box = SliderBox(UPSliderRangeValue(lower: 2, upper: 8))
        let slider = UPSlider(rangeValue: box.binding, min: 0, max: 10, step: 2)

        slider.changeLower(to: 9)
        XCTAssertEqual(box.value, UPSliderRangeValue(lower: 6, upper: 8))
        slider.changeUpper(to: 1)
        XCTAssertEqual(box.value, UPSliderRangeValue(lower: 6, upper: 8))
    }

    func testRangeEmitsStructuredChangingAndChangePayloads() {
        let box = SliderBox(UPSliderRangeValue(lower: 2, upper: 8))
        var changing: [UPSliderRangeValue] = []
        var changes: [UPSliderRangeValue] = []
        let slider = UPSlider(rangeValue: box.binding, min: 0, max: 10, step: 2)
            .onRangeChanging { changing.append($0) }
            .onRangeChange { changes.append($0) }

        slider.changeLower(to: 9)
        slider.endRangeInteraction()

        XCTAssertEqual(changing, [.init(lower: 6, upper: 8)])
        XCTAssertEqual(changes, [.init(lower: 6, upper: 8)])
    }

    func testDisabledRangeSuppressesStructuredEvents() {
        let box = SliderBox(UPSliderRangeValue(lower: 2, upper: 8))
        var eventCount = 0
        let slider = UPSlider(rangeValue: box.binding, min: 0, max: 10, step: 2, disabled: true)
            .onRangeChanging { _ in eventCount += 1 }
            .onRangeChange { _ in eventCount += 1 }

        slider.changeUpper(to: 10)
        slider.endRangeInteraction()

        XCTAssertEqual(box.value, .init(lower: 2, upper: 8))
        XCTAssertEqual(eventCount, 0)
    }

    func testStringAndIntegerBindingsPreserveUpstreamNumberCompatibility() {
        let stringBox = SliderBox("0")
        let integerBox = SliderBox(0)
        let stringSlider = UPSlider(modelValue: stringBox.binding, min: 0, max: 10, step: 2)
        let integerSlider = UPSlider(modelValue: integerBox.binding, min: 0, max: 10, step: 2)

        stringSlider.changeInteraction(to: 7.1)
        integerSlider.changeInteraction(to: 5.1)

        XCTAssertEqual(stringBox.value, "8")
        XCTAssertEqual(integerBox.value, 6)
    }

    /// 上游 `libs/config/props/slider.js` 的默认值。
    func testSliderPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.slider.blockSize, 18)
        XCTAssertEqual(UPConfig.slider.min, 0)
        XCTAssertEqual(UPConfig.slider.max, 100)
        XCTAssertEqual(UPConfig.slider.step, 1)
        XCTAssertEqual(UPConfig.slider.activeColor, "#2979ff")
        XCTAssertEqual(UPConfig.slider.inactiveColor, "#c0c4cc")
        XCTAssertEqual(UPConfig.slider.blockColor, "#ffffff")
        XCTAssertFalse(UPConfig.slider.showValue)
        XCTAssertFalse(UPConfig.slider.useNative)
        XCTAssertEqual(UPConfig.slider.height, "")
        XCTAssertFalse(UPConfig.slider.vertical)
        XCTAssertEqual(UPConfig.slider.size, "2px")
        XCTAssertEqual(UPConfig.slider.length, "auto")
    }

    /// 上游 `sizeLocal`：`height` 非空取它，否则取 `size`。
    func testSliderTrackThicknessPrefersHeightOverSize() {
        XCTAssertEqual(UPSlider().resolvedTrackThickness, 2)
        XCTAssertEqual(UPSlider(size: "6px").resolvedTrackThickness, 6)
        // height 一给就盖掉 size。
        XCTAssertEqual(UPSlider(height: "10px", size: "6px").resolvedTrackThickness, 10)
    }

    /// 上游 `innerStyleCpu`：容器厚度是 blockSize，区间 + showValue 时多 24。
    func testSliderInnerThicknessAccountsForRangeLabels() {
        XCTAssertEqual(UPSlider().resolvedInnerThickness, 18)
        XCTAssertEqual(UPSlider(blockSize: 26).resolvedInnerThickness, 26)

        let box = SliderBox(UPSliderRangeValue(lower: 0, upper: 10))
        XCTAssertEqual(UPSlider(rangeValue: box.binding, showValue: true).resolvedInnerThickness, 42)
        // 非区间时即便 showValue 为真也不额外加空间（数值渲染在轨道右侧）。
        XCTAssertEqual(UPSlider(showValue: true).resolvedInnerThickness, 18)
    }

    /// 上游 `updateValue` 的 `sliderLength`：`(value - min) / range * trackLength`，
    /// 上限夹到 trackLength。
    func testSliderFillLengthMatchesUpstreamFormula() {
        let slider = UPSlider(min: 0, max: 100, step: 1)
        XCTAssertEqual(slider.fillLength(for: 0, trackLength: 200), 0)
        XCTAssertEqual(slider.fillLength(for: 50, trackLength: 200), 100)
        XCTAssertEqual(slider.fillLength(for: 100, trackLength: 200), 200)
        // 超出范围先被 normalize 夹住。
        XCTAssertEqual(slider.fillLength(for: 500, trackLength: 200), 200)
        // 轨道长度为 0 时没有可填充长度。
        XCTAssertEqual(slider.fillLength(for: 50, trackLength: 0), 0)

        // 上游 `touchButtonStyle`：滑块中心再加半个 blockSize。
        XCTAssertEqual(slider.blockOffset(for: 50, trackLength: 200), 100 + 9)
    }

    /// 上游 `onTouchMove` 的换算：`(distance / trackLength) * (max - min) + min`，
    /// 再走 `format` 的 step 对齐。
    func testSliderValueAtDistanceMatchesUpstreamFormula() {
        let slider = UPSlider(min: 0, max: 100, step: 1)
        XCTAssertEqual(slider.value(atDistance: 0, trackLength: 200), 0)
        XCTAssertEqual(slider.value(atDistance: 100, trackLength: 200), 50)
        XCTAssertEqual(slider.value(atDistance: 200, trackLength: 200), 100)
        // 超出轨道被夹到边界。
        XCTAssertEqual(slider.value(atDistance: 400, trackLength: 200), 100)
        XCTAssertEqual(slider.value(atDistance: -50, trackLength: 200), 0)

        // step 会把结果对齐到档位。
        let stepped = UPSlider(min: 0, max: 10, step: 2)
        XCTAssertEqual(stepped.value(atDistance: 100, trackLength: 200), 6)

        // 轨道长度为 0 时退回下界。
        XCTAssertEqual(slider.value(atDistance: 50, trackLength: 0), 0)
    }
}

@MainActor
private final class SliderBox<Value> {
    var value: Value

    init(_ value: Value) { self.value = value }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
