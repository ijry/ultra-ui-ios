import Foundation

/// 上游 `fileList` 里每一项的状态字符串。
public enum UPUploadStatus: String, Equatable, Sendable {
    case idle = ""
    case uploading
    case failed
    case success
}

/// `u-upload` 的一项文件。上游是普通对象，字段随选取来源（image/video/media/file）
/// 略有差异，这里取并集：`url` / `thumb` / `type` / `size` / `status` / `message` /
/// `progress` / `deletable` / `width` / `height`，另外保留仓库既有的 `data` /
/// `mimeType`，便于宿主直接持有本地字节。
public struct UPUploadFile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var url: String
    public var thumb: String
    /// `"image"` / `"video"` / 空串（其他文件）。
    public var type: String
    public var size: Int
    public var status: UPUploadStatus
    public var message: String
    /// 上游是 0…100 的整数百分比。
    public var progress: Int
    /// 上游 `item.deletable` 可以逐项覆盖组件的 `deletable`。
    public var deletable: Bool?
    public var width: CGFloat
    public var height: CGFloat
    public var data: Data
    public var mimeType: String

    public init(id: UUID = UUID(),
                name: String = "",
                url: String = "",
                thumb: String = "",
                type: String = "",
                size: Int = 0,
                status: UPUploadStatus = .idle,
                message: String = "",
                progress: Int = 0,
                deletable: Bool? = nil,
                width: CGFloat = 0,
                height: CGFloat = 0,
                data: Data = Data(),
                mimeType: String = "application/octet-stream") {
        self.id = id
        self.name = name
        self.url = url
        self.thumb = thumb
        self.type = type
        self.size = size
        self.status = status
        self.message = message
        self.progress = progress
        self.deletable = deletable
        self.width = width
        self.height = height
        self.data = data
        self.mimeType = mimeType
    }

    /// 仓库既有签名。
    public init(id: UUID = UUID(), name: String, data: Data, mimeType: String = "application/octet-stream") {
        self.init(id: id,
                  name: name,
                  size: data.count,
                  data: data,
                  mimeType: mimeType)
    }

    /// 上游 `formatFileList` 取 `item.name || item.url || item.thumb` 判定类型。
    public var typeSource: String {
        if !name.isEmpty { return name }
        if !url.isEmpty { return url }
        return thumb
    }

    /// 对应上游 `test.image(value)`：`/\.(jpeg|jpg|gif|png|svg|webp|jfif|bmp|dpg)/i`，
    /// 且先截掉 query。
    public static func isImageSource(_ value: String) -> Bool {
        let path = value.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        return matches(path.lowercased(),
                       extensions: ["jpeg", "jpg", "gif", "png", "svg", "webp", "jfif", "bmp", "dpg"])
    }

    /// 对应上游 `test.video(value)`：`/\.(mp4|mpg|mpeg|dat|asf|avi|rm|rmvb|mov|wmv|flv|mkv|m3u8)/i`，
    /// 注意上游这里**没有**截 query。
    public static func isVideoSource(_ value: String) -> Bool {
        matches(value.lowercased(),
                extensions: ["mp4", "mpg", "mpeg", "dat", "asf", "avi", "rm", "rmvb", "mov", "wmv", "flv", "mkv", "m3u8"])
    }

    private static func matches(_ value: some StringProtocol, extensions: [String]) -> Bool {
        extensions.contains { value.contains(".\($0)") }
    }
}

/// `beforeRead` / `afterRead` / `oversize` 的事件负载，对应上游
/// `Object.assign({ file }, this.getDetail())`。`file` 在 `multiple` 时是数组，
/// 原生统一用数组承载。
public struct UPUploadReadEvent: Equatable, Sendable {
    public let files: [UPUploadFile]
    /// 上游 `name` prop，用于同页多个上传组件区分来源。
    public let name: String
    public let index: Int

    public init(files: [UPUploadFile], name: String, index: Int) {
        self.files = files
        self.name = name
        self.index = index
    }

    public var file: UPUploadFile? { files.first }
}

