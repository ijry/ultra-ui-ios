import SwiftUI

/// Typed identifier accepted by uview-plus `u-radio` and `u-radio-group`.
///
/// Radio and checkbox names have the same upstream `String | Number | Boolean`
/// contract. Reusing the identity-preserving representation ensures that
/// `"1"`, `1`, and `true` remain distinct, just as Vue strict equality does.
public typealias UPRadioName = UPCheckboxName
public typealias UPRadioNameValue = UPCheckboxNameValue
public typealias UPRadioTextValue = UPCheckboxTextValue
public typealias UPRadioUnitValue = UPCheckboxUnitValue
public typealias UPRadioFlag = UPCheckboxFlag

/// Parameters supplied to the SwiftUI equivalent of uview-plus's named `icon`
/// slot on `u-radio`.
public struct UPRadioIconSlotContext: Sendable {
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

/// Parameters supplied to the SwiftUI equivalent of uview-plus's named
/// `label` slot on `u-radio`.
public struct UPRadioLabelSlotContext: Sendable {
    public let label: String
    public let elDisabled: Bool

    public init(label: String, elDisabled: Bool) {
        self.label = label
        self.elDisabled = elDisabled
    }
}

/// This context carries main-actor SwiftUI bindings through the environment.
/// It is consumed only by `@MainActor` radio views, so its SwiftUI binding and
/// callback are intentionally never transferred between actors.
struct UPRadioGroupContext: @unchecked Sendable {
    let value: Binding<UPRadioName>
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
    let setSelected: (UPRadioName) -> Void
}

private struct UPRadioGroupContextKey: EnvironmentKey {
    static let defaultValue: UPRadioGroupContext? = nil
}

extension EnvironmentValues {
    var upRadioGroupContext: UPRadioGroupContext? {
        get { self[UPRadioGroupContextKey.self] }
        set { self[UPRadioGroupContextKey.self] = newValue }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-radio`.
///
/// Use it inside ``UPRadioGroup``. The group owns the single `modelValue`
/// binding while every child keeps uview-plus's child-overrides-parent rules
/// for inheritable props and exposes the named `icon` and `label` slots.
@MainActor
public struct UPRadio: View {
    var customClass: String
    var name: UPRadioName
    var shape: String
    var disabled: UPRadioFlag
    var labelDisabled: UPRadioFlag
    var activeColor: String
    var inactiveColor: String
    var iconSize: String
    var labelSize: String
    var label: String
    var size: String
    /// Retained for parity with the declared uview-plus prop. The upstream
    /// render path uses `iconColor`, so this property intentionally has no
    /// independent visual effect.
    var color: String
    var labelColor: String
    var iconColor: String
    var customStyle: UPStyle

    private var onChangeHandler: ((UPRadioName) -> Void)?
    private var iconContent: ((UPRadioIconSlotContext) -> AnyView)?
    private var labelContent: ((UPRadioLabelSlotContext) -> AnyView)?

    var hasIconSlot: Bool
    var hasLabelSlot: Bool

    @State private var localChecked: Bool
    @Environment(\.upRadioGroupContext) private var groupContext
    @Environment(\.upTheme) private var theme

    public init<Name: UPRadioNameValue, Size: UPRadioUnitValue, IconSize: UPRadioUnitValue, Label: UPRadioTextValue, LabelSize: UPRadioUnitValue>(
        customClass: String = UPConfig.radio.customClass,
        name: Name = UPConfig.radio.name,
        shape: String = UPConfig.radio.shape,
        disabled: UPRadioFlag = UPConfig.radio.disabled,
        labelDisabled: UPRadioFlag = UPConfig.radio.labelDisabled,
        activeColor: String = UPConfig.radio.activeColor,
        inactiveColor: String = UPConfig.radio.inactiveColor,
        iconSize: IconSize = UPConfig.radio.iconSize,
        labelSize: LabelSize = UPConfig.radio.labelSize,
        label: Label = UPConfig.radio.label,
        size: Size = UPConfig.radio.size,
        color: String = UPConfig.radio.color,
        labelColor: String = UPConfig.radio.labelColor,
        iconColor: String = UPConfig.radio.iconColor,
        customStyle: UPStyle = UPConfig.radio.customStyle,
        onChange: ((UPRadioName) -> Void)? = nil
    ) {
        self.customClass = customClass
        self.name = name.upCheckboxNameValue
        self.shape = shape
        self.disabled = disabled
        self.labelDisabled = labelDisabled
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.iconSize = iconSize.upCheckboxUnitValue
        self.labelSize = labelSize.upCheckboxUnitValue
        self.label = label.upCheckboxTextValue
        self.size = size.upCheckboxUnitValue
        self.color = color
        self.labelColor = labelColor
        self.iconColor = iconColor
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.iconContent = nil
        self.labelContent = nil
        self.hasIconSlot = false
        self.hasLabelSlot = false
        self._localChecked = State(initialValue: false)
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
    }

    /// Current visual selection state after resolving the enclosing group.
    var isChecked: Bool {
        groupContext?.value.wrappedValue == name || (groupContext == nil && localChecked)
    }

    var resolvedDisabled: Bool {
        disabled.explicitValue ?? groupContext?.disabled ?? false
    }

    var resolvedLabelDisabled: Bool {
        labelDisabled.explicitValue ?? groupContext?.labelDisabled ?? false
    }

    var resolvedShape: String {
        let raw = shape.isEmpty ? groupContext?.shape ?? "circle" : shape
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
        groupContext?.borderBottom == true && groupContext?.placement.lowercased() == "column"
    }

    /// Equivalent of tapping the icon area in the upstream component.
    func triggerIconTap() {
        guard !resolvedDisabled else { return }
        select()
    }

    /// Equivalent of tapping the label area in the upstream component.
    func triggerLabelTap() {
        guard !resolvedDisabled, !resolvedLabelDisabled else { return }
        select()
    }

    /// Equivalent of the wrapper tap behavior used for right-placed icons.
    func triggerWrapperTap() {
        guard resolvedIconPlacement == "right" else { return }
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
        .onTapGesture {
            triggerWrapperTap()
        }
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

    private var iconSlotContext: UPRadioIconSlotContext {
        UPRadioIconSlotContext(
            elIconSize: resolvedIconSize,
            elIconColor: resolvedIconColor,
            checked: isChecked,
            elDisabled: resolvedDisabled
        )
    }

    private var labelSlotContext: UPRadioLabelSlotContext {
        UPRadioLabelSlotContext(label: label, elDisabled: resolvedDisabled)
    }

    private var resolvedActiveColor: String {
        !activeColor.isEmpty ? activeColor : groupContext?.activeColor ?? "primary"
    }

    private var resolvedInactiveColor: String {
        !inactiveColor.isEmpty ? inactiveColor : groupContext?.inactiveColor ?? "#c8c9cc"
    }

    private var resolvedLabelColor: String {
        !labelColor.isEmpty ? labelColor : groupContext?.labelColor ?? "content"
    }

    private var resolvedIconColor: String {
        if resolvedDisabled {
            return isChecked ? resolvedInactiveColor : "transparent"
        }
        guard isChecked else { return "transparent" }
        return !iconColor.isEmpty ? iconColor : groupContext?.iconColor ?? "#ffffff"
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
        let raw = !childValue.isEmpty ? childValue : groupValue ?? ""
        let parsed = UPUnit.parse(raw)
        return parsed > 0 ? parsed : fallback
    }

    /// Performs the one-way selection operation used by uview-plus radio.
    /// A selected radio deliberately cannot be toggled off by another tap.
    private func select() {
        guard !isChecked else { return }
        // The child `change` event fires before the parent group updates its
        // v-model value in the upstream implementation.
        onChangeHandler?(name)
        if let groupContext {
            groupContext.setSelected(name)
        } else {
            $localChecked.wrappedValue = true
        }
    }
}

public extension UPRadio {
    /// Registers uview-plus's `change(name)` callback on this radio item.
    func onChange(_ action: @escaping (UPRadioName) -> Void) -> UPRadio {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// SwiftUI equivalent of uview-plus's named `icon` slot.
    func icon<Content: View>(@ViewBuilder _ content: @escaping (UPRadioIconSlotContext) -> Content) -> UPRadio {
        var copy = self
        copy.iconContent = { AnyView(content($0)) }
        copy.hasIconSlot = true
        return copy
    }

    /// SwiftUI equivalent of uview-plus's named `label` slot.
    func label<Content: View>(@ViewBuilder _ content: @escaping (UPRadioLabelSlotContext) -> Content) -> UPRadio {
        var copy = self
        copy.labelContent = { AnyView(content($0)) }
        copy.hasLabelSlot = true
        return copy
    }
}
