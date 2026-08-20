# uview-plus SwiftUI 复刻进度

> 最后更新：2026-08-21
> 上游基线：uview-plus `3.8.86`，以 `components/u-*` 目录为完整清单
> iOS 基线：`main` / `ea0cc68`

## 总览

| 指标 | 数量 | 说明 |
| --- | ---: | --- |
| 上游组件目录 | 138 | 包括公开组件、配套子组件和内部辅助组件 |
| 已完成 | 44 | 已提交，具备对应 SwiftUI 类型和测试基线 |
| 兼容增强中 | 11 | 已有已提交基线，当前工作区还有未提交的接口兼容增强 |
| 开发中 | 0 | 当前没有处于开发中的组件 |
| 待开始 | 83 | 尚无对应 SwiftUI 组件实现 |
| 已有实现覆盖 | 55 / 138 | `已完成 + 兼容增强中 + 开发中`，约 39.9% |
| 已提交覆盖 | 55 / 138 | `已完成 + 兼容增强中` 均已有已提交基线，约 39.9% |

## 状态口径

| 标记 | 复刻进度 | 接口兼容性口径 |
| --- | --- | --- |
| ✅ | 已完成 | 已对齐当前纳入范围的 props 默认值、String/Number 输入、事件 payload 和插槽映射，并有测试基线 |
| 🔄 | 兼容增强中 | 已有可用且已提交的 SwiftUI 基线；工作区仍有未提交的接口对齐增强，完成度以最终提交为准 |
| 🚧 | 开发中 | 已有未提交实现或测试；尚未完成独立验证和提交，不能视为稳定接口 |
| ⬜ | 待开始 | 尚未实现；接口兼容性未评估 |

接口映射原则：uview-plus named slot 对应 SwiftUI `@ViewBuilder`；Vue emit 对应闭包或链式事件修饰符；无法在 iOS 原生平台成立的小程序、DOM、CSS 或路由能力会保留兼容元数据，或在备注中明确采用原生替代方案。

## 组件清单

