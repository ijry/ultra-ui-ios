import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/coupon/coupon`。
@MainActor
struct CouponDemoView: View {
    @State private var eventLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCoupon(
                    amount: "100",
                    limit: "满200可用",
                    title: "满减券",
                    time: "2023-12-31前使用",
                    color: "#333",
                    onClick: { log("基础用法") }
                )

                tip("最近点击：\(eventLog)")
            }

            DemoSection("小尺寸") {
                UPCoupon(
                    amount: "20",
                    title: "满减券",
                    actionText: "去使用",
                    size: "small",
                    onClick: { log("小尺寸") }
                )

                tip("size 三档分别对应 160 / 180 / 220 rpx 高度与 8 / 10 / 12 个锯齿。")
            }

            DemoSection("大尺寸") {
                UPCoupon(
                    amount: "200",
                    unit: "￥",
                    limit: "满500可用",
                    title: "满减券",
                    desc: "仅限VIP用户",
                    time: "有效期至2023-12-31",
                    size: "large",
                    type: "error",
                    onClick: { log("大尺寸") }
                )

                tip("unit 默认就是 ￥，unitPosition=\"left\" 时拼成「￥200」。")
            }

            DemoSection("自定义内容") {
                UPCoupon(
                    amount: "66",
                    title: "自定义券",
                    actionText: "去使用",
                    shape: "card",
                    onClick: { log("自定义内容") }
                )
                .amountContent { amount in
                    Text("\(amount) 元")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(UPColor.parse("error"))
                }
                .titleContent { title in
                    HStack(spacing: 4) {
                        UPIcon(name: "gift", color: "#fa3534", size: "14")
                        Text(title).font(.system(size: 15, weight: .bold))
                    }
                }
                .actionContent { text, _ in
                    UPButton(type: "success", size: "mini", text: text) {
                        log("自定义 action 插槽")
                    }
                }

                tip("amount / unit / limit / title / desc / time / action 七个作用域插槽都可用，另有一个叠在券面之上的默认插槽。")
            }

            DemoSection("圆形按钮") {
                UPCoupon(
                    amount: "30",
                    title: "满减券",
                    actionText: "抢购",
                    circle: true,
                    onClick: { log("圆形按钮") }
                )

                tip("照抄上游：默认 action 标签的 shape 三元两边都是 circle，所以 circle 实际不改变外观。")
            }

            DemoSection("禁用状态") {
                UPCoupon(
                    amount: "50",
                    title: "已过期",
                    desc: "活动已结束",
                    time: "2023-01-01至2023-01-31",
                    disabled: true,
                    onClick: { log("禁用状态") }
                )

                tip("disabled=true 时按钮不可点，click() 与 claim() 都会直接返回。")
            }

            DemoSection("红包样式") {
                UPCoupon(
                    amount: "50",
                    unit: "元",
                    title: "新人红包",
                    desc: "限时专享",
                    shape: "envelope",
                    type: "warning",
                    onClick: { log("红包样式") }
                )

                tip("shape=\"envelope\" 顶部铺一条 20rpx 渐变斜纹；type=\"warning\" 换成橙色渐变底 + 白字。")
            }

            DemoSection("卡片样式") {
                UPCoupon(
                    amount: "88",
                    unit: "折",
                    title: "折扣券",
                    desc: "全场通用",
                    actionText: "立即领取",
                    shape: "card",
                    type: "success",
                    onClick: { log("卡片样式") }
                )

                tip("unit=\"折\" 时拼成「折88」，上游是 unitPosition 决定单位在左还是在右，这里显式传 unitPosition: \"right\" 才会变成「88折」。")
            }

            DemoSection("单位在右") {
                UPCoupon(
                    amount: "88",
                    unit: "折",
                    unitPosition: "right",
                    title: "折扣券",
                    desc: "全场通用",
                    actionText: "立即领取",
                    onClick: { log("单位在右") }
                )
            }

            DemoSection("当前原生范围") {
                Text("原生 UPCoupon 对齐上游 15 个 props、click 事件与全部 8 个插槽：左金额（单位按 unitPosition 决定在左还是在右）、中描述、右侧默认 up-tag 三段式排版按上游字号与间距复刻；shape 为 coupon 时左右各挖一个 48rpx 白色半圆缺口，envelope 时顶部铺一条 20rpx 渐变斜纹，card 为纯圆角；size 三档映射高度与 dotCount；type 命中 primary / success / warning / error 时换成渐变底 + 白字，虚线分隔线也随之从 #ccc 变 #eee，右侧标签换成透明底 + #eee 边框。照抄上游两处反直觉：无 type 时金额颜色写死为红色（不跟随 color 之外的主题），以及默认 action 标签的 shape 三元 circle ? 'circle' : 'circle' 两边一样、circle 实际不影响外观。envelope 的绳子在券外，会被上游自己的 overflow: hidden 裁掉，因此原生也不画。claim() / isClaimed / onClaim 是仓库既有扩展，上游没有对应能力。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func log(_ name: String) {
        eventLog = name
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
