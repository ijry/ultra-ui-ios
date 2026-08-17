import SwiftUI

/// Typed identifier accepted by uview-plus `u-checkbox` and `u-checkbox-group`.
///
/// The cases intentionally keep strings, numbers, and booleans distinct, which
/// mirrors the strict-equality membership checks used by the Vue component.
public enum UPCheckboxName: Hashable, Sendable, CustomStringConvertible {
    case string(String)
    case number(Double)
    case boolean(Bool)

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: Int) {
        self = .number(Double(value))
    }

    public init(_ value: Double) {
        self = .number(value.isFinite ? value : 0)
    }

    public init(_ value: Bool) {
        self = .boolean(value)
    }

    public var description: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .boolean(let value):
            return value ? "true" : "false"
        }
    }
}

extension UPCheckboxName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension UPCheckboxName: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension UPCheckboxName: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value.isFinite ? value : 0)
    }
}

extension UPCheckboxName: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

/// Values accepted by the uview-plus `name` prop.
public protocol UPCheckboxNameValue {
    var upCheckboxNameValue: UPCheckboxName { get }
}

extension UPCheckboxName: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { self }
}

extension String: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .string(self) }
}

extension Int: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension Int8: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension Int16: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension Int32: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension Int64: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension UInt: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension UInt8: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension UInt16: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension UInt32: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension UInt64: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(self)) }
}

extension Double: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(isFinite ? self : 0) }
}

extension Float: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(isFinite ? self : 0)) }
}

extension CGFloat: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .number(Double(isFinite ? self : 0)) }
}

extension Bool: UPCheckboxNameValue {
    public var upCheckboxNameValue: UPCheckboxName { .boolean(self) }
}

/// A String-or-Number value accepted by `size`, `iconSize`, `labelSize`, and
/// `label` uview-plus props.
public protocol UPCheckboxTextValue {
    var upCheckboxTextValue: String { get }
}

extension String: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { self }
}

extension Int: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension Int8: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension Int16: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension Int32: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension Int64: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension UInt: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension UInt8: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension UInt16: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension UInt32: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension UInt64: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { String(self) }
}

extension Double: UPCheckboxTextValue {
    public var upCheckboxTextValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { Double(self).upCheckboxTextValue }
}

extension CGFloat: UPCheckboxTextValue {
    public var upCheckboxTextValue: String { Double(self).upCheckboxTextValue }
}

/// Semantic alias used by the sizing props so their accepted input surface is
/// explicit at call sites.
public protocol UPCheckboxUnitValue: UPCheckboxTextValue {
    var upCheckboxUnitValue: String { get }
}

public extension UPCheckboxUnitValue {
    var upCheckboxUnitValue: String { upCheckboxTextValue }
}

extension String: UPCheckboxUnitValue {}
extension Int: UPCheckboxUnitValue {}
extension Int8: UPCheckboxUnitValue {}
extension Int16: UPCheckboxUnitValue {}
extension Int32: UPCheckboxUnitValue {}
extension Int64: UPCheckboxUnitValue {}
extension UInt: UPCheckboxUnitValue {}
extension UInt8: UPCheckboxUnitValue {}
extension UInt16: UPCheckboxUnitValue {}
extension UInt32: UPCheckboxUnitValue {}
extension UInt64: UPCheckboxUnitValue {}
extension Double: UPCheckboxUnitValue {}
extension Float: UPCheckboxUnitValue {}
extension CGFloat: UPCheckboxUnitValue {}

/// Represents the upstream `String | Boolean` override props. An empty string
/// means "inherit from the enclosing checkbox group".
public enum UPCheckboxFlag: Equatable, Sendable, CustomStringConvertible {
    case inherited
    case value(Bool)

    public init(_ value: Bool) {
        self = .value(value)
    }

    public init(_ value: String) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "":
            self = .inherited
        case "false", "0", "no", "off":
            self = .value(false)
        default:
            self = .value(true)
        }
    }

    var explicitValue: Bool? {
        switch self {
        case .inherited: nil
        case .value(let value): value
        }
    }

    public var description: String {
        switch self {
        case .inherited: ""
        case .value(let value): value ? "true" : "false"
        }
    }
}

