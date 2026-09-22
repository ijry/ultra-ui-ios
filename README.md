# ultra-ui-ios

uview-plus 的 SwiftUI 原生实现。项目提供可独立引用的 `UltraUI` Swift Package，以及覆盖核心组件的 iOS Demo App；组件沿用 uview-plus 的字符串参数风格，并在 SwiftUI 中封装原生交互与动画。

## 已实现组件

上游 uview-plus `3.8.113` 的 `components/u-*` 共 140 个目录已全部有对应的 `UP` 前缀 SwiftUI 类型。逐个组件的复刻进度、接口兼容性评级，以及小程序 / DOM / CSS 能力在原生下的适配取舍，见 [UVIEW_PLUS_PROGRESS.md](UVIEW_PLUS_PROGRESS.md)。

Demo App 与上游示例工程的组件页面一一对应，共 103 页，沿用上游的 7 个分类：

| 分类 | 页面数 | 代表组件 |
| --- | ---: | --- |
| 基础组件 | 11 | `UPButton`、`UPIcon`、`UPImage`、`UPText` |
| 表单组件 | 20 | `UPForm`、`UPInput`、`UPPicker`、`UPCalendar` |
| 数据组件 | 7 | `UPTable`、`UPTable2`、`UPVirtualList`、`UPLineProgress` |
| 反馈组件 | 17 | `UPToast`、`UPModal`、`UPActionSheet`、`UPPopover` |
| 布局组件 | 15 | `UPPopup`、`UPCard`、`UPOverlay`、`UPScrollList` |
| 导航组件 | 12 | `UPTabs`、`UPTabbar`、`UPNavbar`、`UPDropdown` |
| 其他组件 | 21 | `UPParse`、`UPMarkdown`、`UPCodeInput`、`UPDragsort` |

## 要求

- iOS 17.0+
- Swift 6+
- Xcode（Demo 工程通过 XcodeGen 生成）

## 运行 Demo

```bash
xcodegen generate
open UltraUIDemo.xcodeproj
```

在 Xcode 中选择 `UltraUIDemo` scheme 后运行。Demo 首页按组件提供独立示例页面。

## 作为本地 Swift Package 使用

将 `UltraUI` 目录作为本地 Package 添加到 App 或 Package 目标后：

```swift
import SwiftUI
import UltraUI

@main
struct ExampleApp: App {
    init() {
        // 图标字体仅需在 App 启动时注册一次。
        UltraUI.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 命令式 Toast 的展示层；通常在根视图挂载一次。
                .overlay { UPToastView() }
        }
    }
}
```

常用组件示例：

```swift
UPButton(type: "primary", text: "保存")
    .onClick {
        UPToast.show(message: "保存成功", type: "success")
    }

UPPopup(show: $showPopup, mode: "bottom", closeable: true) {
    Text("Popup 内容")
        .padding(24)
}

UPModal(
    show: $showModal,
    title: "提示",
    content: "是否继续？",
    showCancelButton: true,
    onConfirm: { /* 处理确认 */ }
)

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

UPTextarea(prop: "bio", placeholder: "介绍一下自己", maxlength: 200, count: true, autoHeight: true)
```

## 验证

```bash
swift test --package-path UltraUI
xcodebuild -project UltraUIDemo.xcodeproj \
  -scheme UltraUIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

两条命令跑的是同一份 `UltraUI/Tests`：前者在宿主平台执行，后者在模拟器上额外覆盖 Demo 的路由契约测试。新增测试文件或 Demo 页后必须先执行 `xcodegen generate`，否则新文件不会进入 Xcode 工程，模拟器全量测试会静默漏跑。这一步现由 `ProjectGenerationContractTests` 在 `swift test` 中强制校验：它会比对 `Demo` 与 `UltraUI/Tests` 下的全部源文件和生成工程的 Sources 编译阶段，漏掉的文件会直接让宿主平台测试失败。
