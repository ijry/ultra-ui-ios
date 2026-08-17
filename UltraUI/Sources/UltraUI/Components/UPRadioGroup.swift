import SwiftUI

/// Layout direction accepted by uview-plus `u-radio-group`.
public enum UPRadioPlacement: String, Equatable, Sendable {
    case row
    case column
}

/// Native SwiftUI counterpart of uview-plus `u-radio-group`.
///
/// `modelValue` is represented by a typed binding so String, Number, and
/// Boolean names remain distinguishable on the Swift side. Use:
///
/// ```swift
/// @State private var language: UPRadioName = "swift"
///
/// UPRadioGroup(modelValue: $language) {
///     UPRadio(name: "swift", label: "Swift")
///     UPRadio(name: "kotlin", label: "Kotlin")
/// }
/// ```
@MainActor
public struct UPRadioGroup<Content: View>: View {
    var customClass: String
    var modelValue: Binding<UPRadioName>?
    var value: UPRadioName
    var disabled: Bool
    var shape: String
    var activeColor: String
    var inactiveColor: String
    var name: String
    var size: String
    var placement: String
    var label: String
    var labelColor: String
    var labelSize: String
    var labelDisabled: Bool
    var iconColor: String
    var iconSize: String
    var borderBottom: Bool
    var iconPlacement: String
    var gap: String
    var customStyle: UPStyle

    private var onChangeHandler: ((UPRadioName) -> Void)?
    private let content: Content
    @State private var localValue: UPRadioName

