import Foundation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

@MainActor
public final class UPShortVideo: View {
    public var src: String
    public var autoplay: Bool
    public var loop: Bool
    public var controls: Bool
    public private(set) var isPlaying: Bool
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
        self.isPlaying = autoplay
        self.onPlayHandler = onPlay
        self.onPauseHandler = onPause
        #if canImport(AVKit)
        self.player = URL(string: src).map(AVPlayer.init(url:))
        #endif
    }

    public func onPlay(_ action: @escaping () -> Void) -> UPShortVideo { onPlayHandler = action; return self }
    public func onPause(_ action: @escaping () -> Void) -> UPShortVideo { onPauseHandler = action; return self }

    public func play() {
        isPlaying = true
        #if canImport(AVKit)
        player?.play()
        #endif
        onPlayHandler?()
    }

    public func pause() {
        isPlaying = false
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
