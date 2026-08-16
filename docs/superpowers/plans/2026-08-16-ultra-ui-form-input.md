# UltraUI Form Input Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a uview-plus-compatible SwiftUI form layer with nested string `prop` paths, synchronous rules, central validation, `UPInput`, and `UPTextarea`.

**Architecture:** A recursive `UPFormValue` stores a SwiftUI-bound `UPFormModel` and resolves dot-separated object paths plus numeric array segments. `UPForm` creates one observable context that is propagated with `environmentObject`; `UPFormItem`, `UPInput`, and `UPTextarea` use the shared context for prop-based reads, writes, triggers, and errors. An optional caller-owned `UPFormController` exposes imperative validation without retaining the model.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Swift Package Manager, XcodeGen, iOS 17.0+.

## Global Constraints

- Keep the Package platform floor at iOS 17.0 and macOS 14.0; do not add third-party dependencies.
- Preserve existing source grouping (`Core`, `Components`) and add a focused `Forms` source directory for form-specific state and validation types.
- Use uview-plus-style string parameters and safe fallbacks: unknown `trigger`, `border`, `type`, `labelPosition`, and `errorType` must not crash.
- `UPForm` must accept `Binding<UPFormModel>` and string `prop` paths; `UPInput` and `UPTextarea` must also work with direct `Binding<String>` outside a form.
- Support only synchronous validation in this phase: `required`, `min`, `max`, `length`, regex `pattern`, and synchronous `validator`.
- Do not add picker, date, number-box, code-input, remote validation, keyboard-management, or cross-field dependency APIs.
- Every production behavior change starts with a failing XCTest, followed by the minimal implementation and a focused green test.
- Re-run `swift test --package-path UltraUI`, XcodeGen, and iOS Simulator tests before the final commit.

---

### Task 1: Recursive Form Model and Prop-Path Operations

**Files:**
- Create: `UltraUI/Sources/UltraUI/Forms/UPFormValue.swift`
- Create: `UltraUI/Tests/UltraUITests/FormValueTests.swift`

**Interfaces:**
- Consumes: Foundation only.
- Produces:
  ```swift
  public enum UPFormValue: Equatable {
      case string(String)
      case number(Double)
      case bool(Bool)
      case object([String: UPFormValue])
      case array([UPFormValue])
      case null

      public var stringValue: String { get }
      public static func value(at prop: String, in model: UPFormModel) -> UPFormValue
      public static func set(_ value: UPFormValue, at prop: String, in model: inout UPFormModel)
  }

  public typealias UPFormModel = [String: UPFormValue]
  ```
- Used by: Tasks 2–6.

- [ ] **Step 1: Write the failing model/path tests**

  Create `FormValueTests.swift`:

  ```swift
  import XCTest
  @testable import UltraUI

  final class FormValueTests: XCTestCase {
      func testLiteralValuesProduceExpectedStringValues() {
          let string: UPFormValue = "hello"
          let number: UPFormValue = 42
          let bool: UPFormValue = true
          let empty: UPFormValue = nil

          XCTAssertEqual(string.stringValue, "hello")
          XCTAssertEqual(number.stringValue, "42")
          XCTAssertEqual(bool.stringValue, "true")
          XCTAssertEqual(empty.stringValue, "")
      }

      func testNestedObjectAndArrayPathsReadAndWrite() {
          var model: UPFormModel = [
              "account": .object(["email": .string("old@example.com")]),
              "contacts": .array([.object(["email": .string("first@example.com")])])
          ]

          XCTAssertEqual(UPFormValue.value(at: "account.email", in: model), .string("old@example.com"))
          XCTAssertEqual(UPFormValue.value(at: "contacts.0.email", in: model), .string("first@example.com"))

          UPFormValue.set(.string("new@example.com"), at: "account.email", in: &model)
          UPFormValue.set(.string("second@example.com"), at: "contacts.1.email", in: &model)

          XCTAssertEqual(UPFormValue.value(at: "account.email", in: model), .string("new@example.com"))
          XCTAssertEqual(UPFormValue.value(at: "contacts.1.email", in: model), .string("second@example.com"))
      }

      func testWritingMissingObjectPathCreatesIntermediateObjects() {
          var model: UPFormModel = [:]
          UPFormValue.set(.string("Lin"), at: "profile.name", in: &model)

          XCTAssertEqual(UPFormValue.value(at: "profile.name", in: model), .string("Lin"))
          XCTAssertEqual(UPFormValue.value(at: "missing.path", in: model), .null)
      }
  }
  ```

