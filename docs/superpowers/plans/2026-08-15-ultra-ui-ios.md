# ultra-ui-ios Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 uview-plus 核心组件移植为 SwiftUI 版本（SPM Package + Demo App），接口保持字符串风格一致。

**Architecture:** SPM Package `UltraUI` 提供组件，Xcode App 工程（xcodegen 生成）内嵌依赖并展示 Demo。组件用 SwiftUI 原生实现，字符串参数内部解析为枚举，弹窗体系为 UPPopup → UPModal 组合，Toast 提供命令式全局 API。

**Tech Stack:** Swift 6.3、SwiftUI、Xcode 26.6、xcodegen 2.46、XCTest、iOS 17.0+

## Global Constraints

- 部署目标 iOS 17.0+，Swift 6 严格并发模式（`@MainActor` 用于 UI 类型）
- 所有组件前缀 `UP`，文件名与类型名一致
- 字符串参数非法值回退默认（与 uview-plus 行为一致），不抛错
- 颜色解析支持 `#RRGGBB`、`#RRGGBBAA`、主题名（primary/success/error/warning/info/default）
- rpx 换算基准宽度 375pt（`UPUnit.rpx(_:)`）
- 默认值严格对齐 uview-plus `props/*.js`（见设计文档）
- 图标字体全量内置 `upicon.ttf`（213 图标），SPM resources 打包
- 每任务结束必须 `swift build`/`xcodebuild` 通过并 commit

---

### Task 1: 工程脚手架（SPM Package + Xcode 工程）

**Files:**
- Create: `UltraUI/Package.swift`
- Create: `UltraUI/Sources/UltraUI/UltraUI.swift`
- Create: `UltraUI/Tests/UltraUITests/UltraUITests.swift`
- Create: `project.yml`（xcodegen 配置）
- Create: `Demo/UltraUIDemoApp.swift`
- Create: `Demo/ContentView.swift`
- Create: `.gitignore`

**Interfaces:**
- Produces: `UltraUI` 库 target（可被 App 依赖）、`UltraUIDemo` App target、`UltraUITests` 测试 target

- [ ] **Step 1: 写 Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UltraUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "UltraUI", targets: ["UltraUI"])
    ],
    targets: [
        .target(name: "UltraUI", resources: [.process("Resources")]),
        .testTarget(name: "UltraUITests", dependencies: ["UltraUI"])
    ]
)
```

- [ ] **Step 2: 写 xcodegen project.yml**

```yaml
name: UltraUIDemo
options:
  bundleIdPrefix: com.xyito
  deploymentTarget:
    iOS: "17.0"
packages:
  UltraUI:
    path: UltraUI
targets:
  UltraUIDemo:
    type: application
    platform: iOS
    sources: [Demo]
    dependencies:
      - package: UltraUI
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: com.xyito.ultrauidemo
        SWIFT_VERSION: "6.0"
  UltraUITests:
    type: bundle.unit-test
    platform: iOS
    sources: [UltraUI/Tests]
    dependencies:
      - target: UltraUIDemo
      - package: UltraUI
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "6.0"
schemes:
  UltraUIDemo:
    build:
      targets:
        UltraUIDemo: all
    run:
      config: Debug
    test:
      targets:
        - UltraUITests
```

- [ ] **Step 3: 写最小 Demo App**

`Demo/UltraUIDemoApp.swift`:
```swift
import SwiftUI

@main
struct UltraUIDemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

`Demo/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("UltraUI Demo")
            }
            .navigationTitle("UltraUI")
        }
    }
}
```

- [ ] **Step 4: 生成工程并构建验证**

```bash
xcodegen generate
xcodebuild -scheme UltraUIDemo -destination 'platform=iOS Simulator,name=iPhone 17' build
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: scaffold SPM package and demo app"
```

---

### Task 2: Core 层（UPTheme / UPUnit / UPColor / UPConfig）

**Files:**
- Create: `UltraUI/Sources/UltraUI/Core/UPTheme.swift`
- Create: `UltraUI/Sources/UltraUI/Core/UPUnit.swift`
- Create: `UltraUI/Sources/UltraUI/Core/UPColor.swift`
- Create: `UltraUI/Sources/UltraUI/Core/UPConfig.swift`
- Test: `UltraUI/Tests/UltraUITests/CoreTests.swift`

**Interfaces:**
- Produces: `UPTheme`（环境值，含全部色板）、`UPUnit.rpx(_:)`、`UPColor.parse(_:) -> Color`、`UPConfig`（各组件默认值静态常量）

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class CoreTests: XCTestCase {
    func testColorHex() {
        XCTAssertEqual(UPColor.parse("#3c9cff"), Color(red: 0x3c/255, green: 0x9c/255, blue: 0xff/255))
    }
    func testColorHexAlpha() {
        XCTAssertEqual(UPColor.parse("#3c9cff80"), Color(red: 0x3c/255, green: 0x9c/255, blue: 0xff/255, opacity: 0x80/255))
    }
    func testColorThemeName() {
        XCTAssertEqual(UPColor.parse("primary"), UPTheme.default.primary)
    }
    func testColorInvalidFallsBack() {
        XCTAssertEqual(UPColor.parse("not-a-color"), UPTheme.default.content)
    }
    func testRpx() {
        XCTAssertEqual(UPUnit.rpx(650), 650 * 375.0 / 375.0)
        XCTAssertEqual(UPUnit.rpx(325), 325.0)
    }
    func testConfigDefaults() {
        XCTAssertEqual(UPConfig.button.type, "info")
        XCTAssertEqual(UPConfig.modal.confirmText, "确认")
        XCTAssertEqual(UPConfig.popup.mode, "bottom")
    }
}
```

- [ ] **Step 2: 运行确认失败**

```bash
swift test --package-path UltraUI
```

- [ ] **Step 3: 实现 UPTheme**

```swift
import SwiftUI

