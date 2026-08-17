import SwiftUI

/// A String-or-Number text value accepted by uview-plus `u-cell` props.
public protocol UPCellTextValue {
    var upCellTextValue: String { get }
}

extension String: UPCellTextValue {
    public var upCellTextValue: String { self }
}

extension Int: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension Int8: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension Int16: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension Int32: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension Int64: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension UInt: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension UInt8: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension UInt16: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension UInt32: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension UInt64: UPCellTextValue {
    public var upCellTextValue: String { String(self) }
}

extension Double: UPCellTextValue {
    public var upCellTextValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPCellTextValue {
    public var upCellTextValue: String {
        Double(self).upCellTextValue
    }
}

extension CGFloat: UPCellTextValue {
    public var upCellTextValue: String {
        Double(self).upCellTextValue
    }
}

/// Typed event payload for the uview-plus `u-cell` `name` prop.
public enum UPCellName: Equatable, Sendable, CustomStringConvertible {
    case string(String)
    case number(Double)

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: Int) {
        self = .number(Double(value))
    }

    public init(_ value: Double) {
        self = .number(value)
    }

    public var description: String {
        switch self {
        case .string(let value): return value
        case .number(let value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        }
    }
}

extension UPCellName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension UPCellName: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension UPCellName: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

public protocol UPCellNameValue {
    var upCellNameValue: UPCellName { get }
}

extension UPCellName: UPCellNameValue {
    public var upCellNameValue: UPCellName { self }
}

extension String: UPCellNameValue {
    public var upCellNameValue: UPCellName { UPCellName(self) }
}

extension Int: UPCellNameValue {
    public var upCellNameValue: UPCellName { UPCellName(self) }
}

extension Int8: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension Int16: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension Int32: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension Int64: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension UInt: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension UInt8: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension UInt16: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension UInt32: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension UInt64: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(self)) }
}

extension Double: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(isFinite ? self : 0) }
}

extension Float: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(isFinite ? self : 0)) }
}

extension CGFloat: UPCellNameValue {
    public var upCellNameValue: UPCellName { .number(Double(isFinite ? self : 0)) }
}

/// Native SwiftUI counterpart of uview-plus `u-cell`.
///
/// The String/Number props, custom styles, named-slot equivalents, disabled
/// behavior, arrow orientation, and `click({ name })` payload follow the
/// checked-in uview-plus implementation. Mini-program routing metadata is
/// retained in `url` and `linkType`; callers can perform navigation in the
/// click callback on Apple platforms.
public struct UPCell: View {
    var customClass: String
    var title: String
    var label: String
    var value: String
    var icon: String
    var disabled: Bool
    var border: Bool
    var center: Bool
    var url: String
    var linkType: String
    var clickable: Bool
    var isLink: Bool
    var required: Bool
    var rightIcon: String
    var arrowDirection: String
    var iconStyle: UPStyle
    var rightIconStyle: UPStyle
    var titleStyle: UPStyle
    var size: String
    var stop: Bool
    var name: UPCellName
    var customStyle: UPStyle

    var onTapHandler: (() -> Void)?
    var onClickHandler: ((UPCellName) -> Void)?

    private var iconContent: AnyView?
    private var titleContent: AnyView?
    private var labelContent: AnyView?
    private var valueContent: AnyView?
    private var rightIconContent: AnyView?
    private var legacyRightIconContent: AnyView?

    @Environment(\.upTheme) private var theme

    public init<Title: UPCellTextValue, Label: UPCellTextValue, Value: UPCellTextValue, Name: UPCellNameValue>(
        customClass: String = UPConfig.cell.customClass,
        title: Title = UPConfig.cell.title,
        label: Label = UPConfig.cell.label,
        value: Value = UPConfig.cell.value,
        icon: String = UPConfig.cell.icon,
        disabled: Bool = UPConfig.cell.disabled,
        border: Bool = UPConfig.cell.border,
        center: Bool = UPConfig.cell.center,
        url: String = UPConfig.cell.url,
        linkType: String = UPConfig.cell.linkType,
        clickable: Bool = UPConfig.cell.clickable,
        isLink: Bool = UPConfig.cell.isLink,
        required: Bool = UPConfig.cell.required,
        rightIcon: String = UPConfig.cell.rightIcon,
        arrowDirection: String = UPConfig.cell.arrowDirection,
        iconStyle: UPStyle = UPConfig.cell.iconStyle,
        rightIconStyle: UPStyle = UPConfig.cell.rightIconStyle,
        titleStyle: UPStyle = UPConfig.cell.titleStyle,
        size: String = UPConfig.cell.size,
        stop: Bool = UPConfig.cell.stop,
        name: Name = UPConfig.cell.name,
        customStyle: UPStyle = UPStyle(),
        onTap: (() -> Void)? = nil,
        onClick: ((UPCellName) -> Void)? = nil
    ) {
        self.customClass = customClass
        self.title = title.upCellTextValue
        self.label = label.upCellTextValue
        self.value = value.upCellTextValue
        self.icon = icon
        self.disabled = disabled
        self.border = border
        self.center = center
        self.url = url
        self.linkType = linkType
        self.clickable = clickable
        self.isLink = isLink
        self.required = required
        self.rightIcon = rightIcon
        self.arrowDirection = arrowDirection
        self.iconStyle = iconStyle
        self.rightIconStyle = rightIconStyle
        self.titleStyle = titleStyle
        self.size = size
        self.stop = stop
        self.name = name.upCellNameValue
        self.customStyle = customStyle
        self.onTapHandler = onTap
        self.onClickHandler = onClick
        self.iconContent = nil
        self.titleContent = nil
        self.labelContent = nil
        self.valueContent = nil
        self.rightIconContent = nil
        self.legacyRightIconContent = nil
    }