- [ ] **Step 2: Run the focused test to verify it fails**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormValueTests
  ```

  Expected: compilation fails because `UPFormValue` and `UPFormModel` do not exist.

- [ ] **Step 3: Implement `UPFormValue` and path traversal**

  In `UPFormValue.swift`:

  ```swift
  import Foundation

  public enum UPFormValue: Equatable {
      case string(String)
      case number(Double)
      case bool(Bool)
      case object([String: UPFormValue])
      case array([UPFormValue])
      case null

      public var stringValue: String {
          switch self {
          case .string(let value): return value
          case .number(let value): return value.rounded() == value ? String(Int(value)) : String(value)
          case .bool(let value): return value ? "true" : "false"
          case .object, .array, .null: return ""
          }
      }
  }

  public typealias UPFormModel = [String: UPFormValue]
  ```

  Add literal conformances for `String`, integer, floating point, boolean, `nil`, `[String: UPFormValue]`, and `[UPFormValue]`. Implement `value(at:in:)` by splitting a non-empty prop on `.` and traversing object keys or non-negative numeric array indexes. Implement `set(_:at:in:)` recursively: choose an object or array intermediate value based on whether the next path segment parses as a non-negative integer; grow arrays with `.null` values before assigning an indexed child; ignore an empty prop.

- [ ] **Step 4: Run focused tests to verify they pass**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormValueTests
  ```

  Expected: 3 passing tests.

- [ ] **Step 5: Commit the model task**

  ```bash
  git add UltraUI/Sources/UltraUI/Forms/UPFormValue.swift UltraUI/Tests/UltraUITests/FormValueTests.swift
  git commit -m "feat: add recursive form model"
  ```

---

### Task 2: Rules, Form Context, and Imperative Validation Controller

**Files:**
- Create: `UltraUI/Sources/UltraUI/Forms/UPFormRule.swift`
- Create: `UltraUI/Sources/UltraUI/Forms/UPFormContext.swift`
- Create: `UltraUI/Sources/UltraUI/Forms/UPFormController.swift`
- Create: `UltraUI/Tests/UltraUITests/FormValidationTests.swift`

**Interfaces:**
- Consumes: `UPFormValue`, `UPFormModel` from Task 1; SwiftUI `Binding`; Combine/SwiftUI `ObservableObject`.
- Produces:
  ```swift
  public struct UPFormRule {
      public init(required: Bool = false,
                  min: Int? = nil,
                  max: Int? = nil,
                  length: Int? = nil,
                  pattern: String? = nil,
                  message: String = "",
                  trigger: String = "submit",
                  validator: ((UPFormValue, UPFormModel) -> String?)? = nil)
  }
  public typealias UPFormRules = [String: [UPFormRule]]

  @MainActor
  public final class UPFormController: ObservableObject {
      @Published public private(set) var errors: [String: String]
      @discardableResult public func validate() -> Bool
      @discardableResult public func validateField(_ prop: String) -> Bool
      public func clearValidate(_ props: [String]? = nil)
  }
  ```
- Used by: Tasks 3–6.

- [ ] **Step 1: Write the failing rule and controller tests**

  Create `FormValidationTests.swift`:

  ```swift
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
  }

  @MainActor
  private final class FormModelBox {
      var model: UPFormModel
      init(_ model: UPFormModel) { self.model = model }
      var binding: Binding<UPFormModel> {
          Binding(get: { self.model }, set: { self.model = $0 })
      }
  }
  ```

