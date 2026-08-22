import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class FormViewTests: XCTestCase {
    func testFormAndItemDefaults() {
        let form = UPForm(model: .constant([:])) { EmptyView() }
        let item = UPFormItem(label: "邮箱", prop: "account.email") { EmptyView() }

        XCTAssertNil(UPConfig.formItem.borderBottom)
        XCTAssertEqual(form.errorType, "message")
        XCTAssertEqual(item.labelPosition, "left")
        XCTAssertEqual(item.labelWidth, "45px")
        XCTAssertTrue(item.borderBottom)
    }

    func testItemOnlyShowsMessageErrorForMessageModeAndNonEmptyError() {
        XCTAssertTrue(UPFormItem<EmptyView>.shouldShowError(errorType: "message", error: "请输入邮箱"))
        XCTAssertFalse(UPFormItem<EmptyView>.shouldShowError(errorType: "none", error: "请输入邮箱"))
        XCTAssertFalse(UPFormItem<EmptyView>.shouldShowError(errorType: "message", error: ""))
    }

    func testUnknownPresentationValuesResolveToSafeDefaults() {
        XCTAssertEqual(UPForm<EmptyView>.resolvedErrorType("unexpected"), "message")
        XCTAssertEqual(UPFormItem<EmptyView>.resolvedLabelPosition("unexpected"), "left")
        XCTAssertTrue(UPFormItem<EmptyView>.shouldShowError(errorType: "unexpected", error: "请输入邮箱"))
    }

    func testContextUpdatesToTheLatestModelRulesAndErrorType() {
        let original = FormModelBox(["name": .string("old")])
        let replacement = FormModelBox(["name": .string("")])
        let controller = UPFormController()
        let context = UPFormContext(model: original.binding, controller: controller)
        context.connectController()

        context.update(
            model: replacement.binding,
            rules: ["name": [UPFormRule(required: true, message: "请输入姓名")]],
            errorType: "unexpected"
        )

        XCTAssertEqual(context.value(for: "name"), .string(""))
        XCTAssertEqual(context.errorType, "message")
        XCTAssertFalse(controller.validateField("name"))
        XCTAssertEqual(controller.errors["name"], "请输入姓名")
    }

    /// `border-bottom` turns the field underline red instead of printing a
    /// message; `toast` and `none` print nothing inline.
    func testBorderBottomErrorTypeTintsTheUnderlineInsteadOfPrintingAMessage() {
        XCTAssertTrue(
            UPFormItem<EmptyView>.shouldTintBorder(errorType: "border-bottom", error: "请输入邮箱")
        )
        XCTAssertFalse(
            UPFormItem<EmptyView>.shouldTintBorder(errorType: "border-bottom", error: "")
        )
        XCTAssertFalse(
            UPFormItem<EmptyView>.shouldTintBorder(errorType: "message", error: "请输入邮箱")
        )
        XCTAssertFalse(
            UPFormItem<EmptyView>.shouldShowError(errorType: "border-bottom", error: "请输入邮箱")
        )
        XCTAssertFalse(
            UPFormItem<EmptyView>.shouldShowError(errorType: "toast", error: "请输入邮箱")
        )
    }

    /// Upstream `errorType: 'toast'` surfaces the first error through the toast
    /// centre rather than inline.
    func testToastErrorTypeRoutesTheFirstErrorToTheToastCentre() {
        XCTAssertEqual(
            UPFormContext.toastMessage(errorType: "toast", errors: ["b": "第二个", "a": "第一个"]),
            "第一个"
        )
        XCTAssertNil(UPFormContext.toastMessage(errorType: "message", errors: ["a": "第一个"]))
        XCTAssertNil(UPFormContext.toastMessage(errorType: "toast", errors: [:]))
    }

    /// The instance property is what a host observes to drive its `UPToastCenter`;
    /// presentation stays host-owned, as it is for every other component.
    func testContextExposesTheToastMessageForTheHostToPresent() {
        let box = FormModelBox(["email": .string("")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: ["email": [UPFormRule(required: true, message: "请输入邮箱")]],
            controller: controller,
            errorType: "toast"
        )
        context.connectController()

        XCTAssertNil(context.toastMessage)

        XCTAssertFalse(controller.validate())

        XCTAssertEqual(context.toastMessage, "请输入邮箱")
    }

    func testLabelAndErrorSlotsRecordTheirContent() {
        let plain = UPFormItem(label: "邮箱", prop: "email") { EmptyView() }
        XCTAssertFalse(plain.hasLabelSlot)
        XCTAssertFalse(plain.hasErrorSlot)

        let slotted = UPFormItem(label: "邮箱", prop: "email") { EmptyView() }
            .label { Text("自定义标签") }
            .error { Text("自定义错误") }

        XCTAssertTrue(slotted.hasLabelSlot)
        XCTAssertTrue(slotted.hasErrorSlot)
    }
}

@MainActor
private final class FormModelBox {
    var model: UPFormModel

    init(_ model: UPFormModel) {
        self.model = model
    }

    var binding: Binding<UPFormModel> {
        Binding(get: { self.model }, set: { self.model = $0 })
    }
}
