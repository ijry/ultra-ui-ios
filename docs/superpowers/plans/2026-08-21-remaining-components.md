# UltraUI Remaining uview-plus Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不引入 Fastview 专用 API 的前提下，将 uview-plus 3.8.86 剩余 82 个组件复刻为可交互、可测试、接口尽量一致的 SwiftUI 组件，使 UltraUI 达到 138 / 138 已提交覆盖。

**Architecture:** 按依赖关系分 12 个批次推进：基础原语先行，父子组件族在同批通过 SwiftUI Environment 协作，系统与媒体能力使用 Apple 原生框架和可注入适配器。每个组件以同名初始化参数映射 prop、以 `Binding` 映射 `v-model`、以闭包及 `.onXxx` 映射 emit、以 `@ViewBuilder` 映射 slot；确定性状态归一化与几何计算从 View 中分离以便测试。

**Tech Stack:** Swift 6、SwiftUI、XCTest、Foundation；按批次使用 Core Graphics、Core Image、PDFKit、AVKit、PhotosUI、UniformTypeIdentifiers、Network.framework、CoreLocation；uview-plus 3.8.86 上游源码作为接口事实来源。

## Global Constraints

- 上游基线固定为 uview-plus 3.8.86，组件清单固定为 `UVIEW_PLUS_PROGRESS.md` 中 82 个“待开始”组件。
- Package 平台保持 iOS 17、macOS 14；默认不新增第三方依赖。
- Vue prop 尽量映射为同名 Swift 初始化参数，`v-model` 映射为 `Binding`，emit 映射为闭包及 `.onXxx`，slot 映射为 `@ViewBuilder`。
- 原生可实现的交互必须真实实现；DOM、uni-app、小程序专属能力使用 Apple 原生替代或保留中立兼容元数据。
- 不引入 Fastview 专用类型、导入、条件分支或命名。
- 只使用当前主工作区；不创建或使用 worktree，不派发协作者。
- 不执行 `git reset`、`git clean`、`git add .`；不覆盖、清理或混入既有 dirty / untracked 文件。
- 每个实现组先运行新增定向测试并观察因类型或行为缺失而 RED，再写最小实现至 GREEN。
- 每次提交只精确暂存列出的路径，并运行 `git diff --cached --name-only` 与 `git diff --cached --check`。
- 每批结束运行 `cd UltraUI && swift test`、UltraUIDemo generic iOS Simulator build 和 macOS Swift Package 编译验证。
- 组件只有接口核对、真实交互、隔离测试、全量验证和实现提交全部完成后，才能在进度表标记为“已完成”。

---

## File Map

### Batch 1 新文件

- `UltraUI/Sources/UltraUI/Components/UPView.swift`：通用样式容器与 click。
- `UltraUI/Sources/UltraUI/Components/UPStatusBar.swift`：顶部安全区占位与高度回调。
- `UltraUI/Sources/UltraUI/Components/UPSafeBottom.swift`：底部安全区占位。
- `UltraUI/Sources/UltraUI/Components/UPSection.swift`：章节标题、右侧操作和 click。
- `UltraUI/Sources/UltraUI/Components/UPToolbar.swift`：取消、标题、确认及 right slot。
- `UltraUI/Sources/UltraUI/Components/UPSlider.swift`：单值/范围、水平/垂直滑杆及归一化。
- `UltraUI/Sources/UltraUI/Components/UPSubsection.swift`：分段选项模型、Binding 与 change。
- `UltraUI/Sources/UltraUI/Components/UPPagination.swift`：分页 Binding、页码 token 与 page-size 选择。
- `UltraUI/Tests/UltraUITests/ViewStatusSafeTests.swift`：前三个原语的默认值、样式和事件。
- `UltraUI/Tests/UltraUITests/SectionToolbarTests.swift`：section/toolbar 接口和事件。
- `UltraUI/Tests/UltraUITests/SliderTests.swift`：滑杆边界、步长、事件和范围。
- `UltraUI/Tests/UltraUITests/SubsectionPaginationTests.swift`：分段与分页模型。
- `UltraUI/Tests/UltraUITests/PrimitiveBatchCompatibilityTests.swift`：八种 View 的公开构造编译契约。

### Batch 2–12 文件边界

后续组件均采用 `UltraUI/Sources/UltraUI/Components/UP<Name>.swift` 一组件一主文件；仅父子族共享的 Environment、状态或值模型可放入同批 `UP<Family>Context.swift`。测试按批次放入下列固定文件，避免创建无归属的大型测试文件：

