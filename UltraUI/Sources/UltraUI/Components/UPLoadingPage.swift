import SwiftUI

/// Semantic alias for the String-or-Number props accepted by
/// uview-plus `u-loading-page`.
public typealias UPLoadingPageUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-loading-page`.
///
/// The prop names and default values intentionally follow the upstream
/// component. The trailing `@ViewBuilder` initializer is the SwiftUI mapping
/// of the component's default slot and replaces the default loading text.
@MainActor
public struct UPLoadingPage: View {
    public let loadingText: String
    public let image: String
    public let loadingMode: String
    public let loading: Bool
    public let bgColor: String
    public let color: String
    public let fontSize: String
    public let iconSize: String
    public let loadingColor: String
    public let zIndex: Double
    public let customClass: String
    public let customStyle: UPStyle

    private let contentSlot: AnyView?

    @Environment(\.upTheme) private var theme

    /// Whether the upstream loading overlay should be rendered.
    public var shouldRender: Bool {
        Self.shouldRender(loading: loading)
    }

    /// The normalized loading animation mode used by the native renderer.
    public var resolvedLoadingMode: String {
        Self.normalizedLoadingMode(loadingMode)
    }

    /// Native point size resolved from the upstream String-or-Number prop.
    public var resolvedFontSize: CGFloat {
        Self.resolvedDimension(fontSize, fallback: CGFloat(UPLoadingPageConfig.fontSize))
    }

    /// Native point size resolved from the upstream String-or-Number prop.
    public var resolvedIconSize: CGFloat {
        Self.resolvedDimension(iconSize, fallback: CGFloat(UPLoadingPageConfig.iconSize))
    }

    /// Whether a non-empty image prop replaces the loading indicator.
    public var usesImage: Bool {
        !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether a trailing SwiftUI content slot was supplied.
    public var hasContentSlot: Bool {
        contentSlot != nil
    }

    /// The background token selected by the same precedence as `overlayStyle`:
    /// custom style, explicit `bgColor`, then the current page theme.
    public var effectiveBackgroundToken: String {
        if let customBackground = customStyle.backgroundColor,
           !customBackground.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customBackground
        }

        let explicit = bgColor.trimmingCharacters(in: .whitespacesAndNewlines)
        return explicit.isEmpty ? "bg" : explicit
    }

    public init(
        loadingText: some UPLoadingPageUnitValue = UPConfig.loadingPage.loadingText,
        image: String = UPConfig.loadingPage.image,
        loadingMode: String = UPConfig.loadingPage.loadingMode,
        loading: Bool = UPConfig.loadingPage.loading,
        bgColor: String = UPConfig.loadingPage.bgColor,
        color: String = UPConfig.loadingPage.color,
        fontSize: some UPLoadingPageUnitValue = UPConfig.loadingPage.fontSize,
        iconSize: some UPLoadingPageUnitValue = UPConfig.loadingPage.iconSize,
        loadingColor: String = UPConfig.loadingPage.loadingColor,
        zIndex: some UPLoadingPageUnitValue = UPConfig.loadingPage.zIndex,
        customClass: String = UPConfig.loadingPage.customClass,
        customStyle: UPStyle = UPConfig.loadingPage.customStyle
    ) {
        self.loadingText = loadingText.upCheckboxUnitValue
        self.image = image
        self.loadingMode = loadingMode
        self.loading = loading
        self.bgColor = bgColor
        self.color = color
        self.fontSize = fontSize.upCheckboxUnitValue
        self.iconSize = iconSize.upCheckboxUnitValue
        self.loadingColor = loadingColor
        self.zIndex = Self.resolvedZIndex(
            zIndex.upCheckboxUnitValue,
            fallback: Double(UPLoadingPageConfig.zIndex)
        )
        self.customClass = customClass
        self.customStyle = customStyle
        self.contentSlot = nil
    }

    public init<Content: View>(
        loadingText: some UPLoadingPageUnitValue = UPConfig.loadingPage.loadingText,
        image: String = UPConfig.loadingPage.image,
        loadingMode: String = UPConfig.loadingPage.loadingMode,
        loading: Bool = UPConfig.loadingPage.loading,
        bgColor: String = UPConfig.loadingPage.bgColor,
        color: String = UPConfig.loadingPage.color,
        fontSize: some UPLoadingPageUnitValue = UPConfig.loadingPage.fontSize,
        iconSize: some UPLoadingPageUnitValue = UPConfig.loadingPage.iconSize,
        loadingColor: String = UPConfig.loadingPage.loadingColor,
        zIndex: some UPLoadingPageUnitValue = UPConfig.loadingPage.zIndex,
        customClass: String = UPConfig.loadingPage.customClass,
        customStyle: UPStyle = UPConfig.loadingPage.customStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.loadingText = loadingText.upCheckboxUnitValue
        self.image = image
        self.loadingMode = loadingMode
        self.loading = loading
        self.bgColor = bgColor
        self.color = color
        self.fontSize = fontSize.upCheckboxUnitValue
        self.iconSize = iconSize.upCheckboxUnitValue
        self.loadingColor = loadingColor
        self.zIndex = Self.resolvedZIndex(
            zIndex.upCheckboxUnitValue,
            fallback: Double(UPLoadingPageConfig.zIndex)
        )
        self.customClass = customClass
        self.customStyle = customStyle
        self.contentSlot = AnyView(content())
    }

    public var body: some View {
        Group {
            if shouldRender {
                overlay
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: shouldRender)
    }

    private var overlay: some View {
        ZStack {
            VStack(spacing: 0) {
                loadingVisual
                    .frame(width: resolvedIconSize, height: resolvedIconSize)
                    .padding(.bottom, 10)

                if let contentSlot {
                    contentSlot
                } else {
                    Text(loadingText)
                        .font(.system(size: resolvedFontSize))
                        .foregroundStyle(UPColor.parse(color, theme: theme))
                }
            }
            .offset(y: -75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UPColor.parse(effectiveBackgroundToken, theme: theme))
        .ignoresSafeArea()
        .zIndex(zIndex)
        .upStyle(customStyle)
    }

    @ViewBuilder
    private var loadingVisual: some View {
        if usesImage {
            if let url = URL(string: image), url.scheme != nil {
                AsyncImage(url: url) { phase in
                    if let loadedImage = phase.image {
                        loadedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Image(image)
                    .resizable()
                    .scaledToFit()
            }
        } else {
            UPLoadingIcon(
                show: true,
                color: loadingColor,
                vertical: true,
                mode: resolvedLoadingMode,
                size: Double(resolvedIconSize)
            )
        }
    }
}

public extension UPLoadingPage {
    /// Returns one of the three modes documented by uview-plus.
    nonisolated static func normalizedLoadingMode(_ value: String) -> String {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "circle", "spinner", "semicircle":
            return normalized
        default:
            return UPLoadingPageConfig.loadingMode
        }
    }

    nonisolated static func shouldRender(loading: Bool) -> Bool {
        loading
    }

    private nonisolated static func resolvedDimension(_ value: String, fallback: CGFloat) -> CGFloat {
        let parsed = UPUnit.parse(value)
        return parsed.isFinite && parsed > 0 ? parsed : fallback
    }

    private nonisolated static func resolvedZIndex(_ value: String, fallback: Double) -> Double {
        let parsed = Double(UPUnit.parse(value))
        return parsed.isFinite ? parsed : fallback
    }
}
