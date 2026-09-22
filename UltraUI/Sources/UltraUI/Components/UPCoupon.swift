import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-coupon` `amount` prop.
public typealias UPCouponAmountValue = UPImageUnitValue

/// SwiftUI requires views to be value types, so the mutable claim state lives in
/// a small reference box rather than making the view itself a class.
@MainActor
@Observable
private final class UPCouponState {
    var isClaimed = false
}

/// Native SwiftUI counterpart of uview-plus `u-coupon`.
///
/// 上游是「左金额 + 中描述 + 右操作」三段式券面：`shape` 决定券形（`coupon` 左右挖圆缺口、
/// `envelope` 顶部斜纹加一根绳子、`card` 纯圆角），`size` 决定高度，`type` 命中内置主题时
/// 换成渐变底 + 白字，右侧默认放一个 `up-tag`。原生按同一套规则重绘。
@MainActor
public struct UPCoupon: View {
    /// 仓库既有字段：券 id。
    public let id: String
    /// 上游 `amount`。
    public let amount: String
    public let unit: String
    /// 上游 `unitPosition`：`left` / `right`。
    public let unitPosition: String
    public let limit: String
    public let title: String
    public let desc: String
    public let time: String
    public let actionText: String
    /// 上游 `shape`：`coupon` / `envelope` / `card`。
    public let shape: String
    /// 上游 `size`：`small` / `medium` / `large`。
    public let size: String
    public let circle: Bool
    public let disabled: Bool
    public let bgColor: String
    public let color: String
    /// 上游 `type`：命中 `primary` / `success` / `warning` / `error` 时换渐变主题。
    public let type: String
    /// 仓库既有字段：`amount` 的数值形态。
    public let value: Double
    public var isClaimed: Bool { state.isClaimed }

    @State private var state: UPCouponState
    private var onClaimHandler: ((UPCoupon) -> Void)?
    private var onClickHandler: (() -> Void)?
    private var amountSlot: ((String) -> AnyView)?
    private var unitSlot: ((String, String) -> AnyView)?
    private var limitSlot: ((String) -> AnyView)?
    private var titleSlot: ((String) -> AnyView)?
    private var descSlot: ((String) -> AnyView)?
    private var timeSlot: ((String) -> AnyView)?
    private var actionSlot: ((String, Bool) -> AnyView)?
    private var contentSlot: AnyView?

    @Environment(\.upTheme) private var theme

    /// 仓库既有签名。
    public init(id: String = "",
                title: String = "",
                value: Double = 0,
                claimed: Bool = false,
                onClaim: ((UPCoupon) -> Void)? = nil) {
        self.init(id: id,
                  amount: value == 0 ? "" : String(value),
                  title: title,
                  onClaim: onClaim)
        self.state.isClaimed = claimed
    }

    /// 与上游 `props` 对齐的初始化器。
    public init(id: String = "",
                amount: any UPCouponAmountValue = UPConfig.coupon.amount,
                unit: String = UPConfig.coupon.unit,
                unitPosition: String = UPConfig.coupon.unitPosition,
                limit: String = UPConfig.coupon.limit,
                title: String = UPConfig.coupon.title,
                desc: String = UPConfig.coupon.desc,
                time: String = UPConfig.coupon.time,
                actionText: String = UPConfig.coupon.actionText,
                shape: String = UPConfig.coupon.shape,
                size: String = UPConfig.coupon.size,
                circle: Bool = UPConfig.coupon.circle,
                disabled: Bool = UPConfig.coupon.disabled,
                bgColor: String = UPConfig.coupon.bgColor,
                color: String = UPConfig.coupon.color,
                type: String = UPConfig.coupon.type,
                onClick: (() -> Void)? = nil,
                onClaim: ((UPCoupon) -> Void)? = nil) {
        self.id = id
        self.amount = amount.upImageUnitValue
        self.unit = unit
        self.unitPosition = unitPosition
        self.limit = limit
        self.title = title
        self.desc = desc
        self.time = time
        self.actionText = actionText
        self.shape = shape
        self.size = size
        self.circle = circle
        self.disabled = disabled
        self.bgColor = bgColor
        self.color = color
        self.type = type
        self.value = Double(amount.upImageUnitValue) ?? 0
        self.onClaimHandler = onClaim
        self.onClickHandler = onClick
        self._state = State(initialValue: UPCouponState())
    }

    // MARK: - 解析后的呈现值

    /// 上游 `dotCount`：按尺寸给出的锯齿数量，未命中时回落 10。
    public var dotCount: Int {
        switch size {
        case "small": return UPConfig.coupon.smallDotCount
        case "large": return UPConfig.coupon.largeDotCount
        default: return UPConfig.coupon.mediumDotCount
        }
    }

    /// 上游 `--small/--medium/--large` 的高度。
    public var resolvedHeight: CGFloat {
        switch size {
        case "small": return UPConfig.coupon.smallHeight
        case "large": return UPConfig.coupon.largeHeight
        default: return UPConfig.coupon.mediumHeight
        }
    }

    /// 上游内置主题的渐变端色，未命中 `type` 时返回 nil。
    public var gradientColors: [String]? {
        switch type {
        case "primary": return UPConfig.coupon.primaryGradient
        case "success": return UPConfig.coupon.successGradient
        case "warning": return UPConfig.coupon.warningGradient
        case "error": return UPConfig.coupon.errorGradient
        default: return nil
        }
    }

    /// 上游主题类会把整块文字刷白，同时 `couponStyle.color` 优先级更高。
    public var resolvedTextColor: String {
        if !color.isEmpty { return color }
        return gradientColors != nil ? "#ffffff" : "main"
    }

    /// 上游 `__amount-value` 无 type 时写死红色，有 type 时被主题类刷白。
    public var resolvedAmountColor: String {
        if !color.isEmpty { return color }
        return gradientColors != nil ? "#ffffff" : UPConfig.coupon.amountColor
    }

    /// 上游 `__amount` 右侧虚线：无 type 用 `#ccc`，有 type 被主题类改成 `#eee`。
    public var resolvedDashColor: String {
        gradientColors != nil ? UPConfig.coupon.dashColorOnType : UPConfig.coupon.dashColor
    }

    /// 上游默认 action 插槽里 `up-tag` 的两个配色：`type` 非空时透明底 + `#eee` 边框。
    public var actionTagBackgroundColor: String {
        type.isEmpty ? UPConfig.coupon.tagBgColor : "transparent"
    }

    public var actionTagBorderColor: String {
        type.isEmpty ? UPConfig.coupon.tagBgColor : UPConfig.coupon.tagBorderColorOnType
    }

    /// 上游模板 `unitPosition === 'left'` / `'right'`。
    public var showsUnitBeforeAmount: Bool { unitPosition == "left" }

    /// 仓库既有拼接：把单位与金额按位置拼成一串。
    public var displayAmount: String {
        guard !amount.isEmpty else { return "" }
        return showsUnitBeforeAmount ? unit + amount : amount + unit
    }

    // MARK: - 事件

    public func onClaim(_ action: @escaping (UPCoupon) -> Void) -> UPCoupon {
        var copy = self
        copy.onClaimHandler = action
        return copy
    }

    /// 对应上游 `click` 事件。上游 `handleClick` 在 `disabled` 时直接 return。
    public func onClick(_ action: @escaping () -> Void) -> UPCoupon {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public func claim() {
        guard !isClaimed, !disabled else { return }
        state.isClaimed = true
        onClaimHandler?(self)
    }

    /// 上游 `handleClick()`。
    public func click() {
        guard !disabled else { return }
        onClickHandler?()
    }

    // MARK: - 插槽

    /// 对应上游作用域插槽 `amount`。
    public func amountContent<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPCoupon {
        var copy = self
        copy.amountSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游作用域插槽 `unit`，参数是 `unit` 与 `unitPosition`。
    public func unitContent<Slot: View>(@ViewBuilder _ builder: @escaping (String, String) -> Slot) -> UPCoupon {
        var copy = self
        copy.unitSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游作用域插槽 `limit`。
    public func limitContent<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPCoupon {
        var copy = self
        copy.limitSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游作用域插槽 `title`。
    public func titleContent<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPCoupon {
        var copy = self
        copy.titleSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游作用域插槽 `desc`。
    public func descContent<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPCoupon {
        var copy = self
        copy.descSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游作用域插槽 `time`。
    public func timeContent<Slot: View>(@ViewBuilder _ builder: @escaping (String) -> Slot) -> UPCoupon {
        var copy = self
        copy.timeSlot = { AnyView(builder($0)) }
        return copy
    }

    /// 对应上游作用域插槽 `action`，参数是 `actionText` 与 `circle`。
    public func actionContent<Slot: View>(@ViewBuilder _ builder: @escaping (String, Bool) -> Slot) -> UPCoupon {
        var copy = self
        copy.actionSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游默认插槽：叠在券面之上的额外内容。
    public func content<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPCoupon {
        var copy = self
        copy.contentSlot = AnyView(builder())
        return copy
    }

    public var hasAmountSlot: Bool { amountSlot != nil }
    public var hasUnitSlot: Bool { unitSlot != nil }
    public var hasLimitSlot: Bool { limitSlot != nil }
    public var hasTitleSlot: Bool { titleSlot != nil }
    public var hasDescSlot: Bool { descSlot != nil }
    public var hasTimeSlot: Bool { timeSlot != nil }
    public var hasActionSlot: Bool { actionSlot != nil }
    public var hasContentSlot: Bool { contentSlot != nil }

    // MARK: - 视图

    public var body: some View {
        couponBody
            .frame(height: resolvedHeight)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: UPConfig.coupon.cornerRadius, style: .continuous))
            .overlay(alignment: .top) { envelopeStripe }
            .overlay { notches }
            // 上游 `--disabled { opacity: 0.5 }`。
            .opacity(disabled ? UPConfig.coupon.disabledOpacity : 1)
            .contentShape(Rectangle())
            .onTapGesture { click() }
    }

    private var couponBody: some View {
        HStack(spacing: 0) {
            amountColumn
            infoColumn
            actionColumn
        }
        .padding(.horizontal, UPUnit.rpx(CGFloat(30)))
        .overlay { contentSlot }
    }

    /// 上游 `__amount`：单位、金额、门槛竖排，右侧一条虚线分隔。
    private var amountColumn: some View {
        VStack(alignment: .leading, spacing: UPUnit.rpx(CGFloat(10))) {
            if showsUnitBeforeAmount { unitText }
            amountText
            if !showsUnitBeforeAmount { unitText }
            limitText
        }
        .padding(.leading, UPUnit.rpx(CGFloat(10)))
        .padding(.trailing, UPUnit.rpx(CGFloat(30)))
        .overlay(alignment: .trailing) {
            UPLine(color: resolvedDashColor, direction: "col", dashed: true)
        }
    }

    @ViewBuilder
    private var unitText: some View {
        if let unitSlot {
            unitSlot(unit, unitPosition)
        } else {
            Text(unit)
                .font(.system(size: UPConfig.coupon.unitFontSize))
                .foregroundStyle(UPColor.parse(resolvedTextColor, theme: theme))
        }
    }

    @ViewBuilder
    private var amountText: some View {
        if let amountSlot {
            amountSlot(amount)
        } else {
            Text(amount)
                .font(.system(size: UPConfig.coupon.amountFontSize, weight: .bold))
                .foregroundStyle(UPColor.parse(resolvedAmountColor, theme: theme))
        }
    }

    @ViewBuilder
    private var limitText: some View {
        if let limitSlot {
            limitSlot(limit)
        } else if !limit.isEmpty {
            Text(limit)
                .font(.system(size: UPConfig.coupon.limitFontSize))
                .foregroundStyle(UPColor.parse(resolvedTextColor, theme: theme))
                .opacity(0.9)
        }
    }

    /// 上游 `__info`：标题、描述、有效期竖排。
    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: UPUnit.rpx(CGFloat(10))) {
            if let titleSlot {
                titleSlot(title)
            } else {
                Text(title)
                    .font(.system(size: UPConfig.coupon.titleFontSize, weight: .bold))
                    .foregroundStyle(UPColor.parse(resolvedTextColor, theme: theme))
            }

            if let descSlot {
                descSlot(desc)
            } else if !desc.isEmpty {
                Text(desc)
                    .font(.system(size: UPConfig.coupon.descFontSize))
                    .foregroundStyle(UPColor.parse(resolvedTextColor, theme: theme))
                    .opacity(0.9)
            }

            if let timeSlot {
                timeSlot(time)
            } else if !time.isEmpty {
                Text(time)
                    .font(.system(size: UPConfig.coupon.timeFontSize))
                    .foregroundStyle(UPColor.parse(resolvedTextColor, theme: theme))
                    .opacity(0.8)
            }
        }
        .padding(.leading, UPUnit.rpx(CGFloat(30)))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 上游 `__action`：默认放一个 error 型 `up-tag`。
    ///
    /// 照抄上游：`shape` 那句三元 `circle ? 'circle' : 'circle'` 两边一样，
    /// 也就是标签恒为圆角胶囊，`circle` 实际不影响外观。
    private var actionColumn: some View {
        Group {
            if let actionSlot {
                actionSlot(actionText, circle)
            } else {
                UPTag(type: "error",
                      size: "medium",
                      shape: "circle",
                      text: actionText,
                      bgColor: actionTagBackgroundColor,
                      borderColor: actionTagBorderColor,
                      borderRadius: UPConfig.coupon.tagBorderRadius)
            }
        }
        .padding(.trailing, UPUnit.rpx(CGFloat(20)))
    }

    @ViewBuilder
    private var background: some View {
        if !bgColor.isEmpty {
            UPColor.parse(bgColor, theme: theme)
        } else if let gradientColors {
            LinearGradient(colors: gradientColors.map { UPColor.parse($0, theme: theme) },
                           startPoint: .leading,
                           endPoint: .trailing)
        } else {
            UPColor.parse(UPConfig.coupon.defaultBackground, theme: theme)
        }
    }

    /// 上游 `--envelope::before`：顶部一条 20rpx 的斜纹。绳子（`__rope`）在券外，
    /// 会被 `overflow: hidden` 裁掉，因此原生只画斜纹。
    @ViewBuilder
    private var envelopeStripe: some View {
        if shape == "envelope" {
            LinearGradient(colors: [
                UPColor.parse(UPConfig.coupon.ropeStartColor, theme: theme),
                UPColor.parse(UPConfig.coupon.ropeEndColor, theme: theme)
            ], startPoint: .leading, endPoint: .trailing)
            .frame(height: UPConfig.coupon.envelopeStripeHeight)
        }
    }

    /// 上游 `--coupon::before/::after`：左右各一个 48rpx 的白色半圆缺口。
    @ViewBuilder
    private var notches: some View {
        if shape == "coupon" {
            HStack {
                notch
                Spacer()
                notch
            }
            .padding(.horizontal, -UPConfig.coupon.notchSize / 2)
        }
    }

    private var notch: some View {
        Circle()
            .fill(Color.white)
            .frame(width: UPConfig.coupon.notchSize, height: UPConfig.coupon.notchSize)
    }
}
