import SwiftUI

/// A string-or-number value accepted by the uview-plus `u-skeleton` dimension
/// props. The raw spelling is preserved for compatibility while the original
/// JavaScript truthiness is retained for array fallback behavior.
public protocol UPSkeletonUnitValue {
    var upSkeletonUnitValue: UPSkeletonUnit { get }
}

/// A normalized scalar used by u-skeleton's string-or-number props.
public struct UPSkeletonUnit: Equatable, Sendable {
    public let value: String
    public let isJavaScriptFalsy: Bool

    public init(value: String, isJavaScriptFalsy: Bool) {
        self.value = value
        self.isJavaScriptFalsy = isJavaScriptFalsy
    }
}

extension String: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: self, isJavaScriptFalsy: isEmpty)
    }
}

extension Int: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension Int8: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension Int16: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension Int32: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension Int64: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension UInt: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension UInt8: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension UInt16: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension UInt32: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension UInt64: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(value: String(self), isJavaScriptFalsy: self == 0)
    }
}

extension Double: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        UPSkeletonUnit(
            value: Self.upSkeletonFormatted(self),
            isJavaScriptFalsy: self == 0 || self.isNaN
        )
    }
}

extension Float: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        Double(self).upSkeletonUnitValue
    }
}

extension CGFloat: UPSkeletonUnitValue {
    public var upSkeletonUnitValue: UPSkeletonUnit {
        Double(self).upSkeletonUnitValue
    }
}

private extension Double {
    static func upSkeletonFormatted(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}

/// A scalar-or-array value accepted by uview-plus `rowsWidth` and
/// `rowsHeight`. `scalar` and `array` are normalized comparison helpers; the
/// initializer still accepts native `String`, number, `[String]`, and
/// `[Number]` inputs directly.
public enum UPSkeletonUnitInput: Equatable, Sendable {
    case single(UPSkeletonUnit)
    case multiple([UPSkeletonUnit])

    public static func scalar(_ value: String) -> UPSkeletonUnitInput {
        .single(UPSkeletonUnit(value: value, isJavaScriptFalsy: value.isEmpty))
    }

    public static func array(_ values: [String]) -> UPSkeletonUnitInput {
        .multiple(values.map {
            UPSkeletonUnit(value: $0, isJavaScriptFalsy: $0.isEmpty)
        })
    }

    var isArray: Bool {
        if case .multiple = self { return true }
        return false
    }

    var scalarValue: UPSkeletonUnit? {
        guard case let .single(value) = self else { return nil }
        return value
    }

    var arrayValues: [UPSkeletonUnit] {
        guard case let .multiple(values) = self else { return [] }
        return values
    }
}

/// Values that can be converted to one of u-skeleton's scalar-or-array props.
public protocol UPSkeletonUnitInputConvertible {
    var upSkeletonUnitInput: UPSkeletonUnitInput { get }
}

extension String: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Int: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Double: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Float: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension CGFloat: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Int8: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Int16: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Int32: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Int64: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension UInt: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension UInt8: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension UInt16: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension UInt32: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension UInt64: UPSkeletonUnitInputConvertible {
    public var upSkeletonUnitInput: UPSkeletonUnitInput { .single(upSkeletonUnitValue) }
}

extension Array: UPSkeletonUnitInputConvertible where Element: UPSkeletonUnitValue {
    public var upSkeletonUnitInput: UPSkeletonUnitInput {
        .multiple(map(\.upSkeletonUnitValue))
    }
}

/// A computed paragraph row in uview-plus `u-skeleton`.
public struct UPSkeletonRow: Equatable, Sendable {
    public let width: String
    public let height: String
    public let marginTop: String

    public func resolvedWidth(in containerWidth: CGFloat) -> CGFloat {
        UPSkeletonDimension.resolveWidth(width, in: containerWidth)
    }

    public var resolvedHeight: CGFloat {
        max(UPUnit.parse(height), 0)
    }
}

/// Native SwiftUI counterpart of uview-plus `u-skeleton`.
///
/// The prop names, defaults, `rowsWidth` / `rowsHeight` scalar-or-array
/// surface, and the default Vue slot behavior mirror the checked-in uview-plus
/// implementation. When `loading` is false, the SwiftUI trailing
/// `ViewBuilder` is rendered in place of the skeleton markup. Native shimmer
/// animation approximates uview-plus's CSS gradient animation.
public struct UPSkeleton: View {
    var loading: Bool
    var animate: Bool
    var rows: String
    var rowsWidth: UPSkeletonUnitInput
    var rowsHeight: UPSkeletonUnitInput
    var title: Bool
    var titleWidth: String
    var titleHeight: String
    var avatar: Bool
    var avatarSize: String
    var avatarShape: String
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle

    private let content: AnyView

    /// Creates a skeleton with a SwiftUI equivalent of uview-plus's default
    /// slot. The slot is displayed only while `loading` is false.
    public init<Content: View>(
        loading: Bool = UPConfig.skeleton.loading,
        animate: Bool = UPConfig.skeleton.animate,
        rows: any UPSkeletonUnitValue = UPConfig.skeleton.rows,
        rowsWidth: any UPSkeletonUnitInputConvertible = UPConfig.skeleton.rowsWidth,
        rowsHeight: any UPSkeletonUnitInputConvertible = UPConfig.skeleton.rowsHeight,
        title: Bool = UPConfig.skeleton.title,
        titleWidth: any UPSkeletonUnitValue = UPConfig.skeleton.titleWidth,
        titleHeight: any UPSkeletonUnitValue = UPConfig.skeleton.titleHeight,
        avatar: Bool = UPConfig.skeleton.avatar,
        avatarSize: any UPSkeletonUnitValue = UPConfig.skeleton.avatarSize,
        avatarShape: String = UPConfig.skeleton.avatarShape,
        customClass: String = UPConfig.skeleton.customClass,
        customStyle: UPStyle = UPConfig.skeleton.customStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.loading = loading
        self.animate = animate
        self.rows = rows.upSkeletonUnitValue.value
        self.rowsWidth = rowsWidth.upSkeletonUnitInput
        self.rowsHeight = rowsHeight.upSkeletonUnitInput
        self.title = title
        self.titleWidth = titleWidth.upSkeletonUnitValue.value
        self.titleHeight = titleHeight.upSkeletonUnitValue.value
        self.avatar = avatar
        self.avatarSize = avatarSize.upSkeletonUnitValue.value
        self.avatarShape = avatarShape
        self.customClass = customClass
        self.customStyle = customStyle
        self.content = AnyView(content())
    }

    /// Creates an empty `<u-skeleton />` equivalent without default-slot
    /// content.
    public init(
        loading: Bool = UPConfig.skeleton.loading,
        animate: Bool = UPConfig.skeleton.animate,
        rows: any UPSkeletonUnitValue = UPConfig.skeleton.rows,
        rowsWidth: any UPSkeletonUnitInputConvertible = UPConfig.skeleton.rowsWidth,
        rowsHeight: any UPSkeletonUnitInputConvertible = UPConfig.skeleton.rowsHeight,
        title: Bool = UPConfig.skeleton.title,
        titleWidth: any UPSkeletonUnitValue = UPConfig.skeleton.titleWidth,
        titleHeight: any UPSkeletonUnitValue = UPConfig.skeleton.titleHeight,
        avatar: Bool = UPConfig.skeleton.avatar,
        avatarSize: any UPSkeletonUnitValue = UPConfig.skeleton.avatarSize,
        avatarShape: String = UPConfig.skeleton.avatarShape,
        customClass: String = UPConfig.skeleton.customClass,
        customStyle: UPStyle = UPConfig.skeleton.customStyle
    ) {
        self.init(
            loading: loading,
            animate: animate,
            rows: rows,
            rowsWidth: rowsWidth,
            rowsHeight: rowsHeight,
            title: title,
            titleWidth: titleWidth,
            titleHeight: titleHeight,
            avatar: avatar,
            avatarSize: avatarSize,
            avatarShape: avatarShape,
            customClass: customClass,
            customStyle: customStyle
        ) {
            EmptyView()
        }
    }

    var showsSkeleton: Bool { loading }

    /// Matches the upstream `rowsArray` computed property. Widths and heights
    /// remain in their raw uview-compatible form; native layout resolves `%`
    /// widths once SwiftUI knows the content width.
    var rowsArray: [UPSkeletonRow] {
        let count = rowCount
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            let rowWidth = resolvedRowWidth(at: index)
            let rowHeight = resolvedRowHeight(at: index)
            let marginTop: String
            if !title && index == 0 {
                marginTop = "0"
            } else if title && index == 0 {
                marginTop = "20px"
            } else {
                marginTop = "12px"
            }
            return UPSkeletonRow(width: rowWidth, height: rowHeight, marginTop: marginTop)
        }
    }