public struct UPTheme: Equatable, Sendable {
    public var main: Color = .init(hex: 0x303133)
    public var content: Color = .init(hex: 0x606266)
    public var tips: Color = .init(hex: 0x909193)
    public var light: Color = .init(hex: 0xC0C4CC)
    public var border: Color = .init(hex: 0xDADBDE)
    public var bg: Color = .init(hex: 0xF3F4F6)
    public var disabled: Color = .init(hex: 0xC8C9CC)
    public var primary: Color = .init(hex: 0x3C9CFF)
    public var primaryDark: Color = .init(hex: 0x398ADE)
    public var primaryDisabled: Color = .init(hex: 0x9AC AFC)
    public var primaryLight: Color = .init(hex: 0xECF5FF)
    public var warning: Color = .init(hex: 0xF9AE3D)
    public var warningDark: Color = .init(hex: 0xF1A532)
    public var warningDisabled: Color = .init(hex: 0xF9D39B)
    public var warningLight: Color = .init(hex: 0xFDF6EC)
    public var success: Color = .init(hex: 0x5AC725)
    public var successDark: Color = .init(hex: 0x53C21D)
    public var successDisabled: Color = .init(hex: 0xA9E08F)
    public var successLight: Color = .init(hex: 0xF5FFF0)
    public var error: Color = .init(hex: 0xF56C6C)
    public var errorDark: Color = .init(hex: 0xE45656)
    public var errorDisabled: Color = .init(hex: 0xF7B2B2)
    public var errorLight: Color = .init(hex: 0xFEF0F0)
    public var info: Color = .init(hex: 0x909399)
    public var infoDark: Color = .init(hex: 0x767A82)
    public var infoDisabled: Color = .init(hex: 0xC4C6C9)
    public var infoLight: Color = .init(hex: 0xF4F4F5)

    public static let `default` = UPTheme()
}

public extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private struct UPThemeKey: EnvironmentKey {
    static let defaultValue = UPTheme.default
}
public extension EnvironmentValues {
    var upTheme: UPTheme {
        get { self[UPThemeKey.self] }
        set { self[UPThemeKey.self] = newValue }
    }
}
```

- [ ] **Step 4: 实现 UPUnit / UPColor / UPConfig**

```swift
import SwiftUI

public enum UPUnit {
    /// rpx → pt，375 基准宽度
    public static func rpx(_ value: Double) -> Double { value * 375.0 / 375.0 }
    public static func rpx(_ value: CGFloat) -> CGFloat { CGFloat(rpx(Double(value))) }
    /// 解析 "650rpx" / "20px" / 数值 → pt
    public static func parse(_ value: Any) -> CGFloat {
        if let n = value as? NSNumber { return CGFloat(truncating: n) }
        if let s = value as? String {
            if s.hasSuffix("rpx") { return rpx(CGFloat(Double(s.dropLast(3)) ?? 0)) }
            if s.hasSuffix("px") { return CGFloat(Double(s.dropLast(2)) ?? 0) }
            if let d = Double(s) { return CGFloat(d) }
        }
        return 0
    }
}
```

```swift
import SwiftUI

public enum UPColor {
    public static func parse(_ value: String, theme: UPTheme = .default) -> Color {
        if value.hasPrefix("#") {
            let hex = value.dropFirst()
            if hex.count == 6, let v = UInt32(hex, radix: 16) {
                return Color(hex: v)
            }
            if hex.count == 8, let v = UInt32(hex, radix: 16) {
                return Color(red: Double((v >> 24) & 0xFF) / 255,
                             green: Double((v >> 16) & 0xFF) / 255,
                             blue: Double((v >> 8) & 0xFF) / 255,
                             opacity: Double(v & 0xFF) / 255)
            }
        }
        switch value {
        case "primary": return theme.primary
        case "success": return theme.success
        case "error": return theme.error
        case "warning": return theme.warning
        case "info", "default": return theme.info
        case "main": return theme.main
        case "content": return theme.content
        case "tips": return theme.tips
        case "light": return theme.light
        case "border": return theme.border
        case "bg": return theme.bg
        case "disabled": return theme.disabled
        default: return theme.content
        }
    }
}
```

```swift
import Foundation

