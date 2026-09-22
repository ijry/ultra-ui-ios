import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-sticky` unit props.
public typealias UPStickyUnitValue = UPImageUnitValue

/// 仓库既有事件负载：`index` + 是否吸顶。
///
/// 上游文档注释写了 `@event fixed` / `@event unfixed`，但 `.vue` 里既没有 `emits`
/// 声明、也没有任何 `$emit`：`setFixed(top)` 只改内部 `fixed` 标记。因此这是原生扩展。
public struct UPStickyChange: Equatable, Sendable {
    public var index: String
    public var isFixed: Bool
    public init(index: String, isFixed: Bool) { self.index = index; self.isFixed = isFixed }
}

/// 对应上游 `data`：`fixed` 与量出来的内容尺寸。
@MainActor
@Observable
private final class UPStickyState {
    /// 上游 `fixed`：js 模式下是否处于吸顶。
    var fixed = false
    /// 上游 `height` / `left` / `width`：js 模式下要还原的内容尺寸。
    var contentHeight: CGFloat = 0
    var contentWidth: CGFloat = 0
    var contentLeft: CGFloat = 0
}

/// Native SwiftUI counterpart of uview-plus `u-sticky`.
///
/// 上游先探测平台是否支持 `position: sticky`：支持就直接用 CSS 吸顶，不支持就退回
/// IntersectionObserver + `position: fixed` 的 js 方案（此时要把量到的宽高回填给父元素，
/// 防止塌陷）。iOS 一侧只需要前者语义，原生用 `overlay` + 滚动探针复刻吸顶判定，
/// 同时保留上游 `stickyTop = offsetTop + customNavHeight` 的算法与 js 模式下的尺寸记录。
@MainActor
public struct UPSticky<Content: View>: View {
    /// 上游 `offsetTop`。
    public var offsetTop: CGFloat
    /// 上游 `customNavHeight`：H5 端默认 44，其他端 0。
    public var customNavHeight: CGFloat
    public var disabled: Bool
    public var bgColor: String
    /// 上游 `zIndex`：空串表示交给 `zIndex.sticky`。
    public var zIndex: String
    /// 上游 `index`：自定义标识。
    public var index: String
    /// 上游 mixin 提供的 `customStyle`。
    public var customStyle: UPStyle

    private let content: Content
    @State private var state: UPStickyState
    private var onFixedHandler: ((UPStickyChange) -> Void)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器。
    public init(offsetTop: any UPStickyUnitValue = UPConfig.sticky.offsetTop,
                customNavHeight: any UPStickyUnitValue = UPConfig.sticky.customNavHeight,
                disabled: Bool = UPConfig.sticky.disabled,
                bgColor: String = UPConfig.sticky.bgColor,
                zIndex: any UPStickyUnitValue = UPConfig.sticky.zIndex,
                index: any UPStickyUnitValue = UPConfig.sticky.index,
                customStyle: UPStyle = UPStyle(),
                @ViewBuilder content: () -> Content) {
        self.offsetTop = UPUnit.parse(offsetTop.upImageUnitValue)
        self.customNavHeight = UPUnit.parse(customNavHeight.upImageUnitValue)
        self.disabled = disabled
        self.bgColor = bgColor
        self.zIndex = zIndex.upImageUnitValue
        self.index = index.upImageUnitValue
        self.customStyle = customStyle
        self.content = content()
        self._state = State(initialValue: UPStickyState())
    }

    // MARK: - 解析后的呈现值

    /// 上游 `getStickyTop()`：`getPx(offsetTop) + getPx(customNavHeight)`。
    public var stickyTop: CGFloat { offsetTop + customNavHeight }

    /// 仓库既有名。
    public var pinOffset: CGFloat { stickyTop }

    /// 上游 `uZindex`：`zIndex` 为假值（空串或 0）时回落 `zIndex.sticky`。
    public var resolvedZIndex: Double {
        let parsed = UPUnit.parse(zIndex)
        return parsed > 0 ? Double(parsed) : UPConfig.sticky.fallbackZIndex
    }

    /// 上游 `setFixed(top)`：`top <= stickyTop` 即进入吸顶。`disabled` 时恒不吸顶。
    public func isFixed(minY: CGFloat) -> Bool {
        !disabled && minY <= stickyTop
    }

    /// 上游 `data.fixed`。
    public var fixed: Bool { state.fixed }

    /// 上游 js 模式回填给父元素的高度，用来防止塌陷；未吸顶时上游给的是 `auto`。
    public var placeholderHeight: CGFloat? {
        state.fixed ? state.contentHeight : nil
    }

    /// 上游 `stickyContent` 在 js 模式下记录的宽度，`auto` 时不写死。
    public var contentWidth: CGFloat? {
        state.contentWidth > 0 ? state.contentWidth : nil
    }

    // MARK: - 上游 methods

    /// 上游 `setFixed(top)`：只改标记，不抛事件。原生额外抛出仓库既有的 `onFixed`。
    public func setFixed(top: CGFloat) {
        let next = isFixed(minY: top)
        guard next != state.fixed else { return }
        state.fixed = next
        onFixedHandler?(UPStickyChange(index: index, isFixed: next))
    }

    /// 仓库既有方法：外部滚动监听把当前 minY 灌进来。
    public func report(minY: CGFloat) {
        let next = isFixed(minY: minY)
        state.fixed = next
        onFixedHandler?(UPStickyChange(index: index, isFixed: next))
    }

    /// 上游 `initObserveContent()` 量到的内容尺寸。
    public func recordContentSize(_ size: CGSize, left: CGFloat = 0) {
        state.contentHeight = size.height
        state.contentWidth = size.width
        state.contentLeft = left
    }

    /// 仓库既有事件。
    public func onFixed(_ action: @escaping (UPStickyChange) -> Void) -> Self {
        var copy = self
        copy.onFixedHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        content
            .background(UPColor.parse(bgColor, theme: theme))
            .background(sizeProbe)
            .upStyle(customStyle)
            .zIndex(resolvedZIndex)
    }

    /// 上游 `$uGetRect('#' + elId)` 量内容尺寸，原生用 GeometryReader。
    private var sizeProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    recordContentSize(proxy.size, left: proxy.frame(in: .global).minX)
                }
                .onChange(of: proxy.size) { _, value in
                    recordContentSize(value, left: proxy.frame(in: .global).minX)
                }
        }
    }
}

public extension UPSticky where Content == EmptyView {
    init(offsetTop: any UPStickyUnitValue = UPConfig.sticky.offsetTop,
         customNavHeight: any UPStickyUnitValue = UPConfig.sticky.customNavHeight,
         disabled: Bool = UPConfig.sticky.disabled,
         bgColor: String = UPConfig.sticky.bgColor,
         zIndex: any UPStickyUnitValue = UPConfig.sticky.zIndex,
         index: any UPStickyUnitValue = UPConfig.sticky.index,
         customStyle: UPStyle = UPStyle()) {
        self.init(offsetTop: offsetTop,
                  customNavHeight: customNavHeight,
                  disabled: disabled,
                  bgColor: bgColor,
                  zIndex: zIndex,
                  index: index,
                  customStyle: customStyle,
                  content: EmptyView.init)
    }
}
