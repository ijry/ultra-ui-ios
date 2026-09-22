import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/progress/progress`。
struct ProgressDemoView: View {
    @State private var manualPercentage = 50

    var body: some View {
        DemoPage {
            DemoSection("默认配置") {
                UPLineProgress()
            }

            DemoSection("基础功能") {
                UPLineProgress(percentage: 30)
            }

            DemoSection("不显示百分比") {
                UPLineProgress(percentage: 40, showText: false)
            }

            DemoSection("从右往左") {
                UPLineProgress(percentage: 40, showText: false, fromRight: true)
            }

            DemoSection("自定义高度") {
                UPLineProgress(percentage: 50, showText: false, height: 8)
            }

            DemoSection("自定义颜色") {
                UPLineProgress(
                    activeColor: "#3c9cff",
                    inactiveColor: "#f3f4f6",
                    percentage: 60,
                    showText: false,
                    height: 8
                )
            }

            DemoSection("自定义内容") {
                UPLineProgress(
                    activeColor: "#3c9cff",
                    inactiveColor: "#f3f4f6",
                    percentage: 70,
                    showText: false,
                    height: 12
                ) {
                    Text("70%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }

            DemoSection("手动加减") {
                UPLineProgress(
                    activeColor: "#3c9cff",
                    inactiveColor: "#f3f4f6",
                    percentage: manualPercentage,
                    showText: false,
                    height: 8
                )

                Text("当前进度：\(manualPercentage)%")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    UPButton(size: "small", text: "减少") {
                        manualPercentage = max(0, manualPercentage - 10)
                    }
                    UPButton(type: "primary", size: "small", text: "增加") {
                        manualPercentage = min(100, manualPercentage + 10)
                    }
                }
            }
        }
    }
}
