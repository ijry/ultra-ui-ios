# uview-plus SwiftUI 复刻进度

> 最后更新：2026-08-22
> 上游基线：uview-plus `3.8.86`，以 `components/u-*` 目录为完整清单
> iOS 基线：`main` / `58e44d0`

## 总览

| 指标 | 数量 | 说明 |
| --- | ---: | --- |
| 上游组件目录 | 138 | 包括公开组件、配套子组件和内部辅助组件 |
| 已完成 | 138 | 已提交，具备对应 SwiftUI 类型和测试基线 |
| 兼容增强中 | 0 | 当前没有未提交的兼容增强 |
| 开发中 | 0 | 当前没有处于开发中的组件 |
| 待开始 | 0 | 138 个上游目录均有对应 SwiftUI 类型 |
| 已有实现覆盖 | 138 / 138 | `已完成 + 兼容增强中 + 开发中`，100% |
| 已提交覆盖 | 138 / 138 | `已完成 + 兼容增强中` 均已有已提交基线，100% |

## 状态口径

| 标记 | 复刻进度 | 接口兼容性口径 |
| --- | --- | --- |
| ✅ | 已完成 | 已提交 SwiftUI 实现与测试基线；接口兼容性在“高”或“基线可用”栏中单独标注 |
| 🔄 | 兼容增强中 | 已有可用且已提交的 SwiftUI 基线，当前没有未提交增强 |
| 🚧 | 开发中 | 已有未提交实现或测试；尚未完成独立验证和提交，不能视为稳定接口 |
| ⬜ | 待开始 | 尚未实现；接口兼容性未评估 |

接口映射原则：uview-plus named slot 对应 SwiftUI `@ViewBuilder`；Vue emit 对应闭包或链式事件修饰符；无法在 iOS 原生平台成立的小程序、DOM、CSS 或路由能力会保留兼容元数据，或在备注中明确采用原生替代方案。

输入组件族的原生适配语义：`placeholderClass` 无 CSS class 对应物；`fixed`、`adjustPosition`、`holdKeyboard`、`showConfirmBar`、`disableDefaultPadding` 属小程序键盘与页面上推语义；`cursor`、`cursorSpacing`、`selectionStart`、`selectionEnd` 因 SwiftUI 不公开光标位置 API 而仅作元数据保留；`ignoreCompositionEvent` 的输入法合成事件由系统托管；上游 blur 前 150ms 去抖（用于保证清除按钮可点）在 `@FocusState` 下时序不同，改由 `onlyClearableOnFocused` 与 disabled 抑制共同覆盖。

表单组件族的原生适配语义：上游 `validate` 返回 Promise 并 reject 错误数组，Swift 侧改为同步 `Bool` 返回值加 `errors` 字典，`$nextTick` 时序由 SwiftUI 的状态更新取代；`errorType: 'toast'` 上游直接调用全局 `toast()`，Swift 侧由 `UPFormContext.toastMessage` 暴露首条错误、交宿主 `UPToastCenter` 呈现，与本包其余组件一致地保持呈现权在宿主。

公告组件族的原生适配语义：`speed`（每秒滚动 px）与 `duration`（滚动周期 ms）作为兼容元数据保留，实际滚动交 SwiftUI 动画；`disableTouch` 的手势切换限小程序平台；`url` + `linkType` 的路由跳转由宿主实现，与 `UPButton` 的开放能力转发一致。

## 组件清单

