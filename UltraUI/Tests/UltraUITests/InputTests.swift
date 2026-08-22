import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class InputTests: XCTestCase {
    func testDefaultsAndLengthTruncation() {
        let input = UPInput()

        XCTAssertEqual(input.type, "text")
        XCTAssertEqual(input.border, "surround")
        XCTAssertFalse(input.clearable)
        XCTAssertEqual(UPInput.truncated("abcdef", maxlength: 4), "abcd")
        XCTAssertEqual(UPInput.truncated("abcdef", maxlength: nil), "abcdef")
        XCTAssertEqual(UPInput.truncated("abcdef", maxlength: -1), "abcdef")
        XCTAssertEqual(UPInput.truncated("abcdef", maxlength: 0), "")
    }

    func testChangeFocusAndBlurModifiersStoreHandlers() {
        var changes: [String] = []
        var focused = false
        var blurred = false
        let input = UPInput()
            .onChange { changes.append($0) }
            .onFocus { focused = true }
            .onBlur { blurred = true }

        input.onChangeHandler?("value")
        input.onFocusHandler?()
        input.onBlurHandler?()

        XCTAssertEqual(changes, ["value"])
        XCTAssertTrue(focused)
        XCTAssertTrue(blurred)
    }

    func testCommitPrefersFormPropBindingAndTruncatesBeforeValidation() {
        let modelBox = InputModelBox(["account": .object(["name": .string("old")])])
        let controller = UPFormController()
        let form = UPFormContext(
            model: modelBox.binding,
            rules: ["account.name": [UPFormRule(min: 4, message: "至少 4 个字符", trigger: "change")]],
            controller: controller
        )
        form.connectController()
        let directBox = InputTextBox("direct")
        let localBox = InputTextBox("local")
        var changes: [String] = []

        UPInput.commit(
            "abcdef",
            prop: "account.name",
            form: form,
            directText: directBox.binding,
            fallbackText: localBox.binding,
            maxlength: 4,
            readonly: false,
            onChange: { changes.append($0) }
        )

        XCTAssertEqual(UPFormValue.value(at: "account.name", in: modelBox.model), .string("abcd"))
        XCTAssertEqual(directBox.value, "direct")
        XCTAssertEqual(localBox.value, "local")
        XCTAssertNil(controller.errors["account.name"])
        XCTAssertEqual(changes, ["abcd"])
    }

    func testCommitUsesDirectBindingOutsideFormAndReadonlyPreservesValue() {
        let directBox = InputTextBox("old")
        let localBox = InputTextBox("local")
        var changes: [String] = []

        UPInput.commit(
            "abcdef",
            prop: "",
            form: nil,
            directText: directBox.binding,
            fallbackText: localBox.binding,
            maxlength: 3,
            readonly: false,
            onChange: { changes.append($0) }
        )
        XCTAssertEqual(directBox.value, "abc")
        XCTAssertEqual(changes, ["abc"])

        UPInput.commit(
            "ignored",
            prop: "",
            form: nil,
            directText: directBox.binding,
            fallbackText: localBox.binding,
            maxlength: nil,
            readonly: true,
            onChange: { changes.append($0) }
        )
        XCTAssertEqual(directBox.value, "abc")
        XCTAssertEqual(changes, ["abc"])
    }

    func testFormPropValueTakesPrecedenceOverModelValueAndLegacyBindings() {
        let formBox = InputModelBox(["name": .string("form")])
        let form = UPFormContext(model: formBox.binding, controller: UPFormController())
        let modelValueBox = InputTextBox("model")
        let legacyTextBox = InputTextBox("legacy")
        let localTextBox = InputTextBox("local")

        XCTAssertEqual(
            UPInput.value(
                prop: "name",
                form: form,
                modelValue: modelValueBox.binding,
                directText: legacyTextBox.binding,
                fallbackText: localTextBox.binding
            ),
            "form"
        )
    }

    func testCommitFormatsTruncatesAndEmitsInputAndChangeEvents() {
        let modelValueBox = InputTextBox("old")
        let localTextBox = InputTextBox("local")
        var inputEvents: [String] = []
        var changeEvents: [String] = []

        UPInput.commit(
            " a b c d ",
            prop: "",
            form: nil,
            modelValue: modelValueBox.binding,
            directText: nil,
            fallbackText: localTextBox.binding,
            maxlength: 3,
            readonly: false,
            formatter: { $0.replacingOccurrences(of: " ", with: "").uppercased() },
            onInput: { inputEvents.append($0) },
            onChange: { changeEvents.append($0) }
        )

        XCTAssertEqual(modelValueBox.value, "ABC")
        XCTAssertEqual(localTextBox.value, "local")
        XCTAssertEqual(inputEvents, ["ABC"])
        XCTAssertEqual(changeEvents, ["ABC"])
    }

    func testUnknownBorderAndTypeUseSafeFallbacks() {
        XCTAssertEqual(UPInput.resolvedBorder("unexpected"), "surround")
        XCTAssertEqual(UPInput.resolvedType("unexpected"), "text")
        XCTAssertEqual(UPInput.resolvedTextAlignment("right"), .trailing)
    }

    /// Upstream exposes `prefix` and `suffix` named slots alongside the
    /// `prefixIcon` and `suffixIcon` string props.
    func testPrefixAndSuffixSlotsRecordTheirContent() {
        let plain = UPInput()
        XCTAssertFalse(plain.hasPrefixSlot)
        XCTAssertFalse(plain.hasSuffixSlot)

        let slotted = UPInput()
            .prefix { Text("+86") }
            .suffix { Text("@example.com") }

        XCTAssertTrue(slotted.hasPrefixSlot)
        XCTAssertTrue(slotted.hasSuffixSlot)
    }

    func testValueCarryingFocusAndBlurFireAlongsideTheLegacyHooks() {
        var events: [String] = []
        let input = UPInput(
            onFocusValue: { events.append("focusValue:\($0)") },
            onBlurValue: { events.append("blurValue:\($0)") }
        )
        .onFocus { events.append("focus") }
        .onBlur { events.append("blur") }

        input.onFocusHandler?()
        input.onFocusValueEvent?("typed")
        input.onBlurHandler?()
        input.onBlurValueEvent?("typed")

        XCTAssertEqual(events, ["focus", "focusValue:typed", "blur", "blurValue:typed"])
    }

    /// Upstream types `fontSize` and `cursorSpacing` as `String | Number`.
    func testFontSizeAndCursorSpacingAcceptStringAndNumberForms() {
        XCTAssertEqual(UPInput(fontSize: 18).fontSize, "18")
        XCTAssertEqual(UPInput(fontSize: "18px").fontSize, "18px")
        XCTAssertEqual(UPInput(cursorSpacing: 40).cursorSpacing, 40)
        XCTAssertEqual(UPInput(cursorSpacing: "40").cursorSpacing, 40)
    }
}

@MainActor
private final class InputModelBox {
    var model: UPFormModel

    init(_ model: UPFormModel) {
        self.model = model
    }

    var binding: Binding<UPFormModel> {
        Binding(get: { self.model }, set: { self.model = $0 })
    }
}

@MainActor
private final class InputTextBox {
    var value: String

    init(_ value: String) {
        self.value = value
    }

    var binding: Binding<String> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
