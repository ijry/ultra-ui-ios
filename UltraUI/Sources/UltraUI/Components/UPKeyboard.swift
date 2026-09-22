import SwiftUI

@MainActor private final class UPKeyboardStageState { var stage: UPCarKeyboardStage = .province }

/// Native SwiftUI counterpart of uview-plus `u-keyboard`.
///
/// Upstream is a pure forwarder: an outer `u-popup` plus a tooltip row, and the
/// grid itself comes from `u-number-keyboard` (`mode == 'number' || 'card'`) or
/// `u-car-keyboard` (any other mode). `dotDisabled`/`random` reach the number
/// grid, `random`/`autoChange` reach the car grid.
@MainActor
public struct UPKeyboard: View {
    public var show: Bool
    public var mode: String
    public var dotDisabled: Bool
    public var random: Bool
    public var autoChange: Bool
    public var zIndex: CGFloat
    public var overlay: Bool
    public var closeOnClickOverlay: Bool
    public var safeAreaInsetBottom: Bool
    public var disabled: Bool
    public var tooltip: Bool
    public var showTips: Bool
    public var tips: String
    public var showCancel: Bool
    public var showConfirm: Bool
    public var cancelText: String
    public var confirmText: String
    public var keys: [UPKeyboardKey]
    private let numberGrid: [UPKeyboardKey]
    private let provinceGrid: [UPKeyboardKey]
    private let letterGrid: [UPKeyboardKey]
    private let stageState: UPKeyboardStageState
    private var onInputHandler: ((String) -> Void)?
    private var onDeleteHandler: (() -> Void)?
    private var onConfirmHandler: (() -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onChangeHandler: ((String) -> Void)?
    private var onBackspaceHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    public init(show: Bool = UPConfig.keyboard.show, mode: String = UPConfig.keyboard.mode,
                dotDisabled: Bool = UPConfig.keyboard.dotDisabled, random: Bool = UPConfig.keyboard.random,
                autoChange: Bool = UPConfig.keyboard.autoChange,
                zIndex: some UPImageUnitValue = UPConfig.keyboard.zIndex,
                overlay: Bool = UPConfig.keyboard.overlay, closeOnClickOverlay: Bool = UPConfig.keyboard.closeOnClickOverlay,
                safeAreaInsetBottom: Bool = UPConfig.keyboard.safeAreaInsetBottom,
                disabled: Bool = false, tooltip: Bool = UPConfig.keyboard.tooltip,
                showTips: Bool = UPConfig.keyboard.showTips, tips: String = UPConfig.keyboard.tips,
                showCancel: Bool = UPConfig.keyboard.showCancel, showConfirm: Bool = UPConfig.keyboard.showConfirm,
                cancelText: String = UPConfig.keyboard.cancelText, confirmText: String = UPConfig.keyboard.confirmText,
                keys: [UPKeyboardKey] = [], randomSource: ([String]) -> [String] = { $0.shuffled() }) {
        self.show = show; self.mode = mode; self.dotDisabled = dotDisabled
        self.random = random; self.autoChange = autoChange
        self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.overlay = overlay; self.closeOnClickOverlay = closeOnClickOverlay
        self.safeAreaInsetBottom = safeAreaInsetBottom; self.disabled = disabled
        self.tooltip = tooltip; self.showTips = showTips; self.tips = tips
        self.showCancel = showCancel; self.showConfirm = showConfirm
        self.cancelText = cancelText; self.confirmText = confirmText; self.keys = keys
        let digits = UPNumberKeyboard.keyValues(mode: mode, dotDisabled: dotDisabled)
        self.numberGrid = (random ? randomSource(digits) : digits).map { UPKeyboardKey(value: $0) }
        self.provinceGrid = (random ? randomSource(UPCarKeyboard.provinces) : UPCarKeyboard.provinces).map { UPKeyboardKey(value: $0) }
        self.letterGrid = (random ? randomSource(UPCarKeyboard.letters) : UPCarKeyboard.letters).map { UPKeyboardKey(value: $0) }
        self.stageState = UPKeyboardStageState()
    }

    /// Upstream template fallback:
    /// `tips ? tips : mode == 'number' ? '数字键盘' : mode == 'card' ? '身份证键盘' : '车牌号键盘'`.
    public var resolvedTips: String {
        if !tips.isEmpty { return tips }
        switch mode {
        case "number": return "数字键盘"
        case "card": return "身份证键盘"
        default: return "车牌号键盘"
        }
    }
    /// The whole `u-keyboard__tooltip` row is gated by `tooltip`.
    public var showsToolbar: Bool { tooltip }
    public var showsCancelButton: Bool { tooltip && showCancel }
    public var showsConfirmButton: Bool { tooltip && showConfirm }
    public var showsTipsText: Bool { tooltip && showTips }
    /// `mode == 'number' || mode == 'card'` picks `u-number-keyboard`; every
    /// other mode falls through to `u-car-keyboard`.
    public var usesNumberKeyboard: Bool { mode == "number" || mode == "card" }
    /// The car grid keeps two key sets and `changeCarInputMode` toggles them.
    public var carStage: UPCarKeyboardStage { stageState.stage }
    /// Keys default to the forwarded grid, but a host may hand over its own set
    /// (`UPNumberKeyboard`/`UPCarKeyboard` do exactly that).
    public var resolvedKeys: [UPKeyboardKey] {
        if !keys.isEmpty { return keys }
        if usesNumberKeyboard { return numberGrid }
        return carStage == .province ? provinceGrid : letterGrid
    }
    /// Both upstream grids render a backspace cell outside their `v-for`, so it
    /// only drops out when the host already supplies a delete key.
    public var showsBackspaceKey: Bool { !resolvedKeys.contains { $0.kind == .delete } }
    /// The 中/英 cell also lives outside the `v-for`, but switching only makes
    /// sense while this view owns the two car grids; a host that passes `keys`
    /// keeps that authority (see `UPCarKeyboard.changeInputMode()`).
    public var showsInputModeToggle: Bool { ownsCarGrid }
    /// True while `mode` routes to the car grid and no host supplied `keys`,
    /// i.e. while `changeCarInputMode`/`autoChange` belong to this view.
    private var ownsCarGrid: Bool { !usesNumberKeyboard && keys.isEmpty }
    /// `numList` renders three per row; the car grid slices 10/10/10/6.
    public var columnCount: Int { usesNumberKeyboard ? 3 : 10 }
    /// Upstream `popupStyle`:
    /// `upThemeVar('--up-bg-color', upThemeIsDark ? '#2c2c2e' : 'rgb(214, 218, 220)')`.
    public nonisolated static func panelBackgroundColorName(dark: Bool) -> String { dark ? "#2c2c2e" : "#d6dadc" }

    public var body: some View {
        if show {
            VStack(spacing: 0) {
                if showsToolbar { toolbar }
                grid
                if safeAreaInsetBottom { UPSafeBottom() }
            }
            .background(UPColor.parse(Self.panelBackgroundColorName(dark: colorScheme == .dark)))
            .zIndex(Double(zIndex))
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: columnCount), spacing: 8) {
            if showsInputModeToggle { inputModeToggle }
            ForEach(resolvedKeys) { key in keyCell(key) }
            if showsBackspaceKey { backspaceCell }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 8)
    }

