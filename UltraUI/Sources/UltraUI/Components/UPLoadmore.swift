import SwiftUI

/// Semantic alias for the `String | Number` size and spacing props accepted by
/// uview-plus `u-loadmore`.
public typealias UPLoadmoreUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-loadmore`.
public struct UPLoadmore: View {
    var status: String
    var bgColor: String
    var icon: Bool
    var fontSize: String
    var iconSize: String
    var color: String
    var loadingIcon: String
    var loadmoreText: String
    var loadingText: String
    var nomoreText: String
    var isDot: Bool
    var iconColor: String
    var marginTop: String
    var marginBottom: String
    var height: String
    var line: Bool
    var lineColor: String
    var dashed: Bool
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    private var onLoadmoreHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    public init(
        status: String = UPConfig.loadmore.status,
        bgColor: String = UPConfig.loadmore.bgColor,
        icon: Bool = UPConfig.loadmore.icon,
        fontSize: some UPLoadmoreUnitValue = UPConfig.loadmore.fontSize,
        iconSize: some UPLoadmoreUnitValue = UPConfig.loadmore.iconSize,
        color: String = UPConfig.loadmore.color,
        loadingIcon: String = UPConfig.loadmore.loadingIcon,
        loadmoreText: String = UPConfig.loadmore.loadmoreText,
        loadingText: String = UPConfig.loadmore.loadingText,
        nomoreText: String = UPConfig.loadmore.nomoreText,
        isDot: Bool = UPConfig.loadmore.isDot,
        iconColor: String = UPConfig.loadmore.iconColor,
        marginTop: some UPLoadmoreUnitValue = UPConfig.loadmore.marginTop,
        marginBottom: some UPLoadmoreUnitValue = UPConfig.loadmore.marginBottom,
        height: some UPLoadmoreUnitValue = UPConfig.loadmore.height,
        line: Bool = UPConfig.loadmore.line,
        lineColor: String = UPConfig.loadmore.lineColor,
        dashed: Bool = UPConfig.loadmore.dashed,
        customClass: String = UPConfig.loadmore.customClass,
        customStyle: UPStyle = UPConfig.loadmore.customStyle,
        onLoadmore: (() -> Void)? = nil
    ) {
        self.status = status
        self.bgColor = bgColor
        self.icon = icon
        self.fontSize = fontSize.upCheckboxUnitValue
        self.iconSize = iconSize.upCheckboxUnitValue
        self.color = color
        self.loadingIcon = loadingIcon
        self.loadmoreText = loadmoreText
        self.loadingText = loadingText
        self.nomoreText = nomoreText
        self.isDot = isDot
        self.iconColor = iconColor
        self.marginTop = marginTop.upCheckboxUnitValue
        self.marginBottom = marginBottom.upCheckboxUnitValue
        self.height = height.upCheckboxUnitValue
        self.line = line
        self.lineColor = lineColor
        self.dashed = dashed
        self.customClass = customClass
        self.customStyle = customStyle
        self.onLoadmoreHandler = onLoadmore
    }

    public var body: some View {
        HStack(spacing: 0) {
            if showsLines {
                separator
            }

            statusContent

            if showsLines {
                separator
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: resolvedHeight)
        .background(resolvedBackground)
        .padding(.top, resolvedMarginTop)
        .padding(.bottom, resolvedMarginBottom)
        .upStyle(customStyle)
    }

    /// Text selected by the same status rules as the upstream `showText` computed prop.
    var showText: String {
        if status == "loadmore" { return loadmoreText }
        if status == "loading" { return loadingText }
        if status == "nomore" && isDot { return "●" }
        return nomoreText
    }

    /// Whether the upstream loading icon branch is visible.
    var showsLoadingIcon: Bool {
        status == "loading" && icon
    }

    /// Whether each of the two surrounding 140rpx lines is visible.
    var showsLines: Bool {
        line
    }

    /// Native point size resolved from uview-plus' String-or-Number `fontSize` prop.
    var resolvedFontSize: CGFloat {
        max(Self.unitValue(fontSize) ?? CGFloat(UPConfig.loadmore.fontSize), 0)
    }

    /// Native point size resolved from uview-plus' String-or-Number `iconSize` prop.
    var resolvedIconSize: CGFloat {
        max(Self.unitValue(iconSize) ?? CGFloat(UPConfig.loadmore.iconSize), 0)
    }

    /// The outer CSS-like top margin resolved for SwiftUI layout.
    var resolvedMarginTop: CGFloat {
        Self.unitValue(marginTop) ?? 0
    }

    /// The outer CSS-like bottom margin resolved for SwiftUI layout.
    var resolvedMarginBottom: CGFloat {
        Self.unitValue(marginBottom) ?? 0
    }

    /// `nil` represents the upstream CSS `height: auto` behavior.
    var resolvedHeight: CGFloat? {
        guard let value = Self.unitValue(height), value >= 0 else { return nil }
        return value
    }

    func triggerLoadmore() {
        guard status == "loadmore" else { return }
        onLoadmoreHandler?()
    }

    private var resolvedBackground: Color {
        let normalized = bgColor.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty || normalized == "transparent" {
            return .clear
        }
        return UPColor.parse(bgColor, theme: theme)
    }

    private var separator: some View {
        UPLine(
            color: lineColor,
            length: "140rpx",
            direction: "row",
            hairline: false,
            margin: 0,
            dashed: dashed
        )
        .frame(width: UPUnit.rpx(140), height: 1)
    }

    private var statusContent: some View {
        HStack(spacing: showsLoadingIcon ? 8 : 0) {
            if showsLoadingIcon {
                UPLoadingIcon(
                    show: true,
                    color: iconColor,
                    mode: loadingIcon,
                    size: Double(resolvedIconSize),
                    text: ""
                )
                .frame(width: resolvedIconSize, height: resolvedIconSize)
                .clipped()
            }

            Text(showText)
                .font(.system(size: resolvedFontSize))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(UPColor.parse(color, theme: theme))
        }
        .padding(.horizontal, 15)
        .contentShape(Rectangle())
        .onTapGesture(perform: triggerLoadmore)
    }

    private static func unitValue(_ raw: String) -> CGFloat? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != "auto" else { return nil }

        let numericPart: Substring
        let multiplier: CGFloat
        if normalized.hasSuffix("rpx") {
            numericPart = normalized.dropLast(3)
            multiplier = UPUnit.rpx(1)
        } else if normalized.hasSuffix("px") {
            numericPart = normalized.dropLast(2)
            multiplier = 1
        } else {
            numericPart = Substring(normalized)
            multiplier = 1
        }

        guard let value = Double(numericPart), value.isFinite else { return nil }
        return CGFloat(value) * multiplier
    }
}

public extension UPLoadmore {
    /// Registers the uview-plus `loadmore` event callback.
    func onLoadmore(_ action: @escaping () -> Void) -> UPLoadmore {
        var copy = self
        copy.onLoadmoreHandler = action
        return copy
    }
}
