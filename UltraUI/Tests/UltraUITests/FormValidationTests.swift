import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class FormValidationTests: XCTestCase {
    func testControllerUsesFirstFailingRuleAndClearsErrors() {
        let box = FormModelBox(["email": .string("")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: ["email": [
                UPFormRule(required: true, message: "请输入邮箱"),
                UPFormRule(pattern: #".+@.+\..+"#, message: "邮箱格式不正确")
            ]],
            controller: controller
        )
        context.connectController()

        XCTAssertFalse(controller.validateField("email"))
        XCTAssertEqual(controller.errors["email"], "请输入邮箱")

        box.model = ["email": .string("dev@example.com")]
        XCTAssertTrue(controller.validateField("email"))
        XCTAssertNil(controller.errors["email"])

        controller.clearValidate()
        XCTAssertTrue(controller.errors.isEmpty)
    }

    func testTriggerFiltersRulesUntilExplicitValidation() {
        let box = FormModelBox(["name": .string("ab")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: ["name": [UPFormRule(min: 3, message: "至少 3 个字符", trigger: "blur")]],
            controller: controller
        )
        context.connectController()

        XCTAssertTrue(context.validate(prop: "name", trigger: "change"))
        XCTAssertFalse(context.validate(prop: "name", trigger: "blur"))
        XCTAssertFalse(controller.validateField("name"))
    }

    func testRequiredTreatsEmptyStringsAndContainersAsMissing() {
        let rule = UPFormRule(required: true, message: "必填")

        XCTAssertEqual(rule.errorMessage(for: .string(""), model: [:]), "必填")
        XCTAssertEqual(rule.errorMessage(for: .null, model: [:]), "必填")
        XCTAssertEqual(rule.errorMessage(for: .array([]), model: [:]), "必填")
        XCTAssertEqual(rule.errorMessage(for: .object([:]), model: [:]), "必填")
        XCTAssertNil(rule.errorMessage(for: .array([.string("value")]), model: [:]))
    }

    func testLengthRulesSupportStringsAndArrays() {
        XCTAssertEqual(
            UPFormRule(min: 3, message: "太短").errorMessage(for: .string("ab"), model: [:]),
            "太短"
        )
        XCTAssertEqual(
            UPFormRule(max: 2, message: "太长").errorMessage(for: .array([1, 2, 3]), model: [:]),
            "太长"
        )
        XCTAssertEqual(
            UPFormRule(length: 2, message: "长度不对").errorMessage(for: .array([1]), model: [:]),
            "长度不对"
        )
        XCTAssertNil(UPFormRule(min: 3, message: "太短").errorMessage(for: .number(2), model: [:]))
    }

    func testPatternAndCustomValidatorReturnRuleErrors() {
        XCTAssertEqual(
            UPFormRule(pattern: #"^[0-9]+$"#, message: "仅数字").errorMessage(for: .string("abc"), model: [:]),
            "仅数字"
        )
        XCTAssertEqual(
            UPFormRule(pattern: "[", message: "正则无效").errorMessage(for: .string("abc"), model: [:]),
            "正则无效"
        )
        XCTAssertEqual(
            UPFormRule(message: "默认错误", validator: { value, _ in
                value.stringValue == "taken" ? "用户名已存在" : nil
            }).errorMessage(for: .string("taken"), model: [:]),
            "用户名已存在"
        )
        XCTAssertNil(
            UPFormRule(validator: { _, _ in "" }).errorMessage(for: .string("value"), model: [:])
        )
    }

    func testControllerValidatesAllFieldsAndCanClearSelectedErrors() {
        let box = FormModelBox(["email": .string(""), "name": .string("")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: [
                "email": [UPFormRule(required: true, message: "请输入邮箱")],
                "name": [UPFormRule(required: true, message: "请输入姓名")]
            ],
            controller: controller
        )
        context.connectController()

        XCTAssertFalse(controller.validate())
        XCTAssertEqual(controller.errors["email"], "请输入邮箱")
        XCTAssertEqual(controller.errors["name"], "请输入姓名")

        controller.clearValidate(["email"])
        XCTAssertNil(controller.errors["email"])
        XCTAssertEqual(controller.errors["name"], "请输入姓名")
    }

    func testContextSetWritesModelAndValidatesOnlyChangeRules() {
        let box = FormModelBox(["name": .string("ready")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: ["name": [UPFormRule(required: true, message: "请输入姓名", trigger: "change")]],
            controller: controller
        )
        context.connectController()

        context.set(.string(""), for: "name", trigger: "change")
        XCTAssertEqual(UPFormValue.value(at: "name", in: box.model), .string(""))
        XCTAssertEqual(controller.errors["name"], "请输入姓名")

        context.set(.string("Lin"), for: "name", trigger: "change")
        XCTAssertEqual(UPFormValue.value(at: "name", in: box.model), .string("Lin"))
        XCTAssertNil(controller.errors["name"])
    }

    func testNestedFormExampleValidatesAndWritesModel() {
        let box = FormModelBox([
            "account": .object(["email": .string(""), "password": .string("")]),
            "bio": .string("")
        ])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: [
                "account.email": [UPFormRule(required: true, message: "请输入邮箱")],
                "account.password": [UPFormRule(min: 6, message: "密码至少 6 位")]
            ],
            controller: controller
        )
        context.connectController()

        context.set(.string("dev@example.com"), for: "account.email", trigger: "change")
        context.set(.string("123456"), for: "account.password", trigger: "change")

        XCTAssertTrue(controller.validate())
        XCTAssertEqual(
            UPFormValue.value(at: "account.email", in: box.model),
            .string("dev@example.com")
        )
    }

    func testUnknownRuleTriggerRunsOnlyForExplicitValidation() {
        let box = FormModelBox(["name": .string("ab")])
        let controller = UPFormController()
        let context = UPFormContext(
            model: box.binding,
            rules: ["name": [UPFormRule(min: 3, message: "至少 3 个字符", trigger: "manual")]],
            controller: controller
        )
        context.connectController()

        XCTAssertTrue(context.validate(prop: "name", trigger: "change"))
        XCTAssertNil(controller.errors["name"])
        XCTAssertFalse(controller.validateField("name"))
        XCTAssertEqual(controller.errors["name"], "至少 3 个字符")
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
