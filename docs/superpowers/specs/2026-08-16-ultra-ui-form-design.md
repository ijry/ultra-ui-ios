# ultra-ui-ios 第二期：表单输入组件设计

> 状态：设计已确认，等待规格文档审阅

## 目标

在首期 9 个核心组件之上，增加与 uview-plus 表单 API 尽量一致的 SwiftUI 表单输入层。重点保留 `model`、字符串 `prop`、`rules`、字段/全表单验证和输入事件，同时使用 SwiftUI 原生输入控件、焦点与环境传播机制实现。

## 本期范围

新增以下公共类型：

- `UPFormValue`
- `UPFormModel`
- `UPFormRule`
- `UPFormController`
- `UPForm`
- `UPFormItem`
- `UPInput`
- `UPTextarea`

同步新增：

- `FormDemoView` 及首页入口
- 模型路径、规则、控制器、Input、Textarea、FormItem 的单元测试

## 设计原则

1. **高兼容优先**：`UPForm` 使用 `model`、`rules`，字段使用字符串 `prop`，控制器提供 `validate()` 等集中式 API。
2. **SwiftUI 原生承载**：输入组件通过 `TextField`、`SecureField`、`TextEditor`、`FocusState` 和环境上下文实现，不模拟 Vue 或小程序生命周期。
3. **保留直接绑定入口**：`UPInput(text:)` 与 `UPTextarea(text:)` 可脱离 `UPForm` 单独使用；若同时提供 `prop` 且在 `UPForm` 内，表单字段绑定优先。
4. **确定性校验**：本期内置规则和自定义同步校验器；不引入网络异步校验及隐式重试。
5. **字符串风格参数**：`type: "password"`、`border: "surround"`、`trigger: "blur"` 等沿用既有组件的字符串参数约定，非法值回退到默认行为。

## 数据模型

### `UPFormValue`

`UPFormValue` 是递归值枚举，支持：

```swift
public enum UPFormValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: UPFormValue])
    case array([UPFormValue])
    case null
}

public typealias UPFormModel = [String: UPFormValue]
```

它将实现字符串、数字、布尔和字典字面量转换，使调用端可自然书写：

```swift
@State private var model: UPFormModel = [
    "account": [
        "email": "",
        "password": ""
    ],
    "bio": ""
]
```

### 路径约定

- `prop` 以点分路径定位模型字段，如 `"account.email"`。
- 数组索引使用数字片段，如 `"contacts.0.email"`。
- 读取不存在的字段返回 `.null`；向不存在的对象路径写入字符串时自动创建中间对象。
- `UPInput` 与 `UPTextarea` 将字段值转换为字符串；`number`、`bool` 和 `null` 的显示使用稳定的文本表示。

## 表单上下文与控制器

`UPForm` 通过私有环境值注入表单上下文。上下文持有模型绑定、规则、控制器及当前验证错误，从而让 `UPFormItem`、`UPInput` 和 `UPTextarea` 仅凭 `prop` 读写同一字段。

```swift
@MainActor
public final class UPFormController: ObservableObject {
    @Published public private(set) var errors: [String: String] = [:]

    @discardableResult public func validate() -> Bool
    @discardableResult public func validateField(_ prop: String) -> Bool
    public func clearValidate(_ props: [String]? = nil)
}
```

控制器由调用方以 `@StateObject` 持有并传给 `UPForm`。它不持有外部模型；每次 `UPForm` 渲染都会将当前表单上下文连接给控制器，避免陈旧绑定。

## 校验规则

```swift
public struct UPFormRule {
    public var required: Bool
    public var min: Int?
    public var max: Int?
    public var length: Int?
    public var pattern: String?
    public var message: String
    public var trigger: String
    public var validator: ((UPFormValue, UPFormModel) -> String?)?
}

public typealias UPFormRules = [String: [UPFormRule]]
```

### 规则行为

- `required`：空字符串、`.null`、空数组和空对象视为缺失。
- `min` / `max` / `length`：对字符串按字符数校验，对数组按元素数校验。
- `pattern`：对字符串执行正则匹配；无效正则返回规则自身的错误信息，不崩溃。
- `validator`：同步自定义校验器；返回非空字符串即为错误文案。
- 同一字段规则按声明顺序执行，首个错误即停止。
- `trigger` 支持 `"change"`、`"blur"`、`"submit"`；未知值仅在显式 `validate` 时执行。
- `validate()` 和 `validateField(_:)` 忽略触发时机，执行目标字段的全部规则。