- [ ] **Step 2: Run focused tests to verify they fail**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormValidationTests
  ```

  Expected: compilation fails because `UPFormRule`, `UPFormContext`, and `UPFormController` do not exist.

- [ ] **Step 3: Implement synchronous rule evaluation and controller linkage**

  In `UPFormRule.swift`, implement rule storage and an internal `errorMessage(for:model:)` that returns the first applicable error. Treat empty strings, `.null`, empty arrays, and empty objects as missing. Use `value.stringValue.count` for string length and array count for array length. Compile `pattern` with `NSRegularExpression`; return `message` for an invalid pattern. Call `validator` after built-in constraints and return its non-empty result.

  In `UPFormContext.swift`, implement an `@MainActor final class UPFormContext: ObservableObject` with a stored `Binding<UPFormModel>`, `UPFormRules`, `UPFormController`, `@Published private(set) var errors`, `value(for:)`, `set(_:for:trigger:)`, and `validate(prop:trigger:force:)`. `set` must mutate the bound model through `UPFormValue.set` and execute only rules whose trigger is `"change"` when called from an input change.

  In `UPFormController.swift`, keep a weak context reference assigned by `UPFormContext.connectController()`. `validate()` iterates sorted rule keys and forces all rules. `validateField(_:)` forces all rules for one prop. `clearValidate(nil)` clears every error; `clearValidate(["email"])` removes only the listed keys. Mirror context errors to the published public `errors` property after every mutation.

- [ ] **Step 4: Run focused tests to verify they pass**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormValidationTests
  ```

  Expected: 2 passing tests.

- [ ] **Step 5: Commit validation infrastructure**

  ```bash
  git add UltraUI/Sources/UltraUI/Forms/UPFormRule.swift \
          UltraUI/Sources/UltraUI/Forms/UPFormContext.swift \
          UltraUI/Sources/UltraUI/Forms/UPFormController.swift \
          UltraUI/Tests/UltraUITests/FormValidationTests.swift
  git commit -m "feat: add form validation controller"
  ```

---

### Task 3: Form Container, Item Layout, Defaults, and Error Presentation

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPForm.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPFormItem.swift`
- Modify: `UltraUI/Sources/UltraUI/Core/UPConfig.swift`
- Create: `UltraUI/Tests/UltraUITests/FormViewTests.swift`

**Interfaces:**
- Consumes: `UPFormModel`, `UPFormRules`, `UPFormContext`, `UPFormController`, `UPUnit`, `UPTheme`, `UPColor`.
- Produces:
  ```swift
  public struct UPForm<Content: View>: View {
      public init(model: Binding<UPFormModel>,
                  rules: UPFormRules = [:],
                  controller: UPFormController? = nil,
                  errorType: String = UPConfig.form.errorType,
                  @ViewBuilder content: @escaping () -> Content)
  }

  public struct UPFormItem<Content: View>: View {
      public init(label: String = UPConfig.formItem.label,
                  prop: String = UPConfig.formItem.prop,
                  required: Bool = UPConfig.formItem.required,
                  labelPosition: String = UPConfig.formItem.labelPosition,
                  labelWidth: String = UPConfig.formItem.labelWidth,
                  borderBottom: Bool = UPConfig.formItem.borderBottom,
                  help: String = UPConfig.formItem.help,
                  @ViewBuilder content: @escaping () -> Content)
  }
  ```
- Used by: Tasks 4–6.

- [ ] **Step 1: Write the failing container/item default and display-state tests**

  Create `FormViewTests.swift`:

  ```swift
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
          XCTAssertTrue(UPFormItem.shouldShowError(errorType: "message", error: "请输入邮箱"))
          XCTAssertFalse(UPFormItem.shouldShowError(errorType: "none", error: "请输入邮箱"))
          XCTAssertFalse(UPFormItem.shouldShowError(errorType: "message", error: ""))
      }
  }
  ```

- [ ] **Step 2: Run focused tests to verify they fail**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormViewTests
  ```

  Expected: compilation fails because `UPForm`, `UPFormItem`, and `UPConfig.form` do not exist.

- [ ] **Step 3: Add configuration and implement container/item views**

  Add these defaults in `UPConfig.swift`:

  ```swift
  public enum form {
      public static let errorType = "message"
  }
  public enum formItem {
      public static let label = ""
      public static let prop = ""
      public static let required = false
      public static let labelPosition = "left"
      public static let labelWidth = "90px"
      public static let borderBottom = true
      public static let help = ""
  }
  ```

  `UPForm` must create one `UPFormContext` as a `@StateObject`, using the optional supplied controller or one internally created by the context. Wrap content in `.environmentObject(context)`, call `context.connectController()` on appearance, and update the context's latest model/rules/error type whenever those inputs change.

  `UPFormItem` must read `@EnvironmentObject private var form: UPFormContext`, lay out label + content in an `HStack` for `"left"` and a `VStack` for `"top"`, render the required red asterisk before a non-empty label, apply `UPUnit.parse(labelWidth)`, and conditionally use `UPLine` for `borderBottom`. Add `internal static func shouldShowError(errorType:error:) -> Bool` that accepts only a non-empty error and resolved error type `"message"`; show that error in `theme.error` beneath content. Unknown `labelPosition` resolves to `"left"`; unknown `errorType` resolves to `"message"`.