- Batch 2：`TableTests.swift`、`StepsTests.swift`、`SwiperTests.swift`。
- Batch 3：`TabsTests.swift`、`TabbarTests.swift`、`NavbarScrollStickyTests.swift`。
- Batch 4：`PickerCoreTests.swift`、`PickerSelectionTests.swift`、`DropdownTests.swift`。
- Batch 5：`KeyboardTests.swift`、`MessageInputTests.swift`。
- Batch 6：`ListVirtualizationTests.swift`、`WaterfallTests.swift`、`IndexListTests.swift`。
- Batch 7：`NoticeTests.swift`、`PopoverGuideTests.swift`、`FloatAgreementTests.swift`。
- Batch 8：`DragRefreshTests.swift`、`SwipeActionTests.swift`、`ReadMoreTests.swift`。
- Batch 9：`AlbumCanvasTests.swift`、`SignatureCropperTests.swift`、`PosterCodeTests.swift`、`ColorPickerTests.swift`。
- Batch 10：`RichTextTests.swift`、`PDFVideoTests.swift`、`UploadTests.swift`。
- Batch 11：`NetworkLocationTests.swift`。
- Batch 12：`CalendarTests.swift`、`CouponSKUTests.swift`、`CateTreeTests.swift`。

---

### Task 1: UPView、UPStatusBar 与 UPSafeBottom

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPView.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPStatusBar.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPSafeBottom.swift`
- Test: `UltraUI/Tests/UltraUITests/ViewStatusSafeTests.swift`

**Interfaces:**
- Consumes: `UPStyle`, `UPUnit.parse(_:)`, `UPColor.parse(_:)`, `View.upStyle(_:)`。
- Produces: `UPView<Content>`, `UPStatusBar<Content>`, `UPSafeBottom`；三者均可独立构造，前两者接受默认 slot。

- [ ] **Step 1: 写失败测试**

```swift
@MainActor final class ViewStatusSafeTests: XCTestCase {
    func testViewDefaultsAndClick() {
        var clicks = 0
        let view = UPView().onClick { clicks += 1 }
        XCTAssertEqual(view.backgroundColor, "")
        XCTAssertEqual(view.flexDirection, "")
        XCTAssertEqual(view.width, "")
        view.triggerClick()
        XCTAssertEqual(clicks, 1)
    }

    func testStatusBarDefaultsAndResolvedHeight() {
        var heights: [CGFloat] = []
        let bar = UPStatusBar(height: 0).onUpdateHeight { heights.append($0) }
        XCTAssertEqual(bar.bgColor, "transparent")
        XCTAssertEqual(bar.resolvedHeight(safeAreaTop: 47, statusBarHeight: nil), 47)
        bar.reportHeight(safeAreaTop: 47, statusBarHeight: 54)
        XCTAssertEqual(heights, [54])
    }

