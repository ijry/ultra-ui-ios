# Card / Empty / Image / Text Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete and stabilize SwiftUI replicas of uview-plus `u-card`, `u-empty`, `u-image`, and `u-text`, with compatible props, defaults, slots, events, tests, and progress tracking.

**Architecture:** Preserve the current four component files and their public uview-compatible initializers. Convert web/uni-app values at the rendering boundary using existing `UPUnit`, `UPColor`, `UPStyle`, and `UPIcon`; use native `AsyncImage` for remote image loading and `@ViewBuilder`/closures for slots and events.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Swift Package Manager; iOS 17 and macOS 14 minimum; no additional dependencies.

## Global Constraints

- Work only in the current workspace; do not create, switch, or use a git worktree.
- Do not run `git reset`, `git clean`, or `git add .`.
- Do not overwrite, stage, or commit unrelated dirty files, especially Button, Form, Input, Modal, Popup, Textarea, Toast, configuration, form context, and their tests.
- Do not add Fastview-specific APIs.
- Match uview-plus 3.8.86 prop names, defaults, String/Number inputs, event payloads, and slot semantics as closely as Swift permits.
- `UPImage` must use native `AsyncImage`; do not add Kingfisher, SDWebImage, or another dependency.
- Each component task follows RED, GREEN, focused verification, and an exact-path commit.

---

### Task 1: Stabilize UPCard

**Files:**
- Modify: `UltraUI/Sources/UltraUI/Components/UPCard.swift`
- Modify: `UltraUI/Tests/UltraUITests/CardTests.swift`

**Interfaces:**
- Consumes: `UPConfig.card`, `UPUnit`, `UPInsets`, `UPStyle`, `UPColor`, `UPImage`.
- Produces: `UPCardUnitValue`, `UPCardIndex`, `UPCard`, named `head`/`body`/`foot` builders, and `.onClick`/`.onHeadClick`/`.onBodyClick`/`.onFootClick` modifiers.

- [ ] **Step 1: Add failing compatibility tests**

Add tests that compile and assert String/Number values, all `UPCardIndex` literal forms, named-slot flags, padding fallback, `full` margin behavior, and the four event payloads. The test must include representative calls such as:

```swift
let card = UPCard(
    titleSize: 16,
    subTitleSize: "14px",
    index: ["id": 7, "visible": true],
    borderRadius: 12,
    thumbWidth: 36,
    padding: "10px 20px",
    paddingHead: "8px"
) { Text("body") }
XCTAssertEqual(card.index, ["id": 7, "visible": true])
XCTAssertEqual(card.resolvedHeadPadding, UPInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run:

```bash
cd UltraUI && swift test --filter CardTests
```

Expected: at least one newly added assertion or compile-time API probe fails before implementation changes. If every new test already passes, record that the current implementation already satisfies it and add a test for an uncovered upstream behavior before proceeding.

- [ ] **Step 3: Implement only the missing UPCard behavior**

Keep the current public names and defaults. Normalize `String | Number` dimensions through `UPCardUnitValue`, preserve `UPCardIndex` payloads, map the three slots without a synthetic Vue default slot, apply border/padding/radius/shadow using native SwiftUI equivalents, and ensure each tap region emits `index` exactly once.

- [ ] **Step 4: Run focused GREEN verification**

```bash
cd UltraUI && swift test --filter CardTests
```

Expected: all `CardTests` pass with zero failures.

- [ ] **Step 5: Commit only Card files**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPCard.swift UltraUI/Tests/UltraUITests/CardTests.swift
git diff --cached --check
git commit -m "feat: add card component"
```

### Task 2: Stabilize UPEmpty

**Files:**
- Modify: `UltraUI/Sources/UltraUI/Components/UPEmpty.swift`
- Modify: `UltraUI/Tests/UltraUITests/EmptyTests.swift`

**Interfaces:**
- Consumes: `UPConfig.empty`, `UPUnit`, `UPStyle`, `UPIcon`, `UPImage`.
- Produces: generic `UPEmpty<Content>` plus an `EmptyView` convenience initializer; mode-derived `iconName` and `displayText` compatibility behavior.

- [ ] **Step 1: Add failing UPEmpty tests**