- [ ] **Step 4: Run focused tests to verify they pass**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormViewTests
  ```

  Expected: 2 passing tests.

- [ ] **Step 5: Commit form layout components**

  ```bash
  git add UltraUI/Sources/UltraUI/Core/UPConfig.swift \
          UltraUI/Sources/UltraUI/Components/UPForm.swift \
          UltraUI/Sources/UltraUI/Components/UPFormItem.swift \
          UltraUI/Tests/UltraUITests/FormViewTests.swift
  git commit -m "feat: add form and form-item components"
  ```

---

### Task 4: `UPInput` with Prop Binding, Direct Binding, State, and Events

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPInput.swift`
- Modify: `UltraUI/Sources/UltraUI/Core/UPConfig.swift`
- Create: `UltraUI/Tests/UltraUITests/InputTests.swift`

**Interfaces:**
- Consumes: `UPFormContext` and `UPFormItem` from Tasks 2–3, `UPIcon`, `UPColor`, `UPTheme`.
- Produces:
  ```swift
  public struct UPInput: View {
      public init(prop: String = UPConfig.input.prop,
                  text: Binding<String>? = nil,
                  type: String = UPConfig.input.type,
                  placeholder: String = UPConfig.input.placeholder,
                  border: String = UPConfig.input.border,
                  inputAlign: String = UPConfig.input.inputAlign,
                  clearable: Bool = UPConfig.input.clearable,
                  disabled: Bool = UPConfig.input.disabled,
                  readonly: Bool = UPConfig.input.readonly,
                  prefixIcon: String = UPConfig.input.prefixIcon,
                  suffixIcon: String = UPConfig.input.suffixIcon,
                  maxlength: Int? = UPConfig.input.maxlength,
                  count: Bool = UPConfig.input.count)
  }
  ```
- Used by: Tasks 5–6.

- [ ] **Step 1: Write failing input defaults, truncation, and event-registration tests**

  Create `InputTests.swift`:

  ```swift
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
  }
  ```

- [ ] **Step 2: Run focused tests to verify they fail**

  Run:

  ```bash
  swift test --package-path UltraUI --filter InputTests
  ```

  Expected: compilation fails because `UPInput` and `UPConfig.input` do not exist.

- [ ] **Step 3: Implement `UPInput`**

  Add `UPConfig.input` defaults:

  ```swift
  public enum input {
      public static let prop = ""
      public static let type = "text"
      public static let placeholder = ""
      public static let border = "surround"
      public static let inputAlign = "left"
      public static let clearable = false
      public static let disabled = false
      public static let readonly = false
      public static let prefixIcon = ""
      public static let suffixIcon = ""
      public static let maxlength: Int? = nil
      public static let count = false
  }
  ```

  `UPInput` must use `@EnvironmentObject` form context when it has a non-empty `prop`, otherwise use `text` and finally a local empty binding. Resolve `type == "password"` with `SecureField`, otherwise use `TextField`. Enforce `maxlength` through `truncated(_:maxlength:)` in the binding setter. `disabled` disables the field; `readonly` leaves it visually enabled but routes changes back to the previous value. Add a trailing clear button only when `clearable`, the current value is non-empty, and the field is neither disabled nor readonly. Render optional prefix/suffix icons using `UPIcon`; apply `border` as surround, bottom line, or no border with `UPLine`/theme colors; unknown border resolves to surround. On text writes call form `set(_:for:trigger: "change")` or direct binding then invoke `onChangeHandler`; use `FocusState` to invoke focus/blur handlers and `form.validate(prop:trigger: "blur")` on focus loss.

  Add public builder modifiers that copy the view exactly as the existing `UPButton` event modifiers do:

  ```swift
  func onChange(_ action: @escaping (String) -> Void) -> UPInput
  func onFocus(_ action: @escaping () -> Void) -> UPInput
  func onBlur(_ action: @escaping () -> Void) -> UPInput
  ```

- [ ] **Step 4: Run focused tests to verify they pass**

  Run:

  ```bash
  swift test --package-path UltraUI --filter InputTests
  ```

  Expected: 2 passing tests.

