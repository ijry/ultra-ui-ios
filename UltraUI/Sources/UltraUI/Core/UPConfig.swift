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
        public static let confirmText = "确认"
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

}