extension UPCheckboxFlag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension UPCheckboxFlag: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .value(value)
    }
}

/// The detail object emitted with uview-plus checkbox `change` events.
public struct UPCheckboxChange: Equatable, Sendable {
    public let name: UPCheckboxName

    public init(name: UPCheckboxName) {
        self.name = name
    }
}

/// Parameters supplied to the SwiftUI equivalent of the named `icon` slot.
public struct UPCheckboxIconSlotContext: Sendable {
    public let elIconSize: CGFloat
    public let elIconColor: String
    public let checked: Bool
    public let elDisabled: Bool

    public init(elIconSize: CGFloat, elIconColor: String, checked: Bool, elDisabled: Bool) {
        self.elIconSize = elIconSize
        self.elIconColor = elIconColor
        self.checked = checked
        self.elDisabled = elDisabled
    }
}

/// Parameters supplied to the SwiftUI equivalent of the named `label` slot.
public struct UPCheckboxLabelSlotContext: Sendable {
    public let label: String
    public let elDisabled: Bool

    public init(label: String, elDisabled: Bool) {
        self.label = label
        self.elDisabled = elDisabled
    }
}

/// This context carries main-actor SwiftUI bindings through the environment. It
/// is only consumed by `@MainActor` checkbox views, so its non-Sendable
/// closures never cross an actor boundary.
struct UPCheckboxGroupContext: @unchecked Sendable {
    let values: Binding<[UPCheckboxName]>
    let shape: String
    let disabled: Bool
    let activeColor: String
    let inactiveColor: String
    let size: String
    let placement: String
    let labelSize: String
    let labelColor: String
    let labelDisabled: Bool
    let iconColor: String
    let iconSize: String
    let iconPlacement: String
    let borderBottom: Bool
    let setChecked: (UPCheckboxName, Bool) -> Void
}

private struct UPCheckboxGroupContextKey: EnvironmentKey {
    static let defaultValue: UPCheckboxGroupContext? = nil
}

