import SwiftUI

/// A main-actor toast state container. Add ``UPToastView`` near the root of
/// your app once, then call ``UPToast/show(message:type:position:duration:)``
/// from any SwiftUI action.
@MainActor
public final class UPToastCenter: ObservableObject {
    public static let shared = UPToastCenter()

    @Published public private(set) var message = ""
    @Published public private(set) var type = "default"
    @Published public private(set) var position = UPConfig.toast.position
    @Published public private(set) var isShowing = false

    private var dismissTask: Task<Void, Never>?

    public init() {}

    deinit {
        dismissTask?.cancel()
    }

    public func show(message: String,
                     type: String = "default",
                     position: String = UPConfig.toast.position,
                     duration: Double = UPConfig.toast.duration) {
        dismissTask?.cancel()
        self.message = message
        self.type = type
        self.position = position

        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = true
        }

        guard duration > 0 else { return }
        let nanoseconds = UInt64(max(0, duration) * 1_000_000)
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    public func hide() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = false
        }
    }
}

/// uview-plus compatible toast API.
@MainActor
public enum UPToast {
    public static func show(message: String,
                            type: String = "default",
                            position: String = UPConfig.toast.position,
                            duration: Double = UPConfig.toast.duration) {
        UPToastCenter.shared.show(message: message,
                                  type: type,
                                  position: position,
                                  duration: duration)
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
        Group {
            if center.isShowing {
                toastContent
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: UPToast.alignment(for: center.position))
                    .padding(.top, center.position == "top" ? 60 : 0)
                    .padding(.bottom, center.position == "bottom" ? 40 : 0)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(UPConfig.toast.zIndex)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: center.isShowing)
    }

    private var toastContent: some View {
        VStack(spacing: 8) {
            if center.type == "loading" {
                UPLoadingIcon(show: true,
                              color: "#ffffff",
                              textColor: "#ffffff",
                              vertical: true,
                              mode: "circle",
                              size: 25)
            } else if !UPToast.iconName(for: center.type).isEmpty {
                UPIcon(name: UPToast.iconName(for: center.type),
                       color: "#ffffff",
                       size: "17px")
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
