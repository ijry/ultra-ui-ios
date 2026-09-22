import Observation
import SwiftUI

/// 对应上游 `data.abc`：`false` 输入省份中文简称，`true` 输入车牌号码。
@MainActor
@Observable
private final class UPCarKeyboardState {
    var value: String
    var stage: UPCarKeyboardStage

    init(_ value: String) {
        self.value = value
        self.stage = value.isEmpty ? .province : .letter
    }
}

/// Native SwiftUI counterpart of uview-plus `u-car-keyboard`.
///
/// 上游把 36 个键切成 10/10/10/6 四行，第四行左端是「中/英」切换、右端是退格，
/// 中间只有 6 个字符键，因此那一行整体居中。原生按同一套分行与特殊键宽度重绘。
@MainActor
public struct UPCarKeyboard: View {
    /// 上游 `areaList`，保持原顺序以便按 10/10/10/6 切行。
    public static let provinces = ["京", "沪", "粤", "津", "冀", "豫", "云", "辽", "黑", "湘", "皖", "鲁", "苏", "浙", "赣", "鄂", "桂", "甘", "晋", "陕", "蒙", "吉", "闽", "贵", "渝", "川", "青", "琼", "宁", "挂", "藏", "港", "澳", "新", "使", "学"]
    /// 上游 `engKeyBoardList`：先 10 个数字，再 QWERTY 布局。
    public static let letters = Array("1234567890QWERTYUIOPASDFGHJKLZXCVBNM").map(String.init)

    public var show: Bool
    /// 仓库既有属性：车牌最长位数。上游本身不限长（由宿主的输入框负责）。
    public var maxlength: Int
    public var disabled: Bool
    /// 上游 `random`：是否打乱按键顺序。
    public var random: Bool
    /// 上游 `autoChange`：输入一个中文后是否自动切到英文。
    public var autoChange: Bool

    private var modelValue: Binding<String>?
    @State private var state: UPCarKeyboardState
    private let provinceKeys: [String]
    private let letterKeys: [String]
    private var onChangeHandler: ((String) -> Void)?
    private var onConfirmHandler: ((String) -> Void)?
    private var onBackspaceHandler: ((String) -> Void)?

    @Environment(\.upTheme) private var theme

    public init(modelValue: Binding<String>? = nil,
                show: Bool = false,
                maxlength: Int = 8,
                disabled: Bool = false,
                random: Bool = UPConfig.carKeyboard.random,
                autoChange: Bool = UPConfig.carKeyboard.autoChange,
                randomSource: ([String]) -> [String] = { $0.shuffled() }) {
        self.modelValue = modelValue
        self.show = show
        self.maxlength = max(0, maxlength)
        self.disabled = disabled
        self.random = random
        self.autoChange = autoChange
        self.provinceKeys = random ? randomSource(Self.provinces) : Self.provinces
        self.letterKeys = random ? randomSource(Self.letters) : Self.letters
        self._state = State(initialValue: UPCarKeyboardState(modelValue?.wrappedValue ?? ""))
    }

    // MARK: - 解析后的呈现值

    /// 上游 `abc`：`false` 是省份档、`true` 是字母档。
    public var stage: UPCarKeyboardStage { state.stage }

    public var keys: [UPKeyboardKey] {
        (stage == .province ? provinceKeys : letterKeys).map { UPKeyboardKey(value: $0) }
    }

    /// 上游 `areaList` / `engKeyBoardList` 的 `slice(0,10)/(10,20)/(20,30)/(30,36)`。
    public var rows: [[String]] {
        Self.slicedRows(stage == .province ? provinceKeys : letterKeys)
    }

    nonisolated static func slicedRows(_ keys: [String]) -> [[String]] {
        var result: [[String]] = []
        var start = 0
        for size in UPConfig.carKeyboard.rowSizes {
            let end = min(start + size, keys.count)
            guard start < end else {
                result.append([])
                continue
            }
            result.append(Array(keys[start..<end]))
            start = end
        }
        return result
    }

    /// 上游 `i + 1 === 4 && 'u-keyboard__button--center'`：第四行整体居中。
    public func isCenteredRow(_ index: Int) -> Bool { index == 3 }

    /// 上游第四行左端「中/英」、右端退格，都在 `v-for` 之外。
    public func hasFunctionKeys(_ index: Int) -> Bool { index == 3 }

    // MARK: - 上游 methods

