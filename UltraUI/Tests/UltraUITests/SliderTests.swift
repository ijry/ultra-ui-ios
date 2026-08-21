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
}

@MainActor
private final class SliderBox<Value> {
    var value: Value

    init(_ value: Value) { self.value = value }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
