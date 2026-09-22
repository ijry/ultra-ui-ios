import Observation
import SwiftUI

public typealias UPTooltipTextValue = UPCheckboxTextValue
public typealias UPTooltipUnitValue = UPCheckboxUnitValue

/// 气泡的可见性必须驱动 SwiftUI 刷新，值类型 View 无法直接持有可变状态，
/// 因此用一个 `@Observable` 状态盒承载上游的 `showTooltip`。
@MainActor
@Observable
final class UPTooltipState {
    var show: Bool
    /// 单例互斥时由 `UPTooltipCenter` 触发的关闭回调，等价于上游
    /// `activeSingletonTooltip.close()` 会走到那个实例自己的 `$emit('close')`。
    @ObservationIgnored var onClose: (() -> Void)?

    init(show: Bool) {
        self.show = show
    }

    func dismiss() {
        guard show else { return }
        show = false
        onClose?()
    }
}

/// 对应上游模块级变量 `activeSingletonTooltip`：`singleton` 为真的 tooltip
/// 同一时刻只允许一个展开。
@MainActor
public final class UPTooltipCenter {
    public static let shared = UPTooltipCenter()

    private weak var active: UPTooltipState?

    init() {}

    /// 上游 `open()` 开头的互斥分支。
    func activate(_ state: UPTooltipState) {
        if let active, active !== state { active.dismiss() }
        active = state
    }

    /// 上游 `close()` / `clearActiveTooltip()` 会把自己从全局变量上摘掉。
    func deactivate(_ state: UPTooltipState) {
        guard active === state else { return }
        active = nil
    }

    /// 便于单测断言当前占位者。
    var hasActive: Bool { active != nil }
}

/// Native SwiftUI counterpart of uview-plus `u-tooltip`.
///
/// 与上游的差异集中在测量与遮罩：
/// - 上游在 `getElRect()` 里把气泡挪到屏幕外量尺寸，再据此算「贴边重定位」
///   （`screenGap: 12`）。SwiftUI 的 overlay 由父级裁剪，原生用对齐 + 偏移定位，
///   不做贴边重算；需要精确位置时用 `forcePosition`。
/// - `overlay` 上游是 `position: fixed` 的全屏透明层，原生用一个超大透明层近似
///   同样的拦截范围（与 `UPPopover` 一致）。
@MainActor
public struct UPTooltip<Content: View>: View {
    /// 上游 `u-transition` 的 `duration="300"`，写死不作为 prop。
    public static var fadeDuration: Double { 300 }
    /// 上游 `indicatorWidth`：14×14 方块旋转 45° 当三角指示器。
    public static var indicatorSide: CGFloat { 14 }
    /// 指示器上游用 `-4px` 探出气泡外沿。
    public static var indicatorOverhang: CGFloat { 4 }
    /// 上游 `__list` 的 `border-radius: 5px`。
    public static var bubbleCornerRadius: CGFloat { 5 }
    /// 上游 `__list` 与 `__indicator` 的 `background-color: #060607`。
    public static var defaultPopupBackground: String { "#060607" }
    /// 上游 `__btn__text` 的 13pt 白字，`__btn` 的 `padding: 11px 13px`。
    public static var buttonFontSize: CGFloat { 13 }
    /// 上游 `u-line` 分隔线：`color="#8d8e90"`、`length="18"`。
    public static var separatorColor: String { "#8d8e90" }
    public static var separatorLength: CGFloat { 18 }
    /// 与 `UPPopover` 同一套透明遮罩尺寸。
    public static var dismissLayerSide: CGFloat { 3_000 }

    public var text: String
    public var copyText: String
    public var size: CGFloat
    public var color: String
    public var bgColor: String
    public var popupBgColor: String
    public var direction: String
    public var zIndex: Double
    public var showCopy: Bool
    public var buttons: [String]
    public var overlay: Bool
    public var showToast: Bool
    public var triggerMode: String
    /// 上游 `{...style, ...forcePosition}` 会整体覆盖计算出的定位；原生把
    /// `top`/`bottom`/`left`/`right` 映射为气泡偏移的覆盖值。
    public var forcePosition: UPStyle
    public var singleton: Bool
    /// 上游 `show` prop 原值，只有 `triggerMode == "manual"` 时变化才会开合。
    let showProp: Bool

    public var show: Bool { state.show }

    @State private var state: UPTooltipState
    private let trigger: Content
    private var contentSlot: AnyView?
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClickHandler: ((Int) -> Void)?
    /// 便于单测替换，语义与 `UPCopy` 一致。
    var clipboardWriter: UPClipboardWriter
    @Environment(\.upTheme) private var theme

