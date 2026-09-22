import Foundation
import Observation
import SwiftUI

/// 上游 `data.lists` 与 `fileList` 的可变副本；值类型 View 无法直接持有可变状态。
@MainActor
@Observable
private final class UPUploadState {
    var files: [UPUploadFile]
    /// 仓库既有的整体进度（0…1），与上游逐项 `progress` 并存。
    var progress: Double = 0

    init(files: [UPUploadFile]) {
        self.files = files
    }
}

/// Native SwiftUI counterpart of uview-plus `u-upload`.
///
/// 与上游的差异集中在「选文件」和「预览」两处平台能力：
/// - `accept` / `capture` / `camera` / `compressed` / `sizeType` / `maxDuration` /
///   `extension` 是 `uni.chooseImage` / `chooseVideo` / `chooseMedia` / `chooseFile`
///   的参数，iOS 上要由宿主用 `PhotosPicker` / `fileImporter` 选完再调
///   `receive(_:)`；这些 prop 原样保留，`pickerRequest` 会把它们打包给宿主。
/// - `previewFullImage` 上游调 `uni.previewImage` / `previewMedia`，仓库内没有预览
///   层，原生把同类文件的 `urls` + `current` 放进 `clickPreview` 负载交给宿主。
/// - `getVideoThumb` 上游用 canvas 抓视频首帧，原生没有对应能力，只保留取值。
/// - `autoUpload` 走 `UPUploadTransport`（默认 multipart POST）；`oss` / `cos` /
///   `kodo` 三个云直传驱动依赖各家签名接口，原生只实现 `local`（默认）分支，
///   其余驱动会抛 `error`。
@MainActor
public struct UPUpload: View {
    public var accept: String
    /// 上游 prop 名是 `extension`，Swift 里是关键字，改用 `extensions`。
    public var extensions: [String]
    public var capture: [String]
    public var compressed: Bool
    public var camera: String
    public var maxDuration: Double
    public var uploadIcon: String
    public var uploadIconColor: String
    public var useBeforeRead: Bool
    public var previewFullImage: Bool
    public var maxCount: Int
    public var disabled: Bool
    public var imageMode: String
    public var name: String
    public var sizeType: [String]
    public var multiple: Bool
    public var deletable: Bool
    public var maxSize: Int
    public var uploadText: String
    public var width: CGFloat
    public var height: CGFloat
    public var previewImage: Bool
    public var autoDelete: Bool
    public var autoUpload: Bool
    public var autoUploadApi: String
    public var autoUploadAuthUrl: String
    public var autoUploadDriver: String
    public var autoUploadHeader: [String: String]
    /// 上游用 canvas 抓首帧，原生没有对应能力，保留取值。
    public var getVideoThumb: Bool
    public var customAfterAutoUpload: Bool
    public var videoPreviewObjectFit: String
    public var customStyle: UPStyle

    /// 对应上游 `v-model:fileList`。
    private var fileListBinding: Binding<[UPUploadFile]>?

    public var files: [UPUploadFile] { fileListBinding?.wrappedValue ?? state.files }
    public var progress: Double { state.progress }

    @State private var state: UPUploadState
    @Environment(\.upTheme) private var theme
    private var beforeReadHandler: ((UPUploadReadEvent) -> Bool)?
    private var onBeforeReadHandler: ((UPUploadReadEvent) -> Void)?
    private var afterReadHandler: ((UPUploadReadEvent) -> Void)?
    private var onAfterReadHandler: ((UPUploadReadEvent) -> Void)?
    private var legacyAfterReadHandler: (([UPUploadFile]) -> Void)?
    private var onOversizeHandler: ((UPUploadReadEvent) -> Void)?
    private var onDeleteHandler: ((UPUploadDeleteEvent) -> Void)?
    private var legacyDeleteHandler: ((UPUploadFile) -> Void)?
    private var onClickPreviewHandler: ((UPUploadPreviewEvent) -> Void)?
    private var onErrorHandler: ((String) -> Void)?
    private var onAfterAutoUploadHandler: ((UPUploadAutoUploadEvent) -> Void)?
    private var onProgressHandler: ((Double) -> Void)?
    private var onSuccessHandler: (([UPUploadFile]) -> Void)?
    private var onPickHandler: ((UPUploadPickRequest) -> Void)?
    private var triggerSlot: AnyView?
    var transport: UPUploadTransport

