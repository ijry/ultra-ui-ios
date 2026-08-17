import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CodeInputTests: XCTestCase {
    func testDefaultsMatchUviewPlusCodeInput() {
        let input = UPCodeInput()

        XCTAssertTrue(input.adjustPosition)
        XCTAssertEqual(input.maxlength, "6")
        XCTAssertFalse(input.dot)
        XCTAssertEqual(input.mode, "box")
        XCTAssertFalse(input.hairline)
        XCTAssertEqual(input.space, "10")
        XCTAssertEqual(input.value, "")
        XCTAssertFalse(input.focus)
        XCTAssertFalse(input.bold)
        XCTAssertEqual(input.color, "#606266")
        XCTAssertEqual(input.fontSize, "18")
        XCTAssertEqual(input.size, "35")
        XCTAssertFalse(input.disabledKeyboard)
        XCTAssertEqual(input.borderColor, "#c9cacc")
        XCTAssertTrue(input.disabledDot)
        XCTAssertEqual(input.resolvedMode, .box)
        XCTAssertEqual(input.resolvedMaxlength, 6)
        XCTAssertEqual(input.inputValue, "")
    }

    func testModelValueStartsTruncatedAndInputKeepsUpstreamEventOrder() {
        let box = CodeInputValueBox("1234567")
        var events: [String] = []
        let input = UPCodeInput(
            modelValue: box.binding,
            maxlength: 4,
            onChange: { value in
                events.append("change:\(value):model=\(box.value)")
            },
            onFinish: { value in
                events.append("finish:\(value):model=\(box.value)")
            }
        )

        // The upstream model watcher truncates only the component's display;
        // it does not mutate the parent v-model value.
        XCTAssertEqual(box.value, "1234567")
        XCTAssertEqual(input.inputValue, "1234")
        XCTAssertEqual(input.codeArray, ["1", "2", "3", "4"])

        input.triggerInput("1.2.3")

        // u-code-input removes just the first dot from its displayed value on
        // the next tick, but emits and writes the original input payload.
        XCTAssertEqual(input.inputValue, "12.3")
        XCTAssertEqual(box.value, "1.2.3")
        XCTAssertEqual(
            events,
            [
                "change:1.2.3:model=1234567",
                "finish:1.2.3:model=1.2.3"
            ]
        )
    }

    func testChangeAndFinishModifiersInstallOnTheNativeController() {
        let box = CodeInputValueBox("")
        var changed: [String] = []
        var finished: [String] = []
        let input = UPCodeInput(modelValue: box.binding, maxlength: "3")
            .onChange { changed.append($0) }
            .onFinish { finished.append($0) }

        input.triggerInput("12")
        input.triggerInput("123")

        XCTAssertEqual(box.value, "123")
        XCTAssertEqual(changed, ["12", "123"])
        XCTAssertEqual(finished, ["123"])
    }

    func testStringAndNumberPropsResolveNativeLayoutMetadata() {
        let style = UPStyle(["backgroundColor": "primary"])
        let input = UPCodeInput(
            maxlength: "4",
            dot: true,
            mode: "line",
            hairline: true,
            space: "0",
            value: 123456,
            focus: true,
            bold: true,
            color: "error",
            fontSize: "20px",
            size: "40rpx",
            disabledKeyboard: true,
            borderColor: "warning",
            disabledDot: false,
            customClass: "verification-code",
            customStyle: style
        )

        XCTAssertEqual(input.maxlength, "4")
        XCTAssertEqual(input.value, "123456")
        XCTAssertEqual(input.inputValue, "1234")
        XCTAssertEqual(input.codeArray, ["1", "2", "3", "4"])
        XCTAssertEqual(input.resolvedMode, .line)
        XCTAssertEqual(input.resolvedMaxlength, 4)
        XCTAssertEqual(input.resolvedSpace, 0)
        XCTAssertEqual(input.resolvedFontSize, 20)
        XCTAssertEqual(input.resolvedSize, 40)
        XCTAssertTrue(input.controller.isFocused)
        XCTAssertEqual(input.customClass, "verification-code")
        XCTAssertEqual(input.customStyle, style)
    }

    func testInvalidStringPropsFallBackToUpstreamDefaultsAndZeroLengthStaysValid() {
        let invalid = UPCodeInput(
            maxlength: "not-a-length",
            mode: "unsupported",
            space: "invalid-unit",
            fontSize: "invalid-unit",
            size: "-10"
        )
        let zero = UPCodeInput(maxlength: 0, space: 0)

        XCTAssertEqual(invalid.resolvedMaxlength, UPConfig.codeInput.maxlength)
        XCTAssertEqual(invalid.resolvedMode, .box)
        XCTAssertEqual(invalid.resolvedSpace, UPConfig.codeInput.space)
        XCTAssertEqual(invalid.resolvedFontSize, UPConfig.codeInput.fontSize)
        XCTAssertEqual(invalid.resolvedSize, UPConfig.codeInput.size)
        XCTAssertEqual(zero.resolvedMaxlength, 0)
        XCTAssertEqual(zero.resolvedSpace, 0)
        XCTAssertEqual(zero.codeArray, [])
    }

    func testExternalModelSynchronizationKeepsDotsButTruncatesAndCustomControllerInputWorks() {
        let box = CodeInputValueBox("1.2.345")
        let input = UPCodeInput(maxlength: 4, modelValue: box.binding, disabledDot: true)

        // A prop/model watcher only applies substring(maxlength), matching the
        // source component. Dot removal is specific to native input events.
        XCTAssertEqual(input.inputValue, "1.2.")

        box.value = "98765"
        input.synchronizeExternalModelValue()
        XCTAssertEqual(input.inputValue, "9876")

        input.controller.input("7.8.9")
        XCTAssertEqual(input.inputValue, "78.9")
        XCTAssertEqual(box.value, "7.8.9")
    }
}

@MainActor
private final class CodeInputValueBox {
    var value: String

    init(_ value: String) {
        self.value = value
    }

    var binding: Binding<String> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