/// `delete` 的事件负载，对应上游 `{ name, index, file }`。
public struct UPUploadDeleteEvent: Equatable, Sendable {
    public let file: UPUploadFile
    public let name: String
    public let index: Int

    public init(file: UPUploadFile, name: String, index: Int) {
        self.file = file
        self.name = name
        self.index = index
    }
}

/// `clickPreview` 的事件负载，对应上游 `Object.assign({}, item, this.getDetail(index))`。
public struct UPUploadPreviewEvent: Equatable, Sendable {
    public let file: UPUploadFile
    public let name: String
    public let index: Int
    /// 预览时同类文件的地址集合与当前位置，对应上游 `previewImage` /
    /// `previewMedia` 的 `urls` + `current`。
    public let urls: [String]
    public let current: Int

    public init(file: UPUploadFile, name: String, index: Int, urls: [String], current: Int) {
        self.file = file
        self.name = name
        self.index = index
        self.urls = urls
        self.current = current
    }
}

/// `afterAutoUpload` 的事件负载：上游把接口返回体连同 `callback` 一起抛出，
/// 宿主回填 `{ url, thumb }` 决定最终落库地址。
public struct UPUploadAutoUploadEvent: Sendable {
    public let file: UPUploadFile
    public let index: Int
    /// 上游把 `uploadFile` 的响应体原样带出，原生用字符串承载。
    public let response: String
    public let callback: @Sendable (String, String) -> Void

    public init(file: UPUploadFile,
                index: Int,
                response: String,
                callback: @escaping @Sendable (String, String) -> Void) {
        self.file = file
        self.index = index
        self.response = response
        self.callback = callback
    }
}

/// 一次自动上传请求，对应上游 `uni.uploadFile` 的参数。
public struct UPUploadRequest: Equatable, Sendable {
    public let url: String
    public let header: [String: String]
    /// 上游写死 `name: 'file'`。
    public let fieldName: String

    public init(url: String, header: [String: String], fieldName: String = "file") {
        self.url = url
        self.header = header
        self.fieldName = fieldName
    }
}

/// 自动上传的结果：`url` 是最终地址，`response` 供 `afterAutoUpload` 使用。
public struct UPUploadResult: Equatable, Sendable {
    public let url: String
    public let thumb: String
    public let response: String

    public init(url: String, thumb: String = "", response: String = "") {
        self.url = url
        self.thumb = thumb
        self.response = response
    }
}

/// 自动上传的传输层，可注入以便单测。
public typealias UPUploadTransport = @Sendable (UPUploadFile, UPUploadRequest) async -> Result<UPUploadResult, Error>

/// 默认传输层：`multipart/form-data` POST，等价于 `uni.uploadFile` 的默认行为。
/// 只有宿主显式开启 `autoUpload` 并给出 `autoUploadApi` 时才会发起请求。
public enum UPUploadSystemTransport {
    public static let boundary = "UltraUIUploadBoundary"

    public static let send: UPUploadTransport = { file, request in
        guard let url = URL(string: request.url), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            return .failure(UPUploadError.invalidEndpoint(request.url))
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        for (key, value) in request.header { urlRequest.setValue(value, forHTTPHeaderField: key) }
        urlRequest.httpBody = body(for: file, fieldName: request.fieldName)
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let text = String(data: data, encoding: .utf8) ?? ""
            return .success(UPUploadResult(url: file.url, thumb: file.thumb, response: text))
        } catch {
            return .failure(error)
        }
    }

    static func body(for file: UPUploadFile, fieldName: String) -> Data {
        var body = Data()
        let filename = file.name.isEmpty ? "file" : file.name
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(file.mimeType)\r\n\r\n".utf8))
        body.append(file.data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }
}

public enum UPUploadError: LocalizedError, Equatable {
    case invalidEndpoint(String)
    case unsupportedDriver(String)

    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let value): return "无效的上传地址：\(value)"
        case .unsupportedDriver(let value): return "不支持的上传驱动：\(value)"
        }
    }
}
