import SwiftUI

/// Semantic alias for the String-or-Number props accepted by
/// uview-plus `u-back-top`.
public typealias UPBackTopUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-back-top`.
///
/// Place this view in an overlay above the scrollable content and feed the
/// current native scroll offset through `scrollTop`. The upstream `click`
/// emit maps to ``onClick(_:)``; callers use that callback with
/// `ScrollViewReader` to perform the platform-native scroll-to-top action.
@MainActor
public struct UPBackTop: View {
    public let mode: String
    public let icon: String
    public let text: String
    public let duration: String
    public let scrollTop: String
    public let top: String
    public let bottom: String
    public let right: String
    public let zIndex: String
    public let iconStyle: UPStyle
    public let customClass: String
    public let customStyle: UPStyle

    private let contentSlot: AnyView?
    var onClickHandler: (() -> Void)?

    /// Whether the button is shown at the current upstream scroll threshold.
    public var isVisible: Bool {
        resolvedScrollTop > resolvedTop
    }

    /// Normalized native shape. Upstream treats every non-circle mode as a
    /// square button.
    public var resolvedMode: String {
        mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "circle"
            ? "circle"
            : "square"
    }

    public var resolvedDuration: Double {
        Self.resolveDuration(duration, fallback: Double(UPBackTopConfig.duration))
    }

    public var resolvedScrollTop: CGFloat {
        Self.resolveLength(scrollTop, fallback: CGFloat(UPBackTopConfig.scrollTop))
    }

    public var resolvedTop: CGFloat {
        Self.resolveLength(top, fallback: CGFloat(UPBackTopConfig.top))
    }

    public var resolvedBottom: CGFloat {
        Self.resolveLength(bottom, fallback: CGFloat(UPBackTopConfig.bottom))
    }

    public var resolvedRight: CGFloat {
        Self.resolveLength(right, fallback: CGFloat(UPBackTopConfig.right))
    }

    public var resolvedZIndex: Double {
        Self.resolveNumber(zIndex, fallback: Double(UPBackTopConfig.zIndex))
    }

    public var resolvedCornerRadius: CGFloat {
        resolvedMode == "circle" ? 100 : 4
    }

    /// Whether a SwiftUI equivalent of the upstream default slot is present.
    public var hasContentSlot: Bool {
        contentSlot != nil
    }

    public init(
        mode: String = UPConfig.backTop.mode,
        icon: String = UPConfig.backTop.icon,
        text: String = UPConfig.backTop.text,
        duration: some UPBackTopUnitValue = UPConfig.backTop.duration,
        scrollTop: some UPBackTopUnitValue = UPConfig.backTop.scrollTop,
        top: some UPBackTopUnitValue = UPConfig.backTop.top,
        bottom: some UPBackTopUnitValue = UPConfig.backTop.bottom,
        right: some UPBackTopUnitValue = UPConfig.backTop.right,
        zIndex: some UPBackTopUnitValue = UPConfig.backTop.zIndex,
        iconStyle: UPStyle = UPConfig.backTop.iconStyle,
        customClass: String = UPConfig.backTop.customClass,
        customStyle: UPStyle = UPConfig.backTop.customStyle,
        onClick: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.icon = icon
        self.text = text
        self.duration = duration.upCheckboxUnitValue
        self.scrollTop = scrollTop.upCheckboxUnitValue
        self.top = top.upCheckboxUnitValue
        self.bottom = bottom.upCheckboxUnitValue
        self.right = right.upCheckboxUnitValue
        self.zIndex = zIndex.upCheckboxUnitValue
        self.iconStyle = iconStyle
        self.customClass = customClass
        self.customStyle = customStyle
        self.contentSlot = nil
        self.onClickHandler = onClick
    }

    public init<Content: View>(
        mode: String = UPConfig.backTop.mode,
        icon: String = UPConfig.backTop.icon,
        text: String = UPConfig.backTop.text,
        duration: some UPBackTopUnitValue = UPConfig.backTop.duration,
        scrollTop: some UPBackTopUnitValue = UPConfig.backTop.scrollTop,
        top: some UPBackTopUnitValue = UPConfig.backTop.top,
        bottom: some UPBackTopUnitValue = UPConfig.backTop.bottom,
        right: some UPBackTopUnitValue = UPConfig.backTop.right,
        zIndex: some UPBackTopUnitValue = UPConfig.backTop.zIndex,
        iconStyle: UPStyle = UPConfig.backTop.iconStyle,
        customClass: String = UPConfig.backTop.customClass,
        customStyle: UPStyle = UPConfig.backTop.customStyle,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.mode = mode
        self.icon = icon
        self.text = text
        self.duration = duration.upCheckboxUnitValue
        self.scrollTop = scrollTop.upCheckboxUnitValue
        self.top = top.upCheckboxUnitValue
        self.bottom = bottom.upCheckboxUnitValue
        self.right = right.upCheckboxUnitValue
        self.zIndex = zIndex.upCheckboxUnitValue
        self.iconStyle = iconStyle
        self.customClass = customClass
        self.customStyle = customStyle
        self.contentSlot = AnyView(content())
        self.onClickHandler = onClick
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isVisible {
                renderedContent
                    .frame(width: 40, height: 40)
                    .padding(.bottom, resolvedBottom)
                    .padding(.trailing, resolvedRight)
                    .transition(.opacity)
                    .zIndex(resolvedZIndex)
                    .onTapGesture {
                        triggerClick()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.easeOut(duration: resolvedDuration / 1_000), value: isVisible)
    }

    @ViewBuilder
    private var renderedContent: some View {
        if let contentSlot {
            contentSlot
        } else {
            VStack(spacing: 0) {
                UPIcon(
                    name: icon,
                    color: iconStyle.foregroundColor ?? "#909399",
                    size: Self.iconSize(from: iconStyle)
                )

                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundStyle(
                            UPColor.parse(customStyle.foregroundColor ?? "#606266")
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 225 / 255, green: 225 / 255, blue: 225 / 255))
            .clipShape(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
            )
            .upStyle(customStyle)
        }
    }

    func triggerClick() {
        onClickHandler?()
    }

    nonisolated static func resolveLength(_ value: String, fallback: CGFloat) -> CGFloat {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return fallback }

        let number: Double?
        if normalized.hasSuffix("rpx") {
            number = Double(normalized.dropLast(3))
        } else if normalized.hasSuffix("px") {
            number = Double(normalized.dropLast(2))
        } else {
            number = Double(normalized)
        }

        guard let number, number.isFinite else { return fallback }
        return normalized.hasSuffix("rpx")
            ? UPUnit.rpx(CGFloat(number))
            : CGFloat(number)
    }

    nonisolated static func resolveDuration(_ value: String, fallback: Double) -> Double {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let numeric = normalized.hasSuffix("ms")
            ? String(normalized.dropLast(2))
            : normalized
        guard let value = Double(numeric), value.isFinite else { return fallback }
        return max(0, value)
    }

    nonisolated static func resolveNumber(_ value: String, fallback: Double) -> Double {
        guard let value = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)),
              value.isFinite else {
            return fallback
        }
        return value
    }

    nonisolated private static func iconSize(from style: UPStyle) -> String {
        style.value(for: "font-size") ?? "19px"
    }
}

public extension UPBackTop {
    func onClick(_ action: @escaping () -> Void) -> UPBackTop {
        var copy = self
        copy.onClickHandler = action
        return copy
    }
}
