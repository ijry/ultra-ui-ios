import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class KeyboardTests: XCTestCase {
    func testNumberKeyboardUsesInjectedRandomOrderAndUpdatesBinding() {
        let value = StringBox("")
        var events: [String] = []
        let keyboard = UPNumberKeyboard(
            modelValue: value.binding,
            random: true,
            randomSource: { ["3", "1", "2", "9", "8", "7", "6", "5", "4"] }
        )
        .onChange { events.append("change:\($0)") }
        .onConfirm { events.append("confirm:\($0)") }

        XCTAssertEqual(keyboard.keys.map(\.value), ["3", "1", "2", "9", "8", "7", "6", "5", "4"])
        keyboard.press("3")
        keyboard.delete()
        keyboard.press("1")
        keyboard.confirm()
        XCTAssertEqual(value.value, "1")
        XCTAssertEqual(events, ["change:3", "change:", "change:1", "confirm:1"])
    }

    func testCarKeyboardMovesFromProvinceToLetterStage() {
        let value = StringBox("")
        let keyboard = UPCarKeyboard(modelValue: value.binding)
        XCTAssertEqual(keyboard.stage, .province)
        keyboard.press("京")
        XCTAssertEqual(value.value, "京")
        XCTAssertEqual(keyboard.stage, .letter)
        keyboard.press("A")
        XCTAssertEqual(value.value, "京A")
        keyboard.delete()
        XCTAssertEqual(value.value, "京")
    }

    func testKeyboardCloseAndDisabledEvents() {
        var closed = 0
        let keyboard = UPKeyboard(show: true, disabled: true).onCancel { closed += 1 }
        keyboard.cancel()
        XCTAssertEqual(closed, 0)

        let enabled = UPKeyboard(show: true).onCancel { closed += 1 }
        enabled.cancel()
        XCTAssertEqual(closed, 1)
    }
}
@MainActor
final class MessageInputTests: XCTestCase {
    /// Upstream `getVal` stores the raw value but returns early when it is
    /// longer than `maxlength`, so neither `change` nor `finish` is emitted.
    func testMessageInputRejectsOverLengthInputWithoutEmittingEvents() {
        let value = StringBox("")
        var changes: [String] = []
        var finishes: [String] = []
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4)
            .onChange { changes.append($0) }
            .onFinish { finishes.append($0) }

        input.input("hello")
        XCTAssertTrue(changes.isEmpty)
        XCTAssertTrue(finishes.isEmpty)

        input.input("123")
        XCTAssertEqual(value.value, "123")
        XCTAssertEqual(changes, ["123"])
        XCTAssertTrue(finishes.isEmpty)

        input.input("1234")
        XCTAssertEqual(value.value, "1234")
        XCTAssertEqual(changes, ["123", "1234"])
        XCTAssertEqual(finishes, ["1234"])
    }

    /// The upstream `modelValue` watcher truncates with `substring`, so an
    /// external write is clamped even though user input of the same length is
    /// rejected outright.
    func testExternalModelValueIsTruncatedUnlikeUserInput() {
        let value = StringBox("123456")
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4)

        XCTAssertEqual(input.inputValue, "1234")
    }

    func testMessageInputFocusAndDisabledState() {
        var focused = 0
        var blurred = 0
        let input = UPMessageInput(disabled: false)
            .onFocus { focused += 1 }
            .onBlur { blurred += 1 }
        input.focus()
        input.blur()
        XCTAssertEqual(focused, 1)
        XCTAssertEqual(blurred, 1)

        let disabled = UPMessageInput(disabled: true)
        disabled.input("12")
        XCTAssertEqual(disabled.inputValue, "")
    }

    func testDisabledKeyboardIgnoresInputButKeepsExternalValue() {
        let value = StringBox("12")
        var changes: [String] = []
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4, disabledKeyboard: true)
            .onChange { changes.append($0) }

        input.input("123")

        XCTAssertEqual(input.inputValue, "12")
        XCTAssertEqual(value.value, "12")
        XCTAssertTrue(changes.isEmpty)
    }

    func testDefaultsMatchUpstreamProps() {
        let input = UPMessageInput()

        XCTAssertEqual(input.maxlength, 4)
        XCTAssertEqual(input.mode, "box")
        XCTAssertFalse(input.dotFill)
        XCTAssertTrue(input.breathe)
        XCTAssertFalse(input.autoFocus)
        XCTAssertFalse(input.bold)
        XCTAssertEqual(input.fontSize, 60)
        XCTAssertEqual(input.width, 80)
        XCTAssertEqual(input.activeColor, "#2979ff")
        XCTAssertEqual(input.inactiveColor, "#606266")
        XCTAssertFalse(input.disabledKeyboard)
    }

    func testAcceptsRejectsOnlyOverLengthValues() {
        XCTAssertTrue(UPMessageInput.accepts("", maxlength: 4))
        XCTAssertTrue(UPMessageInput.accepts("1234", maxlength: 4))
        XCTAssertFalse(UPMessageInput.accepts("12345", maxlength: 4))
    }

    func testResolvedModeFallsBackToBox() {
        XCTAssertEqual(UPMessageInput.resolvedMode("box"), "box")
        XCTAssertEqual(UPMessageInput.resolvedMode("middleLine"), "middleLine")
        XCTAssertEqual(UPMessageInput.resolvedMode("bottomLine"), "bottomLine")
        XCTAssertEqual(UPMessageInput.resolvedMode("unexpected"), "box")
    }

    /// Upstream only swaps in `activeColor` for the box border, and only on the
    /// cell at the current fill position.
    func testBorderColorUsesActiveColorOnlyForActiveBoxCell() {
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 2, filledCount: 2, mode: "box", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#2979ff"
        )
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 1, filledCount: 2, mode: "box", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#606266"
        )
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 2, filledCount: 2, mode: "bottomLine", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#606266"
        )
    }

    func testIsBreathingOnlyAtActiveIndexWhenEnabled() {
        XCTAssertTrue(UPMessageInput.isBreathing(atIndex: 2, filledCount: 2, breathe: true))
        XCTAssertFalse(UPMessageInput.isBreathing(atIndex: 3, filledCount: 2, breathe: true))
        XCTAssertFalse(UPMessageInput.isBreathing(atIndex: 2, filledCount: 2, breathe: false))
    }
}