    func testSafeBottomUsesNonnegativeInset() {
        XCTAssertEqual(UPSafeBottom().resolvedHeight(safeAreaBottom: -3), 0)
        XCTAssertEqual(UPSafeBottom().resolvedHeight(safeAreaBottom: 34), 34)
    }
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run: `cd UltraUI && swift test --filter ViewStatusSafeTests`
Expected: FAIL，报错包含 `cannot find 'UPView' in scope`、`UPStatusBar` 或 `UPSafeBottom`。

- [ ] **Step 3: 写最小实现**

实现以下公开表面，并在 `body` 中使用 `GeometryReader.safeAreaInsets` 读取原生安全区：

```swift
public struct UPView<Content: View>: View {
    public init(backgroundColor: String = "", color: String = "", flexDirection: String = "",
                justifyContent: String = "", alignItems: String = "", flex1: String = "",
                width: String = "", height: String = "", padding: String = "",
                margin: String = "", borderColor: String = "",
                @ViewBuilder content: () -> Content)
    public func onClick(_ action: @escaping () -> Void) -> Self
    public func triggerClick()
}

public struct UPStatusBar<Content: View>: View {
    public init(bgColor: String = "transparent", height: CGFloat = 0,
                customStyle: UPStyle = UPStyle(), @ViewBuilder content: () -> Content)
    public func resolvedHeight(safeAreaTop: CGFloat, statusBarHeight: CGFloat?) -> CGFloat
    public func onUpdateHeight(_ action: @escaping (CGFloat) -> Void) -> Self
    public func reportHeight(safeAreaTop: CGFloat, statusBarHeight: CGFloat?)
}

public struct UPSafeBottom: View {
    public init(customStyle: UPStyle = UPStyle())
    public func resolvedHeight(safeAreaBottom: CGFloat) -> CGFloat
}
```

为 `UPView` 和 `UPStatusBar` 提供 `Content == EmptyView` 便捷初始化；点击回调只在真实 tap 或 `triggerClick()` 时触发。

- [ ] **Step 4: 运行测试确认 GREEN**

Run: `cd UltraUI && swift test --filter ViewStatusSafeTests`
Expected: PASS。

- [ ] **Step 5: 精确提交**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPView.swift UltraUI/Sources/UltraUI/Components/UPStatusBar.swift UltraUI/Sources/UltraUI/Components/UPSafeBottom.swift UltraUI/Tests/UltraUITests/ViewStatusSafeTests.swift
git diff --cached --name-only
git diff --cached --check
git commit -m "feat: add view and safe area primitives"
```

### Task 2: UPSection 与 UPToolbar

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPSection.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPToolbar.swift`
- Test: `UltraUI/Tests/UltraUITests/SectionToolbarTests.swift`

**Interfaces:**
- Consumes: `UPColor.parse(_:)`、SwiftUI Button/HStack。
- Produces: `UPSection<Content>` 的 title/right action；`UPToolbar<RightContent>` 的 confirm/cancel 和 right named slot。

- [ ] **Step 1: 写失败测试**

```swift
@MainActor final class SectionToolbarTests: XCTestCase {
    func testSectionDefaultsAndClick() {
        var clicks = 0
        let section = UPSection().onClick { clicks += 1 }
        XCTAssertEqual(section.title, "")
        XCTAssertEqual(section.subTitle, "更多")
        XCTAssertTrue(section.right)
        XCTAssertEqual(section.fontSize, 15)
        XCTAssertTrue(section.bold)
        XCTAssertTrue(section.showLine)
        XCTAssertTrue(section.arrow)
        section.triggerClick()
        XCTAssertEqual(clicks, 1)
    }

    func testToolbarDefaultsAndEvents() {
        var events: [String] = []
        let toolbar = UPToolbar(title: "选择")
            .onCancel { events.append("cancel") }
            .onConfirm { events.append("confirm") }
        XCTAssertTrue(toolbar.show)
        XCTAssertEqual(toolbar.cancelText, "取消")
        XCTAssertEqual(toolbar.confirmText, "确认")
        toolbar.triggerCancel(); toolbar.triggerConfirm()
        XCTAssertEqual(events, ["cancel", "confirm"])
    }
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run: `cd UltraUI && swift test --filter SectionToolbarTests`
Expected: FAIL，目标类型不存在。

- [ ] **Step 3: 写最小实现**

```swift
public struct UPSection<Content: View>: View {
    public init(title: String = "", subTitle: String = "更多", right: Bool = true,
                fontSize: CGFloat = 15, bold: Bool = true, color: String = "#303133",
                subColor: String = "#909399", showLine: Bool = true,
                lineColor: String = "", arrow: Bool = true,
                @ViewBuilder content: () -> Content)
    public func onClick(_ action: @escaping () -> Void) -> Self
    public func triggerClick()
}

public struct UPToolbar<RightContent: View>: View {
    public init(show: Bool = true, cancelText: String = "取消", confirmText: String = "确认",
                cancelColor: String = "#909193", confirmColor: String = "",
                title: String = "", rightSlot: Bool = false,
                @ViewBuilder right: () -> RightContent)
    public func onConfirm(_ action: @escaping () -> Void) -> Self
    public func onCancel(_ action: @escaping () -> Void) -> Self
    public func triggerConfirm()
    public func triggerCancel()
}
```

提供 `EmptyView` 便捷初始化。`show == false` 时不渲染；`rightSlot == true` 时用 named slot 替换确认文字，仍由同一确认 action 驱动。

- [ ] **Step 4: 运行测试确认 GREEN**

Run: `cd UltraUI && swift test --filter SectionToolbarTests`
Expected: PASS。

- [ ] **Step 5: 精确提交**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPSection.swift UltraUI/Sources/UltraUI/Components/UPToolbar.swift UltraUI/Tests/UltraUITests/SectionToolbarTests.swift
git diff --cached --name-only
git diff --cached --check
git commit -m "feat: add section and toolbar components"
```

### Task 3: UPSlider

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPSlider.swift`
- Test: `UltraUI/Tests/UltraUITests/SliderTests.swift`

**Interfaces:**
- Consumes: SwiftUI `Slider`、DragGesture、`UPStyle`。
- Produces: `UPSliderValueInput`、`UPSliderRangeValue`、`UPSlider` 单值与范围 Binding、`onStart/onChanging/onChange`。

- [ ] **Step 1: 写失败测试**

```swift
@MainActor final class SliderTests: XCTestCase {
    func testDefaultsMatchUpstream() {
        let slider = UPSlider()
        XCTAssertEqual(slider.value, 0)
        XCTAssertEqual(slider.blockSize, 18)
        XCTAssertEqual(slider.min, 0)
        XCTAssertEqual(slider.max, 100)
        XCTAssertEqual(slider.step, 1)
        XCTAssertFalse(slider.showValue)
        XCTAssertFalse(slider.disabled)
        XCTAssertFalse(slider.vertical)
        XCTAssertFalse(slider.isRange)
    }