    /// 仓库既有签名。
    public init(files: [UPUploadFile] = UPConfig.upload.fileList,
                maxCount: Int = UPConfig.upload.maxCount,
                disabled: Bool = UPConfig.upload.disabled) {
        self.init(fileList: files, maxCount: maxCount, disabled: disabled)
    }

    /// 与上游 `props.js` 对齐的初始化器。
    public init(fileList: [UPUploadFile] = UPConfig.upload.fileList,
                accept: String = UPConfig.upload.accept,
                extensions: [String] = UPConfig.upload.extensions,
                capture: [String] = UPConfig.upload.capture,
                compressed: Bool = UPConfig.upload.compressed,
                camera: String = UPConfig.upload.camera,
                maxDuration: some UPListUnitValue = UPConfig.upload.maxDuration,
                uploadIcon: String = UPConfig.upload.uploadIcon,
                uploadIconColor: String = UPConfig.upload.uploadIconColor,
                useBeforeRead: Bool = UPConfig.upload.useBeforeRead,
                previewFullImage: Bool = UPConfig.upload.previewFullImage,
                maxCount: some UPListUnitValue = UPConfig.upload.maxCount,
                disabled: Bool = UPConfig.upload.disabled,
                imageMode: String = UPConfig.upload.imageMode,
                name: String = UPConfig.upload.name,
                sizeType: [String] = UPConfig.upload.sizeType,
                multiple: Bool = UPConfig.upload.multiple,
                deletable: Bool = UPConfig.upload.deletable,
                maxSize: Int = UPConfig.upload.maxSize,
                uploadText: String = UPConfig.upload.uploadText,
                width: some UPListUnitValue = UPConfig.upload.width,
                height: some UPListUnitValue = UPConfig.upload.height,
                previewImage: Bool = UPConfig.upload.previewImage,
                autoDelete: Bool = UPConfig.upload.autoDelete,
                autoUpload: Bool = UPConfig.upload.autoUpload,
                autoUploadApi: String = UPConfig.upload.autoUploadApi,
                autoUploadAuthUrl: String = UPConfig.upload.autoUploadAuthUrl,
                autoUploadDriver: String = UPConfig.upload.autoUploadDriver,
                autoUploadHeader: [String: String] = UPConfig.upload.autoUploadHeader,
                getVideoThumb: Bool = UPConfig.upload.getVideoThumb,
                customAfterAutoUpload: Bool = UPConfig.upload.customAfterAutoUpload,
                videoPreviewObjectFit: String = UPConfig.upload.videoPreviewObjectFit,
                customStyle: UPStyle = UPStyle(),
                beforeRead: ((UPUploadReadEvent) -> Bool)? = nil,
                afterRead: ((UPUploadReadEvent) -> Void)? = nil) {
        self.fileListBinding = nil
        self.accept = accept
        self.extensions = extensions
        self.capture = capture
        self.compressed = compressed
        self.camera = camera
        self.maxDuration = Double(UPUnit.parse(maxDuration.upImageUnitValue))
        self.uploadIcon = uploadIcon
        self.uploadIconColor = uploadIconColor
        self.useBeforeRead = useBeforeRead
        self.previewFullImage = previewFullImage
        self.maxCount = max(0, Int(UPUnit.parse(maxCount.upImageUnitValue)))
        self.disabled = disabled
        self.imageMode = imageMode
        self.name = name
        self.sizeType = sizeType
        self.multiple = multiple
        self.deletable = deletable
        self.maxSize = maxSize
        self.uploadText = uploadText
        self.width = max(UPUnit.parse(width.upImageUnitValue), 0)
        self.height = max(UPUnit.parse(height.upImageUnitValue), 0)
        self.previewImage = previewImage
        self.autoDelete = autoDelete
        self.autoUpload = autoUpload
        self.autoUploadApi = autoUploadApi
        self.autoUploadAuthUrl = autoUploadAuthUrl
        self.autoUploadDriver = autoUploadDriver
        self.autoUploadHeader = autoUploadHeader
        self.getVideoThumb = getVideoThumb
        self.customAfterAutoUpload = customAfterAutoUpload
        self.videoPreviewObjectFit = videoPreviewObjectFit
        self.customStyle = customStyle
        self.beforeReadHandler = beforeRead
        self.afterReadHandler = afterRead
        self.transport = UPUploadSystemTransport.send
        self._state = State(initialValue: UPUploadState(files: fileList))
    }