Cover all defaults, String/Number dimensions, `show`, custom image detection, `message -> chat`, default mode text, explicit text precedence, and default slot construction:

```swift
let empty = UPEmpty(
    textSize: 15,
    iconSize: 88,
    width: 120,
    height: 90,
    marginTop: 24
) { Text("retry") }
XCTAssertEqual(empty.resolvedTextSize, 15)
XCTAssertEqual(empty.resolvedWidth, 120)
XCTAssertEqual(UPEmpty(mode: "message").iconName, "chat")
```

- [ ] **Step 2: Run the focused test and confirm RED**

```bash
cd UltraUI && swift test --filter EmptyTests
```

Expected: a new compatibility assertion or compile-time API probe fails. If current code passes the first probes, add coverage for an upstream mode/default not yet represented.

- [ ] **Step 3: Implement only missing UPEmpty behavior**

Retain the upstream props and actual source behavior. Render URL/path icons through `UPImage`, built-in modes through `UPIcon`, use explicit text before mode text, hide the entire view when `show == false`, and do not invent documentation-only `click`/`close` events absent from the upstream Vue implementation.

- [ ] **Step 4: Run focused GREEN verification**

```bash
cd UltraUI && swift test --filter EmptyTests
```

Expected: all `EmptyTests` pass with zero failures.

- [ ] **Step 5: Commit only Empty files**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPEmpty.swift UltraUI/Tests/UltraUITests/EmptyTests.swift
git diff --cached --check
git commit -m "feat: add empty component"
```

### Task 3: Stabilize UPImage

**Files:**
- Modify: `UltraUI/Sources/UltraUI/Components/UPImage.swift`
- Modify: `UltraUI/Tests/UltraUITests/ImageTests.swift`

**Interfaces:**
- Consumes: SwiftUI `AsyncImage`, `UPConfig.image`, `UPUnit`, `UPStyle`, `UPIcon`, `UPColor`.
- Produces: `UPImage`, `UPImageLoadState`, `UPImageLoadEvent`, `UPImageErrorEvent`, `loading`/`error` builders, and `.onClick`/`.onLoad`/`.onError` modifiers.

- [ ] **Step 1: Add failing UPImage tests**

Test defaults, String/Number dimensions, circle radius, source classification, loading/error visibility, slot flags, mode mapping, event modifier retention, and error/load payload shape. Avoid live network assertions; make deterministic state/helper assertions instead:

```swift
let image = UPImage(src: "https://example.com/a.png", width: 120, height: "80px", shape: "circle")
XCTAssertEqual(image.initialLoadState, .loading)
XCTAssertEqual(image.resolvedWidth, 120)
XCTAssertEqual(image.resolvedRadius, 60)

let slotted = UPImage(src: "", loading: { Text("loading") }, error: { Text("failed") })
XCTAssertTrue(slotted.hasLoadingSlot)
XCTAssertTrue(slotted.hasErrorSlot)
```

- [ ] **Step 2: Run the focused test and confirm RED**

```bash
cd UltraUI && swift test --filter ImageTests
```

Expected: at least one new API or behavior test fails before the implementation update.

- [ ] **Step 3: Implement only missing UPImage behavior**

Use `AsyncImage` for `http`/`https`, native asset `Image` for non-remote sources, and error state for an empty source. Render loading/error slots only when the matching show flag is true; otherwise use the configured icon and background. Map aspect-fill modes to `scaledToFill`, all other supported modes to `scaledToFit`, clip with radius/circle, and suppress duplicate load/error emissions for one state transition.

- [ ] **Step 4: Run focused GREEN verification**

```bash
cd UltraUI && swift test --filter ImageTests
```

Expected: all `ImageTests` pass with zero failures and no live network dependency.

- [ ] **Step 5: Commit only Image files**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPImage.swift UltraUI/Tests/UltraUITests/ImageTests.swift
git diff --cached --check
git commit -m "feat: add image component"
```

### Task 4: Stabilize UPText

**Files:**
- Modify: `UltraUI/Sources/UltraUI/Components/UPText.swift`
- Modify: `UltraUI/Tests/UltraUITests/TextTests.swift`

