# UPActionSheet 设计说明

## 目标

在 `UltraUI` Swift Package 中实现 uview-plus `u-action-sheet` 的 SwiftUI 原生版本。组件优先保持上游 props、默认值、事件名称、事件载荷及关闭时序一致，并使用现有的 `UPPopup` 完成原生底部弹层展示。实现必须独立于共享工作区内协作者正在修改的 `UPPopup`、`UPOverlay`、`UPModal` 和 `UPConfig.swift`，使未来 Fastview 可以复用稳定、接近上游的 Swift API。

## 范围

本轮实现标准的操作菜单：标题、描述、默认 action 列表、取消按钮、可选自定义内容、遮罩关闭控制、动作禁用/加载状态、安全区、圆角和可滚动的最大列表高度。

本轮不实现小程序特有的开放能力，例如 `getUserInfo`、`contact`、`getPhoneNumber`、`launchApp`、`openSetting` 以及对应平台事件。`openType` 和 action 上的 `openType` 字段会保留在 Swift 数据模型中，作为接口和未来 Fastview 适配的兼容数据；iOS 运行时不触发小程序平台能力。

## 实现方案

采用组合式方案：`UPActionSheet` 使用 `UPPopup(show:, mode: "bottom")` 处理遮罩、入场/退场动画、层级和基础安全区域，其内部内容层由 `UPActionSheet` 自己渲染。

不直接使用 `UPPopup` 的关闭事件来派发 ActionSheet 的 `close`。组件会将 `UPPopup` 的 `closeOnClickOverlay` 固定为 `false`，再由 `UPActionSheet` 的遮罩回调根据其自身的 `closeOnClickOverlay` prop 决定是否更新绑定和触发 `close`。这样可以区分用户交互关闭与外部 `show` 绑定变化，保持 ActionSheet 的事件顺序确定。

## 对外接口

### 视图

主初始化器要求 `show: Binding<Bool>`，对应 Vue 的 `v-model:show`：

```swift
UPActionSheet(
    show: $show,
    title: "请选择操作",
    description: "请选择下面的一个选项",
    actions: [
        UPActionSheetAction(name: "编辑"),
        UPActionSheetAction(name: "删除", color: "#fa3534")
    ],
    cancelText: "取消",
    closeOnClickAction: true,
    closeOnClickOverlay: true,
    safeAreaInsetBottom: true,
    round: 0,
    wrapMaxHeight: "600px"
)
```

支持的 props：

- `show: Binding<Bool>`：展示状态。
- `title: String`：标题；非空时显示右上角关闭按钮。
- `description: String`：标题下方或列表上方的描述。
- `actions: [UPActionSheetAction]`：默认操作项。
- `nameKey: String`：从 action 动态字段读取主文案的键，默认 `"name"`。
- `subnameKey: String`：从 action 动态字段读取副文案的键，默认保留上游的 `"subnameKey"` 拼写。
- `cancelText: String`：非空时显示取消按钮。
- `closeOnClickAction: Bool`：选择动作或点击自定义内容后是否关闭，默认 `true`。
- `safeAreaInsetBottom: Bool`：是否给底部安全区留出空间，默认 `true`。
- `openType: String`：保留小程序兼容字段；在 iOS 上不执行平台操作。
- `closeOnClickOverlay: Bool`：点击遮罩是否关闭，默认 `true`。
- `round`：顶部圆角；支持 `String`、`Int`、`Double` 和 `CGFloat`，默认 `0`。
- `wrapMaxHeight`：默认列表的最大高度；支持 `String`、`Int`、`Double` 和 `CGFloat`，默认 `"600px"`。

`round` 和 `wrapMaxHeight` 会在初始化时标准化为原生 `CGFloat`。无效、非有限或负值安全回退为默认值或 `0`，不会使视图崩溃。

提供带 trailing `@ViewBuilder` 的内容初始化器。存在自定义内容时，默认的 `actions` 列表不渲染：

```swift
UPActionSheet(show: $show, title: "自定义操作") {
    VStack {
        Text("自定义内容")
        Divider()
        Text("操作区域")
    }
}
```

### Action 数据模型

`UPActionSheetAction` 是选择事件的载荷，包含类型安全的常用字段和动态 `values`：

```swift
UPActionSheetAction(
    name: "删除",
    subname: "删除后无法恢复",
    color: "#fa3534",
    fontSize: 16,
    disabled: false,
    loading: false,
    openType: ""
)
```

支持使用动态数据配合 `nameKey` 与 `subnameKey`：

```swift
UPActionSheetAction(
    values: [
        "label": "编辑",
        "detail": "修改当前内容"
    ]
)
```

模型字段：

- `id`：稳定的 SwiftUI 列表标识；调用方可显式提供，未提供时由模型生成。
- `name`、`subname`：常用文案字段。
- `color`、`fontSize`：动作主文案样式。
- `disabled`、`loading`：交互状态。
- `openType`：跨端兼容字段。
- `values: [String: String]`：任意上游 action 扩展字段。