- [ ] **Step 5: Commit input component**

  ```bash
  git add UltraUI/Sources/UltraUI/Core/UPConfig.swift \
          UltraUI/Sources/UltraUI/Components/UPInput.swift \
          UltraUI/Tests/UltraUITests/InputTests.swift
  git commit -m "feat: add form input component"
  ```

---

### Task 5: `UPTextarea` with Character Limits, Auto-Height Mapping, and Events

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPTextarea.swift`
- Modify: `UltraUI/Sources/UltraUI/Core/UPConfig.swift`
- Create: `UltraUI/Tests/UltraUITests/TextareaTests.swift`

**Interfaces:**
- Consumes: `UPFormContext`, `UPInput.truncated(_:maxlength:)`, `UPTheme`, `UPColor` from Tasks 2–4.
- Produces:
  ```swift
  public struct UPTextarea: View {
      public init(prop: String = UPConfig.textarea.prop,
                  text: Binding<String>? = nil,
                  placeholder: String = UPConfig.textarea.placeholder,
                  maxlength: Int? = UPConfig.textarea.maxlength,
                  count: Bool = UPConfig.textarea.count,
                  disabled: Bool = UPConfig.textarea.disabled,
                  readonly: Bool = UPConfig.textarea.readonly,
                  height: Double = UPConfig.textarea.height,
                  autoHeight: Bool = UPConfig.textarea.autoHeight)
  }
  ```
- Used by: Task 6.

- [ ] **Step 1: Write failing textarea default, truncation, and layout-mode tests**

  Create `TextareaTests.swift`:

  ```swift
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
      }

      func testResolvedLineLimitMapsAutoHeightSafely() {
          XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: false), 1...1)
          XCTAssertEqual(UPTextarea.resolvedLineLimit(autoHeight: true), 3...8)
      }
  }
  ```

- [ ] **Step 2: Run focused tests to verify they fail**

  Run:

  ```bash
  swift test --package-path UltraUI --filter TextareaTests
  ```

  Expected: compilation fails because `UPTextarea` and `UPConfig.textarea` do not exist.

- [ ] **Step 3: Implement `UPTextarea`**

  Add `UPConfig.textarea` defaults:

  ```swift
  public enum textarea {
      public static let prop = ""
      public static let placeholder = ""
      public static let maxlength: Int? = nil
      public static let count = false
      public static let disabled = false
      public static let readonly = false
      public static let height: Double = 100
      public static let autoHeight = false
  }
  ```

  Use the same prop-first binding rule, focus event storage, change trigger, blur trigger, readonly behavior, and character truncation as `UPInput`. Implement multiline text with `TextField("", text:axis: .vertical)` and `lineLimit(resolvedLineLimit(autoHeight:))`, showing a theme-colored placeholder overlay while empty. Use a fixed `frame(minHeight: height)` only when `autoHeight` is false; when true, omit fixed height and use `3...8` lines. Display a `"current/max"` counter when `count` is true and a max is supplied, otherwise show `"current"` when `count` is true. Expose `onChange`, `onFocus`, and `onBlur` modifiers with the same names and behavior as `UPInput`.

- [ ] **Step 4: Run focused tests to verify they pass**

  Run:

  ```bash
  swift test --package-path UltraUI --filter TextareaTests
  ```

  Expected: 2 passing tests.

- [ ] **Step 5: Commit textarea component**

  ```bash
  git add UltraUI/Sources/UltraUI/Core/UPConfig.swift \
          UltraUI/Sources/UltraUI/Components/UPTextarea.swift \
          UltraUI/Tests/UltraUITests/TextareaTests.swift
  git commit -m "feat: add textarea component"
  ```

---

### Task 6: Form Demo, Public Documentation, and End-to-End Verification

**Files:**
- Create: `Demo/FormDemoView.swift`
- Modify: `Demo/HomeView.swift`
- Modify: `README.md`
- Modify if regenerated: `UltraUIDemo.xcodeproj/project.pbxproj`
- Test: `UltraUI/Tests/UltraUITests/FormValidationTests.swift`

**Interfaces:**
- Consumes: all types from Tasks 1–5 plus `UPButton`, `UPToast`, and existing demo navigation.
- Produces: a user-runnable Form demo and documented usage of the new public API.

- [ ] **Step 1: Write the failing Demo/API compilation exercise**

  Add this integration-style test to `FormValidationTests.swift`:

  ```swift
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

      context.set("dev@example.com", for: "account.email", trigger: "change")
      context.set("123456", for: "account.password", trigger: "change")

      XCTAssertTrue(controller.validate())
      XCTAssertEqual(UPFormValue.value(at: "account.email", in: box.model), .string("dev@example.com"))
  }
  ```

- [ ] **Step 2: Run the focused integration test to verify it fails before completing prior tasks**

  Run:

  ```bash
  swift test --package-path UltraUI --filter FormValidationTests/testNestedFormExampleValidatesAndWritesModel
  ```

  Expected before Task 2 is complete: compilation fails because the form context/controller APIs do not exist. Expected after Tasks 1–5: the selected test passes.

- [ ] **Step 3: Add the Form demo**

  Create `Demo/FormDemoView.swift` with a nested `UPFormModel`, a `@StateObject private var form = UPFormController()`, email/password/bio fields, and a Submit `UPButton`. The button must call `form.validate()` and show `UPToast.show(message: "校验通过", type: "success")` when true; otherwise show `UPToast.show(message: "请检查表单内容", type: "error")`. Include a disabled direct-binding input and a read-only direct-binding textarea so both non-form bindings are visible. Add `NavigationLink("Form") { FormDemoView() }` under a new `Section("表单")` in `HomeView.swift`.

- [ ] **Step 4: Document the new components**

  Update the README component list with `UPForm` / `UPFormItem` / `UPInput` / `UPTextarea`. Add the following usage excerpt after the existing Popup/Modal examples:

  ```swift
  @State private var model: UPFormModel = [
      "email": ""
  ]
  @StateObject private var form = UPFormController()

  UPForm(
      model: $model,
      rules: ["email": [UPFormRule(required: true, message: "请输入邮箱")]],
      controller: form
  ) {
      UPFormItem(label: "邮箱", prop: "email") {
          UPInput(prop: "email", placeholder: "name@example.com", clearable: true)
      }
  }
  ```

- [ ] **Step 5: Run all package tests and regenerate the Demo project**

  Run:

  ```bash
  swift test --package-path UltraUI
  xcodegen generate
  xcodebuild \
    -project UltraUIDemo.xcodeproj \
    -scheme UltraUIDemo \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    test CODE_SIGNING_ALLOWED=NO
  ```

  Expected: every package and simulator test passes with no compiler errors.

- [ ] **Step 6: Install and launch the Demo for visual verification**

  Run:

  ```bash
  APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*/Build/Products/Debug-iphonesimulator/UltraUIDemo.app' -type d -print | head -n 1)
  xcrun simctl install booted "$APP_PATH"
  xcrun simctl launch booted com.xyito.ultrauidemo
  xcrun simctl io booted screenshot /tmp/ultrauidemo-form.png
  ```

  Verify the Home view has a Form entry and the Form screen renders field labels, inputs, error space, textarea counter, and submit action without an application crash.

- [ ] **Step 7: Commit the Demo, docs, and verification changes**

  ```bash
  git add Demo/FormDemoView.swift Demo/HomeView.swift README.md UltraUIDemo.xcodeproj/project.pbxproj UltraUI/Tests/UltraUITests/FormValidationTests.swift
  git commit -m "feat: add form component demo"
  ```

---

## Self-Review

1. **Spec coverage:** Task 1 covers recursive values and nested props. Task 2 covers built-in rules, triggers, custom synchronous validation, errors, and imperative APIs. Task 3 covers `UPForm` / `UPFormItem`, defaults, labels, borders, and error presentation. Tasks 4–5 cover Input and Textarea props/events/behavior. Task 6 covers Demo, README, package tests, simulator tests, installation, launch, and screenshot verification.
2. **Placeholder scan:** No deferred implementation markers or generic test steps are present. Each task has a concrete file list, test body, expected failure, production responsibility, pass command, and commit command.
3. **Type consistency:** `UPFormModel` is `[String: UPFormValue]` in every task. All component `prop` labels are `String`. `UPFormController` uses `validate()`, `validateField(_:)`, and `clearValidate(_:)` everywhere. `UPFormContext.set(_:for:trigger:)` is the sole prop-based mutation API used by Input, Textarea, and the integration test.