    /// `v-model:fileList` 版本：文件列表由宿主持有。
    public init(fileList: Binding<[UPUploadFile]>,
                accept: String = UPConfig.upload.accept,
                extensions: [String] = UPConfig.upload.extensions,
                capture: [String] = UPConfig.upload.capture,
                compressed: Bool = UPConfig.upload.compressed,
                camera: String = UPConfig.upload.camera,
                maxDuration: some UPListUnitValue = UPConfig.upload.maxDuration,
                uploadIcon: String = UPConfig.upload.uploadIcon,
                uploadIconColor: String = UPConfig.upload.uploadIconColor,
                useBeforeRead: Bool = UPConfig.upload.useBeforeRead,
                previewFullImage: Bool = UPConfig.upload.previewFullImage,
                maxCount: some UPListUnitValue = UPConfig.upload.maxCount,
                disabled: Bool = UPConfig.upload.disabled,
                imageMode: String = UPConfig.upload.imageMode,
                name: String = UPConfig.upload.name,
                sizeType: [String] = UPConfig.upload.sizeType,
                multiple: Bool = UPConfig.upload.multiple,
                deletable: Bool = UPConfig.upload.deletable,
                maxSize: Int = UPConfig.upload.maxSize,
                uploadText: String = UPConfig.upload.uploadText,
                width: some UPListUnitValue = UPConfig.upload.width,
                height: some UPListUnitValue = UPConfig.upload.height,
                previewImage: Bool = UPConfig.upload.previewImage,
                autoDelete: Bool = UPConfig.upload.autoDelete,
                autoUpload: Bool = UPConfig.upload.autoUpload,
                autoUploadApi: String = UPConfig.upload.autoUploadApi,
                autoUploadAuthUrl: String = UPConfig.upload.autoUploadAuthUrl,
                autoUploadDriver: String = UPConfig.upload.autoUploadDriver,
                autoUploadHeader: [String: String] = UPConfig.upload.autoUploadHeader,
                getVideoThumb: Bool = UPConfig.upload.getVideoThumb,
                customAfterAutoUpload: Bool = UPConfig.upload.customAfterAutoUpload,
                videoPreviewObjectFit: String = UPConfig.upload.videoPreviewObjectFit,
                customStyle: UPStyle = UPStyle(),
                beforeRead: ((UPUploadReadEvent) -> Bool)? = nil,
                afterRead: ((UPUploadReadEvent) -> Void)? = nil) {
        self.init(fileList: fileList.wrappedValue,
                  accept: accept,
                  extensions: extensions,
                  capture: capture,
                  compressed: compressed,
                  camera: camera,
                  maxDuration: maxDuration,
                  uploadIcon: uploadIcon,
                  uploadIconColor: uploadIconColor,
                  useBeforeRead: useBeforeRead,
                  previewFullImage: previewFullImage,
                  maxCount: maxCount,
                  disabled: disabled,
                  imageMode: imageMode,
                  name: name,
                  sizeType: sizeType,
                  multiple: multiple,
                  deletable: deletable,
                  maxSize: maxSize,
                  uploadText: uploadText,
                  width: width,
                  height: height,
                  previewImage: previewImage,
                  autoDelete: autoDelete,
                  autoUpload: autoUpload,
                  autoUploadApi: autoUploadApi,
                  autoUploadAuthUrl: autoUploadAuthUrl,
                  autoUploadDriver: autoUploadDriver,
                  autoUploadHeader: autoUploadHeader,
                  getVideoThumb: getVideoThumb,
                  customAfterAutoUpload: customAfterAutoUpload,
                  videoPreviewObjectFit: videoPreviewObjectFit,
                  customStyle: customStyle,
                  beforeRead: beforeRead,
                  afterRead: afterRead)
        self.fileListBinding = fileList
    }

