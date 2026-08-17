import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class RateTests: XCTestCase {
    func testDefaultsAndResolvedMetricsMatchUviewPlus() {
        let rate = UPRate()

        XCTAssertEqual(rate.customClass, "")
        XCTAssertEqual(rate.value, 1)
        XCTAssertEqual(rate.count, "5")
        XCTAssertFalse(rate.disabled)
        XCTAssertFalse(rate.readonly)
        XCTAssertEqual(rate.size, "18")
        XCTAssertEqual(rate.inactiveColor, "")
        XCTAssertEqual(rate.activeColor, "")
        XCTAssertEqual(rate.gutter, "4")
        XCTAssertEqual(rate.minCount, "1")
        XCTAssertFalse(rate.allowHalf)
        XCTAssertEqual(rate.activeIcon, "star-fill")
        XCTAssertEqual(rate.inactiveIcon, "star")
        XCTAssertTrue(rate.touchable)
        XCTAssertEqual(rate.customStyle, UPStyle())

        XCTAssertEqual(rate.activeIndex, 1)
        XCTAssertEqual(rate.resolvedCount, 5)
        XCTAssertEqual(rate.resolvedSize, 18)
        XCTAssertEqual(rate.resolvedGutter, 4)
        XCTAssertEqual(rate.resolvedItemWidth, 22)
    }

    func testBindingSupportsNumberAndStringModelsAndChangePrecedesModelWrite() {
        let numberBox = RateValueBox(1.0)
        let stringBox = RateValueBox("1")
        var emitted: [Double] = []
        var valueWhenChanged: Double?

        let numericRate = UPRate(modelValue: numberBox.binding) { value in
            emitted.append(value)
            valueWhenChanged = numberBox.value
        }
        let stringRate = UPRate(modelValue: stringBox.binding)

        numericRate.triggerTap(index: 3)
        stringRate.triggerTap(index: 2)

        // u-rate emits `change` before `update:modelValue`.
        XCTAssertEqual(valueWhenChanged, 1)
        XCTAssertEqual(numberBox.value, 3)
        XCTAssertEqual(stringBox.value, "2")
        XCTAssertEqual(emitted, [3])
    }

    func testFluentOnChangeAndIntegerBindingUseTheUviewPlusChangePayload() {
        let integerBox = RateValueBox(1)
        var emitted: [Double] = []
        let rate = UPRate(modelValue: integerBox.binding)
            .onChange { emitted.append($0) }

        rate.triggerTap(index: 4)

        XCTAssertEqual(integerBox.value, 4)
        XCTAssertEqual(emitted, [4])
    }

    func testHalfStarClickAndMinimumCountFollowUviewPlusSelectionRules() {
        let box = RateValueBox(1.0)
        var emitted: [Double] = []
        let rate = UPRate(
            modelValue: box.binding,
            count: 5,
            minCount: 1,
            allowHalf: true,
            onChange: { emitted.append($0) }
        )

        rate.triggerTap(index: 2, fraction: 0.25)
        XCTAssertEqual(box.value, 1.5)

        // The beginning of the first icon would otherwise produce zero, but
        // u-rate clamps it to `minCount`.
        rate.triggerTap(index: 1, fraction: 0)
        XCTAssertEqual(box.value, 1)

        // Repeating an unchanged selection does not re-emit Vue's watched
        // `activeIndex` value.
        rate.triggerTap(index: 1, fraction: 0)
        XCTAssertEqual(emitted, [1.5, 1])
    }

    func testTouchabilityOnlyDisablesDraggingWhileDisabledAndReadonlyBlockAllSelection() {
        let touchBox = RateValueBox(1.0)
        let blockedBox = RateValueBox(1.0)
        let readonlyBox = RateValueBox(1.0)
        var emitted: [Double] = []

        let untouchable = UPRate(
            modelValue: touchBox.binding,
            touchable: false,
            onChange: { emitted.append($0) }
        )
        let disabled = UPRate(
            modelValue: blockedBox.binding,
            disabled: true,
            onChange: { emitted.append($0) }
        )
        let readonly = UPRate(
            modelValue: readonlyBox.binding,
            readonly: true,
            onChange: { emitted.append($0) }
        )

        untouchable.triggerTouch(at: untouchable.resolvedItemWidth * 4)
        XCTAssertEqual(touchBox.value, 1)
        untouchable.triggerTap(index: 4)
        XCTAssertEqual(touchBox.value, 4)

        disabled.triggerTap(index: 4)
        readonly.triggerTap(index: 4)
        XCTAssertEqual(blockedBox.value, 1)
        XCTAssertEqual(readonlyBox.value, 1)
        XCTAssertEqual(emitted, [4])
    }

    func testInitialValueNormalizesInvalidAndOutOfRangeInputsLikeUviewPlus() {
        let invalid = UPRate(value: "not-a-number", count: 3, minCount: 2)
        let overflowing = UPRate(value: 9, count: 3, minCount: 1)

        XCTAssertEqual(invalid.activeIndex, 2)
        XCTAssertEqual(overflowing.activeIndex, 3)
    }
}

@MainActor
private final class RateValueBox<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