    public init(
        customClass: String = UPConfig.radioGroup.customClass,
        name: String = UPConfig.radioGroup.name,
        modelValue: Binding<UPRadioName>? = nil,
        value: any UPRadioNameValue = UPConfig.radioGroup.value,
        disabled: Bool = UPConfig.radioGroup.disabled,
        shape: String = UPConfig.radioGroup.shape,
        activeColor: String = UPConfig.radioGroup.activeColor,
        inactiveColor: String = UPConfig.radioGroup.inactiveColor,
        size: any UPRadioUnitValue = UPConfig.radioGroup.size,
        placement: String = UPConfig.radioGroup.placement,
        label: String = UPConfig.radioGroup.label,
        labelColor: String = UPConfig.radioGroup.labelColor,
        labelSize: any UPRadioUnitValue = UPConfig.radioGroup.labelSize,
        labelDisabled: Bool = UPConfig.radioGroup.labelDisabled,
        iconColor: String = UPConfig.radioGroup.iconColor,
        iconSize: any UPRadioUnitValue = UPConfig.radioGroup.iconSize,
        borderBottom: Bool = UPConfig.radioGroup.borderBottom,
        iconPlacement: String = UPConfig.radioGroup.iconPlacement,
        gap: any UPRadioUnitValue = UPConfig.radioGroup.gap,
        customStyle: UPStyle = UPConfig.radioGroup.customStyle,
        onChange: ((UPRadioName) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.customClass = customClass
        self.modelValue = modelValue
        self.value = value.upCheckboxNameValue
        self.disabled = disabled
        self.shape = shape
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.name = name
        self.size = size.upCheckboxUnitValue
        self.placement = placement
        self.label = label
        self.labelColor = labelColor
        self.labelSize = labelSize.upCheckboxUnitValue
        self.labelDisabled = labelDisabled
        self.iconColor = iconColor
        self.iconSize = iconSize.upCheckboxUnitValue
        self.borderBottom = borderBottom
        self.iconPlacement = iconPlacement
        self.gap = gap.upCheckboxUnitValue
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.content = content()
        self._localValue = State(initialValue: modelValue?.wrappedValue ?? self.value)
    }

    public var body: some View {
        Group {
            if resolvedPlacement == .column {
                VStack(alignment: .leading, spacing: resolvedGap) {
                    content
                }
            } else {
                HStack(alignment: .center, spacing: resolvedGap) {
                    content
                }
            }
        }
        .environment(\.upRadioGroupContext, groupContext)
        .upStyle(customStyle)
    }

    var resolvedPlacement: UPRadioPlacement {
        placement.lowercased() == UPRadioPlacement.column.rawValue ? .column : .row
    }

    var resolvedGap: CGFloat {
        let parsed = UPUnit.parse(gap)
        return parsed >= 0 ? parsed : 0
    }

    /// Computes the value written by a child selection. The radio group's
    /// single-value contract means the selected child always replaces the
    /// previously selected name.
    static func updatedValue(current: UPRadioName, name: UPRadioName) -> UPRadioName {
        name
    }

    /// Testable/native imperative counterpart used by an enclosed radio via the
    /// environment. It preserves uview-plus's idempotence: selecting the
    /// already-selected radio does not emit another group `change` event.
    func triggerRadioChange(name: UPRadioName) {
        let binding = selectionBinding
        guard binding.wrappedValue != name else { return }
        let updated = Self.updatedValue(current: binding.wrappedValue, name: name)
        binding.wrappedValue = updated
        onChangeHandler?(updated)
    }

    private var selectionBinding: Binding<UPRadioName> {
        modelValue ?? $localValue
    }

    private var groupContext: UPRadioGroupContext {
        let selection = selectionBinding
        let handler = onChangeHandler
        return UPRadioGroupContext(
            value: selection,
            shape: shape,
            disabled: disabled,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            size: size,
            placement: placement,
            labelSize: labelSize,
            labelColor: labelColor,
            labelDisabled: labelDisabled,
            iconColor: iconColor,
            iconSize: iconSize,
            iconPlacement: iconPlacement,
            borderBottom: borderBottom,
            setSelected: { name in
                guard selection.wrappedValue != name else { return }
                let updated = Self.updatedValue(current: selection.wrappedValue, name: name)
                selection.wrappedValue = updated
                handler?(updated)
            }
        )
    }
}

public extension UPRadioGroup where Content == EmptyView {
    /// Creates an empty group, matching `<u-radio-group />`.
    init(
        customClass: String = UPConfig.radioGroup.customClass,
        name: String = UPConfig.radioGroup.name,
        modelValue: Binding<UPRadioName>? = nil,
        value: any UPRadioNameValue = UPConfig.radioGroup.value,
        disabled: Bool = UPConfig.radioGroup.disabled,
        shape: String = UPConfig.radioGroup.shape,
        activeColor: String = UPConfig.radioGroup.activeColor,
        inactiveColor: String = UPConfig.radioGroup.inactiveColor,
        size: any UPRadioUnitValue = UPConfig.radioGroup.size,
        placement: String = UPConfig.radioGroup.placement,
        label: String = UPConfig.radioGroup.label,
        labelColor: String = UPConfig.radioGroup.labelColor,
        labelSize: any UPRadioUnitValue = UPConfig.radioGroup.labelSize,
        labelDisabled: Bool = UPConfig.radioGroup.labelDisabled,
        iconColor: String = UPConfig.radioGroup.iconColor,
        iconSize: any UPRadioUnitValue = UPConfig.radioGroup.iconSize,
        borderBottom: Bool = UPConfig.radioGroup.borderBottom,
        iconPlacement: String = UPConfig.radioGroup.iconPlacement,
        gap: any UPRadioUnitValue = UPConfig.radioGroup.gap,
        customStyle: UPStyle = UPConfig.radioGroup.customStyle,
        onChange: ((UPRadioName) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            name: name,
            modelValue: modelValue,
            value: value,
            disabled: disabled,
            shape: shape,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            size: size,
            placement: placement,
            label: label,
            labelColor: labelColor,
            labelSize: labelSize,
            labelDisabled: labelDisabled,
            iconColor: iconColor,
            iconSize: iconSize,
            borderBottom: borderBottom,
            iconPlacement: iconPlacement,
            gap: gap,
            customStyle: customStyle,
            onChange: onChange
        ) {
            EmptyView()
        }
    }
}

public extension UPRadioGroup {
    /// Registers uview-plus's group-level `change(name)` callback.
    func onChange(_ action: @escaping (UPRadioName) -> Void) -> UPRadioGroup {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }
}
