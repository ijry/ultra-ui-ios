# UltraUI 剩余 uview-plus 组件总体复刻设计

- 日期：2026-08-21
- 上游基线：uview-plus 3.8.86
- 当前范围：`UVIEW_PLUS_PROGRESS.md` 中 82 个“待开始”组件
- 最终目标：138 / 138 个上游组件均具备已提交的 SwiftUI 实现与测试基线

## 1. 背景与目标

UltraUI 已覆盖 56 / 138 个 uview-plus 组件，其中 45 个已完成，11 个已有提交基线并处于兼容增强中。剩余 82 个组件覆盖基础容器、父子组合组件、选择器、列表、手势、绘图、文档、媒体、系统能力和业务组件。

本项目将剩余组件作为一个连续工程推进，不再逐组件请求优先级或普通实现决策。实现按依赖批次进行，每批均完成接口核对、TDD、全量验证、精确提交和进度更新。仅当上游行为与 Apple 平台能力之间存在无法通过既定兼容规则确定的真实产品决策时，才请求用户输入。

## 2. 完成口径

组件只有同时满足以下条件后才能在进度表标记为“已完成”：

1. 已核对 uview-plus 3.8.86 的 props、默认值、emits、slots、公开方法及关键行为。
2. SwiftUI 类型可以独立导入并构造。
3. Vue prop 尽量映射为同名 Swift 初始化参数。
4. `v-model` 映射为 `Binding`，emit 映射为闭包或 `.onXxx` 链式修饰器。
5. 默认和 named slot 映射为 `@ViewBuilder`。
6. 原生平台可实现的关键交互已实现，而非只有空接口。
7. 平台不可成立的 DOM、小程序或 uni-app 行为已映射为原生替代方案或明确的兼容元数据。
8. 具有隔离自动化测试；测试先失败，再以最小实现通过。
9. UltraUI 全量 `swift test` 通过。
10. UltraUIDemo iOS Simulator 构建通过。
11. 实现和测试已精确提交，未混入既有 dirty 文件。

不允许通过批量生成空壳类型获得名义上的 138 / 138。

## 3. 总体架构规则

### 3.1 接口映射

| uview-plus / Vue | UltraUI / SwiftUI |
| --- | --- |
| prop | 同名初始化参数或公开值类型 |
| `String \| Number` | 现有兼容值协议、明确的值枚举或泛型转换入口 |
| `v-model` / `modelValue` | `Binding<Value>` |
| emit | 初始化闭包及 `.onXxx` 链式修饰器 |
| default slot | `@ViewBuilder content` |
| named slot | 对应名称的 `@ViewBuilder` 参数 |
| provide / inject | SwiftUI Environment 或内部 Observable 状态上下文 |
| ref 方法 | 公开控制模型、协调器或可测试实例方法 |
| CSS 单位字符串 | `UPUnit`、`UPStyle`、`UPInsets` 等现有解析能力 |
| DOM / uni API | SwiftUI 或 Apple framework 原生替代 |

公开接口优先维持上游命名。为 Swift 类型安全新增的模型不替换上游兼容入口，而作为补充入口存在。

### 3.2 父子组件

`tabs/tabs-item`、`tabbar/tabbar-item`、`steps/steps-item`、`dropdown/dropdown-item`、`index-list/index-item/index-anchor`、`swipe-action/swipe-action-item`、`table/tr/th/td` 等组件族使用以下策略：

- 父组件持有 Binding 或内部协调状态。
- 子组件通过 Environment 获取父级配置和事件通道。
- 子组件仍提供可独立构造的稳定公开类型。
- 父子接口在同一批次完成，避免出现已提交但无法组合使用的半成品。

### 3.3 系统框架

默认只使用 Apple 原生框架，不新增第三方依赖：

- 二维码 / 条码：Core Image、Core Graphics
- PDF：PDFKit
- 视频：AVKit / AVFoundation
- 图片选择与上传输入：PhotosUI、UniformTypeIdentifiers
- 网络状态：Network.framework
- 定位：CoreLocation
- 富文本 / HTML：AttributedString、Foundation XML/HTML 能力与受控原生桥接
- 剪贴板：UIKit / AppKit

