import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class NumberBoxTests: XCTestCase {
    func testDefaultsAndResolvedMetricsMatchUviewPlus() {
        let box = UPNumberBox()

        XCTAssertEqual(box.customClass, "")
        XCTAssertEqual(box.name, "")
        XCTAssertEqual(box.value, .number(0))
        XCTAssertEqual(box.min, "1")
        XCTAssertEqual(box.max, "9007199254740991")
        XCTAssertEqual(box.step, "1")
        XCTAssertFalse(box.integer)
        XCTAssertFalse(box.disabled)
        XCTAssertFalse(box.disabledInput)
        XCTAssertFalse(box.asyncChange)
        XCTAssertEqual(box.inputWidth, "35")
        XCTAssertTrue(box.showMinus)
        XCTAssertTrue(box.showPlus)
        XCTAssertNil(box.decimalLength)
        XCTAssertTrue(box.longPress)
        XCTAssertEqual(box.color, "")
        XCTAssertEqual(box.buttonWidth, "30")
        XCTAssertEqual(box.buttonSize, "30")
        XCTAssertEqual(box.buttonRadius, "0px")
        XCTAssertEqual(box.bgColor, "")
        XCTAssertEqual(box.disabledBgColor, "")
        XCTAssertEqual(box.inputBgColor, "")
        XCTAssertEqual(box.cursorSpacing, "100")
        XCTAssertFalse(box.disableMinus)
        XCTAssertFalse(box.disablePlus)
        XCTAssertEqual(box.iconStyle, UPStyle())
        XCTAssertFalse(box.miniMode)
        XCTAssertEqual(box.customStyle, UPStyle())

        // The source component initializes its internal value through
        // `format`, so its default `value: 0` is immediately clamped to min.
        XCTAssertEqual(box.currentValue, .number(1))
        XCTAssertEqual(box.resolvedInputWidth, 35)
        XCTAssertEqual(box.resolvedButtonWidth, 30)
        XCTAssertEqual(box.resolvedButtonSize, 30)
        XCTAssertTrue(box.isDisabled(.minus))
        XCTAssertFalse(box.isDisabled(.plus))
    }

    func testModelBindingsAndChangePayloadPreserveNameTypeAndEventOrder() {
        let numberBox = NumberBoxValueBox(1.0)
        let stringBox = NumberBoxValueBox("1")
        var emitted: [UPNumberBoxChange] = []
        var modelAtChange: Double?

        let numberControl = UPNumberBox(
            name: "quantity",
            modelValue: numberBox.binding,
            min: 1,
            max: 5,
            step: 0.5
        ) { detail in
            emitted.append(detail)
            modelAtChange = numberBox.value
        }
        let stringControl = UPNumberBox(modelValue: stringBox.binding, min: 1, max: 5)

        numberControl.triggerPlus()
        stringControl.triggerPlus()

        // `change` is emitted synchronously before the source's next-tick
        // model update. The SwiftUI bridge keeps that observable ordering.
        XCTAssertEqual(modelAtChange, 1)
        XCTAssertEqual(numberBox.value, 1.5)
        XCTAssertEqual(stringBox.value, "2")
        XCTAssertEqual(
            emitted,
            [UPNumberBoxChange(value: .number(1.5), name: "quantity", type: .plus)]
        )
    }

    func testPlusMinusAndOverlimitEventsRespectBoundsAndExplicitButtonDisables() {
        let box = NumberBoxValueBox(2.0)
        var changes: [UPNumberBoxChange] = []
        var overlimits: [UPNumberBoxButtonType] = []
        var plusCount = 0
        var minusCount = 0
        let control = UPNumberBox(
            modelValue: box.binding,
            min: 1,
            max: 2,
            onChange: { changes.append($0) },
            onOverlimit: { overlimits.append($0) },
            onPlus: { plusCount += 1 },
            onMinus: { minusCount += 1 }
        )

        control.triggerPlus()
        control.triggerMinus()
        control.triggerMinus()
        control.triggerMinus()

        XCTAssertEqual(box.value, 1)
        XCTAssertEqual(changes.map(\.type), [.minus])
        XCTAssertEqual(overlimits, [.plus, .minus, .minus])
        XCTAssertEqual(plusCount, 0)
        XCTAssertEqual(minusCount, 1)

        let blocked = UPNumberBox(modelValue: box.binding, disablePlus: true)
        blocked.triggerPlus()
        XCTAssertEqual(box.value, 1)
    }

    func testAsyncChangeEmitsCandidateAndButtonEventWithoutMutatingTheBinding() {
        let box = NumberBoxValueBox(1.0)
        var changes: [UPNumberBoxChange] = []
        var plusCount = 0
        let control = UPNumberBox(
            modelValue: box.binding,
            min: 1,
            asyncChange: true,
            onChange: { changes.append($0) },
            onPlus: { plusCount += 1 }
        )

        control.triggerPlus()

        XCTAssertEqual(box.value, 1)
        XCTAssertEqual(changes, [UPNumberBoxChange(value: .number(2), name: "", type: .plus)])
        XCTAssertEqual(plusCount, 1)
    }

    func testInputDecimalFilteringAndBlurMatchUviewPlusTwoPhaseChangeBehavior() {
        let box = NumberBoxValueBox("1")
        var changes: [UPNumberBoxChange] = []
        var focusEvents: [UPNumberBoxFocusEvent] = []
        var blurEvents: [UPNumberBoxBlurEvent] = []
        let control = UPNumberBox(
            name: 9,
            modelValue: box.binding,
            min: 0,
            max: 10,
            decimalLength: 2,
            onChange: { changes.append($0) },
            onFocus: { focusEvents.append($0) },
            onBlur: { blurEvents.append($0) }
        )

        control.triggerFocus()
        control.triggerInput("2.999")
        XCTAssertEqual(box.value, "2.99")
        XCTAssertEqual(changes.map(\.value), [.string("2.999"), .string("2.99")])

        // An empty input is retained during editing and coerced only on blur.
        control.triggerInput("")
        XCTAssertEqual(box.value, "2.99")
        control.triggerBlur()

        XCTAssertEqual(box.value, "0.00")
        XCTAssertEqual(focusEvents, [UPNumberBoxFocusEvent(name: 9)])
        XCTAssertEqual(blurEvents, [UPNumberBoxBlurEvent(value: .string("0.00"), name: 9)])
        XCTAssertEqual(changes.last, UPNumberBoxChange(value: .string("0.00"), name: 9, type: nil))
    }

    func testMiniModeSlotsAndLongPressTicksKeepTheUviewPlusSurface() {
        let box = NumberBoxValueBox(0.0)
        let mini = UPNumberBox(modelValue: box.binding, min: 0, miniMode: true)
            .minus { context in
                Image(systemName: context.isDisabled ? "minus.circle" : "minus")
            }
            .input { context in
                Text(context.value.description)
            }
            .plus { context in
                Image(systemName: context.isDisabled ? "plus.circle" : "plus")
            }
        let nonRepeating = UPNumberBox(modelValue: box.binding, min: 0, longPress: false)

        XCTAssertTrue(mini.hasMinusSlot)
        XCTAssertTrue(mini.hasInputSlot)
        XCTAssertTrue(mini.hasPlusSlot)
        XCTAssertTrue(mini.hidesMinus)
        XCTAssertFalse(mini.showsInput)

        mini.triggerLongPressTick(.plus)
        XCTAssertEqual(box.value, 1)
        XCTAssertFalse(mini.hidesMinus)
        XCTAssertTrue(mini.showsInput)

        nonRepeating.triggerLongPressTick(.plus)
        XCTAssertEqual(box.value, 1)
    }
}

@MainActor
private final class NumberBoxValueBox<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
