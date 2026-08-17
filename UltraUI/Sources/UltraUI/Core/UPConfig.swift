import Foundation

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
        public static let text = ""
        public static let icon = ""
        public static let iconColor = ""
        public static let color = ""
        public static let throttleTime: Double = 0
        public static let block = false
    }
    public enum popup {
        public static let show = false
        public static let overlay = true
        public static let mode = "bottom"
        public static let duration: Double = 300
        public static let closeable = false
        public static let closeOnClickOverlay = true
        public static let zIndex: Double = 10075
        public static let safeAreaInsetBottom = true
        public static let safeAreaInsetTop = false
        public static let closeIconPos = "top-right"
        public static let round = "20px"
        public static let zoom = true
        public static let bgColor = ""
        public static let overlayOpacity: Double = 0.5
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
    }
    public enum toast {
        public static let zIndex: Double = 10090
        public static let duration: Double = 2000
        public static let position = "center"
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
        public static let label = ""
        public static let labelPos = "right"
        public static let labelSize = "15px"
        public static let labelColor = "#606266"
        public static let space = "3px"
        public static let customPrefix = "uicon"
    }
    public enum line {
        public static let color = "#d6d7d9"
        public static let length = "100%"
        public static let direction = "row"
        public static let hairline = true
        public static let margin: Double = 0
        public static let dashed = false
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
        public static let duration: Double = 1200
        public static let inactiveColor = ""
    }
    public enum form {
        public static let errorType = "message"
    }
    public enum formItem {
        public static let label = ""
        public static let prop = ""
        public static let required = false
        public static let labelPosition = "left"
        public static let labelWidth = "90px"
        public static let borderBottom = true
        public static let help = ""
    }
    public enum input {
        public static let prop = ""
        public static let type = "text"
        public static let placeholder = ""
        public static let border = "surround"
        public static let inputAlign = "left"
        public static let clearable = false
        public static let disabled = false
        public static let readonly = false
        public static let prefixIcon = ""
        public static let suffixIcon = ""
        public static let maxlength: Int? = nil
        public static let count = false
    }
    public enum textarea {
        public static let prop = ""
        public static let placeholder = ""
        public static let maxlength: Int? = nil
        public static let count = false
        public static let disabled = false
        public static let readonly = false
        public static let height: Double = 100
        public static let autoHeight = false
    }
}
