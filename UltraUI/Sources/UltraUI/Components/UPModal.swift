import SwiftUI

public struct UPModal<CustomContent: View>: View {
    @Binding var show: Bool
    var title: String
    var content: String
    var confirmText: String
    var cancelText: String
    var showConfirmButton: Bool
    var showCancelButton: Bool
    var confirmColor: String
    var cancelColor: String
    var buttonReverse: Bool
    var zoom: Bool
    var asyncClose: Bool
    var closeOnClickOverlay: Bool
    var negativeTop: Double
    var width: String
    var confirmButtonShape: String
    var duration: Double
    var contentTextAlign: String
    var asyncCloseTip: String
    var asyncCancelClose: Bool
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    var onClose: (() -> Void)?
    var onCancelOnAsync: (() -> Void)?
    private var hasCustomContent: Bool
    private var customContent: CustomContent

    @Environment(\.upTheme) private var theme
    @State private var loading = false

    public init(show: Binding<Bool>,
                title: String = UPConfig.modal.title,
                content: String = UPConfig.modal.content,
                confirmText: String = UPConfig.modal.confirmText,
                cancelText: String = UPConfig.modal.cancelText,
                showConfirmButton: Bool = UPConfig.modal.showConfirmButton,
                showCancelButton: Bool = UPConfig.modal.showCancelButton,
                confirmColor: String = UPConfig.modal.confirmColor,
                cancelColor: String = UPConfig.modal.cancelColor,
                buttonReverse: Bool = UPConfig.modal.buttonReverse,
                zoom: Bool = UPConfig.modal.zoom,
                asyncClose: Bool = UPConfig.modal.asyncClose,
                closeOnClickOverlay: Bool = UPConfig.modal.closeOnClickOverlay,
                negativeTop: Double = UPConfig.modal.negativeTop,
                width: String = UPConfig.modal.width,
                confirmButtonShape: String = UPConfig.modal.confirmButtonShape,
                duration: Double = UPConfig.modal.duration,
                contentTextAlign: String = UPConfig.modal.contentTextAlign,
                asyncCloseTip: String = UPConfig.modal.asyncCloseTip,
                asyncCancelClose: Bool = UPConfig.modal.asyncCancelClose,
                onConfirm: (() -> Void)? = nil,
                onCancel: (() -> Void)? = nil,
                onClose: (() -> Void)? = nil,
                onCancelOnAsync: (() -> Void)? = nil,
                @ViewBuilder customContent: () -> CustomContent) {
        self._show = show
        self.title = title
        self.content = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.showConfirmButton = showConfirmButton
        self.showCancelButton = showCancelButton
        self.confirmColor = confirmColor
        self.cancelColor = cancelColor
        self.buttonReverse = buttonReverse
        self.zoom = zoom
        self.asyncClose = asyncClose
        self.closeOnClickOverlay = closeOnClickOverlay
        self.negativeTop = negativeTop
        self.width = width
        self.confirmButtonShape = confirmButtonShape
        self.duration = duration
        self.contentTextAlign = contentTextAlign
        self.asyncCloseTip = asyncCloseTip
        self.asyncCancelClose = asyncCancelClose
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.onClose = onClose
        self.onCancelOnAsync = onCancelOnAsync
        self.hasCustomContent = true
        self.customContent = customContent()
    }