    var resolvedTitleHeight: CGFloat { max(UPUnit.parse(titleHeight), 0) }
    var resolvedAvatarSize: CGFloat { max(UPUnit.parse(avatarSize), 0) }

    /// Native equivalent of the upstream `uTitleWidth` computation.
    func resolvedTitleWidth(in contentWidth: CGFloat) -> CGFloat {
        UPSkeletonDimension.resolveWidth(titleWidth, in: contentWidth)
    }

    /// uview-plus only assigns a border radius for `circle` and `square`.
    var avatarCornerRadius: CGFloat {
        switch avatarShape {
        case "circle": return 100
        case "square": return 4
        default: return 0
        }
    }

    public var body: some View {
        Group {
            if showsSkeleton {
                skeletonMarkup
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .upStyle(customStyle)
    }

    private var skeletonMarkup: some View {
        HStack(alignment: .top, spacing: avatar ? 15 : 0) {
            if avatar {
                UPSkeletonPlaceholder(
                    animate: animate,
                    cornerRadius: avatarCornerRadius
                )
                .frame(width: resolvedAvatarSize, height: resolvedAvatarSize)
            }

            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    if title {
                        UPSkeletonPlaceholder(animate: animate, cornerRadius: 3)
                            .frame(
                                width: max(resolvedTitleWidth(in: proxy.size.width), 0),
                                height: resolvedTitleHeight
                            )
                    }

                    ForEach(Array(rowsArray.enumerated()), id: \.offset) { _, row in
                        UPSkeletonPlaceholder(animate: animate, cornerRadius: 3)
                            .frame(
                                width: max(row.resolvedWidth(in: proxy.size.width), 0),
                                height: row.resolvedHeight
                            )
                            .padding(.top, max(UPUnit.parse(row.marginTop), 0))
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: contentHeight,
                    alignment: .topLeading
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: contentHeight)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentHeight: CGFloat {
        var height: CGFloat = title ? resolvedTitleHeight : 0
        for row in rowsArray {
            height += max(UPUnit.parse(row.marginTop), 0) + row.resolvedHeight
        }
        return max(height, 0)
    }

    private var rowLimit: Double {
        let parsed = Double(rows.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return parsed.isFinite && parsed > 0 ? parsed : 0
    }

    private var rowCount: Int {
        guard rowLimit > 0, rowLimit < Double(Int.max) else { return 0 }
        return Int(rowLimit.rounded(.up))
    }

    private func resolvedRowWidth(at index: Int) -> String {
        let fallback = isUpstreamLastRow(index) ? "70%" : "100%"
        switch rowsWidth {
        case let .single(value):
            return isUpstreamLastRow(index) ? "70%" : value.value
        case let .multiple(values):
            guard index < values.count, !values[index].isJavaScriptFalsy else {
                return fallback
            }
            return values[index].value
        }
    }

    private func resolvedRowHeight(at index: Int) -> String {
        switch rowsHeight {
        case let .single(value):
            return value.value
        case let .multiple(values):
            guard index < values.count, !values[index].isJavaScriptFalsy else {
                return "18px"
            }
            return values[index].value
        }
    }

    private func isUpstreamLastRow(_ index: Int) -> Bool {
        Double(index) == rowLimit - 1
    }

}

private enum UPSkeletonDimension {
    static func resolveWidth(_ rawValue: String, in containerWidth: CGFloat) -> CGFloat {
        guard rawValue.hasSuffix("%") else {
            return UPUnit.parse(rawValue)
        }

        let percentage = Double(rawValue.dropLast()) ?? 0
        return containerWidth * CGFloat(Int(percentage)) / 100
    }
}

private struct UPSkeletonPlaceholder: View {
    let animate: Bool
    let cornerRadius: CGFloat

    @State private var shimmerMoved = false

    private let skeletonColor = Color(red: 47.0 / 255.0, green: 49.0 / 255.0, blue: 53.0 / 255.0)
    private let shimmerColor = Color.white.opacity(0.12)

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [skeletonColor, shimmerColor, skeletonColor],
                    startPoint: shimmerMoved ? .trailing : .leading,
                    endPoint: shimmerMoved ? .leading : .trailing
                )
            )
            .onAppear {
                guard animate else { return }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    shimmerMoved = true
                }
            }
    }
}
