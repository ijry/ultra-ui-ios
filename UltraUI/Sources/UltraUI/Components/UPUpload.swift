import Foundation
import SwiftUI

public struct UPUploadFile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var data: Data
    public var mimeType: String

    public init(id: UUID = UUID(), name: String, data: Data, mimeType: String = "application/octet-stream") {
        self.id = id
        self.name = name
        self.data = data
        self.mimeType = mimeType
    }
}

@MainActor
public final class UPUpload: View {
    public var maxCount: Int
    public var disabled: Bool
    public private(set) var files: [UPUploadFile]
    public private(set) var progress: Double = 0
    private var onAfterReadHandler: (([UPUploadFile]) -> Void)?
    private var onDeleteHandler: ((UPUploadFile) -> Void)?
    private var onProgressHandler: ((Double) -> Void)?
    private var onSuccessHandler: (([UPUploadFile]) -> Void)?

    public init(files: [UPUploadFile] = [], maxCount: Int = 52, disabled: Bool = false) {
        self.files = files
        self.maxCount = max(0, maxCount)
        self.disabled = disabled
    }

    public func onAfterRead(_ action: @escaping ([UPUploadFile]) -> Void) -> UPUpload { onAfterReadHandler = action; return self }
    public func onDelete(_ action: @escaping (UPUploadFile) -> Void) -> UPUpload { onDeleteHandler = action; return self }
    public func onProgress(_ action: @escaping (Double) -> Void) -> UPUpload { onProgressHandler = action; return self }
    public func onSuccess(_ action: @escaping ([UPUploadFile]) -> Void) -> UPUpload { onSuccessHandler = action; return self }

    public func add(_ file: UPUploadFile) {
        guard !disabled, files.count < maxCount else { return }
        files.append(file)
        onAfterReadHandler?(files)
    }

    public func delete(_ id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        let file = files.remove(at: index)
        onDeleteHandler?(file)
    }

    public func updateProgress(_ value: Double) {
        progress = min(max(value, 0), 1)
        onProgressHandler?(progress)
    }

    public func complete() {
        progress = 1
        onSuccessHandler?(files)
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 8) {
            ForEach(files) { file in
                VStack(spacing: 4) {
                    Image(systemName: "doc")
                    Text(file.name).font(.caption).lineLimit(1)
                }.frame(width: 72, height: 72)
            }
            if !disabled && files.count < maxCount {
                Image(systemName: "plus").frame(width: 72, height: 72)
                    .background(Color.secondary.opacity(0.1))
            }
        }
    }
}
