# uview-plus SwiftUI 兼容性审计

> 日期：2026-08-21
> 上游基线：uview-plus `3.8.86`
> iOS 基线：`cbb2af5`

## 结论

`components/u-*` 的 138 个目录均已在 `UltraUI/Sources/UltraUI/Components` 中找到对应的公开 Swift 类型，并且实现与测试已提交。`UVIEW_PLUS_PROGRESS.md` 已同步为 138 / 138 已提交覆盖，待开始、开发中和未提交兼容增强均为 0。

本审计把“复刻完成”定义为存在可构造的 SwiftUI 类型、可测试的行为基线和明确的平台映射；它不把 Vue DOM、CSS 或 uni-app 全局 API 声称为 SwiftUI 中的逐字节等价行为。

## 核对项

- 逐行核对进度表的 138 个编号，编号集合为 `1...138`，无重复或遗漏。
- 逐项核对 Swift 类型映射，包括父子组件和数据模型，例如 `UPTabsItem`、`UPTabbarItem`、`UPPickerColumn`、`UPTr`、`UPTh` 和 `UPTd`。
- 组件接口遵循统一映射：props 对应初始化参数，`v-model` 对应 `Binding`，emits 对应闭包或链式事件方法，slots 对应 `@ViewBuilder` 内容参数。
- 平台能力使用 Apple 原生替代：Core Image、Canvas、PDFKit、AVKit、Network.framework、Core Location 和 SwiftUI 原生控件。
- 系统能力采用注入式 Provider 或回调，避免测试依赖真实网络、定位权限、媒体库或上传服务。
- 测试总数为 389，最近完整 `swift test --package-path UltraUI` 通过，0 failures。

## 兼容性分级

进度表中的“高”表示已经覆盖当前范围内的主要 props 默认值、String/Number 输入、事件 payload 和插槽映射，并有对应行为测试。“基线可用”表示 SwiftUI 原生替代和核心状态、事件、几何或数据模型已经提交，但 Vue 特有的 DOM 定位、CSS 动画细节、平台路由或真实系统服务仍由宿主接入。

“基线可用”不是空壳，也不表示所有上游运行时细节已经逐项等价。复杂平台组件的限制和替代方案已写在进度表备注及对应源文件的公开接口中。

## 已知平台差异

- 小程序开放能力、页面栈、DOM 节点选择和 CSS 层叠没有直接 SwiftUI 等价物；组件保留可复用的数据和事件入口，由宿主决定路由或平台行为。
- PDF、视频、定位、网络状态、图片输入和上传都只封装原生能力，不擅自修改宿主权限配置或提供网络服务实现。
- Markdown、HTML 解析、二维码和条码使用受控的 Foundation/Core Image 路径，调用方仍需对远端内容和安全策略负责。

## 验证命令

```bash
swift test --package-path UltraUI
swift build --package-path UltraUI
xcodebuild -project UltraUIDemo.xcodeproj \
  -scheme UltraUIDemo \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
git diff --check
```