任何权限相关组件必须只提供能力封装，不擅自写入宿主 App 的 Info.plist。需要宿主权限声明时，在组件文档和 API 注释中明确要求。

### 3.4 兼容元数据

以下能力在 Apple 原生环境没有一一对应语义，可保留原值供未来宿主或 Fastview 消费：

- 小程序 open-type、胶囊按钮、页面栈和路由地址
- H5 DOM 节点选择、CSS class、z-index 的浏览器语义
- uni-app 全局 toast、modal、navigateTo、previewImage、downloadFile
- nvue / WXS 特有的优化路径

保留元数据不得引入 Fastview 专用类型或条件分支。UltraUI 保持独立 SwiftUI 库。

## 4. 实施批次

### Batch 1：原语与安全区

`u-view`、`u-status-bar`、`u-safe-bottom`、`u-section`、`u-toolbar`、`u-slider`、`u-subsection`、`u-pagination`

目标：建立通用容器、安全区读取、工具栏和基础选择控制接口，为后续组合组件复用。

### Batch 2：表格、步骤和分页容器

`u-table`、`u-table2`、`u-tr`、`u-th`、`u-td`、`u-steps`、`u-steps-item`、`u-swiper`、`u-swiper-indicator`

目标：建立父子 Environment 协作、表格布局和分页视图基础。

### Batch 3：导航与选项容器

`u-tabs`、`u-tabs-item`、`u-tabbar`、`u-tabbar-item`、`u-navbar`、`u-navbar-mini`、`u-scroll-list`、`u-sticky`

目标：完成横向选择、底部导航、顶部导航和固定定位的原生映射。

### Batch 4：Picker 与选择组件族

`u-picker-data`、`u-picker-column`、`u-picker`、`u-datetime-picker`、`u-select`、`u-choose`、`u-cascader`、`u-dropdown`、`u-dropdown-item`

目标：统一选项值、列状态、Binding、confirm/change/cancel 事件和 Toolbar 复用。

### Batch 5：键盘组件族

`u-keyboard`、`u-number-keyboard`、`u-car-keyboard`、`u-message-input`

目标：共享键位模型和输入事件，同时保留 random、dot、车牌等上游模式。

### Batch 6：列表与布局

`u-list`、`u-list-item`、`u-virtual-list`、`u-refresh-virtual-list`、`u-lazy-load`、`u-waterfall`、`u-index-list`、`u-index-item`、`u-index-anchor`

目标：用 Lazy 容器、PreferenceKey 和 ScrollViewReader 映射虚拟化、可见范围和索引定位。

### Batch 7：通知、浮层和引导

`u-column-notice`、`u-row-notice`、`u-notice-bar`、`u-notify`、`u-popover`、`u-tooltip`、`u-guide`、`u-float-button`、`u-agreement`

目标：复用通知数据模型、Overlay 和原生弹层；业务路由仅保留兼容元数据或通过回调交给宿主。

### Batch 8：手势与刷新

`u-dragsort`、`u-pull-refresh`、`u-swipe-action`、`u-swipe-action-item`、`u-read-more`

目标：使用 SwiftUI gesture、refreshable 和 GeometryReader 实现阈值、排序、展开与事件 payload。

### Batch 9：图片、绘制和码生成

`u-album`、`u-canvas`、`u-signature`、`u-cropper`、`u-poster`、`u-qrcode`、`u-barcode`、`u-color-picker`

目标：建立 Core Graphics / Core Image 渲染和可测试的数据输出模型；预览与导出通过原生回调暴露。

### Batch 10：富文本、文档和媒体

`u-markdown`、`u-parse`、`u-pdf-reader`、`u-short-video`、`u-upload`

目标：使用 AttributedString、PDFKit、AVKit、PhotosUI 封装原生内容能力，并明确远端数据、安全和宿主上传边界。

