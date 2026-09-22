import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/waterfall/waterfall`。
@MainActor
struct WaterfallDemoView: View {
    private struct Goods: Identifiable, Equatable {
        let id: Int
        var price: Int
        var title: String
        var shop: String
        var image: String
        var favorite = false
    }

    private nonisolated static let baseURL = "https://uview-plus.jiangruyi.com/uview/swiper/"

    private nonisolated static let titles: [String] = [
        "北国风光，千里冰封，万里雪飘",
        "望长城内外，惟余莽莽",
        "大河上下，顿失滔滔",
        "欲与天公试比高",
        "须晴日，看红装素裹，分外妖娆",
        "江山如此多娇，引无数英雄竞折腰",
        "惜秦皇汉武，略输文采",
        "唐宗宋祖，稍逊风骚",
        "一代天骄，成吉思汗",
        "只识弯弓射大雕",
        "俱往矣，数风流人物，还看今朝"
    ]

    private nonisolated static let prices = [35, 75, 385, 784, 7891, 2341, 661, 1654, 1678, 924, 8243]

    private nonisolated static func goods(at index: Int) -> Goods {
        Goods(
            id: index,
            price: prices[index % prices.count],
            title: titles[index % titles.count],
            shop: "李白杜甫白居易旗舰店",
            image: baseURL + "swiper\(index % 3 + 1).png"
        )
    }

    private nonisolated static var initialList: [Goods] { (0..<8).map(goods(at:)) }

    @State private var flowList: [Goods] = WaterfallDemoView.initialList
    @State private var nextID = 8
    @State private var addedLog: [String] = []
    @State private var batchLog = ""

    @State private var columnList: [Goods] = (0..<7).map(WaterfallDemoView.goods(at:))
    @State private var autoList: [Goods] = (0..<9).map(WaterfallDemoView.goods(at:))

    var body: some View {
        DemoPage {
            DemoSection("基础使用（v-model 数据源）") {
                tip("组件按列持有数据：每加一条先量各列真实高度，塞进最短列，等 addTime 毫秒后再量一次并抛 after-add-one。")

                waterfall

                HStack(spacing: 10) {
                    UPButton(type: "primary", size: "small", text: "加载更多") { loadMore() }
                    UPButton(size: "small", text: "重置") { reset() }
                    UPButton(type: "error", size: "small", text: "清空") { flowList = [] }
                }

                if !batchLog.isEmpty {
                    tip(batchLog)
                }

                if !addedLog.isEmpty {
                    tip("after-add-one：" + addedLog.suffix(3).joined(separator: "，"))
                }
            }

            DemoSection("addTime 与三列") {
                tip("addTime 设为 0 时一次性排完；columns 传 3 得到三列。")

                UPWaterfall(modelValue: $autoList, addTime: 0, columns: 3, key: { String($0.id) }) { item in
                    compactCard(item)
                }
            }

            DemoSection("columns='auto' 自适应") {
                tip("auto 模式按容器宽度算列数：floor(width / (minColumnWidth + 7))，再抬到 columnsMin。")

                UPWaterfall(
                    modelValue: $autoList,
                    addTime: 0,
                    columns: "auto",
                    columnsMin: 2,
                    minColumnWidth: 120,
                    key: { String($0.id) }
                ) { item in
                    compactCard(item)
                }
            }

            DemoSection("column 作用域插槽") {
                tip("column 插槽把整列数据交给页面自己渲染，参数是 colIndex 与 colList。")

                UPWaterfall(modelValue: $columnList, addTime: 0, key: { String($0.id) })
                    .column { index, list in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("第 \(index + 1) 列 · \(list.count) 条")
                                .font(.system(size: 12))
                                .foregroundStyle(UPColor.parse("primary"))

                            ForEach(list) { item in
                                compactCard(item)
                            }
                        }
                    }
            }

            DemoSection("当前原生范围") {
                Text("原生 UPWaterfall 对齐上游 modelValue / addTime / idKey / columns / columnsMin / minColumnWidth 六个属性，after-add-one 与 after-add-all 两个事件，column / left 两个作用域插槽，以及 clear / remove / modify 三个方法：列高改用 GeometryReader 量，addTime 用 Task.sleep 逐条追加，换代靠 generation 让旧循环立即退出。上游 idKey 是字符串字段名，Swift 侧没有字符串下标，因此定位用 key 闭包，modify 改哪个字段由 transform 闭包决定。仓库既有的 UPWaterfall(columnCount:columnGap:rowGap:) 形态保留，走自定义 Layout 一次性排布。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var waterfall: some View {
        UPWaterfall(modelValue: $flowList, addTime: 120, key: { String($0.id) }) { item in
            goodsCard(item)
        }
        .onAfterAddOne { item, height in
            addedLog.append("#\(item.id) 列高 \(Int(height))")
        }
        .onAfterAddAll { heights, newData in
            let text = heights.map { String(Int($0)) }.joined(separator: " / ")
            batchLog = "after-add-all：新增 \(newData.count) 条，列高 \(text)"
        }
    }

    private func goodsCard(_ item: Goods) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            UPImage(src: item.image, mode: "aspectFill", width: 150, height: 110)

            Text(item.title)
                .font(.system(size: 13))
                .foregroundStyle(UPColor.parse("main"))
                .padding(.horizontal, 8)
                .padding(.top, 8)

            Text("\(item.price)元")
                .font(.system(size: 15))
                .foregroundStyle(UPColor.parse("error"))
                .padding(.horizontal, 8)
                .padding(.top, 4)

            HStack(spacing: 5) {
                Text("自营")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .background(UPColor.parse("error"))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(item.favorite ? "已收藏" : "放心购")
                    .font(.system(size: 11))
                    .foregroundStyle(UPColor.parse("primary"))
                    .padding(.horizontal, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(UPColor.parse("primary"), lineWidth: 0.5)
                    }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            Text(item.shop)
                .font(.system(size: 11))
                .foregroundStyle(UPColor.parse("tips"))
                .padding(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topLeading) {
            UPIcon(name: item.favorite ? "heart-fill" : "heart", color: "#fa3534", size: "16") {
                modify(item)
            }
            .padding(6)
        }
        .overlay(alignment: .topTrailing) {
            UPIcon(name: "close-circle-fill", color: "#909193", size: "16") {
                flowList.removeAll { $0.id == item.id }
            }
            .padding(6)
        }
    }

    private func compactCard(_ item: Goods) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            UPImage(src: item.image, mode: "aspectFill", width: 88, height: 80)

            Text(item.title)
                .font(.system(size: 12))
                .foregroundStyle(UPColor.parse("main"))

            Text("\(item.price)元")
                .font(.system(size: 13))
                .foregroundStyle(UPColor.parse("error"))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// 对应上游 `modify(id, key, value)`，这里把 `favorite` 取反。
    private func modify(_ item: Goods) {
        guard let index = flowList.firstIndex(where: { $0.id == item.id }) else { return }
        flowList[index].favorite.toggle()
    }

    private func loadMore() {
        for _ in 0..<4 {
            flowList.append(Self.goods(at: nextID))
            nextID += 1
        }
    }

    private func reset() {
        flowList = Self.initialList
        nextID = 8
        addedLog = []
        batchLog = ""
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
