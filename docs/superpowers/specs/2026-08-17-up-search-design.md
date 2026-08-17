# UPSearch 设计说明

## 目标

在 `UltraUI` Swift Package 中实现 uview-plus `u-search` 的 SwiftUI 版本。组件优先保持上游 props、默认值、事件命名和事件载荷一致，同时用 SwiftUI 原生 `TextField`、焦点系统和键盘提交行为完成 iOS 交互。实现不依赖当前共享工作区中其他未提交组件，便于后续 Fastview 适配。

## 范围

本轮只实现单行搜索框，不实现网络请求、历史记录、联想列表、分页或路由跳转。`url` / `linkType` 等跨端导航能力不作为搜索组件职责；保留必要的源兼容字段时不执行平台跳转。

## 对外接口

### 视图

提供 `UPSearch` SwiftUI `View`，主初始化器使用 `Binding<String>`：

- 值与输入：`value`、`placeholder`、`maxlength`、`disabled`、`focus`、`autoBlur`
- 外观：`shape`、`bgColor`、`borderColor`、`color`、`placeholderColor`、`searchIcon`、`searchIconColor`、`searchIconSize`、`iconPosition`、`inputAlign`、`height`、`margin`
- 操作区：`showAction`、`actionText`、`animation`、`onlyClearableOnFocused`
- 兼容样式：`inputStyle`、`actionStyle`、`customStyle`
- 上游命名兼容：保留 `clearabled`；另提供 Swift 侧常用拼写 `clearable`，两者不能产生冲突时以显式传入值为准

提供无内容初始化和 trailing `@ViewBuilder` slot，slot 用于扩展输入框右侧区域，不改变默认操作区语义。

### 事件

事件回调保留 uview-plus 名称和载荷：

- `onChange(String)`：文本变化后触发
- `onSearch(String)`：键盘 Search / 提交触发
- `onCustom(String)`：点击右侧操作按钮触发
- `onClear()`：点击清除触发
- `onFocus(String)` / `onBlur(String)`：焦点变化触发
- `onClick()`：点击禁用组件外壳时触发
- `onClickIcon(String)`：点击搜索图标触发

绑定写入与 `onChange` 的先后顺序固定为：先发出上游事件，再写入绑定，和现有输入类组件的兼容测试约定一致；清除操作同样先更新事件语义，再写入空字符串。

### 控制器

提供 `UPSearchController`（`ObservableObject`、主线程隔离）：

- `focus()`：请求输入框获得焦点
- `blur()`：请求输入框失去焦点
- `clear()`：清空当前值并通过组件绑定完成同步

控制器只保存操作意图和注册的内部动作，不暴露 UIKit 控件实例，避免把实现锁定在 UIKit。

## 结构与数据流

1. `UPSearch` 读取 `Binding<String>` 和标准化后的 props。
2. `@FocusState` 是 SwiftUI 焦点真源；`UPSearchController` 通过注册闭包转发 focus/blur/clear 意图。
3. 原生 `TextField` 负责输入、光标、键盘和提交；`onChange` 统一做最大长度截断、事件回调和绑定写入。
4. 外壳使用 `HStack` / `ZStack` 组合 label、搜索图标、输入框、清除图标和 action 按钮。
5. `iconPosition == "right"` 时只交换图标与输入内容的视觉顺序，不改变事件载荷。
6. `animation` 仅控制 action 区显隐过渡；不改变 `showAction == false` 的行为。

## 默认值与标准化

默认值集中在新增的搜索配置扩展中，不直接编辑共享工作区当前有协作者修改的 `UPConfig.swift`。默认值以 uview-plus 3.x 搜索配置为基准：圆角形状、启用清除、显示搜索操作按钮、左侧图标、32 高度、最大长度不限、自动调整键盘位置并在结束编辑后自动失焦。

字符串或数字单位统一通过现有 `UPUnit` 解析。非法 `shape`、`iconPosition`、`inputAlign`、`maxlength` 和 `height` 使用安全回退值；负的有限 `maxlength` 视为不限，正值按字符数截断。

## 样式映射

- `shape == "round"` 使用胶囊圆角，否则使用小圆角方形。
- 配置 `borderColor` 时绘制边框；未配置时保持无边框。
- `inputAlign` 映射为 SwiftUI `TextAlignment`。
- `customStyle`、`inputStyle`、`actionStyle` 复用现有 `UPStyle` / `.upStyle` 桥接；未支持的 CSS 属性忽略。
- 图标优先复用 `UPIcon`，未知图标仍保持可渲染且不导致输入区崩溃。

## 错误与边界行为

- 禁用状态禁止编辑、聚焦、清除和 action 操作，但保留 `onClick` 兼容回调。
- 空值时不显示清除按钮；`onlyClearableOnFocused` 为真时仅焦点状态显示。
- 外部绑定变化也经过最大长度标准化，避免视图状态和模型不一致。
- 控制器在尚未挂载视图时缓存最后一次操作意图，挂载后执行一次；重复注册不会保留旧视图动作。
- 回调均在主线程执行；组件不创建后台任务，也不产生未处理异常。

## 测试策略

新增 `UPSearchTests`，先覆盖失败再实现：

1. 默认值与所有关键 props 的标准化。
2. `clearabled` / `clearable` 兼容接口及字符串/数字单位输入。
3. 文本输入的最大长度、绑定同步和事件顺序。
4. focus / blur / search / custom / clear / clickIcon 回调载荷。
5. action 显隐、禁用状态和右侧图标布局元数据。
6. `UPSearchController` 在挂载前后调用 focus、blur、clear 的行为。
7. 固定画布的 SwiftUI 原生渲染冒烟测试。

## 非目标

- 不把 `UPSearch` 改造成通用表单输入替代品。
- 不修改已有 `UPInput`、`UPTextarea`、`UPConfig.swift` 或协作者未提交文件。
- 不在本轮实现 uview-plus 的页面导航、搜索建议、滚动 marquee 或网络层。