    // MARK: - 解析后的呈现值

    /// 对应上游 `formatFileList` 的结果：补 `isImage` / `isVideo` / `deletable`。
    public var lists: [UPUploadFile] {
        files.map { file in
            var item = file
            if item.type.isEmpty {
                item.type = Self.resolvedType(for: file, accept: accept)
            }
            if item.deletable == nil { item.deletable = deletable }
            return item
        }
    }

    /// 对应上游 `data.isInCount`。
    public var isInCount: Bool { files.count < maxCount }

    /// 上游 `formatFileList`：`item.name` 非空时只看文件名，否则先看 `accept`。
    public static func resolvedType(for file: UPUploadFile, accept: String) -> String {
        if !file.name.isEmpty {
            if UPUploadFile.isImageSource(file.name) { return "image" }
            if UPUploadFile.isVideoSource(file.name) { return "video" }
            return ""
        }
        let source = file.typeSource
        if accept == "image" || UPUploadFile.isImageSource(source) { return "image" }
        if accept == "video" || UPUploadFile.isVideoSource(source) { return "video" }
        return ""
    }

    /// 上游 `resolvedUploadIconColor`：默认值时改用主题的 content 色。
    public var resolvedUploadIconColor: Color {
        uploadIconColor == UPConfig.upload.uploadIconColor
            ? theme.info
            : UPColor.parse(uploadIconColor, theme: theme)
    }

    /// 对应上游 `getDetail(index)`。
    public func detail(index: Int? = nil) -> (name: String, index: Int) {
        (name, index ?? files.count)
    }

    /// 打包给宿主的选文件参数，对应上游 `chooseFile(chooseParams)`。
    public var pickerRequest: UPUploadPickRequest {
        UPUploadPickRequest(accept: accept,
                            extensions: extensions,
                            multiple: multiple,
                            capture: capture,
                            compressed: compressed,
                            maxDuration: maxDuration,
                            sizeType: sizeType,
                            camera: camera,
                            maxCount: max(maxCount - files.count, 0))
    }

    // MARK: - 上游方法

    /// 对应上游 `chooseFile`：`disabled` 时直接 reject，否则把参数交给宿主。
    public func chooseFile() {
        guard !disabled else { return }
        onPickHandler?(pickerRequest)
    }

    /// 宿主选完文件后调用，对应上游 `chooseFile().then(onBeforeRead)`。
    /// `multiple` 为假时上游只取第一个。
    public func receive(_ picked: [UPUploadFile]) {
        let incoming = multiple ? picked : Array(picked.prefix(1))
        guard !incoming.isEmpty else { return }
        onBeforeRead(incoming)
    }

    /// 对应上游 `onBeforeRead`：`beforeRead` 闭包返回 false 或 `useBeforeRead`
    /// 的回调传 false 时中断，否则进入 `onAfterRead`。
    public func onBeforeRead(_ incoming: [UPUploadFile]) {
        let event = UPUploadReadEvent(files: incoming, name: name, index: files.count)
        if let beforeReadHandler, !beforeReadHandler(event) { return }
        if useBeforeRead {
            onBeforeReadHandler?(event)
            return
        }
        onAfterRead(incoming)
    }

    /// 上游 `useBeforeRead` 的 `callback(ok)`。
    public func resumeBeforeRead(_ incoming: [UPUploadFile], ok: Bool) {
        guard ok else { return }
        onAfterRead(incoming)
    }

    /// 对应上游 `onAfterRead`：先查 `maxSize`，再按 `autoUpload` 决定是入队上传
    /// 还是直接抛 `afterRead`。
    public func onAfterRead(_ incoming: [UPUploadFile]) {
        let event = UPUploadReadEvent(files: incoming, name: name, index: files.count)
        if incoming.contains(where: { $0.size > maxSize }) {
            UPToast.show(message: "超过大小限制")
            onOversizeHandler?(event)
            return
        }
        guard autoUpload else {
            afterReadHandler?(event)
            onAfterReadHandler?(event)
            legacyAfterReadHandler?(incoming)
            return
        }
        startAutoUpload(incoming)
    }

