import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/floatButton/floatButton`。
@MainActor
struct FloatButtonDemoView: View {
    @State private var basic = UPFloatButton()
    @State private var menu = UPFloatButton(isMenu: true, list: [
        UPFloatButtonItem(id: "plus", name: "plus"),
        UPFloatButtonItem(id: "order", name: "order")
    ])
    @State private var colored = UPFloatButton(
        backgroundColor: "#f9ae3d",
        color: "#ffffff",
        width: "56px",
        height: "56px",
        borderColor: "#fa3534",
        isMenu: true,
        list: [
            UPFloatButtonItem(id: "back-1", name: "arrow-left", backgroundColor: "#5ac725"),
            UPFloatButtonItem(id: "back-2", name: "home", backgroundColor: "#3c9cff")
        ]
    )
    @State private var slotted = UPFloatButton(isMenu: true, list: [
        UPFloatButtonItem(id: "one", name: "star"),
        UPFloatButtonItem(id: "two", name: "heart")
    ])
    @State private var refreshTick = 0
    @State private var lastEvent = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                tip("isMenu 为 false 时只有主按钮，点击只抛 click，不展开子项。")

                basic
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .id(refreshTick)
            }

            DemoSection("带子菜单模式") {
                tip("isMenu 为 true 时点击主按钮切换 showList，默认图标同步旋转 45°，子项在主按钮上方纵向铺开。")

                menu
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 180, alignment: .bottom)
                    .id(refreshTick)

                tip("事件：\(lastEvent)")
            }

            DemoSection("配色与尺寸") {
                tip("backgroundColor / color / width / height / borderColor 作用在主按钮上；子项没给配色时回退到组件的值。")

                colored
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 200, alignment: .bottom)
                    .id(refreshTick)
            }

            DemoSection("默认插槽") {
                tip("默认作用域插槽拿到 showList，可以自己决定主按钮长什么样。")

                slotted
                    .content { showList in
                        UPIcon(name: showList ? "close" : "list", color: "#ffffff", size: "20")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 180, alignment: .bottom)
                    .id(refreshTick)
            }

            DemoSection("固定定位") {
                tip("上游用 position: fixed 加 right / top / bottom 把按钮钉在屏幕角上。原生下这三个值只是解析后的数值，实际摆放交给页面用 overlay 或 ZStack 决定。")

                let pinned = UPFloatButton(right: "30px", bottom: "60px", isMenu: true, list: [
                    UPFloatButtonItem(id: "top", name: "arrow-upward")
                ])

                RoundedRectangle(cornerRadius: 8)
                    .fill(UPColor.parse("#f3f4f6"))
                    .frame(height: 200)
                    .overlay(alignment: .bottomTrailing) {
                        pinned
                            .padding(.trailing, UPUnit.parse(pinned.right))
                            .padding(.bottom, UPUnit.parse(pinned.bottom))
                    }
                    .id(refreshTick)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPFloatButton 对齐上游 backgroundColor / color / width / height / borderColor / right / top / bottom / isMenu / list 十个属性，click 与 item-click 两个事件（item-click 负载带 index），以及默认作用域插槽（参数 showList）与具名插槽 list。子项三个配色都按上游 item?.x ? item?.x : x 回退，borderColor 为空串时不画边框。上游用 position: fixed 定位，原生不越权改页面层级，right / top / bottom 只做解析，摆放交给调用方；仓库既有的 items / expanded / toggle / close / select 与 direction 保留。组件内部展开状态用 @Observable 存，但本页把实例放在 @State 里，所以额外带了一个 id 让 SwiftUI 重新求值。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        guard lastEvent == "尚未点击" else { return }
        basic = basic.onClick { lastEvent = "基础按钮：click" }
        menu = menu.onItemClick { (event: UPFloatButtonItemClickEvent) in
            lastEvent = "子菜单点击：\(event.item.name)（index \(event.index)）"
            refreshTick += 1
        }
        colored = colored.onItemClick { (event: UPFloatButtonItemClickEvent) in
            lastEvent = "配色项点击：\(event.item.name)（index \(event.index)）"
            refreshTick += 1
        }
        slotted = slotted.onItemClick { (event: UPFloatButtonItemClickEvent) in
            lastEvent = "插槽项点击：\(event.item.name)（index \(event.index)）"
            refreshTick += 1
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
