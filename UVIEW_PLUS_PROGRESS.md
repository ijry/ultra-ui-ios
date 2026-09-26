# uview-plus SwiftUI 复刻进度

> 最后更新：2026-09-04
> 上游基线：uview-plus `3.8.113`，以 `components/u-*` 目录为完整清单
> iOS 基线：`main` / `269d9e6`

## 总览

| 指标 | 数量 | 说明 |
| --- | ---: | --- |
| 上游组件目录 | 140 | 包括公开组件、配套子组件和内部辅助组件 |
| 已完成 | 120 | 已提交，具备对应 SwiftUI 类型和测试基线 |
| 兼容增强中 | 18 | `u-tabs`、`u-car-keyboard`、`u-number-keyboard`、`u-modal`、`u-picker`、`u-datetime-picker`、`u-toolbar`、`u-read-more`、`u-no-network`、`u-city-locate`、`u-swipe-action`、`u-swipe-action-item`、`u-guide`、`u-keyboard`、`u-index-anchor`、`u-index-list`、`u-pdf-reader`、`u-notify` 已有提交基线，行为/文案修复尚未提交 |
| 开发中 | 2 | `u-novel-reader`、`u-tabs-pro` 实现与测试已 GREEN，尚未提交 |
| 待开始 | 0 | 140 个上游目录均有对应 SwiftUI 类型 |
| 已有实现覆盖 | 140 / 140 | `已完成 + 兼容增强中 + 开发中`，100% |
| 已提交覆盖 | 138 / 140 | `已完成 + 兼容增强中` 均已有已提交基线，约 98.6% |

## 状态口径

| 标记 | 复刻进度 | 接口兼容性口径 |
| --- | --- | --- |
| ✅ | 已完成 | 已提交 SwiftUI 实现与测试基线；接口兼容性在“高”或“基线可用”栏中单独标注 |
| 🔄 | 兼容增强中 | 已有可用且已提交的 SwiftUI 基线，另有尚未提交的接口或行为增强 |
| 🚧 | 开发中 | 已有未提交实现或测试；尚未完成独立验证和提交，不能视为稳定接口 |
| ⬜ | 待开始 | 尚未实现；接口兼容性未评估 |

接口映射原则：uview-plus named slot 对应 SwiftUI `@ViewBuilder`；Vue emit 对应闭包或链式事件修饰符；无法在 iOS 原生平台成立的小程序、DOM、CSS 或路由能力会保留兼容元数据，或在备注中明确采用原生替代方案。

输入组件族的原生适配语义：`placeholderClass` 无 CSS class 对应物；`fixed`、`adjustPosition`、`holdKeyboard`、`showConfirmBar`、`disableDefaultPadding` 属小程序键盘与页面上推语义；`cursor`、`cursorSpacing`、`selectionStart`、`selectionEnd` 因 SwiftUI 不公开光标位置 API 而仅作元数据保留；`ignoreCompositionEvent` 的输入法合成事件由系统托管；上游 blur 前 150ms 去抖（用于保证清除按钮可点）在 `@FocusState` 下时序不同，改由 `onlyClearableOnFocused` 与 disabled 抑制共同覆盖。

表单组件族的原生适配语义：上游 `validate` 返回 Promise 并 reject 错误数组，Swift 侧改为同步 `Bool` 返回值加 `errors` 字典，`$nextTick` 时序由 SwiftUI 的状态更新取代；`errorType: 'toast'` 上游直接调用全局 `toast()`，Swift 侧由 `UPFormContext.toastMessage` 暴露首条错误、交宿主 `UPToastCenter` 呈现，与本包其余组件一致地保持呈现权在宿主。

公告组件族的原生适配语义：`speed`（每秒滚动 px）与 `duration`（滚动周期 ms）作为兼容元数据保留，实际滚动交 SwiftUI 动画；`disableTouch` 的手势切换限小程序平台；`url` + `linkType` 的路由跳转由宿主实现，与 `UPButton` 的开放能力转发一致。

旧表格组件族的原生适配语义：上游 `u-th`/`u-td` 在 `mounted` 中经 `$parent` 反查父表并把样式拷进自身，SwiftUI 无此机制，改由 `UPTable` 通过 Environment 下发 `UPTableStyleContext`；上游用 CSS `flex: 0 0 <width>` 固定列宽，Swift 侧改为 `fixedWidth`（自适应时为 `nil`）；`padding` 的 CSS 简写拆为纵横两个 inset。

`u-table2` 的照抄决策：上游 `emits` 声明 11 个事件但实际只 emit 6 个名字，`select-all`/`cell-click`/`row-dblclick`/`header-click`/`filter-change` 是死声明（其中 `handleHeaderClick` 存在且已绑定，却只做排序从不 emit），故不建模，改由 `UPTable2.declaredButNeverEmittedEventNames` 记录并用测试固定。上游同样**不存在**全选、半选 indeterminate、合计行与 `selectable` 行禁用回调，未按 element-plus 直觉补齐。以下反直觉行为按约定照抄并在源码注释标注，以保证迁移可预测：`sortable: 'custom'` 仍走本地排序（上游 `!!column.sortable`）；排序第三态是删除条件而非 `order: null`；`selection-change` 早于 `select`；选择只向下级联不更新父行；`hasTree` 只看第一层故纯 `hasChildren` 懒加载树无展开箭头；`defaultExpandAll` 是 merge 永不移除；空数据判定用原始 `data` 故过滤为空时不显示 `emptyText`；`maxHeight` 直拼 `px` 使 `"50vh"` 变 `"50vhpx"`；固定列仅认严格 `"left"` 且浮层需先横向滚动才显形。渲染层（固定列重复渲染浮层、`spanMethod` 合并单元格）保持简化基线；上游 `tableRow.vue` 的 `getCellSpan` 对象分支存在 ReferenceError，未移植。

## 组件清单