### Batch 11：系统能力

`u-no-network`、`u-city-locate`

目标：以 Network.framework 和 CoreLocation 提供可注入、可测试的状态模型；权限声明由宿主负责。

### Batch 12：复杂业务组件

`u-calendar`、`u-calendar-strip`、`u-coupon`、`u-goods-sku`、`u-cate-tab`、`u-tree`

目标：在前述原语、选择器、列表和浮层能力稳定后实现复杂组合逻辑。

## 5. 数据流与状态

- 简单展示组件保持值语义。
- 双向选择组件由调用方 Binding 作为单一事实来源。
- 命令式组件使用 `@MainActor` 控制模型，避免把可变引用藏在 View 值中。
- 异步系统能力使用协议或闭包注入，测试不得操作真实网络、定位或用户媒体库。
- 事件顺序按上游实现写入测试，例如 Binding 更新、change、confirm、close 的先后关系。
- 异步事件在主 actor 更新 UI 状态。

## 6. 错误处理

- 无效尺寸和范围值采用与上游一致的归一化或安全边界，不因输入崩溃。
- 系统 API 失败通过上游已有 fail/error 事件映射；上游无失败事件时提供内部安全失败，不擅自增加强制错误 UI。
- 远端内容解析失败显示可配置 fallback，并触发对应错误回调。
- 权限拒绝返回明确状态，不自动打开系统设置。
- 平台不支持的能力必须可以编译，并以受控失败或兼容元数据降级。

## 7. 测试与验证

每批遵循同一验证序列：

1. 为该批每个新公开类型编写失败测试。
2. 运行定向测试，确认因目标类型或行为缺失而 RED。
3. 写最小实现并运行定向测试至 GREEN。
4. 增加父子集成、事件顺序、边界和平台适配测试。
5. 运行 `swift test` 全量测试。
6. 运行 UltraUIDemo generic iOS Simulator build。
7. 对使用 AppKit / macOS 条件分支的批次，以 Swift Package macOS 构建作为编译验证。
8. 精确暂存本批文件并检查 staged path。
9. 提交实现，再更新和提交进度文档。

对于图像、绘图和布局组件，优先测试确定性数据模型、几何计算和渲染输出尺寸；必要时增加固定画布渲染测试，但不依赖不稳定的像素逐点快照。

## 8. Git 与工作区约束

- 只使用当前主工作区。
- 不创建、切换或使用 git worktree。
- 不派发会创建隔离工作区的协作者。
- 不执行 `git reset`、`git clean`、`git add .`。
- 不覆盖、清理或提交当前既有 dirty / untracked 文件。
- 每次使用完整目标路径精确暂存。
- 每次提交前运行 `git diff --cached --name-only` 和 `git diff --cached --check`。
- 如果目标组件必须修改一个已有 dirty 文件，先通过新增独立文件或扩展规避；无法规避时，将目标 patch 与原有 patch逐块隔离，且不得未经审计提交整文件。

## 9. 进度管理

`UVIEW_PLUS_PROGRESS.md` 是唯一进度事实来源。每批完成后更新：

- iOS 基线提交
- 已完成、兼容增强中、开发中、待开始数量
- 已有实现和已提交覆盖率
- 该批组件行的兼容性及备注

组件只有实现和测试已提交、全量验证通过后才从“待开始”改为“已完成”。

## 10. 最终验收

项目完成时必须满足：

- 上游清单仍为 138 个组件，无漏项或重复项。
- 待开始和开发中均为 0。
- 已完成与兼容增强中均有已提交实现；兼容增强中的既有 dirty 工作另行完成审计后归零。
- 已提交覆盖为 138 / 138。
- 全部 Swift 测试通过。
- UltraUIDemo iOS Simulator 构建通过。
- macOS Swift Package 构建通过。
- 没有 Fastview 专用 API。
- 没有把空壳组件计为完成。
- 既有用户修改未被覆盖或错误提交。
