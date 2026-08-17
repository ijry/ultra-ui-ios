import SwiftUI

/// Layout selection accepted by uview-plus `u-checkbox-group`.
public enum UPCheckboxPlacement: String, Equatable, Sendable {
    case row
    case column
}

/// Detail object supplied by uview-plus checkbox-group `change` events after
/// the selected names have been updated.
public struct UPCheckboxGroupChange: Equatable, Sendable {
    public let name: UPCheckboxName
    public let isChecked: Bool

    public init(name: UPCheckboxName, isChecked: Bool) {
        self.name = name
        self.isChecked = isChecked
    }
}

/// Native SwiftUI counterpart of uview-plus `u-checkbox-group`.
///
/// `modelValue` is the direct equivalent of Vue 3 `v-model`; the group
/// publishes its configuration through a SwiftUI environment so nested
/// ``UPCheckbox`` views retain uview-plus's parent/default precedence.
@MainActor
public struct UPCheckboxGroup<Content: View>: View {
    var customClass: String
    var name: String
    var value: [UPCheckboxName]
    var shape: String
    var disabled: Bool
    var activeColor: String
    var inactiveColor: String
    var size: String
    var placement: String
    var labelSize: String
    var labelColor: String
    var labelDisabled: Bool
    var iconColor: String
    var iconSize: String
    var iconPlacement: String
    var borderBottom: Bool
    var customStyle: UPStyle

    private var modelValue: Binding<[UPCheckboxName]>?
    private var onChangeHandler: (([UPCheckboxName], UPCheckboxGroupChange) -> Void)?
    private let content: Content
    @State private var localValue: [UPCheckboxName]

    public init<Size: UPCheckboxUnitValue, LabelSize: UPCheckboxUnitValue, IconSize: UPCheckboxUnitValue>(
        customClass: String = UPConfig.checkboxGroup.customClass,
        name: String = UPConfig.checkboxGroup.name,
        modelValue: Binding<[UPCheckboxName]>? = nil,
        value: [UPCheckboxName] = UPConfig.checkboxGroup.value,
        shape: String = UPConfig.checkboxGroup.shape,
        disabled: Bool = UPConfig.checkboxGroup.disabled,
        activeColor: String = UPConfig.checkboxGroup.activeColor,
        inactiveColor: String = UPConfig.checkboxGroup.inactiveColor,
        size: Size = UPConfig.checkboxGroup.size,
        placement: String = UPConfig.checkboxGroup.placement,
        labelSize: LabelSize = UPConfig.checkboxGroup.labelSize,
        labelColor: String = UPConfig.checkboxGroup.labelColor,
        labelDisabled: Bool = UPConfig.checkboxGroup.labelDisabled,
        iconColor: String = UPConfig.checkboxGroup.iconColor,
        iconSize: IconSize = UPConfig.checkboxGroup.iconSize,
        iconPlacement: String = UPConfig.checkboxGroup.iconPlacement,
        borderBottom: Bool = UPConfig.checkboxGroup.borderBottom,
        customStyle: UPStyle = UPConfig.checkboxGroup.customStyle,
        onChange: (([UPCheckboxName], UPCheckboxGroupChange) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.customClass = customClass
        self.name = name
        self.modelValue = modelValue
        self.value = value
        self.shape = shape
        self.disabled = disabled
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.size = size.upCheckboxUnitValue
        self.placement = placement
        self.labelSize = labelSize.upCheckboxUnitValue
        self.labelColor = labelColor
        self.labelDisabled = labelDisabled
        self.iconColor = iconColor
        self.iconSize = iconSize.upCheckboxUnitValue
        self.iconPlacement = iconPlacement
        self.borderBottom = borderBottom
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.content = content()
        self._localValue = State(initialValue: modelValue?.wrappedValue ?? value)
    }

    public var body: some View {
        Group {
            if resolvedPlacement == .column {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    content
                }
            }
        }
        .environment(\.upCheckboxGroupContext, groupContext)
        .upStyle(customStyle)
    }

