import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/poster/poster`。
@MainActor
struct PosterDemoView: View {
    /// 画布太大，页面里按比例缩小预览。
    private static let previewScale: CGFloat = 0.4

    private static let goodsImage = "https://uview-plus.jiangruyi.com/uview/swiper/swiper1.png"

    /// 逐条对应上游 `json`：`css` 定画布，`views` 是六个绝对定位图层。
    private static let json = UPPosterJSON(
        css: UPPosterCSS(width: "750rpx",
                         height: "1114rpx",
                         background: "linear-gradient(135deg, #3c9cff, #5ac725)"),
        views: [
            UPPosterView(type: "view",
                         css: UPPosterCSS(left: "40rpx", top: "144rpx",
                                          width: "670rpx", height: "930rpx",
                                          background: "#ffffff", radius: "16rpx")),
            UPPosterView(type: "text", text: "为您挑选了一个好物",
                         css: UPPosterCSS(left: "144rpx", top: "70rpx", width: "460rpx", height: "48rpx",
                                          color: "#ffffff", fontSize: "32rpx", textAlign: "center")),
            UPPosterView(type: "image", src: PosterDemoView.goodsImage,
                         css: UPPosterCSS(left: "72rpx", top: "176rpx",
                                          width: "606rpx", height: "606rpx", radius: "12rpx")),
            UPPosterView(type: "text", text: "￥299",
                         css: UPPosterCSS(left: "72rpx", top: "830rpx", width: "260rpx", height: "60rpx",
                                          color: "#ff0000", fontSize: "44rpx", fontWeight: "bold")),
            UPPosterView(type: "text", text: "精美陶瓷茶具套装，高端大气上档次，送礼自用两相宜，限时特惠仅此一天",
                         css: UPPosterCSS(left: "72rpx", top: "900rpx", width: "396rpx", height: "120rpx",
                                          color: "#333333", fontSize: "26rpx", lineHeight: "40rpx",
                                          lineClamp: 2)),
            UPPosterView(type: "qrcode", text: "https://example.com/product/123",
                         css: UPPosterCSS(left: "500rpx", top: "880rpx",
                                          width: "178rpx", height: "178rpx"))
        ]
    )

    @State private var exportedImage: UIImage?
    @State private var eventLog = "尚未生成"

    private var poster: UPPoster { UPPoster(json: Self.json) }

    var body: some View {
        DemoPage {
            DemoSection("基础示例") {
                UPButton(type: "primary", shape: "circle", text: "生成海报") { generatePoster() }

                tip("最近事件：\(eventLog)")

                if let exportedImage {
                    Image(uiImage: exportedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: poster.renderSize.width * Self.previewScale)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    tip("导出尺寸：\(Int(exportedImage.size.width)) × \(Int(exportedImage.size.height))")
                }
            }

            DemoSection("海报内容") {
                poster
                    .scaleEffect(Self.previewScale, anchor: .topLeading)
                    .frame(width: poster.renderSize.width * Self.previewScale,
                           height: poster.renderSize.height * Self.previewScale,
                           alignment: .topLeading)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("共 \(poster.renderedCommands.count) 个图层：渐变底 + 白卡片 + 3 段文字 + 商品图 + 二维码。")
                tip("画布 \(Int(poster.renderSize.width)) × \(Int(poster.renderSize.height))pt（750rpx × 1114rpx），页面按 \(Int(Self.previewScale * 100))% 缩放预览。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPPoster 已覆盖上游唯一的 json prop 与 exportImage()：json.css 定画布与背景（支持纯色和 linear-gradient），json.views 支持 text / image / qrcode / view 四种 type，css 里的 left / top / width / height / background / color / fontSize / fontWeight / lineHeight / textAlign / radius / lineClamp 都会生效，rpx 按 UPUnit 的 375 设计基准折算（对应上游 convertRpxToPx 只取一次比例的做法）。exportImage(scale:) 用 ImageRenderer 离屏渲染成 PNG 并写入临时目录，返回 width / height / path / data，字段与上游 { width, height, path, blob } 对齐；上游 20s 超时是 canvas 异步绘制才需要的，原生是同步渲染。两点差异：radial-gradient 上游也只解析颜色按线性画，原生同样只做线性；网络图片要先加载完才会出现在导出结果里（上游用 getImageInfo 预取）。仓库既有的 UPPoster(size:layers:) 与 UPPosterLayer 保留，会转成上游 views 元素。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func generatePoster() {
        guard let export = poster.exportImage() else {
            eventLog = "export 失败"
            return
        }
        exportedImage = UIImage(data: export.data)
        eventLog = "export 成功：\(export.path)"
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
