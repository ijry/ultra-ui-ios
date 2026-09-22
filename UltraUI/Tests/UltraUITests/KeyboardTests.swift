import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class KeyboardTests: XCTestCase {
    func testNumberKeyboardUsesInjectedRandomOrderAndUpdatesBinding() {
        let value = StringBox("")
        var events: [String] = []
        let keyboard = UPNumberKeyboard(
            modelValue: value.binding,
            random: true,
            randomSource: { _ in ["3", "1", "2", "9", "8", "7", "6", "5", "4"] }
        )
        .onChange { events.append("change:\($0)") }
        .onConfirm { events.append("confirm:\($0)") }

        XCTAssertEqual(keyboard.keys.map(\.value), ["3", "1", "2", "9", "8", "7", "6", "5", "4"])
        keyboard.press("3")
        keyboard.delete()
        keyboard.press("1")
        keyboard.confirm()
        XCTAssertEqual(value.value, "1")
        XCTAssertEqual(events, ["change:3", "change:", "change:1", "confirm:1"])
    }

    /// Upstream `numList` has three branches: `[1..9, 0]` when the dot is
    /// disabled in number mode, `[1..9, dot, 0]` for the default number mode,
    /// and `[1..9, cardX, 0]` for card mode. The `dotDisabled` branch is
    /// guarded by `mode == 'number'`, so card mode keeps `X` regardless.
    func testNumberKeyboardKeySetsMatchUpstreamNumListBranches() {
        let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        XCTAssertEqual(UPNumberKeyboard().keys.map(\.value), digits + [".", "0"])
        XCTAssertEqual(UPNumberKeyboard(dotDisabled: true).keys.map(\.value), digits + ["0"])
        XCTAssertEqual(UPNumberKeyboard(mode: "card").keys.map(\.value), digits + ["X", "0"])
        XCTAssertEqual(UPNumberKeyboard(mode: "card", dotDisabled: true).keys.map(\.value), digits + ["X", "0"])
    }

    func testNumberKeyboardCanTypeZeroAndDot() {
        let value = StringBox("")
        let keyboard = UPNumberKeyboard(modelValue: value.binding)
        keyboard.press("0")
        keyboard.press(".")
        keyboard.press("5")
        XCTAssertEqual(value.value, "0.5")
    }

    /// Upstream shuffles the whole `numList`, so the randomised keyboard still
    /// exposes the dot and the zero rather than only the nine leading digits.
    func testRandomNumberKeyboardShufflesTheEntireKeySet() {
        let keyboard = UPNumberKeyboard(random: true)
        XCTAssertEqual(keyboard.keys.count, 11)
        XCTAssertEqual(Set(keyboard.keys.map(\.value)), Set(["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0"]))
    }

    func testCarKeyboardMovesFromProvinceToLetterStage() {
        let value = StringBox("")
        let keyboard = UPCarKeyboard(modelValue: value.binding, autoChange: true)
        XCTAssertEqual(keyboard.stage, .province)
        keyboard.press("京")
        XCTAssertEqual(value.value, "京")
        XCTAssertEqual(keyboard.stage, .letter)
        keyboard.press("A")
        XCTAssertEqual(value.value, "京A")
        keyboard.delete()
        XCTAssertEqual(value.value, "京")
    }

    /// Upstream `areaList` is a 36-entry grid that also carries 挂/港/澳/使/学,
    /// and `engKeyBoardList` leads with the digits before a QWERTY layout.
    func testCarKeyboardKeyGridsMatchUpstream() {
        XCTAssertEqual(UPCarKeyboard.provinces, [
            "京", "沪", "粤", "津", "冀", "豫", "云", "辽", "黑", "湘",
            "皖", "鲁", "苏", "浙", "赣", "鄂", "桂", "甘", "晋", "陕",
            "蒙", "吉", "闽", "贵", "渝", "川", "青", "琼", "宁", "挂",
            "藏", "港", "澳", "新", "使", "学"
        ])
        XCTAssertEqual(UPCarKeyboard.letters.count, 36)
        XCTAssertEqual(UPCarKeyboard.letters.prefix(10).joined(), "1234567890")
        XCTAssertEqual(UPCarKeyboard.letters.dropFirst(10).joined(), "QWERTYUIOPASDFGHJKLZXCVBNM")
    }

    func testCarKeyboardAcceptsPlatePrefixesAndLettersMissingFromTheOldGrid() {
        let value = StringBox("")
        let keyboard = UPCarKeyboard(modelValue: value.binding, autoChange: true)
        keyboard.press("港")
        XCTAssertEqual(value.value, "港")
        keyboard.press("I")
        keyboard.press("O")
        keyboard.press("0")
        XCTAssertEqual(value.value, "港IO0")
    }

    /// Upstream defaults `autoChange` to `false`, so a province press keeps the
    /// Chinese grid until `changeCarInputMode` flips the mode.
    func testCarKeyboardKeepsProvinceStageUntilInputModeIsChanged() {
        let value = StringBox("")
        let keyboard = UPCarKeyboard(modelValue: value.binding)
        XCTAssertFalse(keyboard.autoChange)
        keyboard.press("京")
        XCTAssertEqual(keyboard.stage, .province)
        keyboard.press("A")
        XCTAssertEqual(value.value, "京")

        keyboard.changeInputMode()
        XCTAssertEqual(keyboard.stage, .letter)
        keyboard.press("A")
        XCTAssertEqual(value.value, "京A")
        keyboard.changeInputMode()
        XCTAssertEqual(keyboard.stage, .province)
    }

    func testRandomCarKeyboardShufflesBothGridsWithoutLosingKeys() {
        let keyboard = UPCarKeyboard(random: true, randomSource: { $0.reversed() })
        XCTAssertEqual(keyboard.keys.map(\.value), UPCarKeyboard.provinces.reversed())
        keyboard.changeInputMode()
        XCTAssertEqual(keyboard.keys.map(\.value), UPCarKeyboard.letters.reversed())

        let shuffled = UPCarKeyboard(random: true)
        XCTAssertEqual(Set(shuffled.keys.map(\.value)), Set(UPCarKeyboard.provinces))
    }

    /// 上游 `areaList` / `engKeyBoardList` 都按 `slice(0,10)/(10,20)/(20,30)/(30,36)` 切成四行。
    func testCarKeyboardRowsSliceTenTenTenSix() {
        XCTAssertEqual(UPConfig.carKeyboard.rowSizes, [10, 10, 10, 6])

        let keyboard = UPCarKeyboard()
        let rows = keyboard.rows
        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows.map(\.count), [10, 10, 10, 6])
        XCTAssertEqual(rows[0].first, "京")
        XCTAssertEqual(rows[3], ["藏", "港", "澳", "新", "使", "学"])

        // 第四行整体居中，且左右各挂一个功能键（中/英 与退格）。
        XCTAssertTrue(keyboard.isCenteredRow(3))
        XCTAssertFalse(keyboard.isCenteredRow(0))
        XCTAssertTrue(keyboard.hasFunctionKeys(3))
        XCTAssertFalse(keyboard.hasFunctionKeys(2))

        keyboard.changeInputMode()
        XCTAssertEqual(keyboard.rows[3], ["X", "C", "V", "B", "N", "M"])
    }

    /// 切行函数在键数不足时不会越界。
    func testCarKeyboardRowSlicingHandlesShortGrids() {
        typealias Keyboard = UPCarKeyboard
        XCTAssertEqual(Keyboard.slicedRows(["a", "b"]), [["a", "b"], [], [], []])
        XCTAssertEqual(Keyboard.slicedRows([]), [[], [], [], []])
    }

    /// 上游 `props.js`：`random` 与 `autoChange` 都默认 false。
    func testCarKeyboardPropDefaultsMatchUpstream() {
        XCTAssertFalse(UPConfig.carKeyboard.random)
        XCTAssertFalse(UPConfig.carKeyboard.autoChange)
        // 上游 carInputClick 的 sleep(200) 与 backspaceClick 的 250ms 定时器。
        XCTAssertEqual(UPConfig.carKeyboard.autoChangeDelay, 200)
        XCTAssertEqual(UPConfig.carKeyboard.backspaceRepeatInterval, 250)

        let keyboard = UPCarKeyboard()
        XCTAssertFalse(keyboard.random)
        XCTAssertFalse(keyboard.autoChange)
        XCTAssertEqual(keyboard.stage, .province)
    }

    /// 上游 `btnBgGray(index)`：非乱序 + 下标 9 + （card 模式 或 number 模式且允许小数点）才变灰。
    func testNumberKeyboardGrayKeyMatchesUpstream() {
        let dotted = UPNumberKeyboard()
        XCTAssertTrue(dotted.isGrayKey(at: 9))
        XCTAssertFalse(dotted.isGrayKey(at: 8))
        XCTAssertFalse(dotted.isGrayKey(at: 10))

        // number 模式隐藏小数点时第 10 键不再变灰（它改成占双格）。
        let noDot = UPNumberKeyboard(dotDisabled: true)
        XCTAssertFalse(noDot.isGrayKey(at: 9))

        // card 模式恒带 X，第 10 键照旧变灰。
        XCTAssertTrue(UPNumberKeyboard(mode: "card", dotDisabled: true).isGrayKey(at: 9))

        // 乱序时一律不变灰。
        XCTAssertFalse(UPNumberKeyboard(random: true).isGrayKey(at: 9))
    }

    /// 上游 `itemStyle(index)`：number 模式 + 隐藏小数点 + 下标 9 时宽度变 464rpx。
    func testNumberKeyboardWideKeyMatchesUpstream() {
        let normal = UPNumberKeyboard()
        XCTAssertEqual(normal.keyWidth(at: 9), UPUnit.rpx(CGFloat(222)))

        let wide = UPNumberKeyboard(dotDisabled: true)
        XCTAssertEqual(wide.keyWidth(at: 9), UPUnit.rpx(CGFloat(464)))
        XCTAssertEqual(wide.keyWidth(at: 8), UPUnit.rpx(CGFloat(222)))

        // card 模式不受 dotDisabled 影响，不会拉宽。
        XCTAssertEqual(UPNumberKeyboard(mode: "card", dotDisabled: true).keyWidth(at: 9),
                       UPUnit.rpx(CGFloat(222)))

        // 照抄上游：这条判定没有排除乱序，random 时下标 9 同样会被拉宽。
        XCTAssertEqual(UPNumberKeyboard(dotDisabled: true, random: true).keyWidth(at: 9),
                       UPUnit.rpx(CGFloat(464)))
    }

    /// 上游 `keyboardClick(val)`：允许小数点且不是 `.` / `X` 时会先 `Number(val)`。
    func testNumberKeyboardNormalizesNumericValues() {
        typealias Keyboard = UPNumberKeyboard
        XCTAssertEqual(Keyboard.normalizedValue("7", dotDisabled: false), "7")
        XCTAssertEqual(Keyboard.normalizedValue(".", dotDisabled: false), ".")
        XCTAssertEqual(Keyboard.normalizedValue("X", dotDisabled: false), "X")
        // dotDisabled 为真时上游根本不做转换。
        XCTAssertEqual(Keyboard.normalizedValue("7", dotDisabled: true), "7")
    }

    /// 上游 `props.js`：`mode: 'number'`、`dotDisabled: false`、`random: false`。
    func testNumberKeyboardPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.numberKeyboard.mode, "number")
        XCTAssertFalse(UPConfig.numberKeyboard.dotDisabled)
        XCTAssertFalse(UPConfig.numberKeyboard.random)
        XCTAssertEqual(UPConfig.numberKeyboard.columnCount, 3)
        XCTAssertEqual(UPConfig.numberKeyboard.backspaceRepeatInterval, 250)

        let keyboard = UPNumberKeyboard()
        XCTAssertEqual(keyboard.mode, "number")
        XCTAssertFalse(keyboard.dotDisabled)
        XCTAssertFalse(keyboard.random)
        XCTAssertEqual(keyboard.keys.map(\.value), ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0"])
    }

    func testKeyboardCloseAndDisabledEvents() {
        var closed = 0
        let keyboard = UPKeyboard(show: true, disabled: true).onCancel { closed += 1 }
        keyboard.cancel()
        XCTAssertEqual(closed, 0)

        let enabled = UPKeyboard(show: true).onCancel { closed += 1 }
        enabled.cancel()
        XCTAssertEqual(closed, 1)
    }

    /// `UPKeyboardKey` derives its `ForEach` identity from the kind and value so
    /// that the functional keys of one grid never collide with an input key.
    func testKeyboardKeyDerivesIdentityAndLabelFromValueAndKind() {
        let digit = UPKeyboardKey(value: "7")
        XCTAssertEqual(digit.id, "input:7")
        XCTAssertEqual(digit.label, "7")
        XCTAssertEqual(digit.kind, .input)
        XCTAssertFalse(digit.disabled)

        let delete = UPKeyboardKey(value: "7", label: "删除", kind: .delete, disabled: true)
        XCTAssertEqual(delete.id, "delete:7")
        XCTAssertEqual(delete.label, "删除")
        XCTAssertTrue(delete.disabled)
        XCTAssertNotEqual(delete.id, digit.id)

        XCTAssertEqual(UPKeyboardKey(id: "custom", value: "7").id, "custom")
        XCTAssertEqual(Set(UPCarKeyboard.letters).count, UPCarKeyboard.letters.count)
        XCTAssertEqual(Set(UPNumberKeyboard(mode: "card").keys.map(\.id)).count, 11)
    }

    /// `u-keyboard/keyboard.js`: `tooltip`/`showTips`/`showCancel`/`showConfirm`
    /// 默认全开，`cancelText`/`confirmText` 走 i18n 的「取消」「确定」，
    /// `tips` 默认空串。
    func testKeyboardToolbarDefaultsMatchUpstreamProps() {
        let keyboard = UPKeyboard()
        XCTAssertTrue(keyboard.tooltip)
        XCTAssertTrue(keyboard.showTips)
        XCTAssertTrue(keyboard.showCancel)
        XCTAssertTrue(keyboard.showConfirm)
        XCTAssertEqual(keyboard.tips, "")
        XCTAssertEqual(keyboard.cancelText, "取消")
        XCTAssertEqual(keyboard.confirmText, "确定")
        XCTAssertEqual(UPConfig.keyboard.cancelText, "取消")
        XCTAssertEqual(UPConfig.keyboard.confirmText, "确定")
        XCTAssertTrue(UPConfig.keyboard.tooltip)
    }

    /// 上游模板的 tips 兜底表达式：
    /// `tips ? tips : mode == 'number' ? '数字键盘' : mode == 'card' ? '身份证键盘' : '车牌号键盘'`，
    /// 所以除 number/card 之外的任意 mode 都回落到车牌号键盘。
    func testKeyboardResolvedTipsFallsBackToModeLabel() {
        XCTAssertEqual(UPKeyboard(mode: "number").resolvedTips, "数字键盘")
        XCTAssertEqual(UPKeyboard(mode: "card").resolvedTips, "身份证键盘")
        XCTAssertEqual(UPKeyboard(mode: "car").resolvedTips, "车牌号键盘")
        XCTAssertEqual(UPKeyboard(mode: "unknown").resolvedTips, "车牌号键盘")
        XCTAssertEqual(UPKeyboard(mode: "number", tips: "请输入金额").resolvedTips, "请输入金额")
    }

    /// `tooltip` 为假时整条工具条不渲染，因此 cancel/confirm/tips 都不可见；
    /// 单独关掉 `showCancel`/`showConfirm` 只隐藏对应按钮。
    func testKeyboardToolbarVisibilityFollowsTooltipAndPerButtonFlags() {
        let hidden = UPKeyboard(tooltip: false)
        XCTAssertFalse(hidden.showsToolbar)
        XCTAssertFalse(hidden.showsCancelButton)
        XCTAssertFalse(hidden.showsConfirmButton)
        XCTAssertFalse(hidden.showsTipsText)

        let partial = UPKeyboard(showTips: false, showCancel: false)
        XCTAssertTrue(partial.showsToolbar)
        XCTAssertFalse(partial.showsCancelButton)
        XCTAssertTrue(partial.showsConfirmButton)
        XCTAssertFalse(partial.showsTipsText)
    }

    /// `keyboard.js` 的 16 个默认值。
    func testKeyboardConfigMatchesUpstreamDefaults() {
        XCTAssertEqual(UPConfig.keyboard.mode, "number")
        XCTAssertFalse(UPConfig.keyboard.dotDisabled)
        XCTAssertFalse(UPConfig.keyboard.random)
        XCTAssertFalse(UPConfig.keyboard.autoChange)
        XCTAssertTrue(UPConfig.keyboard.overlay)
        XCTAssertTrue(UPConfig.keyboard.closeOnClickOverlay)
        XCTAssertTrue(UPConfig.keyboard.safeAreaInsetBottom)
        XCTAssertFalse(UPConfig.keyboard.show)
        XCTAssertEqual(UPConfig.keyboard.zIndex, 10075)

        let keyboard = UPKeyboard()
        XCTAssertFalse(keyboard.dotDisabled)
        XCTAssertFalse(keyboard.random)
        XCTAssertFalse(keyboard.autoChange)
        XCTAssertEqual(keyboard.zIndex, 10075)
        XCTAssertTrue(keyboard.overlay)
        XCTAssertTrue(keyboard.closeOnClickOverlay)
        XCTAssertTrue(keyboard.safeAreaInsetBottom)
    }

    /// 上游模板按 `mode == 'number' || mode == 'card'` 把 `dotDisabled` 转发给
    /// `u-number-keyboard`，其余 mode 一律走 `u-car-keyboard`，所以未显式给
    /// `keys` 时按 mode 回落到对应网格。
    func testKeyboardResolvedKeysFollowUpstreamModeBranch() {
        let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        XCTAssertTrue(UPKeyboard().usesNumberKeyboard)
        XCTAssertEqual(UPKeyboard().resolvedKeys.map(\.value), digits + [".", "0"])
        XCTAssertEqual(UPKeyboard(dotDisabled: true).resolvedKeys.map(\.value), digits + ["0"])
        XCTAssertEqual(UPKeyboard(mode: "card").resolvedKeys.map(\.value), digits + ["X", "0"])
        XCTAssertEqual(UPKeyboard(mode: "card", dotDisabled: true).resolvedKeys.map(\.value), digits + ["X", "0"])

        let car = UPKeyboard(mode: "car")
        XCTAssertFalse(car.usesNumberKeyboard)
        XCTAssertEqual(car.resolvedKeys.map(\.value), UPCarKeyboard.provinces)
        XCTAssertEqual(UPKeyboard(mode: "unknown").resolvedKeys.map(\.value), UPCarKeyboard.provinces)
    }

    /// 上游数字网格是 3 列的 `numList`，车牌号网格按 10/10/10/6 切片，
    /// 退格键与 中/英 切换是 v-for 之外的独立单元格，所以只在自动构建时出现。
    func testKeyboardGridShapeMatchesUpstreamLayout() {
        XCTAssertEqual(UPKeyboard().columnCount, 3)
        XCTAssertEqual(UPKeyboard(mode: "card").columnCount, 3)
        XCTAssertEqual(UPKeyboard(mode: "car").columnCount, 10)

        XCTAssertTrue(UPKeyboard().showsBackspaceKey)
        XCTAssertFalse(UPKeyboard().showsInputModeToggle)
        XCTAssertTrue(UPKeyboard(mode: "car").showsInputModeToggle)

        let custom = [UPKeyboardKey(value: "1"), UPKeyboardKey(value: "", label: "删除", kind: .delete)]
        let hosted = UPKeyboard(mode: "car", keys: custom)
        XCTAssertEqual(hosted.resolvedKeys.map(\.label), ["1", "删除"])
        XCTAssertFalse(hosted.showsBackspaceKey)
        XCTAssertFalse(hosted.showsInputModeToggle)
    }

    /// `random` 同时作用于数字网格与车牌号的中文/英文两套网格。
    func testKeyboardRandomShufflesEveryForwardedGrid() {
        let number = UPKeyboard(random: true, randomSource: { Array($0.reversed()) })
        XCTAssertEqual(number.resolvedKeys.map(\.value), ["0", ".", "9", "8", "7", "6", "5", "4", "3", "2", "1"])

        let car = UPKeyboard(mode: "car", random: true, randomSource: { Array($0.reversed()) })
        XCTAssertEqual(car.resolvedKeys.map(\.value), Array(UPCarKeyboard.provinces.reversed()))
        car.changeInputMode()
        XCTAssertEqual(car.resolvedKeys.map(\.value), Array(UPCarKeyboard.letters.reversed()))
    }

    /// `autoChange` 上游只转发给 `u-car-keyboard`：输入一个中文后自动切到英文，
    /// 关闭时停在中文网格直到 `changeCarInputMode` 手动切换；数字键盘不受影响。
    func testKeyboardAutoChangeSwitchesCarGridAfterProvince() {
        let auto = UPKeyboard(mode: "car", autoChange: true)
        XCTAssertEqual(auto.carStage, .province)
        auto.press(UPKeyboardKey(value: "京"))
        XCTAssertEqual(auto.carStage, .letter)
        XCTAssertEqual(auto.resolvedKeys.map(\.value), UPCarKeyboard.letters)

        let manual = UPKeyboard(mode: "car")
        XCTAssertFalse(manual.autoChange)
        manual.press(UPKeyboardKey(value: "京"))
        XCTAssertEqual(manual.carStage, .province)
        manual.changeInputMode()
        XCTAssertEqual(manual.carStage, .letter)
        manual.changeInputMode()
        XCTAssertEqual(manual.carStage, .province)

        let number = UPKeyboard(autoChange: true)
        number.press(UPKeyboardKey(value: "1"))
        XCTAssertEqual(number.carStage, .province)
    }

    /// `u-keyboard` 的 6 个 emit。`change` 回抛被点按键的原值（上游
    /// `keyboardClick(val)` / `carInputClick(i, j)` 都是直接把该键抛出来），
    /// `backspace` 不带载荷，`close`/`closed` 由外层 popup 转发。
    func testKeyboardEmitsUpstreamSixEvents() {
        var events: [String] = []
        let keyboard = UPKeyboard(show: true)
            .onChange { events.append("change:\($0)") }
            .onBackspace { events.append("backspace") }
            .onConfirm { events.append("confirm") }
            .onCancel { events.append("cancel") }
            .onClose { events.append("close") }
            .onClosed { events.append("closed") }

        keyboard.press(UPKeyboardKey(value: "7"))
        keyboard.backspace()
        keyboard.confirm()
        keyboard.cancel()
        keyboard.close()
        keyboard.closed()
        XCTAssertEqual(events, ["change:7", "backspace", "confirm", "cancel", "close", "closed"])
    }

    /// 禁用只拦按键与工具条，popup 的 close/closed 是容器行为，照旧转发。
    func testDisabledKeyboardBlocksKeysButStillForwardsPopupClose() {
        var events: [String] = []
        let keyboard = UPKeyboard(show: true, disabled: true)
            .onChange { events.append("change:\($0)") }
            .onBackspace { events.append("backspace") }
            .onClose { events.append("close") }
            .onClosed { events.append("closed") }
        keyboard.press(UPKeyboardKey(value: "7"))
        keyboard.backspace()
        keyboard.close()
        keyboard.closed()
        XCTAssertEqual(events, ["close", "closed"])
    }

    /// 上游 `popupStyle` 用 `upThemeVar('--up-bg-color', upThemeIsDark ? '#2c2c2e' : 'rgb(214, 218, 220)')`
    /// 给面板铺底，浅色值等价 `#d6dadc`。
    func testKeyboardPanelBackgroundFollowsColorScheme() {
        XCTAssertEqual(UPKeyboard.panelBackgroundColorName(dark: false), "#d6dadc")
        XCTAssertEqual(UPKeyboard.panelBackgroundColorName(dark: true), "#2c2c2e")
    }
}
@MainActor
final class MessageInputTests: XCTestCase {
    /// Upstream `getVal` stores the raw value but returns early when it is
    /// longer than `maxlength`, so neither `change` nor `finish` is emitted.
    func testMessageInputRejectsOverLengthInputWithoutEmittingEvents() {
        let value = StringBox("")
        var changes: [String] = []
        var finishes: [String] = []
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4)
            .onChange { changes.append($0) }
            .onFinish { finishes.append($0) }

