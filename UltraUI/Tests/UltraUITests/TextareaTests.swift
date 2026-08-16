import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TextareaTests: XCTestCase {
    func testDefaultsAndTruncation() {
        let textarea = UPTextarea()

        XCTAssertEqual(textarea.height, 100)
        XCTAssertFalse(textarea.autoHeight)
        XCTAssertFalse(textarea.count)
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: 3), "123")
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: nil), "12345")
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: 0), "")
    }

    func testResolvedLineLimitMapsAutoHeightSafely() {
        XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: false), 1...1)
        XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: true), 3...8)
    }

    func testChangeFocusAndBlurModifiersStoreHandlers() {
        var changes: [String] = []
        var focused = false
        var blurred = false
        let textarea = UPTextarea()
            .onChange { changes.append($0) }
            .onFocus { focused = true }
            .onBlur { blurred = true }

        textarea.onChangeHandler?("value")
        textarea.onFocusHandler?()
        textarea.onBlurHandler?()

        XCTAssertEqual(changes, ["value"])
        XCTAssertTrue(focused)
        XCTAssertTrue(blurred)
    }

    func testCommitPrefersFormPropBindingAndTruncatesBeforeValidation() {
        let modelBox = TextareaModelBox(["profile": .object(["bio": .string("old")])])
        let controller = UPFormController()
        let form = UPFormContext(
            model: modelBox.binding,
            rules: ["profile.bio": [UPFormRule(min: 4, message: "至少 4 个字符", trigger: "change")]],
            controller: controller
        )
        form.connectController()
        let directBox = TextareaTextBox("direct")
        let localBox = TextareaTextBox("local")
        var changes: [String] = []

        UPTextarea.commit(
            "abcdef",
            prop: "profile.bio",
            form: form,
            directText: directBox.binding,
            fallbackText: localBox.binding,
            maxlength: 3,
            readonly: false,
            onChange: { changes.append($0) }
        )

        XCTAssertEqual(UPFormValue.value(at: "profile.bio", in: modelBox.model), .string("abc"))
        XCTAssertEqual(directBox.value, "direct")
        XCTAssertEqual(localBox.value, "local")
        XCTAssertEqual(controller.errors["profile.bio"], "至少 4 个字符")
        XCTAssertEqual(changes, ["abc"])
    }

    func testCommitUsesDirectBindingOutsideFormAndReadonlyPreservesValue() {
        let directBox = TextareaTextBox("old")
        let localBox = TextareaTextBox("local")
        var changes: [String] = []

        UPTextarea.commit(
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

        UPTextarea.commit(
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
}

@MainActor
private final class TextareaModelBox {
    var model: UPFormModel

    init(_ model: UPFormModel) {
        self.model = model
    }

    var binding: Binding<UPFormModel> {
        Binding(get: { self.model }, set: { self.model = $0 })
    }
}

@MainActor
private final class TextareaTextBox {
    var value: String

    init(_ value: String) {
        self.value = value
    }

    var binding: Binding<String> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
