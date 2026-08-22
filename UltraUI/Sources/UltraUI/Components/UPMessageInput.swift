import SwiftUI

/// Observable state backing ``UPMessageInput``, mirroring a uview-plus
/// component ref. Matches the controller shape used by
/// ``UPCodeInputController`` so the value survives SwiftUI view rebuilds and
/// mutations redraw the cells.
@MainActor
public final class UPMessageInputController: ObservableObject {
    @Published public private(set) var inputValue: String
    @Published public private(set) var isFocused = false

    private var maxlength: Int
    private var onChangeHandler: ((String) -> Void)?
    private var onFinishHandler: ((String) -> Void)?
    private var onModelValueUpdateHandler: ((String) -> Void)?
    private var onFocusHandler: (() -> Void)?
    private var onBlurHandler: (() -> Void)?

    /// External writes are clamped the way the upstream `modelValue` watcher
    /// does with `substring(0, maxlength)`.
    public init(value: String = UPConfig.messageInput.value,
                maxlength: Int = UPConfig.messageInput.maxlength) {
        let resolvedMaxlength = Swift.max(0, maxlength)
        self.maxlength = resolvedMaxlength
        self.inputValue = String(value.prefix(resolvedMaxlength))
    }

    func register(maxlength: Int,
                  onChange: ((String) -> Void)?,
                  onFinish: ((String) -> Void)?,
                  onModelValueUpdate: ((String) -> Void)?,
                  onFocus: (() -> Void)?,
                  onBlur: (() -> Void)?) {
        let resolvedMaxlength = Swift.max(0, maxlength)
        if resolvedMaxlength != self.maxlength {
            self.maxlength = resolvedMaxlength
            inputValue = String(inputValue.prefix(resolvedMaxlength))
        }
        onChangeHandler = onChange
        onFinishHandler = onFinish
        onModelValueUpdateHandler = onModelValueUpdate
        onFocusHandler = onFocus
        onBlurHandler = onBlur
    }

    func setOnChangeHandler(_ handler: ((String) -> Void)?) {
        onChangeHandler = handler
    }

    func setOnFinishHandler(_ handler: ((String) -> Void)?) {
        onFinishHandler = handler
    }

    func setOnFocusHandler(_ handler: (() -> Void)?) {
        onFocusHandler = handler
    }

    func setOnBlurHandler(_ handler: (() -> Void)?) {
        onBlurHandler = handler
    }

    func setOnModelValueUpdateHandler(_ handler: ((String) -> Void)?) {
        onModelValueUpdateHandler = handler
    }

    /// Applies user input using the upstream `getVal` contract: the value is
    /// stored, but anything longer than `maxlength` stops there without
    /// emitting `change` or `finish`.
    public func input(_ value: String) {
        guard UPMessageInput.accepts(value, maxlength: maxlength) else { return }
        inputValue = value
        onModelValueUpdateHandler?(value)
        onChangeHandler?(value)
        if value.count == maxlength {
            onFinishHandler?(value)
        }
    }

    /// Clamps an externally supplied value, matching the upstream watcher.
    func syncExternalValue(_ value: String) {
        let clamped = String(value.prefix(maxlength))
        guard clamped != inputValue else { return }
        inputValue = clamped
    }

    public func focus() {
        guard !isFocused else { return }
        isFocused = true
        onFocusHandler?()
    }

    public func blur() {
        guard isFocused else { return }
        isFocused = false
        onBlurHandler?()
    }

    func setFocused(_ focused: Bool) {
        if focused {
            focus()
        } else {
            blur()
        }
    }
}

/// A native SwiftUI counterpart of uview-plus `u-message-input`.
///
/// A transparent native `TextField` supplies keyboard and focus behavior while
/// the visible cells are drawn from the controller's value, the same split used
/// by ``UPCodeInput``.
@MainActor
public struct UPMessageInput: View {
    // uview-plus props.
    public var maxlength: Int
    public var mode: String
    public var dotFill: Bool
    public var breathe: Bool
    /// The upstream `focus` prop. Named ``autoFocus`` because the pre-existing
    /// imperative ``focus()`` already occupies that name on this type; the
    /// `focus:` initializer label still matches upstream.
    public var autoFocus: Bool
    public var bold: Bool
    public var fontSize: Double
    public var width: Double
    public var activeColor: String
    public var inactiveColor: String
    public var disabledKeyboard: Bool

    /// Existing native-only shorthands retained for source compatibility.
    public var disabled: Bool
    public var error: Bool

    private var modelValue: Binding<String>?

    // Vue emits represented as typed closures.
    private var onChangeHandler: ((String) -> Void)?
    private var onFinishHandler: ((String) -> Void)?
    /// Earlier native modifier hooks; upstream has no focus or blur emit.
    private var onFocusHandler: (() -> Void)?
    private var onBlurHandler: (() -> Void)?

