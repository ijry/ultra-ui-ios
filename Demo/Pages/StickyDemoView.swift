import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/sticky/sticky`。
@MainActor
struct StickyDemoView: View {
    @State private var fixedLog = "尚未吸顶"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DemoSection("基础使用") {
                    UPText(type: "content", text: "滚动页面,即可看到下方的按钮会吸顶。")

                    Text("状态：\(fixedLog)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("stickyTop = offsetTop + customNavHeight，minY 小于等于它即进入吸顶。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                stickyBar

                DemoSection("offsetTop 与自定义导航栏") {
                    Text("offsetTop 与 customNavHeight 相加得到吸顶阈值；H5 端 customNavHeight 默认 44，iOS 侧默认 0。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                offsetBar

                DemoSection("disabled") {
                    Text("disabled 为真时恒不吸顶，setFixed 也不会翻标记。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                disabledBar

                UPGap(height: 1500)

                UPDivider(text: "已到底部")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .coordinateSpace(name: Self.scrollSpace)
    }

    private static let scrollSpace = "sticky-demo-scroll"

    private var stickyBar: some View {
        let sticky = UPSticky(offsetTop: 0, bgColor: "#ffffff", index: "sticky-demo") {
            UPButton(type: "success", text: "吸顶按钮", block: true)
                .padding(.vertical, 8)
        }
        .onFixed { change in
            fixedLog = change.isFixed ? "已吸顶(\(change.index))" : "未吸顶"
        }

        return sticky
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .named(Self.scrollSpace)).minY) { _, newValue in
                            sticky.report(minY: newValue)
                        }
                }
            }
    }

    private var offsetBar: some View {
        let sticky = UPSticky(offsetTop: 20, customNavHeight: 44, bgColor: "#ecf5ff", index: "offset-demo") {
            UPButton(type: "primary", text: "offsetTop 20 + navHeight 44", block: true)
                .padding(.vertical, 8)
        }
        let threshold = Int(sticky.stickyTop)
        let bar = sticky.onFixed { change in
            fixedLog = change.isFixed ? "已吸顶(\(change.index))，阈值 \(threshold)" : "未吸顶"
        }

        return bar.background(probe(for: bar))
    }

    private var disabledBar: some View {
        UPSticky(offsetTop: 0, disabled: true, bgColor: "#fff7e6", index: "disabled-demo") {
            UPButton(text: "disabled 不吸顶", block: true)
                .padding(.vertical, 8)
        }
    }

    private func probe<C: View>(for sticky: UPSticky<C>) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onChange(of: proxy.frame(in: .named(Self.scrollSpace)).minY) { _, newValue in
                    sticky.setFixed(top: newValue)
                }
        }
    }
}
