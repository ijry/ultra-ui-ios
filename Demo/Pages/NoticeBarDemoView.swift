import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/noticeBar/noticeBar`。
struct NoticeBarDemoView: View {
    @State private var lastClick = "尚未点击"

    private let text1 = "uview-plus众多组件覆盖开发过程的各个需求，组件功能丰富，多端兼容。让您快速集成，开箱即用"
    private let text2 = "uview-plus众多的贴心小工具，是您开发过程中召之即来的利器，让您飞镖在手，百步穿杨"
    private let text3 = "uview-plus收集众多的常用页面和布局，减少开发者的重复工作，让您专注逻辑，事半功倍"
    private let text4 = [
        "寒雨连江夜入吴",
        "平明送客楚山孤",
        "洛阳亲友如相问",
        "一片冰心在玉壶"
    ]
    private let text5 = "涵盖uniapp各个方面，给开发者方向指导和设计理念，让您茅塞顿开，一马平川"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPNoticeBar(text: text1, fontSize: "30px")
            }

            DemoSection("可关闭") {
                UPNoticeBar(text: text5, mode: "closable")
            }

            DemoSection("自定义横向滚动速度") {
                UPNoticeBar(text: text2, mode: "closable", speed: "250")
            }

            DemoSection("可跳转（点击右箭头）") {
                UPNoticeBar(text: text3, mode: "link", url: "/pages/componentsB/tag/tag")
            }

            DemoSection("横向步进滚动") {
                UPNoticeBar(text: text4, step: true)
                    .onClick { index in
                        lastClick = "步进滚动第 \(index + 1) 条"
                    }
            }

            DemoSection("纵向滚动") {
                UPNoticeBar(text: text4, direction: "column")
                    .onClick { index in
                        lastClick = "纵向滚动第 \(index + 1) 条"
                    }
            }

            DemoSection("纵向滚动（文字居中）") {
                UPNoticeBar(text: text4, direction: "column", justifyContent: "center")
                    .onClick { index in
                        lastClick = "居中滚动第 \(index + 1) 条"
                    }
            }

            DemoSection("自定义样式") {
                UPNoticeBar(text: text1, color: "#ffffff", bgColor: "#f56c6c")
            }

            DemoSection("单独的行/列公告") {
                UPRowNotice(text: text4, mode: "closable")

                UPColumnNotice(text: text4, current: 1, justifyContent: "center")

                Text("点击事件：\(lastClick)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("已展示文本数组、方向、步进、mode 图标、颜色与字号。滚动动画本身与 url 跳转目前仅保留兼容 API。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