    @StateObject private var stateController: UPMessageInputController
    @FocusState private var nativeInputIsFocused: Bool
    @Environment(\.upTheme) private var theme

    /// The native controller corresponding to a uview-plus component ref.
    public var controller: UPMessageInputController { stateController }

    public var inputValue: String { stateController.inputValue }

    public init(modelValue: Binding<String>? = nil,
                maxlength: some UPMessageInputUnitValue = UPConfig.messageInput.maxlength,
                mode: String = UPConfig.messageInput.mode,
                dotFill: Bool = UPConfig.messageInput.dotFill,
                breathe: Bool = UPConfig.messageInput.breathe,
                focus: Bool = UPConfig.messageInput.focus,
                bold: Bool = UPConfig.messageInput.bold,
                fontSize: some UPMessageInputUnitValue = UPConfig.messageInput.fontSize,
                width: some UPMessageInputUnitValue = UPConfig.messageInput.width,
                activeColor: String = UPConfig.messageInput.activeColor,
                inactiveColor: String = UPConfig.messageInput.inactiveColor,
                disabledKeyboard: Bool = UPConfig.messageInput.disabledKeyboard,
                disabled: Bool = UPConfig.messageInput.disabled,
                error: Bool = UPConfig.messageInput.error) {
        let resolvedMaxlength = Self.parseCount(
            maxlength.upCheckboxUnitValue,
            fallback: UPConfig.messageInput.maxlength
        )
        self.maxlength = resolvedMaxlength
        self.mode = mode
        self.dotFill = dotFill
        self.breathe = breathe
        self.autoFocus = focus
        self.bold = bold
        self.fontSize = Self.parseDimension(
            fontSize.upCheckboxUnitValue,
            fallback: UPConfig.messageInput.fontSize
        )
        self.width = Self.parseDimension(
            width.upCheckboxUnitValue,
            fallback: UPConfig.messageInput.width
        )
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.disabledKeyboard = disabledKeyboard
        self.disabled = disabled
        self.error = error
        self.modelValue = modelValue
        let activeController = UPMessageInputController(
            value: modelValue?.wrappedValue ?? UPConfig.messageInput.value,
            maxlength: resolvedMaxlength
        )
        activeController.setOnModelValueUpdateHandler(
            modelValue.map { binding in
                { binding.wrappedValue = $0 }
            }
        )
        _stateController = StateObject(wrappedValue: activeController)
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<max(0, maxlength), id: \.self) { index in
                cell(at: index)
            }
        }
        .overlay { nativeInput }
        .onAppear {
            mount()
            if autoFocus && !isInputDisabled {
                nativeInputIsFocused = true
            }
        }
        .onChange(of: autoFocus) { _, requestedFocus in
            if !isInputDisabled {
                nativeInputIsFocused = requestedFocus
            }
        }
        .onChange(of: modelValue?.wrappedValue ?? "") { _, newValue in
            stateController.syncExternalValue(newValue)
        }
    }

    /// Upstream `getVal` stores the raw value and returns early when it is
    /// longer than `maxlength`, so an over-length entry emits nothing.
    public static func accepts(_ value: String, maxlength: Int) -> Bool {
        value.count <= max(0, maxlength)
    }

    public static func resolvedMode(_ mode: String) -> String {
        switch mode {
        case "middleLine", "bottomLine": return mode
        default: return "box"
        }
    }

    /// Upstream only swaps in `activeColor` for the box border, and only for the
    /// cell sitting at the current fill position.
    public static func borderColorName(atIndex index: Int,
                                       filledCount: Int,
                                       mode: String,
                                       activeColor: String,
                                       inactiveColor: String) -> String {
        let isActive = index == filledCount && resolvedMode(mode) == "box"
        return isActive ? activeColor : inactiveColor
    }

    public static func isBreathing(atIndex index: Int, filledCount: Int, breathe: Bool) -> Bool {
        breathe && index == filledCount
    }

    /// Applies user input through the controller, keeping the pre-controller
    /// call site working.
    public func input(_ value: String) {
        guard !isInputDisabled else { return }
        stateController.input(value)
    }

    /// Imperative focus, retained for source compatibility with the earlier
    /// native API. The upstream `focus` prop is exposed as ``autoFocus``
    /// because Swift cannot carry both spellings on one type.
    public func focus() {
        guard !isInputDisabled else { return }
        stateController.focus()
    }

    public func blur() {
        guard !isInputDisabled else { return }
        stateController.blur()
    }

    private var isInputDisabled: Bool { disabled || disabledKeyboard }

    private var filledCount: Int { stateController.inputValue.count }

    private var resolvedModeName: String { Self.resolvedMode(mode) }

    private var cellSide: CGFloat { UPUnit.rpx(width) }

    private var lineThickness: CGFloat { bold ? 4 : 2 }

    private func mount() {
        stateController.register(
            maxlength: maxlength,
            onChange: onChangeHandler,
            onFinish: onFinishHandler,
            onModelValueUpdate: modelValue.map { binding in
                { binding.wrappedValue = $0 }
            },
            onFocus: onFocusHandler,
            onBlur: onBlurHandler
        )
        stateController.syncExternalValue(modelValue?.wrappedValue ?? stateController.inputValue)
    }

    private var nativeInputValue: Binding<String> {
        Binding(
            get: { stateController.inputValue },
            set: { stateController.input($0) }
        )
    }

    @ViewBuilder
    private var nativeInput: some View {
        TextField("", text: nativeInputValue)
#if os(iOS)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
#endif
            .font(.system(size: 1))
            .foregroundStyle(Color.clear)
            .tint(Color.clear)
            .opacity(0.01)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focused($nativeInputIsFocused)
            .disabled(isInputDisabled)
            .onChange(of: nativeInputIsFocused) { _, isFocused in
                stateController.setFocused(isFocused)
            }
            .accessibilityLabel("验证码输入")
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        ZStack {
            Text(character(at: index))
                .font(.system(size: UPUnit.rpx(fontSize), weight: bold ? .bold : .regular))
                .foregroundStyle(UPColor.parse(inactiveColor, theme: theme))

            if resolvedModeName == "middleLine" && filledCount <= index {
                Rectangle()
                    .fill(indicatorColor(at: index))
                    .frame(width: cellSide * 0.5, height: lineThickness)
            }
        }
        .frame(width: cellSide, height: cellSide)
        .overlay {
            if resolvedModeName == "box" {
                Rectangle()
                    .stroke(borderColor(at: index), lineWidth: 1)
            }
        }
        .overlay(alignment: .bottom) {
            if resolvedModeName == "bottomLine" {
                Rectangle()
                    .fill(indicatorColor(at: index))
                    .frame(height: lineThickness)
            }
        }
        .opacity(Self.isBreathing(atIndex: index, filledCount: filledCount, breathe: breathe) ? 0.3 : 1)
        .animation(
            Self.isBreathing(atIndex: index, filledCount: filledCount, breathe: breathe)
                ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                : .default,
            value: filledCount
        )
    }

    private func character(at index: Int) -> String {
        let value = stateController.inputValue
        guard index < value.count else { return "" }
        guard !dotFill else { return "●" }
        return String(value[value.index(value.startIndex, offsetBy: index)])
    }

    private func borderColor(at index: Int) -> Color {
        let name = Self.borderColorName(
            atIndex: index,
            filledCount: filledCount,
            mode: mode,
            activeColor: error ? "#fa3534" : activeColor,
            inactiveColor: error ? "#fa3534" : inactiveColor
        )
        return UPColor.parse(name, theme: theme)
    }

    private func indicatorColor(at index: Int) -> Color {
        if error { return UPColor.parse("#fa3534", theme: theme) }
        let name = index == filledCount ? activeColor : inactiveColor
        return UPColor.parse(name, theme: theme)
    }

    private static func parseCount(_ value: String, fallback: Int) -> Int {
        let dimension = UPUnit.parse(value)
        guard dimension > 0 else { return fallback }
        return Int(dimension)
    }

    private static func parseDimension(_ value: String, fallback: Double) -> Double {
        let dimension = Double(UPUnit.parse(value))
        return dimension > 0 ? dimension : fallback
    }
}

/// Mirrors the upstream `String | Number` props on `u-message-input`.
public typealias UPMessageInputUnitValue = UPCheckboxUnitValue

public extension UPMessageInput {
    func onChange(_ action: @escaping (String) -> Void) -> UPMessageInput {
        var copy = self
        copy.onChangeHandler = action
        copy.stateController.setOnChangeHandler(action)
        return copy
    }

    func onFinish(_ action: @escaping (String) -> Void) -> UPMessageInput {
        var copy = self
        copy.onFinishHandler = action
        copy.stateController.setOnFinishHandler(action)
        return copy
    }

    func onFocus(_ action: @escaping () -> Void) -> UPMessageInput {
        var copy = self
        copy.onFocusHandler = action
        copy.stateController.setOnFocusHandler(action)
        return copy
    }

    func onBlur(_ action: @escaping () -> Void) -> UPMessageInput {
        var copy = self
        copy.onBlurHandler = action
        copy.stateController.setOnBlurHandler(action)
        return copy
    }
}
