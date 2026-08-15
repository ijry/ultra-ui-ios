# ultra-ui-ios 设计文档（uview-plus SwiftUI 版）

> 日期：2026-08-15 · 状态：已确认

## 目标
将 uview-plus（uni-app Vue 组件库）核心组件移植为 SwiftUI 版本，接口尽量保持字符串风格一致，可对原生组件封装。首期聚焦核心组件集。

## 范围（首期 9 个组件）
UPButton、UPPopup、UPModal、UPToast、UPOverlay、UPIcon、UPLine、UPGap、UPLoadingIcon

## 工程形态
- Xcode App 工程（Demo 页）+ 内嵌 SPM Package（UltraUI）
- Swift 6.3 / Xcode 26.6，iOS 目标 17.0+

## 接口风格（贴近 uview-plus 字符串）
- 字符串参数：type: "primary"、size: "large"、shape: "circle" 等，内部解析为枚举，非法值回退默认
- 事件：.onConfirm / .onCancel / .onClose / .onTap 修饰符
- 颜色：支持 #RRGGBB、#RRGGBBAA、主题名（primary/success/error/warning/info）
- 小程序专属参数（openType/formType 等）保留但忽略

## 组件参数对齐（默认值取自 uview-plus props/*.js）
### UPButton
hairline(false)、type("info")、size("normal")、shape("square")、plain(false)、disabled(false)、loading(false)、loadingText("")、loadingMode("spinner")、loadingSize(15)、text("")、icon("")、iconColor("")、color("")、throttleTime(0)、block(false)
- 尺寸：large(100%×50px)、normal(100%×40px)、small(60px×30px)、mini(50px×22px)
- 主题色：primary #3c9cff、success #5ac725、error #f56c6c、warning #f9ae3d、info #909399
- 事件：onTap、onClick（throttleTime 节流）

### UPPopup
show(false)、overlay(true)、mode("bottom")、duration(300)、closeable(false)、overlayStyle({})、closeOnClickOverlay(true)、zIndex(10075)、safeAreaInsetBottom(true)、safeAreaInsetTop(false)、closeIconPos("top-right")、round("20px")、zoom(true)、bgColor("")、overlayOpacity(0.5)、pageInline(false)、touchable(false)、minHeight("200px")、maxHeight("600px")
- 事件：onClose、onOpen、onClickOverlay

### UPModal（基于 UPPopup mode="center" 组合）
show(false)、title("")、content("")、confirmText("确认")、cancelText("取消")、showConfirmButton(true)、showCancelButton(false)、confirmColor("#2979ff")、cancelColor("#606266")、buttonReverse(false)、zoom(true)、asyncClose(false)、closeOnClickOverlay(false)、negativeTop(0)、width("650rpx")、confirmButtonShape("")、duration(400)、contentTextAlign("left")、asyncCloseTip("操作中...")、asyncCancelClose(false)、contentStyle({})
- 事件：onConfirm、onCancel、onClose、onCancelOnAsync

### UPToast
命令式 UPToast.show(message:type:position:duration:) + 声明式组件
- type：default/success/error/warning/loading
- position：center/top/bottom
- duration 默认 2000ms，zIndex 10090

### UPOverlay
show(false)、zIndex(10070)、duration(300)、opacity(0.5)

### UPIcon
name("")、color(内容色 #606266)、size("16px")、bold(false)、label("")、labelPos("right")、labelSize("15px")、labelColor(#606266)、space("3px")、customPrefix("uicon")
- 内置 uview-plus 图标字体子集（常用 60+），SF Symbols 映射兜底

### UPLine
color("#d6d7d9")、length("100%")、direction("row")、hairline(true)、margin(0)、dashed(false)

### UPGap
bgColor("transparent")、height(20)、marginTop(0)、marginBottom(0)

### UPLoadingIcon
show(true)、color(#909399)、textColor(#909399)、vertical(false)、mode("spinner")、size(24)、textSize(15)、text("")、duration(1200)、inactiveColor("")

## 主题色板（对齐 uview-plus theme.scss）
- main #303133、content #606266、tips #909193、light #c0c4cc、border #dadbde、bg #f3f4f6、disabled #c8c9cc
- primary #3c9cff（dark #398ade、disabled #9acafc、light #ecf5ff）
- warning #f9ae3d、success #5ac725、error #f56c6c、info #909399

## 关键实现
- UPUnit：rpx→pt 换算（375 基准宽度），addUnit 等价物
- 弹窗体系：UPPopup 用 ZStack+overlay，UPModal 组合 UPPopup(mode:"center")
- Toast：UPToastCenter 环境对象 + 全局 show
- 主题：UPTheme 环境值，支持覆盖
- Demo：首页列表 + 每组件一页

## 明确不做（首期）
- 小程序专属能力（openType/formType/微信登录）——参数保留但忽略
- 复杂业务组件（upload/calendar/cascader/table/canvas 等）二期
- 图标字体全量（先常用子集）
