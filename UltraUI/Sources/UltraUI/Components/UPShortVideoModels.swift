import Foundation

/// 视频作者信息，对应上游 `item.author`。
public struct UPShortVideoAuthor: Equatable, Sendable {
    public var name: String
    public var avatar: String
    public var desc: String

    public init(name: String = "", avatar: String = "", desc: String = "") {
        self.name = name
        self.avatar = avatar
        self.desc = desc
    }
}

/// `videoList` 的一项，字段取自上游模板里用到的全部键。
public struct UPShortVideoItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var videoUrl: String
    public var author: UPShortVideoAuthor
    public var likeCount: Int
    public var commentCount: Int
    public var shareCount: Int
    public var collectCount: Int
    public var isLiked: Bool
    public var isCollected: Bool
    /// 上游 `item.playbackRate`，倍速弹窗写入。
    public var playbackRate: Double
    /// 上游 `item.progress`：0…100 的播放进度，由 `timeUpdate` 写入。
    public var progress: Double

    public init(id: String? = nil,
                videoUrl: String,
                author: UPShortVideoAuthor = UPShortVideoAuthor(),
                likeCount: Int = 0,
                commentCount: Int = 0,
                shareCount: Int = 0,
                collectCount: Int = 0,
                isLiked: Bool = false,
                isCollected: Bool = false,
                playbackRate: Double = 1,
                progress: Double = 0) {
        self.id = id ?? videoUrl
        self.videoUrl = videoUrl
        self.author = author
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.collectCount = collectCount
        self.isLiked = isLiked
        self.isCollected = isCollected
        self.playbackRate = playbackRate
        self.progress = progress
    }
}

/// `like` / `comment` / `share` / `collect` 的事件负载，
/// 对应上游 `$emit('like', { item, index })`。
public struct UPShortVideoAction: Equatable, Sendable {
    public let item: UPShortVideoItem
    public let index: Int

    public init(item: UPShortVideoItem, index: Int) {
        self.item = item
        self.index = index
    }
}

/// `progressChanging` / `progressChange` 的事件负载，
/// 对应上游 `{ progress, index }`。
public struct UPShortVideoProgress: Equatable, Sendable {
    public let progress: Double
    public let index: Int

    public init(progress: Double, index: Int) {
        self.progress = progress
        self.index = index
    }
}

/// `videoPlay` / `videoPause` / `videoEnded` / `timeUpdate` / `loadedMetadata`
/// 的事件负载。上游第二个字段是平台原始事件对象，原生换成秒数。
public struct UPShortVideoPlayback: Equatable, Sendable {
    public let index: Int
    public let currentTime: Double
    public let duration: Double

    public init(index: Int, currentTime: Double = 0, duration: Double = 0) {
        self.index = index
        self.currentTime = currentTime
        self.duration = duration
    }

    /// 上游 `onTimeUpdate` 用 `currentTime / duration * 100` 更新进度。
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration * 100, 0), 100)
    }
}
