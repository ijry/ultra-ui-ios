import SwiftUI

/// Semantic alias for the `String | Number` sizing props accepted by
/// uview-plus `u-search`.
public typealias UPSearchUnitValue = UPCheckboxUnitValue

/// Imperative access to a mounted ``UPSearch`` instance.
///
/// The controller deliberately stores actions rather than a UIKit text-field
/// reference. This keeps the public surface usable from SwiftUI and leaves
/// room for a future Fastview adapter to provide its own native focus bridge.
@MainActor
public final class UPSearchController: ObservableObject {
    private enum Action {
        case focus
        case blur
        case clear
    }

    private var focusHandler: (() -> Void)?
    private var blurHandler: (() -> Void)?
    private var clearHandler: (() -> Void)?
    private var pendingActions: [Action] = []

    public init() {}

    /// Requests that the search field become first responder when mounted.
    public func focus() {
        dispatch(.focus)
    }

    /// Requests that the search field resign focus when mounted.
    public func blur() {
        dispatch(.blur)
    }

    /// Clears the mounted search value through the same event pipeline as the
    /// visible clear button.
    public func clear() {
        dispatch(.clear)
    }

    /// Connects the controller to the current SwiftUI view instance.
    ///
    /// Actions issued before mounting are replayed in their original order.
    func register(
        focus: @escaping () -> Void,
        blur: @escaping () -> Void,
        clear: @escaping () -> Void
    ) {
        focusHandler = focus
        blurHandler = blur
        clearHandler = clear

        let pending = pendingActions
        pendingActions.removeAll(keepingCapacity: true)
        pending.forEach(execute)
    }

    /// Disconnects the controller from a disappearing view. Subsequent
    /// imperative calls are queued until another view registers.
    func unregister() {
        focusHandler = nil
        blurHandler = nil
        clearHandler = nil
    }

    private func dispatch(_ action: Action) {
        switch action {
        case .focus:
            if let focusHandler {
                focusHandler()
            } else {
                pendingActions.append(action)
            }
        case .blur:
            if let blurHandler {
                blurHandler()
            } else {
                pendingActions.append(action)
            }
        case .clear:
            if let clearHandler {
                clearHandler()
            } else {
                pendingActions.append(action)
            }
        }
    }

