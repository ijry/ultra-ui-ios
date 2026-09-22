import Foundation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

/// 只放行系统能直接加载的地址，与 `UPImage.remoteImageURL(_:)` 同一套判定。
enum UPParseURL {
    static func remote(_ source: String) -> URL? {
        guard let url = URL(string: source), let scheme = url.scheme?.lowercased() else { return nil }
        return ["http", "https", "file"].contains(scheme) ? url : nil
    }

    /// 对应上游 `mediaError` 的换源：挑第一个能播放的地址。
    static func firstPlayable(_ sources: [String]) -> (index: Int, url: URL)? {
        for (index, source) in sources.enumerated() {
            if let url = remote(source) { return (index, url) }
        }
        return nil
    }
}

/// 跨节点的播放器登记表，用来实现上游 `pauseVideo`（播放一个时暂停其他）。
/// 与 `UPReadMoreState` 一样是给 `@State` 持有的普通引用类型。
@MainActor
final class UPParseMediaCoordinator {
    #if canImport(AVKit)
    private var players: [String: AVPlayer] = [:]
    #endif

    init() {}

    func register(_ player: AnyObject?, for id: String) {
        #if canImport(AVKit)
        guard let player = player as? AVPlayer else { return }
        players[id] = player
        #endif
    }

    func unregister(_ id: String) {
        #if canImport(AVKit)
        players[id] = nil
        #endif
    }

    func pauseOthers(except id: String) {
        #if canImport(AVKit)
        for (key, player) in players where key != id {
            player.pause()
        }
        #endif
    }
}

/// `<img>`。上游用 `mode="widthFix"` 让图片按容器宽度等比缩放，
/// 原生用 `scaledToFit()` 得到同样效果，所以这里不复用需要固定尺寸的 `UPImage`。
@MainActor
struct UPParseImageView: View {
    let node: UPParseNode
    let context: UPParseContext
    let base: CGFloat

    @State private var failed = false

    private var src: String { node.attributes["src"] ?? "" }

    private var showsMenu: Bool {
        context.showImgMenu && node.attributes["ignore"] == nil
    }

    var body: some View {
        image
            .contentShape(Rectangle())
            .onTapGesture { context.onImageTap(node) }
            .modifier(UPParseImageMenu(enabled: showsMenu, src: src, copy: context.copy))
    }

    @ViewBuilder
    private var image: some View {
        if failed, !context.errorImg.isEmpty {
            placeholder(context.errorImg)
        } else if src.isEmpty {
            placeholder(context.loadingImg)
        } else if let url = UPParseURL.remote(src) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let loaded):
                    fitted(loaded)
                case .failure(let error):
                    placeholder(context.errorImg)
                        .onAppear { report(error.localizedDescription) }
                case .empty:
                    placeholder(context.loadingImg)
                @unknown default:
                    placeholder(context.loadingImg)
                }
            }
        } else {
            fitted(Image(src))
        }
    }

    private func fitted(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }

    /// 上游占位图同样走 `mode="widthFix"`；没配占位图时留 1px 空位，
    /// 对应上游 `._image { height: 1px }`。
    @ViewBuilder
    private func placeholder(_ source: String) -> some View {
        if let url = UPParseURL.remote(source) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    fitted(image)
                } else {
                    Color.clear.frame(height: 1)
                }
            }
        } else if !source.isEmpty {
            fitted(Image(source))
        } else {
            Color.clear.frame(height: 1)
        }
    }

    private func report(_ message: String) {
        // 上游只有配了 errorImg 才切占位图，`error` 事件一律抛出。
        failed = true
        context.onMediaError(UPParseErrorEvent(source: "img",
                                              src: src,
                                              attributes: node.attributes,
                                              message: message))
    }
}

