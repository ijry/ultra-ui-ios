import Foundation
import Observation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

@MainActor
@Observable
private final class UPShortVideoState {
    var isPlaying: Bool

    init(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
}

/// 单条短视频播放器。
///
/// 上游 `u-short-video` 是一整屏的短视频流，它的四个 prop
/// （`tabsList` / `videoList` / `currentTab` / `currentVideo`）与十个事件都在
/// `UPShortVideoFeed` 里；本类型只承载「一条视频怎么播」，供 Feed 与宿主复用。
@MainActor
public struct UPShortVideo: View {
    public var src: String
    public var autoplay: Bool
    public var loop: Bool
    public var controls: Bool
    public var isPlaying: Bool { state.isPlaying }
    @State private var state: UPShortVideoState
    private var onPlayHandler: (() -> Void)?
    private var onPauseHandler: (() -> Void)?
    #if canImport(AVKit)
    private let player: AVPlayer?
    #endif

    public init(src: String = "", autoplay: Bool = false, loop: Bool = false,
                controls: Bool = true, onPlay: (() -> Void)? = nil,
                onPause: (() -> Void)? = nil) {
        self.src = src
        self.autoplay = autoplay
        self.loop = loop
        self.controls = controls
        self._state = State(initialValue: UPShortVideoState(isPlaying: autoplay))
        self.onPlayHandler = onPlay
        self.onPauseHandler = onPause
        #if canImport(AVKit)
        self.player = URL(string: src).map(AVPlayer.init(url:))
        #endif
    }

    public func onPlay(_ action: @escaping () -> Void) -> UPShortVideo { var copy = self; copy.onPlayHandler = action; return copy }
    public func onPause(_ action: @escaping () -> Void) -> UPShortVideo { var copy = self; copy.onPauseHandler = action; return copy }

    public func play() {
        state.isPlaying = true
        #if canImport(AVKit)
        player?.play()
        #endif
        onPlayHandler?()
    }

    public func pause() {
        state.isPlaying = false
        #if canImport(AVKit)
        player?.pause()
        #endif
        onPauseHandler?()
    }

    public var body: some View {
        #if canImport(AVKit)
        VideoPlayer(player: player)
        #else
        Rectangle().fill(Color.black).overlay(Image(systemName: "play.fill").foregroundStyle(.white))
        #endif
    }
}