本期不包含 `asyncValidator`、服务端校验、跨字段自动依赖追踪或错误 Toast 模式。

## `UPForm` API

```swift
UPForm(
    model: $model,
    rules: rules,
    controller: form,
    errorType: "message"
) {
    // UPFormItem / input controls
}
```

- `model`：`Binding<UPFormModel>`。
- `rules`：`UPFormRules`，默认空字典。
- `controller`：默认新建控制器；需要外部验证时传入稳定的 `@StateObject` 实例。
- `errorType`：本期支持 `"message"` 和 `"none"`；未知值回退 `"message"`。
- 通过环境向子视图提供模型、规则、校验和字段错误。

## `UPFormItem` API

```swift
UPFormItem(
    label: "邮箱",
    prop: "account.email",
    required: true,
    labelPosition: "left",
    labelWidth: "90px",
    borderBottom: true
) {
    UPInput(prop: "account.email", placeholder: "name@example.com")
}
```

支持：`label`、`prop`、`required`、`labelPosition`、`labelWidth`、`borderBottom`、`help`、自定义内容。

- `labelPosition` 支持 `"left"` 和 `"top"`。
- `required` 仅影响必填星号展示；实际校验仍由 `rules` 决定。
- `errorType == "message"` 时在字段下方展示控制器中该 `prop` 的错误。

## `UPInput` API

```swift
UPInput(
    prop: "account.password",
    type: "password",
    placeholder: "至少 6 位",
    border: "surround",
    clearable: true,
    prefixIcon: "uicon-lock",
    maxlength: 32,
    count: true
)
.onChange { value in }
.onFocus { }
.onBlur { }
```

支持的主要 props：

- 绑定：`prop`、`text`（可选直接 `Binding<String>`）
- 外观：`placeholder`、`border`（`surround` / `bottom` / `none`）、`inputAlign`、`prefixIcon`、`suffixIcon`
- 行为：`type`（`text` / `password`）、`clearable`、`disabled`、`readonly`、`maxlength`、`count`
- 事件：`onChange`、`onFocus`、`onBlur`

当处于表单中且提供 `prop` 时，变更触发 `change` 校验，失焦触发 `blur` 校验。`readonly` 保持可聚焦但不允许改写，`disabled` 同时禁用交互。

## `UPTextarea` API

```swift
UPTextarea(
    prop: "bio",
    placeholder: "介绍一下自己",
    maxlength: 200,
    count: true,
    autoHeight: true,
    height: 100
)
```

支持：`prop` / `text`、`placeholder`、`maxlength`、`count`、`disabled`、`readonly`、`height`、`autoHeight`、`onChange`、`onFocus`、`onBlur`。

- `autoHeight == true` 映射为可增长的多行 SwiftUI 输入，并有合理行数上限。
- `autoHeight == false` 使用固定最小高度。
- 字符数限制应用于输入变更后，保证模型、展示和校验接收同一截断值。

## Demo

新增 `FormDemoView`，演示：

1. 嵌套 `account.email` / `account.password` 字段。
2. `required`、正则和最小长度规则。
3. 失焦、输入变化与提交时校验。
4. 密码输入、清除按钮、文本域、字数统计和禁用/只读状态。
5. 使用 `UPFormController.validate()` 显示通过或错误 Toast。

## 测试与验收

### 单元测试

- `UPFormValue` 的字面量转换、对象和数组路径读写。
- 字段不存在、非对象中间节点、数组下标和 `.null` 边界。
- 内置校验规则、无效正则、自定义校验和首错短路。
- `change`、`blur`、`submit` 触发过滤及控制器集中校验。
- Input / Textarea 的默认值、字符串参数回退、长度截断及直接/表单绑定优先级。
- FormItem 的错误展示状态和控制器错误清理。

### 集成验证

- `swift test --package-path UltraUI`
- 通过 XcodeGen 重新生成工程。
- iOS Simulator 的 `xcodebuild test`。
- 安装、启动 Demo，并检查 Form 页面可打开、输入、校验和 Toast 反馈。

## 非目标

- `UPPicker`、`UPDatePicker`、`UPNumberBox`、`UPCodeInput` 等输入派生组件。
- 远程/异步校验、跨字段依赖自动刷新。
- 小程序专属键盘、确认键、光标和表单事件参数。
- 完整 uview-plus 表单样式的逐像素复制。
