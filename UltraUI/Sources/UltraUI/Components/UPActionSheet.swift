import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-action-sheet`.
@MainActor
public struct UPActionSheet: View {
    var show: Binding<Bool>
    var title: String
    var description: String
    var actions: [UPActionSheetAction]
    var nameKey: String
    var subnameKey: String
    var cancelText: String
    var closeOnClickAction: Bool
    var safeAreaInsetBottom: Bool
    var openType: String
    var closeOnClickOverlay: Bool
    var round: String
    var wrapMaxHeight: String
    var onSelectHandler: ((UPActionSheetAction) -> Void)?
    var onCloseHandler: (() -> Void)?
    var customContent: AnyView?

    @Environment(\.upTheme) private var theme

    public init(
        show: Binding<Bool>,
        title: String = UPConfig.actionSheet.title,
        description: String = UPConfig.actionSheet.description,
        actions: [UPActionSheetAction] = UPConfig.actionSheet.actions,
        nameKey: String = UPConfig.actionSheet.nameKey,
        subnameKey: String = UPConfig.actionSheet.subnameKey,
        cancelText: String = UPConfig.actionSheet.cancelText,
        closeOnClickAction: Bool = UPConfig.actionSheet.closeOnClickAction,
        safeAreaInsetBottom: Bool = UPConfig.actionSheet.safeAreaInsetBottom,
        openType: String = UPConfig.actionSheet.openType,
        closeOnClickOverlay: Bool = UPConfig.actionSheet.closeOnClickOverlay,
        round: some UPActionSheetUnitValue = UPConfig.actionSheet.round,
        wrapMaxHeight: some UPActionSheetUnitValue = UPConfig.actionSheet.wrapMaxHeight,
        onSelect: ((UPActionSheetAction) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.show = show
        self.title = title
        self.description = description
        self.actions = actions
        self.nameKey = nameKey
        self.subnameKey = subnameKey
        self.cancelText = cancelText
        self.closeOnClickAction = closeOnClickAction
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.openType = openType
        self.closeOnClickOverlay = closeOnClickOverlay
        self.round = round.upCheckboxUnitValue
        self.wrapMaxHeight = wrapMaxHeight.upCheckboxUnitValue
        self.onSelectHandler = onSelect
        self.onCloseHandler = onClose
        self.customContent = nil
    }

    public init<Content: View>(
        show: Binding<Bool>,
        title: String = UPConfig.actionSheet.title,
        description: String = UPConfig.actionSheet.description,
        actions: [UPActionSheetAction] = UPConfig.actionSheet.actions,
        nameKey: String = UPConfig.actionSheet.nameKey,
        subnameKey: String = UPConfig.actionSheet.subnameKey,
        cancelText: String = UPConfig.actionSheet.cancelText,
        closeOnClickAction: Bool = UPConfig.actionSheet.closeOnClickAction,
        safeAreaInsetBottom: Bool = UPConfig.actionSheet.safeAreaInsetBottom,
        openType: String = UPConfig.actionSheet.openType,
        closeOnClickOverlay: Bool = UPConfig.actionSheet.closeOnClickOverlay,
        round: some UPActionSheetUnitValue = UPConfig.actionSheet.round,
        wrapMaxHeight: some UPActionSheetUnitValue = UPConfig.actionSheet.wrapMaxHeight,
        onSelect: ((UPActionSheetAction) -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.show = show
        self.title = title
        self.description = description
        self.actions = actions
        self.nameKey = nameKey
        self.subnameKey = subnameKey
        self.cancelText = cancelText
        self.closeOnClickAction = closeOnClickAction
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.openType = openType
        self.closeOnClickOverlay = closeOnClickOverlay
        self.round = round.upCheckboxUnitValue
        self.wrapMaxHeight = wrapMaxHeight.upCheckboxUnitValue
        self.onSelectHandler = onSelect
        self.onCloseHandler = onClose
        self.customContent = AnyView(content())
    }

    var resolvedRound: CGFloat {
        Self.parseDimension(round, fallback: 0)
    }

    var resolvedWrapMaxHeight: CGFloat {
        Self.parseDimension(wrapMaxHeight, fallback: Self.parseDimension(UPConfig.actionSheet.wrapMaxHeight, fallback: 600))
    }

    var hasCustomContent: Bool {
        customContent != nil
    }

    var shouldRenderDefaultActions: Bool {
        customContent == nil
    }

    func displayName(for action: UPActionSheetAction) -> String {
        action.value(for: nameKey) ?? action.name
    }

    public var body: some View {
        UPPopup(
            show: show,
            mode: "bottom",
            closeOnClickOverlay: false,
            safeAreaInsetBottom: false,
            round: "\(resolvedRound)px",
            onClickOverlay: {
                Self.performOverlayTap(
                    show: show,
                    closeOnClickOverlay: closeOnClickOverlay,
                    onClose: onCloseHandler
                )
            }
        ) {
            sheetContent
        }
    }

    private var sheetContent: some View {
        VStack(spacing: 0) {
            if !title.isEmpty {
                titleHeader
            }

            if !description.isEmpty {
                descriptionView
            }

            if let customContent {
                customContent
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Self.performContentTap(
                            show: show,
                            closeOnClickAction: closeOnClickAction,
                            onClose: onCloseHandler
                        )
                    }
            } else {
                actionList
            }

            if !cancelText.isEmpty {
                cancelSection
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .safeAreaPadding(.bottom, safeAreaInsetBottom ? nil : 0)
    }

    private var titleHeader: some View {
        ZStack(alignment: .trailing) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.main)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 48)

            Button {
                Self.performClose(show: show, onClose: onCloseHandler)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.tips)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
        }
        .frame(minHeight: 48)
    }

    private var descriptionView: some View {
        Text(description)
            .font(.system(size: 13))
            .foregroundStyle(theme.tips)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, title.isEmpty ? 18 : 0)
            .padding(.bottom, 12)
    }

    private var actionList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    actionRow(action)

                    if index < actions.count - 1 {
                        Divider().background(theme.border)
                    }
                }
            }
        }
        .frame(maxHeight: resolvedWrapMaxHeight)
    }

    private var cancelSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.bg)
                .frame(height: 6)

            Button {
                Self.performClose(show: show, onClose: onCloseHandler)
            } label: {
                Text(cancelText)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.main)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionRow(_ action: UPActionSheetAction) -> some View {
        Button {
            Self.performSelection(
                action,
                show: show,
                closeOnClickAction: closeOnClickAction,
                onSelect: onSelectHandler,
                onClose: onCloseHandler
            )
        } label: {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                if action.loading {
                    ProgressView()
                        .controlSize(.small)
                }

                VStack(spacing: 4) {
                    Text(displayName(for: action))
                        .font(.system(size: action.resolvedFontSize ?? 16))
                        .foregroundStyle(actionForegroundColor(action))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    if let subname = action.value(for: subnameKey), !subname.isEmpty {
                        Text(subname)
                            .font(.system(size: 12))
                            .foregroundStyle(action.disabled || action.loading ? theme.disabled : theme.tips)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action.disabled || action.loading)
    }

    private func actionForegroundColor(_ action: UPActionSheetAction) -> Color {
        if action.disabled || action.loading { return theme.disabled }
        if !action.color.isEmpty { return UPColor.parse(action.color, theme: theme) }
        return theme.main
    }

    nonisolated static func parseDimension(_ value: String, fallback: CGFloat) -> CGFloat {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty, !raw.hasSuffix("%") else { return fallback }

        let parsed: Double?
        if raw.hasSuffix("rpx") {
            parsed = Double(raw.dropLast(3))
        } else if raw.hasSuffix("px") {
            parsed = Double(raw.dropLast(2))
        } else {
            parsed = Double(raw)
        }

        guard let parsed, parsed.isFinite, parsed >= 0 else { return fallback }
        return raw.hasSuffix("rpx") ? UPUnit.rpx(CGFloat(parsed)) : CGFloat(parsed)
    }

    nonisolated static func performSelection(
        _ action: UPActionSheetAction,
        show: Binding<Bool>,
        closeOnClickAction: Bool,
        onSelect: ((UPActionSheetAction) -> Void)?,
        onClose: (() -> Void)?
    ) {
        guard !action.disabled, !action.loading else { return }
        onSelect?(action)
        if closeOnClickAction {
            show.wrappedValue = false
            onClose?()
        }
    }

    nonisolated static func performClose(
        show: Binding<Bool>,
        onClose: (() -> Void)?
    ) {
        show.wrappedValue = false
        onClose?()
    }

    nonisolated static func performOverlayTap(
        show: Binding<Bool>,
        closeOnClickOverlay: Bool,
        onClose: (() -> Void)?
    ) {
        guard closeOnClickOverlay else { return }
        performClose(show: show, onClose: onClose)
    }

    nonisolated static func performContentTap(
        show: Binding<Bool>,
        closeOnClickAction: Bool,
        onClose: (() -> Void)?
    ) {
        guard closeOnClickAction else { return }
        performClose(show: show, onClose: onClose)
    }
}

public extension UPActionSheet {
    func onSelect(_ action: @escaping (UPActionSheetAction) -> Void) -> UPActionSheet {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    func onClose(_ action: @escaping () -> Void) -> UPActionSheet {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }
}
