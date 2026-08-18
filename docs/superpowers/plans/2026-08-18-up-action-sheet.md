# UPActionSheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task with review checkpoints. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a SwiftUI-native `UPActionSheet` that preserves the uview-plus action-sheet props, action payload shape, close/select event order, and custom-content behavior without touching collaborators' dirty files.

**Architecture:** Keep defaults in a new `UPConfig.actionSheet` extension, keep action payloads in a small value type with typed common fields plus dynamic string values, and implement a non-generic `UPActionSheet` that stores an optional `AnyView` slot. Compose the existing committed `UPPopup` in bottom mode, but intercept its overlay tap so ActionSheet controls its own `closeOnClickOverlay` and `close` semantics.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Swift Package Manager, iOS 17+/macOS 14+.

## Global Constraints

- Preserve the uview-plus prop spellings and defaults, including the upstream `subnameKey` default spelling `"subnameKey"`.
- Use SwiftUI native views and `UPPopup`; do not expose UIKit/AppKit instances.
- Add only ActionSheet-specific files and docs; do not edit `UPConfig.swift`, `UPPopup.swift`, `UPOverlay.swift`, `UPModal.swift`, or any currently dirty collaborator file.
- Keep iOS 17+/macOS 14+ compatibility and Swift 6 strict-concurrency compatibility.
- Follow TDD: each production slice is preceded by a test that is run in a failing state for the intended reason.
- Run focused tests after each slice, then full package tests/build before claiming completion.
- Stage and commit only explicitly listed ActionSheet paths; never use `git reset`, `git clean`, or bulk staging.

## File Map

- Create: `UltraUI/Sources/UltraUI/Core/UPActionSheetConfig.swift` — isolated `UPConfig.actionSheet` defaults and the public unit-value alias.
- Create: `UltraUI/Sources/UltraUI/Components/UPActionSheetAction.swift` — typed action payload, dynamic values, and key lookup.
- Create: `UltraUI/Sources/UltraUI/Components/UPActionSheet.swift` — public SwiftUI view, event helpers, layout, slot, and fluent event modifiers.
- Create: `UltraUI/Tests/UltraUITests/ActionSheetTests.swift` — default, normalization, payload, event-order, and rendering tests.

---

### Task 1: Add failing contract tests for defaults and action payloads

**Files:**
- Create: `UltraUI/Tests/UltraUITests/ActionSheetTests.swift`

**Interfaces:**
- The tests define the required public surface before production types exist: `UPConfig.actionSheet`, `UPActionSheetUnitValue`, `UPActionSheetAction`, `UPActionSheetAction.value(for:)`, and `UPActionSheetAction.resolvedFontSize`.

- [ ] **Step 1: Write the failing tests.**

```swift
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ActionSheetTests: XCTestCase {
    func testDefaultsMatchUviewPlusActionSheet() {
        XCTAssertFalse(UPConfig.actionSheet.show)
        XCTAssertEqual(UPConfig.actionSheet.title, "")
        XCTAssertEqual(UPConfig.actionSheet.description, "")
        XCTAssertTrue(UPConfig.actionSheet.actions.isEmpty)
        XCTAssertEqual(UPConfig.actionSheet.nameKey, "name")
        XCTAssertEqual(UPConfig.actionSheet.subnameKey, "subnameKey")
        XCTAssertEqual(UPConfig.actionSheet.cancelText, "")
        XCTAssertTrue(UPConfig.actionSheet.closeOnClickAction)
        XCTAssertTrue(UPConfig.actionSheet.safeAreaInsetBottom)
        XCTAssertEqual(UPConfig.actionSheet.openType, "")
        XCTAssertTrue(UPConfig.actionSheet.closeOnClickOverlay)
        XCTAssertEqual(UPConfig.actionSheet.round, "0")
        XCTAssertEqual(UPConfig.actionSheet.wrapMaxHeight, "600px")
    }

    func testTypedActionPopulatesBothStandardSubnameKeys() {
        let action = UPActionSheetAction(
            id: "delete",
            name: "删除",
            subname: "删除后无法恢复",
            color: "#fa3534",
            fontSize: 16,
            disabled: true,
            loading: false
        )

        XCTAssertEqual(action.id, "delete")
        XCTAssertEqual(action.value(for: "name"), "删除")
        XCTAssertEqual(action.value(for: "subname"), "删除后无法恢复")
        XCTAssertEqual(action.value(for: "subnameKey"), "删除后无法恢复")
        XCTAssertEqual(action.color, "#fa3534")
        XCTAssertEqual(action.resolvedFontSize, 16)
        XCTAssertTrue(action.disabled)
        XCTAssertFalse(action.loading)
    }

    func testDynamicActionValuesHonorCustomKeys() {
        let action = UPActionSheetAction(
            id: "edit",
            values: [
                "label": "编辑",
                "detail": "修改当前内容"
            ]
        )

        XCTAssertEqual(action.value(for: "label"), "编辑")
        XCTAssertEqual(action.value(for: "detail"), "修改当前内容")
        XCTAssertEqual(action.value(for: "missing"), nil)
    }

    func testStringAndNumberDimensionsNormalizeSafely() {
        XCTAssertEqual(UPActionSheet.parseDimension("48px", fallback: 0), 48)
        XCTAssertEqual(UPActionSheet.parseDimension("24rpx", fallback: 0), 24)
        XCTAssertEqual(UPActionSheet.parseDimension("bad", fallback: 7), 7)
        XCTAssertEqual(UPActionSheet.parseDimension("-4", fallback: 7), 7)
        XCTAssertEqual(UPActionSheet.parseDimension("infinity", fallback: 7), 7)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify the red state.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests
```

