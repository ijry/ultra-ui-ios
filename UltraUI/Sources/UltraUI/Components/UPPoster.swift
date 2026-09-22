import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 仓库既有的图层枚举，等价于上游 `json.views` 里 `type` 为
/// `text` / `view` / `image` 的三种；渐变、圆角、字号这些扩展样式请用
/// `UPPosterView` + `UPPosterCSS`。
public enum UPPosterLayer: Equatable, Sendable {
    case text(String, frame: CGRect, color: String = "#000000")
    case rectangle(frame: CGRect, color: String = "#ffffff")
    case image(source: String, frame: CGRect)
    case qrcode(String, frame: CGRect)

    /// 转成与上游一致的 `views` 元素。
    public var posterView: UPPosterView {
        switch self {
        case let .text(value, frame, color):
            return UPPosterView(type: "text", text: value, css: Self.css(frame, color: color))
        case let .rectangle(frame, color):
            return UPPosterView(type: "view", css: Self.css(frame, background: color))
        case let .image(source, frame):
            return UPPosterView(type: "image", src: source, css: Self.css(frame))
        case let .qrcode(value, frame):
            return UPPosterView(type: "qrcode", text: value, css: Self.css(frame))
        }
    }

    private static func css(_ frame: CGRect, color: String = "", background: String = "") -> UPPosterCSS {
        UPPosterCSS(left: String(describing: Double(frame.minX)),
                    top: String(describing: Double(frame.minY)),
                    width: String(describing: Double(frame.width)),
                    height: String(describing: Double(frame.height)),
                    background: background,
                    color: color)
    }
}

/// 渲染指令，供单测断言图层顺序与位置。
public enum UPPosterRenderCommand: Equatable, Sendable {
    case text(String, CGRect, String)
    case rectangle(CGRect, String)
    case image(String, CGRect)
    case qrcode(String, CGRect)
}

/// Native SwiftUI counterpart of uview-plus `u-poster`.
///
/// 上游只有一个 `json` prop：`json.css` 定画布与背景，`json.views` 是绝对定位的
/// 图层数组（`text` / `image` / `qrcode` / `view`），`exportImage()` 用 canvas
/// 逐层绘制后导出临时文件。
///
/// 原生把图层直接画成 SwiftUI 视图（绝对定位的 `ZStack`），`exportImage()` 用
/// `ImageRenderer` 离屏渲染成 PNG 并写入临时目录，返回值字段与上游对齐。
/// 差异：上游的 `radial-gradient` 只解析颜色仍按线性画，原生同样只做线性；
/// 网络图片需要先加载完才能出现在导出结果里（上游用 `getImageInfo` 预取）。
@MainActor
public struct UPPoster: View {
    public var json: UPPosterJSON

    public init(json: UPPosterJSON = UPPosterJSON()) {
        self.json = json
    }

    /// 仓库既有签名。
    public init(size: CGSize = CGSize(width: 300, height: 450), layers: [UPPosterLayer] = []) {
        let css = UPPosterCSS(width: String(describing: Double(max(0, size.width))),
                              height: String(describing: Double(max(0, size.height))))
        self.json = UPPosterJSON(css: css, views: layers.map(\.posterView))
    }

    /// 上游 `json.css.width / height`，缺省 750rpx × 1114rpx。
    public var renderSize: CGSize { json.size }

    public var views: [UPPosterView] { json.views }

    public var renderedCommands: [UPPosterRenderCommand] {
        json.views.compactMap { view in
            switch view.type {
            case "text": return .text(view.text, view.css.frame, view.css.color)
            case "view": return .rectangle(view.css.frame, view.css.background)
            case "image": return .image(view.src, view.css.frame)
            case "qrcode": return .qrcode(view.text, view.css.frame)
            default: return nil
            }
        }
    }

