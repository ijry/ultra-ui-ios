import SwiftUI

@MainActor
public final class UPCoupon: View {
    public let id: String; public let title: String; public let value: Double; public private(set) var isClaimed = false
    private var onClaimHandler: ((UPCoupon) -> Void)?
    public init(id: String = "", title: String = "", value: Double = 0, claimed: Bool = false, onClaim: ((UPCoupon) -> Void)? = nil) { self.id = id; self.title = title; self.value = value; self.isClaimed = claimed; self.onClaimHandler = onClaim }
    public func onClaim(_ action: @escaping (UPCoupon) -> Void) -> UPCoupon { onClaimHandler = action; return self }
    public func claim() { guard !isClaimed else { return }; isClaimed = true; onClaimHandler?(self) }
    public var body: some View { HStack { VStack(alignment: .leading) { Text(self.title); Text("¥\(self.value, specifier: "%.0f")").font(.title3) }; Spacer(); Button(self.isClaimed ? "已领取" : "领取") { self.claim() }.disabled(self.isClaimed) }.padding() }
}