    private func keyCell(_ key: UPKeyboardKey) -> some View {
        Button { press(key) } label: {
            Text(key.label)
                .font(.system(size: usesNumberKeyboard ? 20 : 16, weight: usesNumberKeyboard ? .medium : .regular))
                .foregroundStyle(keyTextColor)
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(keyBackgroundColor, in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(disabled || key.disabled)
    }

    private var backspaceCell: some View {
        Button { backspace() } label: {
            UPIcon(name: "backspace", color: "#303133", size: "22")
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(functionKeyBackgroundColor, in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var inputModeToggle: some View {
        Button { changeInputMode() } label: {
            HStack(spacing: 1) {
                Text("中").foregroundStyle(carStage == .province ? UPColor.parse("primary") : keyTextColor)
                Text("/").font(.system(size: 15)).foregroundStyle(keyTextColor)
                Text("英").foregroundStyle(carStage == .letter ? UPColor.parse("primary") : keyTextColor)
            }
            .font(.system(size: 16))
            .frame(maxWidth: .infinity, minHeight: keyHeight)
            .background(functionKeyBackgroundColor, in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            Group {
                if showsCancelButton {
                    Button(cancelText) { cancel() }
                        .foregroundStyle(UPColor.parse("#909399"))
                        .disabled(disabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if showsTipsText {
                    Text(resolvedTips).foregroundStyle(UPColor.parse("#909399"))
                }
            }
            .frame(maxWidth: .infinity)

            Group {
                if showsConfirmButton {
                    Button(confirmText) { confirm() }
                        .foregroundStyle(UPColor.parse("#2979ff"))
                        .disabled(disabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(cardBackgroundColor)
    }

    private var keyHeight: CGFloat { usesNumberKeyboard ? 45 : 40 }
    private var keyTextColor: Color { colorScheme == .dark ? .white : UPColor.parse("#303133") }
    private var keyBackgroundColor: Color { cardBackgroundColor }
    private var cardBackgroundColor: Color { colorScheme == .dark ? UPColor.parse("#1c1c1e") : .white }
    private var functionKeyBackgroundColor: Color { colorScheme == .dark ? UPColor.parse("#3a3a3c") : UPColor.parse("#c8cad2") }

    public func press(_ key: UPKeyboardKey) {
        guard !disabled, !key.disabled else { return }
        switch key.kind {
        case .input:
            if ownsCarGrid, autoChange, stageState.stage == .province { stageState.stage = .letter }
            onInputHandler?(key.value); onChangeHandler?(key.value)
        case .delete: backspace()
        case .confirm: confirm()
        case .cancel: cancel()
        case .spacer: break
        }
    }
    /// Upstream `changeCarInputMode`, the 中/英 toggle in the car grid.
    public func changeInputMode() { guard !disabled, ownsCarGrid else { return }; stageState.stage = stageState.stage == .province ? .letter : .province }
    public func backspace() { guard !disabled else { return }; onDeleteHandler?(); onBackspaceHandler?() }
    public func cancel() { guard !disabled else { return }; onCancelHandler?() }
    public func confirm() { guard !disabled else { return }; onConfirmHandler?() }
    /// `popupClose` and the popup's `closed` are container events, so they keep
    /// firing while the grid itself is disabled.
    public func close() { onCloseHandler?() }
    public func closed() { onClosedHandler?() }
    public func onInput(_ action: @escaping (String) -> Void) -> Self { var c = self; c.onInputHandler = action; return c }
    public func onDelete(_ action: @escaping () -> Void) -> Self { var c = self; c.onDeleteHandler = action; return c }
    public func onConfirm(_ action: @escaping () -> Void) -> Self { var c = self; c.onConfirmHandler = action; return c }
    public func onCancel(_ action: @escaping () -> Void) -> Self { var c = self; c.onCancelHandler = action; return c }
    public func onChange(_ action: @escaping (String) -> Void) -> Self { var c = self; c.onChangeHandler = action; return c }
    public func onBackspace(_ action: @escaping () -> Void) -> Self { var c = self; c.onBackspaceHandler = action; return c }
    public func onClose(_ action: @escaping () -> Void) -> Self { var c = self; c.onCloseHandler = action; return c }
    public func onClosed(_ action: @escaping () -> Void) -> Self { var c = self; c.onClosedHandler = action; return c }
}