| # | uview-plus 组件 | SwiftUI 类型 | 复刻进度 | 接口兼容性 | 备注 |
| ---: | --- | --- | --- | --- | --- |
| 1 | `u-action-sheet` | `UPActionSheet` | ✅ 已完成 | 高 | props、事件、默认/description 插槽及 `UPConfig.actionSheet` 已覆盖 |
| 2 | `u-action-sheet-data` | `UPActionSheetAction` | ✅ 已完成 | 高 | 上游 action 数据模型映射为强类型 Swift 结构 |
| 3 | `u-agreement` | `UPAgreement` | ✅ 已完成 | 基线可用 | 协议勾选业务组件 |
| 4 | `u-album` | `UPAlbum` | ✅ 已完成 | 基线可用 | 图片宫格与预览 |
| 5 | `u-alert` | `UPAlert` | ✅ 已完成 | 高 | props、显示/关闭行为、事件和插槽已覆盖 |
| 6 | `u-avatar` | `UPAvatar` | ✅ 已完成 | 高 | props、String/Number 尺寸、事件已覆盖 |
| 7 | `u-avatar-group` | `UPAvatarGroup` | ✅ 已完成 | 高 | 头像组布局、超量显示和数据输入已覆盖 |
| 8 | `u-back-top` | `UPBackTop` | ✅ 已完成 | 高 | props、阈值、默认插槽、click；滚动动作由 `ScrollViewReader` 接入 |
| 9 | `u-badge` | `UPBadge` | ✅ 已完成 | 高 | props、定位和 String/Number 输入已覆盖 |
| 10 | `u-barcode` | `UPBarcode` | ✅ 已完成 | 基线可用 | 已采用 Core Image Code 128 生成 |
| 11 | `u-box` | `UPBox` | ✅ 已完成 | 高 | 三区域布局、默认值、颜色及 named slots 已覆盖 |
| 12 | `u-button` | `UPButton` | ✅ 已完成 | 中高 | 原生 Button 封装；String/Number 文本、尺寸和时间 props、点击节流、默认 slot 及开放能力宿主转发接口已覆盖；小程序能力由 iOS 宿主实现 |
| 13 | `u-calendar` | `UPCalendar` | ✅ 已完成 | 中高 | single/multiple/range、日期 Binding、边界/只读/maxCount、select/confirm/close 已覆盖 |
| 14 | `u-calendar-strip` | `UPCalendarStrip` | ✅ 已完成 | 中高 | modelValue/current Binding、只读/禁用日期及结构化 change payload 已覆盖 |
| 15 | `u-canvas` | `UPCanvas` | ✅ 已完成 | 基线可用 | 已采用 SwiftUI Canvas 命令模型 |
| 16 | `u-car-keyboard` | `UPCarKeyboard` | ✅ 已完成 | 基线可用 | 车牌键盘 |
| 17 | `u-card` | `UPCard` | ✅ 已完成 | 高 | props、String/Number 单位、三类 named slot、index 和四类点击事件已覆盖 |
| 18 | `u-cascader` | `UPCascader` | ✅ 已完成 | 基线可用 | 级联选择器 |
| 19 | `u-cate-tab` | `UPCateTab` | ✅ 已完成 | 中高 | current Binding、结构化 change payload 及旧版值回调已覆盖；DOM 滚动联动采用原生 ScrollView |
| 20 | `u-cell` | `UPCell` | ✅ 已完成 | 高 | props、name payload、事件和插槽已覆盖 |
| 21 | `u-cell-group` | `UPCellGroup` | ✅ 已完成 | 高 | 分组样式和内容容器已覆盖 |
| 22 | `u-checkbox` | `UPCheckbox` | ✅ 已完成 | 高 | name/value、String/Number/Bool、事件及图标/标签插槽已覆盖 |
| 23 | `u-checkbox-group` | `UPCheckboxGroup` | ✅ 已完成 | 高 | Binding、change payload、父子配置继承已覆盖 |
| 24 | `u-choose` | `UPChoose` | ✅ 已完成 | 基线可用 | 选择业务组件 |
| 25 | `u-circle-progress` | `UPCircleProgress` | ✅ 已完成 | 高 | `percentage`、范围约束、shared mixin 样式和原生进度环已覆盖 |
| 26 | `u-city-locate` | `UPCityLocate` | ✅ 已完成 | 基线可用 | 城市定位业务组件，已提供可注入定位 Provider；权限由宿主声明 |
| 27 | `u-code` | `UPCode` | ✅ 已完成 | 高 | 倒计时状态、事件和控制接口已覆盖 |
| 28 | `u-code-input` | `UPCodeInput` | ✅ 已完成 | 高 | String/Number props、输入状态、事件已覆盖 |
| 29 | `u-col` | `UPCol` | ✅ 已完成 | 高 | 与 `UPRow` 配套的 span/offset 布局已覆盖 |
| 30 | `u-collapse` | `UPCollapse` | ✅ 已完成 | 高 | scalar/array value、accordion、change/open/close 已覆盖 |
| 31 | `u-collapse-item` | `UPCollapseItem` | ✅ 已完成 | 高 | disabled、name、标题/图标/内容等 named slots 已覆盖 |
| 32 | `u-color-picker` | `UPColorPicker` | ✅ 已完成 | 基线可用 | 可封装 SwiftUI `ColorPicker`，需保持上游颜色模型 |
| 33 | `u-column-notice` | `UPColumnNotice` | ✅ 已完成 | 中高 | 上游 props（icon/mode/color/bgColor/fontSize/speed/step/duration/disableTouch/justifyContent）与 click/close 已覆盖；duration 默认 1500 与 notice-bar 的 2000 区分；旧 `notices:`/`interval:` 初始化器保留（`58e44d0`） |
| 34 | `u-copy` | `UPCopy` | ✅ 已完成 | 高 | 原生剪贴板、props、默认/自定义 slot、success 及空内容/失败行为已覆盖 |
| 35 | `u-count-down` | `UPCountDown` | ✅ 已完成 | 高 | 时间输入、格式化、change/finish payload 与控制接口已覆盖 |
| 36 | `u-count-to` | `UPCountTo` | ✅ 已完成 | 高 | 数字动画、格式化和事件已覆盖 |
| 37 | `u-coupon` | `UPCoupon` | ✅ 已完成 | 中高 | amount/unit/limit/desc/time/action/style props、disabled/click 及旧 claim API 已覆盖 |
| 38 | `u-cropper` | `UPCropper` | ✅ 已完成 | 基线可用 | 已提供裁剪矩形约束与确认回调基线 |
| 39 | `u-datetime-picker` | `UPDatetimePicker` | ✅ 已完成 | 中高 | Int64 时间戳与 String time/timesecond Binding、范围夹取、结构化 payload、受控 show、关闭生命周期、原生双向 DatePicker 及 named slots 已覆盖；列级 formatter/filter 与原生滚动时序采用适配语义（`b345e9f`） |
| 40 | `u-divider` | `UPDivider` | ✅ 已完成 | 高 | 方向、文字、虚线和尺寸 props 已覆盖 |
| 41 | `u-dragsort` | `UPDragsort` | ✅ 已完成 | 基线可用 | 拖拽排序与事件 payload |
| 42 | `u-dropdown` | `UPDropdown` | ✅ 已完成 | 基线可用 | 与 `UPDropdownItem` 配套 |
| 43 | `u-dropdown-item` | `UPDropdownItem` | ✅ 已完成 | 基线可用 | 下拉菜单子项 |
| 44 | `u-empty` | `UPEmpty` | ✅ 已完成 | 高 | mode 文案/icon 映射、图片 icon、默认 slot、String/Number 单位和 show 已覆盖 |
| 45 | `u-float-button` | `UPFloatButton` | ✅ 已完成 | 基线可用 | 悬浮按钮、展开菜单和 item-click |
| 46 | `u-form` | `UPForm` | ✅ 已完成 | 中高 | 表单模型、规则校验、错误类型与上下文已覆盖；`resetFields`/`resetField` 的 originalModel 快照、`setRules`、`validate(showErrorMsg:)` 已补齐；`errorType` 的 border-bottom 已渲染，toast 由 `toastMessage` 交宿主 `UPToastCenter` 呈现（`7cec530`） |
| 47 | `u-form-item` | `UPFormItem` | ✅ 已完成 | 中高 | 布局、错误状态、props 与插槽已覆盖；label/error 命名插槽、border-bottom 错误下划线已补齐（`7cec530`） |
| 48 | `u-gap` | `UPGap` | ✅ 已完成 | 中高 | 基础尺寸和背景已覆盖；后续可统一 shared mixin 接口 |
| 49 | `u-goods-sku` | `UPGoodsSku` | ✅ 已完成 | 中高 | 规格组合、库存禁用、数量 Binding、确认载荷及旧字典回调已覆盖 |
| 50 | `u-grid` | `UPGrid` | ✅ 已完成 | 高 | col、border、align、gap、click 上下文已覆盖 |
| 51 | `u-grid-item` | `UPGridItem` | ✅ 已完成 | 高 | name/index payload、item click 和插槽已覆盖 |
| 52 | `u-guide` | `UPGuide` | ✅ 已完成 | 基线可用 | 引导遮罩与步骤定位 |
| 53 | `u-icon` | `UPIcon` | ✅ 已完成 | 基线可用 | 字体图标与图片模式、props 和事件基线已提交 |
| 54 | `u-image` | `UPImage` | ✅ 已完成 | 高 | 原生 AsyncImage、loading/error slot、尺寸/圆角、占位显示和 click/load/error 已覆盖 |
| 55 | `u-index-anchor` | `UPIndexAnchor` | ✅ 已完成 | 基线可用 | 与索引列表配套 |
| 56 | `u-index-item` | `UPIndexItem` | ✅ 已完成 | 基线可用 | 与索引列表配套 |
| 57 | `u-index-list` | `UPIndexList` | ✅ 已完成 | 基线可用 | 索引定位和滚动联动 |
| 58 | `u-input` | `UPInput` | ✅ 已完成 | 中高 | 原生 TextField、props、事件和插槽已覆盖；String/Number fontSize 与 cursorSpacing、prefix/suffix 命名插槽、带值 focus/blur 事件已补齐（`fad47ec`）；清除按钮额外抑制 disabled 状态为原生适配 |
| 59 | `u-keyboard` | `UPKeyboard` | ✅ 已完成 | 基线可用 | 自定义键盘容器 |
| 60 | `u-lazy-load` | `UPLazyLoad` | ✅ 已完成 | 基线可用 | SwiftUI 原生按需渲染语义不同 |
| 61 | `u-line` | `UPLine` | ✅ 已完成 | 中高 | 方向、长度、虚线与 hairline 已覆盖 |
| 62 | `u-line-progress` | `UPLineProgress` | ✅ 已完成 | 高 | props、范围约束、方向、文本和默认插槽已覆盖 |
| 63 | `u-link` | `UPLink` | ✅ 已完成 | 高 | props、click/open 行为和 URL 兼容已覆盖 |
| 64 | `u-list` | `UPList` | ✅ 已完成 | 基线可用 | 虚拟列表容器 |
| 65 | `u-list-item` | `UPListItem` | ✅ 已完成 | 基线可用 | 列表子项 |
| 66 | `u-loading-icon` | `UPLoadingIcon` | ✅ 已完成 | 基线可用 | 原生动画、props 与样式基线已提交 |
| 67 | `u-loading-page` | `UPLoadingPage` | ✅ 已完成 | 高 | 全屏 overlay、模式、图片、默认插槽和配置已覆盖 |
| 68 | `u-loadmore` | `UPLoadmore` | ✅ 已完成 | 高 | status、图标、文字、尺寸和 click 已覆盖 |
| 69 | `u-markdown` | `UPMarkdown` | ✅ 已完成 | 基线可用 | 已采用 Foundation AttributedString，无第三方依赖 |
| 70 | `u-message-input` | `UPMessageInput` | ✅ 已完成 | 中高 | 上游全部 props、box/middleLine/bottomLine 三种 mode、breathe 动画、change/finish 已覆盖；按上游 `getVal` 语义实现"超长输入不派发事件、外部赋值截断"；已改为可观测 controller 并补透明 TextField 承接键盘（`fad47ec`）；上游 `focus` prop 因与既有 `focus()` 方法同名而存储为 `autoFocus`，`focus:` 初始化标签不变 |
| 71 | `u-modal` | `UPModal` | ✅ 已完成 | 中高 | 基于原生弹层；String/Number 偏移、宽度和动画时长、同步/异步确认顺序、异步取消、named slots 及 `confirmButtonShape` 取消按钮抑制已覆盖 |
| 72 | `u-navbar` | `UPNavbar` | ✅ 已完成 | 基线可用 | 需映射 NavigationStack/toolbar，同时保留上游布局 props |
| 73 | `u-navbar-mini` | `UPNavbarMini` | ✅ 已完成 | 基线可用 | 小程序胶囊导航语义需原生适配 |
| 74 | `u-no-network` | `UPNoNetwork` | ✅ 已完成 | 基线可用 | 已提供可注入网络状态模型和 Network.framework 适配 |
| 75 | `u-notice-bar` | `UPNoticeBar` | ✅ 已完成 | 中高 | 13 个上游 props、`text` 的 Array/String 双类型、带索引 click、close 已覆盖；关闭图标改由 `mode == "closable"` 驱动（上游无 closable prop）；`resolvedVariant` 公开 direction/step 的 column/row 委派选择；无参 onClick 旧拼写保留（`58e44d0`） |
| 76 | `u-notify` | `UPNotify` | ✅ 已完成 | 基线可用 | 顶部通知及命令式 API |
| 77 | `u-number-box` | `UPNumberBox` | ✅ 已完成 | 高 | 数值模型、步进、范围、格式和事件已覆盖 |
| 78 | `u-number-keyboard` | `UPNumberKeyboard` | ✅ 已完成 | 基线可用 | 数字键盘和 random/dot 模式 |
| 79 | `u-overlay` | `UPOverlay` | ✅ 已完成 | 基线可用 | overlay 基线、shared props 和交互已提交 |
| 80 | `u-pagination` | `UPPagination` | ✅ 已完成 | 基线可用 | 页码状态与 change payload |
| 81 | `u-parse` | `UPParse` | ✅ 已完成 | 基线可用 | 已提供受控 HTML 标签解析与错误回调 |
| 82 | `u-pdf-reader` | `UPPDFReader` | ✅ 已完成 | 基线可用 | 已提供 PDFKit 条件适配和页码事件基线 |
| 83 | `u-picker` | `UPPicker` | ✅ 已完成 | 中高 | String/Number/Bool props、受控 show、defaultIndex/最近确认值回滚、上游 payload aliases、关闭生命周期、UPToolbar 及 named slots 已覆盖（`b345e9f`） |
| 84 | `u-picker-column` | `UPPickerColumn` | ✅ 已完成 | 中高 | 原生 wheel Binding、索引夹取及非负 itemHeight 已覆盖（`b345e9f`） |
| 85 | `u-picker-data` | `UPPickerData` | ✅ 已完成 | 中高 | text/value/id 数据模型及 Picker 结构化事件 payload 已覆盖（`b345e9f`） |
| 86 | `u-popover` | `UPPopover` | ✅ 已完成 | 基线可用 | 原生 popover 与箭头定位 |
| 87 | `u-popup` | `UPPopup` | ✅ 已完成 | 中高 | 多方向原生 popup；String/Number 动画、层级、圆角和透明度、外部关闭补发 close、去重及 closed 生命周期已覆盖；DOM 手势采用 SwiftUI 原生语义 |
| 88 | `u-poster` | `UPPoster` | ✅ 已完成 | 基线可用 | 海报合成与导出 |
| 89 | `u-pull-refresh` | `UPPullRefresh` | ✅ 已完成 | 基线可用 | 可组合 SwiftUI refreshable，需保持状态接口 |
| 90 | `u-qrcode` | `UPQRCode` | ✅ 已完成 | 基线可用 | 可基于 Core Image 生成二维码 |
| 91 | `u-radio` | `UPRadio` | ✅ 已完成 | 高 | value/name、String/Number/Bool、事件和插槽已覆盖 |
| 92 | `u-radio-group` | `UPRadioGroup` | ✅ 已完成 | 高 | Binding、change payload 和父子配置继承已覆盖 |
| 93 | `u-rate` | `UPRate` | ✅ 已完成 | 高 | props、半星、手势、change payload 已覆盖 |
| 94 | `u-read-more` | `UPReadMore` | ✅ 已完成 | 基线可用 | 内容测量、展开/收起事件 |
| 95 | `u-refresh-virtual-list` | `UPRefreshVirtualList` | ✅ 已完成 | 基线可用 | 上游虚拟列表刷新辅助组件 |
| 96 | `u-row` | `UPRow` | ✅ 已完成 | 高 | gutter、justify、align、click 和布局上下文已覆盖 |
| 97 | `u-row-notice` | `UPRowNotice` | ✅ 已完成 | 中高 | 上游 props（icon/mode/color/bgColor/fontSize/speed）与 click/change/close 已覆盖；旧 `notices:` 初始化器保留（`58e44d0`） |
| 98 | `u-safe-bottom` | `UPSafeBottom` | ✅ 已完成 | 基线可用 | 可映射 safeAreaInset |
| 99 | `u-scroll-list` | `UPScrollList` | ✅ 已完成 | 基线可用 | 横向滚动和指示器联动 |
| 100 | `u-search` | `UPSearch` | ✅ 已完成 | 高 | Binding、clear/search/custom 事件、左右插槽和配置已覆盖 |
| 101 | `u-section` | `UPSection` | ✅ 已完成 | 基线可用 | 当前上游目录仅保留配置，无独立 Vue 实现 |
| 102 | `u-select` | `UPSelect` | ✅ 已完成 | 基线可用 | 选择器业务封装 |
| 103 | `u-short-video` | `UPShortVideo` | ✅ 已完成 | 基线可用 | 视频播放、手势和预加载，复杂原生能力 |
| 104 | `u-signature` | `UPSignature` | ✅ 已完成 | 基线可用 | Canvas/触摸签名与图片导出 |
| 105 | `u-skeleton` | `UPSkeleton` | ✅ 已完成 | 高 | rows/title/avatar、尺寸数组、loading 插槽已覆盖 |
| 106 | `u-slider` | `UPSlider` | ✅ 已完成 | 中高 | String/Number、单值/区间 Binding、step 归一化及 start/changing/change 区间 payload 已覆盖（`e26fc1e`） |
| 107 | `u-status-bar` | `UPStatusBar` | ✅ 已完成 | 基线可用 | 可映射 safe area 顶部 inset |
| 108 | `u-steps` | `UPSteps` | ✅ 已完成 | 中高 | 支持 String/Number current、安全归一化、方向和步骤状态解析；与 steps-item 配套 |
| 109 | `u-steps-item` | `UPStepsItem` | ✅ 已完成 | 中高 | title/desc/iconSize/error/itemStyle、slot 和 click 已覆盖 |
| 110 | `u-sticky` | `UPSticky` | ✅ 已完成 | 基线可用 | SwiftUI pinned views 与上游 offset 语义适配 |
| 111 | `u-subsection` | `UPSubsection` | ✅ 已完成 | 中高 | current Binding、禁用/去重、公开选中索引及结构化 change payload 已覆盖（`e26fc1e`） |
| 112 | `u-swipe-action` | `UPSwipeAction` | ✅ 已完成 | 基线可用 | 与 swipe-action-item 配套及互斥状态 |
| 113 | `u-swipe-action-item` | `UPSwipeActionItem` | ✅ 已完成 | 基线可用 | 侧滑菜单、阈值和事件 payload |
| 114 | `u-swiper` | `UPSwiper` | ✅ 已完成 | 中高 | current Binding/currentItemId、原生 TabView 回写、change/click payload 和循环导航已覆盖；平台动画细节采用原生语义（`e26fc1e`） |
| 115 | `u-swiper-indicator` | `UPSwiperIndicator` | ✅ 已完成 | 基线可用 | Swiper 指示器辅助组件 |
| 116 | `u-switch` | `UPSwitch` | ✅ 已完成 | 高 | active/inactive value、loading/disabled、change 已覆盖 |
| 117 | `u-tabbar` | `UPTabbar` | ✅ 已完成 | 中高 | 支持 Binding/无控 String value、结构化 change payload、图标/样式/安全区；与 tabbar-item 配套 |
| 118 | `u-tabbar-item` | `UPTabbarItem` | ✅ 已完成 | 中高 | tabbar 子项、badge、active/inactive icon、事件 payload |
| 119 | `u-table` | `UPTable` | ✅ 已完成 | 基线可用 | 旧版表格组件族，与 tr/th/td 配套 |
| 120 | `u-table2` | `UPTable2` | ✅ 已完成 | 基线可用 | 新版表格，含内部 tableRow |
| 121 | `u-tabs` | `UPTabs` | ✅ 已完成 | 中高 | 支持 String 列表/Int Binding、无控选中状态、disabled/click/change、滚动指示器；与 tabs-item 配套 |
| 122 | `u-tabs-item` | `UPTabsItem` | ✅ 已完成 | 中高 | name/badge/icon/disabled 元数据与父子选择上下文已覆盖 |
| 123 | `u-tag` | `UPTag` | ✅ 已完成 | 高 | props、click/close payload、图标及内容插槽已覆盖 |
| 124 | `u-td` | `UPTd` | ✅ 已完成 | 基线可用 | 旧版表格单元格 |
| 125 | `u-text` | `UPText` | ✅ 已完成 | 高 | mode/formatter、String/Number 属性、图标、行数/样式、link/phone 元数据和 click 已覆盖 |
| 126 | `u-textarea` | `UPTextarea` | ✅ 已完成 | 中高 | 原生 TextEditor、props、count、formatter 已覆盖；String/Number height 与 cursorSpacing、带值 focus/blur 事件已补齐；已修正非自增高时被限制为单行的行数上限，改为固定高度 + 内部滚动（`fad47ec`） |
| 127 | `u-th` | `UPTh` | ✅ 已完成 | 基线可用 | 旧版表格表头单元格 |
| 128 | `u-title` | `UPTitle` | ✅ 已完成 | 高 | 标题模式、颜色、尺寸和样式已覆盖 |
| 129 | `u-toast` | `UPToast` / `UPToastView` | ✅ 已完成 | 基线可用 | 声明式/命令式基线、options 与行为已提交 |
| 130 | `u-toolbar` | `UPToolbar` | ✅ 已完成 | 基线可用 | Picker 等组件共用的工具栏 |
| 131 | `u-tooltip` | `UPTooltip` | ✅ 已完成 | 基线可用 | 浮层定位、复制和关闭行为 |
| 132 | `u-tr` | `UPTr` | ✅ 已完成 | 基线可用 | 旧版表格行 |
| 133 | `u-transition` | `UPTransition` | ✅ 已完成 | 高 | mode、duration、timing、生命周期事件、click 和插槽已覆盖 |
| 134 | `u-tree` | `UPTree` | ✅ 已完成 | 中高 | 递归节点、禁用、多选/勾选 Binding、展开及 select/check 事件已覆盖 |
| 135 | `u-upload` | `UPUpload` | ✅ 已完成 | 基线可用 | PhotosPicker、上传状态、预览及事件，复杂原生能力 |
| 136 | `u-view` | `UPView` | ✅ 已完成 | 基线可用 | 上游通用 View 包装组件 |
| 137 | `u-virtual-list` | `UPVirtualList` | ✅ 已完成 | 基线可用 | 需映射 Lazy 容器和可见范围计算 |
| 138 | `u-waterfall` | `UPWaterfall` | ✅ 已完成 | 基线可用 | 瀑布流布局与数据更新 |

## 更新规则

1. 新组件开始开发时，将状态改为 `🚧 开发中`，备注写明实现和测试文件是否仍未提交。
2. 已有组件做接口补齐时，将状态改为 `🔄 兼容增强中`，不能覆盖其“已有提交基线”的事实。
3. 只有完成 RED/GREEN、干净 archive 全量测试并提交后，才改为 `✅ 已完成`。
4. 每次状态变化同步更新顶部日期、iOS 基线提交、分类数量和覆盖率。
5. 上游升级时重新扫描 `components/u-*`；新增、删除或改名的目录必须同步到此表。