public enum UPConfig {
    public enum button {
        public static let hairline = false
        public static let type = "info"
        public static let size = "normal"
        public static let shape = "square"
        public static let plain = false
        public static let disabled = false
        public static let loading = false
        public static let loadingText = ""
        public static let loadingMode = "spinner"
        public static let loadingSize: Double = 15
        public static let text = ""
        public static let icon = ""
        public static let iconColor = ""
        public static let color = ""
        public static let throttleTime: Double = 0
        public static let block = false
    }
    public enum popup {
        public static let show = false
        public static let overlay = true
        public static let mode = "bottom"
        public static let duration: Double = 300
        public static let closeable = false
        public static let closeOnClickOverlay = true
        public static let zIndex: Double = 10075
        public static let safeAreaInsetBottom = true
        public static let safeAreaInsetTop = false
        public static let closeIconPos = "top-right"
        public static let round = "20px"
        public static let zoom = true
        public static let bgColor = ""
        public static let overlayOpacity: Double = 0.5
    }
    public enum modal {
        public static let show = false
        public static let title = ""
        public static let content = ""
        public static let confirmText = "确认"
        public static let cancelText = "取消"
        public static let showConfirmButton = true
        public static let showCancelButton = false
        public static let confirmColor = "#2979ff"
        public static let cancelColor = "#606266"
        public static let buttonReverse = false
        public static let zoom = true
        public static let asyncClose = false
        public static let closeOnClickOverlay = false
        public static let negativeTop: Double = 0
        public static let width = "650rpx"
        public static let confirmButtonShape = ""
        public static let duration: Double = 400
        public static let contentTextAlign = "left"
        public static let asyncCloseTip = "操作中..."
        public static let asyncCancelClose = false
    }
    public enum toast {
        public static let zIndex: Double = 10090
        public static let duration: Double = 2000
        public static let position = "center"
    }
    public enum overlay {
        public static let show = false
        public static let zIndex: Double = 10070
        public static let duration: Double = 300
        public static let opacity: Double = 0.5
    }
    public enum icon {
        public static let name = ""
        public static let color = "#606266"
        public static let size = "16px"
        public static let bold = false
        public static let label = ""
        public static let labelPos = "right"
        public static let labelSize = "15px"
        public static let labelColor = "#606266"
        public static let space = "3px"
        public static let customPrefix = "uicon"
    }
    public enum line {
        public static let color = "#d6d7d9"
        public static let length = "100%"
        public static let direction = "row"
        public static let hairline = true
        public static let margin: Double = 0
        public static let dashed = false
    }
    public enum gap {
        public static let bgColor = "transparent"
        public static let height: Double = 20
        public static let marginTop: Double = 0
        public static let marginBottom: Double = 0
    }
    public enum loadingIcon {
        public static let show = true
        public static let color = "#909399"
        public static let textColor = "#909399"
        public static let vertical = false
        public static let mode = "spinner"
        public static let size: Double = 24
        public static let textSize: Double = 15
        public static let text = ""
        public static let duration: Double = 1200
        public static let inactiveColor = ""
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

```bash
swift test --package-path UltraUI
```

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: core layer - theme, unit, color, config"
```

---

### Task 3: UPIcon（内置图标字体全量）

**Files:**
- Create: `UltraUI/Sources/UltraUI/Resources/upicon.ttf`（复制自 uview-plus）
- Create: `UltraUI/Sources/UltraUI/Components/UPIcon.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPIconMap.swift`（由 icons.js 生成）
- Test: `UltraUI/Tests/UltraUITests/IconTests.swift`

**Interfaces:**
- Produces: `UPIcon(name:color:size:bold:label:labelPos:labelSize:space:customPrefix:)`，`UPIconMap.glyph(for:) -> String`，`.onTap` 事件

- [ ] **Step 1: 复制字体并生成映射**

```bash
mkdir -p UltraUI/Sources/UltraUI/Resources
cp uview-plus/src/uni_modules/uview-plus/components/u-icon/upicon.ttf UltraUI/Sources/UltraUI/Resources/
python3 - << 'PY'
import re, json
src = open('uview-plus/src/uni_modules/uview-plus/components/u-icon/icons.js').read()
pairs = re.findall(r"'([^']+)':\s*'\\u([0-9a-fA-F]{4})'", src)
with open('UltraUI/Sources/UltraUI/Components/UPIconMap.swift', 'w') as f:
    f.write("import Foundation\n\npublic enum UPIconMap {\n    public static let glyphs: [String: String] = [\n")
    for name, code in pairs:
        f.write(f'        "{name}": "\\u{{{code}}}",\n')
    f.write("    ]\n\n    public static func glyph(for name: String) -> String {\n        glyphs[name] ?? \"\"\n    }\n}\n")
print(f"generated {len(pairs)} glyphs")
PY
```

- [ ] **Step 2: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class IconTests: XCTestCase {
    func testGlyphExists() {
        XCTAssertFalse(UPIconMap.glyph(for: "uicon-checkmark").isEmpty)
        XCTAssertEqual(UPIconMap.glyphs.count, 213)
    }
    func testUnknownGlyphEmpty() {
        XCTAssertEqual(UPIconMap.glyph(for: "uicon-nope"), "")
    }
}
```

- [ ] **Step 3: 实现 UPIcon**

```swift
import SwiftUI

public struct UPIcon: View {
    var name: String
    var color: String
    var size: String
    var bold: Bool
    var label: String
    var labelPos: String
    var labelSize: String
    var labelColor: String
    var space: String
    var customPrefix: String
    var onTap: (() -> Void)?

    public init(name: String = UPConfig.icon.name,
                color: String = UPConfig.icon.color,
                size: String = UPConfig.icon.size,
                bold: Bool = UPConfig.icon.bold,
                label: String = UPConfig.icon.label,
                labelPos: String = UPConfig.icon.labelPos,
                labelSize: String = UPConfig.icon.labelSize,
                labelColor: String = UPConfig.icon.labelColor,
                space: String = UPConfig.icon.space,
                customPrefix: String = UPConfig.icon.customPrefix,
                onTap: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.size = size
        self.bold = bold
        self.label = label
        self.labelPos = labelPos
        self.labelSize = labelSize
        self.labelColor = labelColor
        self.space = space
        self.customPrefix = customPrefix
        self.onTap = onTap
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        let glyph = UPIconMap.glyph(for: customPrefix.isEmpty ? name : "\(customPrefix)-\(name)")
        let fontSize = UPUnit.parse(size)
        return HStack(spacing: UPUnit.parse(space)) {
            if labelPos == "left" { labelView }
            Text(glyph)
                .font(.custom("uview-icon", size: fontSize))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(UPColor.parse(color, theme: theme))
            if labelPos == "right" { labelView }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var labelView: some View {
        Text(label)
            .font(.system(size: UPUnit.parse(labelSize)))
            .foregroundStyle(UPColor.parse(labelColor, theme: theme))
    }
}

public extension UPIcon {
    func onTap(_ action: @escaping () -> Void) -> UPIcon {
        var copy = self
        copy.onTap = action
        return copy
    }
}
```

- [ ] **Step 4: 注册字体（App 启动时）**

`UltraUI/Sources/UltraUI/UltraUI.swift`:
```swift
import SwiftUI

public enum UltraUI {
    public static func registerFonts() {
        guard let url = Bundle.module.url(forResource: "upicon", withExtension: "ttf"),
              let data = try? Data(contentsOf: url) as CFData,
              let provider = CGDataProvider(data: data),
              let font = CGFont(provider) else { return }
        CTFontManagerRegisterGraphicsFont(font, nil)
    }
}
```

Demo App `init()` 中调用 `UltraUI.registerFonts()`。

- [ ] **Step 5: 测试 + 构建验证 + Commit**

```bash
swift test --package-path UltraUI
xcodegen generate && xcodebuild -scheme UltraUIDemo -destination 'platform=iOS Simulator,name=iPhone 17' build
git add -A && git commit -m "feat: icon component with full uview-plus glyph set"
```

---

### Task 4: UPLine / UPGap / UPLoadingIcon

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPLine.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPGap.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPLoadingIcon.swift`
- Test: `UltraUI/Tests/UltraUITests/BasicComponentsTests.swift`

**Interfaces:**
- Produces: `UPLine(color:length:direction:hairline:margin:dashed:)`、`UPGap(bgColor:height:marginTop:marginBottom:)`、`UPLoadingIcon(show:color:textColor:vertical:mode:size:textSize:text:duration:inactiveColor:)`

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class BasicComponentsTests: XCTestCase {
    func testLineDefaults() {
        let line = UPLine()
        XCTAssertEqual(line.color, "#d6d7d9")
        XCTAssertEqual(line.direction, "row")
    }
    func testGapDefaults() {
        let gap = UPGap()
        XCTAssertEqual(gap.height, 20)
    }
    func testLoadingDefaults() {
        let l = UPLoadingIcon()
        XCTAssertEqual(l.mode, "spinner")
        XCTAssertEqual(l.size, 24)
    }
}
```

- [ ] **Step 2: 实现 UPLine**

```swift
import SwiftUI

public struct UPLine: View {
    var color: String
    var length: String
    var direction: String
    var hairline: Bool
    var margin: Double
    var dashed: Bool

    public init(color: String = UPConfig.line.color,
                length: String = UPConfig.line.length,
                direction: String = UPConfig.line.direction,
                hairline: Bool = UPConfig.line.hairline,
                margin: Double = UPConfig.line.margin,
                dashed: Bool = UPConfig.line.dashed) {
        self.color = color
        self.length = length
        self.direction = direction
        self.hairline = hairline
        self.margin = margin
        self.dashed = dashed
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        let isRow = direction == "row"
        let lineColor = UPColor.parse(color, theme: theme)
        let lineWidth: CGFloat = hairline ? 0.5 : 1
        let lineView = Group {
            if dashed {
                DashedLine(color: lineColor, width: lineWidth)
            } else {
                Rectangle().fill(lineColor).frame(height: lineWidth)
            }
        }
        return Group {
            if isRow {
                HStack {
                    lineView.frame(maxWidth: .infinity)
                }
                .frame(height: 1)
                .padding(.vertical, margin)
            } else {
                VStack {
                    lineView.frame(width: lineWidth, maxHeight: .infinity)
                }
                .frame(width: 1)
                .padding(.horizontal, margin)
            }
        }
    }
}

private struct DashedLine: View {
    let color: Color
    let width: CGFloat
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, dash: [4, 3]))
        }
        .frame(height: width)
    }
}
```

- [ ] **Step 3: 实现 UPGap**

```swift
import SwiftUI

public struct UPGap: View {
    var bgColor: String
    var height: Double
    var marginTop: Double
    var marginBottom: Double

    public init(bgColor: String = UPConfig.gap.bgColor,
                height: Double = UPConfig.gap.height,
                marginTop: Double = UPConfig.gap.marginTop,
                marginBottom: Double = UPConfig.gap.marginBottom) {
        self.bgColor = bgColor
        self.height = height
        self.marginTop = marginTop
        self.marginBottom = marginBottom
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        Color.clear
            .frame(height: height)
            .background(bgColor == "transparent" ? Color.clear : UPColor.parse(bgColor, theme: theme))
            .padding(.top, marginTop)
            .padding(.bottom, marginBottom)
    }
}
```

- [ ] **Step 4: 实现 UPLoadingIcon**

```swift
import SwiftUI

public struct UPLoadingIcon: View {
    var show: Bool
    var color: String
    var textColor: String
    var vertical: Bool
    var mode: String
    var size: Double
    var textSize: Double
    var text: String
    var duration: Double
    var inactiveColor: String

    public init(show: Bool = UPConfig.loadingIcon.show,
                color: String = UPConfig.loadingIcon.color,
                textColor: String = UPConfig.loadingIcon.textColor,
                vertical: Bool = UPConfig.loadingIcon.vertical,
                mode: String = UPConfig.loadingIcon.mode,
                size: Double = UPConfig.loadingIcon.size,
                textSize: Double = UPConfig.loadingIcon.textSize,
                text: String = UPConfig.loadingIcon.text,
                duration: Double = UPConfig.loadingIcon.duration,
                inactiveColor: String = UPConfig.loadingIcon.inactiveColor) {
        self.show = show
        self.color = color
        self.textColor = textColor
        self.vertical = vertical
        self.mode = mode
        self.size = size
        self.textSize = textSize
        self.text = text
        self.duration = duration
        self.inactiveColor = inactiveColor
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        if show {
            Group {
                if vertical {
                    VStack(spacing: 8) { spinner; textView }
                } else {
                    HStack(spacing: 8) { spinner; textView }
                }
            }
        }
    }

    private var spinner: some View {
        let c = UPColor.parse(color, theme: theme)
        return Group {
            if mode == "circle" {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(c, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))
                    .onAppear { start() }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: c))
                    .scaleEffect(size / 20)
            }
        }
    }

    private var textView: some View {
        Text(text)
            .font(.system(size: textSize))
            .foregroundStyle(UPColor.parse(textColor, theme: theme))
    }

    @State private var rotation: Double = 0
    private func start() {
        withAnimation(.linear(duration: duration / 1000).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}
```

- [ ] **Step 5: 测试 + Commit**

```bash
swift test --package-path UltraUI
git add -A && git commit -m "feat: line, gap, loading-icon components"
```

---

### Task 5: UPOverlay + UPPopup

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPOverlay.swift`
- Create: `UltraUI/Sources/UltraUI/Components/UPPopup.swift`
- Test: `UltraUI/Tests/UltraUITests/PopupTests.swift`

**Interfaces:**
- Produces: `UPOverlay(show:zIndex:duration:opacity:onTap:)`、`UPPopup(show:overlay:mode:duration:closeable:closeOnClickOverlay:zIndex:safeAreaInsetBottom:safeAreaInsetTop:closeIconPos:round:zoom:bgColor:overlayOpacity:onClose:onOpen:onClickOverlay:)`，`UPPopup` 支持 `@ViewBuilder content` 闭包

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class PopupTests: XCTestCase {
    func testOverlayDefaults() {
        let o = UPOverlay()
        XCTAssertEqual(o.zIndex, 10070)
        XCTAssertEqual(o.opacity, 0.5)
    }
    func testPopupDefaults() {
        let p = UPPopup(show: .constant(false)) { EmptyView() }
        XCTAssertEqual(p.mode, "bottom")
        XCTAssertEqual(p.duration, 300)
        XCTAssertTrue(p.closeOnClickOverlay)
    }
}
```

- [ ] **Step 2: 实现 UPOverlay**

```swift
import SwiftUI

public struct UPOverlay: View {
    var show: Bool
    var zIndex: Double
    var duration: Double
    var opacity: Double
    var onTap: (() -> Void)?

    public init(show: Bool = UPConfig.overlay.show,
                zIndex: Double = UPConfig.overlay.zIndex,
                duration: Double = UPConfig.overlay.duration,
                opacity: Double = UPConfig.overlay.opacity,
                onTap: (() -> Void)? = nil) {
        self.show = show
        self.zIndex = zIndex
        self.duration = duration
        self.opacity = opacity
        self.onTap = onTap
    }

    public var body: some View {
        Color.black
            .opacity(show ? opacity : 0)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { if show { onTap?() } }
            .animation(.easeInOut(duration: duration / 1000), value: show)
    }
}
```

- [ ] **Step 3: 实现 UPPopup**

```swift
import SwiftUI

public struct UPPopup<Content: View>: View {
    @Binding var show: Bool
    var overlay: Bool
    var mode: String
    var duration: Double
    var closeable: Bool
    var closeOnClickOverlay: Bool
    var zIndex: Double
    var safeAreaInsetBottom: Bool
    var safeAreaInsetTop: Bool
    var closeIconPos: String
    var round: String
    var zoom: Bool
    var bgColor: String
    var overlayOpacity: Double
    var onClose: (() -> Void)?
    var onOpen: (() -> Void)?
    var onClickOverlay: (() -> Void)?
    @ViewBuilder var content: () -> Content

    public init(show: Binding<Bool>,
                overlay: Bool = UPConfig.popup.overlay,
                mode: String = UPConfig.popup.mode,
                duration: Double = UPConfig.popup.duration,
                closeable: Bool = UPConfig.popup.closeable,
                closeOnClickOverlay: Bool = UPConfig.popup.closeOnClickOverlay,
                zIndex: Double = UPConfig.popup.zIndex,
                safeAreaInsetBottom: Bool = UPConfig.popup.safeAreaInsetBottom,
                safeAreaInsetTop: Bool = UPConfig.popup.safeAreaInsetTop,
                closeIconPos: String = UPConfig.popup.closeIconPos,
                round: String = UPConfig.popup.round,
                zoom: Bool = UPConfig.popup.zoom,
                bgColor: String = UPConfig.popup.bgColor,
                overlayOpacity: Double = UPConfig.popup.overlayOpacity,
                onClose: (() -> Void)? = nil,
                onOpen: (() -> Void)? = nil,
                onClickOverlay: (() -> Void)? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self._show = show
        self.overlay = overlay
        self.mode = mode
        self.duration = duration
        self.closeable = closeable
        self.closeOnClickOverlay = closeOnClickOverlay
        self.zIndex = zIndex
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.safeAreaInsetTop = safeAreaInsetTop
        self.closeIconPos = closeIconPos
        self.round = round
        self.zoom = zoom
        self.bgColor = bgColor
        self.overlayOpacity = overlayOpacity
        self.onClose = onClose
        self.onOpen = onOpen
        self.onClickOverlay = onClickOverlay
        self.content = content
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        ZStack {
            if overlay {
                UPOverlay(show: show, zIndex: zIndex - 1, duration: duration, opacity: overlayOpacity) {
                    if closeOnClickOverlay {
                        show = false
                        onClose?()
                    }
                    onClickOverlay?()
                }
            }
            if show {
                panel
                    .transition(transition)
                    .zIndex(zIndex)
            }
        }
        .animation(.easeInOut(duration: duration / 1000), value: show)
        .onChange(of: show) { _, newValue in
            if newValue { onOpen?() } else { onClose?() }
        }
    }

    private var transition: AnyTransition {
        switch mode {
        case "top": .move(edge: .top)
        case "bottom": .move(edge: .bottom)
        case "left": .move(edge: .leading)
        case "right": .move(edge: .trailing)
        default: zoom ? .scale(scale: 0.8).combined(with: .opacity) : .opacity
        }
    }

    private var panel: some View {
        Group {
            switch mode {
            case "top":
                VStack { panelContent; Spacer(minLength: 0) }
            case "bottom":
                VStack { Spacer(minLength: 0); panelContent }
            case "left":
                HStack { panelContent; Spacer(minLength: 0) }
            case "right":
                HStack { Spacer(minLength: 0); panelContent }
            default:
                ZStack { panelContent }
            }
        }
        .ignoresSafeArea(edges: mode == "top" ? .top : (mode == "bottom" ? .bottom : []))
    }

    private var panelContent: some View {
        content()
            .frame(maxWidth: mode == "center" ? nil : .infinity)
            .background(bgColor.isEmpty ? Color.white : UPColor.parse(bgColor, theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: UPUnit.parse(round)))
            .overlay(alignment: closeIconAlignment) {
                if closeable {
                    Button {
                        show = false
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.tips)
                            .padding(8)
                            .background(Circle().fill(theme.bg))
                    }
                    .padding(8)
                }
            }
    }

    private var closeIconAlignment: Alignment {
        switch closeIconPos {
        case "top-left": .topLeading
        case "bottom-left": .bottomLeading
        case "bottom-right": .bottomTrailing
        default: .topTrailing
        }
    }
}

public extension UPPopup {
    func onClose(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onClose = action; return c }
    func onOpen(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onOpen = action; return c }
    func onClickOverlay(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onClickOverlay = action; return c }
}
```

- [ ] **Step 4: 测试 + Commit**

```bash
swift test --package-path UltraUI
git add -A && git commit -m "feat: overlay and popup components"
```

---

### Task 6: UPButton

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPButton.swift`
- Test: `UltraUI/Tests/UltraUITests/ButtonTests.swift`

**Interfaces:**
- Produces: `UPButton(type:size:shape:plain:disabled:loading:loadingText:loadingMode:loadingSize:text:icon:iconColor:color:hairline:block:throttleTime:onTap:)`，`.onTap(_:)` 修饰符

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class ButtonTests: XCTestCase {
    func testDefaults() {
        let b = UPButton()
        XCTAssertEqual(b.type, "info")
        XCTAssertEqual(b.size, "normal")
        XCTAssertEqual(b.shape, "square")
    }
    func testSizeHeights() {
        XCTAssertEqual(UPButton.height(for: "large"), 50)
        XCTAssertEqual(UPButton.height(for: "normal"), 40)
        XCTAssertEqual(UPButton.height(for: "small"), 30)
        XCTAssertEqual(UPButton.height(for: "mini"), 22)
    }
}
```

- [ ] **Step 2: 实现 UPButton**

```swift
import SwiftUI

public struct UPButton: View {
    var type: String
    var size: String
    var shape: String
    var plain: Bool
    var disabled: Bool
    var loading: Bool
    var loadingText: String
    var loadingMode: String
    var loadingSize: Double
    var text: String
    var icon: String
    var iconColor: String
    var color: String
    var hairline: Bool
    var block: Bool
    var throttleTime: Double
    var onTap: (() -> Void)?

    public init(type: String = UPConfig.button.type,
                size: String = UPConfig.button.size,
                shape: String = UPConfig.button.shape,
                plain: Bool = UPConfig.button.plain,
                disabled: Bool = UPConfig.button.disabled,
                loading: Bool = UPConfig.button.loading,
                loadingText: String = UPConfig.button.loadingText,
                loadingMode: String = UPConfig.button.loadingMode,
                loadingSize: Double = UPConfig.button.loadingSize,
                text: String = UPConfig.button.text,
                icon: String = UPConfig.button.icon,
                iconColor: String = UPConfig.button.iconColor,
                color: String = UPConfig.button.color,
                hairline: Bool = UPConfig.button.hairline,
                block: Bool = UPConfig.button.block,
                throttleTime: Double = UPConfig.button.throttleTime,
                onTap: (() -> Void)? = nil) {
        self.type = type
        self.size = size
        self.shape = shape
        self.plain = plain
        self.disabled = disabled
        self.loading = loading
        self.loadingText = loadingText
        self.loadingMode = loadingMode
        self.loadingSize = loadingSize
        self.text = text
        self.icon = icon
        self.iconColor = iconColor
        self.color = color
        self.hairline = hairline
        self.block = block
        self.throttleTime = throttleTime
        self.onTap = onTap
    }

    @Environment(\.upTheme) private var theme

    public static func height(for size: String) -> CGFloat {
        switch size {
        case "large": 50
        case "small": 30
        case "mini": 22
        default: 40
        }
    }

    public var body: some View {
        let bg = backgroundColor
        let fg = foregroundColor
        return Button(action: handleTap) {
            HStack(spacing: 6) {
                if loading {
                    UPLoadingIcon(show: true, color: fg.toHexString(), mode: loadingMode, size: loadingSize)
                } else if !icon.isEmpty {
                    UPIcon(name: icon, color: iconColor.isEmpty ? fg.toHexString() : iconColor, size: "\(loadingSize)")
                }
                if !displayText.isEmpty {
                    Text(displayText)
                        .font(.system(size: fontSize))
                        .foregroundStyle(fg)
                }
            }
            .frame(maxWidth: block ? .infinity : nil)
            .frame(height: Self.height(for: size))
            .padding(.horizontal, horizontalPadding)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: hairline ? 0.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading)
        .opacity(disabled ? 0.5 : 1)
    }

    private var displayText: String {
        if loading && !loadingText.isEmpty { return loadingText }
        return text
    }

    private var fontSize: CGFloat {
        switch size {
        case "large": 16
        case "small": 14
        case "mini": 12
        default: 15
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case "large": 20
        case "small": 12
        case "mini": 8
        default: 16
        }
    }

    private var cornerRadius: CGFloat {
        shape == "circle" ? Self.height(for: size) / 2 : 3
    }

    private var themeColor: Color {
        switch type {
        case "primary": theme.primary
        case "success": theme.success
        case "error": theme.error
        case "warning": theme.warning
        default: theme.info
        }
    }

    private var backgroundColor: Color {
        if !color.isEmpty { return UPColor.parse(color, theme: theme) }
        if plain { return .clear }
        return themeColor
    }

    private var foregroundColor: Color {
        if !color.isEmpty { return .white }
        if plain { return themeColor }
        return .white
    }

    private var borderColor: Color {
        if plain { return themeColor }
        return themeColor
    }

    private func handleTap() {
        guard !disabled, !loading else { return }
        if throttleTime > 0 {
            let now = Date()
            if now.timeIntervalSince(lastTap) < throttleTime / 1000 { return }
            lastTap = now
        }
        onTap?()
    }

    @State private var lastTap = Date.distantPast
}

public extension UPButton {
    func onTap(_ action: @escaping () -> Void) -> UPButton {
        var copy = self
        copy.onTap = action
        return copy
    }
}

private extension Color {
    func toHexString() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
```

- [ ] **Step 3: 测试 + Commit**

```bash
swift test --package-path UltraUI
git add -A && git commit -m "feat: button component"
```

---

### Task 7: UPModal

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPModal.swift`
- Test: `UltraUI/Tests/UltraUITests/ModalTests.swift`

**Interfaces:**
- Produces: `UPModal(show:title:content:confirmText:cancelText:showConfirmButton:showCancelButton:confirmColor:cancelColor:buttonReverse:zoom:asyncClose:closeOnClickOverlay:negativeTop:width:confirmButtonShape:duration:contentTextAlign:asyncCloseTip:asyncCancelClose:onConfirm:onCancel:onClose:onCancelOnAsync:)`，支持 `@ViewBuilder content` 覆盖默认内容

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class ModalTests: XCTestCase {
    func testDefaults() {
        let m = UPModal(show: .constant(false))
        XCTAssertEqual(m.confirmText, "确认")
        XCTAssertEqual(m.cancelText, "取消")
        XCTAssertTrue(m.showConfirmButton)
        XCTAssertFalse(m.showCancelButton)
        XCTAssertEqual(m.width, "650rpx")
    }
}
```

- [ ] **Step 2: 实现 UPModal**

```swift
import SwiftUI

public struct UPModal<Content: View>: View {
    @Binding var show: Bool
    var title: String
    var content: String
    var confirmText: String
    var cancelText: String
    var showConfirmButton: Bool
    var showCancelButton: Bool
    var confirmColor: String
    var cancelColor: String
    var buttonReverse: Bool
    var zoom: Bool
    var asyncClose: Bool
    var closeOnClickOverlay: Bool
    var negativeTop: Double
    var width: String
    var confirmButtonShape: String
    var duration: Double
    var contentTextAlign: String
    var asyncCloseTip: String
    var asyncCancelClose: Bool
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    var onClose: (() -> Void)?
    var onCancelOnAsync: (() -> Void)?
    @ViewBuilder var customContent: () -> Content

    public init(show: Binding<Bool>,
                title: String = UPConfig.modal.title,
                content: String = UPConfig.modal.content,
                confirmText: String = UPConfig.modal.confirmText,
                cancelText: String = UPConfig.modal.cancelText,
                showConfirmButton: Bool = UPConfig.modal.showConfirmButton,
                showCancelButton: Bool = UPConfig.modal.showCancelButton,
                confirmColor: String = UPConfig.modal.confirmColor,
                cancelColor: String = UPConfig.modal.cancelColor,
                buttonReverse: Bool = UPConfig.modal.buttonReverse,
                zoom: Bool = UPConfig.modal.zoom,
                asyncClose: Bool = UPConfig.modal.asyncClose,
                closeOnClickOverlay: Bool = UPConfig.modal.closeOnClickOverlay,
                negativeTop: Double = UPConfig.modal.negativeTop,
                width: String = UPConfig.modal.width,
                confirmButtonShape: String = UPConfig.modal.confirmButtonShape,
                duration: Double = UPConfig.modal.duration,
                contentTextAlign: String = UPConfig.modal.contentTextAlign,
                asyncCloseTip: String = UPConfig.modal.asyncCloseTip,
                asyncCancelClose: Bool = UPConfig.modal.asyncCancelClose,
                onConfirm: (() -> Void)? = nil,
                onCancel: (() -> Void)? = nil,
                onClose: (() -> Void)? = nil,
                onCancelOnAsync: (() -> Void)? = nil,
                @ViewBuilder customContent: @escaping () -> Content = { EmptyView() }) {
        self._show = show
        self.title = title
        self.content = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.showConfirmButton = showConfirmButton
        self.showCancelButton = showCancelButton
        self.confirmColor = confirmColor
        self.cancelColor = cancelColor
        self.buttonReverse = buttonReverse
        self.zoom = zoom
        self.asyncClose = asyncClose
        self.closeOnClickOverlay = closeOnClickOverlay
        self.negativeTop = negativeTop
        self.width = width
        self.confirmButtonShape = confirmButtonShape
        self.duration = duration
        self.contentTextAlign = contentTextAlign
        self.asyncCloseTip = asyncCloseTip
        self.asyncCancelClose = asyncCancelClose
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.onClose = onClose
        self.onCancelOnAsync = onCancelOnAsync
        self.customContent = customContent
    }

    @Environment(\.upTheme) private var theme
    @State private var loading = false

    public var body: some View {
        UPPopup(show: $show, mode: "center", zoom: zoom, duration: duration,
                closeOnClickOverlay: closeOnClickOverlay, safeAreaInsetBottom: false,
                round: "6px", onClose: onClose) {
            VStack(spacing: 0) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.main)
                        .padding(.top, 25)
                        .padding(.bottom, 12)
                }
                if !(customContent() is EmptyView) {
                    customContent()
                        .padding(.horizontal, 25)
                        .padding(.bottom, 25)
                } else if !content.isEmpty {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.content)
                        .multilineTextAlignment(textAlignment)
                        .frame(maxWidth: .infinity, alignment: textAlignment == .center ? .center : .leading)
                        .padding(.horizontal, 25)
                        .padding(.top, title.isEmpty ? 25 : 0)
                        .padding(.bottom, 25)
                }
                if showConfirmButton || showCancelButton {
                    UPLine(color: theme.border.toHexString(), direction: "row")
                    HStack(spacing: 0) {
                        if buttonReverse {
                            confirmButton
                            if showConfirmButton && showCancelButton { divider }
                            cancelButton
                        } else {
                            cancelButton
                            if showConfirmButton && showCancelButton { divider }
                            confirmButton
                        }
                    }
                    .frame(height: 48)
                }
            }
            .frame(width: UPUnit.parse(width))
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, negativeTop)
        }
    }

    private var textAlignment: TextAlignment {
        contentTextAlign == "center" ? .center : (contentTextAlign == "right" ? .trailing : .leading)
    }

    private var divider: some View {
        UPLine(color: theme.border.toHexString(), direction: "col")
            .frame(height: 48)
    }

    private var confirmButton: some View {
        Button {
            if asyncClose {
                loading = true
            } else {
                show = false
            }
            onConfirm?()
        } label: {
            Group {
                if loading {
                    UPLoadingIcon(show: true, color: confirmColor, mode: "spinner", size: 18)
                } else {
                    Text(confirmText)
                        .font(.system(size: 16))
                        .foregroundStyle(UPColor.parse(confirmColor, theme: theme))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button {
            if asyncClose && loading {
                if !asyncCloseTip.isEmpty {
                    UPToast.show(message: asyncCloseTip, type: "none", position: "center")
                }
                onCancelOnAsync?()
            } else {
                if !asyncCancelClose { show = false }
                onCancel?()
            }
        } label: {
            Text(cancelText)
                .font(.system(size: 16))
                .foregroundStyle(UPColor.parse(cancelColor, theme: theme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

public extension UPModal {
    func onConfirm(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onConfirm = action; return c }
    func onCancel(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onCancel = action; return c }
    func onClose(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onClose = action; return c }
    func onCancelOnAsync(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onCancelOnAsync = action; return c }
}
```

- [ ] **Step 3: 测试 + Commit**

```bash
swift test --package-path UltraUI
git add -A && git commit -m "feat: modal component"
```

---

### Task 8: UPToast（命令式 + 声明式）

**Files:**
- Create: `UltraUI/Sources/UltraUI/Components/UPToast.swift`
- Test: `UltraUI/Tests/UltraUITests/ToastTests.swift`

**Interfaces:**
- Produces: `UPToast.show(message:type:position:duration:zIndex:)` 静态方法、`UPToastView` 声明式组件、`UPToastCenter`（ObservableObject 环境对象）

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import UltraUI

final class ToastTests: XCTestCase {
    func testTypeIcon() {
        XCTAssertEqual(UPToast.iconName(for: "success"), "uicon-checkmark")
        XCTAssertEqual(UPToast.iconName(for: "error"), "uicon-close")
        XCTAssertEqual(UPToast.iconName(for: "warning"), "uicon-info-circle")
    }
    func testPositionAlignment() {
        XCTAssertEqual(UPToast.alignment(for: "top"), .top)
        XCTAssertEqual(UPToast.alignment(for: "bottom"), .bottom)
        XCTAssertEqual(UPToast.alignment(for: "center"), .center)
    }
}
```

- [ ] **Step 2: 实现 UPToast**

```swift
import SwiftUI

public final class UPToastCenter: ObservableObject {
    @Published public var message: String = ""
    @Published public var type: String = "default"
    @Published public var position: String = "center"
    @Published public var isShowing: Bool = false
    private var timer: Timer?

