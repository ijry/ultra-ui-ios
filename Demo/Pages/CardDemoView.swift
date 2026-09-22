import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/card/card`。
struct CardDemoView: View {
    @State private var showThumbnail = true
    @State private var cardPadding = 15
    @State private var showFoot = true
    @State private var showBorder = true
    @State private var eventText = "尚未操作"

    private let thumbnail = "https://uview-plus.jiangruyi.com/uview/ext/59c256f85a8c3757.jpg"
    private let title = "素胚勾勒出青花，笔锋浓转淡"
    private let subTitle = "2023-05-15"

    var body: some View {
        DemoPage {
            DemoSection("基础卡片") {
                UPCard(margin: "0", showHead: false, showFoot: false) {
                    Text("尊敬的客户您好，您有来自平台的开票通知。如果有疑问请联系您的客户经理。")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
            }

            DemoSection("高级卡片") {
                UPCard(
                    border: showBorder,
                    index: ["id": 7],
                    padding: cardPadding,
                    paddingHead: "12px",
                    paddingBody: "0",
                    paddingFoot: "2px 15px",
                    showFoot: showFoot,
                    onClick: { _ in
                        eventText = "已触发 click"
                    },
                    onHeadClick: { _ in
                        eventText = "已触发 head-click"
                    },
                    head: {
                        HStack(spacing: 10) {
                            if showThumbnail {
                                UPImage(
                                    src: thumbnail,
                                    mode: "aspectFill",
                                    width: 36,
                                    height: 36,
                                    radius: 4
                                )
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(title)
                                    .font(.system(size: 15, weight: .medium))
                                    .lineLimit(1)

                                Text(subTitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                    },
                    body: {
                        VStack(spacing: 0) {
                            articleRow("瓶身描绘的牡丹一如你初妆，冉冉檀香透过窗心事我了然，宣纸上走笔至此搁一半", divider: true)
                            articleRow("釉色渲染仕女图韵味被私藏，而你嫣然的一笑如含苞待放", divider: false)
                        }
                    },
                    foot: {
                        HStack(spacing: 6) {
                            UPIcon(name: "chat-fill", size: "16")
                            Text("30 评论")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                )

                Text("事件：\(eventText)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("参数配置") {
                Toggle("显示左上角图标", isOn: $showThumbnail)
                Toggle("显示底部", isOn: $showFoot)
                Toggle("显示外边框", isOn: $showBorder)

                Picker("内边距", selection: $cardPadding) {
                    ForEach([10, 15, 20], id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func articleRow(_ text: String, divider: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(text)
                .font(.system(size: 14))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            UPImage(
                src: thumbnail,
                mode: "aspectFill",
                width: 72,
                height: 72,
                radius: 8
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if divider {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
            }
        }
    }
}
