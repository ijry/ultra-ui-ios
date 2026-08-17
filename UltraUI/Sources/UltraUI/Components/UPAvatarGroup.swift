import SwiftUI

/// Semantic alias for the `String | Number` props accepted by `u-avatar-group`.
public typealias UPAvatarGroupUnitValue = UPCheckboxUnitValue

/// A typed Swift representation of one member of uview-plus `u-avatar-group`'s
/// `urls` array. The upstream component accepts either a URL string or an
/// object whose selected property (or `url`) contains the avatar URL.
public enum UPAvatarGroupItem: Equatable, Sendable {
    case url(String)
    case object([String: String])
}

extension UPAvatarGroupItem: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .url(value)
    }

    public init(unicodeScalarLiteral value: String) {
        self = .url(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .url(value)
    }
}

/// Native SwiftUI counterpart of uview-plus `u-avatar-group`.
///
/// The component retains the upstream props and maps its overlapping-avatar
/// layout to an `HStack`. `showMore` is emitted as an `onShowMore` closure when
/// the final visible avatar's native overlay is tapped.
public struct UPAvatarGroup: View {
    var urls: [UPAvatarGroupItem]
    var maxCount: Int
    var shape: String
    var mode: String
    var showMore: Bool
    var size: Double
    var keyName: String
    var gap: Double
    var extraValue: Int
    /// Retained for uview-plus source compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    var showMoreHandler: (() -> Void)?

    /// Creates a group from the upstream string-or-object `urls` array.
    /// Each `String | Number` prop is independently typed so native Swift
    /// callers can mix strings, integers, and floating-point values just as
    /// Vue callers can mix JavaScript strings and numbers.
    public init(urls: [UPAvatarGroupItem] = UPConfig.avatarGroup.urls,
                maxCount: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.maxCount,
                shape: String = UPConfig.avatarGroup.shape,
                mode: String = UPConfig.avatarGroup.mode,
                showMore: Bool = UPConfig.avatarGroup.showMore,
                size: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.size,
                keyName: String = UPConfig.avatarGroup.keyName,
                gap: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.gap,
                extraValue: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.extraValue,
                customClass: String = UPConfig.avatarGroup.customClass,
                customStyle: UPStyle = UPConfig.avatarGroup.customStyle,
                onShowMore: (() -> Void)? = nil) {
        self.urls = urls
        self.maxCount = Self.integerValue(maxCount.upCheckboxUnitValue)
        self.shape = shape
        self.mode = mode
        self.showMore = showMore
        self.size = Double(UPUnit.parse(size.upCheckboxUnitValue))
        self.keyName = keyName
        self.gap = Double(UPUnit.parse(gap.upCheckboxUnitValue))
        self.extraValue = Self.integerValue(extraValue.upCheckboxUnitValue)
        self.customClass = customClass
        self.customStyle = customStyle
        self.showMoreHandler = onShowMore
    }

    /// Convenience overload for the common upstream `string[]` `urls` form.
    public init(urls: [String],
                maxCount: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.maxCount,
                shape: String = UPConfig.avatarGroup.shape,
                mode: String = UPConfig.avatarGroup.mode,
                showMore: Bool = UPConfig.avatarGroup.showMore,
                size: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.size,
                keyName: String = UPConfig.avatarGroup.keyName,
                gap: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.gap,
                extraValue: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.extraValue,
                customClass: String = UPConfig.avatarGroup.customClass,
                customStyle: UPStyle = UPConfig.avatarGroup.customStyle,
                onShowMore: (() -> Void)? = nil) {
        self.init(
            urls: urls.map(UPAvatarGroupItem.url),
            maxCount: maxCount,
            shape: shape,
            mode: mode,
            showMore: showMore,
            size: size,
            keyName: keyName,
            gap: gap,
            extraValue: extraValue,
            customClass: customClass,
            customStyle: customStyle,
            onShowMore: onShowMore
        )
    }

    /// Convenience overload for the object-array form accepted by uview-plus.
    public init(urls: [[String: String]],
                maxCount: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.maxCount,
                shape: String = UPConfig.avatarGroup.shape,
                mode: String = UPConfig.avatarGroup.mode,
                showMore: Bool = UPConfig.avatarGroup.showMore,
                size: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.size,
                keyName: String = UPConfig.avatarGroup.keyName,
                gap: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.gap,
                extraValue: some UPAvatarGroupUnitValue = UPConfig.avatarGroup.extraValue,
                customClass: String = UPConfig.avatarGroup.customClass,
                customStyle: UPStyle = UPConfig.avatarGroup.customStyle,
                onShowMore: (() -> Void)? = nil) {
        self.init(
            urls: urls.map(UPAvatarGroupItem.object),
            maxCount: maxCount,
            shape: shape,
            mode: mode,
            showMore: showMore,
            size: size,
            keyName: keyName,
            gap: gap,
            extraValue: extraValue,
            customClass: customClass,
            customStyle: customStyle,
            onShowMore: onShowMore
        )
    }

    public var body: some View {
        HStack(spacing: -resolvedSize * resolvedGap) {
            ForEach(Array(visibleURLs.enumerated()), id: \.offset) { index, url in
                avatar(url: url, index: index)
                    .zIndex(Double(visibleURLs.count - index))
            }
        }
        .upStyle(customStyle)
    }

    /// The upstream `urls.slice(0, maxCount)` projection, after resolving
    /// object members through `keyName` and then their `url` fallback.
    var visibleURLs: [String] {
        Array(urls.prefix(max(maxCount, 0))).map { $0.resolvedURL(keyName: keyName) }
    }

    var hiddenCount: Int {
        max(urls.count - visibleURLs.count, 0)
    }

    var showsMoreIndicator: Bool {
        showMore && !visibleURLs.isEmpty && (hiddenCount > 0 || extraValue > 0)
    }

    var moreText: String {
        "+\(extraValue > 0 ? extraValue : hiddenCount)"
    }

    /// SwiftUI event modifier corresponding to uview-plus `@showMore`.
    public func onShowMore(_ action: @escaping () -> Void) -> UPAvatarGroup {
        var copy = self
        copy.showMoreHandler = action
        return copy
    }

    @ViewBuilder
    private func avatar(url: String, index: Int) -> some View {
        ZStack {
            UPAvatar(src: url, shape: shape, size: size, mode: mode)

            if showsMoreIndicator && index == visibleURLs.count - 1 {
                Button(action: { showMoreHandler?() }) {
                    Text(moreText)
                        .font(.system(size: resolvedSize * 0.4))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
                .accessibilityLabel("Show \(extraValue > 0 ? extraValue : hiddenCount) more avatars")
            }
        }
        .frame(width: resolvedSize, height: resolvedSize)
    }

    private var resolvedSize: CGFloat {
        max(CGFloat(size), 1)
    }

    private var resolvedGap: CGFloat {
        min(max(CGFloat(gap), 0), 1)
    }

    private var resolvedCornerRadius: CGFloat {
        shape.lowercased() == "square" ? 4 : resolvedSize / 2
    }

    private static func integerValue(_ value: String) -> Int {
        Int(UPUnit.parse(value))
    }
}

private extension UPAvatarGroupItem {
    func resolvedURL(keyName: String) -> String {
        switch self {
        case .url(let value):
            return value
        case .object(let values):
            let configuredValue = keyName.isEmpty ? nil : values[keyName]
            if let configuredValue, !configuredValue.isEmpty {
                return configuredValue
            }
            return values["url"] ?? ""
        }
    }
}