    /// 对应上游 `exportImage()`：渲染成图并写入临时目录。
    /// 上游 20s 超时是 canvas 异步绘制导致的，原生是同步渲染，不需要。
    @discardableResult
    public func exportImage(scale: CGFloat = 2) -> UPPosterExport? {
        let renderer = ImageRenderer(content: body)
        renderer.scale = scale
        guard let data = Self.pngData(from: renderer) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("up-poster-\(UUID().uuidString).png")
        guard (try? data.write(to: url)) != nil else { return nil }
        return UPPosterExport(width: renderSize.width,
                              height: renderSize.height,
                              path: url.path,
                              data: data)
    }

    /// `ImageRenderer` 在 iOS 出 `UIImage`、在 macOS 出 `NSImage`，统一转成 PNG。
    private static func pngData(from renderer: ImageRenderer<some View>) -> Data? {
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff) else { return nil }
        return representation.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            background

            ForEach(Array(json.views.enumerated()), id: \.offset) { _, view in
                layer(view)
            }
        }
        .frame(width: renderSize.width, height: renderSize.height, alignment: .topLeading)
        .clipped()
    }

    /// 上游先按 `json.css.background` 铺底，支持渐变。
    @ViewBuilder
    private var background: some View {
        fill(json.css.background)
            .frame(width: renderSize.width, height: renderSize.height)
    }

    @ViewBuilder
    private func layer(_ view: UPPosterView) -> some View {
        let frame = view.css.frame
        switch view.type {
        case "text":
            textLayer(view)
                .frame(width: frame.width > 0 ? frame.width : nil,
                       height: frame.height > 0 ? frame.height : nil,
                       alignment: view.css.frameAlignment)
                .position(x: frame.midX, y: frame.midY)
        case "view":
            fill(view.css.background)
                .frame(width: frame.width, height: frame.height)
                .clipShape(RoundedRectangle(cornerRadius: UPPosterCSS.length(view.css.radius)))
                .position(x: frame.midX, y: frame.midY)
        case "image":
            UPImage(src: view.src, mode: "aspectFill", width: frame.width, height: frame.height)
                .clipShape(RoundedRectangle(cornerRadius: UPPosterCSS.length(view.css.radius)))
                .position(x: frame.midX, y: frame.midY)
        case "qrcode":
            qrcodeLayer(view, frame: frame)
                .position(x: frame.midX, y: frame.midY)
        default:
            EmptyView()
        }
    }

    private func textLayer(_ view: UPPosterView) -> some View {
        let size = UPPosterCSS.length(view.css.fontSize)
        let lineHeight = UPPosterCSS.length(view.css.lineHeight)
        return Text(view.text)
            .font(.system(size: size > 0 ? size : 14, weight: view.css.isBold ? .bold : .regular))
            .foregroundStyle(view.css.color.isEmpty ? Color.black : UPColor.parse(view.css.color))
            .multilineTextAlignment(view.css.alignment)
            .lineLimit(view.css.lineClamp > 0 ? view.css.lineClamp : nil)
            .lineSpacing(lineHeight > 0 && size > 0 ? max(lineHeight - size, 0) : 0)
    }

    /// 上游 `qrcode` 图层无文本时画一个 `QR` 占位块。
    @ViewBuilder
    private func qrcodeLayer(_ view: UPPosterView, frame: CGRect) -> some View {
        if view.text.isEmpty {
            ZStack {
                UPColor.parse("#f5f5f5")
                Text("QR")
                    .font(.system(size: 12))
                    .foregroundStyle(UPColor.parse("#999999"))
            }
            .frame(width: frame.width, height: frame.height)
        } else {
            UPQRCode(value: view.text, size: max(frame.width, frame.height))
                .frame(width: frame.width, height: frame.height)
        }
    }

    /// 纯色或 `linear-gradient(...)`。
    @ViewBuilder
    private func fill(_ background: String) -> some View {
        if background.isEmpty {
            Color.clear
        } else if UPPosterGradient.isGradient(background) {
            let points = UPPosterGradient.unitPoints(angle: UPPosterGradient.angle(of: background))
            LinearGradient(colors: UPPosterGradient.colors(of: background).map { UPColor.parse($0) },
                           startPoint: points.start,
                           endPoint: points.end)
        } else {
            UPColor.parse(background)
        }
    }
}
