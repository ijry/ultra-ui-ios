import SwiftUI

/// Typed value accepted by uview-plus `u-switch` `modelValue`, `value`,
/// `activeValue`, and `inactiveValue` props.
///
/// Reusing the checkbox identity representation preserves Vue's strict
/// distinction between string, numeric, and boolean values. For example,
/// `"1"`, `1`, and `true` are different switch values.
public typealias UPSwitchValue = UPCheckboxName
public typealias UPSwitchValueInput = UPCheckboxNameValue
public typealias UPSwitchUnitValue = UPCheckboxUnitValue

/// Values whose native SwiftUI bindings can be bridged to ``UPSwitchValue``.
///
/// The uview-plus component accepts strings, numbers, and booleans. This
/// protocol keeps a `Binding<Bool>`, `Binding<String>`, or numeric binding
/// ergonomic while retaining the value identity used by the upstream API.
public protocol UPSwitchBindingValue: UPCheckboxNameValue {
    static func upSwitchBindingValue(from value: UPSwitchValue) -> Self?
}

extension UPSwitchValue: UPSwitchBindingValue {
    public static func upSwitchBindingValue(from value: UPSwitchValue) -> UPSwitchValue? {
        value
    }
}

extension String: UPSwitchBindingValue {
    public static func upSwitchBindingValue(from value: UPSwitchValue) -> String? {
        guard case .string(let string) = value else { return nil }
        return string
    }
}

extension Bool: UPSwitchBindingValue {
    public static func upSwitchBindingValue(from value: UPSwitchValue) -> Bool? {
        guard case .boolean(let boolean) = value else { return nil }
        return boolean
    }
}

public extension UPSwitchBindingValue where Self: BinaryInteger {
    static func upSwitchBindingValue(from value: UPSwitchValue) -> Self? {
        guard case .number(let number) = value else { return nil }
        return Self(exactly: number)
    }
}

extension Int: UPSwitchBindingValue {}
extension Int8: UPSwitchBindingValue {}
extension Int16: UPSwitchBindingValue {}
extension Int32: UPSwitchBindingValue {}
extension Int64: UPSwitchBindingValue {}
extension UInt: UPSwitchBindingValue {}
extension UInt8: UPSwitchBindingValue {}
extension UInt16: UPSwitchBindingValue {}
extension UInt32: UPSwitchBindingValue {}
extension UInt64: UPSwitchBindingValue {}

public extension UPSwitchBindingValue where Self: BinaryFloatingPoint {
    static func upSwitchBindingValue(from value: UPSwitchValue) -> Self? {
        guard case .number(let number) = value, number.isFinite else { return nil }
        return Self(number)
    }
}

extension Double: UPSwitchBindingValue {}
extension Float: UPSwitchBindingValue {}
extension CGFloat: UPSwitchBindingValue {}

/// Native SwiftUI counterpart of uview-plus `u-switch`.
///
/// `modelValue` maps directly to a native binding. The binding overloads
/// preserve uview-plus's String/Number/Boolean value contract:
///
/// ```swift
/// @State private var status = "off"
///
/// UPSwitch(
///     modelValue: $status,
///     activeValue: "on",
///     inactiveValue: "off"
/// )
/// ```
///
/// Set `asyncChange` when the `change` callback should receive the proposed
/// value without the component writing the binding; this mirrors the upstream
/// caller-controlled asynchronous change behavior.
@MainActor
public struct UPSwitch: View {
    var customClass: String
    var loading: Bool
    var disabled: Bool
    var size: String
    var activeColor: String
    var inactiveColor: String
    var dotActiveColor: String
    var dotInactiveColor: String
    var value: UPSwitchValue
    var activeValue: UPSwitchValue
    var inactiveValue: UPSwitchValue
    var asyncChange: Bool
    var space: String
    var customStyle: UPStyle