    /// 仓库既有签名：把单个文件加入列表并抛 `afterRead`。
    public func add(_ file: UPUploadFile) {
        guard !disabled, isInCount else { return }
        write(files + [file])
        let event = UPUploadReadEvent(files: [file], name: name, index: files.count - 1)
        afterReadHandler?(event)
        onAfterReadHandler?(event)
        legacyAfterReadHandler?(files)
    }

    /// 对应上游 `deleteItem(index)`：`autoDelete` 为真时自己删，否则抛 `delete`
    /// 交给宿主决定。
    public func deleteItem(at index: Int) {
        guard files.indices.contains(index) else { return }
        let file = files[index]
        if autoDelete {
            var next = files
            next.remove(at: index)
            write(next)
        }
        onDeleteHandler?(UPUploadDeleteEvent(file: file, name: name, index: index))
        legacyDeleteHandler?(file)
    }

    /// 仓库既有签名：按 id 删除，语义等价于 `autoDelete` 为真。
    public func delete(_ id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        let file = files[index]
        var next = files
        next.remove(at: index)
        write(next)
        onDeleteHandler?(UPUploadDeleteEvent(file: file, name: name, index: index))
        legacyDeleteHandler?(file)
    }

    /// 对应上游 `updateUpload(index, param)`：`progress` 到 100 即视为成功。
    public func updateUpload(at index: Int, progress: Int) {
        guard files.indices.contains(index) else { return }
        var next = files
        next[index].status = progress >= 100 ? .success : .uploading
        next[index].message = ""
        next[index].progress = min(max(progress, 0), 100)
        write(next)
    }

    /// 对应上游 `succcessUpload(index, url, thumb)`（上游函数名即三个 c）。
    public func successUpload(at index: Int, url: String, thumb: String = "") {
        guard files.indices.contains(index) else { return }
        var next = files
        next[index].status = .success
        next[index].message = ""
        next[index].url = url
        next[index].thumb = thumb
        next[index].progress = 100
        write(next)
    }

    /// 对应上游 `onClickPreview`：`previewFullImage` 为真时收集同类文件的地址，
    /// 一并放进 `clickPreview` 负载。
    public func clickPreview(at index: Int) {
        let items = lists
        guard items.indices.contains(index) else { return }
        let item = items[index]
        var urls: [String] = []
        var current = 0
        if previewFullImage, item.type == "image" || item.type == "video" {
            for (offset, candidate) in items.enumerated() where candidate.type == item.type {
                if offset == index { current = urls.count }
                urls.append(candidate.url.isEmpty ? candidate.thumb : candidate.url)
            }
        }
        onClickPreviewHandler?(UPUploadPreviewEvent(file: item,
                                                   name: name,
                                                   index: index,
                                                   urls: urls,
                                                   current: current))
    }

    /// 仓库既有的整体进度。
    public func updateProgress(_ value: Double) {
        state.progress = min(max(value, 0), 1)
        onProgressHandler?(state.progress)
    }

    public func complete() {
        state.progress = 1
        onSuccessHandler?(files)
    }

    /// 对应上游 `onAfterRead` 里 `autoUpload` 的分支。
    private func startAutoUpload(_ incoming: [UPUploadFile]) {
        let driver = autoUploadDriver.isEmpty ? "local" : autoUploadDriver
        guard driver == "local" else {
            onErrorHandler?(UPUploadError.unsupportedDriver(driver).localizedDescription)
            return
        }
        let offset = files.count
        var next = files
        for file in incoming {
            var pending = file
            pending.status = .uploading
            pending.message = "上传中"
            pending.progress = 0
            next.append(pending)
        }
        write(next)

        let request = UPUploadRequest(url: autoUploadApi, header: autoUploadHeader)
        let transport = self.transport
        for (position, file) in incoming.enumerated() {
            let index = offset + position
            Task { @MainActor in
                switch await transport(file, request) {
                case .success(let result):
                    guard customAfterAutoUpload else {
                        successUpload(at: index, url: result.url, thumb: result.thumb)
                        return
                    }
                    // 上游把响应体连同 callback 抛给宿主，由宿主回填最终地址。
                    onAfterAutoUploadHandler?(UPUploadAutoUploadEvent(
                        file: file,
                        index: index,
                        response: result.response,
                        callback: { url, thumb in
                            Task { @MainActor in successUpload(at: index, url: url, thumb: thumb) }
                        }
                    ))
                case .failure(let error):
                    var failed = files
                    if failed.indices.contains(index) {
                        failed[index].status = .failed
                        failed[index].message = error.localizedDescription
                        write(failed)
                    }
                    onErrorHandler?(error.localizedDescription)
                }
            }
        }
    }

