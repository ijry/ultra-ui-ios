import SwiftUI
import UltraUI

struct AvatarDemoView: View {
    @State private var tappedName = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础演示") {
                HStack(spacing: 16) {
                    UPAvatar(
                        size: 56,
                        text: "U",
                        fontSize: 22,
                        randomBgColor: true,
                        colorIndex: 0,
                        name: "uview"
                    )

                    UPAvatar(
                        size: 56,
                        text: "友",
                        fontSize: 22,
                        randomBgColor: true,
                        colorIndex: 5,
                        name: "friend"
                    )

                    Text("文字头像")
                        .foregroundStyle(.secondary)
                }
            }

            DemoSection("头像形状与尺寸") {
                HStack(alignment: .bottom, spacing: 16) {
                    UPAvatar(shape: "circle", size: 44, text: "圆", randomBgColor: true)
                    UPAvatar(shape: "square", size: 44, text: "方", randomBgColor: true)
                    UPAvatar(size: 30, text: "S", randomBgColor: true)
                    UPAvatar(size: 48, text: "M", randomBgColor: true)
                    UPAvatar(size: 66, text: "L", randomBgColor: true)
                }
            }

            DemoSection("图标头像") {
                HStack(spacing: 16) {
                    UPAvatar(
                        size: 52,
                        bgColor: "#f9ae3d",
                        color: "#ffffff",
                        fontSize: 22,
                        icon: "star-fill"
                    )
                    UPAvatar(
                        size: 52,
                        bgColor: "#e45656",
                        color: "#ffffff",
                        fontSize: 22,
                        icon: "heart-fill"
                    )
                    UPAvatar(
                        size: 52,
                        bgColor: "#4ca7f5",
                        color: "#ffffff",
                        fontSize: 22,
                        icon: "person-fill"
                    )
                }
            }

            DemoSection("图片与加载失败") {
                HStack(spacing: 16) {
                    UPAvatar(
                        src: "https://uview-plus.jiangruyi.com/album/1.jpg",
                        size: 60,
                        mode: "aspectFill"
                    )

                    UPAvatar(
                        src: "https://example.invalid/missing-avatar.png",
                        size: 60,
                        defaultUrl: ""
                    )

                    Text("失败时显示默认头像")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            DemoSection("点击事件") {
                HStack(spacing: 16) {
                    UPAvatar(
                        size: 56,
                        text: "A",
                        randomBgColor: true,
                        name: "alice"
                    )
                    .onClick { name in
                        tappedName = name
                    }

                    Text(tappedName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