/// 上游 APP-PLUS 长按图片弹「保存图片」，原生保存到相册需要额外权限，
/// 因此 `showImgMenu` 落成系统长按菜单里的「复制图片链接」。
private struct UPParseImageMenu: ViewModifier {
    let enabled: Bool
    let src: String
    let copy: (String) -> Void

    func body(content: Content) -> some View {
        if enabled, !src.isEmpty {
            content.contextMenu {
                Button("复制图片链接") { copy(src) }
            }
        } else {
            content
        }
    }
}

/// `<video>` / `<audio>`。可播放的源由 `node.sources` 依次尝试，
/// 对应上游 `mediaError` 里的换源逻辑。
@MainActor
struct UPParseMediaView: View {
    let node: UPParseNode
    let context: UPParseContext
    let style: UPParseStyle
    let base: CGFloat

    @State private var player: AnyObject?
    @State private var isPlaying = false

    private var identifier: String { node.attributes["id"] ?? node.sources.first ?? node.name }
    private var resolved: (index: Int, url: URL)? { UPParseURL.firstPlayable(node.sources) }
    private var src: String { resolved.map { node.sources[$0.index] } ?? "" }

    var body: some View {
        content
            .task(id: src) { await start() }
            .onDisappear { context.media.unregister(identifier) }
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(AVKit)
        if node.name == "video" {
            VideoPlayer(player: player as? AVPlayer)
                // 上游 `._video { width: 300px; height: 225px }`，宽度改为随容器。
                .frame(height: style.length(for: "height", base: base) ?? 225)
        } else {
            audioBar
        }
        #else
        audioBar
        #endif
    }

    /// `<audio>` 上游是平台自带控件，原生给一个播放按钮加标题。
    private var audioBar: some View {
        HStack(spacing: 12) {
            Button {
                toggle()
            } label: {
                UPIcon(name: isPlaying ? "uicon-pause" : "uicon-play-right", size: "20")
            }
            .buttonStyle(.plain)
            .disabled(resolved == nil)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.attributes["name"] ?? src)
                    .font(.system(size: 14))
                    .lineLimit(1)
                if let author = node.attributes["author"], !author.isEmpty {
                    Text(author).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(UPColor.parse(UPConfig.image.bgColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func toggle() {
        #if canImport(AVKit)
        guard let player = player as? AVPlayer else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            reportPlay()
        }
        #endif
    }

    /// 上游在 `mounted` 里建播放器，出错时才换源；原生把「所有源都不可播放」
    /// 归到 `error` 事件，AVKit 播放中途的失败回调没有接入（与 `UPShortVideo` 一致）。
    private func start() async {
        guard let resolved else {
            guard !node.sources.isEmpty else { return }
            context.onMediaError(UPParseErrorEvent(source: node.name,
                                                   src: node.sources[0],
                                                   attributes: node.attributes,
                                                   message: "无法播放的媒体源"))
            return
        }
        #if canImport(AVKit)
        let player = AVPlayer(url: resolved.url)
        player.isMuted = node.attributes["muted"] != nil
        self.player = player
        context.media.register(player, for: identifier)
        if node.attributes["autoplay"] != nil {
            player.play()
            isPlaying = true
            reportPlay()
        }
        await observePlayback(player)
        #endif
    }

    #if canImport(AVKit)
    /// 播放状态没有 Swift 6 下安全可用的推送式回调，这里沿用组件内既有的
    /// 轮询做法（`UPParse` 的 `ready` 也是每 350ms 探测一次）。
    private func observePlayback(_ player: AVPlayer) async {
        while !Task.isCancelled {
            let playing = player.timeControlStatus == .playing
            if playing != isPlaying {
                isPlaying = playing
                if playing { reportPlay() }
            }
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
        }
    }
    #endif

    private func reportPlay() {
        if context.pauseVideo {
            context.media.pauseOthers(except: identifier)
        }
        context.onPlay(UPParsePlayEvent(source: node.name,
                                        src: src,
                                        attributes: node.attributes))
    }
}