extension EnvironmentValues {
    var upCheckboxGroupContext: UPCheckboxGroupContext? {
        get { self[UPCheckboxGroupContextKey.self] }
        set { self[UPCheckboxGroupContextKey.self] = newValue }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-checkbox`.
///
/// Pass `checked: $value` together with `usedAlone: true` for the native
/// equivalent of `v-model:checked`. Inside ``UPCheckboxGroup``, selection is
/// driven by the group's `modelValue` binding and all inheritable group props
/// retain the child-overrides-parent precedence from uview-plus.
@MainActor
public struct UPCheckbox: View {
    var customClass: String
    var name: UPCheckboxName
    var shape: String
    var size: String
    var checked: Bool
    var disabled: UPCheckboxFlag
    var activeColor: String
    var inactiveColor: String
    var iconSize: String
    var iconColor: String
    var label: String
    var labelSize: String
    var labelColor: String
    var labelDisabled: UPCheckboxFlag
    var usedAlone: Bool
    var customStyle: UPStyle

    private var checkedBinding: Binding<Bool>?
    private var onChangeHandler: ((Bool, UPCheckboxChange) -> Void)?
    private var iconContent: ((UPCheckboxIconSlotContext) -> AnyView)?
    private var labelContent: ((UPCheckboxLabelSlotContext) -> AnyView)?

    var hasIconSlot: Bool
    var hasLabelSlot: Bool

    @State private var localChecked: Bool
    @Environment(\.upCheckboxGroupContext) private var groupContext
    @Environment(\.upTheme) private var theme

    public init<Name: UPCheckboxNameValue, Size: UPCheckboxUnitValue, IconSize: UPCheckboxUnitValue, Label: UPCheckboxTextValue, LabelSize: UPCheckboxUnitValue>(
        customClass: String = UPConfig.checkbox.customClass,
        name: Name = UPConfig.checkbox.name,
        shape: String = UPConfig.checkbox.shape,
        size: Size = UPConfig.checkbox.size,
        checked: Bool = UPConfig.checkbox.checked,
        disabled: UPCheckboxFlag = UPConfig.checkbox.disabled,
        activeColor: String = UPConfig.checkbox.activeColor,
        inactiveColor: String = UPConfig.checkbox.inactiveColor,
        iconSize: IconSize = UPConfig.checkbox.iconSize,
        iconColor: String = UPConfig.checkbox.iconColor,
        label: Label = UPConfig.checkbox.label,
        labelSize: LabelSize = UPConfig.checkbox.labelSize,
        labelColor: String = UPConfig.checkbox.labelColor,
        labelDisabled: UPCheckboxFlag = UPConfig.checkbox.labelDisabled,
        usedAlone: Bool = UPConfig.checkbox.usedAlone,
        customStyle: UPStyle = UPConfig.checkbox.customStyle,
        onChange: ((Bool, UPCheckboxChange) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            name: name.upCheckboxNameValue,
            shape: shape,
            size: size.upCheckboxUnitValue,
            checked: checked,
            checkedBinding: nil,
            disabled: disabled,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            iconSize: iconSize.upCheckboxUnitValue,
            iconColor: iconColor,
            label: label.upCheckboxTextValue,
            labelSize: labelSize.upCheckboxUnitValue,
            labelColor: labelColor,
            labelDisabled: labelDisabled,
            usedAlone: usedAlone,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    /// Native two-way-binding overload for uview-plus's `update:checked` emit.
    public init<Name: UPCheckboxNameValue, Size: UPCheckboxUnitValue, IconSize: UPCheckboxUnitValue, Label: UPCheckboxTextValue, LabelSize: UPCheckboxUnitValue>(
        customClass: String = UPConfig.checkbox.customClass,
        name: Name = UPConfig.checkbox.name,
        shape: String = UPConfig.checkbox.shape,
        size: Size = UPConfig.checkbox.size,
        checked: Binding<Bool>,
        disabled: UPCheckboxFlag = UPConfig.checkbox.disabled,
        activeColor: String = UPConfig.checkbox.activeColor,
        inactiveColor: String = UPConfig.checkbox.inactiveColor,
        iconSize: IconSize = UPConfig.checkbox.iconSize,
        iconColor: String = UPConfig.checkbox.iconColor,
        label: Label = UPConfig.checkbox.label,
        labelSize: LabelSize = UPConfig.checkbox.labelSize,
        labelColor: String = UPConfig.checkbox.labelColor,
        labelDisabled: UPCheckboxFlag = UPConfig.checkbox.labelDisabled,
        usedAlone: Bool = UPConfig.checkbox.usedAlone,
        customStyle: UPStyle = UPConfig.checkbox.customStyle,
        onChange: ((Bool, UPCheckboxChange) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            name: name.upCheckboxNameValue,
            shape: shape,
            size: size.upCheckboxUnitValue,
            checked: checked.wrappedValue,
            checkedBinding: checked,
            disabled: disabled,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            iconSize: iconSize.upCheckboxUnitValue,
            iconColor: iconColor,
            label: label.upCheckboxTextValue,
            labelSize: labelSize.upCheckboxUnitValue,
            labelColor: labelColor,
            labelDisabled: labelDisabled,
            usedAlone: usedAlone,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    private init(
        customClass: String,
        name: UPCheckboxName,
        shape: String,
        size: String,
        checked: Bool,
        checkedBinding: Binding<Bool>?,
        disabled: UPCheckboxFlag,
        activeColor: String,
        inactiveColor: String,
        iconSize: String,
        iconColor: String,
        label: String,
        labelSize: String,
        labelColor: String,
        labelDisabled: UPCheckboxFlag,
        usedAlone: Bool,
        customStyle: UPStyle,
        onChange: ((Bool, UPCheckboxChange) -> Void)?
    ) {
        self.customClass = customClass
        self.name = name
        self.shape = shape
        self.size = size
        self.checked = checked
        self.checkedBinding = checkedBinding
        self.disabled = disabled
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.label = label
        self.labelSize = labelSize
        self.labelColor = labelColor
        self.labelDisabled = labelDisabled
        self.usedAlone = usedAlone
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.iconContent = nil
        self.labelContent = nil
        self.hasIconSlot = false
        self.hasLabelSlot = false
        self._localChecked = State(initialValue: checkedBinding?.wrappedValue ?? checked)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            rowContent
            if showsBottomBorder {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
        .padding(.vertical, 5)
        .padding(.bottom, showsBottomBorder ? 8 : 0)
        .upStyle(customStyle)
        .onChange(of: checked) { _, newValue in
            guard checkedBinding == nil else { return }
            $localChecked.wrappedValue = newValue
        }
    }

    /// Current visual selection state after group membership and standalone
    /// binding resolution.
    var isChecked: Bool {
        if usesGroup, let groupContext {
            return groupContext.values.wrappedValue.contains(name) || localChecked
        }
        return checkedBinding?.wrappedValue ?? localChecked
    }

    var resolvedDisabled: Bool {
        if usesGroup, let groupContext {
            return disabled.explicitValue ?? groupContext.disabled
        }
        return disabled.explicitValue ?? false
    }

    var resolvedLabelDisabled: Bool {
        if usesGroup, let groupContext {
            return labelDisabled.explicitValue ?? groupContext.labelDisabled
        }
        return labelDisabled.explicitValue ?? false
    }

    var resolvedShape: String {
        let raw = shape.isEmpty ? (usesGroup ? groupContext?.shape ?? "square" : "circle") : shape
        return raw.lowercased() == "square" ? "square" : "circle"
    }

    var resolvedSize: CGFloat {
        resolvedLength(size, groupValue: groupContext?.size, fallback: 18)
    }

    var resolvedIconSize: CGFloat {
        resolvedLength(iconSize, groupValue: groupContext?.iconSize, fallback: 12)
    }

    var resolvedLabelFontSize: CGFloat {
        resolvedLength(labelSize, groupValue: groupContext?.labelSize, fallback: 15)
    }

    var resolvedIconPlacement: String {
        groupContext?.iconPlacement.lowercased() == "right" ? "right" : "left"
    }

    var showsBottomBorder: Bool {
        usesGroup && groupContext?.borderBottom == true && groupContext?.placement.lowercased() == "column"
    }

    /// Equivalent of tapping the icon area in the upstream component.
    func triggerIconTap() {
        guard !resolvedDisabled else { return }
        setChecked(!isChecked)
    }

    /// Equivalent of tapping the label area in the upstream component.
    func triggerLabelTap() {
        guard !resolvedDisabled, !resolvedLabelDisabled else { return }
        setChecked(!isChecked)
    }

    /// Equivalent of the wrapper tap behavior used for right-placed icons.
    func triggerWrapperTap() {
        guard usedAlone || resolvedIconPlacement == "right" else { return }
        triggerIconTap()
    }

    @ViewBuilder
    private var rowContent: some View {
        HStack(alignment: .center, spacing: 0) {
            if resolvedIconPlacement == "right" {
                labelView
                iconView
            } else {
                iconView
                labelView
            }
        }
        .contentShape(Rectangle())
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: resolvedShape == "circle" ? resolvedSize / 2 : 3, style: .continuous)
                .fill(iconBackgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: resolvedShape == "circle" ? resolvedSize / 2 : 3, style: .continuous)
                        .stroke(iconBorderColor, lineWidth: 1)
                }

            if isChecked {
                if let iconContent {
                    iconContent(iconSlotContext)
                } else {
                    UPIcon(
                        name: "checkbox-mark",
                        color: resolvedIconColor,
                        size: "\(resolvedIconSize)"
                    )
                }
            }
        }
        .frame(width: resolvedSize, height: resolvedSize)
        .padding(.trailing, resolvedIconPlacement == "right" ? 0 : 6)
        .padding(.leading, resolvedIconPlacement == "right" ? 6 : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerIconTap()
        }
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    @ViewBuilder
    private var labelView: some View {
        Group {
            if let labelContent {
                labelContent(labelSlotContext)
            } else {
                Text(label)
                    .font(.system(size: resolvedLabelFontSize))
                    .foregroundStyle(resolvedDisabled ? UPColor.parse(resolvedInactiveColor, theme: theme) : UPColor.parse(resolvedLabelColor, theme: theme))
            }
        }
        .padding(.leading, resolvedIconPlacement == "right" ? 0 : 5)
        .padding(.trailing, resolvedIconPlacement == "right" ? 12 : 12)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerLabelTap()
        }
    }

    private var usesGroup: Bool {
        !usedAlone && groupContext != nil
    }

    private var iconSlotContext: UPCheckboxIconSlotContext {
        UPCheckboxIconSlotContext(
            elIconSize: resolvedIconSize,
            elIconColor: resolvedIconColor,
            checked: isChecked,
            elDisabled: resolvedDisabled
        )
    }

    private var labelSlotContext: UPCheckboxLabelSlotContext {
        UPCheckboxLabelSlotContext(label: label, elDisabled: resolvedDisabled)
    }

    private var resolvedActiveColor: String {
        !activeColor.isEmpty ? activeColor : (usesGroup ? groupContext?.activeColor ?? "primary" : "primary")
    }

    private var resolvedInactiveColor: String {
        !inactiveColor.isEmpty ? inactiveColor : (usesGroup ? groupContext?.inactiveColor ?? "#c8c9cc" : "#c8c9cc")
    }

    private var resolvedLabelColor: String {
        !labelColor.isEmpty ? labelColor : (usesGroup ? groupContext?.labelColor ?? "content" : "content")
    }

    private var resolvedIconColor: String {
        if resolvedDisabled {
            return isChecked ? resolvedInactiveColor : "transparent"
        }
        guard isChecked else { return "transparent" }
        return !iconColor.isEmpty ? iconColor : (usesGroup ? groupContext?.iconColor ?? "#ffffff" : "#ffffff")
    }

    private var iconBackgroundColor: Color {
        if resolvedDisabled {
            return UPColor.parse("#ebedf0", theme: theme)
        }
        return isChecked ? UPColor.parse(resolvedActiveColor, theme: theme) : .white
    }

    private var iconBorderColor: Color {
        isChecked && !resolvedDisabled ? UPColor.parse(resolvedActiveColor, theme: theme) : UPColor.parse(resolvedInactiveColor, theme: theme)
    }

    private func resolvedLength(_ childValue: String, groupValue: String?, fallback: CGFloat) -> CGFloat {
        let raw = !childValue.isEmpty ? childValue : (usesGroup ? groupValue ?? "" : "")
        let parsed = UPUnit.parse(raw)
        return parsed > 0 ? parsed : fallback
    }

    private func setChecked(_ newValue: Bool) {
        $localChecked.wrappedValue = newValue
        if usesGroup, let groupContext {
            groupContext.setChecked(name, newValue)
        } else {
            (checkedBinding ?? $localChecked).wrappedValue = newValue
        }
        onChangeHandler?(newValue, UPCheckboxChange(name: name))
    }
}

public extension UPCheckbox {
    /// Registers the uview-plus `change(isChecked, { name })` event callback.
    func onChange(_ action: @escaping (Bool, UPCheckboxChange) -> Void) -> UPCheckbox {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// SwiftUI equivalent of uview-plus's named `icon` slot.
    func icon<Content: View>(@ViewBuilder _ content: @escaping (UPCheckboxIconSlotContext) -> Content) -> UPCheckbox {
        var copy = self
        copy.iconContent = { AnyView(content($0)) }
        copy.hasIconSlot = true
        return copy
    }

    /// SwiftUI equivalent of uview-plus's named `label` slot.
    func label<Content: View>(@ViewBuilder _ content: @escaping (UPCheckboxLabelSlotContext) -> Content) -> UPCheckbox {
        var copy = self
        copy.labelContent = { AnyView(content($0)) }
        copy.hasLabelSlot = true
        return copy
    }
}
