import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/cropper/cropper`。
@MainActor
struct CropperDemoView: View {
    private static let album1 = "https://uview-plus.jiangruyi.com/album/1.jpg"
    private static let album2 = "https://uview-plus.jiangruyi.com/album/2.jpg"
    private static let album3 = "https://uview-plus.jiangruyi.com/album/3.jpg"

    @State private var avatarCropper = UPCropper(src: CropperDemoView.album1,
                                                 sourceSize: CGSize(width: 320, height: 320))
    @State private var resizableCropper = UPCropper(src: CropperDemoView.album2,
                                                    sourceSize: CGSize(width: 320, height: 200),
                                                    canChangeSize: true,
                                                    areaWidth: "200rpx",
                                                    areaHeight: "150rpx")
    @State private var innerCropper = UPCropper(src: CropperDemoView.album3,
                                                sourceSize: CGSize(width: 320, height: 320),
                                                inner: true,
                                                fillColor: "#000000")
    @State private var urls: [String] = ["", "", ""]
    @State private var eventLog = "尚未裁剪"
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("头像裁剪") {
                avatarCropper
                    .frame(height: 360)
                    .id(tick)

                HStack(spacing: 12) {
                    UPAvatar(src: urls[0], size: 120)

                    VStack(alignment: .leading, spacing: 6) {
                        UPButton(type: "primary", size: "mini", text: "旋转") {
                            avatarCropper.rotate()
                            tick += 1
                        }
                        UPButton(size: "mini", text: "confirm") { avatarCropper.confirm() }
                    }
                }

                tip("areaWidth/areaHeight 300rpx · exportWidth/exportHeight 260rpx · 双指缩放（canScale）")
                tip("最近事件：\(eventLog)")
            }

            DemoSection("可变大小（canChangeSize）") {
                resizableCropper
                    .frame(height: 240)
                    .id(tick)

                HStack(spacing: 10) {
                    UPButton(type: "primary", size: "mini", text: "缩小裁剪框") {
                        let rect = resizableCropper.cropRect
                        resizableCropper.resizeCropRect(to: CGSize(width: rect.width * 0.8,
                                                                  height: rect.height * 0.8))
                        tick += 1
                    }

                    UPButton(size: "mini", text: "confirm") { resizableCropper.confirm() }
                }

                tip("当前裁剪框：\(rectText(resizableCropper.cropRect))；canChangeSize 为假时 resizeCropRect 会被忽略。")
            }

            DemoSection("限制在图片内（inner）") {
                innerCropper
                    .frame(height: 360)
                    .id(tick)

                UPAvatar(src: urls[2], size: 120)

                UPButton(type: "primary", size: "mini", text: "confirm") { innerCropper.confirm() }

                tip("inner 为真时按钮少一个（无旋转），旋转也被强制禁用；fillColor 换成黑底。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPCropper 已覆盖上游 15 个 prop：canScale / canRotate / canChangeSize / noTab / inner / fillColor / areaWidth / areaHeight / exportWidth / exportHeight / quality / minScale / maxScale 以及 src / sourceSize，事件为 onInit（上游 avtinit）/ onConfirm((UPCropResult) -> Void) / onCancel 外加 onSelect（chooseImage 需要弹相册时回调宿主），方法 rotate() / setScale(_:) / setCropRect(_:) / dragCropRect(by:) / resizeCropRect(to:) / preview() / hidePreview() / chooseImage(index:imageSrc:data:) / confirm() / cancel()。confirm 负载与上游 { avatar, path, index, data } 对齐（index / data 由 chooseImage 带入）。三点差异：上游用三层 canvas 画图与遮罩，原生用图片 + 挖洞遮罩 + 白框；上游 rotate 在安卓上有 500ms 节流，原生不需要；「从相册选图」要宿主接 PhotosPicker，chooseImage 只把参数通过 onSelect 带出去。noTab 对应 uni.showTabBar，iOS 没有全局 tabBar，只保留取值。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        avatarCropper = avatarCropper
            .onConfirm { result in apply(result, at: 0) }
            .onCancel { eventLog = "cancel" }
            .onInit { eventLog = "avtinit：画布就绪" }
            .onSelect { request in
                eventLog = request.needsPicker ? "chooseImage：需要宿主弹相册" : "chooseImage：直接加载"
            }
        resizableCropper = resizableCropper.onConfirm { result in apply(result, at: 1) }
        innerCropper = innerCropper.onConfirm { result in apply(result, at: 2) }
        tick += 1
    }

    private func apply(_ result: UPCropResult, at index: Int) {
        urls[index] = result.source
        eventLog = "confirm：rect \(rectText(result.rect))"
    }

    private func rectText(_ rect: CGRect) -> String {
        "(\(Int(rect.minX)), \(Int(rect.minY)), \(Int(rect.width)), \(Int(rect.height)))"
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
