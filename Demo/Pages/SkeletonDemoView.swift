import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/skeleton/skeleton`。
struct SkeletonDemoView: View {
    @State private var animate = true
    @State private var loading = false

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPSkeleton(rows: "3", title: true)
            }

            DemoSection("自定义段落行数") {
                UPSkeleton(rows: "2", title: true)
            }

            DemoSection("设置段落宽度") {
                UPSkeleton(rows: "2", rowsWidth: ["100%", "35%"], title: true)
            }

            DemoSection("设置段落高度") {
                UPSkeleton(
                    rows: "3",
                    rowsWidth: ["100%", "100%", "100%"],
                    rowsHeight: ["18px", "18px", "80px"],
                    title: true
                )
            }

            DemoSection("是否开启动画") {
                UPSwitch(size: 20, modelValue: $animate, space: "2")

                UPGap(bgColor: "transparent", height: 15)

                UPSkeleton(animate: animate, rows: "3", title: true)
            }

            DemoSection("展示头像") {
                UPSkeleton(animate: animate, rows: "3", title: true, avatar: true)
            }

            DemoSection("切换状态") {
                UPSwitch(size: 20, modelValue: $loading, space: "2")

                UPGap(bgColor: "transparent", height: 15)

                UPSkeleton(
                    loading: loading,
                    rows: "2",
                    rowsHeight: "14",
                    title: true,
                    avatar: true
                ) {
                    HStack(alignment: .top, spacing: 10) {
                        UPImage(
                            src: "https://uview-plus.jiangruyi.com/uview/common/logo.png",
                            width: 40,
                            height: 40,
                            shape: "circle"
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            UPText(type: "main", text: "利剑出鞘,一统江湖", size: 16)
                            UPText(
                                type: "tips",
                                text: "众多组件覆盖开发过程的各个需求，组件功能丰富，多端兼容。让您快速集成，开箱即用",
                                size: 14
                            )
                        }
                    }
                }
            }

            DemoSection("头像形状") {
                HStack(alignment: .top, spacing: 20) {
                    UPSkeleton(rows: "0", title: false, avatar: true, avatarSize: 48)
                    UPSkeleton(
                        rows: "0",
                        title: false,
                        avatar: true,
                        avatarSize: 48,
                        avatarShape: "square"
                    )
                }
            }

            DemoSection("当前原生范围") {
                Text("已支持 loading / animate / rows / rowsWidth / rowsHeight / title / titleWidth / titleHeight / avatar / avatarSize / avatarShape，loading 为 false 时渲染默认插槽。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