| # | uview-plus 组件 | SwiftUI 类型 | 复刻进度 | 接口兼容性 | 备注 |
| ---: | --- | --- | --- | --- | --- |
| 1 | `u-action-sheet` | `UPActionSheet` | ✅ 已完成 | 高 | props、事件、默认/description 插槽及 `UPConfig.actionSheet` 已覆盖 |
| 2 | `u-action-sheet-data` | `UPActionSheetData` | ✅ 已完成 | 属性/事件对齐 | 新增组件本体（只读输入框 + 透明遮盖层 + `u-action-sheet`）：6 个 props、`update:modelValue`、`trigger` 插槽与 `select`/`open`/`close`；`labelKey` 默认 `'name'`、`valueKey` 默认 `'value'`（与 `u-picker-data` 的 `'id'` 不一致，照抄）。action 数据模型仍是 `UPActionSheetAction` |
| 3 | `u-agreement` | `UPAgreement` | ✅ 已完成 | 属性/事件对齐 | 2 个 prop 与 confirm 事件全覆盖，隐私弹窗、`showModal/confirm/cancel/openAgreement` 与声明插槽已移植；上游取消退出应用改为回调宿主 |
| 4 | `u-album` | `UPAlbum` | ✅ 已完成 | 属性/事件对齐 | 16 个 prop 与 preview/albumWidth 全覆盖，对象数组 + keyName、autoWrap、单图长宽比与「+N」提示已移植；系统预览层由宿主负责 |
| 5 | `u-alert` | `UPAlert` | ✅ 已完成 | 高 | props、显示/关闭行为、事件和插槽已覆盖 |
| 6 | `u-avatar` | `UPAvatar` | ✅ 已完成 | 高 | props、String/Number 尺寸、事件已覆盖 |
| 7 | `u-avatar-group` | `UPAvatarGroup` | ✅ 已完成 | 高 | 头像组布局、超量显示和数据输入已覆盖 |
| 8 | `u-back-top` | `UPBackTop` | ✅ 已完成 | 高 | props、阈值、默认插槽、click；滚动动作由 `ScrollViewReader` 接入 |
| 9 | `u-badge` | `UPBadge` | ✅ 已完成 | 高 | props、定位和 String/Number 输入已覆盖 |
| 10 | `u-barcode` | `UPBarcode` | ✅ 已完成 | 属性/事件对齐 | 20 个 props、`rendered`/`error` 两个事件；`UPBarcodeEncoder` 逐位照抄上游手写编码器（CODE128 Code B / CODE39 / EAN13 / EAN8 / EAN5 / EAN2 / UPC / UPCA / UPCE），画布尺寸与文字坐标公式可单测；`validator` 放行但 `switch` 未覆盖的 ITF/MSI/pharmacode/codabar 照抄退回 CODE128；绘制改用 SwiftUI `Canvas`，`useCanvas: false` 对应 `exportImage()` |
| 11 | `u-box` | `UPBox` | ✅ 已完成 | 高 | 三区域布局、默认值、颜色及 named slots 已覆盖 |
| 12 | `u-button` | `UPButton` | ✅ 已完成 | 属性/事件对齐 | 原生 Button 封装；String/Number 文本/尺寸/时间 props、点击节流、默认 slot、开放能力宿主转发已覆盖。本轮对齐上游 `baseColor`/`loadingColor`/`iconColorCom`：默认 `type:"info"` 改为「白底(#ffffff/暗#1c1c1e) + mainColor 文字(#303133/暗#f5f5f5) + 边框色(#dadbde/暗#3a3a3c)」的次要按钮（此前误渲染成灰底 #909399 实心）；其余 type 实心色底白字；plain 透明底、文字/边框取类型色；显式 `color` 实心用 color/白字、plain 用 color 文字；loading 图标色按上游 info→#c9c9c9(暗#9ca3af)/其余→rgb(200,200,200)/plain→类型色；新增 `resolved(Background/Text/Border/Loading/Icon)ColorValue(isDark:)` 供单测 |
| 13 | `u-calendar` | `UPCalendar` | ✅ 已完成 | 属性/事件对齐 | 43 个 prop 与 confirm/close/closed 全覆盖，弹窗承载、多月网格、customList + formatter、maxRange/allowSameDay/rangeResultMode、monthSwitch 切月、enableTime 时分秒、showLunar 与 #footer 插槽已移植；滚动同步副标题不在原生范围 |
| 14 | `u-calendar-strip` | `UPCalendarStrip` | ✅ 已完成 | 属性/事件对齐 | 15 个 prop 与 change/confirm/monthChange/toggleFull 全覆盖，切月、下拉展开月历、今天标记已移植；`fullCalendarProps` 保留为兼容元数据 |
| 15 | `u-canvas` | `UPCanvas` | ✅ 已完成 | 属性/事件对齐 | 7 个 prop 与 ready/touchstart/touchmove/touchend 全覆盖，`bgColor`/`useRootHeightAndWidth`/`disableScroll` 已落地；`canvasId`/`unit` 保留为兼容元数据。本轮新增 `UPCanvasContext` 复刻上游那套 CanvasContext 方法（画笔状态、`save`/`restore` 状态栈、路径与矩形/弧/椭圆/文本落笔、`draw(isLastDraw)` 的替换与叠加、`clearCanvas` 的擦除加铺底），并补 `parseSize`/`getWidth`/`getHeight`/`toTempFilePath`；`estimateTextWidth` 逐字符照抄上游全角/空白/半角三档系数与那份全角字符集（含 `豈` 起点的笔误段），`measureText` 先用 `NSAttributedString` 实测、取不到再退回估算 |
| 16 | `u-car-keyboard` | `UPCarKeyboard` | 🔄 兼容增强中 | 属性/事件对齐 | 车牌键盘。未提交修复：省份/字母两组按键原先缺 `挂/港/澳/使/学` 与 `I/O` 且顺序与上游不符，现按 `areaList`/`engKeyBoardList` 逐项对齐（各 36 键）；补 `random`（含 `randomSource` 注入）与 `autoChange`（上游默认 `false`），另加 `changeInputMode()` 对应上游 `changeCarInputMode` 的中/英切换；`delete()` 不再把中间态强行拉回字母档。本轮补渲染层：按 `slice(0,10)/(10,20)/(20,30)/(30,36)` 切四行、第四行居中并挂「中/英」与退格两个 134rpx 功能键，按键 64rpx × 80rpx、底色取 `--up-bg-color`；长按退格上游是 250ms 定时器连删，原生只在长按满 0.25s 时多删一次 |
| 17 | `u-card` | `UPCard` | ✅ 已完成 | 高 | props、String/Number 单位、三类 named slot、index 和四类点击事件已覆盖 |
| 18 | `u-cascader` | `UPCascader` | ✅ 已完成 | 属性/事件对齐 | 12 个 props、`change`/`confirm`/`cancel` 三个事件与 `levelChange`/`emitChange`/`handleConfirm`/`toFatherIndex` 方法；层级推进与截断、`genTabsList` 占位规则、`setDefaultValue` 逐级回显均可单测；渲染改用 `UPPopup` + `UPTabs`/`UPSteps` + `UPCell`；照抄「确认路径也走 close() 因此会补抛 cancel」的反直觉行为 |
| 19 | `u-cate-tab` | `UPCateTab` | ✅ 已完成 | 属性/事件对齐 | 6 个 prop 与 `update:current` 全覆盖，左右分栏、follow 滚动联动、tab 单组模式、tabKeyName/itemKeyName 与四个作用域插槽已移植 |
| 20 | `u-cell` | `UPCell` | ✅ 已完成 | 高 | props、name payload、事件和插槽已覆盖 |
| 21 | `u-cell-group` | `UPCellGroup` | ✅ 已完成 | 高 | 分组样式和内容容器已覆盖 |
| 22 | `u-checkbox` | `UPCheckbox` | ✅ 已完成 | 高 | name/value、String/Number/Bool、事件及图标/标签插槽已覆盖 |
| 23 | `u-checkbox-group` | `UPCheckboxGroup` | ✅ 已完成 | 高 | Binding、change payload、父子配置继承已覆盖 |
| 24 | `u-choose` | `UPChoose` | ✅ 已完成 | 属性/事件对齐 | 10 个 props、`custom-click`（负载是下标）与默认作用域插槽；标签走 `UPTag`（激活 primary 实心 / 其余 info 描边），`wrap` 决定折行或横向滚动；保留上游「按下标而非按值」语义，同时提供 `currentIndex` 下标绑定与仓库既有按值绑定；上游 `type`/`valueName` 从未被读取，同样只保留参数 |
| 25 | `u-circle-progress` | `UPCircleProgress` | ✅ 已完成 | 高 | `percentage`、范围约束、shared mixin 样式和原生进度环已覆盖 |
| 26 | `u-city-locate` | `UPCityLocate` | 🔄 兼容增强中 | 属性/事件对齐 | 未提交增强：补齐 5 个 prop（`indexList`/`cityList`/`locationType`/`currentCity`/`nameKey`）与 `location-success`/`select-city` 两事件，整页用 `UPIndexList` 承载；定位拆成 `UPLocationProvider` + `UPCityGeocoder` 两个可注入协议，`locationType` 保留取值 |
| 27 | `u-code` | `UPCode` | ✅ 已完成 | 高 | 倒计时状态、事件和控制接口已覆盖 |
| 28 | `u-code-input` | `UPCodeInput` | ✅ 已完成 | 高 | String/Number props、输入状态、事件已覆盖 |
| 29 | `u-col` | `UPCol` | ✅ 已完成 | 高 | 与 `UPRow` 配套的 span/offset 布局已覆盖 |
| 30 | `u-collapse` | `UPCollapse` | ✅ 已完成 | 高 | scalar/array value、accordion、change/open/close 已覆盖 |
| 31 | `u-collapse-item` | `UPCollapseItem` | ✅ 已完成 | 高 | disabled、name、标题/图标/内容等 named slots 已覆盖 |
| 32 | `u-color-picker` | `UPColorPicker` | ✅ 已完成 | 属性/事件对齐 | 2 个 prop 与 confirm/close/closed 全覆盖，自绘取色面板（饱和度方块、色相与透明度轨、常用色板、渐变节点与方向）已移植；`UPColorMath` 复刻上游 HSL↔RGB 与 `linear-gradient` 串 |
| 33 | `u-column-notice` | `UPColumnNotice` | ✅ 已完成 | 中高 | 上游 props（icon/mode/color/bgColor/fontSize/speed/step/duration/disableTouch/justifyContent）与 click/close 已覆盖；duration 默认 1500 与 notice-bar 的 2000 区分；旧 `notices:`/`interval:` 初始化器保留（`58e44d0`） |
| 34 | `u-copy` | `UPCopy` | ✅ 已完成 | 高 | 原生剪贴板、props、默认/自定义 slot、success 及空内容/失败行为已覆盖 |
| 35 | `u-count-down` | `UPCountDown` | ✅ 已完成 | 高 | 时间输入、格式化、change/finish payload 与控制接口已覆盖 |
| 36 | `u-count-to` | `UPCountTo` | ✅ 已完成 | 高 | 数字动画、格式化和事件已覆盖 |
| 37 | `u-coupon` | `UPCoupon` | ✅ 已完成 | 属性/事件对齐 | 15 个 props、`click` 事件与全部 8 个插槽；三段式券面按上游字号复刻，`shape` 的 coupon 缺口 / envelope 斜纹 / card 圆角、`size` 三档高度与 `dotCount`、`type` 四个渐变主题（含虚线与标签配色联动）均已落地；照抄「无 type 时金额写死红色」与「action 标签 shape 三元两边相同、circle 不影响外观」两处反直觉；旧 `claim` API 保留 |
| 38 | `u-cropper` | `UPCropper` | ✅ 已完成 | 属性/事件对齐 | 15 个 prop 与 avtinit/confirm/cancel 全覆盖，裁剪框拖动与缩放、旋转、预览态、inner 按钮布局、`chooseImage` 参数透传已移植；相册选图由宿主接 PhotosPicker |
| 39 | `u-datetime-picker` | `UPDatetimePicker` | 🔄 兼容增强中 | 中高 | Int64 时间戳与 String time/timesecond Binding、范围夹取、结构化 payload、受控 show、关闭生命周期、原生双向 DatePicker 及 named slots 已覆盖；列级 formatter/filter 与原生滚动时序采用适配语义（`b345e9f`）。未提交修复：`confirmText` 默认值按上游 `up.common.confirm` 改为「确定」（原为「确认」） |
| 40 | `u-divider` | `UPDivider` | ✅ 已完成 | 高 | 方向、文字、虚线和尺寸 props 已覆盖 |
| 41 | `u-dragsort` | `UPDragsort` | ✅ 已完成 | 属性/事件对齐 | 5 个 prop 与 `drag-end` 全覆盖，vertical/horizontal/all 三向拖拽、逐项锁定、handler 插槽与震动反馈已移植；逐帧跟手动画不在原生范围 |
| 42 | `u-dropdown` | `UPDropdown` | ✅ 已完成 | 属性/事件对齐 | 11 个 props、`open`/`close` 事件与 `highlight()`；标题栏取色顺序、箭头 180° 旋转、下滑面板与半透明遮罩（高度 = 窗口高度 − 标题栏底部）已复刻；照抄 `current` 哨兵值 99999 与「未激活箭头取 menuDisabledColor」两处反直觉 |
| 43 | `u-dropdown-item` | `UPDropdownItem` | ✅ 已完成 | 属性/事件对齐 | 6 个 props、`change` 事件与默认插槽；内建 cell 列表按上游给选中项换色并补 `checkbox-mark` 对勾，`height: 'auto'` 走内容自适应 |
| 44 | `u-empty` | `UPEmpty` | ✅ 已完成 | 高 | mode 文案/icon 映射、图片 icon、默认 slot、String/Number 单位和 show 已覆盖 |
| 45 | `u-float-button` | `UPFloatButton` | ✅ 已完成 | 属性/事件对齐 | 悬浮按钮、展开菜单和 item-click |
| 46 | `u-form` | `UPForm` | ✅ 已完成 | 中高 | 表单模型、规则校验、错误类型与上下文已覆盖；`resetFields`/`resetField` 的 originalModel 快照、`setRules`、`validate(showErrorMsg:)` 已补齐；`errorType` 的 border-bottom 已渲染，toast 由 `toastMessage` 交宿主 `UPToastCenter` 呈现（`7cec530`） |
| 47 | `u-form-item` | `UPFormItem` | ✅ 已完成 | 中高 | 布局、错误状态、props 与插槽已覆盖；label/error 命名插槽、border-bottom 错误下划线已补齐（`7cec530`） |
| 48 | `u-gap` | `UPGap` | ✅ 已完成 | 属性/事件对齐 | 4 个 prop 已对齐：`height`/`marginTop`/`marginBottom` 收 `String | Number` 走 `UPUnit.parse`，`bgColor` 空/`transparent` 时按 `gapStyle` 回落 `--up-gap-bg-color`（亮 transparent / 暗 `#111111`），并补 mixin `customStyle`（末尾 `upStyle` 叠加）；新增 `resolvedBackgroundValue(isDark:)` 固定主题回落 |
| 49 | `u-goods-sku` | `UPGoodsSku` | ✅ 已完成 | 属性/事件对齐 | 7 个 prop 与 open/confirm/close/closed 全覆盖，弹窗形态、`skuTree`/`skuList`/`goodsInfo` 强类型模型、price/stock/maxBuyNum/canBuy/selectedSkuText 派生值与 trigger/header 插槽已移植 |
| 50 | `u-grid` | `UPGrid` | ✅ 已完成 | 高 | col、border、align、gap、click 上下文已覆盖 |
| 51 | `u-grid-item` | `UPGridItem` | ✅ 已完成 | 高 | name/index payload、item click 和插槽已覆盖 |
| 52 | `u-guide` | `UPGuide` | 🔄 兼容增强中 | 高 | 全屏引导页。未提交增强：`UPConfig.guide` 补齐 `guide.js` 全部 13 个默认值；11 个 prop 全落地（`show` 支持 Binding 双向绑定、`list`/`storageKey`/`once`/`showSkip`/`skipText`/`nextText`/`finishText`/`indicator`/`bgColor`/`zIndex`，`zIndex` 走 `String \| Number` 解析）；`UPGuideStep` 补 `image`/`desc`/`backgroundColor`（背景按 `item.backgroundColor \|\| bgColor` 回落、`desc` 空则回落既有 `message`）；补 `bootstrap()`（空 list 不显示、`once` 已记忆则拦下并回抛 `update:show=false`）、`skip()`/`open()`/`close(remember:)`（`closing` 同 tick 去重）/`reset()`/`readRemembered()`/`writeRemembered()`（写数字 `1`，认 `true`/`1`/`"1"`）与 `resolvedStorageKey` 空串回落；补 `skip`/`close`/`update:show` 三个 emit；记忆落在注入式 `UserDefaults`。上游 swiper 横向滑动手势未原生化，翻页用主按钮或 `select(_:)`/`previous()` |
| 53 | `u-icon` | `UPIcon` | ✅ 已完成 | 属性/事件对齐 | 17 个 props 加 `customStyle`、`click` 事件（负载是 `index`）；字形与图片两条分支、四向 `labelPos`、`space` 间距与 `top` 垂直微调都已落地；`label` 的可见性照抄上游 `v-if="label !== ''"` 的严格判定（传 `"0"` 也显示）；`hoverClass`/`stop` 是 uni-app 的按下态与冒泡控制，SwiftUI 无对应开关，仅保留取值 |
| 54 | `u-image` | `UPImage` | ✅ 已完成 | 高 | 原生 AsyncImage、loading/error slot、尺寸/圆角、占位显示和 click/load/error 已覆盖 |
| 55 | `u-index-anchor` | `UPIndexAnchor` | 🔄 兼容增强中 | 基线可用 | 与索引列表配套。未提交增强：补上游 5 个 prop `text`/`color`/`size`/`bgColor`/`height`（默认 `#606266`/14/`#f1f1f1`/32），`displayIndex` 按上游 `{{ text.name \|\| text }}` 优先取 `text`、空串回落到锚点标识，`size`/`height` 走 `UPUnit.parse` 支持带单位字符串 |
| 56 | `u-index-item` | `UPIndexItem` | ✅ 已完成 | 基线可用 | 与索引列表配套 |
| 57 | `u-index-list` | `UPIndexList` | 🔄 兼容增强中 | 基线可用 | 索引定位和滚动联动。未提交增强：补齐上游 4 个 prop `customNavHeight`（`String \| Number`，走 `UPUnit.parse`）/`itemMargin`（默认 `0rpx`，映射为 `LazyVStack` 间距）/`safeBottomFix`/`indexList`（原 `anchors` 更名为上游 prop 名，`anchors` 保留为上游 `uIndexList` 计算属性：空数组时回落内部生成的 A-Z 26 字母），`activeColor` 默认值按 `indexList.js` 由 `#3c9cff` 改为 `#5677fc`；新增 `resolvedActiveColor`/`resolvedInactiveColor` 照抄上游主题哨兵（命中默认值改取 `primary`/`content`）、`scrollActiveIndex(scrollTop:itemHeights:headerHeight:current:)` 与 `letterIndex(forOffsetY:)` 移植 `scrollHandler`/`getIndexListLetter`；字母栏按上游样式重写（30pt 宽、16×16 圆点、12pt 字号、激活项圆底白字）并补拖动放大指示器（50×50、旋转 -45°、28pt bold、松手 300ms 隐藏）。上游 `safeBottomFix` 唯一使用处 `pageY = pageY + 34` 已被注释，故不参与触点映射，原生改为列表末尾追加 `UPSafeBottom` |
| 58 | `u-input` | `UPInput` | ✅ 已完成 | 属性/事件对齐 | 原生 TextField、props、事件、插槽已覆盖；String/Number fontSize、prefix/suffix 插槽、带值 focus/blur 已补齐。本轮对齐上游 `wrapperStyle`/`inputBorderColor`/`inputStyle`：disabled 背景取 `disabledColor` 或回落 bgColor(#f3f4f6)（此前无 disabledColor 时不上底色）、边框色亮 #dadbde/暗 rgba(255,255,255,0.08) 且 0.5px、文字色取 color 或 mainColor(#303133) 且不随 disabled 变灰；新增 `resolvedDisabledBackgroundValue`/`resolvedBorderColorValue(isDark:)`/`resolvedTextColorValue` 供单测 |
| 59 | `u-keyboard` | `UPKeyboard` | 🔄 兼容增强中 | 高 | 自定义键盘容器。未提交增强：`UPConfig.keyboard` 补齐 `keyboard.js` 全部 16 个默认值，16 个 prop 全落地——工具条 7 个 `tooltip`/`showTips`/`tips`/`showCancel`/`showConfirm`/`cancelText`/`confirmText`（后两者按上游 i18n 为「取消」「确定」）与转发 3 个 `dotDisabled`/`random`/`autoChange`；新增 `resolvedTips` 照抄上游兜底表达式（number→数字键盘、card→身份证键盘、其余→车牌号键盘）、`usesNumberKeyboard`（`mode == 'number' \|\| 'card'` 分支）、`resolvedKeys`（未传 `keys` 时按 mode 自动构建：number/card 走 `UPNumberKeyboard.keyValues`，其余走 `UPCarKeyboard.provinces`/`letters`，`random` 打乱三套网格）、`carStage`/`changeInputMode()`（上游 `changeCarInputMode`）、`columnCount`（数字 3 列、车牌 10 列）、`showsBackspaceKey`/`showsInputModeToggle`（对应上游 `v-for` 之外的独立单元格）与 `panelBackgroundColorName(dark:)`（照抄 `popupStyle`，暗色 `#2c2c2e`、浅色 `rgb(214,218,220)`）；补齐 6 个 emit `change`/`backspace`/`confirm`/`cancel`/`close`/`closed`（后两者是 popup 容器事件，禁用时照旧转发）。`UPNumberKeyboard`/`UPCarKeyboard` 内联时传 `tooltip: false`、`safeAreaInsetBottom: false`，因为工具条与安全区留白属于外层 `u-keyboard`。上游退格键长按连发（250ms 定时器）与 popup 上滑动画未原生化，后者由 `UPPopup` 负责 |
| 60 | `u-lazy-load` | `UPLazyLoad` | ✅ 已完成 | 属性/事件对齐 | SwiftUI 原生按需渲染语义不同 |
| 61 | `u-line` | `UPLine` | ✅ 已完成 | 属性/事件对齐 | 6 个 prop 已对齐：`length`/`margin` 收 `String | Number`，`margin` 按 CSS 简写 1/2/3/4 值展开为 `EdgeInsets`（新增 `marginInsets(_:)`），补 mixin `customStyle`（末尾 `upStyle` 叠加）；方向/虚线/hairline(0.5) 与百分比长度维持既有实现 |
| 62 | `u-line-progress` | `UPLineProgress` | ✅ 已完成 | 高 | props、范围约束、方向、文本和默认插槽已覆盖 |
| 63 | `u-link` | `UPLink` | ✅ 已完成 | 高 | props、click/open 行为和 URL 兼容已覆盖 |
| 64 | `u-list` | `UPList` | ✅ 已完成 | 属性/事件对齐 | 19 个 prop 与 scroll/scrolltolower/scrolltoupper/refresher* 全覆盖，阈值判定、scrollIntoView、分页与禁止滚动已移植；nvue/微信专属项与 refresher 样式只保留取值 |
| 65 | `u-list-item` | `UPListItem` | ✅ 已完成 | 属性对齐 | `anchor` 收 String\|Number 并落成 `.id(_:)`，配合 `scrollIntoView` 滚动 |
| 66 | `u-loading-icon` | `UPLoadingIcon` | ✅ 已完成 | 属性/事件对齐 | 11 个 props 加 `customStyle`；spinner 模式按上游铺 12 个点（逐个转 30°、透明度 `1 - 0.0625 * (i - 1)`、点内 2px × 25% 小竖条），circle 四边描边、暗边由 `otherBorderColor` 决定（`inactiveColor` 优先，否则 `colorGradient(color, '#ffffff', 100)[80]`，逐通道 `Math.round`），semicircle 只画四分之一弧；旋转周期照抄上游——spinner 固定 `1s linear`，只有 circle/semicircle 才用 `duration` + `timingFunction`；文字间距按 `margin-left: 4px` 与竖排 `margin: 6px 0 0` 区分 |
| 67 | `u-loading-page` | `UPLoadingPage` | ✅ 已完成 | 高 | 全屏 overlay、模式、图片、默认插槽和配置已覆盖 |
| 68 | `u-loadmore` | `UPLoadmore` | ✅ 已完成 | 高 | status、图标、文字、尺寸和 click 已覆盖 |
| 69 | `u-markdown` | `UPMarkdown` | ✅ 已完成 | 属性/事件对齐 | 6 个 prop 与 load/ready/imgtap/linktap/play/error 全覆盖；`UPMarkdownParser` 顶替 marked 做 Markdown→HTML（含 GFM 表格与围栏代码块），渲染交给 `UPParse`，`theme` 落成容器配色 |
| 70 | `u-message-input` | `UPMessageInput` | ✅ 已完成 | 中高 | 上游全部 props、box/middleLine/bottomLine 三种 mode、breathe 动画、change/finish 已覆盖；按上游 `getVal` 语义实现"超长输入不派发事件、外部赋值截断"；已改为可观测 controller 并补透明 TextField 承接键盘（`fad47ec`）；上游 `focus` prop 因与既有 `focus()` 方法同名而存储为 `autoFocus`，`focus:` 初始化标签不变 |
| 71 | `u-modal` | `UPModal` | 🔄 兼容增强中 | 中高 | 基于原生弹层；String/Number 偏移、宽度和动画时长、同步/异步确认顺序、异步取消、named slots 及 `confirmButtonShape` 取消按钮抑制已覆盖。未提交修复：`UPConfig.modal.confirmText` 按上游 `up.common.confirm` 改为「确定」（原为「确认」） |
| 72 | `u-navbar` | `UPNavbar` | ✅ 已完成 | 属性/事件对齐 | 18 个 props、`leftClick`/`rightClick` 与 `left`/`center`/`right` 三插槽已对齐；颜色回落照抄上游 `navbarBgColor`（暗 `#1c1c1e` / 亮 `#ffffff`）、`navbarTitleColor`/`navbarLeftIconColor`（mainColor `#303133`）与恒为 mainColor 的 `navbarRightColor`；`statusBarBgColor` 空回落 `bgColor`；右区仅在 `$slots.right || rightIcon || rightText` 时渲染、右图标写死 `20px`；`safeAreaInsetTop` 走 `UPStatusBar`、`fixed && placeholder` 补占位块；`leftClick` 无拦截器时按 `autoBack` 触发 `onNavigateBack`（页面栈归宿主） |
| 73 | `u-navbar-mini` | `UPNavbarMini` | ✅ 已完成 | 属性/事件对齐 | 9 个 props、`leftClick`/`homeClick` 两个事件、`left`/`center` 两个插槽与竖分割线已对齐；`navigateBack`/`reLaunch` 的页面栈跳转归宿主，`autoBack`/`homeUrl` 只保留参数 |
| 74 | `u-no-network` | `UPNoNetwork` | 🔄 兼容增强中 | 属性/事件对齐 | 已提供可注入网络状态模型和 Network.framework 适配。未提交修复：新增上游 `tips` prop（默认 `up.noNetwork.text` = 「哎呀，网络信号丢失」），离线态不再渲染硬编码英文 `No Network`；补齐 `image`（自定义断网图，固定 `size=150`/`imgMode=widthFit`）与 `zIndex`（`String \| Number`，空串回落 `u-overlay` 的 10070）；补齐 `connected`/`disconnected`/`retry` 三个事件与「请检查网络，或前往 设置」+ mini plain 重试按钮，`emitEvent` 照抄上游按 `'none'` 二分（`unknown` 也算已连接） |
| 75 | `u-notice-bar` | `UPNoticeBar` | ✅ 已完成 | 中高 | 13 个上游 props、`text` 的 Array/String 双类型、带索引 click、close 已覆盖；关闭图标改由 `mode == "closable"` 驱动（上游无 closable prop）；`resolvedVariant` 公开 direction/step 的 column/row 委派选择；无参 onClick 旧拼写保留（`58e44d0`） |
| 76 | `u-notify` | `UPNotify` | 🔄 兼容增强中 | 高 | 顶部通知及命令式 API；未提交增强：补 `top`、`color`、`bgColor`、`fontSize`、`safeAreaInsetTop`，`duration` 默认值按 `notify.js` 由 2500 改为 3000，底色按 `.u-notify--{type}` 主题类回落、`bgColor` 非空才覆盖，图标名与 `1.3 × fontSize` 尺寸照抄 `icon` 计算属性，层级固定 10076 |
| 77 | `u-number-box` | `UPNumberBox` | ✅ 已完成 | 高 | 数值模型、步进、范围、格式和事件已覆盖 |
| 78 | `u-number-keyboard` | `UPNumberKeyboard` | 🔄 兼容增强中 | 属性/事件对齐 | 数字键盘和 random/dot 模式。未提交修复：按键集原先恒为 `1-9`，打不出 `0`、`.`（number 模式）与 `X`（card 模式），现由 `keyValues(mode:dotDisabled:)` 照抄上游 `numList` 三分支（`dotDisabled` 分支只在 number 模式生效，故 card 模式恒带 `X`）；`random` 原先因默认 `randomSource` 返回有序表而空转，现默认真正 `shuffled()` 并对整表洗牌。本轮补渲染层：三列网格、按键 222rpx × 90rpx，`btnBgGray` 与 `itemStyle` 两条变形规则照抄（其中拉宽判定未排除乱序），退格键恒灰底 |
| 79 | `u-overlay` | `UPOverlay` | ✅ 已完成 | 属性/事件对齐 | 4 个 props 加 `customStyle` 与 `click` 事件；`zIndex`/`duration`/`opacity` 收 `String \| Number`（`opacity` 单独解析以保小数精度），默认插槽渲染在遮罩之上，`customStyle` 照上游 `deepMerge` 顺序叠在内建样式之后；隐藏时整层淡出并关掉命中测试 |
| 80 | `u-pagination` | `UPPagination` | ✅ 已完成 | 属性/事件对齐 | 10 个 props 与 `update:currentPage`/`update:pageSize`/`current-change`/`size-change` 四个事件；`layout` 的 total/prev/pager/next/sizes 五个关键字全部渲染，按钮与页码样式按上游 CSS 复刻（激活项 `#409eff` 底色白字、空文案回落 arrow-left/right 图标），`displayedPages` 三分支折叠与 `pageSizeIndex`/`pageSizeLabel` 的回落规则可单测；上游 `jumper` 关键字对应的模板整体被注释，不建模 |
| 81 | `u-parse` | `UPParse` | ✅ 已完成 | 属性/事件对齐 | 15 个 prop 与 load/ready/imgtap/linktap/play/error 全覆盖，`parser.js` 词法与节点树完整移植；预览图层、rowspan、svg 由宿主负责 |
| 82 | `u-pdf-reader` | `UPPDFReader` | 🔄 兼容增强中 | 基线可用 | 已提供 PDFKit 条件适配和页码事件基线。未提交增强：补上游 3 个 prop `src`/`height`（默认 `500px`）/`baseUrl`（默认 `https://uview-plus.jiangruyi.com/h5`），新增 `viewerURL` 按上游 `mounted` 公式拼 pdf.js 地址并复刻 `encodeURIComponent` 的保留字符集、空 `baseUrl` 回落内置域名；原生渲染仍走 `documentData`，`src`/`viewerURL` 只作元数据 |
| 83 | `u-picker` | `UPPicker` | 🔄 兼容增强中 | 中高 | String/Number/Bool props、受控 show、defaultIndex/最近确认值回滚、上游 payload aliases、关闭生命周期、UPToolbar 及 named slots 已覆盖（`b345e9f`）。未提交修复：`confirmText` 默认值按上游 `up.common.confirm` 改为「确定」（原为「确认」） |
| 84 | `u-picker-column` | `UPPickerColumn` | ✅ 已完成 | 中高 | 原生 wheel Binding、索引夹取及非负 itemHeight 已覆盖（`b345e9f`） |
| 85 | `u-picker-data` | `UPPickerData` | ✅ 已完成 | 属性对齐 | text/value/id 数据模型与 Picker 结构化事件 payload 外，补齐 `valueKey`/`labelKey`（`options(_:valueKey:labelKey:)` 与 `defaultIndex(for:in:)`） |
| 86 | `u-popover` | `UPPopover` | 🔄 兼容增强中 | 中高 | 未提交增强：补齐上游 10 个 prop（`text`/`color`/`bgColor`/`popupBgColor`/`placement`/`triggerMode`/`show`/`zIndex`/`forcePosition`/`direction`，`text`/`zIndex` 收 String\|Number）、新增 `UPConfig.popover` 默认值；内联 `u-tooltip` 语义：`click`/`longpress` 分别只由点击/长按开启（`hover` 无处理器）、`manual` 才响应 `show` 变化、`open()`/`close()` 幂等 guard、`forcePosition` 覆盖方向偏移、四方向 14pt 旋转指示器与外部点击关闭；`placement` 与上游一致只作记录（`u-tooltip` 未声明该 prop）。屏幕边沿重定位与 singleton 互斥不在原生范围 |
| 87 | `u-popup` | `UPPopup` | ✅ 已完成 | 属性/事件对齐 | 多方向原生 popup；String/Number 动画/层级/圆角/透明度、外部关闭补发 close、去重及 closed 生命周期已覆盖。本轮对齐上游按 mode 的圆角规则：bottom→上两角、top→下两角、left→右两角、right→左两角、center→四角（此前四角统一圆化），新增 `UPRectCorner.forPopup(mode:)` 与自绘 `UPPopupRoundedCorners` 形状；DOM 手势采用 SwiftUI 原生语义 |
| 88 | `u-poster` | `UPPoster` | ✅ 已完成 | 属性/方法对齐 | `json` prop 与 `exportImage()` 全覆盖：text/image/qrcode/view 四种图层、渐变背景、圆角、lineClamp 与 rpx 折算已移植，导出走 `ImageRenderer` 写临时 PNG |
| 89 | `u-pull-refresh` | `UPPullRefresh` | ✅ 已完成 | 属性/事件对齐 | 可组合 SwiftUI refreshable，需保持状态接口 |
| 90 | `u-qrcode` | `UPQRCode` | ✅ 已完成 | 属性/事件对齐 | 19 个 props、`result`/`preview`/`longpressCallback` 三个事件与 `makeCode`/`clearCode`/`toTempFilePath`/`saveCode` 四个方法；矩阵取自 Core Image（`lv` → `inputCorrectionLevel`），再用 SwiftUI `Canvas` 按上游规则逐格重绘，`background`/`foreground`/`pdground`/`quietZone`/`icon` 均可用；`getForeGround` 的开区间判定照抄，`cid` 仅作标识 |
| 91 | `u-radio` | `UPRadio` | ✅ 已完成 | 高 | value/name、String/Number/Bool、事件和插槽已覆盖 |
| 92 | `u-radio-group` | `UPRadioGroup` | ✅ 已完成 | 高 | Binding、change payload 和父子配置继承已覆盖 |
| 93 | `u-rate` | `UPRate` | ✅ 已完成 | 高 | props、半星、手势、change payload 已覆盖 |
| 94 | `u-read-more` | `UPReadMore` | 🔄 兼容增强中 | 基线可用 | 内容测量、展开/收起事件。未提交修复：新增上游 `closeText`/`openText` prop 与 `toggleText`，默认值按 `up.readMore.expand`/`up.readMore.fold` 为「展开阅读全文」/「收起」（原折叠态硬编码「展开」）；补齐剩余 6 个 prop（`showHeight`/`toggle`/`color`/`fontSize`/`shadowStyle`/`textIndent`/`name`）、`arrow-down`/`arrow-up` 箭头图标（尺寸 `fontSize + 2`）、折叠态渐变遮罩与上游 `@open`/`@close`（回传 `name`）事件；`toggle()` 更名为 `toggleReadMore()` 对齐上游方法名 |
| 95 | `u-refresh-virtual-list` | `UPRefreshVirtualList` | ✅ 已完成 | 属性/事件对齐 | 5 个列表 prop 透传 `UPVirtualList`，refresh/scroll 两事件与 finishRefresh/scrollTo/scrollToTop 三方法已覆盖（`threshold` 沿用上游写死的 50） |
| 96 | `u-row` | `UPRow` | ✅ 已完成 | 高 | gutter、justify、align、click 和布局上下文已覆盖 |
| 97 | `u-row-notice` | `UPRowNotice` | ✅ 已完成 | 中高 | 上游 props（icon/mode/color/bgColor/fontSize/speed）与 click/change/close 已覆盖；旧 `notices:` 初始化器保留（`58e44d0`） |
| 98 | `u-safe-bottom` | `UPSafeBottom` | ✅ 已完成 | 基线可用 | 可映射 safeAreaInset |
| 99 | `u-scroll-list` | `UPScrollList` | ✅ 已完成 | 属性/事件对齐 | 6 个 props 与 `left`/`right` 事件；滑块位移照抄 `barStyle` 的比例公式，内容宽与容器宽改由内部 `GeometryReader` 量（对应上游 `scrollWidth` 与 `getComponentWidth()`）；照抄 `scrolltolower` 把「指示器坐标系」的值塞进 `scrollLeft` 的反直觉行为 |
| 100 | `u-search` | `UPSearch` | ✅ 已完成 | 高 | Binding、clear/search/custom 事件、左右插槽和配置已覆盖 |
| 101 | `u-section` | `UPSection` | ✅ 已完成 | 基线可用 | 当前上游目录仅保留配置，无独立 Vue 实现 |
| 102 | `u-select` | `UPSelect` | ✅ 已完成 | 属性/事件对齐 | 18 个 prop 与 `update:current`/`select` 全覆盖，触发行、透明遮罩、绝对定位下拉面板与 text/icon/optionItem 插槽已移植；超屏左右翻转不在原生范围 |
| 103 | `u-short-video` | `UPShortVideo` / `UPShortVideoFeed` | ✅ 已完成 | 属性/事件对齐 | 新增 `UPShortVideoFeed` 覆盖上游整屏形态：4 个 prop 与 tabChange/videoChange/like/comment/share/collect/progress*/videoPlay/videoPause 十个事件、menu/search/actions/tabbar 四插槽、倍速写回 `playbackRate`；单条播放器仍是 `UPShortVideo` |
| 104 | `u-signature` | `UPSignature` | ✅ 已完成 | 属性/事件对齐 | 6 个 prop 与 clear/confirm/error 全覆盖，画板收笔、工具栏（撤销/清空/笔画/色板/导出）与 PNG 导出已移植；每笔记录当时的颜色与粗细 |
| 105 | `u-skeleton` | `UPSkeleton` | ✅ 已完成 | 高 | rows/title/avatar、尺寸数组、loading 插槽已覆盖 |
| 106 | `u-slider` | `UPSlider` | ✅ 已完成 | 属性/事件对齐 | 17 个 props、`start`/`changing`/`change`（区间另有 rangeChanging/rangeChange）；本轮补自绘渲染：`__base`/`__gap`/`__button` 三层按上游配色与尺寸复刻（填充段 0.2s 过渡、滑块 scale 0.9 + 浅阴影、`blockStyle` 可覆盖），`sizeLocal`（height 优先 size）、`sliderLength` 占比、`touchButtonStyle` 半个 blockSize 偏移与 `onTouchMove` 的距离换算均可单测；`useNative` 且非区间时退回 SwiftUI `Slider`；上游 `onTouchStart2`/`onTouchMove2`/`onTouchEnd2` 方法体全被注释，不建模 |
| 107 | `u-status-bar` | `UPStatusBar` | ✅ 已完成 | 属性/事件对齐 | `bgColor`/`height` 两 prop、`update:height`（`onUpdateHeight`/`reportHeight`）、mixin `customStyle` 与默认插槽已对齐；高度取平台 statusBarHeight（缺失回落 safe-area top）。本轮修复核心 `UPColor.parse`：`transparent`/`none` → 全透明、`rgb()`/`rgba()`（含 `.5`/百分比 alpha）正确解析，此前会误落内容灰色，连带修好 `UPNavbarMini`(`rgba(0,0,0,.15)`)、`UPToast`(`rgb(255,255,255)`) 等背景 |
| 108 | `u-steps` | `UPSteps` | ✅ 已完成 | 属性/事件对齐 | 7 个 props；`statusClass`/`statusColor`/`lineStyle` 三个推导均可单测；父子通信由 `getParentData` 换成 Environment 下发 + PreferenceKey 回报；照抄「非当前项自身 error 一律算 error」与「连线颜色看下一个兄弟的 error」两处反直觉 |
| 109 | `u-steps-item` | `UPStepsItem` | ✅ 已完成 | 属性/事件对齐 | 5 个 props 与 `icon`/`title`/`desc`/`content` 四个插槽；序号圈四态（process 实心白字 / wait 灰字 / finish 对勾 / error 叉）、dot 圆点、图标模式与连接线按上游 CSS 尺寸复刻；`onClick` 是原生扩展（上游只给标题加了 `cursor: pointer`） |
| 110 | `u-sticky` | `UPSticky` | ✅ 已完成 | 属性/事件对齐 | 6 个 props 加 `customStyle`；`stickyTop = offsetTop + customNavHeight`、`setFixed(top)` 的阈值判定、`uZindex` 回落 970、js 模式下记录内容宽高防塌陷均已复刻；上游文档写了 `fixed`/`unfixed` 事件但 `.vue` 里从未 `$emit`，`onFixed` 是原生扩展 |
| 111 | `u-subsection` | `UPSubsection` | ✅ 已完成 | 属性/事件对齐 | current Binding/非受控、禁用/去重、结构化 change payload 已覆盖。本轮对齐上游 `resolved*` 主题色：`resolvedInactiveColor`(暗#d1d5db)、`resolvedButtonBgColor`(暗#2b2c30)、`resolvedButtonBarColor`(常#ffffff/暗#3a3b40、禁用#f5f5f5/暗#3a3a3c)、`resolvedDisabledText`(#c8c9cc/暗#6b7280)、`resolvedDisabledBorder`(#d4d4d4/暗#3a3a3c)；`textStyle` 语义：subsection 激活文字白、button 激活取 activeColor，未激活 resolvedInactive，item 级 `activeColorKey`/`inactiveColorKey` 覆盖优先；渲染改为 button 白滑块 / subsection activeColor 描边填充；新增 `resolved*Value(isDark:)` 与 `textColorValue(index:isDark:)` 供单测，并补对象数组非受控 `current: Int` 初始化器 |
| 112 | `u-swipe-action` | `UPSwipeAction` | 🔄 兼容增强中 | 高 | 与 swipe-action-item 配套及互斥状态。未提交增强：`UPSwipeActionGroup` 补上游 `autoClose` 与 `opendItem` 两个 prop，`closeOther(_:)` 只在 `autoClose` 为真时收起同级、`closeAll()` 无条件全关、`updateOpendItem(_:)` 照抄 watch 只对 `false` 生效；`onOpendItemUpdate` 对应上游拼写反常的 `opendItem:update` emit（值恒为 `true`）；`openedIDs` 允许 `autoClose` 关闭时并存多行 |
| 113 | `u-swipe-action-item` | `UPSwipeActionItem` | 🔄 兼容增强中 | 属性/事件对齐 | 侧滑菜单、阈值和事件 payload。未提交增强：补齐上游 9 个 prop（新增 `name`/`autoClose`/`scrolling`/`options`/`duration`，`options` 为 `actions` 的上游别名），`threshold` 默认值按 `swipeActionItem.js` 由 50 改为 20（`.vue` 注释里的 30 是过期文档）；`open()`/`trigger(_:)` 增加 `disabled` 短路，`trigger` 照抄 `buttonClickHandler` 先派发 `click`（payload 为 `index`/`name`）再在 `closeOnClick` 为真时收起；`setScrolling(_:)` 去重后同时派发 `update:scrolling` 与 `scrolling`，`close()` 照抄 `closeHandler` 先复位滑动状态；`resolvedDuration` 照抄 `getDuration` 的 30 阈值单位推断，但用 `Double` 解析以避免上游 `parseInt('0.3')` 得 0 的偏差。上游 `options` 默认值读的是 `swipeActionItem.js` 里不存在的 `rightOptions` 键（实际为 `undefined`），此 bug 不移植，按声明的 `[]` 处理。本轮补渲染与手势：按钮区绝对定位 + 内容层 `translateX` 左移 + 外层裁切，`item.style` 的 `backgroundColor`/`color`/`fontSize`/`borderRadius` 四键与 `icon`/`iconSize` 均已解析（默认底色 `#C7C6CD`、暗色回落 `#4b5563`，图标兜底 17 或 `fontSize × 1.2`），`borderRadius` 一设即改为只包内容且内边距归零；`touchstart`/`touchmove`/`touchend`/`touchcancel` 逐条照抄 `other.js`，`duration` 现在驱动动画；新增 `button` 插槽；照抄「展开态 `moveX == 0` 直接收起、`moveX < 0` 直接 return」两处反直觉 |
| 114 | `u-swiper` | `UPSwiper` | ✅ 已完成 | 属性/事件对齐 | 24 个 props、`click`/`change`/`update:current` 与 `default`/`indicator` 两个插槽；图片走 `UPImage`、视频走 `UPShortVideo`（poster 兜底），loading 渲染 circle 模式 loading-icon，标题横幅与内建指示器按上游条件显示；照抄「`type` 为真值即不再嗅探且只认 image/video」「标题只在图片项显示」「`displayMultipleItems` 空列表强制 0」三处反直觉；`vertical`/`acceleration`/`easingFunction` 是 uni-app swiper 能力，仅保留参数 |
| 115 | `u-swiper-indicator` | `UPSwiperIndicator` | ✅ 已完成 | 属性/事件对齐 | 5 个 props；`line` 底槽宽 `lineWidth * length` 且滑块按 `translateX(current * 22)` 平移（含 0.3s 过渡），`dot` 激活项宽 12pt，尺寸与间距按上游 CSS 复刻 |
| 116 | `u-switch` | `UPSwitch` | ✅ 已完成 | 高 | active/inactive value、loading/disabled、change 已覆盖 |
| 117 | `u-tabbar` | `UPTabbar` | ✅ 已完成 | 属性/事件对齐 | Binding/无控 value、结构化 change payload、安全区、与 tabbar-item 配套已覆盖。本轮对齐上游 tabbar-item `resolvedActiveColor`/`resolvedInactiveColor`（默认 #1989fa→primary #3c9cff、#7d7e80→content #606266）、`itemInlineStyle` 的 `activeBackgroundColor`/`inactiveBackgroundColor`（空→透明）、`textMode`（none 隐藏、active 非激活淡化）；图标改用 `UPIcon`（尺寸随 `iconScale`）；新增 `resolvedActiveColorValue`/`resolvedInactiveColorValue`/`itemBackgroundValue(active:)`/`showsText`/`isTextMuted(active:)` 供单测 |
| 118 | `u-tabbar-item` | `UPTabbarItem` | ✅ 已完成 | 中高 | tabbar 子项、badge、active/inactive icon、事件 payload |
| 119 | `u-table` | `UPTable` | ✅ 已完成 | 中高 | 7 个上游 props 与默认值已覆盖；改由 `UPTableStyleContext` 经 Environment 下发父表样式，替代上游 `$parent` 查找（`9db5229`） |
| 120 | `u-table2` | `UPTable2` | ✅ 已完成 | 属性/事件对齐 | 31 个 props、6 个真实事件载荷、排序三态轮转/multiSort/sortBy/sortMethod、filters 子串匹配、选择向下级联、树形展开与懒加载、左固定列与空数据已覆盖；本轮补齐 `context` 与 `rowStyle`/`cellStyle`/`cellClassName`/`headerCellClassName`/`rowClassName`/`spanMethod` 六个回调（className 类回调只算值、样式走 style）；上游 5 个死声明事件不建模、`declaredButNeverEmittedEventNames` 记录 |
| 121 | `u-tabs` | `UPTabs` | ✅ 已完成 | 属性/事件对齐 | String 列表/Int Binding、无控选中（`init(list:current:Int)` 已同步无控状态盒）、disabled/click/change、滚动指示器、与 tabs-item 配套已覆盖。本轮：指示条默认色对齐上游 `var(--up-primary,#3c9cff)`（新增 `resolvedLineColorValue()`），tab 图标改用 `UPIcon`(+iconStyle) 替代 SF Symbols |
| 122 | `u-tabs-item` | `UPTabsItem` | ✅ 已完成 | 中高 | name/badge/icon/disabled 元数据与父子选择上下文已覆盖 |
| 123 | `u-tag` | `UPTag` | ✅ 已完成 | 高 | props、click/close payload、图标及内容插槽已覆盖 |
| 124 | `u-td` | `UPTd` | ✅ 已完成 | 中高 | 先继承父表 align/padding/fontSize/color/borderColor，再由非空自身 props 覆盖；`width != "auto"` 才固定列宽；padding 无单元格级 prop 故始终继承（`9db5229`） |
| 125 | `u-text` | `UPText` | ✅ 已完成 | 高 | mode/formatter、String/Number 属性、图标、行数/样式、link/phone 元数据和 click 已覆盖 |
| 126 | `u-textarea` | `UPTextarea` | ✅ 已完成 | 属性/事件对齐 | 原生 TextEditor、props、count、formatter 已覆盖；String/Number height、带值 focus/blur 已补齐；非自增高改为固定高度+内部滚动。本轮对齐上游 `textareaStyle`/`textareaBorderColor`/`fieldStyle`：常态白底 #ffffff、disabled 灰底 #f5f7fa（此前无底色）、边框亮 #dadbde/暗 rgba(255,255,255,0.08) 且 0.5px、文字取 content(#606266) 且不随 disabled 变色；新增 `resolvedBackgroundValue`/`resolvedBorderColorValue(isDark:)`/`resolvedTextColorValue` 供单测 |
| 127 | `u-th` | `UPTh` | ✅ 已完成 | 中高 | 继承父表 align/padding/borderColor 与 thStyle 合并顺序已覆盖；`width` 非空才固定列宽（与 td 的 "auto" 判定不同）（`9db5229`） |
| 128 | `u-title` | `UPTitle` | ✅ 已完成 | 高 | 标题模式、颜色、尺寸和样式已覆盖 |
| 129 | `u-toast` | `UPToast` / `UPToastView` | ✅ 已完成 | 属性/事件对齐 | 声明式/命令式基线、`UPToastOptions`/`UPToastCenter`/`UPToast` 已提交；本轮把 `iconName` 对齐上游 `type2icon`（success→checkmark-circle、error→close-circle、warning→error-circle、primary→info-circle，info/loading/default 空串），新增 `resolvedIconName(icon:type:)` 复刻 `iconName` computed 三段判定（假值/"none"→空、"true"→按 type、具体名→原样）；`UPConfig.toast` 的 `icon`/`overlay` 默认改为上游 `true`；内容盒子重绘为上游布局：非 loading 横排（图标 color 绑 type、17px、间距 4）、loading 竖排（circle 模式白环 + `rgb(120,120,120)` 暗环、12px 间隙），底色 `#585858`、圆角 4、文字白色 15px、最大宽 200px |
| 130 | `u-toolbar` | `UPToolbar` | 🔄 兼容增强中 | 基线可用 | Picker 等组件共用的工具栏。未提交修复：`confirmText` 默认值按上游 `up.common.confirm` 改为「确定」（原为「确认」） |
| 131 | `u-tooltip` | `UPTooltip` | ✅ 已完成 | 属性/事件对齐 | 16 个 prop 与 open/close/click 全覆盖，复制按钮、扩展按钮组、singleton 互斥、四方向指示器与 forcePosition 已移植；贴边重定位不在原生范围 |
| 132 | `u-tr` | `UPTr` | ✅ 已完成 | 高 | 上游无 props 无逻辑，仅为 flex 行容器，已完全对应 |
| 133 | `u-transition` | `UPTransition` | ✅ 已完成 | 高 | mode、duration、timing、生命周期事件、click 和插槽已覆盖 |
| 134 | `u-tree` | `UPTree` | ✅ 已完成 | 属性/事件对齐 | 18 个 props、`node-click`/`check-change`/`check`/`node-expand`/`node-collapse`/`current-change` 六个事件、默认作用域插槽与 9 个实例方法已覆盖；级联照抄上游（向下铺开与父节点判定都跳过 disabled 子节点），`props` 字段名映射走 `UPTreeNode.nodes(from:props:)`，缺 `nodeKey` 时用「父key-下标」兜底 |
| 135 | `u-upload` | `UPUpload` | ✅ 已完成 | 属性/事件对齐 | 27 个 prop 与 beforeRead/afterRead/oversize/delete/clickPreview/error/afterAutoUpload 全覆盖，`v-model:fileList`、状态层与进度条、trigger 插槽、local 驱动自动上传已移植；选择器与系统预览层由宿主接入（`onPick` 带出 chooseFile 参数） |
| 136 | `u-view` | `UPView` | ✅ 已完成 | 基线可用 | 上游通用 View 包装组件 |
| 137 | `u-virtual-list` | `UPVirtualList` | ✅ 已完成 | 属性/事件对齐 | 6 个 prop 与 `update:scrollTop`/`scroll` 全覆盖，remain/visibleCount/buffer 区间算法照抄上游；`keyField` 因无法反射取字段改为 `key` 闭包 |
| 138 | `u-waterfall` | `UPWaterfall` | ✅ 已完成 | 属性/事件对齐 | 瀑布流布局与数据更新 |
| 139 | `u-novel-reader` | `UPNovelReader` | 🚧 开发中 | 基线可用 | 章节/翻页/滚动双模式、分页布局计算、进度与书签持久化、阅读时长、目录与设置弹层已覆盖（51 tests）；实现与测试已 GREEN 但尚未提交 |
| 140 | `u-tabs-pro` | `UPTabsPro` | 🚧 开发中 | 中高 | 包一层 `UPTabs`：current 归一化、内容区插槽上下文、list 变化回写、空 `activeStyle` 覆盖子组件默认值、单次点击重复 emit 两遍 `update:current` 均已照抄（28 tests）；`contentMode`/`bindIndexRef` 为上游死 prop，仅作元数据；实现与测试已 GREEN 但尚未提交 |

序号说明：1..138 严格按上游 `components/u-*` 的字母序排列；`3.8.113` 新增的 `u-novel-reader`、`u-tabs-pro` 追加在表尾（字母序位置分别在 76/77 与 122 之后），以避免整表重编号。下次上游升级重新扫描时可一并归位。

## 更新规则

1. 新组件开始开发时，将状态改为 `🚧 开发中`，备注写明实现和测试文件是否仍未提交。
2. 已有组件做接口补齐时，将状态改为 `🔄 兼容增强中`，不能覆盖其“已有提交基线”的事实。
3. 只有完成 RED/GREEN、干净 archive 全量测试并提交后，才改为 `✅ 已完成`。
4. 每次状态变化同步更新顶部日期、iOS 基线提交、分类数量和覆盖率。
5. 上游升级时重新扫描 `components/u-*`；新增、删除或改名的目录必须同步到此表。
