import Foundation

/// Defaults mirrored from the checked-in uview-plus component configuration.
public enum UPConfig {
    public enum button {
        public static let hairline = false
        public static let type = "info"
        public static let size = "normal"
        public static let shape = "square"
        public static let plain = false
        public static let disabled = false
        public static let loading = false
        public static let loadingText = ""
        public static let loadingMode = "spinner"
        public static let loadingSize: Double = 15
        public static let openType = ""
        public static let formType = ""
        public static let appParameter = ""
        public static let hoverStopPropagation = true
        public static let lang = "en"
        public static let sessionFrom = ""
        public static let sendMessageTitle = ""
        public static let sendMessagePath = ""
        public static let sendMessageImg = ""
        public static let showMessageCard = false
        public static let dataName = ""
        public static let throttleTime: Double = 0
        public static let hoverStartTime: Double = 0
        public static let hoverStayTime: Double = 200
        public static let text = ""
        public static let icon = ""
        public static let iconColor = ""
        public static let color = ""
        public static let stop = true
        /// Existing native-only shorthand retained for source compatibility.
        public static let block = false
    }

    public enum popup {
        public static let show = false
        public static let overlay = true
        public static let mode = "bottom"
        public static let duration: Double = 300
        public static let closeable = false
        public static let overlayStyle = UPStyle()
        public static let closeOnClickOverlay = true
        public static let zIndex: Double = 10075
        public static let safeAreaInsetBottom = true
        public static let safeAreaInsetTop = false
        public static let closeIconPos = "top-right"
        public static let round = "20px"
        public static let zoom = true
        public static let bgColor = ""
        public static let overlayOpacity: Double = 0.5
        public static let pageInline = false
        public static let touchable = false
        public static let minHeight = "200px"
        public static let maxHeight = "600px"
    }

    public enum modal {
        public static let show = false
        public static let title = ""
        public static let content = ""
        public static let confirmText = "确定"
        public static let cancelText = "取消"
        public static let showConfirmButton = true
        public static let showCancelButton = false
        public static let confirmColor = "#2979ff"
        public static let cancelColor = "#606266"
        public static let buttonReverse = false
        public static let zoom = true
        public static let asyncClose = false
        public static let closeOnClickOverlay = false
        public static let negativeTop: Double = 0
        public static let width = "650rpx"
        public static let confirmButtonShape = ""
        public static let duration: Double = 400
        public static let contentTextAlign = "left"
        public static let asyncCloseTip = "操作中..."
        public static let asyncCancelClose = false
        public static let contentStyle = UPStyle()
    }

    public enum toast {
        public static let zIndex: Double = 10090
        public static let loading = false
        public static let message = ""
        public static let icon = ""
        public static let type = ""
        public static let loadingMode = ""
        public static let show = false
        public static let overlay = false
        public static let position = "center"
        public static let params: [String: String] = [:]
        public static let duration: Double = 2000
        public static let isTab = false
        public static let url = ""
        public static let back = false
    }

    public enum overlay {
        public static let show = false
        public static let zIndex: Double = 10070
        public static let duration: Double = 300
        public static let opacity: Double = 0.5
    }

    public enum icon {
        public static let name = ""
        public static let color = "#606266"
        public static let size = "16px"
        public static let bold = false
        public static let index = ""
        public static let hoverClass = ""
        public static let customPrefix = "uicon"
        public static let label = ""
        public static let labelPos = "right"
        public static let labelSize = "15px"
        public static let labelColor = "#606266"
        public static let space = "3px"
        public static let imgMode = ""
        public static let width = ""
        public static let height = ""
        public static let top = "0"
        public static let stop = false
    }

    public enum line {
        public static let color = "#d6d7d9"
        public static let length = "100%"
        public static let direction = "row"
        public static let hairline = true
        public static let margin: Double = 0
        public static let dashed = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-line-progress`.
    public enum lineProgress {
        public static let activeColor = "#19be6b"
        public static let inactiveColor = "#ececec"
        public static let percentage = 0
        public static let showText = true
        public static let height = 12
        public static let fromRight = false
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-cell`.
    public enum cell {
        public static let customClass = ""
        public static let title = ""
        public static let label = ""
        public static let value = ""
        public static let icon = ""
        public static let disabled = false
        public static let border = true
        public static let center = false
        public static let url = ""
        public static let linkType = "navigateTo"
        public static let clickable = false
        public static let isLink = false
        public static let required = false
        public static let rightIcon = "arrow-right"
        public static let arrowDirection = ""
        public static let iconStyle = UPStyle()
        public static let rightIconStyle = UPStyle()
        public static let titleStyle = UPStyle()
        public static let size = ""
        public static let stop = true
        public static let name: UPCellName = ""
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-cell-group`.
    public enum cellGroup {
        public static let customClass = ""
        public static let title = ""
        public static let border = true
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-checkbox`.
    public enum checkbox {
        public static let customClass = ""
        public static let name: UPCheckboxName = ""
        public static let shape = ""
        public static let size = ""
        public static let checked = false
        public static let disabled: UPCheckboxFlag = ""
        public static let activeColor = ""
        public static let inactiveColor = ""
        public static let iconSize = ""
        public static let iconColor = ""
        public static let label = ""
        public static let labelSize = ""
        public static let labelColor = ""
        public static let labelDisabled: UPCheckboxFlag = ""
        public static let usedAlone = false
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-checkbox-group`.
    public enum checkboxGroup {
        public static let customClass = ""
        public static let name = ""
        public static let value: [UPCheckboxName] = []
        public static let shape = "square"
        public static let disabled = false
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#c8c9cc"
        public static let size = "18"
        public static let placement = "row"
        public static let labelSize = "14"
        public static let labelColor = "#303133"
        public static let labelDisabled = false
        public static let iconColor = "#ffffff"
        public static let iconSize = "12"
        public static let iconPlacement = "left"
        public static let borderBottom = false
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-radio`.
    public enum radio {
        public static let customClass = ""
        public static let name: UPRadioName = ""
        public static let shape = ""
        public static let disabled: UPRadioFlag = ""
        public static let labelDisabled: UPRadioFlag = ""
        public static let activeColor = ""
        public static let inactiveColor = ""
        public static let iconSize = ""
        public static let labelSize = ""
        public static let label = ""
        public static let size = ""
        public static let color = ""
        public static let labelColor = ""
        public static let iconColor = ""
        /// Present in the upstream default config even though it is inherited
        /// from `u-radio-group` rather than declared as a radio prop.
        public static let placement = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-radio-group`.
    public enum radioGroup {
        public static let customClass = ""
        public static let value: UPRadioName = ""
        public static let disabled = false
        public static let shape = "circle"
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#c8c9cc"
        public static let name = ""
        public static let size = "18"
        public static let placement = "row"
        public static let label = ""
        public static let labelColor = "#303133"
        public static let labelSize = "14"
        public static let labelDisabled = false
        public static let iconColor = "#ffffff"
        public static let iconSize = "12"
        public static let borderBottom = false
        public static let iconPlacement = "left"
        public static let gap = "10px"
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-rate`.
    public enum rate {
        public static let customClass = ""
        public static let value: Double = 1
        public static let count: Double = 5
        public static let disabled = false
        public static let readonly = false
        public static let size: Double = 18
        public static let inactiveColor = ""
        public static let activeColor = ""
        public static let gutter: Double = 4
        public static let minCount: Double = 1
        public static let allowHalf = false
        public static let activeIcon = "star-fill"
        public static let inactiveIcon = "star"
        public static let touchable = true
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-number-box`.
    public enum numberBox {
        public static let customClass = ""
        public static let name = ""
        public static let value = UPNumberBoxValue.number(0)
        public static let min: Double = 1
        public static let max: Double = 9_007_199_254_740_991
        public static let step: Double = 1
        public static let integer = false
        public static let disabled = false
        public static let disabledInput = false
        public static let asyncChange = false
        public static let inputWidth: Double = 35
        public static let showMinus = true
        public static let showPlus = true
        public static let decimalLength: Int? = nil
        public static let longPress = true
        public static let color = ""
        public static let buttonWidth: Double = 30
        public static let buttonSize: Double = 30
        public static let buttonRadius = "0px"
        public static let bgColor = ""
        public static let disabledBgColor = ""
        public static let inputBgColor = ""
        public static let cursorSpacing: Double = 100
        public static let disableMinus = false
        public static let disablePlus = false
        public static let iconStyle = UPStyle()
        public static let miniMode = false
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-switch`.
    public enum `switch` {
        public static let customClass = ""
        public static let loading = false
        public static let disabled = false
        public static let size: Double = 25
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#ffffff"
        public static let dotActiveColor = "#ffffff"
        public static let dotInactiveColor = "#ffffff"
        public static let value: UPSwitchValue = false
        public static let activeValue: UPSwitchValue = true
        public static let inactiveValue: UPSwitchValue = false
        public static let asyncChange = false
        public static let space: Double = 0
        public static let customStyle = UPStyle()
    }

    public enum gap {
        public static let bgColor = "transparent"
        public static let height: Double = 20
        public static let marginTop: Double = 0
        public static let marginBottom: Double = 0
    }

    public enum loadingIcon {
        public static let show = true
        public static let color = "#909399"
        public static let textColor = "#909399"
        public static let vertical = false
        public static let mode = "spinner"
        public static let size: Double = 24
        public static let textSize: Double = 15
        public static let text = ""
        public static let timingFunction = "ease-in-out"
        public static let duration: Double = 1200
        public static let inactiveColor = ""
        /// 上游 `otherBorderColor`：`colorGradient(color, '#ffffff', 100)[80]`，
        /// 即往白色方向插值 80%。
        public static let inactiveLightenRatio: Double = 0.8
        /// 上游 `$u-loading-circle-border-width` / `-semicircle-border-width` 都是 2px。
        public static let borderWidth: CGFloat = 2
        /// 上游 `.__text { margin-left: 4px }`，竖排时改成 `margin: 6px 0 0`。
        public static let textSpacing: CGFloat = 4
        public static let verticalTextSpacing: CGFloat = 6
        /// 上游 spinner 模式固定 12 个点，逐个转 30°、透明度按 `1 - 0.0625 * (i - 1)` 递减。
        public static let spinnerDotCount = 12
        public static let spinnerDotStep: Double = 30
        public static let spinnerDotOpacityStep: Double = 0.0625
        /// 上游 `.__dot:before { width: 2px; height: 25%; border-radius: 40% }`。
        public static let spinnerDotWidth: CGFloat = 2
        public static let spinnerDotHeightRatio: CGFloat = 0.25
        /// 上游 `.__spinner { animation: u-rotate 1s linear infinite }`；
        /// circle / semicircle 才改用 `duration` 与 `timingFunction`。
        public static let spinnerRotationDuration: Double = 1000
    }

