import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/choose/choose`。
@MainActor
struct ChooseDemoView: View {
    private nonisolated static let options = [
        UPChooseOption(value: "a", title: "选项 A"),
        UPChooseOption(value: "b", title: "选项 B"),
        UPChooseOption(value: "c", title: "选项 C")
    ]

    private nonisolated static let manyOptions = (1...8).map {
        UPChooseOption(value: "\($0)", title: "标签 \($0)")
    }

    @State private var single = "a"
    @State private var singleIndex = 0
    @State private var multi = "1"
    @State private var eventLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("单选") {
                tip("上游是按下标工作的：change(index) 往 modelValue 里写的是下标，激活项实心 primary、其余描边 info。")

                UPChoose(
                    options: Self.options,
                    modelValue: $single,
                    currentIndex: $singleIndex
                )
                .onChange { eventLog = "change：下标 \($0)" }

                tip("currentIndex=\(singleIndex)　按值绑定=\(single)")
                tip(eventLog)
            }

            DemoSection("换行与横向滚动") {
                tip("wrap 为真时折行（默认），为假时开横向滚动、不折行。")

                UPChoose(options: Self.manyOptions, modelValue: $multi, wrap: true)

                UPChoose(options: Self.manyOptions, modelValue: $multi, wrap: false)
            }

            DemoSection("尺寸与间距") {
                tip("itemWidth 为 auto 时按内容自适应，给具体值则固定宽度；itemHeight 与 itemPadding 直接落到标签上。")

                UPChoose(
                    options: Self.options,
                    modelValue: $single,
                    itemWidth: "100px",
                    itemHeight: "40px",
                    itemPadding: "4px"
                )
            }

            DemoSection("customClick") {
                tip("customClick 为真时只抛 custom-click（负载是下标），不写回 modelValue，选中态也不变。")

                UPChoose(options: Self.options, customClick: true)
                    .onCustomClick { (index: Int) in eventLog = "custom-click：下标 \(index)" }
            }

            DemoSection("自定义插槽") {
                tip("默认作用域插槽拿到 item 与 index。")

                UPChoose(options: Self.options, modelValue: $single)
                    .itemContent { option, index in
                        HStack(spacing: 4) {
                            Text("\(index + 1).")
                                .font(.system(size: 12))
                                .foregroundStyle(UPColor.parse("tips"))
                            Text(option.title)
                                .font(.system(size: 14))
                                .foregroundStyle(UPColor.parse("primary"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(UPColor.parse("primary"), lineWidth: 0.5)
                        }
                    }
            }

            DemoSection("当前原生范围") {
                Text("原生 UPChoose 对齐上游 10 个 props、custom-click 事件（负载是下标）与默认作用域插槽：标签沿用 UPTag，激活项 primary 实心、其余 info 描边，wrap 为真走折行布局、为假走横向滚动。上游是按下标而不是按值工作的，因此原生同时提供 currentIndex 的下标绑定与仓库既有的按值绑定，change(index) 会把两者一起写回。上游 type 与 valueName 两个 prop 在代码里从未被读取，原生同样只保留参数。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
