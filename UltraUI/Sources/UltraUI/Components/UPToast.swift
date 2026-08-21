import SwiftUI

/// Typed options for the imperative uview-plus `u-toast` surface.
///
/// Values use the same camel-case prop names as upstream. Navigation-related
/// properties (`isTab`, `url`, `params`, `back`) are retained as metadata,
/// because native navigation ownership stays with the host SwiftUI app.
@MainActor
public struct UPToastOptions {
    public var zIndex: Double
    public var loading: Bool
    public var message: String
    public var icon: String
    public var type: String
    public var loadingMode: String
    public var show: Bool
    public var overlay: Bool
    public var position: String
    public var params: [String: String]
    public var duration: Double
    public var isTab: Bool
    public var url: String
    public var callback: (() -> Void)?
    public var back: Bool

    public init(loading: Bool = UPConfig.toast.loading,
                message: String = UPConfig.toast.message,
                icon: String = UPConfig.toast.icon,
                type: String = UPConfig.toast.type,
                loadingMode: String = UPConfig.toast.loadingMode,
                show: Bool = UPConfig.toast.show,
                overlay: Bool = UPConfig.toast.overlay,
                position: String = UPConfig.toast.position,
                params: [String: String] = UPConfig.toast.params,
                duration: Double = UPConfig.toast.duration,
                isTab: Bool = UPConfig.toast.isTab,
                url: String = UPConfig.toast.url,
                callback: (() -> Void)? = nil,
                back: Bool = UPConfig.toast.back,
                zIndex: Double = UPConfig.toast.zIndex) {
        self.zIndex = zIndex
        self.loading = loading
        self.message = message
        self.icon = icon
        self.type = type
        self.loadingMode = loadingMode
        self.show = show
        self.overlay = overlay
        self.position = position
        self.params = params
        self.duration = duration
        self.isTab = isTab
        self.url = url
        self.callback = callback
        self.back = back
    }
}

/// A main-actor toast state container. Add ``UPToastView`` near the root of
/// your app once, then call ``UPToast/show(_:)`` from any SwiftUI action.
@MainActor
public final class UPToastCenter: ObservableObject {
    public static let shared = UPToastCenter()

    @Published public private(set) var zIndex = UPConfig.toast.zIndex
    @Published public private(set) var loading = UPConfig.toast.loading
    @Published public private(set) var message = UPConfig.toast.message
    @Published public private(set) var icon = UPConfig.toast.icon
    @Published public private(set) var type = UPConfig.toast.type
    @Published public private(set) var loadingMode = UPConfig.toast.loadingMode
    @Published public private(set) var overlay = UPConfig.toast.overlay
    @Published public private(set) var position = UPConfig.toast.position
    @Published public private(set) var params = UPConfig.toast.params
    @Published public private(set) var duration = UPConfig.toast.duration
    @Published public private(set) var isTab = UPConfig.toast.isTab
    @Published public private(set) var url = UPConfig.toast.url
    @Published public private(set) var back = UPConfig.toast.back
    @Published public private(set) var isShowing = false

    private var dismissTask: Task<Void, Never>?
    private var completion: (() -> Void)?

    public init() {}

    deinit {
        dismissTask?.cancel()
    }

    /// Shows an upstream-compatible toast configuration.
    public func show(_ options: UPToastOptions) {
        dismissTask?.cancel()
        completeCurrentCallback()

        zIndex = options.zIndex
        loading = options.loading
        message = options.message
        icon = options.icon
        type = options.type
        loadingMode = options.loadingMode
        overlay = options.overlay
        position = options.position
        params = options.params
        duration = options.duration
        isTab = options.isTab
        url = options.url
        back = options.back
        completion = options.callback

        guard options.show else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowing = false
            }
            completeCurrentCallback()
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = true
        }

        // uview-plus treats only `-1` as persistent; zero and other negative
        // durations schedule an immediate completion just like JavaScript timers.
        guard options.duration != -1 else { return }
        let delay = options.duration.isFinite ? max(0, options.duration) : 0
        let nanoseconds = UInt64(delay * 1_000_000)
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    /// Backward-compatible convenience for the earlier native API.
    public func show(message: String,
                     type: String = "default",
                     position: String = UPConfig.toast.position,
                     duration: Double = UPConfig.toast.duration) {
        show(UPToastOptions(
            message: message,
            type: type,
            show: true,
            position: position,
            duration: duration
        ))
    }

    public func hide() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = false
        }
        completeCurrentCallback()
    }

    private func completeCurrentCallback() {
        let callback = completion
        completion = nil
        callback?()
    }
}

/// uview-plus compatible toast API.
@MainActor
public enum UPToast {
    public static func show(_ options: UPToastOptions) {
        UPToastCenter.shared.show(options)
    }

    public static func show(message: String,
                            type: String = "default",
                            position: String = UPConfig.toast.position,
                            duration: Double = UPConfig.toast.duration) {
        UPToastCenter.shared.show(
            message: message,
            type: type,
            position: position,
            duration: duration
        )
    }

    public static func hide() {
        UPToastCenter.shared.hide()
    }

    public static func iconName(for type: String) -> String {
        switch type {
        case "success": return "uicon-checkmark"
        case "error": return "uicon-close"
        case "warning": return "uicon-info-circle"
        default: return ""
        }
    }

    public static func alignment(for position: String) -> Alignment {
        switch position {
        case "top": return .top
        case "bottom": return .bottom
        default: return .center
        }
    }
}

/// Declarative toast layer. Attach it once with `.overlay { UPToastView() }`.
@MainActor
public struct UPToastView: View {
    @ObservedObject private var center: UPToastCenter

    public init(center: UPToastCenter = .shared) {
        self.center = center
    }

    public var body: some View {
        ZStack {
            if center.isShowing && center.overlay {
                UPOverlay(show: true, zIndex: center.zIndex - 1)
            }

            if center.isShowing {
                toastContent
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: UPToast.alignment(for: center.position))
                    .padding(.top, center.position == "top" ? 60 : 0)
                    .padding(.bottom, center.position == "bottom" ? 40 : 0)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(center.zIndex)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: center.isShowing)
    }

    private var toastContent: some View {
        VStack(spacing: 8) {
            if center.loading || center.type == "loading" {
                UPLoadingIcon(
                    show: true,
                    color: "#ffffff",
                    textColor: "#ffffff",
                    vertical: true,
                    mode: center.loadingMode.isEmpty ? "spinner" : center.loadingMode,
                    size: 25
                )
            } else if !center.icon.isEmpty {
                UPIcon(name: center.icon, color: "#ffffff", size: "17px")
            } else if !UPToast.iconName(for: center.type).isEmpty {
                UPIcon(name: UPToast.iconName(for: center.type), color: "#ffffff", size: "17px")
            }

            if !center.message.isEmpty {
                Text(center.message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 260)
    }
}