| # | uview-plus 组件 | SwiftUI 类型 | 复刻进度 | 接口兼容性 | 备注 |
| ---: | --- | --- | --- | --- | --- |
| 1 | `u-action-sheet` | `UPActionSheet` | ✅ 已完成 | 高 | props、事件、默认/description 插槽及 `UPConfig.actionSheet` 已覆盖 |
| 2 | `u-action-sheet-data` | `UPActionSheetAction` | ✅ 已完成 | 高 | 上游 action 数据模型映射为强类型 Swift 结构 |
| 3 | `u-agreement` | `UPAgreement` | ⬜ 待开始 | 未评估 | 协议勾选业务组件 |
| 4 | `u-album` | `UPAlbum` | ⬜ 待开始 | 未评估 | 图片宫格与预览 |
| 5 | `u-alert` | `UPAlert` | ✅ 已完成 | 高 | props、显示/关闭行为、事件和插槽已覆盖 |
| 6 | `u-avatar` | `UPAvatar` | ✅ 已完成 | 高 | props、String/Number 尺寸、事件已覆盖 |
| 7 | `u-avatar-group` | `UPAvatarGroup` | ✅ 已完成 | 高 | 头像组布局、超量显示和数据输入已覆盖 |
| 8 | `u-back-top` | `UPBackTop` | ✅ 已完成 | 高 | props、阈值、默认插槽、click；滚动动作由 `ScrollViewReader` 接入 |
| 9 | `u-badge` | `UPBadge` | ✅ 已完成 | 高 | props、定位和 String/Number 输入已覆盖 |
| 10 | `u-barcode` | `UPBarcode` | ⬜ 待开始 | 未评估 | 需选择原生条码生成实现 |
| 11 | `u-box` | `UPBox` | ✅ 已完成 | 高 | 三区域布局、默认值、颜色及 named slots 已覆盖 |
| 12 | `u-button` | `UPButton` | 🔄 兼容增强中 | 基线可用 | 已有原生 Button 封装；当前有未提交 props/事件兼容增强 |
| 13 | `u-calendar` | `UPCalendar` | ⬜ 待开始 | 未评估 | 复杂日期状态与多选范围 |
| 14 | `u-calendar-strip` | `UPCalendarStrip` | ⬜ 待开始 | 未评估 | 横向日历条 |
| 15 | `u-canvas` | `UPCanvas` | ⬜ 待开始 | 未评估 | 需映射 SwiftUI Canvas / Core Graphics |
| 16 | `u-car-keyboard` | `UPCarKeyboard` | ⬜ 待开始 | 未评估 | 车牌键盘 |
| 17 | `u-card` | `UPCard` | ✅ 已完成 | 高 | props、String/Number 单位、三类 named slot、index 和四类点击事件已覆盖 |
| 18 | `u-cascader` | `UPCascader` | ⬜ 待开始 | 未评估 | 级联选择器 |
| 19 | `u-cate-tab` | `UPCateTab` | ⬜ 待开始 | 未评估 | 分类导航业务组件 |
| 20 | `u-cell` | `UPCell` | ✅ 已完成 | 高 | props、name payload、事件和插槽已覆盖 |
| 21 | `u-cell-group` | `UPCellGroup` | ✅ 已完成 | 高 | 分组样式和内容容器已覆盖 |
| 22 | `u-checkbox` | `UPCheckbox` | ✅ 已完成 | 高 | name/value、String/Number/Bool、事件及图标/标签插槽已覆盖 |
| 23 | `u-checkbox-group` | `UPCheckboxGroup` | ✅ 已完成 | 高 | Binding、change payload、父子配置继承已覆盖 |
| 24 | `u-choose` | `UPChoose` | ⬜ 待开始 | 未评估 | 选择业务组件 |
| 25 | `u-circle-progress` | `UPCircleProgress` | ✅ 已完成 | 高 | `percentage`、范围约束、shared mixin 样式和原生进度环已覆盖 |
| 26 | `u-city-locate` | `UPCityLocate` | ⬜ 待开始 | 未评估 | 城市定位业务组件，涉及系统定位权限 |
| 27 | `u-code` | `UPCode` | ✅ 已完成 | 高 | 倒计时状态、事件和控制接口已覆盖 |
| 28 | `u-code-input` | `UPCodeInput` | ✅ 已完成 | 高 | String/Number props、输入状态、事件已覆盖 |
| 29 | `u-col` | `UPCol` | ✅ 已完成 | 高 | 与 `UPRow` 配套的 span/offset 布局已覆盖 |
| 30 | `u-collapse` | `UPCollapse` | ✅ 已完成 | 高 | scalar/array value、accordion、change/open/close 已覆盖 |
| 31 | `u-collapse-item` | `UPCollapseItem` | ✅ 已完成 | 高 | disabled、name、标题/图标/内容等 named slots 已覆盖 |
| 32 | `u-color-picker` | `UPColorPicker` | ⬜ 待开始 | 未评估 | 可封装 SwiftUI `ColorPicker`，需保持上游颜色模型 |
| 33 | `u-column-notice` | `UPColumnNotice` | ⬜ 待开始 | 未评估 | 上游 notice 内部辅助组件 |
| 34 | `u-copy` | `UPCopy` | ⬜ 待开始 | 未评估 | 需映射系统剪贴板 |
| 35 | `u-count-down` | `UPCountDown` | ✅ 已完成 | 高 | 时间输入、格式化、change/finish payload 与控制接口已覆盖 |
| 36 | `u-count-to` | `UPCountTo` | ✅ 已完成 | 高 | 数字动画、格式化和事件已覆盖 |
| 37 | `u-coupon` | `UPCoupon` | ⬜ 待开始 | 未评估 | 优惠券业务组件 |
| 38 | `u-cropper` | `UPCropper` | ⬜ 待开始 | 未评估 | 需原生图片裁剪与手势实现 |
| 39 | `u-datetime-picker` | `UPDatetimePicker` | ⬜ 待开始 | 未评估 | 可组合原生 DatePicker，需保持事件和范围语义 |
| 40 | `u-divider` | `UPDivider` | ✅ 已完成 | 高 | 方向、文字、虚线和尺寸 props 已覆盖 |
| 41 | `u-dragsort` | `UPDragsort` | ⬜ 待开始 | 未评估 | 拖拽排序与事件 payload |
| 42 | `u-dropdown` | `UPDropdown` | ⬜ 待开始 | 未评估 | 与 `UPDropdownItem` 配套 |
| 43 | `u-dropdown-item` | `UPDropdownItem` | ⬜ 待开始 | 未评估 | 下拉菜单子项 |
| 44 | `u-empty` | `UPEmpty` | ✅ 已完成 | 高 | mode 文案/icon 映射、图片 icon、默认 slot、String/Number 单位和 show 已覆盖 |
| 45 | `u-float-button` | `UPFloatButton` | ⬜ 待开始 | 未评估 | 悬浮按钮、展开菜单和 item-click |
| 46 | `u-form` | `UPForm` | 🔄 兼容增强中 | 基线可用 | 已有表单模型/校验；当前有未提交规则和上下文增强 |
| 47 | `u-form-item` | `UPFormItem` | 🔄 兼容增强中 | 基线可用 | 已有布局与错误状态；当前有未提交 props/插槽增强 |
| 48 | `u-gap` | `UPGap` | ✅ 已完成 | 中高 | 基础尺寸和背景已覆盖；后续可统一 shared mixin 接口 |
| 49 | `u-goods-sku` | `UPGoodsSku` | ⬜ 待开始 | 未评估 | SKU 选择业务组件 |
| 50 | `u-grid` | `UPGrid` | ✅ 已完成 | 高 | col、border、align、gap、click 上下文已覆盖 |
| 51 | `u-grid-item` | `UPGridItem` | ✅ 已完成 | 高 | name/index payload、item click 和插槽已覆盖 |
| 52 | `u-guide` | `UPGuide` | ⬜ 待开始 | 未评估 | 引导遮罩与步骤定位 |
| 53 | `u-icon` | `UPIcon` | 🔄 兼容增强中 | 基线可用 | 字体图标与图片模式已有；当前有未提交 props/事件增强 |
| 54 | `u-image` | `UPImage` | ✅ 已完成 | 高 | 原生 AsyncImage、loading/error slot、尺寸/圆角、占位显示和 click/load/error 已覆盖 |
| 55 | `u-index-anchor` | `UPIndexAnchor` | ⬜ 待开始 | 未评估 | 与索引列表配套 |
| 56 | `u-index-item` | `UPIndexItem` | ⬜ 待开始 | 未评估 | 与索引列表配套 |
| 57 | `u-index-list` | `UPIndexList` | ⬜ 待开始 | 未评估 | 索引定位和滚动联动 |
| 58 | `u-input` | `UPInput` | 🔄 兼容增强中 | 基线可用 | 原生 TextField 基线已有；当前有未提交 props/事件/插槽增强 |
| 59 | `u-keyboard` | `UPKeyboard` | ⬜ 待开始 | 未评估 | 自定义键盘容器 |
| 60 | `u-lazy-load` | `UPLazyLoad` | ⬜ 待开始 | 未评估 | SwiftUI 原生按需渲染语义不同 |
| 61 | `u-line` | `UPLine` | ✅ 已完成 | 中高 | 方向、长度、虚线与 hairline 已覆盖 |
| 62 | `u-line-progress` | `UPLineProgress` | ✅ 已完成 | 高 | props、范围约束、方向、文本和默认插槽已覆盖 |
| 63 | `u-link` | `UPLink` | ✅ 已完成 | 高 | props、click/open 行为和 URL 兼容已覆盖 |
| 64 | `u-list` | `UPList` | ⬜ 待开始 | 未评估 | 虚拟列表容器 |
| 65 | `u-list-item` | `UPListItem` | ⬜ 待开始 | 未评估 | 列表子项 |
| 66 | `u-loading-icon` | `UPLoadingIcon` | 🔄 兼容增强中 | 基线可用 | 原生动画已有；当前有未提交 props 与样式增强 |
| 67 | `u-loading-page` | `UPLoadingPage` | ✅ 已完成 | 高 | 全屏 overlay、模式、图片、默认插槽和配置已覆盖 |
| 68 | `u-loadmore` | `UPLoadmore` | ✅ 已完成 | 高 | status、图标、文字、尺寸和 click 已覆盖 |
| 69 | `u-markdown` | `UPMarkdown` | ⬜ 待开始 | 未评估 | 需要 Markdown 解析/渲染依赖决策 |
| 70 | `u-message-input` | `UPMessageInput` | ⬜ 待开始 | 未评估 | 上游独立消息输入组件 |
| 71 | `u-modal` | `UPModal` | 🔄 兼容增强中 | 基线可用 | 基于原生弹层；当前有未提交 asyncClose、事件和插槽增强 |
| 72 | `u-navbar` | `UPNavbar` | ⬜ 待开始 | 未评估 | 需映射 NavigationStack/toolbar，同时保留上游布局 props |
| 73 | `u-navbar-mini` | `UPNavbarMini` | ⬜ 待开始 | 未评估 | 小程序胶囊导航语义需原生适配 |
| 74 | `u-no-network` | `UPNoNetwork` | ⬜ 待开始 | 未评估 | 需接入 Network.framework |
| 75 | `u-notice-bar` | `UPNoticeBar` | ⬜ 待开始 | 未评估 | 横向/纵向公告滚动 |
| 76 | `u-notify` | `UPNotify` | ⬜ 待开始 | 未评估 | 顶部通知及命令式 API |
| 77 | `u-number-box` | `UPNumberBox` | ✅ 已完成 | 高 | 数值模型、步进、范围、格式和事件已覆盖 |
| 78 | `u-number-keyboard` | `UPNumberKeyboard` | ⬜ 待开始 | 未评估 | 数字键盘和 random/dot 模式 |
| 79 | `u-overlay` | `UPOverlay` | 🔄 兼容增强中 | 基线可用 | overlay 基线已有；当前有未提交 shared props 和交互增强 |
| 80 | `u-pagination` | `UPPagination` | ⬜ 待开始 | 未评估 | 页码状态与 change payload |
| 81 | `u-parse` | `UPParse` | ⬜ 待开始 | 未评估 | HTML 富文本解析，需依赖和安全策略 |
| 82 | `u-pdf-reader` | `UPPDFReader` | ⬜ 待开始 | 未评估 | 可基于 PDFKit 封装 |
| 83 | `u-picker` | `UPPicker` | ⬜ 待开始 | 未评估 | 与 picker-column、toolbar 配套 |
| 84 | `u-picker-column` | `UPPickerColumn` | ⬜ 待开始 | 未评估 | Picker 内部列组件 |
| 85 | `u-picker-data` | `UPPickerData` | ⬜ 待开始 | 未评估 | 上游 Picker 数据辅助组件 |
| 86 | `u-popover` | `UPPopover` | ⬜ 待开始 | 未评估 | 原生 popover 与箭头定位 |
| 87 | `u-popup` | `UPPopup` | 🔄 兼容增强中 | 基线可用 | 多方向 popup 基线已有；当前有未提交 props/生命周期增强 |
| 88 | `u-poster` | `UPPoster` | ⬜ 待开始 | 未评估 | 海报合成与导出 |
| 89 | `u-pull-refresh` | `UPPullRefresh` | ⬜ 待开始 | 未评估 | 可组合 SwiftUI refreshable，需保持状态接口 |
| 90 | `u-qrcode` | `UPQRCode` | ⬜ 待开始 | 未评估 | 可基于 Core Image 生成二维码 |
| 91 | `u-radio` | `UPRadio` | ✅ 已完成 | 高 | value/name、String/Number/Bool、事件和插槽已覆盖 |
| 92 | `u-radio-group` | `UPRadioGroup` | ✅ 已完成 | 高 | Binding、change payload 和父子配置继承已覆盖 |
| 93 | `u-rate` | `UPRate` | ✅ 已完成 | 高 | props、半星、手势、change payload 已覆盖 |
| 94 | `u-read-more` | `UPReadMore` | ⬜ 待开始 | 未评估 | 内容测量、展开/收起事件 |
| 95 | `u-refresh-virtual-list` | `UPRefreshVirtualList` | ⬜ 待开始 | 未评估 | 上游虚拟列表刷新辅助组件 |
| 96 | `u-row` | `UPRow` | ✅ 已完成 | 高 | gutter、justify、align、click 和布局上下文已覆盖 |
| 97 | `u-row-notice` | `UPRowNotice` | ⬜ 待开始 | 未评估 | 上游 notice 内部辅助组件 |
| 98 | `u-safe-bottom` | `UPSafeBottom` | ⬜ 待开始 | 未评估 | 可映射 safeAreaInset |
| 99 | `u-scroll-list` | `UPScrollList` | ⬜ 待开始 | 未评估 | 横向滚动和指示器联动 |
| 100 | `u-search` | `UPSearch` | ✅ 已完成 | 高 | Binding、clear/search/custom 事件、左右插槽和配置已覆盖 |
| 101 | `u-section` | `UPSection` | ⬜ 待开始 | 未评估 | 当前上游目录仅保留配置，无独立 Vue 实现 |
| 102 | `u-select` | `UPSelect` | ⬜ 待开始 | 未评估 | 选择器业务封装 |
| 103 | `u-short-video` | `UPShortVideo` | ⬜ 待开始 | 未评估 | 视频播放、手势和预加载，复杂原生能力 |
| 104 | `u-signature` | `UPSignature` | ⬜ 待开始 | 未评估 | Canvas/触摸签名与图片导出 |
| 105 | `u-skeleton` | `UPSkeleton` | ✅ 已完成 | 高 | rows/title/avatar、尺寸数组、loading 插槽已覆盖 |
| 106 | `u-slider` | `UPSlider` | ⬜ 待开始 | 未评估 | 可封装原生 Slider，需保持 step/range 事件语义 |
| 107 | `u-status-bar` | `UPStatusBar` | ⬜ 待开始 | 未评估 | 可映射 safe area 顶部 inset |
| 108 | `u-steps` | `UPSteps` | ⬜ 待开始 | 未评估 | 与 steps-item 配套 |
| 109 | `u-steps-item` | `UPStepsItem` | ⬜ 待开始 | 未评估 | 步骤子项与父子上下文 |
| 110 | `u-sticky` | `UPSticky` | ⬜ 待开始 | 未评估 | SwiftUI pinned views 与上游 offset 语义适配 |
| 111 | `u-subsection` | `UPSubsection` | ⬜ 待开始 | 未评估 | 分段选择器，可参考原生 Picker segmented style |
| 112 | `u-swipe-action` | `UPSwipeAction` | ⬜ 待开始 | 未评估 | 与 swipe-action-item 配套及互斥状态 |
| 113 | `u-swipe-action-item` | `UPSwipeActionItem` | ⬜ 待开始 | 未评估 | 侧滑菜单、阈值和事件 payload |
| 114 | `u-swiper` | `UPSwiper` | ⬜ 待开始 | 未评估 | 可映射 TabView/page，需兼容 indicator 和事件 |
| 115 | `u-swiper-indicator` | `UPSwiperIndicator` | ⬜ 待开始 | 未评估 | Swiper 指示器辅助组件 |
| 116 | `u-switch` | `UPSwitch` | ✅ 已完成 | 高 | active/inactive value、loading/disabled、change 已覆盖 |
| 117 | `u-tabbar` | `UPTabbar` | ⬜ 待开始 | 未评估 | 与 tabbar-item 配套，需原生安全区处理 |
| 118 | `u-tabbar-item` | `UPTabbarItem` | ⬜ 待开始 | 未评估 | tabbar 子项、badge、事件 payload |
| 119 | `u-table` | `UPTable` | ⬜ 待开始 | 未评估 | 旧版表格组件族，与 tr/th/td 配套 |
| 120 | `u-table2` | `UPTable2` | ⬜ 待开始 | 未评估 | 新版表格，含内部 tableRow |
| 121 | `u-tabs` | `UPTabs` | ⬜ 待开始 | 未评估 | 与 tabs-item 配套、滚动指示器和 change/click |
| 122 | `u-tabs-item` | `UPTabsItem` | ⬜ 待开始 | 未评估 | tabs 子项与父子上下文 |
| 123 | `u-tag` | `UPTag` | ✅ 已完成 | 高 | props、click/close payload、图标及内容插槽已覆盖 |
| 124 | `u-td` | `UPTd` | ⬜ 待开始 | 未评估 | 旧版表格单元格 |
| 125 | `u-text` | `UPText` | ✅ 已完成 | 高 | mode/formatter、String/Number 属性、图标、行数/样式、link/phone 元数据和 click 已覆盖 |
| 126 | `u-textarea` | `UPTextarea` | 🔄 兼容增强中 | 基线可用 | 原生 TextEditor 基线已有；当前有未提交 props/事件增强 |
| 127 | `u-th` | `UPTh` | ⬜ 待开始 | 未评估 | 旧版表格表头单元格 |
| 128 | `u-title` | `UPTitle` | ✅ 已完成 | 高 | 标题模式、颜色、尺寸和样式已覆盖 |
| 129 | `u-toast` | `UPToast` / `UPToastView` | 🔄 兼容增强中 | 基线可用 | 声明式/命令式基线已有；当前有未提交 options 与行为增强 |
| 130 | `u-toolbar` | `UPToolbar` | ⬜ 待开始 | 未评估 | Picker 等组件共用的工具栏 |
| 131 | `u-tooltip` | `UPTooltip` | ⬜ 待开始 | 未评估 | 浮层定位、复制和关闭行为 |
| 132 | `u-tr` | `UPTr` | ⬜ 待开始 | 未评估 | 旧版表格行 |
| 133 | `u-transition` | `UPTransition` | ✅ 已完成 | 高 | mode、duration、timing、生命周期事件、click 和插槽已覆盖 |
| 134 | `u-tree` | `UPTree` | ⬜ 待开始 | 未评估 | 树节点、选择、展开和递归状态 |
| 135 | `u-upload` | `UPUpload` | ⬜ 待开始 | 未评估 | PhotosPicker、上传状态、预览及事件，复杂原生能力 |
| 136 | `u-view` | `UPView` | ⬜ 待开始 | 未评估 | 上游通用 View 包装组件 |
| 137 | `u-virtual-list` | `UPVirtualList` | ⬜ 待开始 | 未评估 | 需映射 Lazy 容器和可见范围计算 |
| 138 | `u-waterfall` | `UPWaterfall` | ⬜ 待开始 | 未评估 | 瀑布流布局与数据更新 |

## 更新规则

1. 新组件开始开发时，将状态改为 `🚧 开发中`，备注写明实现和测试文件是否仍未提交。
2. 已有组件做接口补齐时，将状态改为 `🔄 兼容增强中`，不能覆盖其“已有提交基线”的事实。
3. 只有完成 RED/GREEN、干净 archive 全量测试并提交后，才改为 `✅ 已完成`。
4. 每次状态变化同步更新顶部日期、iOS 基线提交、分类数量和覆盖率。
5. 上游升级时重新扫描 `components/u-*`；新增、删除或改名的目录必须同步到此表。
