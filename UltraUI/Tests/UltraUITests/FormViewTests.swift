import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class FormViewTests: XCTestCase {
    func testFormAndItemDefaults() {
        let form = UPForm(model: .constant([:])) { EmptyView() }
        let item = UPFormItem(label: "邮箱", prop: "account.email") { EmptyView() }

        XCTAssertEqual(form.errorType, "message")
        XCTAssertEqual(item.labelPosition, "left")
        XCTAssertEqual(item.labelWidth, "90px")
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
