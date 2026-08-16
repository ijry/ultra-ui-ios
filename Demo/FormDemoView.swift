import SwiftUI
import UltraUI

struct FormDemoView: View {
    @State private var model: UPFormModel = [
        "account": .object([
            "email": .string(""),
            "password": .string("")
        ]),
        "bio": .string("")
    ]
    @StateObject private var form = UPFormController()
    @State private var disabledText = "此输入框已禁用"
    @State private var readonlyBio = "此文本域以 readonly 模式展示，内容不可修改。"

    private let rules: UPFormRules = [
        "account.email": [
            UPFormRule(required: true, message: "请输入邮箱", trigger: "blur"),
            UPFormRule(
                pattern: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
                message: "请输入有效的邮箱地址",
                trigger: "blur"
            )
        ],
        "account.password": [
            UPFormRule(required: true, message: "请输入密码", trigger: "change"),
            UPFormRule(min: 6, message: "密码至少 6 位", trigger: "change")
        ]
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("嵌套 prop、change / blur 校验、密码输入和文本域字数统计。")
                    .foregroundStyle(.secondary)

                UPForm(model: $model, rules: rules, controller: form) {
                    VStack(alignment: .leading, spacing: 16) {
                        UPFormItem(label: "邮箱", prop: "account.email", required: true) {
                            UPInput(
                                prop: "account.email",
                                placeholder: "name@example.com",
                                clearable: true
                            )
                        }

                        UPFormItem(label: "密码", prop: "account.password", required: true) {
                            UPInput(
                                prop: "account.password",
                                type: "password",
                                placeholder: "至少 6 位",
                                maxlength: 32,
                                count: true
                            )
                        }

                        UPFormItem(label: "个人简介", prop: "bio", labelPosition: "top") {
                            UPTextarea(
                                prop: "bio",
                                placeholder: "介绍一下自己",
                                maxlength: 200,
                                count: true,
                                height: 100,
                                autoHeight: true
                            )
                        }
                    }
                }

                UPButton(type: "primary", text: "提交校验", block: true) {
                    submit()
                }

                Text("独立绑定状态")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                UPInput(text: $disabledText, disabled: true)
                UPTextarea(text: $readonlyBio, readonly: true, height: 100)
            }
            .padding(20)
        }
        .navigationTitle("Form")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        if form.validate() {
            UPToast.show(message: "校验通过", type: "success")
        } else {
            UPToast.show(message: "请检查表单内容", type: "error")
        }
    }
}
