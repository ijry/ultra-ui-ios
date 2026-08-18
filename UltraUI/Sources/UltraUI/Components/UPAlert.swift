import SwiftUI

/// Semantic alias for the `String | Number` `fontSize` prop accepted by
/// uview-plus `u-alert`.
public typealias UPAlertUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-alert`.
///
/// The public prop names mirror the upstream component. `modelValue` is the
/// preferred two-way binding label; `show` is provided as a SwiftUI-friendly
/// compatibility alias. When no binding is supplied, the component owns a
/// local visible state initialized from `UPConfig.alert.value`.
@MainActor
public struct UPAlert: View {
    private var externalModelValue: Binding<Bool>?
    @State private var localShow: Bool
    @State private var suppressNextModelValueChange = false

    var title: String
    var type: String
    var description: String
    var closable: Bool
    var showIcon: Bool
    var effect: String
    var center: Bool
    var fontSize: Double
    var transitionMode: String
    var duration: Double
    var icon: String
    var customClass: String
    var customStyle: UPStyle

    var onClickHandler: (() -> Void)?
    var onCloseHandler: (() -> Void)?
    var onClosedHandler: (() -> Void)?
    var onUpdateModelValueHandler: ((Bool) -> Void)?
    var customCloseContent: AnyView?

    @Environment(\.upTheme) private var theme

    /// The current two-way binding. For an unbound alert this points at its
    /// local SwiftUI state, so the close button and auto-dismiss still work.
    var modelValue: Binding<Bool> {
        externalModelValue ?? $localShow
    }

    /// The current visible value used by the native renderer.
    var show: Bool {
        modelValue.wrappedValue
    }

    public init(
        modelValue: Binding<Bool>? = nil,
        title: String = UPConfig.alert.title,
        type: String = UPConfig.alert.type,
        description: String = UPConfig.alert.description,
        closable: Bool = UPConfig.alert.closable,
        showIcon: Bool = UPConfig.alert.showIcon,
        effect: String = UPConfig.alert.effect,
        center: Bool = UPConfig.alert.center,
        fontSize: some UPAlertUnitValue = UPConfig.alert.fontSize,
        transitionMode: String = UPConfig.alert.transitionMode,
        duration: Double = UPConfig.alert.duration,
        icon: String = UPConfig.alert.icon,
        customClass: String = UPConfig.alert.customClass,
        customStyle: UPStyle = UPConfig.alert.customStyle,
        onClick: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onClosed: (() -> Void)? = nil,
        onUpdateModelValue: ((Bool) -> Void)? = nil
    ) {
        self.externalModelValue = modelValue
        self._localShow = State(initialValue: modelValue?.wrappedValue ?? UPConfig.alert.value)
        self.title = title
        self.type = type
        self.description = description
        self.closable = closable
        self.showIcon = showIcon
        self.effect = effect
        self.center = center
        self.fontSize = Self.normalizedFontSize(fontSize.upCheckboxUnitValue)
        self.transitionMode = transitionMode
        self.duration = duration
        self.icon = icon
        self.customClass = customClass
        self.customStyle = customStyle
        self.onClickHandler = onClick
        self.onCloseHandler = onClose
        self.onClosedHandler = onClosed
        self.onUpdateModelValueHandler = onUpdateModelValue
        self.customCloseContent = nil
    }

    /// SwiftUI-friendly alias for the upstream `modelValue` binding.
    public init(
        show: Binding<Bool>,
        title: String = UPConfig.alert.title,
        type: String = UPConfig.alert.type,
        description: String = UPConfig.alert.description,
        closable: Bool = UPConfig.alert.closable,
        showIcon: Bool = UPConfig.alert.showIcon,
        effect: String = UPConfig.alert.effect,
        center: Bool = UPConfig.alert.center,
        fontSize: some UPAlertUnitValue = UPConfig.alert.fontSize,
        transitionMode: String = UPConfig.alert.transitionMode,
        duration: Double = UPConfig.alert.duration,
        icon: String = UPConfig.alert.icon,
        customClass: String = UPConfig.alert.customClass,
        customStyle: UPStyle = UPConfig.alert.customStyle,
        onClick: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onClosed: (() -> Void)? = nil,
        onUpdateModelValue: ((Bool) -> Void)? = nil
    ) {
        self.init(
            modelValue: show,
            title: title,
            type: type,
            description: description,
            closable: closable,
            showIcon: showIcon,
            effect: effect,
            center: center,
            fontSize: fontSize,
            transitionMode: transitionMode,
            duration: duration,
            icon: icon,
            customClass: customClass,
            customStyle: customStyle,
            onClick: onClick,
            onClose: onClose,
            onClosed: onClosed,
            onUpdateModelValue: onUpdateModelValue
        )
    }

    /// Slot-compatible initializer for the named `close` slot in uview-plus.
    public init<CloseContent: View>(
        modelValue: Binding<Bool>? = nil,
        title: String = UPConfig.alert.title,
        type: String = UPConfig.alert.type,
        description: String = UPConfig.alert.description,
        closable: Bool = UPConfig.alert.closable,
        showIcon: Bool = UPConfig.alert.showIcon,
        effect: String = UPConfig.alert.effect,
        center: Bool = UPConfig.alert.center,
        fontSize: some UPAlertUnitValue = UPConfig.alert.fontSize,
        transitionMode: String = UPConfig.alert.transitionMode,
        duration: Double = UPConfig.alert.duration,
        icon: String = UPConfig.alert.icon,
        customClass: String = UPConfig.alert.customClass,
        customStyle: UPStyle = UPConfig.alert.customStyle,
        onClick: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onClosed: (() -> Void)? = nil,
        onUpdateModelValue: ((Bool) -> Void)? = nil,
        @ViewBuilder close: () -> CloseContent
    ) {
        self.init(
            modelValue: modelValue,
            title: title,
            type: type,
            description: description,
            closable: closable,
            showIcon: showIcon,
            effect: effect,
            center: center,
            fontSize: fontSize,
            transitionMode: transitionMode,
            duration: duration,
            icon: icon,
            customClass: customClass,
            customStyle: customStyle,
            onClick: onClick,
            onClose: onClose,
            onClosed: onClosed,
            onUpdateModelValue: onUpdateModelValue
        )
        self.customCloseContent = AnyView(close())
    }

    /// SwiftUI-friendly `show` alias plus uview-plus `close` slot content.
    public init<CloseContent: View>(
        show: Binding<Bool>,
        title: String = UPConfig.alert.title,
        type: String = UPConfig.alert.type,
        description: String = UPConfig.alert.description,
        closable: Bool = UPConfig.alert.closable,
        showIcon: Bool = UPConfig.alert.showIcon,
        effect: String = UPConfig.alert.effect,
        center: Bool = UPConfig.alert.center,
        fontSize: some UPAlertUnitValue = UPConfig.alert.fontSize,
        transitionMode: String = UPConfig.alert.transitionMode,
        duration: Double = UPConfig.alert.duration,
        icon: String = UPConfig.alert.icon,
        customClass: String = UPConfig.alert.customClass,
        customStyle: UPStyle = UPConfig.alert.customStyle,
        onClick: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onClosed: (() -> Void)? = nil,
        onUpdateModelValue: ((Bool) -> Void)? = nil,
        @ViewBuilder close: () -> CloseContent
    ) {
        self.init(
            modelValue: show,
            title: title,
            type: type,
            description: description,
            closable: closable,
            showIcon: showIcon,
            effect: effect,
            center: center,
            fontSize: fontSize,
            transitionMode: transitionMode,
            duration: duration,
            icon: icon,
            customClass: customClass,
            customStyle: customStyle,
            onClick: onClick,
            onClose: onClose,
            onClosed: onClosed,
            onUpdateModelValue: onUpdateModelValue,
            close: close
        )
    }

    public var body: some View {
        Group {
            if Self.shouldRender(show: show) {
                alertContent
                    .transition(Self.transition(for: transitionMode))
            }
        }
        .animation(.easeOut(duration: Self.transitionAnimationDuration), value: show)
        .onChange(of: show) { oldValue, newValue in
            if suppressNextModelValueChange {
                suppressNextModelValueChange = false
                return
            }

            onUpdateModelValueHandler?(newValue)
            if oldValue && !newValue && duration > 0 {
                onClosedHandler?()
            }
        }
        .task(id: autoDismissTaskID) {
            await dismissAfterDurationIfNeeded()
        }
    }

    var iconName: String {
        Self.iconName(for: type, customIcon: icon)
    }

    var iconColorToken: String {
        Self.iconColorToken(type: type, effect: effect)
    }

    var backgroundColorToken: String {
        Self.backgroundColorToken(type: type, effect: effect)
    }

    var iconRenderColorToken: String {
        iconColorToken == "#fff" ? "#ffffff" : iconColorToken
    }

    var textColorToken: String {
        Self.textColorToken(type: type, effect: effect)
    }

    var resolvedFontSize: CGFloat {
        CGFloat(fontSize)
    }

    var hasCustomCloseContent: Bool {
        customCloseContent != nil
    }

    var shouldRenderCloseButton: Bool {
        closable
    }

    private var autoDismissTaskID: String {
        "\(show)-\(duration)"
    }

    private var alertContent: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 0) {
                if showIcon {
                    UPIcon(
                        name: iconName,
                        color: iconRenderColorToken,
                        size: "18px"
                    )
                    .padding(.trailing, 5)
                }

                VStack(alignment: center ? .center : .leading, spacing: 2) {
                    if !title.isEmpty {
                        Text(title)
                            .font(.system(size: resolvedFontSize, weight: .bold))
                            .foregroundStyle(resolvedTextColor)
                            .multilineTextAlignment(center ? .center : .leading)
                            .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
                    }
                    if !description.isEmpty {
                        Text(description)
                            .font(.system(size: resolvedFontSize))
                            .foregroundStyle(resolvedTextColor)
                            .multilineTextAlignment(center ? .center : .leading)
                            .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
                .padding(.trailing, closable ? 20 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Self.performClick(onClickHandler)
            }

            if closable {
                Button(action: close) {
                    if let customCloseContent {
                        customCloseContent
                    } else {
                        UPIcon(name: "close", color: iconRenderColorToken, size: "15px")
                    }
                }
                .buttonStyle(.plain)
                .frame(minWidth: 22, minHeight: 22)
                .contentShape(Rectangle())
                .padding(.top, 3)
                .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(resolvedBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .upStyle(customStyle)
    }

    private var resolvedBackgroundColor: Color {
        Self.color(for: backgroundColorToken, theme: theme)
    }

    private var resolvedTextColor: Color {
        Self.color(for: textColorToken, theme: theme)
    }

    private func close() {
        suppressNextModelValueChange = true
        Self.performClose(
            modelValue: modelValue,
            duration: duration,
            onUpdateModelValue: onUpdateModelValueHandler,
            onClose: onCloseHandler,
            onClosed: onClosedHandler
        )
    }

    private func dismissAfterDurationIfNeeded() async {
        guard show, duration > 0, duration.isFinite else { return }
        let nanoseconds = UInt64(duration * 1_000_000)
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
        } catch {
            return
        }
        guard !Task.isCancelled, show else { return }
        close()
    }
}

public extension UPAlert {
    /// uview-plus's type-to-icon mapping, with a custom icon taking priority.
    nonisolated static func iconName(for type: String, customIcon: String) -> String {
        if !customIcon.isEmpty { return customIcon }
        switch type.lowercased() {
        case "success": return "checkmark-circle-fill"
        case "error": return "close-circle-fill"
        case "warning": return "error-circle-fill"
        case "info": return "info-circle-fill"
        case "primary": return "more-circle-fill"
        default: return "error-circle-fill"
        }
    }

    nonisolated static func normalizedType(_ value: String) -> String {
        switch value.lowercased() {
        case "primary", "success", "warning", "error", "info": return value.lowercased()
        default: return "warning"
        }
    }

    nonisolated static func normalizedEffect(_ value: String) -> String {
        value.lowercased() == "dark" ? "dark" : "light"
    }

    nonisolated static func iconColorToken(type: String, effect: String) -> String {
        normalizedEffect(effect) == "dark" ? "#fff" : normalizedType(type)
    }

    nonisolated static func backgroundColorToken(type: String, effect: String) -> String {
        let resolvedType = normalizedType(type)
        return normalizedEffect(effect) == "dark" ? resolvedType : "\(resolvedType)Light"
    }

    nonisolated static func textColorToken(type: String, effect: String) -> String {
        normalizedEffect(effect) == "dark" ? "#fff" : normalizedType(type)
    }

    nonisolated static func resolvedFontSize(from value: String) -> CGFloat {
        let parsed = UPUnit.parse(value)
        return parsed.isFinite && parsed > 0 ? parsed : 14
    }

    nonisolated static func shouldRender(show: Bool) -> Bool {
        show
    }

    nonisolated static func performClick(_ onClick: (() -> Void)?) {
        onClick?()
    }

    nonisolated static func performClose(
        modelValue: Binding<Bool>,
        duration: Double,
        onUpdateModelValue: ((Bool) -> Void)?,
        onClose: (() -> Void)?,
        onClosed: (() -> Void)?
    ) {
        modelValue.wrappedValue = false
        onUpdateModelValue?(false)
        onClose?()
        if duration > 0 {
            onClosed?()
        }
    }

    /// u-transition defaults to a 300 ms ease-out animation. Alert's
    /// `duration` prop is the auto-dismiss delay and must not control this.
    nonisolated static let transitionAnimationDuration: Double = 0.3

    /// Normalizes the upstream u-transition mode names while retaining the
    /// aliases used by early native implementations.
    nonisolated static func normalizedTransitionMode(_ value: String) -> String {
        switch value.lowercased() {
        case "none", "fade", "fade-up", "fade-down", "fade-left", "fade-right",
             "slide-up", "slide-down", "slide-left", "slide-right", "zoom", "fade-zoom":
            return value.lowercased()
        case "slide-top":
            return "slide-down"
        case "slide-bottom":
            return "slide-up"
        case "zoom-in":
            return "zoom"
        case "zoom-out":
            return "fade-zoom"
        default:
            return "fade"
        }
    }

    nonisolated static func transition(for mode: String) -> AnyTransition {
        switch normalizedTransitionMode(mode) {
        case "none": return .identity
        case "fade": return .opacity
        case "fade-up": return .move(edge: .bottom).combined(with: .opacity)
        case "fade-down": return .move(edge: .top).combined(with: .opacity)
        case "fade-left": return .move(edge: .leading).combined(with: .opacity)
        case "fade-right": return .move(edge: .trailing).combined(with: .opacity)
        case "slide-up": return .move(edge: .bottom)
        case "slide-down": return .move(edge: .top)
        case "slide-left": return .move(edge: .leading)
        case "slide-right": return .move(edge: .trailing)
        case "zoom": return .scale(scale: 0.95)
        case "fade-zoom": return .scale(scale: 0.95).combined(with: .opacity)
        default: return .opacity
        }
    }

    nonisolated static func color(for token: String, theme: UPTheme) -> Color {
        switch token {
        case "primaryLight": return theme.primaryLight
        case "successLight": return theme.successLight
        case "warningLight": return theme.warningLight
        case "errorLight": return theme.errorLight
        case "infoLight": return theme.infoLight
        case "#fff", "#ffffff": return .white
        default: return UPColor.parse(token, theme: theme)
        }
    }

    private nonisolated static func normalizedFontSize(_ value: String) -> Double {
        let parsed = UPUnit.parse(value)
        return parsed.isFinite && parsed > 0 ? Double(parsed) : Double(UPConfig.alert.fontSize)
    }

    func onClick(_ action: @escaping () -> Void) -> UPAlert {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    func onClose(_ action: @escaping () -> Void) -> UPAlert {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    func onClosed(_ action: @escaping () -> Void) -> UPAlert {
        var copy = self
        copy.onClosedHandler = action
        return copy
    }

    func onUpdateModelValue(_ action: @escaping (Bool) -> Void) -> UPAlert {
        var copy = self
        copy.onUpdateModelValueHandler = action
        return copy
    }
}