    public var body: some View {
        VStack(spacing: 0) {
            rowContent
            if border {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
        .background(Color.clear)
        .upStyle(customStyle)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerClick()
        }
    }

    /// Whether the cell receives the upstream clickable hover/feedback state.
    var effectiveClickable: Bool {
        !disabled && (clickable || isLink)
    }

    /// Whether the right icon wrapper is rendered.
    var showsRightIcon: Bool {
        rightIconContent != nil || legacyRightIconContent != nil || isLink
    }

    /// Whether the default or custom value content is visible.
    var hasVisibleValue: Bool {
        valueContent != nil || !value.isEmpty
    }

    var hasIconSlot: Bool { iconContent != nil }
    var hasTitleSlot: Bool { titleContent != nil }
    var hasLabelSlot: Bool { labelContent != nil }
    var hasValueSlot: Bool { valueContent != nil }
    var hasRightIconSlot: Bool { rightIconContent != nil }
    var hasLegacyRightIconSlot: Bool { legacyRightIconContent != nil }

    var resolvedTitleFontSize: CGFloat {
        size.lowercased() == "large" ? 16 : 15
    }

    var resolvedLabelFontSize: CGFloat {
        size.lowercased() == "large" ? 14 : 12
    }

    var resolvedValueFontSize: CGFloat {
        size.lowercased() == "large" ? 15 : 14
    }

    /// Native rotation equivalent for uview-plus' arrow direction classes.
    var rightIconRotation: CGFloat {
        switch arrowDirection.lowercased() {
        case "up": return -90
        case "down": return 90
        case "left": return 180
        default: return 0
        }
    }

    /// Executes the SwiftUI equivalent of uview-plus `clickHandler`.
    func triggerClick() {
        guard !disabled else { return }
        onTapHandler?()
        onClickHandler?(name)
    }

    @ViewBuilder
    private var rowContent: some View {
        HStack(alignment: center ? .center : .top, spacing: 0) {
            leftContent
            Spacer(minLength: 0)
            valueView
            if showsRightIcon {
                rightIconView
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(effectiveClickable ? Color.gray.opacity(0.001) : Color.clear)
        .opacity(disabled ? 0.6 : 1)
    }

    @ViewBuilder
    private var leftContent: some View {
        HStack(alignment: .center, spacing: 4) {
            if let iconContent {
                iconContent.upStyle(iconStyle)
            } else if !icon.isEmpty {
                UPIcon(
                    name: icon,
                    size: size.lowercased() == "large" ? "22px" : "18px"
                )
                .upStyle(iconStyle)
            }

            VStack(alignment: .leading, spacing: label.isEmpty && labelContent == nil ? 0 : 5) {
                titleView
                labelView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var titleView: some View {
        if let titleContent {
            titleContent
                .upStyle(titleStyle)
                .overlay(alignment: .leading) {
                    if required {
                        requiredMark
                    }
                }
        } else if !title.isEmpty {
            Text(title)
                .font(.system(size: resolvedTitleFontSize))
                .foregroundStyle(disabled ? theme.disabled : theme.main)
                .upStyle(titleStyle)
                .overlay(alignment: .leading) {
                    if required {
                        requiredMark
                    }
                }
        } else if required {
            requiredMark
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if let labelContent {
            labelContent
                .font(.system(size: resolvedLabelFontSize))
                .foregroundStyle(disabled ? theme.disabled : theme.tips)
        } else if !label.isEmpty {
            Text(label)
                .font(.system(size: resolvedLabelFontSize))
                .foregroundStyle(disabled ? theme.disabled : theme.tips)
        }
    }

    @ViewBuilder
    private var valueView: some View {
        if let valueContent {
            valueContent
                .font(.system(size: resolvedValueFontSize))
                .foregroundStyle(disabled ? theme.disabled : theme.content)
                .frame(alignment: .trailing)
        } else if !value.isEmpty {
            Text(value)
                .font(.system(size: resolvedValueFontSize))
                .foregroundStyle(disabled ? theme.disabled : theme.content)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private var rightIconView: some View {
        if let rightIconContent {
            rightIconContent
                .upStyle(rightIconStyle)
                .rotationEffect(.degrees(rightIconRotation))
                .padding(.leading, 4)
        } else if let legacyRightIconContent {
            legacyRightIconContent
                .upStyle(rightIconStyle)
                .rotationEffect(.degrees(rightIconRotation))
                .padding(.leading, 4)
        } else {
            UPIcon(
                name: rightIcon,
                color: disabled ? "disabled" : "info",
                size: size.lowercased() == "large" ? "18px" : "16px"
            )
            .upStyle(rightIconStyle)
            .rotationEffect(.degrees(rightIconRotation))
            .padding(.leading, 4)
        }
    }

    private var requiredMark: some View {
        Text("*")
            .font(.system(size: 14))
            .foregroundStyle(theme.error)
            .offset(x: -8, y: 2)
    }
}

public extension UPCell {
    func onTap(_ action: @escaping () -> Void) -> UPCell {
        var copy = self
        copy.onTapHandler = action
        return copy
    }

    func onClick(_ action: @escaping (UPCellName) -> Void) -> UPCell {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    func icon<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.iconContent = AnyView(content())
        return copy
    }

    func title<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.titleContent = AnyView(content())
        return copy
    }

    func label<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.labelContent = AnyView(content())
        return copy
    }

    func value<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.valueContent = AnyView(content())
        return copy
    }

    func rightIcon<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.rightIconContent = AnyView(content())
        return copy
    }

    /// Legacy slot spelling retained from uview-plus templates.
    func righticon<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCell {
        var copy = self
        copy.legacyRightIconContent = AnyView(content())
        return copy
    }
}
