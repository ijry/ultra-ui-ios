import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/goodsSku/goodsSku`。
@MainActor
struct GoodsSkuDemoView: View {
    private static let goodsInfo = UPGoodsInfo(image: "https://uview-plus.jiangruyi.com/uview/ext/200.jpg",
                                               price: 99,
                                               stock: 100,
                                               title: "示例商品")

    /// 对应上游 `skuTree`：两个维度，叶子带 id 与展示名。
    private static let skuTree = [
        UPGoodsSkuTreeItem(name: "color", label: "颜色", children: [
            UPGoodsSkuLeaf(id: "1", name: "红色"),
            UPGoodsSkuLeaf(id: "2", name: "蓝色"),
            UPGoodsSkuLeaf(id: "3", name: "黑色")
        ]),
        UPGoodsSkuTreeItem(name: "size", label: "尺寸", children: [
            UPGoodsSkuLeaf(id: "s", name: "S"),
            UPGoodsSkuLeaf(id: "m", name: "M"),
            UPGoodsSkuLeaf(id: "l", name: "L"),
            UPGoodsSkuLeaf(id: "xl", name: "XL")
        ])
    ]

    /// 对应上游 `skuList` 的 5 条组合。
    private static let skuList = [
        UPGoodsSkuItem(selections: ["color": "1", "size": "s"], stock: 50, price: 99),
        UPGoodsSkuItem(selections: ["color": "1", "size": "m"], stock: 40, price: 99),
        UPGoodsSkuItem(selections: ["color": "2", "size": "s"], stock: 30, price: 109),
        UPGoodsSkuItem(selections: ["color": "2", "size": "l"], stock: 20, price: 109),
        UPGoodsSkuItem(selections: ["color": "3", "size": "xl"], stock: 60, price: 89)
    ]

    @State private var basicSku = GoodsSkuDemoView.makeSku()
    @State private var maxBuySku = GoodsSkuDemoView.makeSku(maxBuy: 10)
    @State private var buyNowSku = GoodsSkuDemoView.makeSku(confirmText: "立即购买")
    @State private var result = "尚未确认"
    @State private var tick = 0

    private static func makeSku(maxBuy: Int = 999,
                                confirmText: String = "确定",
                                pageInline: Bool = false) -> UPGoodsSku {
        UPGoodsSku(goodsInfo: goodsInfo,
                   skuTree: skuTree,
                   skuList: skuList,
                   maxBuy: maxBuy,
                   confirmText: confirmText,
                   pageInline: pageInline)
    }

    var body: some View {
        DemoPage {
            DemoSection("基本使用") {
                basicSku
                    .trigger { UPButton(type: "primary", text: "选择规格") }
                    .id(tick)

                tip(result)
                tip("弹窗顶部由 goodsInfo 渲染图 / 价 / 库存 / 已选，库存为 0 的组合会置灰。")
            }

            DemoSection("自定义最大购买数量") {
                maxBuySku
                    .trigger { UPButton(type: "warning", text: "maxBuy = 10") }
                    .id(tick)

                tip("maxBuyNum = min(maxBuy, 所选组合库存)：红色 S 有 50 件也只能买 10 件。")
            }

            DemoSection("自定义确认按钮文字") {
                buyNowSku
                    .trigger { UPButton(type: "error", text: "立即购买") }
                    .id(tick)
            }

            DemoSection("页面内联模式") {
                Self.makeSku(pageInline: true)
                    .onConfirmEvent { event in
                        result = "confirm：\(event.selectedText) × \(event.num)"
                    }

                tip("pageInline 为真时 created 里直接 show = true，不再弹层、也不显示关闭按钮。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPGoodsSku 已覆盖上游 7 个 prop：goodsInfo / skuTree / skuList / maxBuy / confirmText / closeable / pageInline，事件为 onOpen / onConfirmEvent((UPGoodsSkuConfirmEvent) -> Void) / onClose / onClosed（另保留仓库既有的 onChange / onConfirm / onConfirmPayload），方法 open() / close() / reset() / select(_:value:) / setQuantity(_:) / confirm()，插槽 trigger / header。派生值与上游一一对应：price / stock 选满后取组合值否则取商品值，maxBuyNum = min(maxBuy, stock)，canBuy 要求维度选满且库存为正，selectedSkuText 把选中的叶子名用逗号拼接，isDisabled 按 skuList 判断某取值是否还能组成有效组合。skuTree / skuList / goodsInfo 三个数据 prop 落成 UPGoodsSkuTreeItem / UPGoodsSkuItem / UPGoodsInfo 强类型模型；上游同时读 image/picture、price/price_fee、stock/quantity 两套字段名，原生归一成一套。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        basicSku = basicSku.onConfirmEvent { event in
            result = "confirm：\(event.selectedText) × \(event.num)，单价 ¥\(String(format: "%g", event.sku?.price ?? 0))"
        }
        maxBuySku = maxBuySku.onConfirmEvent { event in
            result = "confirm（maxBuy 10）：\(event.selectedText) × \(event.num)"
        }
        buyNowSku = buyNowSku.onConfirmEvent { event in
            result = "立即购买：\(event.selectedText) × \(event.num)"
        }
        tick += 1
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
