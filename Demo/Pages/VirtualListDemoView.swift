import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/virtualList/virtualList`。
@MainActor
struct VirtualListDemoView: View {
    private static let items = Array(0..<10_000)

    @State private var offset: CGFloat = 0

    var body: some View {
        DemoPage {
            DemoSection("基本使用") {
                Text("10,000 条数据，固定行高 49pt")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPVirtualList(listData: Self.items,
                              itemHeight: 49,
                              height: "360",
                              buffer: 4,
                              scrollTop: $offset,
                              key: { "item-\($0)" }) { item in
                    HStack {
                        Text("Item \(item)")
                            .font(.system(size: 15))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                }

                Text("scrollTop：\(Int(offset))pt")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPVirtualList 已覆盖上游 6 个 prop：listData / itemHeight / height / buffer / keyField / scrollTop，`update:scrollTop` 落成 scrollTop 绑定、`scroll` 落成 onScroll，作用域插槽即 content 闭包。区间算法照抄上游：remain = ceil(容器高 / itemHeight)、visibleCount = remain + buffer、起点再往前退 buffer / 2，visibleRange / topSpacer / bottomSpacer 都可单测。渲染改用 LazyVStack（本身只实例化可见行），因此不再需要上下占位视图；height 为 100% 或 vh 时交给父级，量不到容器时按上游兜底 500。keyField 在 Swift 里无法从任意 Item 反射取字段，改用可选的 key 闭包，缺省退回下标（与上游 getItemKey 的兜底一致）。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