    public init(text: some UPTooltipTextValue = UPConfig.tooltip.text,
                copyText: some UPTooltipTextValue = UPConfig.tooltip.copyText,
                size: some UPTooltipUnitValue = UPConfig.tooltip.size,
                color: String = UPConfig.tooltip.color,
                bgColor: String = UPConfig.tooltip.bgColor,
                popupBgColor: String = UPConfig.tooltip.popupBgColor,
                direction: String = UPConfig.tooltip.direction,
                zIndex: some UPTooltipUnitValue = UPConfig.tooltip.zIndex,
                showCopy: Bool = UPConfig.tooltip.showCopy,
                buttons: [String] = UPConfig.tooltip.buttons,
                overlay: Bool = UPConfig.tooltip.overlay,
                showToast: Bool = UPConfig.tooltip.showToast,
                triggerMode: String = UPConfig.tooltip.triggerMode,
                forcePosition: UPStyle = UPConfig.tooltip.forcePosition,
                show: Bool = UPConfig.tooltip.show,
                singleton: Bool = UPConfig.tooltip.singleton,
                @ViewBuilder trigger: () -> Content) {
        self.text = text.upCheckboxTextValue
        self.copyText = copyText.upCheckboxTextValue
        self.size = Self.resolveLength(size.upCheckboxUnitValue, fallback: UPConfig.tooltip.size)
        self.color = color
        self.bgColor = bgColor
        self.popupBgColor = popupBgColor
        self.direction = direction
        self.zIndex = Double(Self.resolveLength(zIndex.upCheckboxUnitValue, fallback: UPConfig.tooltip.zIndex))
        self.showCopy = showCopy
        self.buttons = buttons
        self.overlay = overlay
        self.showToast = showToast
        self.triggerMode = triggerMode
        self.forcePosition = forcePosition
        self.singleton = singleton
        self.showProp = show
        self.trigger = trigger()
        self.clipboardWriter = UPSystemClipboard.write
        // 上游挂载时 `getElRect()` 会强制关闭气泡，`show` 初值不会立刻生效；
        // 原生没有这段测量流程，按其它组件的约定直接用初值播种可见性。
        self._state = State(initialValue: UPTooltipState(show: show))
    }

    // MARK: - 上游方法

    /// 对应上游 `open()`。已展开时直接返回，`singleton` 时先关掉别的实例。
    public func open() {
        if singleton { UPTooltipCenter.shared.activate(state) }
        guard !state.show else { return }
        state.onClose = onCloseHandler
        state.show = true
        onOpenHandler?()
    }

    /// 对应上游 `close()`。
    public func close() {
        UPTooltipCenter.shared.deactivate(state)
        guard state.show else { return }
        state.show = false
        onCloseHandler?()
    }

    /// 仓库既有的别名。
    public func showTooltip() { open() }

    public func hideTooltip() { close() }

    /// 对应上游 `watch.show`：只有 `manual` 模式才跟随 `show` 开合。
    func applyManualVisibility(_ newValue: Bool) {
        guard Self.respondsToShowProp(triggerMode: triggerMode) else { return }
        if newValue { open() } else { close() }
    }

    /// 对应上游 `clickHander()`。
    func handleTriggerTap() {
        guard Self.opensOnTap(triggerMode: triggerMode) else { return }
        open()
    }

    /// 对应上游 `longpressHandler()`。
    func handleTriggerLongPress() {
        guard Self.opensOnLongPress(triggerMode: triggerMode) else { return }
        open()
    }

    /// 对应上游 `overlayClickHandler()`：透明遮罩的点击必定关闭。
    func handleOutsideTap() { close() }

    /// 对应上游 `setClipboardData()`：先关闭、抛 `click(0)`，再写剪贴板并提示。
    public func copy() {
        close()
        onClickHandler?(0)
        let payload = copyText.isEmpty ? text : copyText
        let succeeded = clipboardWriter(payload)
        guard showToast else { return }
        UPToast.show(message: succeeded ? "复制成功" : "复制失败")
    }

    /// 对应上游 `btnClickHandler(index)`：`showCopy` 为真时复制占了 0，扩展按钮从 1 起。
    public func tapButton(_ index: Int) {
        guard buttons.indices.contains(index) else { return }
        close()
        onClickHandler?(showCopy ? index + 1 : index)
    }

    // MARK: - 解析后的呈现值

    public static func opensOnTap(triggerMode: String) -> Bool { triggerMode == "click" }
    public static func opensOnLongPress(triggerMode: String) -> Bool { triggerMode == "longpress" }
    public static func respondsToShowProp(triggerMode: String) -> Bool { triggerMode == "manual" }