    private var modelValue: Binding<UPSwitchValue>?
    private var onChangeHandler: ((UPSwitchValue) -> Void)?
    @State private var localValue: UPSwitchValue
    @Environment(\.upTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init<Size: UPSwitchUnitValue, Value: UPSwitchValueInput, ActiveValue: UPSwitchValueInput, InactiveValue: UPSwitchValueInput, Space: UPSwitchUnitValue>(
        customClass: String = UPConfig.`switch`.customClass,
        loading: Bool = UPConfig.`switch`.loading,
        disabled: Bool = UPConfig.`switch`.disabled,
        size: Size = UPConfig.`switch`.size,
        activeColor: String = UPConfig.`switch`.activeColor,
        inactiveColor: String = UPConfig.`switch`.inactiveColor,
        dotActiveColor: String = UPConfig.`switch`.dotActiveColor,
        dotInactiveColor: String = UPConfig.`switch`.dotInactiveColor,
        value: Value = UPConfig.`switch`.value,
        activeValue: ActiveValue = UPConfig.`switch`.activeValue,
        inactiveValue: InactiveValue = UPConfig.`switch`.inactiveValue,
        asyncChange: Bool = UPConfig.`switch`.asyncChange,
        space: Space = UPConfig.`switch`.space,
        customStyle: UPStyle = UPConfig.`switch`.customStyle,
        onChange: ((UPSwitchValue) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            loading: loading,
            disabled: disabled,
            size: size.upCheckboxUnitValue,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            dotActiveColor: dotActiveColor,
            dotInactiveColor: dotInactiveColor,
            modelValue: nil,
            value: value.upCheckboxNameValue,
            activeValue: activeValue.upCheckboxNameValue,
            inactiveValue: inactiveValue.upCheckboxNameValue,
            asyncChange: asyncChange,
            space: space.upCheckboxUnitValue,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    /// Native `Binding` equivalent of the Vue 3 `v-model:modelValue` surface.
    public init<Model: UPSwitchBindingValue, Size: UPSwitchUnitValue, ActiveValue: UPSwitchValueInput, InactiveValue: UPSwitchValueInput, Space: UPSwitchUnitValue>(
        customClass: String = UPConfig.`switch`.customClass,
        loading: Bool = UPConfig.`switch`.loading,
        disabled: Bool = UPConfig.`switch`.disabled,
        size: Size = UPConfig.`switch`.size,
        activeColor: String = UPConfig.`switch`.activeColor,
        inactiveColor: String = UPConfig.`switch`.inactiveColor,
        dotActiveColor: String = UPConfig.`switch`.dotActiveColor,
        dotInactiveColor: String = UPConfig.`switch`.dotInactiveColor,
        modelValue: Binding<Model>,
        activeValue: ActiveValue = UPConfig.`switch`.activeValue,
        inactiveValue: InactiveValue = UPConfig.`switch`.inactiveValue,
        asyncChange: Bool = UPConfig.`switch`.asyncChange,
        space: Space = UPConfig.`switch`.space,
        customStyle: UPStyle = UPConfig.`switch`.customStyle,
        onChange: ((UPSwitchValue) -> Void)? = nil
    ) {
        let erasedBinding = Self.erase(modelValue)
        self.init(
            customClass: customClass,
            loading: loading,
            disabled: disabled,
            size: size.upCheckboxUnitValue,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            dotActiveColor: dotActiveColor,
            dotInactiveColor: dotInactiveColor,
            modelValue: erasedBinding,
            value: erasedBinding.wrappedValue,
            activeValue: activeValue.upCheckboxNameValue,
            inactiveValue: inactiveValue.upCheckboxNameValue,
            asyncChange: asyncChange,
            space: space.upCheckboxUnitValue,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    private init(
        customClass: String,
        loading: Bool,
        disabled: Bool,
        size: String,
        activeColor: String,
        inactiveColor: String,
        dotActiveColor: String,
        dotInactiveColor: String,
        modelValue: Binding<UPSwitchValue>?,
        value: UPSwitchValue,
        activeValue: UPSwitchValue,
        inactiveValue: UPSwitchValue,
        asyncChange: Bool,
        space: String,
        customStyle: UPStyle,
        onChange: ((UPSwitchValue) -> Void)?
    ) {
        self.customClass = customClass
        self.loading = loading
        self.disabled = disabled
        self.size = size
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.dotActiveColor = dotActiveColor
        self.dotInactiveColor = dotInactiveColor
        self.modelValue = modelValue
        self.value = value
        self.activeValue = activeValue
        self.inactiveValue = inactiveValue
        self.asyncChange = asyncChange
        self.space = space
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self._localValue = State(initialValue: modelValue?.wrappedValue ?? value)
    }

    public var body: some View {
        Button(action: triggerTap) {
            switchControl
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading)
        .opacity(disabled ? 0.6 : 1)
        .upStyle(customStyle)
        .onChange(of: value) { _, newValue in
            guard modelValue == nil else { return }
            $localValue.wrappedValue = newValue
        }
    }

    /// Whether the currently resolved model value equals `activeValue` using
    /// the same strict identity semantics as the upstream component.
    var isActive: Bool {
        Self.isActive(value: currentValue, activeValue: activeValue)
    }

    var resolvedSize: CGFloat {
        let parsed = UPUnit.parse(size)
        return parsed > 0 ? parsed : 25
    }

    var resolvedSpace: CGFloat {
        let parsed = UPUnit.parse(space)
        return min(max(parsed, 0), resolvedSize)
    }

    var resolvedTrackWidth: CGFloat {
        resolvedSize * 2 + 2
    }

    var resolvedTrackHeight: CGFloat {
        resolvedSize + 2
    }

    var resolvedNodeSize: CGFloat {
        max(resolvedSize - resolvedSpace, 0)
    }

    /// Native/testable counterpart of tapping the upstream switch wrapper.
    /// Loading and disabled switches intentionally do nothing.
    func triggerTap() {
        guard !disabled, !loading else { return }
        let proposedValue = Self.nextValue(
            current: currentValue,
            activeValue: activeValue,
            inactiveValue: inactiveValue
        )
        if !asyncChange {
            selectionBinding.wrappedValue = proposedValue
        }
        // Upstream emits `change` after its v-model update. Binding writes are
        // synchronous in SwiftUI, so the callback observes the same ordering.
        onChangeHandler?(proposedValue)
    }

    /// Strict-equality state resolution for String/Number/Boolean switch values.
    public static func isActive(value: UPSwitchValue, activeValue: UPSwitchValue) -> Bool {
        value == activeValue
    }

    /// Computes the candidate emitted by a permitted switch interaction.
    public static func nextValue(
        current: UPSwitchValue,
        activeValue: UPSwitchValue,
        inactiveValue: UPSwitchValue
    ) -> UPSwitchValue {
        isActive(value: current, activeValue: activeValue) ? inactiveValue : activeValue
    }

    private static func erase<Model: UPSwitchBindingValue>(_ binding: Binding<Model>) -> Binding<UPSwitchValue> {
        Binding<UPSwitchValue>(
            get: { binding.wrappedValue.upCheckboxNameValue },
            set: { incomingValue in
                guard let typedValue = Model.upSwitchBindingValue(from: incomingValue) else { return }
                binding.wrappedValue = typedValue
            }
        )
    }

    private var currentValue: UPSwitchValue {
        modelValue?.wrappedValue ?? localValue
    }

    private var selectionBinding: Binding<UPSwitchValue> {
        modelValue ?? $localValue
    }

    private var nodeHorizontalInset: CGFloat {
        max((resolvedTrackHeight - resolvedNodeSize) / 2, 0)
    }

    private var nodeOffset: CGFloat {
        let leading = nodeHorizontalInset
        let trailing = max(resolvedTrackWidth - resolvedNodeSize - nodeHorizontalInset, leading)
        return isActive ? trailing : leading
    }

    private var isCustomInactiveColor: Bool {
        inactiveColor != UPConfig.`switch`.inactiveColor
    }

    private var resolvedActiveTrackColor: Color {
        if activeColor.isEmpty || activeColor == UPConfig.`switch`.activeColor {
            return theme.primary
        }
        return UPColor.parse(activeColor, theme: theme)
    }

    private var resolvedInactiveTrackColor: Color {
        if inactiveColor.isEmpty || inactiveColor == UPConfig.`switch`.inactiveColor {
            return colorScheme == .dark ? UPColor.parse("#3a3a3c", theme: theme) : .white
        }
        return UPColor.parse(inactiveColor, theme: theme)
    }

    private var resolvedActiveDotColor: Color {
        if dotActiveColor.isEmpty || dotActiveColor == UPConfig.`switch`.dotActiveColor {
            return .white
        }
        return UPColor.parse(dotActiveColor, theme: theme)
    }

    private var resolvedInactiveDotColor: Color {
        if dotInactiveColor.isEmpty || dotInactiveColor == UPConfig.`switch`.dotInactiveColor {
            return colorScheme == .dark ? UPColor.parse("#d1d5db", theme: theme) : .white
        }
        return UPColor.parse(dotInactiveColor, theme: theme)
    }

    private var resolvedLoadingColor: Color {
        isActive
            ? resolvedActiveTrackColor
            : (colorScheme == .dark ? UPColor.parse("#9ca3af", theme: theme) : UPColor.parse("#aaabad", theme: theme))
    }

    private var resolvedTrackColor: Color {
        isActive ? resolvedActiveTrackColor : resolvedInactiveTrackColor
    }

    private var resolvedNodeColor: Color {
        isActive ? resolvedActiveDotColor : resolvedInactiveDotColor
    }

    private var resolvedBorderColor: Color {
        isCustomInactiveColor || isActive
            ? .clear
            : Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12)
    }

    private var switchControl: some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(resolvedTrackColor)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(resolvedBorderColor, lineWidth: 1)
                }

            Circle()
                .fill(resolvedNodeColor)
                .shadow(color: .black.opacity(0.25), radius: 1, x: 1, y: 1)
                .overlay {
                    if loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(resolvedLoadingColor)
                            .scaleEffect(max(resolvedNodeSize / 38, 0.1))
                    }
                }
                .frame(width: resolvedNodeSize, height: resolvedNodeSize)
                .offset(x: nodeOffset)
        }
        .frame(width: resolvedTrackWidth, height: resolvedTrackHeight)
        .clipShape(Capsule(style: .continuous))
        .contentShape(Capsule(style: .continuous))
        .animation(.easeInOut(duration: 0.4), value: isActive)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityValue(isActive ? "on" : "off")
    }
}

public extension UPSwitch {
    /// Registers the uview-plus `change(value)` event callback.
    func onChange(_ action: @escaping (UPSwitchValue) -> Void) -> UPSwitch {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }
}
