import Observation
import SwiftUI

/// 对应上游 `data` 里的取色状态：色相/饱和度/明度/透明度、渐变节点与弹窗可见性。
@MainActor
@Observable
final class UPColorPickerState {
    var show = false
    /// 0 纯色、1 渐变，对应上游 `colorTypeIndex`。
    var colorTypeIndex = 0
    var hue: Double = 0
    var saturation: Double = 100
    var lightness: Double = 50
    var alpha: Double = 1
    var stops: [UPColorPickerStop]
    var direction: UPColorPickerDirection = .toRight
    /// 对应上游 `editingGradientIndex`：正在改哪个渐变节点。
    var editingStopIndex = -1
    /// 上游 `currentColor`：纯色模式下的当前色值。
    var currentColor: String

    init(color: String) {
        self.currentColor = color
        self.stops = [
            UPColorPickerStop(color: "#ff0000", percent: 0),
            UPColorPickerStop(color: "#0000ff", percent: 1)
        ]
    }
}

/// Native SwiftUI counterpart of uview-plus `u-color-picker`.
///
/// 上游是一个底部弹出的自绘取色面板：纯色/渐变分段、饱和度-明度方块、色相条、
/// 透明度条、常用色板、渐变节点轨道与圆形方向盘，确认时把 `#rgb` / `rgba()` /
/// `linear-gradient(...)` 写回 `v-model`。
///
/// 原生保留同一套交互与数值模型（`UPColorMath` 负责 HSL ↔ RGB 与渐变串），
/// 差异有两处：饱和度-明度方块用 `DragGesture` 取点，上游是 `boundingClientRect`
/// 加 touch 坐标；圆形方向盘换成八向按钮，指针角度仍按上游 `getDirectionAngle` 计算。
@MainActor
public struct UPColorPicker: View {
    /// 上游 `.up-color-picker__saturation` 的高度。
    public static var saturationHeight: CGFloat { 150 }
    /// 上游 `.up-color-picker__gradient-track` 的宽度。
    public static var trackWidth: CGFloat { 280 }
    /// 上游 `addGradientColor` 限制最多 5 个节点、`removeGradientColor` 至少留 2 个。
    public static var maxStops: Int { 5 }
    public static var minStops: Int { 2 }

    @Binding public var color: String
    /// 上游 `commonColors`。
    public var commonColors: [String]
    /// 原生扩展：系统取色器是否支持透明度。
    public var showAlpha: Bool

