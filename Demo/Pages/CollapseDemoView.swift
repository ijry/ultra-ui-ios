import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/collapse/collapse`。
@MainActor
struct CollapseDemoView: View {
    @State private var changeLog = "尚未变化"
    @State private var openLog = "尚未展开"
    @State private var closeLog = "尚未收起"

    private let text1 = "涵盖uniapp各个方面，给开发者方向指导和设计理念，让您茅塞顿开，一马平川"
    private let text2 = "众多组件覆盖开发过程的各个需求，组件功能丰富，多端兼容。让您快速集成，开箱即用"
    private let text3 = "众多的贴心小工具，是您开发过程中召之即来的利器，让您飞镖在手，百步穿杨"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPCollapse(
                    onChange: { changes in
                        changeLog = changes
                            .map { "\($0.name)=\($0.status.rawValue)" }
                            .joined(separator: "，")
                    },
                    onOpen: { name in openLog = "\(name)" },
                    onClose: { name in closeLog = "\(name)" }
                ) {
                    UPCollapseItem(title: "文档指南", name: "Docs guide") { content(text1) }
                    UPCollapseItem(title: "组件全面", name: "Variety components") { content(text2) }
                    UPCollapseItem(title: "众多利器", name: "Numerous tools", showRight: false) { content(text3) }
                }

                Text("change：\(changeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("open：\(openLog)　close：\(closeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("展开和禁用") {
                UPCollapse(value: ["2"]) {
                    UPCollapseItem(title: "文档指南") { content(text1) }
                    UPCollapseItem(title: "组件全面", disabled: true) { content(text2) }
                    UPCollapseItem(title: "众多利器", name: "2") { content(text3) }
                }
            }

            DemoSection("手风琴模式") {
                UPCollapse(accordion: true) {
                    UPCollapseItem(title: "文档指南") { content(text1) }
                    UPCollapseItem(title: "组件全面") { content(text2) }
                    UPCollapseItem(title: "众多利器") { content(text3) }
                }
            }

            DemoSection("移除下划线") {
                UPCollapse(accordion: true, border: false) {
                    UPCollapseItem(title: "文档指南") { content(text1) }
                    UPCollapseItem(title: "组件全面") { content(text2) }
                    UPCollapseItem(title: "众多利器") { content(text3) }
                }
            }

            DemoSection("自定义标题和内容") {
                UPCollapse(accordion: true) {
                    UPCollapseItem { content(text1) }
                        .title {
                            Text("文档指南")
                                .font(.system(size: 14))
                                .foregroundStyle(UPColor.parse("primary"))
                        }

                    UPCollapseItem(title: "组件全面") { content(text2) }
                        .icon { UPIcon(name: "tags-fill", size: "20") }

                    UPCollapseItem(title: "众多利器", icon: "tags-fill") { content(text3) }
                        .rightIcon {
                            Text("10")
                                .font(.system(size: 14))
                                .foregroundStyle(UPColor.parse("primary"))
                        }
                }
            }

            UPGap(height: 50)
        }
    }

    private func content(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(UPColor.parse("tips"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