    /// 上游只为 `top`/`bottom`/`left`/`right` 计算定位，其余取值会退化成盖在触发器
    /// 上；原生统一回落到声明的默认方向。
    public static func resolvedDirection(_ value: String) -> String {
        switch value {
        case "top", "bottom", "left", "right": return value
        default: return UPConfig.tooltip.direction
        }
    }

    public var resolvedDirection: String { Self.resolvedDirection(direction) }

    /// `top`/`bottom` 对应上游的 `marginTop`/`marginBottom: -10px`，
    /// `left`/`right` 对应 `triggerInfo.width + indicatorWidth` 的水平间距。
    public static func baseOffset(direction: String) -> CGSize {
        switch resolvedDirection(direction) {
        case "bottom": return CGSize(width: 0, height: 10)
        case "left": return CGSize(width: -indicatorSide, height: 0)
        case "right": return CGSize(width: indicatorSide, height: 0)
        default: return CGSize(width: 0, height: -10)
        }
    }

    public var bubbleOffset: CGSize {
        var offset = Self.baseOffset(direction: direction)
        if let left = forcePosition.length(for: "left") {
            offset.width = left
        } else if let right = forcePosition.length(for: "right") {
            offset.width = -right
        }
        if let top = forcePosition.length(for: "top") {
            offset.height = top
        } else if let bottom = forcePosition.length(for: "bottom") {
            offset.height = -bottom
        }
        return offset
    }

    /// 上游 `bgColor && showTooltip` 才给兜底触发文本上底色。
    public var resolvedTriggerBackground: String? {
        guard show, !hasTriggerSlot else { return nil }
        let normalized = bgColor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized != "transparent" else { return nil }
        return normalized
    }

    /// 上游 `popupBgColor` 为空时沿用 CSS 里的 `#060607`。
    public var resolvedPopupBackground: String {
        let normalized = popupBgColor.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? Self.defaultPopupBackground : normalized
    }

    /// 等价于上游 `$slots['trigger']` 是否存在。
    public var hasTriggerSlot: Bool { Content.self != EmptyView.self }

    /// 上游 `v-if="showCopy || buttons.length"` 才画指示器。
    public var showsIndicator: Bool { showCopy || !buttons.isEmpty }

    public static func overlayAlignment(for direction: String) -> Alignment {
        switch resolvedDirection(direction) {
        case "bottom": return .bottom
        case "left": return .leading
        case "right": return .trailing
        default: return .top
        }
    }

    private nonisolated static func resolveLength(_ value: String, fallback: Double) -> CGFloat {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return CGFloat(fallback) }
        let parsed = UPUnit.parse(trimmed)
        return parsed > 0 ? parsed : CGFloat(fallback)
    }

    // MARK: - 视图

    public var body: some View {
        triggerView
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { handleTriggerTap() })
            .simultaneousGesture(LongPressGesture().onEnded { _ in handleTriggerLongPress() })
            .overlay { dismissLayer }
            .overlay(alignment: Self.overlayAlignment(for: direction)) { positionedBubble }
            .animation(.easeInOut(duration: Self.fadeDuration / 1_000), value: show)
            .onChange(of: showProp) { _, newValue in applyManualVisibility(newValue) }
            .onDisappear { UPTooltipCenter.shared.deactivate(state) }
    }

    @ViewBuilder private var triggerView: some View {
        if hasTriggerSlot {
            trigger
        } else {
            Text(text)
                .font(.system(size: size))
                .foregroundStyle(UPColor.parse(color, theme: theme))
                .background(resolvedTriggerBackground.map { UPColor.parse($0, theme: theme) } ?? Color.clear)
        }
    }

    @ViewBuilder private var dismissLayer: some View {
        if show, overlay {
            Color.clear
                .frame(width: Self.dismissLayerSide, height: Self.dismissLayerSide)
                .contentShape(Rectangle())
                .onTapGesture { handleOutsideTap() }
        }
    }

    @ViewBuilder private var positionedBubble: some View {
        if show {
            switch resolvedDirection {
            case "bottom":
                bubbleCore.alignmentGuide(.bottom) { $0[.top] }
            case "left":
                bubbleCore.alignmentGuide(.leading) { $0[.trailing] }
            case "right":
                bubbleCore.alignmentGuide(.trailing) { $0[.leading] }
            default:
                bubbleCore.alignmentGuide(.top) { $0[.bottom] }
            }
        }
    }

    private var bubbleCore: some View {
        withIndicator(
            bubbleBody
                .background(UPColor.parse(resolvedPopupBackground, theme: theme))
                .clipShape(RoundedRectangle(cornerRadius: Self.bubbleCornerRadius))
        )
        .fixedSize()
        .offset(x: bubbleOffset.width, y: bubbleOffset.height)
        .zIndex(zIndex)
        .transition(.opacity)
    }

    /// 上游 `__list`：`#content` 插槽优先，否则渲染「复制」与 `buttons`，
    /// 相邻按钮之间插一条竖线。
    private var bubbleBody: some View {
        HStack(spacing: 0) {
            if let contentSlot {
                contentSlot
            } else {
                if showCopy {
                    bubbleButton("复制") { copy() }
                }
                if showCopy, !buttons.isEmpty { separator }
                ForEach(Array(buttons.enumerated()), id: \.offset) { index, title in
                    bubbleButton(title) { tapButton(index) }
                    if index < buttons.count - 1 { separator }
                }
            }
        }
    }

    private func bubbleButton(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(.system(size: Self.buttonFontSize))
            .foregroundStyle(Color.white)
            .padding(.vertical, 11)
            .padding(.horizontal, 13)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private var separator: some View {
        UPLine(color: Self.separatorColor,
               length: String(describing: Int(Self.separatorLength)),
               direction: "column")
    }

    /// 指示器上游 `z-index: -1`，因此这里用 `background` 而非 `overlay` 垫在气泡后面。
    @ViewBuilder private func withIndicator<Bubble: View>(_ bubble: Bubble) -> some View {
        if showsIndicator {
            switch resolvedDirection {
            case "bottom":
                bubble.background(alignment: .top) { indicator.offset(y: -Self.indicatorOverhang) }
            case "left":
                bubble.background(alignment: .trailing) { indicator.offset(x: Self.indicatorOverhang) }
            case "right":
                bubble.background(alignment: .leading) { indicator.offset(x: -Self.indicatorOverhang) }
            default:
                bubble.background(alignment: .bottom) { indicator.offset(y: Self.indicatorOverhang) }
            }
        } else {
            bubble
        }
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(UPColor.parse(resolvedPopupBackground, theme: theme))
            .frame(width: Self.indicatorSide, height: Self.indicatorSide)
            .rotationEffect(.degrees(45))
    }
}

