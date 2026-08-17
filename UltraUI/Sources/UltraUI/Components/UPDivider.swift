import SwiftUI

/// Semantic alias for the `String | Number` props accepted by `u-divider`.
public typealias UPDividerUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-divider`.
///
/// Its prop names and defaults mirror uview-plus. The default Vue slot maps to
/// the trailing `@ViewBuilder` initializer, while `customStyle` is rendered
/// through the shared native style bridge.
public struct UPDivider: View {
    var dashed: Bool
    var hairline: Bool
    var dot: Bool
    var textPosition: String
    var text: String
    var textSize: Double
    var textColor: String
    var lineColor: String
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?
    private var defaultSlotContent: AnyView?

    public init(dashed: Bool = UPConfig.divider.dashed,
                hairline: Bool = UPConfig.divider.hairline,
                dot: Bool = UPConfig.divider.dot,
                textPosition: String = UPConfig.divider.textPosition,
                text: some UPDividerUnitValue = UPConfig.divider.text,
                textSize: some UPDividerUnitValue = UPConfig.divider.textSize,
                textColor: String = UPConfig.divider.textColor,
                lineColor: String = UPConfig.divider.lineColor,
                customClass: String = UPConfig.divider.customClass,
                customStyle: UPStyle = UPConfig.divider.customStyle,
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil) {
        self.dashed = dashed
        self.hairline = hairline
        self.dot = dot
        self.textPosition = textPosition
        self.text = text.upCheckboxTextValue
        self.textSize = Double(UPUnit.parse(textSize.upCheckboxUnitValue))
        self.textColor = textColor
        self.lineColor = lineColor
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTap = onTap
        self.onClick = onClick
        self.defaultSlotContent = nil
    }

    /// Maps the uview-plus default slot to native SwiftUI content.
    public init<Content: View>(dashed: Bool = UPConfig.divider.dashed,
                               hairline: Bool = UPConfig.divider.hairline,
                               dot: Bool = UPConfig.divider.dot,
                               textPosition: String = UPConfig.divider.textPosition,
                               text: some UPDividerUnitValue = UPConfig.divider.text,
                               textSize: some UPDividerUnitValue = UPConfig.divider.textSize,
                               textColor: String = UPConfig.divider.textColor,
                               lineColor: String = UPConfig.divider.lineColor,
                               customClass: String = UPConfig.divider.customClass,
                               customStyle: UPStyle = UPConfig.divider.customStyle,
                               onTap: (() -> Void)? = nil,
                               onClick: (() -> Void)? = nil,
                               @ViewBuilder content: () -> Content) {
        self.init(
            dashed: dashed,
            hairline: hairline,
            dot: dot,
            textPosition: textPosition,
            text: text,
            textSize: textSize,
            textColor: textColor,
            lineColor: lineColor,
            customClass: customClass,
            customStyle: customStyle,
            onTap: onTap,
            onClick: onClick
        )
        self.defaultSlotContent = AnyView(content())
    }

    public var body: some View {
        HStack(spacing: centerSpacing) {
            line(fixedWidth: effectiveTextPosition == "left")
            centerContent
            line(fixedWidth: effectiveTextPosition == "right")
        }
        .frame(maxWidth: .infinity)
        .upStyle(customStyle)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
            onClick?()
        }
    }

    /// Resolves unsupported positions to the upstream effective default.
    static func normalizedTextPosition(_ value: String) -> String {
        switch value.lowercased() {
        case "left", "center", "right":
            return value.lowercased()
        default:
            return "center"
        }
    }

    private var effectiveTextPosition: String {
        Self.normalizedTextPosition(textPosition)
    }

    private var hasCenterContent: Bool {
        defaultSlotContent != nil || dot || !text.isEmpty
    }

    private var centerSpacing: CGFloat {
        hasCenterContent ? 12 : 0
    }

    @ViewBuilder
    private var centerContent: some View {
        if let defaultSlotContent {
            defaultSlotContent
        } else if dot {
            Text("●")
                .font(.system(size: max(CGFloat(textSize), 1)))
                .foregroundStyle(UPColor.parse(textColor))
        } else if !text.isEmpty {
            Text(text)
                .font(.system(size: max(CGFloat(textSize), 1)))
                .foregroundStyle(UPColor.parse(textColor))
        }
    }

    @ViewBuilder
    private func line(fixedWidth: Bool) -> some View {
        if fixedWidth {
            UPLine(
                color: lineColor,
                length: "100%",
                hairline: hairline,
                dashed: dashed
            )
            .frame(width: UPUnit.rpx(80))
        } else {
            UPLine(
                color: lineColor,
                length: "100%",
                hairline: hairline,
                dashed: dashed
            )
            .frame(maxWidth: .infinity)
        }
    }
}