    public enum form {
        public static let errorType = "message"
        public static let borderBottom = true
        public static let labelPosition = "left"
        public static let labelWidth = "45px"
        public static let labelAlign = "left"
        public static let labelStyle = UPStyle()
    }

    public enum formItem {
        public static let label = ""
        public static let prop = ""
        /// `nil` preserves the enclosing `UPForm` value, matching uview-plus' empty default.
        public static let borderBottom: Bool? = nil
        public static let labelPosition = ""
        public static let labelWidth = ""
        public static let rightIcon = ""
        public static let leftIcon = ""
        public static let required = false
        public static let leftIconStyle = UPStyle()
        /// Native extension retained from the earlier implementation.
        public static let help = ""
    }

    public enum input {
        public static let prop = ""
        public static let value = ""
        public static let type = "text"
        public static let fixed = false
        public static let disabled = false
        public static let disabledColor = ""
        public static let clearable = false
        public static let onlyClearableOnFocused = true
        public static let password = false
        public static let maxlength: Int? = 140
        public static let placeholder = ""
        public static let placeholderClass = "input-placeholder"
        public static let placeholderStyle = UPStyle()
        public static let showWordLimit = false
        public static let confirmType = "done"
        public static let confirmHold = false
        public static let holdKeyboard = false
        public static let focus = false
        public static let autoBlur = false
        public static let disableDefaultPadding = false
        public static let cursor = -1
        public static let cursorSpacing: Double = 30
        public static let selectionStart = -1
        public static let selectionEnd = -1
        public static let adjustPosition = true
        public static let inputAlign = "left"
        public static let fontSize = "15px"
        public static let color = ""
        public static let prefixIcon = ""
        public static let prefixIconStyle = UPStyle()
        public static let suffixIcon = ""
        public static let suffixIconStyle = UPStyle()
        public static let border = "surround"
        public static let readonly = false
        public static let shape = "square"
        public static let ignoreCompositionEvent = true
        public static let cursorColor = "#53c21d"
        public static let passwordVisibilityToggle = true
        /// Existing native alias for upstream `showWordLimit`.
        public static let count = false
    }

    public enum textarea {
        public static let prop = ""
        public static let value = ""
        public static let placeholder = ""
        public static let placeholderClass = "textarea-placeholder"
        public static let placeholderStyle = UPStyle()
        public static let height: Double = 70
        public static let confirmType = "done"
        public static let disabled = false
        public static let count = false
        public static let focus = false
        public static let autoHeight = false
        public static let fixed = false
        public static let cursorSpacing: Double = 0
        public static let cursor = -1
        public static let showConfirmBar = true
        public static let selectionStart = -1
        public static let selectionEnd = -1
        public static let adjustPosition = true
        public static let disableDefaultPadding = false
        public static let holdKeyboard = false
        public static let maxlength: Int? = 140
        public static let border = "surround"
        public static let ignoreCompositionEvent = true
        /// Native extension retained from the earlier implementation.
        public static let readonly = false
    }

    public enum text {
        public static let type = ""
        public static let show = true
        public static let text = ""
        public static let prefixIcon = ""
        public static let suffixIcon = ""
        public static let mode = ""
        public static let href = ""
        public static let format = ""
        public static let call = false
        public static let openType = ""
        public static let bold = false
        public static let block = false
        public static let lines = ""
        public static let color = ""
        public static let size: Double = 15
        public static let iconStyle = UPStyle(["fontSize": "15px"])
        public static let decoration = "none"
        public static let margin: Double = 0
        public static let lineHeight = ""
        public static let align = "left"
        public static let wordWrap = "normal"
        public static let flex1 = false
    }