Expected: compilation fails because the ActionSheet configuration, action model, and view helpers do not exist. Do not implement production code before observing this failure.

- [ ] **Step 3: Record the intended failure, then proceed to Task 2.**

The failure must be missing symbols or missing initializers, not a test syntax error. If the test file itself fails to parse, fix only the test syntax and rerun the red command.

---

### Task 2: Implement isolated defaults, unit normalization, and action data

**Files:**
- Create: `UltraUI/Sources/UltraUI/Core/UPActionSheetConfig.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPActionSheetAction.swift`
- Modify: `UltraUI/Tests/UltraUITests/ActionSheetTests.swift`

**Interfaces:**
- Produces `public typealias UPActionSheetUnitValue = UPCheckboxUnitValue` so `String`, integer/floating numeric values, and `CGFloat` can be passed in the same style as existing components.
- Produces `public extension UPConfig { enum actionSheet { ... } }` with the exact defaults asserted in Task 1.
- Produces `public struct UPActionSheetAction: Identifiable, Equatable, Sendable` with `id`, `name`, `subname`, `color`, `fontSize`, `disabled`, `loading`, `openType`, `values`, `init(...)`, `init(values:)`, `value(for:)`, and `resolvedFontSize`.

- [ ] **Step 1: Add the smallest config and data-model implementation.**

`UPActionSheetConfig.swift` must contain only ActionSheet defaults and this alias:

```swift
import CoreGraphics

public typealias UPActionSheetUnitValue = UPCheckboxUnitValue

public extension UPConfig {
    enum actionSheet {
        public static let show = false
        public static let title = ""
        public static let description = ""
        public static let actions: [UPActionSheetAction] = []
        public static let nameKey = "name"
        public static let subnameKey = "subnameKey"
        public static let cancelText = ""
        public static let closeOnClickAction = true
        public static let safeAreaInsetBottom = true
        public static let openType = ""
        public static let closeOnClickOverlay = true
        public static let round = "0"
        public static let wrapMaxHeight = "600px"
    }
}
```

The typed action initializer must convert `fontSize` through `upCheckboxUnitValue`, populate `values["name"]`, `values["subname"]`, and `values["subnameKey"]` when those values are present, and keep explicit custom values intact. `value(for:)` checks the common typed fields first and then the dynamic dictionary. `resolvedFontSize` parses a finite non-negative point value and returns `nil` for invalid input.

- [ ] **Step 2: Run the focused tests and verify they pass.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests
```

Expected: all tests in `ActionSheetTests` pass; no ActionSheet view is required yet because the current tests only exercise the config, model, and static parser contract.

- [ ] **Step 3: Commit the independently green data slice.**

```bash
git add UltraUI/Sources/UltraUI/Core/UPActionSheetConfig.swift \
        UltraUI/Sources/UltraUI/Components/UPActionSheetAction.swift \
        UltraUI/Tests/UltraUITests/ActionSheetTests.swift
git diff --cached --name-status
git commit -m "feat: add action sheet data model"
```

Before committing, the staged name list must contain exactly those three paths.

---

### Task 3: Add failing tests and implement ActionSheet event semantics

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPActionSheet.swift`
- Modify: `UltraUI/Tests/UltraUITests/ActionSheetTests.swift`

