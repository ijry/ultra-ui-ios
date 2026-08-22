import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/badge/badge`。
struct BadgeDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                HStack(spacing: 24) {
                    UPBadge(value: 5)
                    UPBadge(value: 10)
                    UPBadge(value: "99+")
                }
            }

            DemoSection("主题类型") {
                HStack(spacing: 16) {
                    UPBadge(value: 8, type: "primary")
                    UPBadge(value: 8, type: "success")
                    UPBadge(value: 8, type: "error")
                    UPBadge(value: 8, type: "warning")
                    UPBadge(value: 8, type: "info")
                }
            }

            DemoSection("圆点") {
                HStack(spacing: 24) {
                    UPBadge(isDot: true)
                    UPBadge(isDot: true, type: "success")
                    UPBadge(isDot: true, type: "warning")
                }
            }

            DemoSection("最大值") {
                HStack(spacing: 24) {
                    UPBadge(value: 100, max: 99)
                    UPBadge(value: 1000, max: 999)
                }
            }

            DemoSection("形状") {
                HStack(spacing: 24) {
                    UPBadge(value: 6, shape: "circle")
                    UPBadge(value: 6, shape: "horn")
                }
            }
        }
    }
}
