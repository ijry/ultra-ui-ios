import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-popup`.
public struct UPPopup<Content: View>: View {
    @Binding var show: Bool
    var overlay: Bool
    var mode: String
    var duration: Double
    var closeable: Bool
    var overlayStyle: UPStyle
    var closeOnClickOverlay: Bool
    var zIndex: Double
    var safeAreaInsetBottom: Bool
    var safeAreaInsetTop: Bool
    var closeIconPos: String
    var round: String
    var zoom: Bool
    var bgColor: String
    var overlayOpacity: Double
    var pageInline: Bool
    var touchable: Bool
    var minHeight: String
    var maxHeight: String
    var onClose: (() -> Void)?
    var onOpen: (() -> Void)?
    var onClickOverlay: (() -> Void)?
    var onClick: (() -> Void)?
    private var bottomContent: AnyView?
    @ViewBuilder var content: () -> Content

    public init(show: Binding<Bool>,
                overlay: Bool = UPConfig.popup.overlay,
                mode: String = UPConfig.popup.mode,
                duration: Double = UPConfig.popup.duration,
                closeable: Bool = UPConfig.popup.closeable,
                overlayStyle: UPStyle = UPConfig.popup.overlayStyle,
                closeOnClickOverlay: Bool = UPConfig.popup.closeOnClickOverlay,
                zIndex: Double = UPConfig.popup.zIndex,
                safeAreaInsetBottom: Bool = UPConfig.popup.safeAreaInsetBottom,
                safeAreaInsetTop: Bool = UPConfig.popup.safeAreaInsetTop,
                closeIconPos: String = UPConfig.popup.closeIconPos,
                round: String = UPConfig.popup.round,
                zoom: Bool = UPConfig.popup.zoom,
                bgColor: String = UPConfig.popup.bgColor,
                overlayOpacity: Double = UPConfig.popup.overlayOpacity,
                pageInline: Bool = UPConfig.popup.pageInline,
                touchable: Bool = UPConfig.popup.touchable,
                minHeight: String = UPConfig.popup.minHeight,
                maxHeight: String = UPConfig.popup.maxHeight,
                onClose: (() -> Void)? = nil,
                onOpen: (() -> Void)? = nil,
                onClickOverlay: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self._show = show
        self.overlay = overlay
        self.mode = Self.resolvedMode(mode)
        self.duration = duration
        self.closeable = closeable
        self.overlayStyle = overlayStyle
        self.closeOnClickOverlay = closeOnClickOverlay
        self.zIndex = zIndex
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.safeAreaInsetTop = safeAreaInsetTop
        self.closeIconPos = closeIconPos
        self.round = round
        self.zoom = zoom
        self.bgColor = bgColor
        self.overlayOpacity = overlayOpacity
        self.pageInline = pageInline
        self.touchable = touchable
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.onClose = onClose
        self.onOpen = onOpen
        self.onClickOverlay = onClickOverlay
        self.onClick = onClick
        self.bottomContent = nil
        self.content = content
    }

    @Environment(\.upTheme) private var theme

    var hasBottomSlot: Bool { bottomContent != nil }

    /// Preserves the original convenience while treating non-inline content
    /// as the normal popup presentation mode.
    public static func shouldRenderOverlay(show: Bool, overlay: Bool) -> Bool {
        shouldRenderOverlay(show: show, overlay: overlay, pageInline: false)
    }

    /// uview-plus renders its overlay only for non-inline popups.
    public static func shouldRenderOverlay(show: Bool,
                                           overlay: Bool,
                                           pageInline: Bool) -> Bool {
        show && overlay && !pageInline
    }

    static func resolvedMode(_ mode: String) -> String {
        switch mode {
        case "top", "bottom", "left", "right", "center": return mode
        default: return "bottom"
        }
    }

    public var body: some View {
        ZStack {
            if Self.shouldRenderOverlay(show: show, overlay: overlay, pageInline: pageInline) {
                UPOverlay(
                    show: true,
                    zIndex: zIndex - 1,
                    duration: duration,
                    opacity: overlayOpacity,
                    onClick: handleOverlayClick
                )
                .upStyle(overlayStyle)
            }
            if show {
                panel
                    .transition(transition)
                    .zIndex(zIndex)
            }
        }
        .animation(.easeInOut(duration: max(0, duration) / 1_000), value: show)
        .onChange(of: show) { _, newValue in
            if newValue { onOpen?() }
        }
    }

    private var transition: AnyTransition {
        switch mode {
        case "top": return .move(edge: .top)
        case "bottom": return .move(edge: .bottom)
        case "left": return .move(edge: .leading)
        case "right": return .move(edge: .trailing)
        default: return zoom ? .scale(scale: 0.8).combined(with: .opacity) : .opacity
        }
    }

    private var panel: some View {
        Group {
            switch mode {
            case "top":
                VStack { panelWithBottomSlot; Spacer(minLength: 0) }
            case "bottom":
                VStack { Spacer(minLength: 0); panelWithBottomSlot }
            case "left":
                HStack { panelWithBottomSlot; Spacer(minLength: 0) }
            case "right":
                HStack { Spacer(minLength: 0); panelWithBottomSlot }
            default:
                ZStack { panelWithBottomSlot }
            }
        }
        .modifier(PopupSafeAreaModifier(
            pageInline: pageInline,
            mode: mode,
            safeAreaInsetTop: safeAreaInsetTop,
            safeAreaInsetBottom: safeAreaInsetBottom
        ))
    }

    @ViewBuilder
    private var panelWithBottomSlot: some View {
        VStack(spacing: 0) {
            panelContent
            if let bottomContent {
                bottomContent
            }
        }
    }

    private var panelContent: some View {
        content()
            .frame(maxWidth: mode == "center" ? nil : .infinity)
            .frame(minHeight: resolvedHeight(minHeight), maxHeight: resolvedHeight(maxHeight))
            .background(bgColor.isEmpty ? Color.white : UPColor.parse(bgColor, theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius))
            .overlay(alignment: closeIconAlignment) {
                if closeable {
                    Button {
                        Self.applyClose(show: $show, onClose: onClose)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.tips)
                            .padding(8)
                            .background(Circle().fill(theme.bg))
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
    }

    private var resolvedCornerRadius: CGFloat {
        if round == "true" { return 20 }
        if round == "false" { return 0 }
        return UPUnit.parse(round)
    }

    private var closeIconAlignment: Alignment {
        switch closeIconPos {
        case "top-left": return .topLeading
        case "bottom-left": return .bottomLeading
        case "bottom-right": return .bottomTrailing
        default: return .topTrailing
        }
    }

    private func resolvedHeight(_ raw: String) -> CGFloat? {
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let value = UPUnit.parse(raw)
        return value > 0 ? value : nil
    }

    /// Executes the observable result of an overlay tap. Kept separate from the
    /// view gesture so SwiftUI consumers and tests share the same event order.
    /// Applies the upstream `close()` method: update `show` first, then emit
    /// the close event. External Binding changes intentionally do not emit it.
    static func applyClose(show: Binding<Bool>, onClose: (() -> Void)?) {
        show.wrappedValue = false
        onClose?()
    }

    static func applyOverlayClick(show: Binding<Bool>,
                                  mode: String,
                                  closeOnClickOverlay: Bool,
                                  onClickOverlay: (() -> Void)?,
                                  onClick: (() -> Void)?,
                                  onClose: (() -> Void)? = nil) {
        if closeOnClickOverlay {
            applyClose(show: show, onClose: onClose)
        }
        onClickOverlay?()
        if resolvedMode(mode) == "center" {
            onClick?()
        }
    }

    private func handleOverlayClick() {
        Self.applyOverlayClick(
            show: $show,
            mode: mode,
            closeOnClickOverlay: closeOnClickOverlay,
            onClickOverlay: onClickOverlay,
            onClick: onClick,
            onClose: onClose
        )
    }
}

public extension UPPopup {
    /// Maps uview-plus' named `bottom` slot to a native SwiftUI view builder.
    func bottom<Bottom: View>(@ViewBuilder _ content: () -> Bottom) -> UPPopup {
        var copy = self
        copy.bottomContent = AnyView(content())
        return copy
    }

    func settingBottomContent(_ content: AnyView?) -> UPPopup {
        var copy = self
        copy.bottomContent = content
        return copy
    }
}

private struct PopupSafeAreaModifier: ViewModifier {
    let pageInline: Bool
    let mode: String
    let safeAreaInsetTop: Bool
    let safeAreaInsetBottom: Bool

    func body(content: Content) -> some View {
        if pageInline {
            content
        } else {
            content
                .ignoresSafeArea(edges: ignoredEdges)
        }
    }

    private var ignoredEdges: Edge.Set {
        var edges: Edge.Set = []
        if mode == "top" && !safeAreaInsetTop { edges.insert(.top) }
        if mode == "bottom" && !safeAreaInsetBottom { edges.insert(.bottom) }
        if mode == "left" || mode == "right" || mode == "center" { edges = .all }
        return edges
    }
}

public extension UPPopup {
    func onClose(_ action: @escaping () -> Void) -> UPPopup {
        var copy = self
        copy.onClose = action
        return copy
    }

    func onOpen(_ action: @escaping () -> Void) -> UPPopup {
        var copy = self
        copy.onOpen = action
        return copy
    }

    func onClickOverlay(_ action: @escaping () -> Void) -> UPPopup {
        var copy = self
        copy.onClickOverlay = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPPopup {
        var copy = self
        copy.onClick = action
        return copy
    }
}