        input.input("hello")
        XCTAssertTrue(changes.isEmpty)
        XCTAssertTrue(finishes.isEmpty)

        input.input("123")
        XCTAssertEqual(value.value, "123")
        XCTAssertEqual(changes, ["123"])
        XCTAssertTrue(finishes.isEmpty)

        input.input("1234")
        XCTAssertEqual(value.value, "1234")
        XCTAssertEqual(changes, ["123", "1234"])
        XCTAssertEqual(finishes, ["1234"])
    }

    /// The upstream `modelValue` watcher truncates with `substring`, so an
    /// external write is clamped even though user input of the same length is
    /// rejected outright.
    func testExternalModelValueIsTruncatedUnlikeUserInput() {
        let value = StringBox("123456")
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4)

        XCTAssertEqual(input.inputValue, "1234")
    }

    func testMessageInputFocusAndDisabledState() {
        var focused = 0
        var blurred = 0
        let input = UPMessageInput(disabled: false)
            .onFocus { focused += 1 }
            .onBlur { blurred += 1 }
        input.focus()
        input.blur()
        XCTAssertEqual(focused, 1)
        XCTAssertEqual(blurred, 1)

        let disabled = UPMessageInput(disabled: true)
        disabled.input("12")
        XCTAssertEqual(disabled.inputValue, "")
    }

    func testDisabledKeyboardIgnoresInputButKeepsExternalValue() {
        let value = StringBox("12")
        var changes: [String] = []
        let input = UPMessageInput(modelValue: value.binding, maxlength: 4, disabledKeyboard: true)
            .onChange { changes.append($0) }

        input.input("123")

        XCTAssertEqual(input.inputValue, "12")
        XCTAssertEqual(value.value, "12")
        XCTAssertTrue(changes.isEmpty)
    }

    func testDefaultsMatchUpstreamProps() {
        let input = UPMessageInput()

        XCTAssertEqual(input.maxlength, 4)
        XCTAssertEqual(input.mode, "box")
        XCTAssertFalse(input.dotFill)
        XCTAssertTrue(input.breathe)
        XCTAssertFalse(input.autoFocus)
        XCTAssertFalse(input.bold)
        XCTAssertEqual(input.fontSize, 60)
        XCTAssertEqual(input.width, 80)
        XCTAssertEqual(input.activeColor, "#2979ff")
        XCTAssertEqual(input.inactiveColor, "#606266")
        XCTAssertFalse(input.disabledKeyboard)
    }

    func testAcceptsRejectsOnlyOverLengthValues() {
        XCTAssertTrue(UPMessageInput.accepts("", maxlength: 4))
        XCTAssertTrue(UPMessageInput.accepts("1234", maxlength: 4))
        XCTAssertFalse(UPMessageInput.accepts("12345", maxlength: 4))
    }

    func testResolvedModeFallsBackToBox() {
        XCTAssertEqual(UPMessageInput.resolvedMode("box"), "box")
        XCTAssertEqual(UPMessageInput.resolvedMode("middleLine"), "middleLine")
        XCTAssertEqual(UPMessageInput.resolvedMode("bottomLine"), "bottomLine")
        XCTAssertEqual(UPMessageInput.resolvedMode("unexpected"), "box")
    }

    /// Upstream only swaps in `activeColor` for the box border, and only on the
    /// cell at the current fill position.
    func testBorderColorUsesActiveColorOnlyForActiveBoxCell() {
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 2, filledCount: 2, mode: "box", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#2979ff"
        )
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 1, filledCount: 2, mode: "box", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#606266"
        )
        XCTAssertEqual(
            UPMessageInput.borderColorName(atIndex: 2, filledCount: 2, mode: "bottomLine", activeColor: "#2979ff", inactiveColor: "#606266"),
            "#606266"
        )
    }

    func testIsBreathingOnlyAtActiveIndexWhenEnabled() {
        XCTAssertTrue(UPMessageInput.isBreathing(atIndex: 2, filledCount: 2, breathe: true))
        XCTAssertFalse(UPMessageInput.isBreathing(atIndex: 3, filledCount: 2, breathe: true))
        XCTAssertFalse(UPMessageInput.isBreathing(atIndex: 2, filledCount: 2, breathe: false))
    }
}