    public var body: some View {
        UPPopup(show: $show,
                mode: "center",
                duration: duration,
                closeOnClickOverlay: closeOnClickOverlay,
                safeAreaInsetBottom: false,
                round: "6px",
                zoom: zoom,
                onClose: onClose) {
            VStack(spacing: 0) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.main)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 25)
                        .padding(.bottom, 12)
                }

                contentArea

                if showConfirmButton || showCancelButton {
                    UPLine(color: theme.border.upHexString, direction: "row")
                    buttonGroup
                }
            }
            .frame(width: UPUnit.parse(width))
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, -negativeTop)
        }
        .onChange(of: show) { _, newValue in
            if newValue && loading { loading = false }
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if hasCustomContent {
            customContent
                .padding(.horizontal, 25)
                .padding(.top, title.isEmpty ? 25 : 0)
                .padding(.bottom, 25)
        } else if !content.isEmpty || title.isEmpty {
            Text(content)
                .font(.system(size: 15))
                .foregroundStyle(theme.content)
                .multilineTextAlignment(textAlignment)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .padding(.horizontal, 25)
                .padding(.top, title.isEmpty ? 25 : 0)
                .padding(.bottom, 25)
        }
    }

    private var buttonGroup: some View {
        HStack(spacing: 0) {
            if buttonReverse {
                if showConfirmButton { confirmButton }
                if showConfirmButton && showCancelButton { divider }
                if showCancelButton { cancelButton }
            } else {
                if showCancelButton { cancelButton }
                if showConfirmButton && showCancelButton { divider }
                if showConfirmButton { confirmButton }
            }
        }
        .frame(height: 48)
    }

    private var divider: some View {
        UPLine(color: theme.border.upHexString, direction: "col")
            .frame(height: 48)
    }

    private var confirmButton: some View {
        Button {
            if asyncClose {
                loading = true
            } else {
                show = false
            }
            onConfirm?()
        } label: {
            Group {
                if loading {
                    UPLoadingIcon(show: true, color: confirmColor, mode: "spinner", size: 18)
                } else {
                    Text(confirmText)
                        .font(.system(size: 16))
                        .foregroundStyle(UPColor.parse(confirmColor, theme: theme))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button {
            if asyncClose && loading {
                if !asyncCloseTip.isEmpty {
                    UPToast.show(message: asyncCloseTip, type: "default", position: "center")
                }
                onCancelOnAsync?()
            } else {
                if !asyncCancelClose { show = false }
                onCancel?()
            }
        } label: {
            Text(cancelText)
                .font(.system(size: 16))
                .foregroundStyle(UPColor.parse(cancelColor, theme: theme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var textAlignment: TextAlignment {
        switch contentTextAlign {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    private var frameAlignment: Alignment {
        switch contentTextAlign {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }
}

public extension UPModal where CustomContent == EmptyView {
    init(show: Binding<Bool>,
         title: String = UPConfig.modal.title,
         content: String = UPConfig.modal.content,
         confirmText: String = UPConfig.modal.confirmText,
         cancelText: String = UPConfig.modal.cancelText,
         showConfirmButton: Bool = UPConfig.modal.showConfirmButton,
         showCancelButton: Bool = UPConfig.modal.showCancelButton,
         confirmColor: String = UPConfig.modal.confirmColor,
         cancelColor: String = UPConfig.modal.cancelColor,
         buttonReverse: Bool = UPConfig.modal.buttonReverse,
         zoom: Bool = UPConfig.modal.zoom,
         asyncClose: Bool = UPConfig.modal.asyncClose,
         closeOnClickOverlay: Bool = UPConfig.modal.closeOnClickOverlay,
         negativeTop: Double = UPConfig.modal.negativeTop,
         width: String = UPConfig.modal.width,
         confirmButtonShape: String = UPConfig.modal.confirmButtonShape,
         duration: Double = UPConfig.modal.duration,
         contentTextAlign: String = UPConfig.modal.contentTextAlign,
         asyncCloseTip: String = UPConfig.modal.asyncCloseTip,
         asyncCancelClose: Bool = UPConfig.modal.asyncCancelClose,
         onConfirm: (() -> Void)? = nil,
         onCancel: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         onCancelOnAsync: (() -> Void)? = nil) {
        self._show = show
        self.title = title
        self.content = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.showConfirmButton = showConfirmButton
        self.showCancelButton = showCancelButton
        self.confirmColor = confirmColor
        self.cancelColor = cancelColor
        self.buttonReverse = buttonReverse
        self.zoom = zoom
        self.asyncClose = asyncClose
        self.closeOnClickOverlay = closeOnClickOverlay
        self.negativeTop = negativeTop
        self.width = width
        self.confirmButtonShape = confirmButtonShape
        self.duration = duration
        self.contentTextAlign = contentTextAlign
        self.asyncCloseTip = asyncCloseTip
        self.asyncCancelClose = asyncCancelClose
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.onClose = onClose
        self.onCancelOnAsync = onCancelOnAsync
        self.hasCustomContent = false
        self.customContent = EmptyView()
    }
}

public extension UPModal {
    func onConfirm(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onConfirm = action; return c }
    func onCancel(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onCancel = action; return c }
    func onClose(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onClose = action; return c }
    func onCancelOnAsync(_ action: @escaping () -> Void) -> UPModal { var c = self; c.onCancelOnAsync = action; return c }
}
