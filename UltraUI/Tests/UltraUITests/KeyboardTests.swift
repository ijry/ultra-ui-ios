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
    func testMessageInputTruncatesAndEmitsFinish() {
        let value = StringBox("")
        var changed = ""
        var finished = ""
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4)
            .onChange { changed = $0 }
            .onFinish { finished = $0 }

        input.input("hello")
        XCTAssertEqual(value.value, "hell")
        XCTAssertEqual(changed, "hell")
        XCTAssertEqual(finished, "hell")
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
        disabled.input("ignored")
        XCTAssertEqual(disabled.inputValue, "")
    }
}
