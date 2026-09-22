import Observation
import SwiftUI

public typealias UPPopoverTextValue = UPCheckboxTextValue
public typealias UPPopoverUnitValue = UPCheckboxUnitValue

/// 气泡的可见性必须驱动 SwiftUI 刷新，值类型 View 无法直接持有可变状态，
/// 因此用一个 `@Observable` 状态盒承载 `u-tooltip` 的 `showTooltip`。
@MainActor
@Observable
private final class UPPopoverState {
    var show: Bool

    init(show: Bool) {
        self.show = show
    }
}

/// Native popover counterpart of uview-plus `u-popover`.
///
/// 上游 `u-popover.vue` 只是把 10 个 prop 原样转发给 `u-tooltip`（并转发
/// `open`/`close`/`click` 事件、把 `open()`/`close()` 代理到 tooltip），所以这里
/// 直接内联 tooltip 的开合与定位语义。几处上游特性需要留意：
/// - `placement` 虽然被透传，但 `u-tooltip` 并未声明该 prop，真正参与定位的是
///   `direction`，因此原生同样只记录 `placement`。
/// - `triggerMode` 上游只处理 `click` 与 `longpress`，`manual` 依赖 `show` 的
///   watch；`hover` 在 `u-tooltip` 里没有任何处理器，所以不会自动弹出。
/// - `bgColor` 上游只作用于 `u-tooltip` 没有 `#trigger` 插槽时的兜底文本，原生
///   同样只在未提供触发器内容时给兜底文本上底色。
/// - 尾随闭包对应 `#trigger` 插槽，`.content { }` 对应 `#content` 插槽；两者都被
///   上游的 `.up-popover__content`（`padding: 12px 16px`）包裹。
@MainActor
public struct UPPopover<Content: View>: View {
    /// 上游 `u-tooltip` 把淡入淡出写死为 `duration="300"`，不作为 prop 暴露。
    public static var fadeDuration: Double { 300 }
    /// 上游 `indicatorWidth`：14×14 的方块旋转 45° 当作三角指示器。
    public static var indicatorSide: CGFloat { 14 }
    /// 指示器上游用 `-4px` 探出气泡外沿。
    public static var indicatorOverhang: CGFloat { 4 }
    /// 上游 `__list` 的 `border-radius: 5px`。
    public static var bubbleCornerRadius: CGFloat { 5 }
    /// 上游未给气泡文本声明字号，原生取与 `u-tooltip` 触发器文本一致的 14pt。
    public static var textFontSize: CGFloat { 14 }
    /// 上游用 `position: fixed` 的透明 `u-overlay` 防止触摸穿透。SwiftUI 无法从
    /// 子视图脱离父级布局，这里用一个超大透明层近似同样的拦截范围。
    public static var dismissLayerSide: CGFloat { 3_000 }

    public var text: String
    public var color: String
    public var bgColor: String
    public var popupBgColor: String
    /// 仅作记录：上游把它透传给 `u-tooltip`，而 `u-tooltip` 没有这个 prop。
    public var placement: String
    public var triggerMode: String
    public var zIndex: Double
    /// 上游 `{...style, ...forcePosition}` 会整体覆盖计算出的定位；原生把
    /// `top`/`bottom`/`left`/`right` 映射为气泡偏移的覆盖值。
    public var forcePosition: UPStyle
    public var direction: String
    /// 原生扩展：上游的透明遮罩点击必定关闭（`overlayClickHandler`），这里保留
    /// 开关以便宿主自行接管关闭时机。
    public var closeOnClickOutside: Bool
    /// 上游 `show` prop 原值。只有 `triggerMode == "manual"` 时它的变化才会开合。
    let showProp: Bool

    public var show: Bool { state.show }

    @State private var state: UPPopoverState
    private let trigger: Content
    private var contentSlot: AnyView?
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClickHandler: (() -> Void)?
    @Environment(\.upTheme) private var theme

    public init(show: Bool = UPConfig.popover.show,
                text: some UPPopoverTextValue = UPConfig.popover.text,
                color: String = UPConfig.popover.color,
                bgColor: String = UPConfig.popover.bgColor,
                popupBgColor: String = UPConfig.popover.popupBgColor,
                placement: String = UPConfig.popover.placement,
                triggerMode: String = UPConfig.popover.triggerMode,
                zIndex: some UPPopoverUnitValue = UPConfig.popover.zIndex,
                forcePosition: UPStyle = UPConfig.popover.forcePosition,
                direction: String = UPConfig.popover.direction,
                closeOnClickOutside: Bool = true,
                @ViewBuilder trigger: () -> Content) {
        self.text = text.upCheckboxTextValue
        self.color = color
        self.bgColor = bgColor
        self.popupBgColor = popupBgColor
        self.placement = placement
        self.triggerMode = triggerMode
        self.zIndex = Self.resolveZIndex(zIndex.upCheckboxUnitValue, fallback: UPConfig.popover.zIndex)
        self.forcePosition = forcePosition
        self.direction = direction
        self.closeOnClickOutside = closeOnClickOutside
        self.showProp = show
        self.trigger = trigger()
        // 上游挂载时 `getElRect()` 会强制关闭气泡，`show` 初值不会生效；原生没有
        // 这段测量流程，按其它组件的约定直接用初值播种可见性。
        self._state = State(initialValue: UPPopoverState(show: show))
    }

    // MARK: - 上游方法