**Interfaces:**
- Produces `@MainActor public struct UPActionSheet: View`.
- Produces internal testable helpers used by the view and tests:
  - `static func parseDimension(_ value: String, fallback: CGFloat) -> CGFloat`
  - `static func performSelection(_ action: UPActionSheetAction, show: Binding<Bool>, closeOnClickAction: Bool, onSelect: ((UPActionSheetAction) -> Void)?, onClose: (() -> Void)?)`
  - `static func performClose(show: Binding<Bool>, onClose: (() -> Void)?)`
  - `static func performOverlayTap(show: Binding<Bool>, closeOnClickOverlay: Bool, onClose: (() -> Void)?)`
  - `static func performContentTap(show: Binding<Bool>, closeOnClickAction: Bool, onClose: (() -> Void)?)`
- The helpers provide the one source of truth for UI gesture actions and preserve the specified callback ordering.

- [ ] **Step 1: Add failing event-order tests.**

Append these tests to `ActionSheetTests.swift`:

```swift
func testSelectionEmitsSelectThenBindingChangeThenClose() {
    var shown = true
    var events: [String] = []
    let binding = Binding(
        get: { shown },
        set: { shown = $0; events.append("show:\($0)") }
    )
    let action = UPActionSheetAction(id: "edit", name: "编辑")

    UPActionSheet.performSelection(
        action,
        show: binding,
        closeOnClickAction: true,
        onSelect: { events.append("select:\($0.name)") },
        onClose: { events.append("close") }
    )

    XCTAssertEqual(events, ["select:编辑", "show:false", "close"])
    XCTAssertFalse(shown)
}

func testSelectionCanRemainOpenWhenCloseOnClickActionIsFalse() {
    var shown = true
    var events: [String] = []
    let binding = Binding(get: { shown }, set: { shown = $0 })
    let action = UPActionSheetAction(id: "edit", name: "编辑")

    UPActionSheet.performSelection(
        action,
        show: binding,
        closeOnClickAction: false,
        onSelect: { _ in events.append("select") },
        onClose: { events.append("close") }
    )

    XCTAssertEqual(events, ["select"])
    XCTAssertTrue(shown)
}

func testDisabledAndLoadingActionsDoNotSelectOrClose() {
    for action in [
        UPActionSheetAction(id: "disabled", name: "禁用", disabled: true),
        UPActionSheetAction(id: "loading", name: "加载", loading: true)
    ] {
        var shown = true
        var events: [String] = []
        let binding = Binding(get: { shown }, set: { shown = $0 })

        UPActionSheet.performSelection(
            action,
            show: binding,
            closeOnClickAction: true,
            onSelect: { _ in events.append("select") },
            onClose: { events.append("close") }
        )

        XCTAssertTrue(shown)
        XCTAssertTrue(events.isEmpty)
    }
}

func testCancelAndAllowedOverlayCloseUpdateBindingBeforeClose() {
    var shown = true
    var events: [String] = []
    let binding = Binding(
        get: { shown },
        set: { shown = $0; events.append("show:\($0)") }
    )

    UPActionSheet.performClose(show: binding) { events.append("close") }
    XCTAssertEqual(events, ["show:false", "close"])

    shown = true
    events.removeAll()
    UPActionSheet.performOverlayTap(
        show: binding,
        closeOnClickOverlay: true,
        onClose: { events.append("close") }
    )
    XCTAssertEqual(events, ["show:false", "close"])
}

func testDisallowedOverlayDoesNothing() {
    var shown = true
    var closed = false
    let binding = Binding(get: { shown }, set: { shown = $0 })

    UPActionSheet.performOverlayTap(
        show: binding,
        closeOnClickOverlay: false,
        onClose: { closed = true }
    )

    XCTAssertTrue(shown)
    XCTAssertFalse(closed)
}
```

- [ ] **Step 2: Run the new event tests and verify the red state.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests/testSelectionEmitsSelectThenBindingChangeThenClose
```

Expected: compilation fails because `UPActionSheet` and its interaction helpers are not defined.

- [ ] **Step 3: Implement the event helpers and the minimal view shell.**

Create the `UPActionSheet` stored properties and a no-slot initializer with these defaults:

```swift
@MainActor
public struct UPActionSheet: View {
    var show: Binding<Bool>
    var title: String
    var description: String
    var actions: [UPActionSheetAction]
    var nameKey: String
    var subnameKey: String
    var cancelText: String
    var closeOnClickAction: Bool
    var safeAreaInsetBottom: Bool
    var openType: String
    var closeOnClickOverlay: Bool
    var round: String
    var wrapMaxHeight: String
    var onSelectHandler: ((UPActionSheetAction) -> Void)?
    var onCloseHandler: (() -> Void)?
    var customContent: AnyView?

