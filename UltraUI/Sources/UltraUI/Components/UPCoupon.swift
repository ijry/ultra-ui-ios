import SwiftUI

@MainActor
public final class UPCoupon: View {
    public let id: String
    public let amount: String
    public let unit: String
    public let unitPosition: String
    public let limit: String
    public let title: String
    public let desc: String
    public let time: String
    public let actionText: String
    public let shape: String
    public let size: String
    public let circle: Bool
    public let disabled: Bool
    public let bgColor: String
    public let color: String
    public let type: String
    public let value: Double
    public private(set) var isClaimed = false
    private var onClaimHandler: ((UPCoupon) -> Void)?
    private var onClickHandler: (() -> Void)?

    public convenience init(id: String = "", title: String = "", value: Double = 0, claimed: Bool = false, onClaim: ((UPCoupon) -> Void)? = nil) {
        self.init(id: id, amount: value == 0 ? "" : String(value), title: title, onClaim: onClaim)
        self.isClaimed = claimed
    }
    public init(id: String = "", amount: String, unit: String = "￥", unitPosition: String = "left",
                limit: String = "", title: String = "优惠券", desc: String = "", time: String = "",
                actionText: String = "使用", shape: String = "coupon", size: String = "medium",
                circle: Bool = false, disabled: Bool = false, bgColor: String = "", color: String = "",
                type: String = "", onClick: (() -> Void)? = nil, onClaim: ((UPCoupon) -> Void)? = nil) {
        self.id = id; self.amount = amount; self.unit = unit; self.unitPosition = unitPosition; self.limit = limit; self.title = title; self.desc = desc; self.time = time; self.actionText = actionText; self.shape = shape; self.size = size; self.circle = circle; self.disabled = disabled; self.bgColor = bgColor; self.color = color; self.type = type; self.value = Double(amount) ?? 0; self.onClaimHandler = onClaim; self.onClickHandler = onClick
    }
    public func onClaim(_ action: @escaping (UPCoupon) -> Void) -> UPCoupon { onClaimHandler = action; return self }
    public func onClick(_ action: @escaping () -> Void) -> UPCoupon { onClickHandler = action; return self }
    public func claim() { guard !isClaimed, !disabled else { return }; isClaimed = true; onClaimHandler?(self) }
    public func click() { guard !disabled else { return }; onClickHandler?() }
    public var body: some View { HStack { VStack(alignment: .leading) { Text(title); if !amount.isEmpty { Text(unitPosition == "right" ? "\(amount)\(unit)" : "\(unit)\(amount)").font(.title3) }; if !desc.isEmpty { Text(desc).font(.caption) }; if !time.isEmpty { Text(time).font(.caption2) } }; Spacer(); Button(actionText) { self.click() }.disabled(disabled) }.padding().foregroundStyle(color.isEmpty ? .primary : UPColor.parse(color)).background(bgColor.isEmpty ? Color.secondary.opacity(0.12) : UPColor.parse(bgColor)).clipShape(RoundedRectangle(cornerRadius: 8)) }
}