    private func execute(_ action: Action) {
        switch action {
        case .focus:
            focusHandler?()
        case .blur:
            blurHandler?()
        case .clear:
            clearHandler?()
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-search`.
///
/// The component keeps the upstream prop spellings—including `clearabled`—and
/// exposes SwiftUI event modifiers with the same event names and payloads.
@MainActor
public struct UPSearch: View {
    var value: Binding<String>?
    var label: String
    var shape: String
    var bgColor: String
    var placeholder: String
    var clearabled: Bool
    var clearable: Bool?
    var focus: Bool
    var showAction: Bool
    var actionText: String
    var inputAlign: String
    var disabled: Bool
    var animation: Bool
    var borderColor: String
    var searchIconColor: String
    var searchIconSize: String
    var color: String
    var placeholderColor: String
    var searchIcon: String
    var margin: String
    var iconPosition: String
    var maxlength: String
    var height: String
    var adjustPosition: Bool
    var autoBlur: Bool
    var onlyClearableOnFocused: Bool
    var inputStyle: UPStyle
    var actionStyle: UPStyle
    var customStyle: UPStyle

    var onChangeHandler: ((String) -> Void)?
    var onSearchHandler: ((String) -> Void)?
    var onCustomHandler: ((String) -> Void)?
    var onClearHandler: (() -> Void)?
    var onFocusHandler: ((String) -> Void)?
    var onBlurHandler: ((String) -> Void)?
    var onClickHandler: (() -> Void)?
    var onClickIconHandler: ((String) -> Void)?

    private var trailingContent: AnyView?
    @StateObject private var stateController: UPSearchController
    @State private var localValue: String
    @FocusState private var isFocused: Bool
    @Environment(\.upTheme) private var theme

    /// The native instance-control object corresponding to a uview-plus ref.
    public var controller: UPSearchController {
        stateController
    }

    /// Creates a search field without an additional input-right slot.
    public init<Label: UPCheckboxTextValue>(
        value: Binding<String>? = nil,
        shape: String = UPConfig.search.shape,
        bgColor: String = UPConfig.search.bgColor,
        placeholder: String = UPConfig.search.placeholder,
        clearabled: Bool = UPConfig.search.clearabled,
        clearable: Bool? = nil,
        focus: Bool = UPConfig.search.focus,
        showAction: Bool = UPConfig.search.showAction,
        actionText: String = UPConfig.search.actionText,
        label: Label = UPConfig.search.label ?? "",
        inputAlign: String = UPConfig.search.inputAlign,
        disabled: Bool = UPConfig.search.disabled,
        animation: Bool = UPConfig.search.animation,
        borderColor: String = UPConfig.search.borderColor,
        searchIconColor: String = UPConfig.search.searchIconColor,
        searchIconSize: some UPSearchUnitValue = UPConfig.search.searchIconSize,
        color: String = UPConfig.search.color,
        placeholderColor: String = UPConfig.search.placeholderColor,
        searchIcon: String = UPConfig.search.searchIcon,
        margin: some UPSearchUnitValue = UPConfig.search.margin,
        iconPosition: String = UPConfig.search.iconPosition,
        maxlength: some UPSearchUnitValue = UPConfig.search.maxlength,
        height: some UPSearchUnitValue = UPConfig.search.height,
        adjustPosition: Bool = UPConfig.search.adjustPosition,
        autoBlur: Bool = UPConfig.search.autoBlur,
        onlyClearableOnFocused: Bool = UPConfig.search.onlyClearableOnFocused,
        inputStyle: UPStyle = UPConfig.search.inputStyle,
        actionStyle: UPStyle = UPConfig.search.actionStyle,
        customStyle: UPStyle = UPConfig.search.customStyle,
        controller: UPSearchController? = nil,
        onChange: ((String) -> Void)? = nil,
        onSearch: ((String) -> Void)? = nil,
        onCustom: ((String) -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onFocus: ((String) -> Void)? = nil,
        onBlur: ((String) -> Void)? = nil,
        onClick: (() -> Void)? = nil,
        onClickIcon: ((String) -> Void)? = nil
    ) {
        self.value = value
        self.label = label.upCheckboxTextValue
        self.shape = shape
        self.bgColor = bgColor
        self.placeholder = placeholder
        self.clearabled = clearabled
        self.clearable = clearable
        self.focus = focus
        self.showAction = showAction
        self.actionText = actionText
        self.inputAlign = inputAlign
        self.disabled = disabled
        self.animation = animation
        self.borderColor = borderColor
        self.searchIconColor = searchIconColor
        self.searchIconSize = searchIconSize.upCheckboxUnitValue
        self.color = color
        self.placeholderColor = placeholderColor
        self.searchIcon = searchIcon
        self.margin = margin.upCheckboxUnitValue
        self.iconPosition = iconPosition
        self.maxlength = maxlength.upCheckboxUnitValue
        self.height = height.upCheckboxUnitValue
        self.adjustPosition = adjustPosition
        self.autoBlur = autoBlur
        self.onlyClearableOnFocused = onlyClearableOnFocused
        self.inputStyle = inputStyle
        self.actionStyle = actionStyle
        self.customStyle = customStyle
        // Disabled u-search instances are display shells: they retain the
        // upstream `click` callback, but suppress all input/action callbacks.
        self.onChangeHandler = disabled ? nil : onChange
        self.onSearchHandler = disabled ? nil : onSearch
        self.onCustomHandler = disabled ? nil : onCustom
        self.onClearHandler = disabled ? nil : onClear
        self.onFocusHandler = disabled ? nil : onFocus
        self.onBlurHandler = disabled ? nil : onBlur
        self.onClickHandler = onClick
        self.onClickIconHandler = disabled ? nil : onClickIcon
        self.trailingContent = nil

        let initialValue = Self.truncated(
            value?.wrappedValue ?? "",
            maxlength: Self.parseMaxlength(maxlength.upCheckboxUnitValue)
        )
        _localValue = State(initialValue: initialValue)
        _stateController = StateObject(wrappedValue: controller ?? UPSearchController())
    }

    /// Creates a search field with a SwiftUI slot in the right side of the
    /// input shell (the native counterpart of u-search's `inputRight` slot).
    public init<Content: View, Label: UPCheckboxTextValue>(
        value: Binding<String>? = nil,
        shape: String = UPConfig.search.shape,
        bgColor: String = UPConfig.search.bgColor,
        placeholder: String = UPConfig.search.placeholder,
        clearabled: Bool = UPConfig.search.clearabled,
        clearable: Bool? = nil,
        focus: Bool = UPConfig.search.focus,
        showAction: Bool = UPConfig.search.showAction,
        actionText: String = UPConfig.search.actionText,
        label: Label = UPConfig.search.label ?? "",
        inputAlign: String = UPConfig.search.inputAlign,
        disabled: Bool = UPConfig.search.disabled,
        animation: Bool = UPConfig.search.animation,
        borderColor: String = UPConfig.search.borderColor,
        searchIconColor: String = UPConfig.search.searchIconColor,
        searchIconSize: some UPSearchUnitValue = UPConfig.search.searchIconSize,
        color: String = UPConfig.search.color,
        placeholderColor: String = UPConfig.search.placeholderColor,
        searchIcon: String = UPConfig.search.searchIcon,
        margin: some UPSearchUnitValue = UPConfig.search.margin,
        iconPosition: String = UPConfig.search.iconPosition,
        maxlength: some UPSearchUnitValue = UPConfig.search.maxlength,
        height: some UPSearchUnitValue = UPConfig.search.height,
        adjustPosition: Bool = UPConfig.search.adjustPosition,
        autoBlur: Bool = UPConfig.search.autoBlur,
        onlyClearableOnFocused: Bool = UPConfig.search.onlyClearableOnFocused,
        inputStyle: UPStyle = UPConfig.search.inputStyle,
        actionStyle: UPStyle = UPConfig.search.actionStyle,
        customStyle: UPStyle = UPConfig.search.customStyle,
        controller: UPSearchController? = nil,
        onChange: ((String) -> Void)? = nil,
        onSearch: ((String) -> Void)? = nil,
        onCustom: ((String) -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onFocus: ((String) -> Void)? = nil,
        onBlur: ((String) -> Void)? = nil,
        onClick: (() -> Void)? = nil,
        onClickIcon: ((String) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            value: value,
            shape: shape,
            bgColor: bgColor,
            placeholder: placeholder,
            clearabled: clearabled,
            clearable: clearable,
            focus: focus,
            showAction: showAction,
            actionText: actionText,
            label: label,
            inputAlign: inputAlign,
            disabled: disabled,
            animation: animation,
            borderColor: borderColor,
            searchIconColor: searchIconColor,
            searchIconSize: searchIconSize,
            color: color,
            placeholderColor: placeholderColor,
            searchIcon: searchIcon,
            margin: margin,
            iconPosition: iconPosition,
            maxlength: maxlength,
            height: height,
            adjustPosition: adjustPosition,
            autoBlur: autoBlur,
            onlyClearableOnFocused: onlyClearableOnFocused,
            inputStyle: inputStyle,
            actionStyle: actionStyle,
            customStyle: customStyle,
            controller: controller,
            onChange: onChange,
            onSearch: onSearch,
            onCustom: onCustom,
            onClear: onClear,
            onFocus: onFocus,
            onBlur: onBlur,
            onClick: onClick,
            onClickIcon: onClickIcon
        )
        self.trailingContent = AnyView(content())
    }

    /// Convenience initializer for the common Swift ordering of the three
    /// string-or-number sizing props. The primary initializer retains the
    /// upstream prop declaration order; this overload keeps named Swift calls
    /// ergonomic when only these sizing values are customized.
    public init<Maxlength: UPSearchUnitValue, Height: UPSearchUnitValue, IconSize: UPSearchUnitValue>(
        maxlength: Maxlength,
        height: Height,
        searchIconSize: IconSize
    ) {
        self.init(
            searchIconSize: searchIconSize,
            maxlength: maxlength,
            height: height
        )
    }

    /// Convenience initializer matching the focus-first callback ordering
    /// commonly used when a search field only needs lifecycle callbacks.
    public init(
        onFocus: @escaping (String) -> Void,
        onBlur: @escaping (String) -> Void,
        onSearch: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
        onClickIcon: @escaping (String) -> Void
    ) {
        self.init(
            onSearch: onSearch,
            onClear: onClear,
            onFocus: onFocus,
            onBlur: onBlur,
            onClickIcon: onClickIcon
        )
    }

    /// Convenience initializer matching disabled-shell callback usage.
    public init(
        disabled: Bool,
        onClick: @escaping () -> Void,
        onCustom: @escaping (String) -> Void,
        onClear: @escaping () -> Void
    ) {
        self.init(
            disabled: disabled,
            onCustom: onCustom,
            onClear: onClear,
            onClick: onClick
        )
    }

    public var body: some View {
        HStack(spacing: 5) {
            searchShell
            if shouldShowAction {
                actionButton
            }
        }
        .padding(.top, resolvedMargin.top)
        .padding(.leading, resolvedMargin.leading)
        .padding(.bottom, resolvedMargin.bottom)
        .padding(.trailing, resolvedMargin.trailing)
        .animation(animation ? .easeInOut(duration: 0.3) : nil, value: isFocused)
        .upStyle(customStyle)
        .contentShape(Rectangle())
        .onTapGesture {
            if disabled {
                onClickHandler?()
            }
        }
        .onAppear(perform: mount)
        .onDisappear {
            stateController.unregister()
        }
        .onChange(of: isFocused) { _, focused in
            handleFocusChange(focused)
        }
        .onChange(of: externalValue) { _, newValue in
            synchronizeExternalValue(newValue)
        }
        .onChange(of: maxlength) { _, _ in
            synchronizeExternalValue(externalValue)
        }
        .onChange(of: focus) { _, shouldFocus in
            isFocused = !disabled && shouldFocus
        }
        .onChange(of: disabled) { _, isDisabled in
            if isDisabled {
                isFocused = false
            }
        }
    }

    // MARK: - Testable normalization and event helpers

    static func normalizedShape(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "round": return "round"
        default: return "square"
        }
    }

    static func normalizedIconPosition(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "right" ? "right" : "left"
    }

    static func normalizedAlignment(_ value: String) -> TextAlignment {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "center": return .center
        case "right", "trailing", "end": return .trailing
        default: return .leading
        }
    }

    static func parseMaxlength(_ value: String) -> Int? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(normalized), parsed >= 0 else {
            return nil
        }
        return parsed
    }

    static func parseMaxlength(_ value: NSNumber) -> Int? {
        parseMaxlength(value.stringValue)
    }

    static func parseMaxlength<T: UPSearchUnitValue>(_ value: T) -> Int? {
        parseMaxlength(value.upCheckboxUnitValue)
    }

    static func truncated(_ value: String, maxlength: Int?) -> String {
        guard let maxlength, maxlength >= 0 else { return value }
        return String(value.prefix(maxlength))
    }

    /// Emits the normalized change event before mutating the supplied binding.
    @discardableResult
    static func commit(
        _ proposedValue: String,
        binding: Binding<String>?,
        maxlength: Int?,
        onChange: ((String) -> Void)? = nil
    ) -> String {
        let normalized = truncated(proposedValue, maxlength: maxlength)
        onChange?(normalized)
        binding?.wrappedValue = normalized
        return normalized
    }

    /// Convenience overload used by callers with a non-optional binding.
    @discardableResult
    static func commit(
        _ proposedValue: String,
        binding: Binding<String>,
        maxlength: Int?,
        onChange: ((String) -> Void)? = nil
    ) -> String {
        commit(proposedValue, binding: Optional(binding), maxlength: maxlength, onChange: onChange)
    }

    static func shouldShowClear(
        value: String,
        clearabled: Bool,
        focused: Bool,
        onlyClearableOnFocused: Bool
    ) -> Bool {
        guard clearabled, !value.isEmpty else { return false }
        return !onlyClearableOnFocused || focused
    }

    var resolvedShape: String {
        Self.normalizedShape(shape)
    }

    var resolvedIconPosition: String {
        Self.normalizedIconPosition(iconPosition)
    }

    var resolvedAlignment: TextAlignment {
        Self.normalizedAlignment(inputAlign)
    }

    var resolvedMaxlength: Int? {
        Self.parseMaxlength(maxlength)
    }

    var resolvedHeight: CGFloat {
        let parsed = UPUnit.parse(height)
        guard parsed.isFinite, parsed > 0 else { return CGFloat(UPConfig.search.height) }
        return parsed
    }

    var resolvedSearchIconSize: CGFloat {
        let parsed = UPUnit.parse(searchIconSize)
        guard parsed.isFinite, parsed > 0 else { return CGFloat(UPConfig.search.searchIconSize) }
        return parsed
    }

    var resolvedClearable: Bool {
        clearable ?? clearabled
    }

    var resolvedMargin: UPInsets {
        UPStyle(["margin": margin]).margin
    }

    var resolvedShowsAction: Bool {
        showAction && (!animation || isFocused)
    }

    // MARK: - Native rendering

    private var currentValue: String {
        Self.truncated(value?.wrappedValue ?? localValue, maxlength: resolvedMaxlength)
    }

    private var externalValue: String? {
        value?.wrappedValue
    }

    private var shouldShowClearButton: Bool {
        Self.shouldShowClear(
            value: currentValue,
            clearabled: resolvedClearable,
            focused: isFocused,
            onlyClearableOnFocused: onlyClearableOnFocused
        ) && !disabled
    }

    private var shouldShowAction: Bool {
        resolvedShowsAction
    }

    @ViewBuilder
    private var searchShell: some View {
        HStack(spacing: 5) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(resolvedTextColor)
                    .padding(.horizontal, 4)
            }

            if resolvedIconPosition == "left" {
                searchIconButton
            }

            textField
                .frame(maxWidth: .infinity)

            if resolvedIconPosition == "right" {
                searchIconButton
            }

            if shouldShowClearButton {
                clearButton
            }

            if let trailingContent {
                trailingContent
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: resolvedHeight)
        .background(resolvedBackground)
        .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius))
        .overlay {
            if let resolvedBorderColor {
                RoundedRectangle(cornerRadius: resolvedCornerRadius)
                    .stroke(resolvedBorderColor, lineWidth: 1)
            }
        }
    }

    private var textField: some View {
        TextField(
            text: textBinding,
            prompt: Text(placeholder).foregroundStyle(resolvedPlaceholderColor)
        ) {
            Text(placeholder)
        }
            .multilineTextAlignment(resolvedAlignment)
            .foregroundStyle(resolvedTextColor)
            .tint(resolvedTextColor)
            .submitLabel(.search)
            .focused($isFocused)
            .disabled(disabled)
            .frame(maxWidth: .infinity)
            .upStyle(inputStyle)
            .onSubmit {
                submitSearch()
            }
    }

    private var searchIconButton: some View {
        Button(action: handleIconTap) {
            UPIcon(
                name: searchIcon,
                color: resolvedSearchIconColorValue,
                size: "\(resolvedSearchIconSize)px"
            )
            .frame(minWidth: resolvedSearchIconSize, minHeight: resolvedSearchIconSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var clearButton: some View {
        Button(action: clearValue) {
            ZStack {
                Circle()
                    .fill(theme.light)
                UPIcon(name: "close", color: "#ffffff", size: "11px")
            }
            .frame(width: 20, height: 20)
            .scaleEffect(0.82)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel("清除")
    }

    private var actionButton: some View {
        Button(action: customAction) {
            Text(actionText)
                .font(.system(size: 14))
                .foregroundStyle(theme.main)
                .frame(minHeight: resolvedHeight)
                .padding(.horizontal, 2)
                .upStyle(actionStyle)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { currentValue },
            set: { proposedValue in
                commitValue(proposedValue)
            }
        )
    }

    private var resolvedTextColor: Color {
        if color.isEmpty {
            return disabled ? theme.disabled : theme.content
        }
        return UPColor.parse(color, theme: theme)
    }

    private var resolvedPlaceholderColor: Color {
        if placeholderColor.isEmpty {
            return theme.tips
        }
        return UPColor.parse(placeholderColor, theme: theme)
    }

    private var resolvedSearchIconColorValue: String {
        if disabled {
            return "disabled"
        }
        if !searchIconColor.isEmpty {
            return searchIconColor
        }
        return color.isEmpty ? "content" : color
    }

    private var resolvedBackground: Color {
        if bgColor.isEmpty {
            return theme.bg
        }
        return UPColor.parse(bgColor, theme: theme)
    }

    private var resolvedBorderColor: Color? {
        let normalized = borderColor.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != "transparent" else { return nil }
        return UPColor.parse(borderColor, theme: theme)
    }

    private var resolvedCornerRadius: CGFloat {
        resolvedShape == "round" ? resolvedHeight / 2 : 4
    }

    private func mount() {
        stateController.register(
            focus: {
                guard !disabled else { return }
                isFocused = true
            },
            blur: {
                isFocused = false
            },
            clear: {
                clearValue()
            }
        )
        synchronizeExternalValue(externalValue)
        if focus, !disabled {
            isFocused = true
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        let text = currentValue
        if focused {
            onFocusHandler?(text)
        } else {
            onBlurHandler?(text)
        }
    }

    private func synchronizeExternalValue(_ incoming: String?) {
        guard let incoming else { return }
        let normalized = Self.truncated(incoming, maxlength: resolvedMaxlength)
        guard normalized != incoming else { return }
        value?.wrappedValue = normalized
    }

    private func commitValue(_ proposedValue: String) {
        let normalized = Self.truncated(proposedValue, maxlength: resolvedMaxlength)
        onChangeHandler?(normalized)
        if let value {
            value.wrappedValue = normalized
        } else {
            localValue = normalized
        }
    }

    private func clearValue() {
        guard !disabled else { return }
        onClearHandler?()
        commitValue("")
    }

    private func submitSearch() {
        guard !disabled else { return }
        onSearchHandler?(currentValue)
        if autoBlur {
            isFocused = false
        }
    }

    private func customAction() {
        guard !disabled else { return }
        onCustomHandler?(currentValue)
        if autoBlur {
            isFocused = false
        }
    }

    private func handleIconTap() {
        guard !disabled else { return }
        onClickIconHandler?(currentValue)
        if autoBlur {
            isFocused = false
        }
    }
}

public extension UPSearch {
    /// Registers the upstream `change` event callback.
    func onChange(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onChangeHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream `search` event callback.
    func onSearch(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onSearchHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream `custom` event callback.
    func onCustom(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onCustomHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream `clear` event callback.
    func onClear(_ action: @escaping () -> Void) -> UPSearch {
        var copy = self
        copy.onClearHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream `focus` event callback.
    func onFocus(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onFocusHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream `blur` event callback.
    func onBlur(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onBlurHandler = copy.disabled ? nil : action
        return copy
    }

    /// Registers the upstream disabled-shell `click` event callback.
    func onClick(_ action: @escaping () -> Void) -> UPSearch {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    /// Registers the upstream search-icon `clickIcon` event callback.
    func onClickIcon(_ action: @escaping (String) -> Void) -> UPSearch {
        var copy = self
        copy.onClickIconHandler = copy.disabled ? nil : action
        return copy
    }
}