public extension UPTooltip {
    /// 等价于上游 `$slots['content']` 是否存在。
    var hasContentSlot: Bool { contentSlot != nil }

    /// 对应上游 `#content` 具名插槽；未提供时渲染「复制」与 `buttons`。
    func content<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPTooltip {
        var copy = self
        copy.contentSlot = AnyView(builder())
        return copy
    }

    func onOpen(_ action: @escaping () -> Void) -> UPTooltip {
        var copy = self
        copy.onOpenHandler = action
        return copy
    }

    func onClose(_ action: @escaping () -> Void) -> UPTooltip {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    /// 对应上游 `click` 事件：参数是被点按钮的下标（0 是「复制」）。
    func onClick(_ action: @escaping (Int) -> Void) -> UPTooltip {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

}

extension UPTooltip {
    /// 注入剪贴板实现，语义与 `UPCopy` 的 internal init 一致，仅供单测使用。
    func clipboard(_ writer: @escaping UPClipboardWriter) -> UPTooltip {
        var copy = self
        copy.clipboardWriter = writer
        return copy
    }
}

public extension UPTooltip where Content == EmptyView {
    init(text: some UPTooltipTextValue = UPConfig.tooltip.text,
         copyText: some UPTooltipTextValue = UPConfig.tooltip.copyText,
         size: some UPTooltipUnitValue = UPConfig.tooltip.size,
         color: String = UPConfig.tooltip.color,
         bgColor: String = UPConfig.tooltip.bgColor,
         popupBgColor: String = UPConfig.tooltip.popupBgColor,
         direction: String = UPConfig.tooltip.direction,
         zIndex: some UPTooltipUnitValue = UPConfig.tooltip.zIndex,
         showCopy: Bool = UPConfig.tooltip.showCopy,
         buttons: [String] = UPConfig.tooltip.buttons,
         overlay: Bool = UPConfig.tooltip.overlay,
         showToast: Bool = UPConfig.tooltip.showToast,
         triggerMode: String = UPConfig.tooltip.triggerMode,
         forcePosition: UPStyle = UPConfig.tooltip.forcePosition,
         show: Bool = UPConfig.tooltip.show,
         singleton: Bool = UPConfig.tooltip.singleton) {
        self.init(text: text,
                  copyText: copyText,
                  size: size,
                  color: color,
                  bgColor: bgColor,
                  popupBgColor: popupBgColor,
                  direction: direction,
                  zIndex: zIndex,
                  showCopy: showCopy,
                  buttons: buttons,
                  overlay: overlay,
                  showToast: showToast,
                  triggerMode: triggerMode,
                  forcePosition: forcePosition,
                  show: show,
                  singleton: singleton,
                  trigger: EmptyView.init)
    }
}
