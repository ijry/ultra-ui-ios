import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/dropdown/dropdown`。
@MainActor
struct DropdownDemoView: View {
    private static let options1 = [
        UPDropdownOption(value: "1", title: "默认排序"),
        UPDropdownOption(value: "2", title: "距离优先"),
        UPDropdownOption(value: "3", title: "价格优先")
    ]

    private static let options2 = [
        UPDropdownOption(value: "1", title: "去冰"),
        UPDropdownOption(value: "2", title: "加冰"),
        UPDropdownOption(value: "3", title: "正常温"),
        UPDropdownOption(value: "4", title: "加热"),
        UPDropdownOption(value: "5", title: "极寒风暴")
    ]

    private static let attributes = [
        "琪花瑶草", "清词丽句", "宛转蛾眉", "煦色韶光", "鱼沉雁落", "章台杨柳", "霞光万道"
    ]

    private static let activeColors = ["#2979ff", "#ff9900", "#19be6b"]

    @State private var value1 = ""
    @State private var value2 = "2"
    @State private var activeAttribute = "琪花瑶草"
    @State private var eventLog = "尚未操作"
    @State private var borderBottomIndex = 1
    @State private var activeColorIndex = 0
    @State private var maskClickableIndex = 0

    private var borderBottom: Bool { borderBottomIndex == 0 }
    private var activeColor: String { Self.activeColors[activeColorIndex] }
    private var closeOnClickMask: Bool { maskClickableIndex == 0 }

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                tip("点标题展开对应子项的下拉面板，面板下方是半透明遮罩；再点同一项收起（closeOnClickSelf）。")

                UPDropdown(
                    items: menuItems,
                    activeColor: activeColor,
                    closeOnClickMask: closeOnClickMask,
                    borderBottom: borderBottom
                )
                .onOpen { index in eventLog = "open：第\(index + 1)项" }
                .onClose { index in eventLog = "close：第\(index + 1)项" }
                .frame(height: 300, alignment: .top)

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("value1=\(value1.isEmpty ? "未选择" : value1)　value2=\(value2)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义插槽") {
                tip("子项给了默认插槽后不再渲染内建 cell 列表，这里放一个属性标签墙。")

                UPDropdown(items: [slottedItem], borderBottom: true)
                    .frame(height: 320, alignment: .top)
            }

            DemoSection("参数配置") {
                Text("下边框")
                    .font(.system(size: 13))
                UPSubsection(list: ["有", "无"], current: $borderBottomIndex)

                Text("激活颜色")
                    .font(.system(size: 13))
                UPSubsection(list: Self.activeColors, current: $activeColorIndex)

                Text("遮罩是否可点击")
                    .font(.system(size: 13))
                UPSubsection(list: ["是", "否"], current: $maskClickableIndex)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPDropdown 对齐上游 11 个 props、open / close 两个事件与 highlight() 方法：标题栏按上游取色顺序（禁用 → 激活或高亮 → 未激活）着色，箭头激活时转 180°，面板从标题栏下方下滑展开、下方铺半透明遮罩，遮罩高度按「窗口高度 - 标题栏底部」算。照抄上游两处反直觉：current 的未展开哨兵值是 99999 而不是 -1（上游注释说明小程序端不能用 false/''），未激活项的箭头取的是 menuDisabledColor 而不是 inactiveColor。UPDropdownItem 对齐 6 个 props、change 事件与默认插槽，选中项文字换激活色、右侧补 checkbox-mark 对勾；上游 closeOnClickOverlay 由父组件的 closeOnClickMask 实际生效，子项这个 prop 只保留参数。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var menuItems: [UPDropdownItem] {
        [
            UPDropdownItem(title: "距离", options: Self.options1, modelValue: $value1),
            UPDropdownItem(title: "温度", options: Self.options2, modelValue: $value2),
            UPDropdownItem(title: "属性")
        ]
    }

    private var slottedItem: UPDropdownItem {
        UPDropdownItem(title: "属性", height: 220).content {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Self.attributes, id: \.self) { attribute in
                        let selected = attribute == activeAttribute
                        UPTag(
                            type: selected ? "primary" : "info",
                            size: "mini",
                            text: attribute,
                            plain: !selected,
                            onTap: { activeAttribute = attribute }
                        )
                    }
                }

                UPButton(type: "primary", text: "确定") {
                    eventLog = "确定：\(activeAttribute)"
                    UPToast.show(message: "已选择 \(activeAttribute)")
                }
            }
            .padding(12)
            .background(Color.white)
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