    /// 对应上游 `open()`（经 `$refs.tooltip.open()`）。已展开时直接返回。
    public func open() {
        guard !state.show else { return }
        state.show = true
        onOpenHandler?()
    }

    /// 对应上游 `close()`（经 `$refs.tooltip.close()`）。已收起时直接返回。
    public func close() {
        guard state.show else { return }
        state.show = false
        onCloseHandler?()
    }

    /// 对应上游 `watch.show`：只有 `manual` 模式才跟随 `show` 开合。
    func applyManualVisibility(_ newValue: Bool) {
        guard Self.respondsToShowProp(triggerMode: triggerMode) else { return }
        if newValue { open() } else { close() }
    }

    /// 对应上游 `clickHander()`：先转发 `click`，再按 `triggerMode` 决定是否展开。
    ///
    /// 上游 `click` 转发自 `u-tooltip` 的按钮点击，而 popover 始终提供 `#content`
    /// 插槽，使那些按钮不会渲染，该事件实际永不触发；原生按组件文档的语义
    /// 「点击触发器时触发」回调。
    func handleTriggerTap() {
        onClickHandler?()
        guard Self.opensOnTap(triggerMode: triggerMode) else { return }
        open()
    }

    /// 对应上游 `longpressHandler()`。
    func handleTriggerLongPress() {
        guard Self.opensOnLongPress(triggerMode: triggerMode) else { return }
        open()
    }

    /// 对应上游 `overlayClickHandler()`。
    func handleOutsideTap() {
        guard closeOnClickOutside else { return }
        close()
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
        default: return UPConfig.popover.direction
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

    /// 等价于上游 `$slots['trigger']` 是否存在。
    public var hasTriggerSlot: Bool { Content.self != EmptyView.self }

    public static func overlayAlignment(for direction: String) -> Alignment {
        switch resolvedDirection(direction) {
        case "bottom": return .bottom
        case "left": return .leading
        case "right": return .trailing
        default: return .top
        }
    }

    private nonisolated static func resolveZIndex(_ value: String, fallback: Double) -> Double {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let parsed = Double(UPUnit.parse(trimmed))
        return parsed.isFinite ? parsed : fallback
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
    }

    @ViewBuilder private var triggerView: some View {
        if hasTriggerSlot {
            trigger
        } else {
            Text(text)
                .font(.system(size: Self.textFontSize))
                .foregroundStyle(UPColor.parse(color, theme: theme))
                .background(resolvedTriggerBackground.map { UPColor.parse($0, theme: theme) } ?? Color.clear)
        }
    }

    @ViewBuilder private var dismissLayer: some View {
        if show, closeOnClickOutside {
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
                .background(UPColor.parse(popupBgColor, theme: theme))
                .clipShape(RoundedRectangle(cornerRadius: Self.bubbleCornerRadius))
        )
        .fixedSize()
        .offset(x: bubbleOffset.width, y: bubbleOffset.height)
        .zIndex(zIndex)
        .transition(.opacity)
    }

    /// 上游 `.up-popover__content`：flex 居中 + `padding: 12px 16px`，插槽内容与
    /// `text` 兜底都在这个容器里。
    private var bubbleBody: some View {
        HStack(alignment: .center, spacing: 0) {
            if let contentSlot {
                contentSlot
            } else {
                Text(text)
                    .font(.system(size: Self.textFontSize))
                    .foregroundStyle(UPColor.parse(color, theme: theme))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    /// 指示器上游 `z-index: -1`，因此这里用 `background` 而非 `overlay` 垫在气泡后面。
    @ViewBuilder private func withIndicator<Bubble: View>(_ bubble: Bubble) -> some View {
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
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(UPColor.parse(popupBgColor, theme: theme))
            .frame(width: Self.indicatorSide, height: Self.indicatorSide)
            .rotationEffect(.degrees(45))
    }
}

public extension UPPopover {
    /// 等价于上游 `$slots['content']` 是否存在。
    var hasContentSlot: Bool { contentSlot != nil }

    /// 对应上游 `#content` 具名插槽；未提供时渲染 `text`。
    func content<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPPopover {
        var copy = self
        copy.contentSlot = AnyView(builder())
        return copy
    }

    func onOpen(_ action: @escaping () -> Void) -> UPPopover {
        var copy = self
        copy.onOpenHandler = action
        return copy
    }

    func onClose(_ action: @escaping () -> Void) -> UPPopover {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPPopover {
        var copy = self
        copy.onClickHandler = action
        return copy
    }
}

public extension UPPopover where Content == EmptyView {
    init(show: Bool = UPConfig.popover.show,
         text: some UPPopoverTextValue = UPConfig.popover.text,
         color: String = UPConfig.popover.color,
         bgColor: String = UPConfig.popover.bgColor,
         popupBgColor: String = UPConfig.popover.popupBgColor,
         placement: String = UPConfig.popover.placement,
         triggerMode: String = UPConfig.popover.triggerMode,
         zIndex: some UPPopoverUnitValue = UPConfig.popover.zIndex,
         forcePosition: UPStyle = UPConfig.popover.forcePosition,
         direction: String = UPConfig.popover.direction,
         closeOnClickOutside: Bool = true) {
        self.init(show: show,
                  text: text,
                  color: color,
                  bgColor: bgColor,
                  popupBgColor: popupBgColor,
                  placement: placement,
                  triggerMode: triggerMode,
                  zIndex: zIndex,
                  forcePosition: forcePosition,
                  direction: direction,
                  closeOnClickOutside: closeOnClickOutside,
                  trigger: EmptyView.init)
    }
}
