import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/shortVideo/shortVideo`。
@MainActor
struct ShortVideoDemoView: View {
    private static let firstVideo = "https://uview-plus.jiangruyi.com/big/rjtsdl.MP4"
    private static let secondVideo = "https://uview-plus.jiangruyi.com/big/shanghai.mp4"

    @State private var controlled = UPShortVideo(src: ShortVideoDemoView.secondVideo)
    @State private var eventLog = "尚未触发"
    @State private var tick = 0
    @State private var feedTab = 0
    @State private var feedVideo = 0
    @State private var feedLog = "尚未操作"

    /// 对应上游 `videoList`：作者信息与四个计数。
    private static let feedItems = [
        UPShortVideoItem(videoUrl: ShortVideoDemoView.firstVideo,
                         author: UPShortVideoAuthor(name: "uview-plus",
                                                    avatar: "https://uview-plus.jiangruyi.com/common/logo.png",
                                                    desc: "全面的组件和便捷的工具"),
                         likeCount: 1_024,
                         commentCount: 128,
                         shareCount: 32,
                         collectCount: 64),
        UPShortVideoItem(videoUrl: ShortVideoDemoView.secondVideo,
                         author: UPShortVideoAuthor(name: "上海",
                                                    avatar: "https://uview-plus.jiangruyi.com/common/logo.png",
                                                    desc: "魔都夜景"),
                         likeCount: 2_048,
                         commentCount: 256,
                         shareCount: 64,
                         collectCount: 128,
                         isLiked: true)
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPShortVideo(src: Self.firstVideo)
                    .frame(height: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("默认显示系统播放控制条，需要手动点击播放。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自动播放并循环") {
                UPShortVideo(src: Self.secondVideo, autoplay: true, loop: true)
                    .frame(height: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("autoplay 进入即播放，loop 播放结束后自动从头开始。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("隐藏控制条") {
                UPShortVideo(src: Self.secondVideo, autoplay: true, loop: true, controls: false)
                    .frame(height: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("controls 为 false 时交由外层自定义交互，适合短视频流的沉浸式布局。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("事件与手动控制") {
                controlled
                    .frame(height: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .id(tick)

                HStack(spacing: 10) {
                    UPButton(type: "primary", size: "mini", text: "play") {
                        controlled.play()
                        tick += 1
                    }

                    UPButton(type: "warning", size: "mini", text: "pause") {
                        controlled.pause()
                        tick += 1
                    }
                }

                Text("isPlaying：\(controlled.isPlaying ? "播放中" : "已暂停")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("单条播放器 UPShortVideo 提供 src / autoplay / loop / controls / play() / pause() / isPlaying / onPlay / onPause，底层是 AVKit 的 VideoPlayer。上游组件本体是整屏短视频流，原生对应 UPShortVideoFeed：4 个 prop（tabsList / videoList / currentTab / currentVideo）与 tabChange / videoChange / like / comment / share / collect / progressChanging / progressChange / videoPlay / videoPause 十个事件全覆盖，menu / search / actions / tabbar 四个插槽都提供，倍速用 showSpeedOptions(at:) + selectSpeed(_:) 写进 item.playbackRate。纵向翻页用 TabView 的 page 样式（整体旋转 -90°、每页转回 90°），上游底部 tabbar 属于页面壳层，交给 tabbar 插槽。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            DemoSection("短视频流（上游主形态）") {
                UPShortVideoFeed(videoList: Self.feedItems,
                                 currentTab: $feedTab,
                                 currentVideo: $feedVideo)
                    .onTabChange { feedLog = "tabChange：\($0)" }
                    .onVideoChange { feedLog = "videoChange：\($0)" }
                    .onLike { feedLog = "like：第 \($0.index + 1) 条（\($0.item.likeCount)）" }
                    .onComment { feedLog = "comment：第 \($0.index + 1) 条" }
                    .onShare { feedLog = "share：第 \($0.index + 1) 条" }
                    .onCollect { feedLog = "collect：第 \($0.index + 1) 条" }
                    .onProgressChange { feedLog = "progressChange：\(Int($0.progress))%" }
                    .frame(height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("tab=\(feedTab) video=\(feedVideo) · \(feedLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        controlled = controlled
            .onPlay { eventLog = "play" }
            .onPause { eventLog = "pause" }
    }
}