    public static let shared = UPToastCenter()

    public func show(message: String, type: String = "default",
                     position: String = "center", duration: Double = UPConfig.toast.duration) {
        self.message = message
        self.type = type
        self.position = position
        withAnimation(.easeInOut(duration: 0.2)) { isShowing = true }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration / 1000, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) { self?.isShowing = false }
            }
        }
    }

    public func hide() {
        timer?.invalidate()
        withAnimation(.easeInOut(duration: 0.2)) { isShowing = false }
    }
}

public enum UPToast {
    public static func show(message: String, type: String = "default",
                            position: String = "center", duration: Double = UPConfig.toast.duration) {
        UPToastCenter.shared.show(message: message, type: type, position: position, duration: duration)
    }

    public static func iconName(for type: String) -> String {
        switch type {
        case "success": "uicon-checkmark"
        case "error": "uicon-close"
        case "warning": "uicon-info-circle"
        case "loading": ""
        default: ""
        }
    }

    public static func alignment(for position: String) -> Alignment {
        switch position {
        case "top": .top
        case "bottom": .bottom
        default: .center
        }
    }
}

public struct UPToastView: View {
    @ObservedObject var center: UPToastCenter

    public init(center: UPToastCenter = .shared) {
        self.center = center
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        if center.isShowing {
            VStack(spacing: 8) {
                if center.type == "loading" {
                    UPLoadingIcon(show: true, color: "#ffffff", mode: "circle", size: 25)
                } else if !UPToast.iconName(for: center.type).isEmpty {
                    UPIcon(name: UPToast.iconName(for: center.type), color: "#ffffff", size: "17px")
                }
                if !center.message.isEmpty {
                    Text(center.message)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: UPToast.alignment(for: center.position))
            .padding(.top, center.position == "top" ? 60 : 0)
            .padding(.bottom, center.position == "bottom" ? 40 : 0)
            .allowsHitTesting(false)
            .transition(.opacity)
            .zIndex(10090)
        }
    }
}
```

- [ ] **Step 3: 测试 + Commit**

```bash
swift test --package-path UltraUI
git add -A && git commit -m "feat: toast component with imperative API"
```

---

### Task 9: Demo App（首页 + 组件页）

**Files:**
- Create: `Demo/HomeView.swift`
- Create: `Demo/ButtonDemoView.swift`
- Create: `Demo/PopupDemoView.swift`
- Create: `Demo/ModalDemoView.swift`
- Create: `Demo/ToastDemoView.swift`
- Create: `Demo/IconDemoView.swift`
- Create: `Demo/MiscDemoView.swift`（Line/Gap/LoadingIcon/Overlay）
- Modify: `Demo/ContentView.swift`、`Demo/UltraUIDemoApp.swift`

**Interfaces:**
- Consumes: 全部组件
- Produces: 可运行的 Demo App，每个组件一个演示页

- [ ] **Step 1: 改造 App 入口（注册字体 + 挂 Toast 层）**

`Demo/UltraUIDemoApp.swift`:
```swift
import SwiftUI
import UltraUI

@main
struct UltraUIDemoApp: App {
    init() {
        UltraUI.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay(alignment: .top) { UPToastView() }
        }
    }
}
```

- [ ] **Step 2: 首页列表**

`Demo/HomeView.swift`:
```swift
import SwiftUI
import UltraUI

