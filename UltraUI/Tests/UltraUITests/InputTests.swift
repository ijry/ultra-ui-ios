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

    func testUnknownBorderAndTypeUseSafeFallbacks() {
        XCTAssertEqual(UPInput.resolvedBorder("unexpected"), "surround")
        XCTAssertEqual(UPInput.resolvedType("unexpected"), "text")
        XCTAssertEqual(UPInput.resolvedTextAlignment("right"), .trailing)
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