便利初始化器会同时写入 `"subname"` 与 `"subnameKey"`，因此上游默认键和 Swift 常见键都能读取到 `subname`。

### 事件

支持初始化器闭包与 fluent modifier：

```swift
UPActionSheet(show: $show, actions: actions)
    .onSelect { action in
        print(action.name)
    }
    .onClose {
        // 用户关闭操作菜单
    }
```

- `onSelect((UPActionSheetAction) -> Void)`：对应上游 `select`，载荷为被点击的完整 action。
- `onClose(() -> Void)`：对应上游 `close`。

不把外部 `show = false` 伪装成用户关闭事件；此时绑定只负责展示状态，不调用 `onClose`。

## 事件与交互时序

1. 点击启用且非 loading 的 action 时，先同步调用 `onSelect(action)`。
2. 若 `closeOnClickAction == true`，随后写入 `show = false`，再调用 `onClose()`。
3. 点击标题关闭按钮或取消按钮时，写入 `show = false`，再调用 `onClose()`。
4. 点击遮罩时，只有 `closeOnClickOverlay == true` 才执行关闭和 `onClose()`；为 `false` 时保持展示且不发事件。
5. 点击自定义内容时，若 `closeOnClickAction == true`，按关闭时序执行；否则保持展示。
6. `disabled == true` 或 `loading == true` 的 action 不发 `select`，不修改绑定，也不发 `close`。
7. 同一用户交互仅发出一次 `close`。

## 样式与原生映射

- 容器固定复用 `UPPopup(mode: "bottom")`，ActionSheet 自己控制其 `closeOnClickOverlay` 行为。
- 非空标题显示居中、加粗标题及右上角关闭按钮。
- 描述显示在标题下方；若没有标题，保留上游的描述顶部间距。
- 默认动作列表在达到 `wrapMaxHeight` 后使用垂直滚动。
- 动作行主文案默认 16pt；有副文案时显示约 13pt 的次级文本。
- `loading` 动作显示原生 SwiftUI `ProgressView` 并保持不可点击。
- `disabled` 动作使用主题弱化颜色并保持不可点击。
- 相邻动作之间绘制细分隔线；取消按钮存在时，在其前绘制约 6pt 的间隔带。
- `round` 映射为底部弹层的顶部两角圆角；默认 `0` 不额外圆角。
- `safeAreaInsetBottom` 为真时在内容底部包含设备安全区；为假时不额外添加安全区间距。
- 颜色通过已有 `UPColor.parse` 与主题环境解析；未知颜色使用主题安全回退。

## 默认值与配置隔离

新增 `UltraUI/Sources/UltraUI/Core/UPActionSheetConfig.swift`，集中保存 ActionSheet 的上游默认值，避免改动当前协作者正在编辑的 `UPConfig.swift`。

默认值以本地检出的 uview-plus 3.x `u-action-sheet` 源码为准：

- `show = false`
- `title = ""`
- `description = ""`
- `actions = []`
- `nameKey = "name"`
- `subnameKey = "subnameKey"`
- `cancelText = ""`
- `closeOnClickAction = true`
- `safeAreaInsetBottom = true`
- `openType = ""`
- `closeOnClickOverlay = true`
- `round = 0`
- `wrapMaxHeight = "600px"`

## 边界与兼容行为

- 空 `actions` 且没有自定义内容时保留标题、描述和取消按钮区域，避免布局异常。
- `nameKey` 或 `subnameKey` 为空、未知时安全显示空文案，不崩溃。
- 动作的 `fontSize` 允许字符串或数值单位；无效值回退默认字体。
- 自定义内容拥有默认列表的优先级，与上游 slot 行为一致。
- 不暴露 UIKit 控件实例或内部手势状态，保持未来 Fastview 的实现自由度。
- 组件仅在主线程处理 `Binding` 和 SwiftUI 事件，不创建后台任务。

## 测试策略

新增 `ActionSheetTests.swift`，使用 TDD 先覆盖失败场景，再实现最小生产代码：

1. 配置默认值、单位解析及 `round` / `wrapMaxHeight` 标准化。
2. `UPActionSheetAction` 常用字段、动态 `values` 与 `nameKey` / `subnameKey` 读取。
3. `select` 在绑定写入和 `close` 之前发生的事件顺序。
4. 取消、标题关闭、遮罩关闭以及 `closeOnClickOverlay == false` 的行为。
5. `closeOnClickAction == false`、禁用动作和 loading 动作的行为。
6. 自定义内容优先级及其点击关闭语义。
7. 关键样式元数据和固定画布 SwiftUI 渲染冒烟测试。

## 非目标

- 不修改 `UPPopup`、`UPOverlay`、`UPModal`、`UPConfig.swift` 或任何协作者未提交文件。
- 不实现小程序 `openType` 的授权、客服、启动 App 或错误回调能力。
- 不实现 ActionSheet 的网络数据加载、导航、动画手势拖拽或多级菜单。
