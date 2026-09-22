import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/backtop/backtop`。
struct BackTopDemoView: View {
    @State private var selectedOptions: [UPCheckboxName] = ["自定义图标"]
    @State private var scrollTop: CGFloat = 0
    @State private var lastEvent = "尚未点击"

    private let options = [
        "显示方形",
        "自定义图标",
        "自定义距离",
        "自定义样式",
        "自定义返回顶部滚动时间"
    ]

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: BackTopScrollOffsetKey.self,
                                value: max(0, -proxy.frame(in: .named("backtop-scroll")).minY)
                            )
                    }
                    .frame(height: 0)
                    .id("backtop-top")

                    DemoSection("自定义 BackTop（滚动页面即可在右下角看到图标）") {
                        UPCheckboxGroup(
                            modelValue: $selectedOptions,
                            shape: "square",
                            placement: "column",
                            borderBottom: false
                        ) {
                            ForEach(options, id: \.self) { option in
                                UPCheckbox(name: option, label: option)
                            }
                        }

                        Text("当前滚动距离：\(Int(scrollTop)) pt")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Text("事件：\(lastEvent)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    DemoSection("滚动区域") {
                        VStack(spacing: 10) {
                            ForEach(0..<18, id: \.self) { index in
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(UPColor.parse("primary"))
                                        .clipShape(Circle())

                                    Text("向下滚动以查看返回顶部按钮")
                                        .font(.system(size: 14))

                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .coordinateSpace(name: "backtop-scroll")
            .onPreferenceChange(BackTopScrollOffsetKey.self) { value in
                scrollTop = value
            }
            .overlay(alignment: .bottomTrailing) {
                UPBackTop(
                    mode: isSelected("显示方形") ? "square" : "circle",
                    icon: isSelected("自定义图标") ? "arrow-up" : "arrow-upward",
                    duration: isSelected("自定义返回顶部滚动时间") ? 1500 : 300,
                    scrollTop: scrollTop,
                    bottom: isSelected("自定义距离") ? 180 : 100,
                    right: 20,
                    iconStyle: isSelected("自定义样式")
                        ? UPStyle(["color": "#ffffff"])
                        : UPStyle(),
                    customStyle: isSelected("自定义样式")
                        ? UPStyle(["backgroundColor": "#2979ff"])
                        : UPStyle(),
                    onClick: {
                        lastEvent = "已触发 click"
                        withAnimation(.easeInOut(duration: 0.35)) {
                            scrollProxy.scrollTo("backtop-top", anchor: .top)
                        }
                    }
                )
            }
        }
    }

    private func isSelected(_ option: String) -> Bool {
        selectedOptions.contains(UPCheckboxName(option))
    }
}

private struct BackTopScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