    func testSingleValueClampsRoundsAndOrdersEvents() {
        let box = SliderBox(0.0); var events: [String] = []
        let slider = UPSlider(modelValue: box.binding, min: 0, max: 10, step: 2)
            .onStart { events.append("start") }
            .onChanging { events.append("changing:\($0)") }
            .onChange { events.append("change:\($0)") }
        slider.startInteraction(); slider.changeInteraction(to: 7.1); slider.endInteraction()
        XCTAssertEqual(box.value, 8)
        XCTAssertEqual(events, ["start", "changing:8.0", "change:8.0"])
    }

    func testRangeKeepsThumbsOneStepApart() {
        let box = SliderBox(UPSliderRangeValue(lower: 2, upper: 8))
        let slider = UPSlider(rangeValue: box.binding, min: 0, max: 10, step: 2)
        slider.changeLower(to: 9)
        XCTAssertEqual(box.value, UPSliderRangeValue(lower: 6, upper: 8))
        slider.changeUpper(to: 1)
        XCTAssertEqual(box.value, UPSliderRangeValue(lower: 6, upper: 8))
    }
}
```

`SliderBox` 是测试文件内与现有 `RateValueBox` 相同模式的 Binding holder。

- [ ] **Step 2: 运行测试确认 RED**

Run: `cd UltraUI && swift test --filter SliderTests`
Expected: FAIL，报错包含 `cannot find 'UPSlider' in scope`。

- [ ] **Step 3: 写最小实现**

```swift
public struct UPSliderRangeValue: Equatable, Sendable {
    public var lower: Double
    public var upper: Double
    public init(lower: Double, upper: Double)
}

public struct UPSlider: View {
    public init(value: some UPSliderValueInput = 0, blockSize: some UPSliderValueInput = 18,
                min: some UPSliderValueInput = 0, max: some UPSliderValueInput = 100,
                step: some UPSliderValueInput = 1, activeColor: String = "#2979ff",
                inactiveColor: String = "#c0c4cc", blockColor: String = "#ffffff",
                showValue: Bool = false, disabled: Bool = false,
                blockStyle: UPStyle = UPStyle(), useNative: Bool = false,
                height: String = "", innerStyle: UPStyle = UPStyle(),
                vertical: Bool = false, size: String = "2px", length: String = "auto",
                isRange: Bool = false, rangeValue: UPSliderRangeValue = .init(lower: 0, upper: 0))
    public init(modelValue: Binding<Double>, /* 同名 props 与上述一致 */)
    public init(rangeValue: Binding<UPSliderRangeValue>, /* 同名 props 与上述一致，isRange 固定 true */)
    public func onStart(_ action: @escaping () -> Void) -> Self
    public func onChanging(_ action: @escaping (Double) -> Void) -> Self
    public func onChange(_ action: @escaping (Double) -> Void) -> Self
}
```

内部 `normalized(_:)` 先把非法/非正 step 归一为 1，再 clamp 到排序后的 min/max，最后按 `min + round((value-min)/step)*step` 对齐并再次 clamp。单值用原生 `Slider`；range 使用 GeometryReader、轨道和两个 DragGesture thumb；垂直模式旋转原生控件或交换手势轴。事件顺序固定为 start → 每次 Binding 更新后 changing → 结束时 change；disabled 不更新也不发事件。范围下端最多为 `upper-step`，上端最少为 `lower+step`。

- [ ] **Step 4: 运行测试确认 GREEN**

Run: `cd UltraUI && swift test --filter SliderTests`
Expected: PASS。

- [ ] **Step 5: 精确提交**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPSlider.swift UltraUI/Tests/UltraUITests/SliderTests.swift
git diff --cached --name-only
git diff --cached --check
git commit -m "feat: add slider component"
```

### Task 4: UPSubsection 与 UPPagination

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPSubsection.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPPagination.swift`
- Test: `UltraUI/Tests/UltraUITests/SubsectionPaginationTests.swift`
- Test: `UltraUI/Tests/UltraUITests/PrimitiveBatchCompatibilityTests.swift`

**Interfaces:**
- Consumes: SwiftUI Binding、Button、Picker。
- Produces: `UPSubsectionItem`、`UPSubsection`、`UPPaginationToken`、`UPPaginationPageSize`、`UPPagination`。

- [ ] **Step 1: 写失败测试**

```swift
@MainActor final class SubsectionPaginationTests: XCTestCase {
    func testSubsectionDefaultsAndSelection() {
        let box = IntBox(0); var emitted: [Int] = []
        let subsection = UPSubsection(list: ["A", "B"], current: box.binding)
            .onChange { emitted.append($0) }
        subsection.select(1)
        XCTAssertEqual(box.value, 1)
        XCTAssertEqual(emitted, [1])
        XCTAssertEqual(subsection.mode, "button")
        XCTAssertEqual(subsection.fontSize, 12)
    }