    @State private var state: UPColorPickerState
    @Environment(\.upTheme) private var theme
    private var onChangeHandler: ((String) -> Void)?
    private var onConfirmHandler: ((String) -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    private var triggerSlot: AnyView?

    public init(color: Binding<String>,
                commonColors: [String] = UPConfig.colorPicker.commonColors,
                showAlpha: Bool = false,
                onChange: ((String) -> Void)? = nil) {
        _color = color
        self.commonColors = commonColors
        self.showAlpha = showAlpha
        self.onChangeHandler = onChange
        self._state = State(initialValue: UPColorPickerState(color: color.wrappedValue))
    }

    // MARK: - 状态

    /// 对应上游 `data.show`。
    public var show: Bool { state.show }

    public var colorTypeIndex: Int { state.colorTypeIndex }
    public var hue: Double { state.hue }
    public var saturation: Double { state.saturation }
    public var lightness: Double { state.lightness }
    public var alpha: Double { state.alpha }
    public var stops: [UPColorPickerStop] { state.stops }
    public var direction: UPColorPickerDirection { state.direction }

    /// 对应上游 `currentColor`。
    public var currentColor: String { state.currentColor }

    /// 对应上游 `editingGradientIndex`；`-1` 表示没有在编辑渐变节点。
    public var editingStopIndex: Int { state.editingStopIndex }

    /// 对应上游 `gradientStyle`。
    public var gradientText: String {
        UPColorMath.gradientText(stops: state.stops, direction: state.direction)
    }

    /// 对应上游 `displayColor`：编辑渐变节点时预览该节点色，否则预览当前色。
    public var displayColor: String {
        if state.colorTypeIndex == 1, state.stops.indices.contains(state.editingStopIndex) {
            return state.stops[state.editingStopIndex].color
        }
        return state.colorTypeIndex == 1 ? gradientText : state.currentColor
    }

    /// 上游 `getGradientPointerPosition(index)`。
    public func pointerPosition(at index: Int) -> CGFloat {
        guard state.stops.indices.contains(index) else { return 0 }
        return CGFloat(state.stops[index].percent) * Self.trackWidth
    }

    // MARK: - 上游方法

    /// 上游点击触发器时 `show = true`，随后 `watch.show` 调 `initColor()`。
    public func open() {
        initColor()
        state.show = true
    }

    /// 对应上游 `initColor()`：按 `modelValue` 判断纯色还是渐变，并还原游标。
    public func initColor() {
        let value = color.isEmpty ? UPConfig.colorPicker.modelValue : color
        state.currentColor = value
        if UPColorMath.isGradient(value), let gradient = UPColorMath.gradient(of: value) {
            state.colorTypeIndex = 1
            state.direction = gradient.direction
            state.stops = gradient.stops
            state.editingStopIndex = -1
            return
        }
        state.colorTypeIndex = 0
        applySolid(value)
    }

    /// 对应上游 `parseSolidColor`：把色值还原成 HSL 三个游标。
    public func applySolid(_ value: String) {
        state.currentColor = value
        guard let parsed = UPColorMath.hsl(of: value) else { return }
        state.hue = parsed.hue
        state.saturation = parsed.saturation
        state.lightness = parsed.lightness
        state.alpha = parsed.alpha
    }

    /// 对应上游 `changeColorType(index)`。
    public func changeColorType(_ index: Int) {
        state.colorTypeIndex = index == 1 ? 1 : 0
        state.editingStopIndex = -1
    }

    /// 对应上游 `updateSolidColor()`：由游标算出 `rgba()`。
    /// 渐变模式下写进正在编辑的节点。
    public func updateSolidColor() {
        let value = UPColorMath.rgbaText(hue: state.hue,
                                        saturation: state.saturation,
                                        lightness: state.lightness,
                                        alpha: state.alpha)
        guard state.colorTypeIndex == 1, state.stops.indices.contains(state.editingStopIndex) else {
            state.currentColor = value
            return
        }
        state.stops[state.editingStopIndex].color = value
    }

    public func setHue(_ value: Double) {
        state.hue = min(max(value, 0), 360)
        updateSolidColor()
    }

    public func setAlpha(_ value: Double) {
        state.alpha = min(max(value, 0), 1)
        updateSolidColor()
    }

    /// 上游用触点位置反推饱和度与明度：x 轴是饱和度、y 轴自上而下是明度递减。
    public func setSaturationPoint(_ point: CGPoint, in size: CGSize) {
        let side = max(min(size.width, size.height), 1)
        state.saturation = min(max(point.x / side, 0), 1) * 100
        state.lightness = 100 - min(max(point.y / side, 0), 1) * 100
        updateSolidColor()
    }

    /// 对应上游 `selectCommonColor(color)`。
    public func selectCommonColor(_ value: String) {
        state.currentColor = value
        if state.colorTypeIndex == 1, state.stops.indices.contains(state.editingStopIndex) {
            state.stops[state.editingStopIndex].color = value
        } else {
            applySolid(value)
        }
    }

    /// 对应上游 `openColorPickerForGradient(index)`。
    public func editStop(_ index: Int) {
        guard state.stops.indices.contains(index) else { return }
        state.editingStopIndex = index
        applySolid(state.stops[index].color)
    }

    /// 对应上游 `addGradientColor()`：最多 5 个节点。
    public func addStop() {
        guard state.stops.count < Self.maxStops else { return }
        state.stops.append(UPColorPickerStop(color: "#ffffff", percent: 1))
    }

    /// 对应上游 `removeGradientColor(index)`：至少留 2 个。
    public func removeStop(_ index: Int) {
        guard state.stops.count > Self.minStops, state.stops.indices.contains(index) else { return }
        state.stops.remove(at: index)
        if state.editingStopIndex >= state.stops.count { state.editingStopIndex = -1 }
    }

    /// 对应上游 `updateGradientColor`：拖动节点改 `percent` 并保持顺序。
    public func moveStop(_ index: Int, percent: Double) {
        guard state.stops.indices.contains(index) else { return }
        state.stops[index].percent = min(max(percent, 0), 1)
        state.stops.sort { $0.percent < $1.percent }
    }

    public func setDirection(_ value: UPColorPickerDirection) {
        state.direction = value
    }

    /// 对应上游 `confirm()`：写回 `v-model`、关窗、抛 `confirm` 再抛 `close`。
    public func confirm() {
        let value = state.colorTypeIndex == 1 ? gradientText : state.currentColor
        color = value
        state.show = false
        onChangeHandler?(value)
        onConfirmHandler?(value)
        onCloseHandler?()
        onClosedHandler?()
    }

    /// 对应上游 `close()`。
    public func close() {
        state.show = false
        onCloseHandler?()
        onClosedHandler?()
    }

    /// 仓库既有 API：直接写值。
    public func select(_ value: String) {
        color = value
        state.currentColor = value
        onChangeHandler?(value)
    }

    // MARK: - 事件

    public func onChange(_ action: @escaping (String) -> Void) -> UPColorPicker {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游 `confirm` 事件。
    public func onConfirm(_ action: @escaping (String) -> Void) -> UPColorPicker {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    /// 对应上游 `close` 事件。
    public func onClose(_ action: @escaping () -> Void) -> UPColorPicker {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    /// 对应上游 `closed` 事件（弹窗离场动画结束）。
    public func onClosed(_ action: @escaping () -> Void) -> UPColorPicker {
        var copy = self
        copy.onClosedHandler = action
        return copy
    }

    /// 等价于上游默认插槽是否存在。
    public var hasTriggerSlot: Bool { triggerSlot != nil }

    /// 对应上游默认插槽：替换触发器内容（默认是一个当前色的色块）。
    public func trigger<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPColorPicker {
        var copy = self
        copy.triggerSlot = AnyView(builder())
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        triggerView
            .contentShape(Rectangle())
            .onTapGesture { open() }
            .overlay { panel }
    }

    @ViewBuilder
    private var triggerView: some View {
        if let triggerSlot {
            triggerSlot
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(UPColor.parse(color, theme: theme))
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(theme.border, lineWidth: 1)
                }
        }
    }

    private var panel: some View {
        UPPopup(show: Binding(get: { state.show }, set: { if !$0 { close() } }),
                mode: "bottom",
                closeOnClickOverlay: true,
                round: "10px") {
            UPColorPickerPanel(picker: self)
        }
    }
}
