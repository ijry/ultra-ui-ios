import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/album/album`。
@MainActor
struct AlbumDemoView: View {
    @State private var tapped = ""
    @State private var preview = "尚未触发"
    @State private var albumWidth: CGFloat = 0

    /// 上游同页的 `urls1`（对象数组 + `keyName`）与 `urls2`（10 张）。
    private let single = [["src2": "https://uview-plus.jiangruyi.com/uview/album/1.jpg"]]
    private let many = (1...10).map { "https://uview-plus.jiangruyi.com/uview/album/\($0).jpg" }
    private var four: [String] { Array(many.prefix(4)) }

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPAlbum(urls: single, keyName: "src2")
                    .onClick { index, _ in tapped = "第 \(index + 1) 张" }
            }

            DemoSection("多图模式") {
                UPAlbum(urls: many)
            }

            DemoSection("图文对齐") {
                Text("全面的组件和便捷的工具会让您信手拈来，如鱼得水")
                    .font(.system(size: 15))
                    .frame(width: albumWidth > 0 ? albumWidth : nil, alignment: .leading)
                UPAlbum(urls: many, multipleSize: 68)
                    .onAlbumWidth { albumWidth = $0 }
                tip("albumWidth：\(Int(albumWidth))pt")
            }

            DemoSection("更改裁剪模式") {
                UPAlbum(urls: four, multipleMode: "scaleToFill", maxCount: 4, rowCount: 2)
            }

            DemoSection("更改图片大小") {
                UPAlbum(urls: four, multipleSize: 50, maxCount: 4, rowCount: 2)
            }

            DemoSection("自定义圆角") {
                UPAlbum(urls: many, radius: 10)
            }

            DemoSection("自定义形状") {
                UPAlbum(urls: many, shape: "circle")
            }

            DemoSection("自适应自动换行") {
                tip("每行占满自动换行（不受 rowCount 限制）")
                UPAlbum(urls: many, maxCount: 9, autoWrap: true)
            }

            DemoSection("自定义预览与点击") {
                UPAlbum(urls: many, maxCount: 6, previewFullImage: false)
                    .onClick { index, _ in tapped = "第 \(index + 1) 张" }
                    .onPreview { event in
                        preview = "preview：第 \(event.currentIndex + 1) / \(event.urls.count) 张"
                    }
                tip(tapped.isEmpty ? "尚未点击" : "已点击：\(tapped)")
                tip(preview)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPAlbum 已覆盖上游 16 个 prop：urls（字符串或对象数组）/ keyName / singleSize / multipleSize / space / singleMode / multipleMode / maxCount / previewFullImage / rowCount / showMore / shape / radius / autoWrap / unit / stop，事件为 onPreview((UPAlbumPreview) -> Void) / onAlbumWidth((CGFloat) -> Void) 外加原生的 onClick((Int, String) -> Void)。previewFullImage 为真时上游调 uni.previewImage 打开系统预览，仓库内没有图片预览层，此时只回调 onClick，宿主可自行呈现；为假时按上游抛 preview 事件。单图会异步取原图长宽比，让长边等于 singleSize（对应上游 uni.getImageInfo），取不到时退化成正方形。unit 与 stop 只作为兼容元数据保留：尺寸已折算成 pt，SwiftUI 的点击手势默认不冒泡。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