    /// 上游 `carInputClick(i, j)`：取对应档位的值，`autoChange` 时延时切到字母档。
    public func press(_ value: String) {
        guard !disabled, state.value.count < maxlength,
              keys.contains(where: { $0.value == value }) else { return }
        state.value.append(contentsOf: value)
        if !state.value.isEmpty, autoChange, state.stage == .province { state.stage = .letter }
        commit()
    }

    /// 仓库既有方法：退一格，退空后回到省份档。
    ///
    /// 上游 `backspaceClick` 只 `$emit('backspace')` 并起一个 250ms 定时器连删，
    /// 自身不持有输入串，因此「退空回省份档」是原生扩展。
    public func delete() {
        guard !disabled, !state.value.isEmpty else { return }
        state.value.removeLast()
        if state.value.isEmpty { state.stage = .province }
        modelValue?.wrappedValue = state.value
        onBackspaceHandler?(state.value)
        onChangeHandler?(state.value)
    }

    /// 上游 `changeCarInputMode`：中/英 切换。
    public func changeInputMode() {
        guard !disabled else { return }
        state.stage = state.stage == .province ? .letter : .province
    }

    public func confirm() {
        guard !disabled else { return }
        onConfirmHandler?(state.value)
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

    public func onBackspace(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onBackspaceHandler = action; return copy
    }

    // MARK: - 视图

    /// 上游 `u-car-keyboard` 本身只有键盘网格；提示行与安全区填充属于外层
    /// `u-keyboard` 的 popup 包装，因此独立使用时不渲染它们。
    public var body: some View {
        VStack(spacing: UPConfig.carKeyboard.rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                keyRow(row, at: rowIndex)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(UPColor.parse(UPConfig.carKeyboard.backgroundColor, theme: theme))
    }

    private func keyRow(_ row: [String], at rowIndex: Int) -> some View {
        HStack(spacing: UPConfig.carKeyboard.keySpacing) {
            if hasFunctionKeys(rowIndex) { inputModeToggle }

            ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                keyCell(key)
            }

            if hasFunctionKeys(rowIndex) { backspaceCell }
        }
        .frame(maxWidth: .infinity)
    }

    /// 上游 `.__inner-wrapper__inner`：白底、圆角、64rpx × 80rpx。
    private func keyCell(_ key: String) -> some View {
        Button { press(key) } label: {
            Text(key)
                .font(.system(size: UPConfig.carKeyboard.keyFontSize))
                .foregroundStyle(UPColor.parse("main", theme: theme))
                .frame(width: UPConfig.carKeyboard.keyWidth,
                       height: UPConfig.carKeyboard.keyHeight)
                .background(Color.white, in: RoundedRectangle(cornerRadius: UPConfig.carKeyboard.keyCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    /// 上游 `.__inner-wrapper__left`：中/英 两段文字，激活的一段染成 primary。
    private var inputModeToggle: some View {
        Button { changeInputMode() } label: {
            HStack(spacing: 1) {
                Text("中")
                    .foregroundStyle(UPColor.parse(stage == .province ? "primary" : "main", theme: theme))
                Text("/")
                    .font(.system(size: UPConfig.carKeyboard.separatorFontSize))
                    .foregroundStyle(UPColor.parse("main", theme: theme))
                Text("英")
                    .foregroundStyle(UPColor.parse(stage == .letter ? "primary" : "main", theme: theme))
            }
            .font(.system(size: UPConfig.carKeyboard.keyFontSize))
            .frame(width: UPConfig.carKeyboard.specialKeyWidth,
                   height: UPConfig.carKeyboard.keyHeight)
            .background(UPColor.parse(UPConfig.carKeyboard.functionKeyColor, theme: theme),
                        in: RoundedRectangle(cornerRadius: UPConfig.carKeyboard.keyCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    /// 上游 `.__inner-wrapper__right`：退格键，长按连删。
    private var backspaceCell: some View {
        Button { delete() } label: {
            UPIcon(name: "backspace",
                   color: "main",
                   size: UPConfig.carKeyboard.backspaceIconSize)
                .frame(width: UPConfig.carKeyboard.specialKeyWidth,
                       height: UPConfig.carKeyboard.keyHeight)
                .background(UPColor.parse(UPConfig.carKeyboard.functionKeyColor, theme: theme),
                            in: RoundedRectangle(cornerRadius: UPConfig.carKeyboard.keyCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        // 上游 `@touchstart` 起 250ms 定时器连删、`@touchend` 清掉。
        .onLongPressGesture(minimumDuration: 0.25) { delete() }
    }
}