    public init(
        show: Binding<Bool>,
        title: String = UPConfig.actionSheet.title,
        description: String = UPConfig.actionSheet.description,
        actions: [UPActionSheetAction] = UPConfig.actionSheet.actions,
        nameKey: String = UPConfig.actionSheet.nameKey,
        subnameKey: String = UPConfig.actionSheet.subnameKey,
        cancelText: String = UPConfig.actionSheet.cancelText,
        closeOnClickAction: Bool = UPConfig.actionSheet.closeOnClickAction,
        safeAreaInsetBottom: Bool = UPConfig.actionSheet.safeAreaInsetBottom,
        openType: String = UPConfig.actionSheet.openType,
        closeOnClickOverlay: Bool = UPConfig.actionSheet.closeOnClickOverlay,
        round: some UPActionSheetUnitValue = UPConfig.actionSheet.round,
        wrapMaxHeight: some UPActionSheetUnitValue = UPConfig.actionSheet.wrapMaxHeight,
        onSelect: ((UPActionSheetAction) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) { ... }
}
```

Store the two unit props as normalized strings, reject non-finite or negative dimensions in `parseDimension`, and implement helpers exactly as follows:

```swift
static func performSelection(
    _ action: UPActionSheetAction,
    show: Binding<Bool>,
    closeOnClickAction: Bool,
    onSelect: ((UPActionSheetAction) -> Void)?,
    onClose: (() -> Void)?
) {
    guard !action.disabled, !action.loading else { return }
    onSelect?(action)
    if closeOnClickAction {
        show.wrappedValue = false
        onClose?()
    }
}

static func performClose(show: Binding<Bool>, onClose: (() -> Void)?) {
    show.wrappedValue = false
    onClose?()
}

static func performOverlayTap(
    show: Binding<Bool>,
    closeOnClickOverlay: Bool,
    onClose: (() -> Void)?
) {
    guard closeOnClickOverlay else { return }
    performClose(show: show, onClose: onClose)
}

static func performContentTap(
    show: Binding<Bool>,
    closeOnClickAction: Bool,
    onClose: (() -> Void)?
) {
    guard closeOnClickAction else { return }
    performClose(show: show, onClose: onClose)
}
```

- [ ] **Step 4: Run the event tests and verify the green state.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests
```

Expected: all current ActionSheet tests pass. If callback ordering differs, fix the helper implementation rather than adding test-specific behavior.

---

### Task 4: Add failing layout/slot tests and implement the SwiftUI content layer

**Files:**
- Modify: `UltraUI/Sources/UltraUI/Components/UPActionSheet.swift`
- Modify: `UltraUI/Tests/UltraUITests/ActionSheetTests.swift`

**Interfaces:**
- Adds generic trailing-slot initialization without making the public view generic:
  `init<Content: View>(..., @ViewBuilder content: () -> Content)`.
- Adds `onSelect(_:)` and `onClose(_:)` fluent modifiers returning `UPActionSheet`.
- Exposes testable normalized properties `resolvedRound`, `resolvedWrapMaxHeight`, `hasCustomContent`, `shouldRenderDefaultActions`, and `displayName(for:)`.

- [ ] **Step 1: Add failing layout and rendering tests.**

```swift
func testDefaultActionSheetNormalizesPropsAndRendersDefaultActions() {
    let sheet = UPActionSheet(
        show: .constant(false),
        title: "操作",
        actions: [UPActionSheetAction(name: "编辑")],
        round: "12px",
        wrapMaxHeight: 420
    )

    XCTAssertEqual(sheet.title, "操作")
    XCTAssertEqual(sheet.resolvedRound, 12)
    XCTAssertEqual(sheet.resolvedWrapMaxHeight, 420)
    XCTAssertFalse(sheet.hasCustomContent)
    XCTAssertTrue(sheet.shouldRenderDefaultActions)
    XCTAssertEqual(sheet.displayName(for: sheet.actions[0]), "编辑")
}

func testCustomContentSuppressesDefaultActions() {
    let sheet = UPActionSheet(
        show: .constant(false),
        actions: [UPActionSheetAction(name: "不会显示")]
    ) {
        Text("自定义")
    }

    XCTAssertTrue(sheet.hasCustomContent)
    XCTAssertFalse(sheet.shouldRenderDefaultActions)
}

#if os(macOS)
func testActionSheetCanRenderIntoAFixedNativeCanvas() {
    let renderer = ImageRenderer(
        content: UPActionSheet(
            show: .constant(true),
            title: "操作",
            description: "说明",
            actions: [
                UPActionSheetAction(name: "编辑"),
                UPActionSheetAction(name: "删除", disabled: true),
                UPActionSheetAction(name: "加载", loading: true)
            ],
            cancelText: "取消"
        )
        .frame(width: 360, height: 560)
    )

    XCTAssertEqual(renderer.cgImage?.width, 360)
    XCTAssertEqual(renderer.cgImage?.height, 560)
}
#endif
```

- [ ] **Step 2: Run the new tests and verify the red state.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests/testDefaultActionSheetNormalizesPropsAndRendersDefaultActions
```

Expected: compilation fails because the normalized properties, slot initializer, and content implementation are not present.

- [ ] **Step 3: Implement the content layer with `UPPopup`.**

Use `UPPopup(show: show, mode: "bottom", closeOnClickOverlay: false, round: "\(resolvedRound)px", safeAreaInsetBottom: false, onClickOverlay: { ... })`. The overlay callback must call `performOverlayTap(show:closeOnClickOverlay:onClose:)` so external `show` changes never synthesize `onClose`.

Build the sheet content as:

1. Optional title header with centered bold `Text(title)` and a top-trailing `Button` using the native `xmark` image; the button calls `performClose`.
2. Optional description with theme tips color and the upstream title/description spacing rule.
3. Either the custom `AnyView` slot wrapped in a tap handler, or a `ScrollView(.vertical)` with `maxHeight: resolvedWrapMaxHeight` and one button row per action.
4. Optional 6pt cancellation gap and cancellation row; cancellation calls `performClose`.
5. Bottom safe-area padding only when `safeAreaInsetBottom` is true.

For each action row:

- Use `displayName(for:)` with `nameKey`, and `action.value(for: subnameKey)` for the optional subname.
- Render `ProgressView` when `loading` is true.
- Otherwise render the name and optional subname, using `action.color` and `action.resolvedFontSize`; disabled actions use `theme.disabled` and do not receive a selection gesture.
- Draw separators between rows, not after the final row.
- Route every enabled row tap through `performSelection`.

Use `UPColor.parse` for action colors and the existing `upTheme` environment for default main/tips/disabled/border colors. Keep the body free of platform-specific control references.

- [ ] **Step 4: Add and test fluent event modifiers.**

Implement copy-on-write modifiers with the same shape as existing components:

```swift
public extension UPActionSheet {
    func onSelect(_ action: @escaping (UPActionSheetAction) -> Void) -> UPActionSheet {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    func onClose(_ action: @escaping () -> Void) -> UPActionSheet {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }
}
```

Add a test that both modifiers replace the corresponding stored handlers without mutating the original value.

- [ ] **Step 5: Run all ActionSheet tests and verify they pass.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests
```

Expected: all default, model, event, slot, and macOS rendering tests pass with zero failures.

- [ ] **Step 6: Commit the complete component slice.**

```bash
git add UltraUI/Sources/UltraUI/Components/UPActionSheet.swift \
        UltraUI/Tests/UltraUITests/ActionSheetTests.swift
git diff --cached --name-status
git commit -m "feat: add action sheet component"
```

The staged list must contain exactly the two paths above; the config and action-model files were committed in Task 2.

---

### Task 5: Run package and platform verification without touching collaborator changes

**Files:**
- Read-only verification of the ActionSheet commits and shared worktree status.

**Interfaces:**
- No production API changes. This task proves the component compiles in the Swift package and in the generated iOS Demo project.

- [ ] **Step 1: Confirm the working tree boundary.**

Run:

```bash
git status --short
 git diff --name-only
 git ls-files --others --exclude-standard
```

Confirm that no ActionSheet file is unexpectedly modified after its commit and that the pre-existing collaborator paths remain untouched by this task.

- [ ] **Step 2: Run focused and full Swift Package tests.**

Run:

```bash
swift test --package-path UltraUI --filter ActionSheetTests
swift build --package-path UltraUI
swift test --package-path UltraUI --parallel
```

Expected: ActionSheet tests pass, the package builds, and the complete existing test suite reports zero failures.

- [ ] **Step 3: Generate the ignored Xcode project in an isolated verification directory.**

Use an isolated worktree created through `using-git-worktrees`; if the generated project is absent, run:

```bash
xcodegen generate --spec project.yml
xcodebuild \
  -project UltraUIDemo.xcodeproj \
  -scheme UltraUIDemo \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath /tmp/ultra-ui-action-sheet-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: `** BUILD SUCCEEDED **`. Do not add the generated `UltraUIDemo.xcodeproj` if repository ignore rules exclude it.

- [ ] **Step 4: Run final diff checks and report evidence.**

Run:

```bash
git diff --check HEAD~2..HEAD
git log --oneline --decorate -6
```

Report the exact focused-test, full-test, package-build, and simulator-build results. Do not claim completion without fresh command output.
