# ultra-ui-ios

uview-plus 的 SwiftUI 原生实现。项目提供可独立引用的 `UltraUI` Swift Package，以及覆盖核心组件的 iOS Demo App；组件沿用 uview-plus 的字符串参数风格，并在 SwiftUI 中封装原生交互与动画。

## 已实现组件

- `UPButton`：主题、尺寸、圆角、镂空、加载、图标、节流与 `onTap` / `onClick` 事件
- `UPPopup`：四边 / 居中弹出、遮罩、关闭按钮与打开/关闭/遮罩点击事件
- `UPModal`：确认/取消、异步关闭、自定义内容与事件回调
- `UPToast`：全局命令式 `show` / `hide` API 与声明式展示层
- `UPOverlay`
- `UPIcon`：内置图标字体与标签
- `UPLine`、`UPGap`、`UPLoadingIcon`

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
```

## 验证

```bash
swift test --package-path UltraUI
xcodebuild -project UltraUIDemo.xcodeproj \
  -scheme UltraUIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build CODE_SIGNING_ALLOWED=NO
```