    var resolvedPlacement: UPCheckboxPlacement {
        placement.lowercased() == UPCheckboxPlacement.column.rawValue ? .column : .row
    }

    /// Computes the strict-identity array change performed when a child
    /// checkbox changes. This mirrors the group implementation's collection of
    /// currently selected child names.
    static func updatedValues(_ values: [UPCheckboxName], name: UPCheckboxName, isChecked: Bool) -> [UPCheckboxName] {
        if isChecked {
            return values.contains(name) ? values : values + [name]
        }
        return values.filter { $0 != name }
    }

    /// Testable/native imperative counterpart used by a nested checkbox via the
    /// group environment. It also retains the documented `change` event order:
    /// update the bound values first, then invoke the callback.
    func triggerCheckboxChange(name: UPCheckboxName, isChecked: Bool) {
        let binding = selectionBinding
        let updated = Self.updatedValues(binding.wrappedValue, name: name, isChecked: isChecked)
        binding.wrappedValue = updated
        onChangeHandler?(updated, UPCheckboxGroupChange(name: name, isChecked: isChecked))
    }

    private var selectionBinding: Binding<[UPCheckboxName]> {
        modelValue ?? $localValue
    }

    private var groupContext: UPCheckboxGroupContext {
        let selection = selectionBinding
        let handler = onChangeHandler
        return UPCheckboxGroupContext(
            values: selection,
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
            setChecked: { name, isChecked in
                let updated = Self.updatedValues(selection.wrappedValue, name: name, isChecked: isChecked)
                selection.wrappedValue = updated
                handler?(updated, UPCheckboxGroupChange(name: name, isChecked: isChecked))
            }
        )
    }
}

public extension UPCheckboxGroup where Content == EmptyView {
    /// Creates an empty group, matching `<u-checkbox-group />`.
    init<Size: UPCheckboxUnitValue, LabelSize: UPCheckboxUnitValue, IconSize: UPCheckboxUnitValue>(
        customClass: String = UPConfig.checkboxGroup.customClass,
        name: String = UPConfig.checkboxGroup.name,
        modelValue: Binding<[UPCheckboxName]>? = nil,
        value: [UPCheckboxName] = UPConfig.checkboxGroup.value,
        shape: String = UPConfig.checkboxGroup.shape,
        disabled: Bool = UPConfig.checkboxGroup.disabled,
        activeColor: String = UPConfig.checkboxGroup.activeColor,
        inactiveColor: String = UPConfig.checkboxGroup.inactiveColor,
        size: Size = UPConfig.checkboxGroup.size,
        placement: String = UPConfig.checkboxGroup.placement,
        labelSize: LabelSize = UPConfig.checkboxGroup.labelSize,
        labelColor: String = UPConfig.checkboxGroup.labelColor,
        labelDisabled: Bool = UPConfig.checkboxGroup.labelDisabled,
        iconColor: String = UPConfig.checkboxGroup.iconColor,
        iconSize: IconSize = UPConfig.checkboxGroup.iconSize,
        iconPlacement: String = UPConfig.checkboxGroup.iconPlacement,
        borderBottom: Bool = UPConfig.checkboxGroup.borderBottom,
        customStyle: UPStyle = UPConfig.checkboxGroup.customStyle,
        onChange: (([UPCheckboxName], UPCheckboxGroupChange) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            name: name,
            modelValue: modelValue,
            value: value,
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
            customStyle: customStyle,
            onChange: onChange
        ) {
            EmptyView()
        }
    }
}

public extension UPCheckboxGroup {
    /// Registers the uview-plus `change(values, { isChecked, name })` callback.
    func onChange(_ action: @escaping ([UPCheckboxName], UPCheckboxGroupChange) -> Void) -> UPCheckboxGroup {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }
}