struct HomeView: View {
    var body: some View {
        List {
            NavigationLink("Button") { ButtonDemoView() }
            NavigationLink("Popup") { PopupDemoView() }
            NavigationLink("Modal") { ModalDemoView() }
            NavigationLink("Toast") { ToastDemoView() }
            NavigationLink("Icon") { IconDemoView() }
            NavigationLink("Line / Gap / Loading / Overlay") { MiscDemoView() }
        }
        .navigationTitle("UltraUI Demo")
    }
}
```

- [ ] **Step 3: 各组件 Demo 页**

`Demo/ButtonDemoView.swift`（示例，其余页同模式）:
```swift
import SwiftUI
import UltraUI

struct ButtonDemoView: View {
    @State private var loading = false
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                UPButton(type: "primary", size: "large", text: "主按钮")
                UPButton(type: "success", text: "成功")
                UPButton(type: "error", text: "错误")
                UPButton(type: "warning", text: "警告")
                UPButton(type: "info", text: "信息")
                UPButton(type: "primary", shape: "circle", text: "胶囊按钮")
                UPButton(type: "primary", plain: true, text: "镂空按钮")
                UPButton(type: "primary", disabled: true, text: "禁用按钮")
                UPButton(type: "primary", loading: loading, loadingText: "加载中", text: "加载")
                    .onTap { loading = true; DispatchQueue.main.asyncAfter(deadline: .now() + 2) { loading = false } }
                UPButton(type: "primary", icon: "uicon-checkmark", text: "带图标")
                    .onTap { UPToast.show(message: "点击了按钮", type: "success") }
            }
            .padding(20)
        }
        .navigationTitle("Button")
    }
}
```

- [ ] **Step 4: 构建 + 运行验证**

```bash
xcodegen generate
xcodebuild -scheme UltraUIDemo -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install booted <app path> && xcrun simctl launch booted com.xyito.ultrauidemo
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: demo app with component showcase pages"
```

---

### Task 10: 全量验证 + 收尾

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 全量测试 + 构建**

```bash
swift test --package-path UltraUI
xcodegen generate
xcodebuild -scheme UltraUIDemo -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme UltraUIDemo -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- [ ] **Step 2: 更新 README**

```markdown
# ultra-ui-ios

uview-plus 的 SwiftUI 原生版本（SPM Package + Demo App）。

## 组件
UPButton / UPPopup / UPModal / UPToast / UPOverlay / UPIcon / UPLine / UPGap / UPLoadingIcon

## 使用
1. `xcodegen generate` 生成工程
2. 打开 UltraUIDemo.xcodeproj 运行
3. 或通过 SPM 依赖 `UltraUI` 包
```

- [ ] **Step 3: 最终 Commit**

```bash
git add -A && git commit -m "docs: finalize readme"
```

---

## Self-Review 记录

- **Spec 覆盖**：9 组件全部有对应 Task（T3-T8）；主题/单位/颜色/配置在 T2；Demo 在 T9；验证在 T10。✓
- **占位符扫描**：无 TBD/TODO；所有代码步骤含完整实现。✓
- **类型一致性**：`UPUnit.parse`、`UPColor.parse`、`UPConfig.*` 命名在 T2 定义，T3-T8 引用一致；`UPToast.show` 在 T7（modal asyncCloseTip）与 T8 定义一致。✓