    /// Defaults for the SwiftUI counterpart of uview-plus `u-divider`.
    public enum divider {
        public static let dashed = false
        public static let hairline = true
        public static let dot = false
        public static let textPosition = "center"
        public static let text = ""
        public static let textSize: Double = 14
        public static let textColor = "#909399"
        public static let lineColor = "#dcdfe6"
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    public enum link {
        public static let color = "#2979ff"
        public static let fontSize: Double = 15
        public static let underLine = false
        public static let href = ""
        public static let mpTips = "链接已复制，请在浏览器打开"
        public static let lineColor = ""
        public static let text = ""
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    public enum tag {
        public static let type = "primary"
        public static let disabled = false
        public static let size = "medium"
        public static let shape = "square"
        public static let text = ""
        public static let bgColor = ""
        public static let color = ""
        public static let borderColor = ""
        public static let closeColor = "#C6C7CB"
        public static let name = ""
        public static let plainFill = false
        public static let plain = false
        public static let closable = false
        public static let show = true
        public static let icon = ""
        public static let iconColor = ""
        public static let textSize = ""
        public static let height = ""
        public static let padding = ""
        public static let borderRadius = ""
        public static let autoBgColor: Double = 0
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    public enum badge {
        public static let isDot = false
        public static let value = ""
        public static let modelValue: String? = nil
        public static let show = true
        public static let max = 999
        public static let type = "error"
        public static let showZero = false
        public static let bgColor: String? = nil
        public static let color: String? = nil
        public static let shape = "circle"
        public static let numberType = "overflow"
        public static let offset: [CGFloat] = []
        public static let inverted = false
        public static let absolute = false
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    /// Defaults for the SwiftUI counterpart of uview-plus `u-image`.
    public enum image {
        public static let src = ""
        public static let mode = "aspectFill"
        public static let width = "300"
        public static let height = "225"
        public static let shape = "square"
        public static let radius = "0"
        public static let lazyLoad = true
        public static let showMenuByLongpress = true
        public static let loadingIcon = "photo"
        public static let errorIcon = "error-circle"
        public static let showLoading = true
        public static let showError = true
        public static let fade = true
        public static let webp = false
        public static let duration = 500
        public static let bgColor = "#f3f4f6"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-card`.
    public enum card {
        public static let full = false
        public static let title = ""
        public static let titleColor = "#303133"
        public static let titleSize = "15px"
        public static let subTitle = ""
        public static let subTitleColor = "#909399"
        public static let subTitleSize = "13px"
        public static let border = true
        public static let index: UPCardIndex = ""
        public static let margin = "15px"
        public static let borderRadius = "8px"
        public static let headStyle = UPStyle()
        public static let bodyStyle = UPStyle()
        public static let footStyle = UPStyle()
        public static let headBorderBottom = true
        public static let footBorderTop = true
        public static let thumb = ""
        public static let thumbWidth = "30px"
        public static let thumbCircle = false
        public static let padding = "15px"
        public static let paddingHead = ""
        public static let paddingBody = ""
        public static let paddingFoot = ""
        public static let showHead = true
        public static let showFoot = true
        public static let boxShadow = "none"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-skeleton`.
    public enum skeleton {
        public static let loading = true
        public static let animate = true
        public static let rows = 0
        public static let rowsWidth = "100%"
        public static let rowsHeight = 18
        public static let title = true
        public static let titleWidth = "50%"
        public static let titleHeight = 18
        public static let avatar = false
        public static let avatarSize = 32
        public static let avatarShape = "circle"
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-empty`.
    public enum empty {
        public static let icon = ""
        public static let text = ""
        public static let textColor = "#c0c4cc"
        public static let textSize = "14"
        public static let iconColor = "#c0c4cc"
        public static let iconSize = "90"
        public static let mode = "data"
        public static let width = "160"
        public static let height = "160"
        public static let show = true
        public static let marginTop = "0"
    }

    public enum avatar {
        public static let src = ""
        public static let shape = "circle"
        public static let size: Double = 40
        public static let mode = "scaleToFill"
        public static let text = ""
        public static let bgColor = "#c0c4cc"
        public static let color = "#ffffff"
        public static let fontSize: Double = 18
        public static let icon = ""
        public static let mpAvatar = false
        public static let randomBgColor = false
        public static let defaultUrl = ""
        public static let colorIndex = ""
        public static let name = ""
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-avatar-group`.
    public enum avatarGroup {
        public static let urls: [UPAvatarGroupItem] = []
        public static let maxCount = 5
        public static let shape = "circle"
        public static let mode = "scaleToFill"
        public static let showMore = true
        public static let size: Double = 40
        public static let keyName = ""
        public static let gap: Double = 0.5
        public static let extraValue = 0
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }



    /// Defaults for the SwiftUI counterpart of uview-plus `u-loadmore`.
    public enum loadmore {
        public static let status = "loadmore"
        public static let bgColor = "transparent"
        public static let icon = true
        public static let fontSize = 14
        public static let iconSize = 17
        public static let color = "#606266"
        public static let loadingIcon = "spinner"
        public static let loadmoreText = "加载更多"
        public static let loadingText = "正在加载..."
        public static let nomoreText = "没有更多了"
        public static let isDot = false
        public static let iconColor = "#b7b7b7"
        public static let marginTop = 10
        public static let marginBottom = 10
        public static let height = "auto"
        public static let line = false
        public static let lineColor = "#E6E8EB"
        public static let dashed = false
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    /// Defaults for the SwiftUI counterpart of uview-plus `u-count-down`.
    public enum countDown {
        public static let time = 0
        public static let format = "HH:mm:ss"
        public static let autoStart = true
        public static let millisecond = false
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }


    /// Defaults for the SwiftUI counterpart of uview-plus `u-count-to`.
    public enum countTo {
        public static let startVal = 0
        public static let endVal = 0
        public static let duration = 2000
        public static let autoplay = true
        public static let decimals = 0
        public static let useEasing = true
        public static let decimal = "."
        public static let color = "#606266"
        public static let fontSize = 22
        public static let bold = false
        public static let separator = ""
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-code`.
    public enum code {
        public static let seconds = 60
        public static let startText = "获取验证码"
        public static let changeText = "X秒重新获取"
        public static let endText = "重新获取"
        public static let keepRunning = false
        public static let uniqueKey = ""
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-code-input`.
    public enum codeInput {
        public static let adjustPosition = true
        public static let maxlength = 6
        public static let dot = false
        public static let mode = "box"
        public static let hairline = false
        public static let space: Double = 10
        public static let value = ""
        public static let focus = false
        public static let bold = false
        public static let color = "#606266"
        public static let fontSize: Double = 18
        public static let size: Double = 35
        public static let disabledKeyboard = false
        public static let borderColor = "#c9cacc"
        public static let disabledDot = true
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-message-input`.
    public enum messageInput {
        public static let maxlength = 4
        public static let dotFill = false
        public static let mode = "box"
        public static let value = ""
        public static let breathe = true
        public static let focus = false
        public static let bold = false
        /// Upstream declares `fontSize` and `width` in rpx.
        public static let fontSize: Double = 60
        public static let width: Double = 80
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#606266"
        public static let disabledKeyboard = false
        /// Existing native-only shorthands retained for source compatibility.
        public static let disabled = false
        public static let error = false
    }

    /// Defaults for the SwiftUI counterparts of the legacy uview-plus table
    /// primitives `u-table` / `u-tr` / `u-th` / `u-td`.
    public enum table {
        public static let borderColor = "#e4e7ed"
        public static let align = "center"
        public static let padding = "5px 3px"
        public static let fontSize = "14px"
        public static let color = "#606266"
        public static let bgColor = "#ffffff"
        public static let thStyle = UPStyle()
        /// Upstream `u-th` defaults to an empty width, `u-td` to `auto`; both
        /// mean the column stretches.
        public static let thWidth = ""
        public static let tdWidth = "auto"
        public static let headerBgColor = "#f5f6f8"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-notice-bar`.
    public enum noticeBar {
        public static let direction = "row"
        public static let step = false
        public static let icon = "volume"
        public static let mode = ""
        public static let color = "#f9ae3d"
        public static let bgColor = "#fdf6ec"
        public static let speed: Double = 80
        public static let fontSize: Double = 14
        public static let duration: Double = 2000
        public static let disableTouch = true
        public static let url = ""
        public static let linkType = "navigateTo"
        public static let justifyContent = "flex-start"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-column-notice`.
    /// Note the shorter `duration` than `noticeBar`.
    public enum columnNotice {
        public static let icon = "volume"
        public static let mode = ""
        public static let color = "#f9ae3d"
        public static let bgColor = "#fdf6ec"
        public static let fontSize: Double = 14
        public static let speed: Double = 80
        public static let step = false
        public static let duration: Double = 1500
        public static let disableTouch = true
        public static let justifyContent = "flex-start"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-row-notice`.
    public enum rowNotice {
        public static let icon = "volume"
        public static let mode = ""
        public static let color = "#f9ae3d"
        public static let bgColor = "#fdf6ec"
        public static let fontSize: Double = 14
        public static let speed: Double = 80
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-keyboard`.
    public enum keyboard {
        public static let mode = "number"
        public static let dotDisabled = false
        public static let tooltip = true
        public static let showTips = true
        public static let tips = ""
        public static let showCancel = true
        public static let showConfirm = true
        public static let random = false
        public static let safeAreaInsetBottom = true
        public static let closeOnClickOverlay = true
        public static let show = false
        public static let overlay = true
        public static let zIndex: Double = 10075
        public static let cancelText = "取消"
        public static let confirmText = "确定"
        public static let autoChange = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-index-anchor`.
    public enum indexAnchor {
        public static let text = ""
        public static let color = "#606266"
        public static let size: Double = 14
        public static let bgColor = "#f1f1f1"
        public static let height: Double = 32
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-index-list`.
    public enum indexList {
        public static let inactiveColor = "#606266"
        public static let activeColor = "#5677fc"
        public static let indexList: [String] = []
        public static let sticky = true
        public static let customNavHeight: Double = 0
        public static let safeBottomFix = false
        public static let itemMargin = "0rpx"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-pdf-reader`.
    public enum pdfReader {
        public static let src = ""
        public static let height = "500px"
        public static let baseUrl = "https://uview-plus.jiangruyi.com/h5"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-notify`.
    public enum notify {
        public static let top: Double = 0
        public static let type = "primary"
        public static let color = "#ffffff"
        public static let bgColor = ""
        public static let message = ""
        public static let duration = 3_000
        public static let fontSize: Double = 15
        public static let safeAreaInsetTop = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-no-network`.
    ///
    /// Upstream ships `image` as an inline base64 PNG; the native default stays
    /// empty so the offline state falls back to a system symbol, and any custom
    /// source (remote URL, bundled asset or data URI) still renders as-is.
    public enum noNetwork {
        public static let tips = "哎呀，网络信号丢失"
        public static let zIndex = ""
        public static let image = ""
        /// 上游模板里的三段固定文案，来自 `i18n/locales/zh-Hans.js`：
        /// `up.noNetwork.pleaseCheck` / `up.common.settings` / `up.common.retry`。
        public static let pleaseCheckText = "请检查网络，或前往"
        public static let settingsText = "设置"
        public static let retryText = "重试"
        /// 上游 `retry()` 里两条 toast 文案：`up.noNetwork.connect` / `.disconnect`。
        public static let connectToast = "网络已连接"
        public static let disconnectToast = "无网络连接"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-read-more`.
    ///
    /// Upstream keeps `shadowStyle` inside `props.js` instead of the shared
    /// config because it relies on conditional compilation; the non-nvue branch
    /// is mirrored here.
    public enum readMore {
        public static let showHeight: Double = 400
        public static let toggle = false
        public static let closeText = "展开阅读全文"
        public static let openText = "收起"
        public static let color = "#2979ff"
        public static let fontSize: Double = 14
        public static let textIndent = "2em"
        public static let name = ""
        public static let shadowStyle = UPStyle([
            "backgroundImage": "linear-gradient(-180deg, rgba(255, 255, 255, 0) 0%, #fff 80%)",
            "paddingTop": "100px",
            "marginTop": "-100px"
        ])
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-swipe-action`.
    ///
    /// Upstream `swipeAction.js` only ships `autoClose`; `opendItem` is
    /// hard-coded to `false` inside `props.js` and never reaches the shared
    /// config, so it is mirrored here for parity with the rest of the props.
    public enum swipeAction {
        public static let autoClose = true
        public static let opendItem = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-swipe-action-item`.
    ///
    /// `options` reads `defProps.swipeActionItem.rightOptions` upstream, a key
    /// that does not exist in `swipeActionItem.js`, so the prop resolves to
    /// `undefined` there. The declared `options: []` default is used instead.
    public enum swipeActionItem {
        public static let show = false
        public static let closeOnClick = true
        public static let name = ""
        public static let disabled = false
        public static let threshold: CGFloat = 20
        public static let autoClose = true
        public static let scrolling = false
        public static let options: [UPSwipeAction] = []
        public static let duration: Double = 300
        /// 上游 `defaultButtonBgColor` 取 `--up-swipe-action-button-bg-color`，
        /// 浅色回落 `#C7C6CD`、暗色回落 `#4b5563`。
        public static let buttonBackgroundColor = "#c7c6cd"
        public static let darkButtonBackgroundColor = "#4b5563"
        /// 上游 `defaultButtonColor` 取 `--up-swipe-action-button-color`，回落白色。
        public static let buttonColor = "#ffffff"
        /// 上游 `.__wrapper { padding: 0 15px }`，设了 `borderRadius` 时改成 0。
        public static let buttonPadding: CGFloat = 15
        /// 上游内联 style 把文字与行高都设成 `item.style.fontSize ?: '16px'`。
        public static let buttonFontSize: CGFloat = 16
        /// 上游图标尺寸兜底 17，给了 `style.fontSize` 时取 `fontSize * 1.2`。
        public static let buttonIconSize: CGFloat = 17
        public static let buttonIconScale: CGFloat = 1.2
        /// 上游图标在有文字时右边留 2px。
        public static let buttonIconSpacing: CGFloat = 2
        /// 上游 `.__content` 底色取 `--up-card-bg-color`。
        public static let contentBackgroundColor = "#ffffff"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-guide`.
    ///
    /// `list` is declared as a plain Array upstream; the native surface types it
    /// as `[UPGuideStep]`. `zIndex` accepts `String | Number` upstream, so the
    /// numeric default doubles as the fallback for unparsable values.
    public enum guide {
        public static let show = false
        public static let list: [UPGuideStep] = []
        public static let storageKey = "up-guide-default"
        public static let once = true
        public static let showSkip = true
        public static let skipText = "跳过"
        public static let nextText = "下一步"
        public static let finishText = "立即体验"
        public static let indicator = true
        public static let bgColor = "#111111"
        public static let zIndex: Double = 10075
    }

}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-popover`.
    ///
    /// `props.js` 里只有 `registerComponentProps({ popover: {} })`，上游没有
    /// `popover.js` 配置文件，因此下面每个默认值都直接取 `props.js` 的字面量。
    /// `zIndex` 上游声明为 `Number | String`，数值默认值同时充当无法解析时的兜底。
    enum popover {
        public static let text = ""
        public static let color = "#333"
        public static let bgColor = "#f7f7f7"
        public static let popupBgColor = "#f7f7f7"
        public static let placement = "top"
        public static let triggerMode = "click"
        public static let show = false
        public static let zIndex: Double = 10070
        public static let forcePosition = UPStyle()
        public static let direction = "top"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-parse`.
    ///
    /// 上游同时存在两套声明：`props.js` 的 mixin 版与 `u-parse.vue` 内联的
    /// `props`。实际生效的是 `.vue` 内联声明（组件没有 `mixins: [props]`），
    /// 因此下面以 `.vue` 为准，`parse.js` 里 8 个字面量与 `.vue` 一致。
    ///
    /// 分歧点：`props.js` 把 `containerStyle` / `useAnchor` 默认成 `null`，
    /// `.vue` 则把 `containerStyle` 默认成 `''`；`scrollTable` / `selectable` /
    /// `useAnchor` 在 `.vue` 里只声明类型不给默认值，JS 下即 `undefined`（falsy），
    /// 所以原生侧取 `false`。`containerStyle` 上游是 CSS 字符串，原生沿用仓库
    /// 内既有的 `UPStyle` 表示法。
    enum parse {
        public static let containerStyle = UPStyle()
        public static let content = ""
        public static let copyLink = true
        public static let domain = ""
        public static let errorImg = ""
        public static let lazyLoad = false
        public static let loadingImg = ""
        public static let pauseVideo = true
        public static let previewImg = true
        public static let scrollTable = false
        public static let selectable = false
        public static let setTitle = true
        public static let showImgMenu = true
        public static let tagStyle: [String: String] = [:]
        public static let useAnchor = false
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-calendar-strip`。
    ///
    /// 取自 `calendarStrip.js`；`weekText` 上游走 `t('up.week.*')`，
    /// 中文包即「一 二 三 四 五 六 日」（周一开头）。`minDate` / `maxDate`
    /// 上游用 `0` 表示不限制，原生改用 `nil`，语义更直白。
    enum calendarStrip {
        public static let modelValue: Date? = nil
        public static let minDate: Date? = nil
        public static let maxDate: Date? = nil
        public static let color = "#3c9cff"
        public static let weekText = ["一", "二", "三", "四", "五", "六", "日"]
        public static let fullCalendar = true
        public static let fullCalendarProps: [String: String] = [:]
        public static let fullMonthNum = 24
        public static let pullDownThreshold: CGFloat = 40
        public static let collapseAfterSelect = true
        public static let readonly = false
        public static let showToday = true
        public static let monthFormat = ""
        public static let expandHint = "下拉展开月历"
        public static let collapseHint = "上拉收起月历"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-album`。
    ///
    /// 取自 `album.js`；`shape` / `radius` 上游是从 `defProps.image` 取的
    /// （`props.js` 里写的是 `defProps.image.shape` / `defProps.image.radius`），
    /// 因此这里直接引用 `UPConfig.image`，保持两处永远一致。
    enum album {
        public static let urls: [String] = []
        public static let keyName = ""
        public static let singleSize = 180
        public static let multipleSize = 70
        public static let space = 6
        public static let singleMode = "scaleToFill"
        public static let multipleMode = "aspectFill"
        public static let maxCount = 9
        public static let previewFullImage = true
        public static let rowCount = 3
        public static let showMore = true
        public static let shape = UPConfig.image.shape
        public static let radius = UPConfig.image.radius
        public static let autoWrap = false
        public static let unit = "px"
        public static let stop = true
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-tooltip`。
    ///
    /// 取自 `tooltip.js`。`popupBgColor` 默认空串，表示不覆盖 CSS 里的
    /// `.u-tooltip__wrapper__popup__list { background-color: #060607 }`。
    enum tooltip {
        public static let text = ""
        public static let copyText = ""
        public static let size: Double = 14
        public static let color = "#606266"
        public static let bgColor = "transparent"
        public static let direction = "top"
        public static let zIndex: Double = 10071
        public static let showCopy = true
        public static let buttons: [String] = []
        public static let overlay = true
        public static let showToast = true
        public static let popupBgColor = ""
        public static let triggerMode = "longpress"
        public static let forcePosition = UPStyle()
        public static let show = false
        public static let singleton = false
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-list`。
    ///
    /// 前 14 项取自 `list.js`；5 个 `refresher*` 上游没有进 `list.js`，
    /// 默认值直接写在 `props.js` 里，这里照抄。
    /// `height` / `width` 沿用上游的 `0`，语义是「不限制」：上游 `listStyle`
    /// 只在非 0 时写入尺寸，高度缺省回落到窗口高度。
    enum list {
        public static let showScrollbar = false
        public static let lowerThreshold: Double = 50
        public static let upperThreshold: Double = 0
        public static let scrollTop: Double = 0
        public static let offsetAccuracy: Double = 10
        public static let enableFlex = false
        public static let pagingEnabled = false
        public static let scrollable = true
        public static let scrollIntoView = ""
        public static let scrollWithAnimation = false
        public static let enableBackToTop = false
        public static let height: Double = 0
        public static let width: Double = 0
        public static let preLoadScreen: Double = 1
        public static let refresherEnabled = false
        public static let refresherThreshold: Double = 45
        public static let refresherDefaultStyle = "black"
        public static let refresherBackground = "#FFF"
        public static let refresherTriggered = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-list-item`。
    /// 取自 `listItem.js`，上游只有一个 `anchor`。
    enum listItem {
        public static let anchor = ""
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-upload`。
    ///
    /// 取自 `upload.js`。`maxSize` 上游是 `Number.MAX_VALUE`，原生取 `Int.max`。
    /// `beforeRead` / `afterRead` 在 `props.js` 里声明为 `Function`，默认 `null`，
    /// 原生用可选闭包表达，因此这里没有对应常量。
    enum upload {
        public static let accept = "image"
        public static let extensions: [String] = []
        public static let capture = ["album", "camera"]
        public static let compressed = true
        public static let camera = "back"
        public static let maxDuration: Double = 60
        public static let uploadIcon = "camera-fill"
        public static let uploadIconColor = "#D3D4D6"
        public static let useBeforeRead = false
        public static let previewFullImage = true
        public static let maxCount = 52
        public static let disabled = false
        public static let imageMode = "aspectFill"
        public static let name = ""
        public static let sizeType = ["original", "compressed"]
        public static let multiple = false
        public static let deletable = true
        public static let maxSize = Int.max
        public static let fileList: [UPUploadFile] = []
        public static let uploadText = ""
        public static let width: Double = 80
        public static let height: Double = 80
        public static let previewImage = true
        public static let autoDelete = false
        public static let autoUpload = false
        public static let autoUploadApi = ""
        public static let autoUploadAuthUrl = ""
        public static let autoUploadDriver = ""
        public static let autoUploadHeader: [String: String] = [:]
        public static let getVideoThumb = false
        public static let customAfterAutoUpload = false
        public static let videoPreviewObjectFit = "cover"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-calendar`。
    ///
    /// 取自 `calendar.js`；`title` / `startText` / `endText` / `confirmText` /
    /// `confirmDisabledText` / `forbidDaysToast` / `weekText` 上游走 `t(...)`，
    /// 这里取中文包的值。`minDate` / `maxDate` 上游用 `0` 表示不限制，原生用 `nil`。
    /// `maxCount` / `maxRange` 上游是 `Number.MAX_SAFE_INTEGER`，原生取 `Int.max`。
    enum calendar {
        public static let title = "日期选择"
        public static let showTitle = true
        public static let showSubtitle = true
        public static let mode = "single"
        public static let startText = "开始"
        public static let endText = "结束"
        public static let customList: [UPCalendarCustomDay] = []
        public static let color = "#3c9cff"
        public static let minDate: Date? = nil
        public static let maxDate: Date? = nil
        public static let defaultDate: [Date]? = nil
        public static let maxCount = Int.max
        public static let rowHeight: Double = 56
        public static let showLunar = false
        public static let showMark = true
        public static let confirmText = "确定"
        public static let confirmDisabledText = "确定"
        public static let show = false
        public static let closeOnClickOverlay = false
        public static let readonly = false
        public static let showConfirm = true
        public static let maxRange = Int.max
        public static let rangePrompt = ""
        public static let showRangePrompt = true
        public static let allowSameDay = false
        public static let rangeResultMode = "all"
        public static let enableTime = false
        public static let timePrecision = "minute"
        public static let defaultTime = ""
        public static let round: Double = 0
        public static let overlay = true
        public static let duration: Double = 300
        public static let overlayStyle = UPStyle()
        public static let overlayOpacity: Double = 0.5
        public static let zIndex: Double = 10075
        public static let safeAreaInsetBottom = true
        public static let safeAreaInsetTop = false
        public static let bgColor = ""
        public static let monthNum = 3
        public static let monthSwitch = false
        public static let showToday = true
        public static let todayColor = ""
        public static let weekText = ["一", "二", "三", "四", "五", "六", "日"]
        public static let forbidDays: [Date] = []
        public static let forbidDaysToast = "该日期已禁用"
        public static let monthFormat = ""
        public static let pageInline = false
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-markdown`。
    ///
    /// 上游没有 `markdown.js`，`props` 内联在 `u-markdown.vue` 里，这里照抄字面量。
    enum markdown {
        public static let content = ""
        public static let previewImg = true
        public static let copyLink = true
        public static let domain = ""
        public static let showLineNumber = false
        public static let theme = "light"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-agreement`。
    /// 上游只有两个跳转地址，同样内联在 `.vue` 里。
    enum agreement {
        public static let urlProtocol = "/pages/user_agreement/agreement/info?title=用户协议"
        public static let urlPrivacy = "/pages/user_agreement/agreement/info?title=隐私政策"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-color-picker`。
    enum colorPicker {
        public static let modelValue = "#ff0000"
        public static let commonColors: [String] = []
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-signature`。
    /// 上游 props 内联在 `.vue` 里：`width: 300`、`height: 200`、`bgColor: '#ffffff'`、
    /// `color: '#000000'`、`thickness: 3`、`showToolbar: true`。
    enum signature {
        public static let width: Double = 300
        public static let height: Double = 200
        public static let bgColor = "#ffffff"
        public static let color = "#000000"
        public static let thickness: Double = 3
        public static let showToolbar = true
        /// 上游 `data.presetColors`：工具栏色板的 8 个预设色。
        public static let presetColors = [
            "#000000", "#ff0000", "#00ff00", "#0000ff",
            "#ffff00", "#00ffff", "#ff00ff", "#ffffff"
        ]
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-cate-tab`。
    /// props 内联在 `.vue` 里：`mode: 'follow'`、`height: '100%'`、`tabList: []`、
    /// `tabKeyName: 'name'`、`itemKeyName: 'name'`、`current: 0`。
    enum cateTab {
        public static let mode = "follow"
        public static let height = "100%"
        public static let tabKeyName = "name"
        public static let itemKeyName = "name"
        public static let current = 0
        /// 上游 `.u-cate-tab__view { width: 200rpx }`。
        public static let menuWidth: Double = 200
        /// 上游 `.u-cate-tab__item { height: 110rpx }`。
        public static let itemHeight: Double = 110
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-select`。
    /// props 内联在 `.vue` 里；`itemColor` / `iconColor` 为空时上游取主题色。
    enum select {
        public static let maxHeight = "90vh"
        public static let overlay = true
        public static let overlayOpacity: Double = 0.01
        public static let overlayStyle = UPStyle()
        public static let duration: Double = 300
        public static let label = "选项"
        public static let keyName = "id"
        public static let labelName = "name"
        public static let showOptionsLabel = false
        public static let current = ""
        public static let zIndex: Double = 11000
        public static let itemColor = ""
        public static let iconColor = ""
        public static let iconSize = "13px"
        public static let disabled = false
        public static let border = false
        public static let optionsWidth = ""
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-virtual-list`。
    /// props 内联在 `.vue` 里：`itemHeight: 50`、`height: '100%'`、`buffer: 4`、
    /// `keyField: 'id'`、`scrollTop: 0`。
    enum virtualList {
        public static let itemHeight: Double = 50
        public static let height = "100%"
        public static let buffer = 4
        public static let keyField = "id"
        public static let scrollTop: Double = 0
        /// 上游量不到容器高度时的兜底值（`calculateDefaultHeight`）。
        public static let fallbackHeight: Double = 500
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-short-video`。
    /// props 内联在 `.vue` 里：`tabsList` 默认四项、`videoList: []`、
    /// `currentTab: 0`、`currentVideo: 0`。
    enum shortVideo {
        public static let tabsList = ["推荐", "关注", "朋友", "本地"]
        public static let videoList: [UPShortVideoItem] = []
        public static let currentTab = 0
        public static let currentVideo = 0
        /// 上游 `data.speedOptions`。
        public static let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-canvas`。
    /// props 内联在 `.vue` 里：`width: 300`、`height: 300`、`unit: 'px'`、
    /// `useRootHeightAndWidth: false`、`bgColor: '#ffffff'`、`disableScroll: false`；
    /// `canvasId` 上游是随机串。
    enum canvas {
        public static let width: Double = 300
        public static let height: Double = 300
        public static let unit = "px"
        public static let useRootHeightAndWidth = false
        public static let bgColor = "#ffffff"
        public static let disableScroll = false
        /// 上游 `data.fontSize` / `fontFamily` / `fontWeight` 的初始值。
        public static let fontSize: CGFloat = 12
        public static let fontFamily = "sans-serif"
        public static let fontWeight = "normal"
        /// 上游 `estimateTextWidth` 的三档系数：全角占一个字号、空白 0.28、半角 0.56。
        public static let fullWidthRatio: CGFloat = 1
        public static let whitespaceRatio: CGFloat = 0.28
        public static let halfWidthRatio: CGFloat = 0.56
        /// 上游 `setLineCap` / `setLineJoin` 的默认值。
        public static let lineCap = "round"
        public static let lineJoin = "round"
        /// 上游 `setTextAlign` / `setTextBaseline` 的默认值。
        public static let textAlign = "left"
        public static let textBaseline = "alphabetic"
        /// 上游 `toTempFilePath` 的默认导出格式。
        public static let fileType = "png"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-dragsort`。
    /// props 内联在 `.vue` 里：`initialList` 必填、`draggable: true`、
    /// `vibrate: true`、`direction: 'vertical'`、`columns: 3`。
    enum dragsort {
        public static let draggable = true
        public static let vibrate = true
        public static let direction = "vertical"
        public static let columns = 3
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-city-locate`。
    /// props 内联在 `.vue` 里：`indexList: ['🔥']`、`cityList` 默认五个热门城市、
    /// `locationType: 'wgs84'`、`currentCity: ''`、`nameKey: 'name'`。
    enum cityLocate {
        public static let indexList = ["🔥"]
        public static let locationType = "wgs84"
        public static let currentCity = ""
        public static let nameKey = "name"
        /// 上游 `cityList` 的默认值（一组热门城市）。
        public static let cityList: [[UPCity]] = [[
            UPCity(name: "北京", value: "beijing"),
            UPCity(name: "上海", value: "shanghai"),
            UPCity(name: "广州", value: "guangzhou"),
            UPCity(name: "深圳", value: "shenzhen"),
            UPCity(name: "杭州", value: "hangzhou")
        ]]
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-cropper`。
    ///
    /// 上游 `props` 用的是「对象简写」形式（`minScale: ''` 这种直接给默认值），
    /// 因此空串代表「未设置」，`created` 里再兜底：`quality → 0.9`、
    /// `minScale → 0.3`、`maxScale → 4`。
    enum cropper {
        public static let canScale = true
        public static let canRotate = true
        public static let canChangeSize = false
        public static let noTab = true
        public static let inner = false
        public static let fillColor = "transparent"
        public static let areaWidth = "300rpx"
        public static let areaHeight = "300rpx"
        public static let exportWidth = "260rpx"
        public static let exportHeight = "260rpx"
        /// `created` 里的兜底值。
        public static let quality: Double = 0.9
        public static let minScale: Double = 0.3
        public static let maxScale: Double = 4
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-goods-sku`。
    /// props 内联在 `.vue` 里：`goodsInfo: {}`、`skuTree: []`、`skuList: []`、
    /// `maxBuy: 999`、`confirmText: '确定'`、`closeable: true`、`pageInline: false`。
    enum goodsSku {
        public static let maxBuy = 999
        public static let confirmText = "确定"
        public static let closeable = true
        public static let pageInline = false
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-waterfall`。
    /// props 内联在 `.vue` 里：`modelValue: []`（required）、`addTime: 200`、
    /// `idKey: 'id'`、`columns: 2`、`columnsMin: 2`、`minColumnWidth: 230`。
    enum waterfall {
        public static let addTime: Double = 200
        public static let idKey = "id"
        public static let columns = "2"
        public static let columnsMin = 2
        public static let minColumnWidth: Double = 230
        /// 上游 `.u-column:not(:first-child) { margin-left: 10rpx }`。
        public static let columnGap = UPUnit.rpx(CGFloat(10))
        /// 上游 `getColumnsCount()` 在 auto 模式里写死的列间距估算值（约 7px）。
        public static let autoColumnGap: CGFloat = 7
        /// 上游 `data.windowWidth` 的初始值。
        public static let windowWidth: CGFloat = 375
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-lazy-load`。
    /// props 内联在 `.vue` 里：`index` 无默认值、`image: ''`、`imgMode: 'widthFix'`、
    /// `threshold: 100`（rpx）、`duration: 500`、`effect: 'ease-in-out'`、
    /// `isEffect: true`、`borderRadius: 0`（rpx）、`height: '200'`。
    ///
    /// 上游 `loadingImg` / `errorImg` 的默认值是两段约 4KB 的内联 base64 PNG（灰底占位图
    /// 与「加载失败」占位图）。原生不搬这两段 data URI：默认给空串，空串时改用
    /// `UPImage` 的图标占位（`loadingIcon` / `errorIcon`），需要像素级一致时由调用方自己传图。
    enum lazyLoad {
        public static let image = ""
        public static let imgMode = "widthFix"
        public static let loadingImg = ""
        public static let errorImg = ""
        public static let threshold: Double = 100
        public static let duration: Double = 500
        public static let effect = "ease-in-out"
        public static let isEffect = true
        public static let borderRadius: Double = 0
        public static let height = "200"
        /// 上游 `watch.isShow` 里为了拿到过渡效果而写死的 30ms 延时。
        public static let effectDelay: Double = 30
        /// 上游 `mounted` 里等元素挂载的 30ms 延时。
        public static let observeDelay: Double = 30
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-float-button`。
    /// props 内联在 `.vue` 里：`backgroundColor: '#2979ff'`、`color: '#fff'`、
    /// `width: '50px'`、`height: '50px'`、`borderColor: ''`（空串表示无边框）、
    /// `right: '30px'`、`top: ''`、`bottom: ''`、`isMenu: false`、`list: []`。
    enum floatButton {
        public static let backgroundColor = "#2979ff"
        public static let color = "#fff"
        public static let width = "50px"
        public static let height = "50px"
        public static let borderColor = ""
        public static let right = "30px"
        public static let top = ""
        public static let bottom = ""
        public static let isMenu = false
        /// 上游默认插槽里的图标名。
        public static let icon = "plus"
        /// 上游 `.show-list { transform: rotate(45deg) }`。
        public static let expandedRotation: Double = 45
        /// 上游 `.u-float-button__list > view { margin: 5px 0 }`。
        public static let itemSpacing: CGFloat = 10
        /// 上游 `.u-float-button { z-index: 999 }`。
        public static let zIndex: Double = 999
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-pull-refresh`。
    /// props 内联在 `.vue` 里：`refreshing: false`、`threshold: 80`、`damping: 0.4`、
    /// `maxDistance: 120`、`showLoadmore: false`、`loadmoreProps: { status: 'loadmore' }`、
    /// `useScrollView: true`、`enableBackToTop: false`、`lowerThreshold: 50`、`scrollTop: 0`。
    enum pullRefresh {
        public static let refreshing = false
        public static let threshold: CGFloat = 80
        public static let damping: CGFloat = 0.4
        public static let maxDistance: CGFloat = 120
        public static let showLoadmore = false
        public static let useScrollView = true
        public static let enableBackToTop = false
        public static let lowerThreshold: CGFloat = 50
        public static let scrollTop: CGFloat = 0
        /// 上游 `loadmoreProps` 默认只带 `status: 'loadmore'`。
        public static let loadmoreStatus = "loadmore"
        /// 上游默认插槽里的三段文案，来自 `i18n/locales/zh-Hans.js` 的
        /// `up.pullRefresh.pull` / `.release` / `.refreshing`。
        public static let pullText = "下拉刷新"
        public static let releaseText = "释放刷新"
        public static let refreshingText = "正在刷新"
        /// 上游默认插槽里的两个箭头图标与尺寸。
        public static let pullIcon = "arrow-downward"
        public static let releaseIcon = "arrow-upward"
        public static let iconSize = "26px"
        public static let textColor = "#606266"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-barcode`。
    /// props 内联在 `.vue` 里：`value` 必填、`format: 'auto'`、`width: 200`、
    /// `height: 80`、`displayValue: true`、`text: undefined`、`fontOptions: ''`、
    /// `font: 'monospace'`、`textAlign: 'center'`、`textPosition: 'bottom'`、
    /// `textMargin: 2`、`fontSize: 14`、`background: '#ffffff'`、
    /// `lineColor: '#000000'`、`margin: 10`、四个方向 margin `undefined`、
    /// `useCanvas: true`。
    enum barcode {
        public static let format = "auto"
        public static let width: Double = 200
        public static let height: Double = 80
        public static let displayValue = true
        public static let fontOptions = ""
        public static let font = "monospace"
        public static let textAlign = "center"
        public static let textPosition = "bottom"
        public static let textMargin: Double = 2
        /// prop 默认 14，但 `generateBarcode` 里那句 `this.fontSize || 20` 只在
        /// `fontSize` 为 0 这类假值时才生效，正常路径仍是 14。
        public static let fontSize: Double = 14
        public static let background = "#ffffff"
        public static let lineColor = "#000000"
        public static let margin: Double = 10
        public static let useCanvas = true
        /// `calculateCanvasSize` 里的两个下限。
        public static let minCanvasWidth: CGFloat = 100
        public static let minCanvasHeight: CGFloat = 60
        /// `drawBarcode` 里 `options.marginRight || 10` 的兜底值。
        public static let fallbackMarginRight: CGFloat = 10
        /// 错误文案，来自 `i18n/locales/zh-Hans.js` 的 `up.barcode.error`。
        public static let errorText = "生成条码失败"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-tree`。
    /// props 内联在 `.vue` 里：`data: []`、`props: { label, children, nodeKey, disabled }`、
    /// `nodeKey: ''`、`showCheckbox: false`、`defaultExpandAll: false`、
    /// `defaultExpandedKeys: []`、`defaultCheckedKeys: []`、`expandOnClickNode: true`、
    /// `checkOnClickNode: false`、`checkStrictly: false`、`accordion: false`、
    /// `highlightCurrent: false`、`currentNodeKey: ''`、`indent: 32`、`iconSize: 14`、
    /// `checkboxSize: 16`、`expandIcon: 'play-right-fill'`、`collapseIcon: 'arrow-down-fill'`。
    enum tree {
        public static let nodeKey = ""
        public static let showCheckbox = false
        public static let defaultExpandAll = false
        public static let expandOnClickNode = true
        public static let checkOnClickNode = false
        public static let checkStrictly = false
        public static let accordion = false
        public static let highlightCurrent = false
        public static let currentNodeKey = ""
        public static let indent = "32"
        public static let iconSize = "14"
        public static let checkboxSize = "16"
        public static let expandIcon = "play-right-fill"
        public static let collapseIcon = "arrow-down-fill"
        /// `props` 的四个字段名默认值。
        public static let labelKey = "label"
        public static let childrenKey = "children"
        public static let propsNodeKey = "id"
        public static let disabledKey = "disabled"
        /// `getIndentValue` 里没写单位时的兜底单位。
        public static let indentUnit = "rpx"
        /// `switcherColor` 取 `--up-content-color`。
        public static let switcherColor = "#606266"
        /// `.u-tree-node--current .u-tree-node__content` 的高亮底色。
        public static let currentBackgroundColor = "#ecf5ff"
        /// `.u-tree-node--disabled { opacity: 0.55 }`。
        public static let disabledOpacity: Double = 0.55
        /// `.u-tree-node__content { min-height: 72rpx }`。
        public static let nodeMinHeight = UPUnit.rpx(CGFloat(72))
        /// `.u-tree-node__switcher { width/height: 36rpx }`。
        public static let switcherSize = UPUnit.rpx(CGFloat(36))
        /// `.u-tree { font-size: 28rpx }`。
        public static let fontSize = UPUnit.rpx(CGFloat(28))
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-qrcode`。
    /// props 内联在 `.vue` 里：`cid` 是随机串、`size: 200`、`unit: 'px'`、`show: true`、
    /// `val: ''`、`background: '#ffffff'`、`foreground: '#000000'`、`pdground: '#000000'`、
    /// `icon: ''`、`iconSize: 40`、`lv: 3`、`quietZone: 0`、`onval: true`、
    /// `loadMake: true`、`usingComponents: true`、`showLoading: true`、
    /// `loadingText: '生成中'`、`allowPreview: false`、`useRootHeightAndWidth: false`。
    enum qrcode {
        public static let size: Double = 200
        public static let unit = "px"
        public static let show = true
        public static let val = ""
        public static let background = "#ffffff"
        public static let foreground = "#000000"
        public static let pdground = "#000000"
        public static let icon = ""
        public static let iconSize: Double = 40
        /// `lv` 是 `RS_BLOCK_TABLE` 的纠错档位下标：0=L、1=M、2=Q、3=H。
        public static let lv = 3
        public static let quietZone = 0
        public static let onval = true
        public static let loadMake = true
        public static let usingComponents = true
        public static let showLoading = true
        public static let loadingText = "生成中"
        public static let allowPreview = false
        public static let useRootHeightAndWidth = false
        /// `_makeCode` 里内容为空时的 toast 文案。
        public static let emptyToast = "二维码内容不能为空"
        /// `_saveCode` 成功后的 toast 文案。
        public static let savedToast = "二维码保存成功"
        /// `.u-qrcode__loading { background-color: #f7f7f7 }`。
        public static let loadingBackgroundColor = "#f7f7f7"
        /// `qrcode.js` 里内嵌图标的圆角与描边宽度。
        public static let iconCornerRadius: CGFloat = 2
        public static let iconBorderWidth: CGFloat = 6
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-action-sheet-data`。
    /// props 内联在 `.vue` 里：`modelValue: ''`、`title: ''`、`description: ''`、
    /// `options: []`、`valueKey: 'value'`、`labelKey: 'name'`。
    ///
    /// 注意 `labelKey` 默认是 `'name'`（不是 `'label'`），而同类的 `u-picker-data`
    /// 的 `valueKey` 默认是 `'id'`，两者不一致，照抄。
    enum actionSheetData {
        public static let modelValue = ""
        public static let title = ""
        public static let description = ""
        public static let valueKey = "value"
        public static let labelKey = "name"
        /// 上游触发器里那个 `up-input` 固定 `disabled` + `disabledColor="#ffffff"` + `border="none"`。
        public static let disabledColor = "#ffffff"
        public static let border = "none"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-dropdown`。
    /// 来自 `u-dropdown/props.js`：`activeColor: '#2979ff'`、`inactiveColor: '#606266'`、
    /// `closeOnClickMask: true`、`closeOnClickSelf: true`、`duration: 300`、`height: 40`、
    /// `borderBottom: false`、`titleSize: 14`、`borderRadius: 0`、
    /// `menuIcon: 'arrow-down'`、`menuIconSize: 14`。
    enum dropdown {
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#606266"
        public static let closeOnClickMask = true
        public static let closeOnClickSelf = true
        public static let duration = 300
        public static let height = "40"
        public static let borderBottom = false
        public static let titleSize = "14"
        public static let borderRadius = "0"
        public static let menuIcon = "arrow-down"
        public static let menuIconSize = "14"
        /// 上游 `data.current` 的“未展开”哨兵值（注释里说明小程序不能用 false/''）。
        public static let noneIndex = 99_999
        /// 上游 `menuDisabledColor` 取 `--up-disabled-color`。
        public static let menuDisabledColor = "#c0c4cc"
        /// 上游 `.u-dropdown__content__mask { background: rgba(0,0,0,.3) }`。
        public static let maskOpacity: Double = 0.3
        /// 上游 `.u-dropdown__menu__item__arrow--rotate { transform: rotate(180deg) }`。
        public static let arrowRotation: Double = 180
        /// 上游 `.u-dropdown__menu__item__arrow { margin-left: 6rpx }`。
        public static let arrowSpacing = UPUnit.rpx(CGFloat(6))
        /// 量不到可用高度时下拉面板遮罩的兜底高度。
        public static let fallbackContentHeight: CGFloat = 600
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-dropdown-item`。
    /// 来自 `u-dropdown-item/props.js`：`modelValue: ''`、`title: ''`、`options: []`、
    /// `disabled: false`、`height: 'auto'`、`closeOnClickOverlay: true`。
    enum dropdownItem {
        public static let modelValue = ""
        public static let title = ""
        public static let disabled = false
        public static let height = "auto"
        public static let closeOnClickOverlay = true
        /// 上游选中项右侧的对勾图标与尺寸。
        public static let checkedIcon = "checkbox-mark"
        public static let checkedIconSize = "32"
        /// 上游 `.u-dropdown-item__scroll { background: var(--up-card-bg-color, #ffffff) }`。
        public static let backgroundColor = "#ffffff"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-cascader`。
    /// props 内联在 `.vue` 里：`show: false`、`data: []`、`modelValue: []`、
    /// `valueKey: 'value'`、`labelKey: 'label'`、`childrenKey: 'children'`、
    /// `maskCloseAble: true`、`zIndex: 0`、`autoClose: false`、
    /// `headerDirection: 'row'`、`optionsCols: 2`、`closeable: true`。
    enum cascader {
        public static let valueKey = "value"
        public static let labelKey = "label"
        public static let childrenKey = "children"
        public static let maskCloseAble = true
        public static let zIndex: Double = 0
        public static let autoClose = false
        public static let headerDirection = "row"
        public static let optionsCols = 2
        public static let closeable = true
        /// 上游 `genTabsList` 里的占位标题。
        public static let placeholderTabName = "请选择"
        /// 上游 `uZIndex`：`zIndex` 为 0 时回落 `$u.zIndex.popup`。
        public static let popupZIndex: Double = 10075
        /// 上游 `.area-box { height: 800rpx }`。
        public static let paneHeight = UPUnit.rpx(CGFloat(800))
        /// 上游 `levelPaneStyle` 取 `--up-bg-color`。
        public static let paneBackgroundColor = "#f7f7f7"
        /// 上游选中项右侧的对勾图标与尺寸。
        public static let checkedIcon = "checkbox-mark"
        public static let checkedIconSize = "17"
        /// 上游按钮区文案来自 `up.common.cancel` / `up.common.confirm`。
        public static let cancelText = "取消"
        public static let confirmText = "确定"
        /// 上游 `optionsCols == 2` 时每列占 33.33%。
        public static let twoColumnRatio: CGFloat = 1.0 / 3.0
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-coupon`。
    /// props 内联在 `.vue` 里：`amount: ''`、`unit: '￥'`、`unitPosition: 'left'`、
    /// `limit: ''`、`title: '优惠券'`、`desc: ''`、`time: ''`、`actionText: '使用'`、
    /// `shape: 'coupon'`、`size: 'medium'`、`circle: false`、`disabled: false`、
    /// `bgColor: ''`、`color: ''`、`type: ''`。
    enum coupon {
        public static let amount = ""
        public static let unit = "￥"
        public static let unitPosition = "left"
        public static let limit = ""
        public static let title = "优惠券"
        public static let desc = ""
        public static let time = ""
        public static let actionText = "使用"
        public static let shape = "coupon"
        public static let size = "medium"
        public static let circle = false
        public static let disabled = false
        public static let bgColor = ""
        public static let color = ""
        public static let type = ""
        /// 上游 `.up-coupon` 的默认底色与圆角。
        public static let defaultBackground = "#ffebf0"
        public static let cornerRadius = UPUnit.rpx(CGFloat(16))
        /// 上游 `--disabled { opacity: 0.5 }`。
        public static let disabledOpacity: Double = 0.5
        /// 上游三档尺寸的高度：160 / 180 / 220 rpx。
        public static let smallHeight = UPUnit.rpx(CGFloat(160))
        public static let mediumHeight = UPUnit.rpx(CGFloat(180))
        public static let largeHeight = UPUnit.rpx(CGFloat(220))
        /// 上游 `dotCount`：按尺寸给出的锯齿数量（8 / 10 / 12）。
        public static let smallDotCount = 8
        public static let mediumDotCount = 10
        public static let largeDotCount = 12
        /// 上游 `--coupon` 左右两个 48rpx 的白色半圆缺口。
        public static let notchSize = UPUnit.rpx(CGFloat(48))
        /// 上游 `__amount-value` / `-unit` / `-limit` 的字号。
        public static let amountFontSize = UPUnit.rpx(CGFloat(56))
        public static let unitFontSize = UPUnit.rpx(CGFloat(24))
        public static let limitFontSize = UPUnit.rpx(CGFloat(24))
        /// 上游 `__info-title` / `-desc` / `-time` 的字号。
        public static let titleFontSize = UPUnit.rpx(CGFloat(32))
        public static let descFontSize = UPUnit.rpx(CGFloat(24))
        public static let timeFontSize = UPUnit.rpx(CGFloat(20))
        /// 无 `type` 时金额是纯红色（上游写死 `color: red`）。
        public static let amountColor = "#ff0000"
        /// 上游 `__amount` 右侧那条虚线的颜色：无 type 用 #ccc，有 type 用 #eee。
        public static let dashColor = "#cccccc"
        public static let dashColorOnType = "#eeeeee"
        /// 上游 `envelope` 顶部那条 20rpx 斜纹与绳子的渐变端色。
        public static let ropeStartColor = "#ffd000"
        public static let ropeEndColor = "#ffa000"
        public static let envelopeStripeHeight = UPUnit.rpx(CGFloat(20))
        /// 上游内置四个主题渐变的端色。
        public static let primaryGradient = ["#43afff", "#3b8cff"]
        public static let successGradient = ["#67dda9", "#19be6b"]
        public static let warningGradient = ["#ff9739", "#ff6a39"]
        public static let errorGradient = ["#ff7070", "#ff4747"]
        /// 上游默认 action 插槽里那个 `up-tag` 的配色。
        public static let tagBgColor = "#eb433d"
        public static let tagBorderColorOnType = "#eeeeee"
        public static let tagBorderRadius = "6px"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-choose`。
    /// props 内联在 `.vue` 里：`options: []`、`modelValue: false`、`type: 'radio'`、
    /// `itemWidth: 'auto'`、`itemHeight: '50px'`、`itemPadding: '8px'`、
    /// `labelName: 'title'`、`valueName: 'value'`、`customClick: false`、`wrap: true`。
    enum choose {
        public static let type = "radio"
        public static let itemWidth = "auto"
        public static let itemHeight = "50px"
        public static let itemPadding = "8px"
        public static let labelName = "title"
        public static let valueName = "value"
        public static let customClick = false
        public static let wrap = true
        /// 上游默认插槽里的 `up-tag` 固定 `size="large"`，激活项实心、其余描边。
        public static let tagSize = "large"
        public static let activeType = "primary"
        public static let inactiveType = "info"
        /// 上游 `.up-choose ::v-deep .up-tag { font-weight: 600 }`。
        public static let fontWeight: Double = 600
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-sticky`。
    /// 来自 `libs/config/props/sticky.js`：`offsetTop: 0`、`customNavHeight: 0`、
    /// `disabled: false`、`bgColor: 'transparent'`、`zIndex: ''`、`index: ''`。
    ///
    /// `customNavHeight` 只有 H5 端默认 44（自定义导航栏高度），其他端是 0。
    enum sticky {
        public static let offsetTop = "0"
        public static let customNavHeight = "0"
        public static let disabled = false
        public static let bgColor = "transparent"
        public static let zIndex = ""
        public static let index = ""
        /// H5 端 `customNavHeight` 的默认值。
        public static let h5CustomNavHeight: CGFloat = 44
        /// 上游 `uZindex`：`zIndex` 为假值时回落 `zIndex.sticky`。
        public static let fallbackZIndex: Double = 970
        /// 上游 `observeContent()` 里 IntersectionObserver 的 thresholds。
        public static let observerThresholds: [Double] = [0.95, 0.98, 1]
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-scroll-list`。
    /// 来自 `libs/config/props/scrollList.js`：`indicatorWidth: 50`、
    /// `indicatorBarWidth: 20`、`indicator: true`、`indicatorColor: '#f2f2f2'`、
    /// `indicatorActiveColor: '#3c9cff'`、`indicatorStyle: ''`。
    enum scrollList {
        public static let indicatorWidth = "50"
        public static let indicatorBarWidth = "20"
        public static let indicator = true
        public static let indicatorColor = "#f2f2f2"
        public static let indicatorActiveColor = "#3c9cff"
        /// 上游 `.u-scroll-list { padding-bottom: 10px }`。
        public static let paddingBottom: CGFloat = 10
        /// 上游 `.u-scroll-list__indicator { margin-top: 15px }`。
        public static let indicatorMarginTop: CGFloat = 15
        /// 上游 `.__indicator__line` 与 `.__bar` 的高度与圆角。
        public static let indicatorHeight: CGFloat = 4
        public static let indicatorCornerRadius: CGFloat = 100
        /// 上游 CSS 里 `.__line` 写死 60px 宽、`.__bar` 写死 20px，
        /// 但内联 style 会用 `indicatorWidth` / `indicatorBarWidth` 覆盖它们。
        public static let cssLineWidth: CGFloat = 60
        public static let cssBarWidth: CGFloat = 20
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-steps`。
    /// 来自 `libs/config/props/steps.js`：`direction: 'row'`、`current: 0`、
    /// `activeColor: '#3c9cff'`、`inactiveColor: '#969799'`、`activeIcon: ''`、
    /// `inactiveIcon: ''`、`dot: false`。
    enum steps {
        public static let direction = "row"
        public static let current = "0"
        public static let activeColor = "#3c9cff"
        public static let inactiveColor = "#969799"
        public static let activeIcon = ""
        public static let inactiveIcon = ""
        public static let dot = false
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-steps-item`。
    /// 来自 `libs/config/props/stepsItem.js`：`title: ''`、`desc: ''`、
    /// `iconSize: 17`、`error: false`；`itemStyle` 内联在 `props.js` 里默认 `{}`。
    enum stepsItem {
        public static let title = ""
        public static let desc = ""
        public static let iconSize = "17"
        public static let error = false
        /// 上游 `.__wrapper` 与 `.__circle` 都是 20×20，`.__dot` 是 10×10。
        public static let wrapperSize: CGFloat = 20
        public static let circleSize: CGFloat = 20
        public static let dotSize: CGFloat = 10
        /// 上游 `.__circle` 的 1pt 边框与 `.__circle__text` 的 11pt 字号。
        public static let circleBorderWidth: CGFloat = 1
        public static let circleTextFontSize: CGFloat = 11
        /// 上游 finish/error 态图标固定 `size="12"`。
        public static let statusIconSize = "12"
        /// 上游 `.__line` 在 row 时 `top: 10px; height: 1px`，column 时 `left: 10px; width: 1px`。
        public static let lineThickness: CGFloat = 1
        public static let lineOffset: CGFloat = 10
        /// 上游 `contentStyle` 的两个间距档：dot 时 2px、否则 6px。
        public static let dotContentSpacing: CGFloat = 2
        public static let circleContentSpacing: CGFloat = 6
        /// 上游 `.__content--column { margin-left: 6px }`。
        public static let columnContentMarginLeft: CGFloat = 6
        /// 上游 `.u-steps-item--column { padding-bottom: 5px }`。
        public static let columnPaddingBottom: CGFloat = 5
        /// 上游标题 `lineHeight="20px"`，激活项 14pt/`main`、其余 13pt/`content`。
        public static let titleLineHeight: CGFloat = 20
        public static let activeTitleFontSize: CGFloat = 14
        public static let inactiveTitleFontSize: CGFloat = 13
        /// 上游描述固定 `type="tips" size="12"`。
        public static let descFontSize: CGFloat = 12
        /// 上游 `activeStepTextColor` 取 `--up-white`。
        public static let activeStepTextColor = "#ffffff"
        /// 上游 `.__wrapper` 底色取 `--up-card-bg-color`。
        public static let wrapperBackgroundColor = "#ffffff"
        /// 上游 `statusColor` 的 error 分支取 `libs/config/color.js` 的 `color.error`。
        public static let errorColor = "#f56c6c"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-swiper`。
    /// 来自 `libs/config/props/swiper.js`。
    enum swiper {
        public static let indicator = false
        public static let indicatorActiveColor = "#FFFFFF"
        public static let indicatorInactiveColor = "rgba(255, 255, 255, 0.35)"
        public static let indicatorMode = "line"
        public static let autoplay = true
        public static let current = 0
        public static let currentItemId = ""
        public static let interval = 3000
        public static let duration = 300
        public static let circular = false
        public static let vertical = false
        public static let previousMargin = "0"
        public static let nextMargin = "0"
        public static let acceleration = false
        public static let displayMultipleItems = 1
        public static let easingFunction = "default"
        public static let keyName = "url"
        public static let imgMode = "aspectFill"
        public static let height = "130"
        public static let bgColor = "#f3f4f6"
        public static let radius = "4"
        public static let loading = false
        public static let showTitle = false
        /// 上游 `itemStyle` 里非当前项的缩放系数（仅在同时设了前后边距时生效）。
        public static let sideItemScale: Double = 0.92
        /// 上游 `.__title` 的高度、字号与半透明底。
        public static let titleHeight = UPUnit.rpx(CGFloat(80))
        public static let titleFontSize = UPUnit.rpx(CGFloat(28))
        public static let titleBackgroundColor = "rgba(0, 0, 0, 0.3)"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-swiper-indicator`。
    /// 来自 `libs/config/props/swiperIndicator.js`：`length: 0`、`current: 0`、
    /// `indicatorActiveColor: ''`、`indicatorInactiveColor: ''`、`indicatorMode: 'line'`。
    enum swiperIndicator {
        public static let length = "0"
        public static let current = "0"
        public static let indicatorActiveColor = ""
        public static let indicatorInactiveColor = ""
        public static let indicatorMode = "line"
        /// 上游 `data.lineWidth`：线型指示器每段的宽度。
        public static let lineWidth: CGFloat = 22
        /// 上游 `.--line { height: 4px }`。
        public static let lineHeight: CGFloat = 4
        /// 上游 `.__dot` 5×5、`margin: 0 4px`，激活时宽 12。
        public static let dotSize: CGFloat = 5
        public static let dotSpacing: CGFloat = 4
        public static let activeDotWidth: CGFloat = 12
        /// 上游 `.--line__bar` 的默认底色（内联 style 会用 `indicatorActiveColor` 覆盖）。
        public static let barColor = "#FFFFFF"
    }
}

public extension UPConfig {
    /// Defaults for the SwiftUI counterpart of uview-plus `u-car-keyboard`。
    /// props 内联在 `props.js` 里：`random: false`、`autoChange: false`。
    enum carKeyboard {
        public static let random = false
        public static let autoChange = false
        /// 上游 `areaList` / `engKeyBoardList` 都按 10/10/10/6 切成四行。
        public static let rowSizes = [10, 10, 10, 6]
        /// 上游 `carInputClick` 里 `autoChange` 的切档延时。
        public static let autoChangeDelay: Double = 200
        /// 上游 `backspaceClick` 里长按连删的定时器间隔。
        public static let backspaceRepeatInterval: Double = 250
        /// 上游 `$u-car-keyboard-button-inner-width` 与 `-button-height`。
        public static let keyWidth = UPUnit.rpx(CGFloat(64))
        public static let keyHeight = UPUnit.rpx(CGFloat(80))
        /// 上游 `$u-car-keyboard-special-button-width`：中/英 与退格键更宽。
        public static let specialKeyWidth = UPUnit.rpx(CGFloat(134))
        /// 上游 `$u-car-keyboard-button-border-radius` 与按键字号。
        public static let keyCornerRadius: CGFloat = 4
        public static let keyFontSize: CGFloat = 16
        /// 上游 `$u-car-keyboard-line-font-size`：中/英 之间那个斜杠。
        public static let separatorFontSize: CGFloat = 15
        /// 上游 `$u-car-keyboard-button-inner-margin: 8rpx 5rpx`。
        public static let keySpacing = UPUnit.rpx(CGFloat(10))
        public static let rowSpacing = UPUnit.rpx(CGFloat(16))
        /// 上游 `$u-car-keyboard-background-color` 取 `--up-bg-color`（浅色 rgb(224,228,230)）。
        public static let backgroundColor = "#e0e4e6"
        /// 上游 `$u-car-keyboard-u-hover-class-background-color`，也是两个功能键的底色。
        public static let functionKeyColor = "#bbbcc6"
        /// 上游退格图标固定 `size="28"`。
        public static let backspaceIconSize = "28"
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-number-keyboard`。
    /// props 内联在 `props.js` 里：`mode: 'number'`、`dotDisabled: false`、`random: false`。
    enum numberKeyboard {
        public static let mode = "number"
        public static let dotDisabled = false
        public static let random = false
        /// 上游 `$u-number-keyboard-button-width` 与 `-button-height`。
        public static let keyWidth = UPUnit.rpx(CGFloat(222))
        public static let keyHeight = UPUnit.rpx(CGFloat(90))
        /// 上游 `itemStyle`：非乱序 + number 模式 + 隐藏小数点时，第 10 键占双格。
        public static let wideKeyWidth = UPUnit.rpx(CGFloat(464))
        /// 上游 `$u-number-keyboard-button-margin: 4px 6rpx`。
        public static let keySpacing = UPUnit.rpx(CGFloat(12))
        public static let rowSpacing: CGFloat = 8
        /// 上游 `$u-number-keyboard-button-border-*-radius` 四角都是 4px。
        public static let keyCornerRadius: CGFloat = 4
        /// 上游 `$u-number-keyboard-text-font-size` 与 `-font-weight`。
        public static let keyFontSize: CGFloat = 20
        /// 上游 `$u-number-keyboard-background-color` 取 `--up-bg-color`。
        public static let backgroundColor = "#e0e4e6"
        /// 上游 `--gray` 取 `--up-border-color`（浅色 rgb(200,202,210)）。
        public static let grayKeyColor = "#c8cad2"
        /// 上游退格图标固定 `size="28"`。
        public static let backspaceIconSize = "28"
        /// 上游 `backspaceClick` 的连删定时器间隔。
        public static let backspaceRepeatInterval: Double = 250
        /// 上游一行三个按键。
        public static let columnCount = 3
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-slider`。
    /// 来自 `libs/config/props/slider.js`。
    enum slider {
        public static let value: Double = 0
        public static let blockSize: Double = 18
        public static let min: Double = 0
        public static let max: Double = 100
        public static let step: Double = 1
        public static let activeColor = "#2979ff"
        public static let inactiveColor = "#c0c4cc"
        public static let blockColor = "#ffffff"
        public static let showValue = false
        public static let disabled = false
        public static let useNative = false
        public static let height = ""
        public static let vertical = false
        public static let size = "2px"
        public static let length = "auto"
        /// 上游 `.u-slider-inner { padding: 10px 18px; border-radius: 999px }`。
        public static let innerVerticalPadding: CGFloat = 10
        public static let innerHorizontalPadding: CGFloat = 18
        public static let trackCornerRadius: CGFloat = 999
        /// 上游 `.__button { box-shadow: 0 1px 2px rgba(0,0,0,.5); transform: scale(0.9) }`。
        public static let blockShadowRadius: CGFloat = 2
        public static let blockShadowOffsetY: CGFloat = 1
        public static let blockScale: Double = 0.9
        /// 上游 `.__base { background-color: #ebedf0 }`（会被内联的 `inactiveColor` 覆盖）。
        public static let baseColor = "#ebedf0"
        /// 上游 `.__gap { transition: width 0.2s }`。
        public static let gapAnimationDuration: Double = 0.2
        /// 上游 `.__show-value { margin: 10px 18px 10px 0 }`。
        public static let showValueSpacing: CGFloat = 18
        /// 上游 `.__show-range-value { font-size: 12px; line-height: 12px }`。
        public static let rangeValueFontSize: CGFloat = 12
        /// 上游 `innerStyleCpu`：区间 + showValue 时容器要多留 24px 放两个数值。
        public static let rangeValueExtraSpace: CGFloat = 24
        /// 上游 `--disabled { opacity: 0.5 }`。
        public static let disabledOpacity: Double = 0.5
    }

    /// Defaults for the SwiftUI counterpart of uview-plus `u-pagination`。
    /// props 内联在 `.vue` 里：`currentPage: 1`、`pageSize: 10`、`total: 0`、
    /// `prevText: ''`、`nextText: ''`、`buttonBgColor: '#f5f7fa'`、
    /// `buttonBorderColor: '#dcdfe6'`、`pageSizes: [10,20,30,40,50]`、
    /// `layout: 'prev, pager, next'`、`hideOnSinglePage: false`。
    enum pagination {
        public static let currentPage = 1
        public static let pageSize = 10
        public static let total = 0
        public static let prevText = ""
        public static let nextText = ""
        public static let buttonBgColor = "#f5f7fa"
        public static let buttonBorderColor = "#dcdfe6"
        public static let pageSizes = [10, 20, 30, 40, 50]
        public static let layout = "prev, pager, next"
        public static let hideOnSinglePage = false
        /// 上游 `prevText` / `nextText` 为空时渲染的两个箭头图标。
        public static let prevIcon = "arrow-left"
        public static let nextIcon = "arrow-right"
        /// 上游 `.u-pagination { font-size: 14px; color: #606266 }`。
        public static let fontSize: CGFloat = 14
        public static let textColor = "#606266"
        /// 上游 `.u-pagination-item.active` 的底色是 `#409eff`、文字白色。
        public static let activeColor = "#409eff"
        /// 上游按钮与页码的圆角、内边距与外边距。
        public static let cornerRadius: CGFloat = 4
        public static let buttonPadding: CGFloat = 4
        public static let buttonSpacing: CGFloat = 3
        public static let itemSpacing: CGFloat = 2
        public static let itemHorizontalPadding: CGFloat = 8
        /// 上游 `.u-pagination-total` / `-sizes { margin-right: 10px }`。
        public static let sectionSpacing: CGFloat = 10
        /// 上游 `.disabled { opacity: 0.5 }`。
        public static let disabledOpacity: Double = 0.5
        /// 上游 `normalizedPageSizes` 的标签模板：`${size}条/页`。
        public static let pageSizeLabelSuffix = "条/页"
        /// 上游总数文案：`共 {{ total }} 条`。
        public static let totalPrefix = "共 "
        public static let totalSuffix = " 条"
        /// 上游 `displayedPages` 在总页数不超过 4 时直接全列。
        public static let compactPageLimit = 4
    }
}