    /// 对应上游 `$emit('update:fileList', ...)`。
    private func write(_ next: [UPUploadFile]) {
        state.files = next
        fileListBinding?.wrappedValue = next
    }

    // MARK: - 视图

    public var body: some View {
        UPAlbumWrapLayout(spacing: 8, lineSpacing: 8) {
            if previewImage {
                ForEach(Array(lists.enumerated()), id: \.element.id) { index, item in
                    preview(item, index: index)
                }
            }

            if isInCount { triggerView }
        }
        .upStyle(customStyle)
    }

    @ViewBuilder
    private func preview(_ item: UPUploadFile, index: Int) -> some View {
        thumbnail(item)
            .frame(width: width, height: height)
            .background(UPColor.parse(UPConfig.image.bgColor, theme: theme))
            .overlay { RoundedRectangle(cornerRadius: 2).strokeBorder(theme.border, lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay { statusLayer(item) }
            .overlay(alignment: .topTrailing) { deleteBadge(item, index: index) }
            .contentShape(Rectangle())
            .onTapGesture { clickPreview(at: index) }
    }

    @ViewBuilder
    private func thumbnail(_ item: UPUploadFile) -> some View {
        let source = item.thumb.isEmpty ? item.url : item.thumb
        if item.type == "image", !source.isEmpty {
            UPImage(src: source, mode: imageMode, width: width, height: height)
        } else {
            VStack(spacing: 2) {
                UPIcon(name: item.type == "video" ? "uicon-movie" : "uicon-folder",
                       color: "#80CBF9",
                       size: "26")
                Text(item.name.isEmpty ? (item.type == "video" ? "视频" : "文件") : item.name)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.tips)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }

    /// 上游 `.u-upload__status`：半透明黑底 + 图标 + 文案 + 底部 3px 进度条。
    @ViewBuilder
    private func statusLayer(_ item: UPUploadFile) -> some View {
        if item.status == .uploading || item.status == .failed {
            ZStack {
                Color.black.opacity(0.5)
                VStack(spacing: 5) {
                    if item.status == .failed {
                        UPIcon(name: "uicon-close-circle", color: "#ffffff", size: "25")
                    } else {
                        UPLoadingIcon(mode: "circle", size: 22)
                    }
                    if !item.message.isEmpty {
                        Text(item.message)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .fill(theme.primary)
                    .frame(width: width * CGFloat(item.progress) / 100, height: 3)
            }
        }
    }

    /// 上游 `.u-upload__deletable`：右上角 14×14 的深色圆角块。
    @ViewBuilder
    private func deleteBadge(_ item: UPUploadFile, index: Int) -> some View {
        if item.status != .uploading, item.deletable ?? deletable {
            UPIcon(name: "uicon-close", color: "#ffffff", size: "10")
                .frame(width: 14, height: 14)
                .background(Color(hex: 0x373737))
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 100))
                .contentShape(Rectangle())
                .onTapGesture { deleteItem(at: index) }
        }
    }

    /// 上游 `#trigger` / 默认插槽优先，否则渲染带图标的方形按钮。
    @ViewBuilder
    private var triggerView: some View {
        if let triggerSlot {
            triggerSlot
                .contentShape(Rectangle())
                .onTapGesture { chooseFile() }
        } else {
            VStack(spacing: 2) {
                UPIcon(name: uploadIcon, size: "26")
                    .foregroundStyle(resolvedUploadIconColor)
                if !uploadText.isEmpty {
                    Text(uploadText)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.tips)
                }
            }
            .frame(width: width, height: height)
            .background(UPColor.parse("#f4f5f7", theme: theme))
            .overlay { RoundedRectangle(cornerRadius: 2).strokeBorder(theme.border, lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .opacity(disabled ? 0.5 : 1)
            .contentShape(Rectangle())
            .onTapGesture { chooseFile() }
        }
    }
}

/// 选文件参数，对应上游 `chooseFile(chooseParams)` 的入参。
public struct UPUploadPickRequest: Equatable, Sendable {
    public let accept: String
    public let extensions: [String]
    public let multiple: Bool
    public let capture: [String]
    public let compressed: Bool
    public let maxDuration: Double
    public let sizeType: [String]
    public let camera: String
    /// 上游 `maxCount - lists.length`：本次还能选几个。
    public let maxCount: Int

    public init(accept: String,
                extensions: [String],
                multiple: Bool,
                capture: [String],
                compressed: Bool,
                maxDuration: Double,
                sizeType: [String],
                camera: String,
                maxCount: Int) {
        self.accept = accept
        self.extensions = extensions
        self.multiple = multiple
        self.capture = capture
        self.compressed = compressed
        self.maxDuration = maxDuration
        self.sizeType = sizeType
        self.camera = camera
        self.maxCount = maxCount
    }
}

public extension UPUpload {
    /// 等价于上游 `$slots.trigger` 是否存在。
    var hasTriggerSlot: Bool { triggerSlot != nil }

    /// 对应上游 `#trigger`（与默认插槽同义）具名插槽。
    func trigger<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPUpload {
        var copy = self
        copy.triggerSlot = AnyView(builder())
        return copy
    }

    /// 点了「选择文件」时触发，负载是上游 `chooseFile` 的参数。
    func onPick(_ action: @escaping (UPUploadPickRequest) -> Void) -> UPUpload {
        var copy = self
        copy.onPickHandler = action
        return copy
    }

    /// 对应上游 `beforeRead` 事件（需 `useBeforeRead`），用 `resumeBeforeRead` 放行。
    func onBeforeRead(_ action: @escaping (UPUploadReadEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onBeforeReadHandler = action
        return copy
    }

    /// 对应上游 `afterRead` 事件。
    func onAfterRead(_ action: @escaping (UPUploadReadEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onAfterReadHandler = action
        return copy
    }

    /// 仓库既有签名。
    func onAfterRead(_ action: @escaping ([UPUploadFile]) -> Void) -> UPUpload {
        var copy = self
        copy.legacyAfterReadHandler = action
        return copy
    }

    /// 对应上游 `oversize` 事件。
    func onOversize(_ action: @escaping (UPUploadReadEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onOversizeHandler = action
        return copy
    }

    /// 对应上游 `delete` 事件。
    func onDelete(_ action: @escaping (UPUploadDeleteEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onDeleteHandler = action
        return copy
    }

    /// 仓库既有签名。
    func onDelete(_ action: @escaping (UPUploadFile) -> Void) -> UPUpload {
        var copy = self
        copy.legacyDeleteHandler = action
        return copy
    }

    /// 对应上游 `clickPreview` 事件。
    func onClickPreview(_ action: @escaping (UPUploadPreviewEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onClickPreviewHandler = action
        return copy
    }

    /// 对应上游 `error` 事件。
    func onError(_ action: @escaping (String) -> Void) -> UPUpload {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    /// 对应上游 `afterAutoUpload` 事件（需 `customAfterAutoUpload`）。
    func onAfterAutoUpload(_ action: @escaping (UPUploadAutoUploadEvent) -> Void) -> UPUpload {
        var copy = self
        copy.onAfterAutoUploadHandler = action
        return copy
    }

    /// 仓库既有的整体进度回调。
    func onProgress(_ action: @escaping (Double) -> Void) -> UPUpload {
        var copy = self
        copy.onProgressHandler = action
        return copy
    }

    /// 仓库既有的整体完成回调。
    func onSuccess(_ action: @escaping ([UPUploadFile]) -> Void) -> UPUpload {
        var copy = self
        copy.onSuccessHandler = action
        return copy
    }
}

extension UPUpload {
    /// 注入自动上传的传输层，仅供单测使用。
    func uploadTransport(_ transport: @escaping UPUploadTransport) -> UPUpload {
        var copy = self
        copy.transport = transport
        return copy
    }
}
