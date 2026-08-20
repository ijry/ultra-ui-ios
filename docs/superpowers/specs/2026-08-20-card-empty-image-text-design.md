# Card / Empty / Image / Text SwiftUI 复刻设计

> 日期：2026-08-20
> 上游基线：uview-plus 3.8.86
> 目标仓库：ultra-ui-ios

## 目标

在不引入 Fastview 专用 API 或第三方图片库的前提下，完成当前工作区中 `u-card`、`u-empty`、`u-image`、`u-text` 四个组件的 SwiftUI 复刻，使公开初始化参数、默认值、String/Number 输入、事件和 slot 映射尽量保持 uview-plus 兼容，并形成稳定测试基线。

## 范围

### UPCard

- 保留 `full`、标题/副标题、边框、`index`、margin、圆角、缩略图、内边距、头尾显示和阴影等 props。
- `String | Number` 尺寸和间距参数通过 Swift 泛型协议保留源码兼容。
- `head`、`body`、`foot` named slot 映射到 `@ViewBuilder`。
- `click`、`head-click`、`body-click`、`foot-click` 通过闭包和链式修饰器映射，并向回调传递同一个 `index`。
- CSS 阴影和样式字符串转为 SwiftUI 可表达的近似效果，同时保留原始兼容属性。

### UPEmpty

- 保留 `icon`、`text`、颜色/尺寸、`mode`、宽高、`show`、`marginTop`、`customStyle`。
- 按上游规则区分图片 icon 与内置 icon；mode `message` 映射为 `chat`。
- 默认 trailing builder 对应默认 slot。
- 上游实际实现不发出 `click` / `close` 事件，因此不新增虚假回调。

### UPImage

- 保留 `src`、`mode`、尺寸、`shape`、`radius`、懒加载/小程序元数据、loading/error icon、显示开关、fade、webp、duration、bgColor 和 customStyle。
- 远程图片使用 SwiftUI 原生 `AsyncImage`，不增加第三方依赖。
- `loading`、`error` named slot 通过 builder 映射；无 slot 时使用图标占位。
- `click`、`load`、`error` 通过闭包/修饰器映射，错误事件提供结构化错误信息。
- `aspectFill` 等裁剪模式使用 SwiftUI `scaledToFill` / `scaledToFit` 近似；无法在 iOS 原生成立的小程序能力保留为兼容属性。

### UPText

- 保留文字、主题色、显示状态、前后 icon、模式、链接、格式化、拨号元数据、粗体、块级布局、行数、字号、装饰、margin、行高、对齐、换行、`flex1` 和 customStyle。
- 支持 `price`、`date`、`phone`、`name`、`link` 模式的现有格式化语义。
- String/Number 类型属性在 SwiftUI 中保留兼容入口，并转换为原生 CGFloat / Int。
- `click` 通过闭包映射；`link` 使用 `openURL`，`phone` 在 `call` 开启时使用 `tel://` 原生替代。
- `prefixIcon`、`suffixIcon` 使用现有 `UPIcon` 体系。

## 非目标

- 不引入 Kingfisher、SDWebImage 或其他第三方依赖。
- 不实现小程序专有的 DOM、路由、开放能力、长按菜单或上传缓存行为；这些属性仅保留为兼容元数据并在备注/注释中说明。
- 不重置、清理或覆盖工作区中 Button、Form、Input、Modal、Popup、Toast 等其他未提交改动。
- 不在本轮开始新的 uview-plus 组件。

## 测试与验收

1. 先为每个缺失或不完整的行为增加失败测试（RED）。
2. 以最小实现使组件测试通过（GREEN）。
3. 执行 `swift test` 和项目既有的完整测试/构建验证。
4. 检查进度表中四个组件均为 `✅ 已完成`，统计更新为已完成 44、兼容增强中 11、开发中 0、待开始 83、已有实现 55、已提交覆盖 55。
5. 只精确提交四个组件相关源文件、测试、进度表及本设计/计划文档；任何既有无关 dirty/untracked 文件保持原状态。