    func testDisabledSubsectionDoesNotChange() {
        let box = IntBox(0); var emitted = 0
        UPSubsection(list: ["A", "B"], current: box.binding, disabled: true)
            .onChange { _ in emitted += 1 }.select(1)
        XCTAssertEqual(box.value, 0); XCTAssertEqual(emitted, 0)
    }

    func testPaginationTokensAreOrderedAndUniqueAtEdges() {
        let pagination = UPPagination(currentPage: .constant(2), pageSize: .constant(10), total: 100)
        XCTAssertEqual(pagination.totalPages, 10)
        XCTAssertEqual(pagination.tokens, [.page(1), .page(2), .page(3), .page(4), .ellipsis, .page(10)])
        XCTAssertEqual(Set(pagination.tokens).count, pagination.tokens.count)
    }

    func testPaginationClampsAndEmitsChanges() {
        let page = IntBox(1); let size = IntBox(10); var events: [String] = []
        let pagination = UPPagination(currentPage: page.binding, pageSize: size.binding, total: 35)
            .onCurrentChange { events.append("page:\($0)") }
            .onSizeChange { events.append("size:\($0)") }
        pagination.selectPage(9); pagination.selectPageSize(20)
        XCTAssertEqual(page.value, 2)
        XCTAssertEqual(size.value, 20)
        XCTAssertEqual(events, ["page:4", "size:20", "page:2"])
    }
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run: `cd UltraUI && swift test --filter 'SubsectionPaginationTests|PrimitiveBatchCompatibilityTests'`
Expected: FAIL，目标类型不存在。

- [ ] **Step 3: 写最小实现**

```swift
public struct UPSubsectionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var activeColorKey: String?
    public var inactiveColorKey: String?
}

public enum UPPaginationToken: Hashable, Sendable { case page(Int), ellipsis }
public struct UPPaginationPageSize: Equatable, Sendable {
    public let label: String
    public let value: Int
}
```

`UPSubsection` 同时提供 `[String]` 和 `[UPSubsectionItem]` 初始化；保留 `activeColor/inactiveColor/mode/fontSize/bold/bgColor/keyName/activeColorKeyName/inactiveColorKeyName/disabled/customStyle`。`select(_:)` 先检查 disabled 和索引，再写 Binding，最后 emit change。

`UPPagination` 保留 `currentPage/pageSize/total/prevText/nextText/buttonBgColor/buttonBorderColor/pageSizes/layout/hideOnSinglePage`；`totalPages = max(1, ceil(total / max(pageSize, 1)))`。页码 token 严格按规格的四分支生成并做相邻去重；换 pageSize 时先 emit size-change，再把 current clamp 后仅在变化时 emit current-change。

在 `PrimitiveBatchCompatibilityTests.swift` 中构造八个组件的默认和自定义 slot 形式，作为公开 API 编译测试。

- [ ] **Step 4: 运行 Batch 1 定向测试确认 GREEN**

Run: `cd UltraUI && swift test --filter 'ViewStatusSafeTests|SectionToolbarTests|SliderTests|SubsectionPaginationTests|PrimitiveBatchCompatibilityTests'`
Expected: PASS。

- [ ] **Step 5: 精确提交**

```bash
git add -- UltraUI/Sources/UltraUI/Components/UPSubsection.swift UltraUI/Sources/UltraUI/Components/UPPagination.swift UltraUI/Tests/UltraUITests/SubsectionPaginationTests.swift UltraUI/Tests/UltraUITests/PrimitiveBatchCompatibilityTests.swift
git diff --cached --name-only
git diff --cached --check
git commit -m "feat: add subsection and pagination components"
```

### Task 5: Batch 1 全量验证与进度提交

**Files:**
- Modify: `UVIEW_PLUS_PROGRESS.md`

- [ ] **Step 1: 运行全量 Swift 测试**

Run: `cd UltraUI && swift test`
Expected: 全部测试通过，0 failures。

- [ ] **Step 2: 运行 iOS Demo 构建**

Run: `xcodebuild -project UltraUIDemo.xcodeproj -scheme UltraUIDemo -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 3: 运行 macOS Package 编译**

Run: `cd UltraUI && swift build`
Expected: `Build complete!`。

- [ ] **Step 4: 更新进度事实来源**

将 8 行改为“✅ 已完成”，写入每项已覆盖的 prop/event/slot/原生行为；统计改为：已完成 53、兼容增强中 11、开发中 0、待开始 74、已有实现覆盖 64 / 138、已提交覆盖 64 / 138、覆盖率 46.4%。iOS 基线填写 Task 4 的提交 hash。

- [ ] **Step 5: 精确提交进度**

```bash
git add -- UVIEW_PLUS_PROGRESS.md
git diff --cached --name-only
git diff --cached --check
git commit -m "docs: complete primitive component batch"
```

---

## Remaining Batch Execution Contracts

Batch 2–12 不在当前时点预写可能被上游源码核对推翻的逐函数伪代码。进入每批时，必须先从 uview-plus 3.8.86 实际 `.vue`、props mixin 与文档生成一份同目录实施附录，附录必须列出每个 prop 的类型/默认值、emit payload/顺序、slot、公开方法、Apple 映射和可执行 XCTest；附录先精确提交，再按 RED/GREEN 执行。这个“临近实现才冻结精确接口”的规则避免 82 个组件的远期接口因依赖模型演进而失效，同时下面每批的组件清单、写入边界、行为验收、测试文件、验证命令和提交门禁均已固定，不允许删减或空壳替代。

### Task 6: Batch 2 表格、步骤和分页容器

**Files:**
- Create components: `UPTable.swift`, `UPTable2.swift`, `UPTr.swift`, `UPTh.swift`, `UPTd.swift`, `UPTableContext.swift`, `UPSteps.swift`, `UPStepsItem.swift`, `UPStepsContext.swift`, `UPSwiper.swift`, `UPSwiperIndicator.swift` under `UltraUI/Sources/UltraUI/Components/`.
- Test: `UltraUI/Tests/UltraUITests/TableTests.swift`, `StepsTests.swift`, `SwiperTests.swift`.

- [ ] 核对并冻结 9 个组件的上游接口；表格父子通过 Environment 共享列宽/边框/对齐，steps 父子共享 active/direction，swiper 用 `TabView` paging 与计时器，indicator 接收 current/total/mode。
- [ ] RED 必须覆盖：table/tr/th/td 独立及组合构造、跨列宽度和边框；steps active/status 与点击 payload；swiper Binding、autoplay/interval/circular、change/transition/animationfinish 及 indicator dot/line/number。
- [ ] GREEN 后运行 `swift test --filter 'TableTests|StepsTests|SwiperTests'`，精确提交上述实现和测试，消息 `feat: add table steps and swiper components`。
- [ ] 执行三项全量验证，更新 9 行及统计为 73 / 138 已有与已提交覆盖，再独立提交进度。

### Task 7: Batch 3 导航与选项容器

**Files:**
- Create: `UPTabs.swift`, `UPTabsItem.swift`, `UPTabsContext.swift`, `UPTabbar.swift`, `UPTabbarItem.swift`, `UPTabbarContext.swift`, `UPNavbar.swift`, `UPNavbarMini.swift`, `UPScrollList.swift`, `UPSticky.swift`.
- Test: `TabsTests.swift`, `TabbarTests.swift`, `NavbarScrollStickyTests.swift`.

- [ ] 冻结 8 个上游接口；tabs/tabbar 用 Binding + Environment，navbar 保留 left/title/right slots，scroll-list 暴露 scroll event，sticky 用 safe-area 与坐标空间计算吸附偏移。
- [ ] RED 覆盖 disabled item、不重复 emit、active/inactive icon/text/color、safeAreaInset、back/clickLeft/clickRight、横向滚动边界和 sticky threshold。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add navigation container components`；三项全量验证后更新 8 行，覆盖达到 81 / 138 并独立提交进度。

### Task 8: Batch 4 Picker 与选择组件族

**Files:**
- Create: `UPPickerData.swift`, `UPPickerColumn.swift`, `UPPicker.swift`, `UPDatetimePicker.swift`, `UPSelect.swift`, `UPChoose.swift`, `UPCascader.swift`, `UPDropdown.swift`, `UPDropdownItem.swift`, `UPDropdownContext.swift`.
- Test: `PickerCoreTests.swift`, `PickerSelectionTests.swift`, `DropdownTests.swift`.

- [ ] 冻结 9 个上游接口；统一 option label/value/children 模型，picker column 维护索引，datetime 使用原生 `DatePicker` 和范围 clamp，dropdown 父子通过 Environment 维护当前展开项。
- [ ] RED 覆盖 String/Number 值、默认索引、联动列、immediateChange、confirm/cancel/change 顺序、日期格式与 min/max、级联路径、dropdown open/close/select/disabled。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add picker and selection components`；三项全量验证后更新 9 行，覆盖达到 90 / 138 并独立提交进度。

### Task 9: Batch 5 键盘组件族

**Files:**
- Create: `UPKeyboard.swift`, `UPNumberKeyboard.swift`, `UPCarKeyboard.swift`, `UPMessageInput.swift`, `UPKeyboardKey.swift`.
- Test: `KeyboardTests.swift`, `MessageInputTests.swift`.

- [ ] 冻结 4 个上游接口；共享键位值模型，keyboard 负责 show/overlay/safe-area/close，number keyboard 负责 random/dot/delete，car keyboard 负责省份与字母阶段，message input 负责 maxlength/focus/active/error。
- [ ] RED 覆盖按键排列、随机模式确定性注入、输入/delete/change/confirm/cancel/backspace payload、车牌阶段切换、验证码格渲染状态和 disabled。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add keyboard component family`；三项全量验证后更新 4 行，覆盖达到 94 / 138 并独立提交进度。

### Task 10: Batch 6 列表与布局

**Files:**
- Create: `UPList.swift`, `UPListItem.swift`, `UPVirtualList.swift`, `UPRefreshVirtualList.swift`, `UPLazyLoad.swift`, `UPWaterfall.swift`, `UPIndexList.swift`, `UPIndexItem.swift`, `UPIndexAnchor.swift`, `UPIndexListContext.swift`.
- Test: `ListVirtualizationTests.swift`, `WaterfallTests.swift`, `IndexListTests.swift`.

- [ ] 冻结 9 个上游接口；LazyVStack/LazyHStack 实现按需实例化，虚拟列表模型计算 visible range 与 spacer，waterfall 用确定性最短列算法，index-list 用 ScrollViewReader + Environment 定位。
- [ ] RED 覆盖 load/scroll/scrolltolower、item key/estimated size/可见区、refresh 生命周期、lazy 出现回调、瀑布列分配、索引触摸选择/锚点 sticky/active-index emit。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add list and layout components`；三项全量验证后更新 9 行，覆盖达到 103 / 138 并独立提交进度。

### Task 11: Batch 7 通知、浮层和引导

**Files:**
- Create: `UPColumnNotice.swift`, `UPRowNotice.swift`, `UPNoticeBar.swift`, `UPNotify.swift`, `UPPopover.swift`, `UPTooltip.swift`, `UPGuide.swift`, `UPFloatButton.swift`, `UPAgreement.swift`.
- Test: `NoticeTests.swift`, `PopoverGuideTests.swift`, `FloatAgreementTests.swift`.

- [ ] 冻结 9 个上游接口；column/row 共用消息索引与计时模型，notify 使用可控 overlay state，popover/tooltip 由 anchor preference 定位，guide 用步骤 frame 模型，float-button 展开菜单，agreement 以 Binding 维护勾选。
- [ ] RED 覆盖 autoplay/step/duration、click/close/end、notify show/close、popover placement/selection、tooltip copy/click、guide next/skip/finish、float item-click、agreement change/link 回调。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add notice overlay and guide components`；三项全量验证后更新 9 行，覆盖达到 112 / 138 并独立提交进度。

### Task 12: Batch 8 手势与刷新

**Files:**
- Create: `UPDragsort.swift`, `UPPullRefresh.swift`, `UPSwipeAction.swift`, `UPSwipeActionItem.swift`, `UPSwipeActionContext.swift`, `UPReadMore.swift`.
- Test: `DragRefreshTests.swift`, `SwipeActionTests.swift`, `ReadMoreTests.swift`.

- [ ] 冻结 5 个上游接口；dragsort 用 Binding 数组和 move payload，pull-refresh 用阈值状态机包裹 refreshable，swipe-action 父级保证单开，read-more 用测量高度与展开状态。
- [ ] RED 覆盖 drag start/change/end 与 reorder、下拉距离/状态/refresh/restore、互斥展开/点击 option/close、read-more collapse/expand/toggle 与高度阈值。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add gesture and refresh components`；三项全量验证后更新 5 行，覆盖达到 117 / 138 并独立提交进度。

### Task 13: Batch 9 图片、绘制和码生成

**Files:**
- Create: `UPAlbum.swift`, `UPCanvas.swift`, `UPSignature.swift`, `UPCropper.swift`, `UPPoster.swift`, `UPQRCode.swift`, `UPBarcode.swift`, `UPColorPicker.swift` plus focused renderer/model files named `UPCanvasRenderer.swift`, `UPCodeRenderer.swift`, `UPCropModel.swift` if a source exceeds 350 lines.
- Test: `AlbumCanvasTests.swift`, `SignatureCropperTests.swift`, `PosterCodeTests.swift`, `ColorPickerTests.swift`.

- [ ] 冻结 8 个上游接口；album 计算网格与 preview payload，canvas 输出确定性绘制命令，signature/cropper 用 gesture + Core Graphics，poster 组合图文命令，QR/barcode 用 Core Image，color-picker 维持上游 RGBA/HSB/hex 模型并封装原生 ColorPicker。
- [ ] RED 覆盖图片数量/间距/预览、画布尺寸与命令顺序、签名 undo/clear/export、裁剪边界/缩放/旋转、海报层级、码数据/纠错级别/输出尺寸、颜色模型双向转换与 confirm/cancel。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add image drawing and code components`；三项全量验证后更新 8 行，覆盖达到 125 / 138 并独立提交进度。

### Task 14: Batch 10 富文本、文档和媒体

**Files:**
- Create: `UPMarkdown.swift`, `UPParse.swift`, `UPPDFReader.swift`, `UPShortVideo.swift`, `UPUpload.swift` plus `UPUploadModel.swift`.
- Test: `RichTextTests.swift`, `PDFVideoTests.swift`, `UploadTests.swift`.

- [ ] 冻结 5 个上游接口；markdown/parse 生成受控 AttributedString 与 link/image 回调，PDFKit/AVKit 用条件编译 representable，upload 用 PhotosPicker/文件选择输入和宿主注入 uploader，不内置服务端协议。
- [ ] RED 覆盖标题/列表/强调/link、HTML fallback、安全 URL、PDF 页码/翻页/错误、视频 play/pause/ended/error、文件状态队列/数量/大小/删除/retry/success/fail/progress 事件。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add rich document and media components`；三项全量验证后更新 5 行，覆盖达到 130 / 138 并独立提交进度。

### Task 15: Batch 11 系统能力

**Files:**
- Create: `UPNoNetwork.swift`, `UPCityLocate.swift`, `UPNetworkMonitoring.swift`, `UPLocationProviding.swift`.
- Test: `NetworkLocationTests.swift`.

- [ ] 冻结 2 个上游接口；Network.framework 适配器注入连接状态，CoreLocation 适配器注入授权/坐标/反地理编码，View 只消费协议状态且不写宿主 Info.plist。
- [ ] RED 覆盖 disconnected/retry/restored、授权 notDetermined/denied/authorized、定位成功/失败/取消、城市选择与 change payload；测试只用 fake adapter。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add network and location components`；三项全量验证后更新 2 行，覆盖达到 132 / 138 并独立提交进度。

### Task 16: Batch 12 复杂业务组件

**Files:**
- Create: `UPCalendar.swift`, `UPCalendarStrip.swift`, `UPCoupon.swift`, `UPGoodsSKU.swift`, `UPCateTab.swift`, `UPTree.swift` plus focused value models `UPCalendarModels.swift`, `UPCouponModels.swift`, `UPGoodsSKUModels.swift`, `UPTreeModels.swift`.
- Test: `CalendarTests.swift`, `CouponSKUTests.swift`, `CateTreeTests.swift`.

- [ ] 冻结 6 个上游接口；calendar 使用 Calendar API 与单选/范围/多选状态机，strip 复用日期模型，coupon 用 Binding 表示选择，goods-sku 以库存约束的规格笛卡尔索引驱动，cate-tab 与 tree 使用稳定 id 和层级展开状态。
- [ ] RED 覆盖日期 min/max/月切换/confirm、strip 滚动与 change、优惠券可用/禁用/选择、SKU 组合库存/价格/数量/confirm、分类联动、树单选/多选/展开/半选/disabled 与 payload。
- [ ] GREEN 后定向测试并精确提交，消息 `feat: add calendar and business components`；三项全量验证后更新 6 行，覆盖达到 138 / 138 并独立提交进度。

### Task 17: 最终 138 / 138 审计

**Files:**
- Modify: `UVIEW_PLUS_PROGRESS.md`
- Create: `docs/superpowers/reports/2026-08-21-uview-plus-compatibility-audit.md`

- [ ] 从上游 components 目录与进度表分别提取名称并排序比较，断言均为 138、无遗漏、无重复。
- [ ] 扫描 `UltraUI/Sources/UltraUI`，确认不存在 Fastview import/type/condition；审计所有“兼容增强中”既有 dirty 变更，只提交可逐块归属且测试通过的 patch。
- [ ] 运行 `swift test`、`swift build`、generic iOS Simulator build，记录命令、日期、测试数量和最终输出。
- [ ] 报告逐项记录 138 个 Swift 类型、测试文件、平台降级和基线提交；进度表待开始/开发中/兼容增强中归零，已完成与已提交覆盖均为 138 / 138。
- [ ] 精确暂存报告和进度表，检查 staged path/check 后提交 `docs: complete uview plus compatibility audit`。

---

## Plan Maintenance Rule

每完成一项就在本文件把对应 checkbox 改为 `[x]`，但计划勾选更新只与该批进度提交一同精确暂存。若实际上游接口要求调整签名，先在该批实施附录中记录“上游证据 → 调整后的 Swift 签名 → 测试断言”，不得静默偏离，也不得通过删除测试降低完成口径。
