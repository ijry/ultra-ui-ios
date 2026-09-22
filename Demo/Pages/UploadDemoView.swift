import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/upload/upload`。
///
/// iOS 没有 `uni.chooseImage` 这类内置选择器，本页用 `onPick` 拿到上游
/// `chooseFile` 的参数后直接造一条示例文件，等价于「选完文件再回调」的时序；
/// 真机接入 `PhotosPicker` / `fileImporter` 时把 `receive(_:)` 的入参换成
/// 真实文件即可。
@MainActor
struct UploadDemoView: View {
    @State private var basic: [UPUploadFile] = []
    @State private var videos: [UPUploadFile] = []
    @State private var preview: [UPUploadFile] = [
        UPUploadFile(name: "1.jpg", url: "https://uview-plus.jiangruyi.com/uview/swiper/1.jpg")
    ]
    @State private var filled: [UPUploadFile] = [
        UPUploadFile(name: "1.jpg", url: "https://uview-plus.jiangruyi.com/uview/swiper/1.jpg"),
        UPUploadFile(name: "2.jpg", url: "https://uview-plus.jiangruyi.com/uview/swiper/1.jpg")
    ]
    @State private var limited: [UPUploadFile] = []
    @State private var custom: [UPUploadFile] = []
    @State private var uploading: [UPUploadFile] = [
        UPUploadFile(name: "a.jpg",
                     url: "https://uview-plus.jiangruyi.com/uview/swiper/1.jpg",
                     status: .uploading,
                     message: "上传中",
                     progress: 40),
        UPUploadFile(name: "b.jpg",
                     url: "https://uview-plus.jiangruyi.com/uview/swiper/2.jpg",
                     status: .failed,
                     message: "上传失败")
    ]
    @State private var pendingBefore: [UPUploadFile] = []
    @State private var log = "尚未操作"

    private let sampleURLs = (1...5).map { "https://uview-plus.jiangruyi.com/uview/swiper/\($0).jpg" }

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPUpload(fileList: $basic,
                         useBeforeRead: true,
                         maxCount: 10,
                         name: "1",
                         multiple: true,
                         autoDelete: true)
                    .onPick { request in
                        pendingBefore = makeFiles(count: min(request.maxCount, 2))
                        log = "beforeRead：待确认 \(pendingBefore.count) 个文件"
                    }
                    .onBeforeRead { event in
                        pendingBefore = event.files
                        log = "beforeRead：待确认 \(event.files.count) 个文件（name=\(event.name)）"
                    }
                    .onAfterRead { (event: UPUploadReadEvent) in
                        basic += event.files
                        log = "afterRead：追加 \(event.files.count) 个（name=\(event.name)）"
                    }
                    .onDelete { (event: UPUploadDeleteEvent) in
                        log = "delete：第 \(event.index + 1) 个（name=\(event.name)）"
                    }

                HStack(spacing: 12) {
                    UPButton(type: "primary", size: "small", text: "选择文件") {
                        pendingBefore = makeFiles(count: 2)
                        log = "beforeRead：待确认 2 个文件"
                    }
                    UPButton(type: "success", size: "small", text: "确认读取") {
                        basic += pendingBefore
                        log = "afterRead：追加 \(pendingBefore.count) 个"
                        pendingBefore = []
                    }
                }

                tip(log)
                tip("useBeforeRead 为真时上游先抛 beforeRead，等 callback(true) 才继续。")
            }

            DemoSection("上传视频") {
                UPUpload(fileList: $videos,
                         accept: "video",
                         maxCount: 10,
                         name: "2",
                         multiple: true,
                         autoDelete: true)
                    .onPick { _ in
                        videos.append(UPUploadFile(name: "clip-\(videos.count + 1).mp4",
                                                   url: "https://uview-plus.jiangruyi.com/uview/video.mp4"))
                    }

                tip("accept 为 video 时无名文件也按视频渲染。")
            }

            DemoSection("文件预览") {
                UPUpload(fileList: $preview,
                         maxCount: 10,
                         name: "3",
                         multiple: true,
                         autoDelete: true)
                    .onPick { _ in preview += makeFiles(count: 1) }
                    .onClickPreview { event in
                        log = "clickPreview：第 \(event.current + 1) / \(event.urls.count) 张"
                    }

                tip("原生没有系统预览层，clickPreview 会带上同类文件的 urls 与 current。")
            }

            DemoSection("隐藏上传按钮") {
                UPUpload(fileList: $filled, maxCount: 2, name: "4", multiple: true, autoDelete: true)
                tip("已选数量达到 maxCount 时上传按钮自动隐藏。")
            }

            DemoSection("限制上传数量") {
                UPUpload(fileList: $limited, maxCount: 3, name: "5", multiple: true, autoDelete: true)
                    .onPick { request in limited += makeFiles(count: request.maxCount) }
                tip("maxCount 为 3，chooseFile 会把剩余可选数量带出来。")
            }

            DemoSection("自定义上传样式") {
                UPUpload(fileList: $custom,
                         maxCount: 1,
                         name: "6",
                         multiple: true,
                         width: 250,
                         height: 150,
                         autoDelete: true)
                    .trigger {
                        UPImage(src: "https://uview-plus.jiangruyi.com/uview/demo/upload/positive.png",
                                mode: "widthFix",
                                width: 250,
                                height: 150)
                    }
                    .onPick { _ in custom += makeFiles(count: 1) }
            }

            DemoSection("上传状态") {
                UPUpload(fileList: $uploading, maxCount: 3, name: "7", autoDelete: true)

                HStack(spacing: 12) {
                    UPButton(size: "small", text: "进度 80%") {
                        uploading[0].status = .uploading
                        uploading[0].progress = 80
                    }
                    UPButton(type: "success", size: "small", text: "标记成功") {
                        uploading[0].status = .success
                        uploading[0].progress = 100
                        uploading[0].message = ""
                    }
                }

                tip("uploading 与 failed 会盖半透明状态层，底部是 3pt 进度条。")
            }

            DemoSection("自定义上传文案") {
                UPUpload(fileList: .constant([]),
                         uploadIcon: "plus",
                         maxCount: 1,
                         uploadText: "上传图片")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPUpload 已覆盖上游 27 个 prop（extension 因是 Swift 关键字改名为 extensions），事件为 onBeforeRead / onAfterRead / onOversize / onDelete / onClickPreview / onError / onAfterAutoUpload，方法 chooseFile() / receive(_:) / resumeBeforeRead(_:ok:) / deleteItem(at:) / updateUpload(at:progress:) / successUpload(at:url:thumb:) / clickPreview(at:)，并保留仓库既有的 add / delete / updateProgress / complete。三处平台差异：accept / capture / camera / compressed / sizeType / maxDuration / extensions 是 uni.chooseImage 系列的参数，iOS 要由宿主用 PhotosPicker 或 fileImporter 选完再调 receive(_:)，onPick 会把这些参数原样带出；previewFullImage 对应的系统预览层不存在，改由 clickPreview 负载给出 urls 与 current；getVideoThumb 依赖 canvas 抓帧，只保留取值。autoUpload 走 multipart POST 的 local 驱动，oss / cos / kodo 需要各家签名接口，传入时会抛 error。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func makeFiles(count: Int) -> [UPUploadFile] {
        guard count > 0 else { return [] }
        return (0..<count).map { offset in
            let index = (basic.count + offset) % sampleURLs.count
            return UPUploadFile(name: "photo-\(index + 1).jpg", url: sampleURLs[index], size: 1_024)
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