**Interfaces:**
- Consumes: `UPConfig.text`, `UPUnit`, `UPStyle`, `UPIcon`, `UPColor`, SwiftUI `OpenURLAction`.
- Produces: `UPText`, compatible String/Number text/size/lines/margin/lineHeight inputs, formatted `displayText`, and click/tap modifiers.

- [ ] **Step 1: Add failing UPText compatibility tests**

Cover defaults, numeric text conversion, String/Number props, custom formatter precedence, price/date/phone/name modes, line limits, alignment, type/color resolution, icon props, and click callback retention:

```swift
XCTAssertEqual(UPText(text: 1234).text, "1234")
XCTAssertEqual(UPText(text: "13812345678", mode: "phone", format: "encrypt").displayText, "138****5678")
XCTAssertEqual(UPText(text: "张三", mode: "name", format: "encrypt").displayText, "张*")
XCTAssertEqual(UPText(text: "728732.32", mode: "price").displayText, "728,732.32")
```

- [ ] **Step 2: Run the focused test and confirm RED**

```bash
cd UltraUI && swift test --filter TextTests
```

Expected: a new String/Number initializer or formatting assertion fails before implementation changes.

- [ ] **Step 3: Implement only missing UPText behavior**

Preserve upstream prop names while adding typed overloads/protocol conversion where needed. Apply formatter closure before mode formatting, map date tokens deterministically, use `UPColor` type fallback, apply decoration/line limit/alignment/line height, retain mini-program props as metadata, and map link/phone actions to `openURL` without changing the click event contract.

- [ ] **Step 4: Run focused GREEN verification**

```bash
cd UltraUI && swift test --filter TextTests
```

Expected: all `TextTests` pass with zero failures.

- [ ] **Step 5: Commit only Text files**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPText.swift UltraUI/Tests/UltraUITests/TextTests.swift
git diff --cached --check
git commit -m "feat: add text component"
```

### Task 5: Cross-component compatibility and progress tracking

**Files:**
- Modify only if necessary for the four components: `UltraUI/Tests/UltraUITests/UViewPlusCompatibilityTests.swift`
- Modify: `UVIEW_PLUS_PROGRESS.md`

**Interfaces:**
- Consumes: public initializers and event/slot APIs produced by Tasks 1-4.
- Produces: compile-time compatibility coverage and updated project progress totals.

- [ ] **Step 1: Add or isolate four-component compatibility probes**

Ensure one test constructs each component using uview-style camel-case props, numeric values, slots, and event modifiers. Do not stage unrelated compatibility assertions for Button/Form/Input/Modal/Popup/Textarea/Toast if they share the existing dirty file; if isolation is impossible, create `UltraUI/Tests/UltraUITests/CardEmptyImageTextCompatibilityTests.swift` instead and stage only that new file.

- [ ] **Step 2: Run the four focused suites**

```bash
cd UltraUI && swift test --filter 'CardTests|EmptyTests|ImageTests|TextTests|CardEmptyImageTextCompatibilityTests'
```

Expected: all selected tests pass with zero failures.

- [ ] **Step 3: Update the progress document**

Change Card, Empty, Image, and Text from `🚧 开发中` to `✅ 已完成`, describe their completed compatibility scope, and update totals exactly to:

```text
已完成：44
兼容增强中：11
开发中：0
待开始：83
已有实现覆盖：55 / 138
已提交覆盖：55 / 138
```

Set the iOS baseline to the latest four-component commit hash available at that point.

- [ ] **Step 4: Verify the complete table and repository**

Run the component-set/statistics validation script used for `UVIEW_PLUS_PROGRESS.md`, then:

```bash
cd UltraUI && swift test
cd .. && xcodebuild -project UltraUIDemo.xcodeproj -scheme UltraUIDemo -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Expected: 138 documented components, counts `44 + 11 + 0 + 83 = 138`, all Swift tests pass, and the demo project build exits 0.

- [ ] **Step 5: Commit compatibility/progress files exactly**

Stage only the new isolated compatibility test if created and the progress document:

```bash
git add -- UVIEW_PLUS_PROGRESS.md UltraUI/Tests/UltraUITests/CardEmptyImageTextCompatibilityTests.swift
git diff --cached --check
git commit -m "docs: complete card empty image text tracking"
```

If no isolated compatibility file was needed, omit that path and stage only `UVIEW_PLUS_PROGRESS.md`.
