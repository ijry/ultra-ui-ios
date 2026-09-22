import Observation
import SwiftUI

@MainActor
@Observable
private final class UPKeyboardTextState {
    var value: String
    init(_ value: String) { self.value = value }
}

/// Native SwiftUI counterpart of uview-plus `u-number-keyboard`.
///
/// 上游是一张三列网格：`numList` 给出 10 或 11 个键，退格键在 `v-for` 之外单独渲染。
/// 有两处按键会变形：非乱序时第 10 个键（下标 9）在允许小数点/身份证 X 时变灰底，
/// 而 number 模式且隐藏小数点时它改成占双格宽。原生按同一套规则重绘。
@MainActor
public struct UPNumberKeyboard: View {
    public var show: Bool
    /// 仓库既有属性：上游没有 `title`（提示行在外层 `u-keyboard`）。
    public var title: String
    /// 上游 `mode`：`number` / `card`。
    public var mode: String
    /// 上游 `dotDisabled`：只在 number 模式生效。
    public var dotDisabled: Bool
    public var random: Bool
    /// 仓库既有属性：最长位数。上游不限长。
    public var maxlength: Int
    public var disabled: Bool
    public var keys: [UPKeyboardKey]

    private var modelValue: Binding<String>?
    @State private var state: UPKeyboardTextState
    private var onChangeHandler: ((String) -> Void)?
    private var onConfirmHandler: ((String) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onBackspaceHandler: ((String) -> Void)?

    @Environment(\.upTheme) private var theme

    public init(modelValue: Binding<String>? = nil,
                show: Bool = false,
                title: String = "",
                mode: String = UPConfig.numberKeyboard.mode,
                dotDisabled: Bool = UPConfig.numberKeyboard.dotDisabled,
                random: Bool = UPConfig.numberKeyboard.random,
                maxlength: Int = .max,
                disabled: Bool = false,
                randomSource: ([String]) -> [String] = { $0.shuffled() }) {
        self.modelValue = modelValue
        self.show = show
        self.title = title
        self.mode = mode
        self.dotDisabled = dotDisabled
        self.random = random
        self.maxlength = max(0, maxlength)
        self.disabled = disabled
        let base = Self.keyValues(mode: mode, dotDisabled: dotDisabled)
        self.keys = (random ? randomSource(base) : base).map { UPKeyboardKey(value: $0) }
        self._state = State(initialValue: UPKeyboardTextState(modelValue?.wrappedValue ?? ""))
    }

    /// 上游 `numList`。`dotDisabled` 分支只在 `mode == 'number'` 生效，
    /// 因此身份证键盘恒带 `cardX`。
    public static func keyValues(mode: String, dotDisabled: Bool) -> [String] {
        let digits = (1...9).map(String.init)
        if mode == "card" { return digits + ["X", "0"] }
        return dotDisabled ? digits + ["0"] : digits + [".", "0"]
    }

    // MARK: - 上游 computed

    /// 上游 `btnBgGray(index)`：只在非乱序 + 下标 9 + （card 模式或 number 模式且允许小数点）时变灰。
    public func isGrayKey(at index: Int) -> Bool {
        guard !random, index == 9 else { return false }
        return mode != "number" || !dotDisabled
    }

    /// 上游 `itemStyle(index)`：number 模式 + 隐藏小数点 + 下标 9 时宽度改成 464rpx。
    ///
    /// 照抄上游：这条判定**没有**排除乱序，所以 `random` 为真时被打乱到下标 9
    /// 的那个键同样会被拉宽。
    public func keyWidth(at index: Int) -> CGFloat {
        mode == "number" && dotDisabled && index == 9
            ? UPConfig.numberKeyboard.wideKeyWidth
            : UPConfig.numberKeyboard.keyWidth
    }

    /// 上游 `keyboardClick(val)`：允许小数点且不是 `.` / `X` 时会把值转成数字再抛。
    /// 原生统一用字符串承载，转换后的字面量与原值一致，故只做校验。
    nonisolated static func normalizedValue(_ value: String, dotDisabled: Bool) -> String {
        guard !dotDisabled, value != ".", value != "X" else { return value }
        return Int(value).map(String.init) ?? value
    }

    // MARK: - 方法

    public func press(_ value: String) {
        guard !disabled, state.value.count < maxlength, value != "." || !dotDisabled else { return }
        state.value.append(contentsOf: Self.normalizedValue(value, dotDisabled: dotDisabled))
        commit()
    }

    public func delete() {
        guard !disabled, !state.value.isEmpty else { return }
        state.value.removeLast()
        modelValue?.wrappedValue = state.value
        onBackspaceHandler?(state.value)
        onChangeHandler?(state.value)
    }

    public func confirm() {
        guard !disabled else { return }
        onConfirmHandler?(state.value)
    }

    public func cancel() {
        guard !disabled else { return }
        onCancelHandler?()
    }

    private func commit() {
        modelValue?.wrappedValue = state.value
        onChangeHandler?(state.value)
    }

    public func onChange(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }

    public func onConfirm(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onConfirmHandler = action; return copy
    }

    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onCancelHandler = action; return copy
    }

    public func onBackspace(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onBackspaceHandler = action; return copy
    }

    // MARK: - 视图

    /// 上游把提示行与安全区填充放在外层 `u-keyboard` 的 popup 包装上，
    /// 内层 `u-number-keyboard` 只有网格，因此独立使用时两者都不渲染。
    public var body: some View {
        UPAlbumWrapLayout(spacing: UPConfig.numberKeyboard.keySpacing,
                          lineSpacing: UPConfig.numberKeyboard.rowSpacing) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                keyCell(key, at: index)
            }

            backspaceCell
        }
        .padding(.horizontal, UPUnit.rpx(CGFloat(10)))
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(UPColor.parse(UPConfig.numberKeyboard.backgroundColor, theme: theme))
    }

    private func keyCell(_ key: UPKeyboardKey, at index: Int) -> some View {
        Button { press(key.value) } label: {
            Text(key.label)
                .font(.system(size: UPConfig.numberKeyboard.keyFontSize, weight: .medium))
                .foregroundStyle(UPColor.parse("main", theme: theme))
                .frame(width: keyWidth(at: index), height: UPConfig.numberKeyboard.keyHeight)
                .background(isGrayKey(at: index)
                            ? UPColor.parse(UPConfig.numberKeyboard.grayKeyColor, theme: theme)
                            : Color.white,
                            in: RoundedRectangle(cornerRadius: UPConfig.numberKeyboard.keyCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled || key.disabled)
    }

    /// 上游退格键在 `v-for` 之外，恒为灰底。
    private var backspaceCell: some View {
        Button { delete() } label: {
            UPIcon(name: "backspace",
                   color: "main",
                   size: UPConfig.numberKeyboard.backspaceIconSize)
                .frame(width: UPConfig.numberKeyboard.keyWidth,
                       height: UPConfig.numberKeyboard.keyHeight)
                .background(UPColor.parse(UPConfig.numberKeyboard.grayKeyColor, theme: theme),
                            in: RoundedRectangle(cornerRadius: UPConfig.numberKeyboard.keyCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        // 上游 `@touchstart` 起 250ms 定时器连删、`@touchend` 清掉。
        .onLongPressGesture(minimumDuration: 0.25) { delete() }
    }
}
