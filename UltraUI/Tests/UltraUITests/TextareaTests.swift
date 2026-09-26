import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TextareaTests: XCTestCase {
    func testDefaultsAndTruncation() {
        let textarea = UPTextarea()

        XCTAssertEqual(textarea.height, 70)
        XCTAssertFalse(textarea.autoHeight)
        XCTAssertFalse(textarea.count)
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: 3), "123")
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: nil), "12345")
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: -1), "12345")
        XCTAssertEqual(UPTextarea.truncated("12345", maxlength: 0), "")
    }

    /// Upstream's default is `autoHeight: false` with a fixed `height` and
    /// internal scrolling, so a non-auto-height textarea must still wrap.
    /// 上游 `textareaStyle`：常态白底 #ffffff、disabled 灰底 #f5f7fa。
    func testTextareaResolvedBackground() {
        XCTAssertEqual(UPTextarea().resolvedBackgroundValue(), "#ffffff")
        XCTAssertEqual(UPTextarea(disabled: true).resolvedBackgroundValue(), "#f5f7fa")
    }

    /// 上游 `textareaBorderColor`：亮 #dadbde / 暗 rgba(255,255,255,0.08)。
    func testTextareaResolvedBorderColor() {
        XCTAssertEqual(UPTextarea().resolvedBorderColorValue(isDark: false), "#dadbde")
        XCTAssertEqual(UPTextarea().resolvedBorderColorValue(isDark: true), "rgba(255, 255, 255, 0.08)")
    }

    /// 上游 `fieldStyle.color` / `textareaStyle.color`：content(#606266)，不随 disabled 变色。
    func testTextareaResolvedTextColor() {
        XCTAssertEqual(UPTextarea().resolvedTextColorValue(), "#606266")
        XCTAssertEqual(UPTextarea(disabled: true).resolvedTextColorValue(), "#606266")
    }

    func testResolvedLineLimitMapsAutoHeightSafely() {
        XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: false), 1...Int.max)
        XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: true), 3...8)
    }

    func testValueCarryingFocusAndBlurFireAlongsideTheLegacyHooks() {
        var events: [String] = []
        let textarea = UPTextarea(
            onFocusValue: { events.append("focusValue:\($0)") },
            onBlurValue: { events.append("blurValue:\($0)") }
        )
        .onFocus { events.append("focus") }
        .onBlur { events.append("blur") }

        textarea.onFocusHandler?()
        textarea.onFocusValueEvent?("typed")
        textarea.onBlurHandler?()
        textarea.onBlurValueEvent?("typed")

        XCTAssertEqual(events, ["focus", "focusValue:typed", "blur", "blurValue:typed"])
    }

    func testLineCountCountsNewlineSeparatedRows() {
        XCTAssertEqual(UPTextarea.lineCount(in: ""), 0)
        XCTAssertEqual(UPTextarea.lineCount(in: "single"), 1)
        XCTAssertEqual(UPTextarea.lineCount(in: "alpha\nbeta"), 2)
        XCTAssertEqual(UPTextarea.lineCount(in: "alpha\nbeta\n"), 2)
    }

    /// Upstream types `height` as `String | Number`.
    func testHeightAcceptsUpstreamStringAndNumberForms() {
        XCTAssertEqual(UPTextarea(height: 120).height, 120)
        XCTAssertEqual(UPTextarea(height: "120").height, 120)
        XCTAssertEqual(UPTextarea(height: "120px").height, 120)
        XCTAssertEqual(UPTextarea(height: "invalid").height, UPConfig.textarea.height)
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

    func testFormPropValueTakesPrecedenceOverModelValueAndLegacyBindings() {
        let formBox = TextareaModelBox(["bio": .string("form")])
        let form = UPFormContext(model: formBox.binding, controller: UPFormController())
        let modelValueBox = TextareaTextBox("model")
        let legacyTextBox = TextareaTextBox("legacy")
        let localTextBox = TextareaTextBox("local")

        XCTAssertEqual(
            UPTextarea.value(
                prop: "bio",
                form: form,
                modelValue: modelValueBox.binding,
                directText: legacyTextBox.binding,
                fallbackText: localTextBox.binding
            ),
            "form"
        )
    }

    func testCommitFormatsThenReportsTheNativeLineCount() {
        let modelValueBox = TextareaTextBox("old")
        let localTextBox = TextareaTextBox("local")
        var changes: [String] = []
        var lineCounts: [Int] = []

        UPTextarea.commit(
            "alpha\nbeta ",
            prop: "",
            form: nil,
            modelValue: modelValueBox.binding,
            directText: nil,
            fallbackText: localTextBox.binding,
            maxlength: -1,
            readonly: false,
            formatter: { $0.trimmingCharacters(in: .whitespaces) },
            onChange: { changes.append($0) },
            onLineChange: { lineCounts.append($0) }
        )

        XCTAssertEqual(modelValueBox.value, "alpha\nbeta")
        XCTAssertEqual(localTextBox.value, "local")
        XCTAssertEqual(changes, ["alpha\nbeta"])
        XCTAssertEqual(lineCounts, [2])
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
