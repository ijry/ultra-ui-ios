# UPCopy 组件设计规格

- 日期：2026-08-21
- 对应 uview-plus 版本：3.8.86
- 上游组件：`u-copy`
- SwiftUI 组件：`UPCopy`

## 1. 目标

在 UltraUI 中提供 `u-copy` 的 SwiftUI 版本，优先保持其 props、默认内容、点击行为和 `success` 事件语义一致，同时用可测试、跨 Apple 平台的方式封装原生剪贴板。

本组件保持独立，不引入 Fastview 专用接口，也不依赖 UltraUI 当前的全局 Toast 或 Modal 实现。

## 2. 上游兼容接口

`UPCopy` 提供以下公开属性：

| uview-plus 接口 | SwiftUI 接口 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `content` | `content: String` | `""` | 要写入剪贴板的文本 |
| `alertStyle` | `alertStyle: String` | `"toast"` | 保留 `toast` / `modal` 呈现偏好元数据 |
| `notice` | `notice: String` | `"复制成功"` | 复制成功提示内容元数据 |
| default slot | `@ViewBuilder contentView` | `Text("复制")` | 可自定义可点击内容 |
| `success` | `.onSuccess { ... }` | 无操作 | 仅在剪贴板写入成功后调用 |

典型用法：

```swift
UPCopy(
    content: "https://example.com",
    alertStyle: "toast",
    notice: "复制成功"
) {
    Text("复制链接")
}
.onSuccess {
    print("copied")
}
```

不传 slot 时：

```swift
UPCopy(content: "hello")
```

组件显示默认文本“复制”。

## 3. 架构

### 3.1 SwiftUI 视图

`UPCopy` 是泛型 SwiftUI `View`，使用 `@ViewBuilder` 保存默认或自定义内容。其根交互区域响应点击并发起复制。

为兼顾默认 slot 与自定义 slot，提供两个初始化入口：

1. 默认内容初始化器，生成 `Text("复制")`。
2. 泛型 `@ViewBuilder` 初始化器，接收调用方内容。

### 3.2 原生剪贴板适配

剪贴板写入由内部可注入闭包完成：

```swift
(String) -> Bool
```

生产环境默认实现按平台选择：

- iOS / tvOS / visionOS：`UIPasteboard.general.string`
- macOS：`NSPasteboard.general`
- 不支持的平台：返回失败

内部注入点不作为业务公开 API；测试通过 `@testable import UltraUI` 注入假写入器，以验证成功、失败和空内容路径，并避免修改开发机器的真实剪贴板。

## 4. 数据流与行为

点击组件后按以下顺序执行：

1. 读取 `content`。
2. 如果 `content.isEmpty`，立即结束：不访问剪贴板，也不触发 `success`。
3. 调用剪贴板写入器。
4. 写入器返回 `true` 时，调用一次 `success` 闭包。
5. 写入器返回 `false` 时，不触发 `success`，组件不崩溃。

`alertStyle` 和 `notice` 会作为兼容属性公开并保留调用方传值。本次实现不直接显示 Toast 或 Modal，原因是：

- SwiftUI 库没有与 uni-app 全局提示完全等价且无宿主依赖的 API；
- 直接绑定 UltraUI 的 Toast / Modal 会扩大组件耦合；
- 当前目标是提供可供未来 Fastview 使用的通用 uview-plus 兼容层，而非加入 Fastview 专用行为。

后续若 UltraUI 建立稳定的全局反馈环境，可在不改变现有初始化接口的前提下消费这两个元数据。

## 5. 错误与边界处理

- 空字符串视为无可复制内容。
- 空内容不调用系统写入器。
- 系统写入失败不调用 `success`。
- `success` 闭包不承诺主线程以外的调度；当前点击与系统写入均在 SwiftUI 交互线程同步执行。
- `content` 严格保持 `String`，不擅自扩大为任意可字符串化类型，因为上游 prop 声明为 `String`。
- `alertStyle` 保持字符串接口，不额外限制枚举值，以兼容上游和已有调用代码。

## 6. 测试策略

遵循 TDD，先创建无法找到 `UPCopy` 的失败测试，再补充最小实现。测试覆盖：

1. `content`、`alertStyle`、`notice` 默认值。
2. 三个上游 props 可自定义并保持传值。
3. 默认 slot 与自定义 slot 均可构造。
4. 空内容不调用写入器、不触发 `success`。
5. 成功写入时传递原始字符串并恰好触发一次 `success`。
6. 写入失败时不触发 `success`。
7. `.onSuccess` 链式修饰器保留组件配置。
8. UltraUI 完整 Swift 测试套件通过。
9. Demo iOS Simulator 构建通过，以验证 Apple 平台条件编译和包集成。

## 7. 文件范围

实现阶段预计仅修改：

```text
UltraUI/Sources/UltraUI/Components/UPCopy.swift
UltraUI/Tests/UltraUITests/CopyTests.swift
UVIEW_PLUS_PROGRESS.md
```

计划文档另存于：

```text
docs/superpowers/plans/2026-08-21-copy.md
```

不修改 `UPConfig.swift`，也不触碰工作区已有的其他未提交组件文件。

## 8. 完成标准

- `UPCopy` 可由 UltraUI 客户端直接导入使用。
- 上游三个 props、默认 slot 与 `success` 事件均有明确 SwiftUI 映射。
- 空内容、成功和失败路径均有自动化测试。
- iOS/macOS 原生剪贴板实现可条件编译。
- `swift test` 和 Demo iOS Simulator 构建通过。
- `UVIEW_PLUS_PROGRESS.md` 将 `u-copy` 标记为已完成，并更新总计。
