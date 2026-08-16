import SwiftUI

public struct UPPopup<Content: View>: View {
    @Binding var show: Bool
    var overlay: Bool
    var mode: String
    var duration: Double
    var closeable: Bool
    var closeOnClickOverlay: Bool
    var zIndex: Double
    var safeAreaInsetBottom: Bool
    var safeAreaInsetTop: Bool
    var closeIconPos: String
    var round: String
    var zoom: Bool
    var bgColor: String
    var overlayOpacity: Double
    var onClose: (() -> Void)?
    var onOpen: (() -> Void)?
    var onClickOverlay: (() -> Void)?
    @ViewBuilder var content: () -> Content

    public init(show: Binding<Bool>,
                overlay: Bool = UPConfig.popup.overlay,
                mode: String = UPConfig.popup.mode,
                duration: Double = UPConfig.popup.duration,
                closeable: Bool = UPConfig.popup.closeable,
                closeOnClickOverlay: Bool = UPConfig.popup.closeOnClickOverlay,
                zIndex: Double = UPConfig.popup.zIndex,
                safeAreaInsetBottom: Bool = UPConfig.popup.safeAreaInsetBottom,
                safeAreaInsetTop: Bool = UPConfig.popup.safeAreaInsetTop,
                closeIconPos: String = UPConfig.popup.closeIconPos,
                round: String = UPConfig.popup.round,
                zoom: Bool = UPConfig.popup.zoom,
                bgColor: String = UPConfig.popup.bgColor,
                overlayOpacity: Double = UPConfig.popup.overlayOpacity,
                onClose: (() -> Void)? = nil,
                onOpen: (() -> Void)? = nil,
                onClickOverlay: (() -> Void)? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self._show = show
        self.overlay = overlay
        self.mode = mode
        self.duration = duration
        self.closeable = closeable
        self.closeOnClickOverlay = closeOnClickOverlay
        self.zIndex = zIndex
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.safeAreaInsetTop = safeAreaInsetTop
        self.closeIconPos = closeIconPos
        self.round = round
        self.zoom = zoom
        self.bgColor = bgColor
        self.overlayOpacity = overlayOpacity
        self.onClose = onClose
        self.onOpen = onOpen
        self.onClickOverlay = onClickOverlay
        self.content = content
    }

    @Environment(\.upTheme) private var theme

    public static func shouldRenderOverlay(show: Bool, overlay: Bool) -> Bool {
        show && overlay
    }

    public var body: some View {
        ZStack {
            if Self.shouldRenderOverlay(show: show, overlay: overlay) {
                UPOverlay(show: true, zIndex: zIndex - 1, duration: duration, opacity: overlayOpacity) {
                    if closeOnClickOverlay {
                        show = false
                    }
                    onClickOverlay?()
                }
            }
            if show {
                panel
                    .transition(transition)
                    .zIndex(zIndex)
            }
        }
        .animation(.easeInOut(duration: duration / 1000), value: show)
        .onChange(of: show) { _, newValue in
            if newValue { onOpen?() } else { onClose?() }
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
                VStack { panelContent; Spacer(minLength: 0) }
            case "bottom":
                VStack { Spacer(minLength: 0); panelContent }
            case "left":
                HStack { panelContent; Spacer(minLength: 0) }
            case "right":
                HStack { Spacer(minLength: 0); panelContent }
            default:
                ZStack { panelContent }
            }
        }
        .ignoresSafeArea(edges: mode == "top" ? .top : (mode == "bottom" ? .bottom : []))
    }

    private var panelContent: some View {
        content()
            .frame(maxWidth: mode == "center" ? nil : .infinity)
            .background(bgColor.isEmpty ? Color.white : UPColor.parse(bgColor, theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: UPUnit.parse(round)))
            .overlay(alignment: closeIconAlignment) {
                if closeable {
                    Button {
                        show = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.tips)
                            .padding(8)
                            .background(Circle().fill(theme.bg))
                    }
                    .padding(8)
                }
            }
    }

    private var closeIconAlignment: Alignment {
        switch closeIconPos {
        case "top-left": return .topLeading
        case "bottom-left": return .bottomLeading
        case "bottom-right": return .bottomTrailing
        default: return .topTrailing
        }
    }
}

public extension UPPopup {
    func onClose(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onClose = action; return c }
    func onOpen(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onOpen = action; return c }
    func onClickOverlay(_ action: @escaping () -> Void) -> UPPopup { var c = self; c.onClickOverlay = action; return c }
}
