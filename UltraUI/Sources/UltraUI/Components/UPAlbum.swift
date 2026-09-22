import Observation
import SwiftUI

/// `u-album` 的一项图片。上游 `urls` 支持 `Array<String>` 与 `Array<Object>`，
/// 后者用 `keyName` 指定取哪个字段（缺省回落到 `src`），原生用这个枚举承载。
public enum UPAlbumItem: Equatable, Sendable {
    case source(String)
    case object([String: String])

    /// 对应上游 `getSrc(item)`。
    public func source(keyName: String) -> String {
        switch self {
        case .source(let value):
            return value
        case .object(let fields):
            if !keyName.isEmpty, let value = fields[keyName], !value.isEmpty { return value }
            return fields["src"] ?? ""
        }
    }
}

/// 让 `urls:` 同时接受 `[String]` 与 `[[String: String]]`。
public protocol UPAlbumItemValue {
    var upAlbumItem: UPAlbumItem { get }
}

extension String: UPAlbumItemValue {
    public var upAlbumItem: UPAlbumItem { .source(self) }
}

extension Dictionary: UPAlbumItemValue where Key == String, Value == String {
    public var upAlbumItem: UPAlbumItem { .object(self) }
}

extension UPAlbumItem: UPAlbumItemValue {
    public var upAlbumItem: UPAlbumItem { self }
}

/// `preview` 事件负载，对应上游 `$emit('preview', { urls, currentIndex })`。
public struct UPAlbumPreview: Equatable, Sendable {
    public let urls: [String]
    public let currentIndex: Int

    public init(urls: [String], currentIndex: Int) {
        self.urls = urls
        self.currentIndex = currentIndex
    }
}

/// SwiftUI requires views to be value types, so mutable selection state lives in
/// a small reference box rather than making the view itself a class.
@MainActor
@Observable
private final class UPAlbumState {
    var current = 0
}

/// Native SwiftUI counterpart of uview-plus `u-album`.
@MainActor
public struct UPAlbum: View {
    public var items: [UPAlbumItem]
    public let keyName: String
    /// 上游单位跟随 `unit`（默认 `px`），数值经 `addUnit` 拼装；原生统一折算成 pt。
    public let singleSize: CGFloat
    public let multipleSize: CGFloat
    public let space: CGFloat
    public let singleMode: String
    public let multipleMode: String
    public let maxCount: Int
    public let previewFullImage: Bool
    public let rowCount: Int
    public let showMore: Bool
    public let shape: String
    public let radius: CGFloat
    public let autoWrap: Bool
    /// 上游 `unit` 参与 `addUnit(value, unit)`；原生已把尺寸折算成 pt，
    /// 保留原值供宿主查询（与 `UPImage.webp` 同样处理）。
    public let unit: String
    /// 上游 `stop` 控制 `preventEvent`，SwiftUI 的 `onTapGesture` 默认不冒泡，
    /// 同样保留为兼容元数据。
    public let stop: Bool

    /// 原生保留的旧签名：字符串数组。
    public var images: [String] { items.map { $0.source(keyName: keyName) } }
    public var current: Int { state.current }

    @State private var state: UPAlbumState
    @State private var singleAspectRatio: CGFloat?
    private var onClickHandler: ((Int, String) -> Void)?
    private var onPreviewHandler: ((UPAlbumPreview) -> Void)?
    private var onAlbumWidthHandler: ((CGFloat) -> Void)?

    /// 仓库既有签名，`images` 即上游 `urls` 的字符串形态。
    public init(images: [String] = UPConfig.album.urls,
                singleSize: some UPImageUnitValue = UPConfig.album.singleSize,
                multipleSize: some UPImageUnitValue = UPConfig.album.multipleSize,
                maxCount: some UPImageUnitValue = UPConfig.album.maxCount,
                onClick: ((Int, String) -> Void)? = nil) {
        self.init(urls: images,
                  singleSize: singleSize,
                  multipleSize: multipleSize,
                  maxCount: maxCount)
        self.onClickHandler = onClick
    }

    /// 与上游 `props.js` 对齐的初始化器。
    public init(urls: [some UPAlbumItemValue] = [String](),
                keyName: String = UPConfig.album.keyName,
                singleSize: some UPImageUnitValue = UPConfig.album.singleSize,
                multipleSize: some UPImageUnitValue = UPConfig.album.multipleSize,
                space: some UPImageUnitValue = UPConfig.album.space,
                singleMode: String = UPConfig.album.singleMode,
                multipleMode: String = UPConfig.album.multipleMode,
                maxCount: some UPImageUnitValue = UPConfig.album.maxCount,
                previewFullImage: Bool = UPConfig.album.previewFullImage,
                rowCount: some UPImageUnitValue = UPConfig.album.rowCount,
                showMore: Bool = UPConfig.album.showMore,
                shape: String = UPConfig.album.shape,
                radius: some UPImageUnitValue = UPConfig.album.radius,
                autoWrap: Bool = UPConfig.album.autoWrap,
                unit: String = UPConfig.album.unit,
                stop: Bool = UPConfig.album.stop,
                onPreview: ((UPAlbumPreview) -> Void)? = nil) {
        self.items = urls.map(\.upAlbumItem)
        self.keyName = keyName
        self.singleSize = max(0, UPUnit.parse(singleSize.upImageUnitValue))
        self.multipleSize = max(0, UPUnit.parse(multipleSize.upImageUnitValue))
        self.space = max(0, UPUnit.parse(space.upImageUnitValue))
        self.singleMode = singleMode
        self.multipleMode = multipleMode
        self.maxCount = max(0, Int(UPUnit.parse(maxCount.upImageUnitValue)))
        self.previewFullImage = previewFullImage
        self.rowCount = max(1, Int(UPUnit.parse(rowCount.upImageUnitValue)))
        self.showMore = showMore
        self.shape = shape
        self.radius = max(0, UPUnit.parse(radius.upImageUnitValue))
        self.autoWrap = autoWrap
        self.unit = unit
        self.stop = stop
        self.onPreviewHandler = onPreview
        self._state = State(initialValue: UPAlbumState())
    }

    // MARK: - 事件

    /// 原生保留的点击回调（下标 + 地址）。
    public func onClick(_ action: @escaping (Int, String) -> Void) -> UPAlbum {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    /// 对应上游 `preview` 事件：`previewFullImage` 为假时才抛出。
    public func onPreview(_ action: @escaping (UPAlbumPreview) -> Void) -> UPAlbum {
        var copy = self
        copy.onPreviewHandler = action
        return copy
    }

    /// 对应上游 `albumWidth` 事件。
    public func onAlbumWidth(_ action: @escaping (CGFloat) -> Void) -> UPAlbum {
        var copy = self
        copy.onAlbumWidthHandler = action
        return copy
    }

    // MARK: - 状态

    /// 全部图片地址，对应上游 `onPreviewTap` 里的 `urls.map(getSrc)`。
    public var sources: [String] { items.map { $0.source(keyName: keyName) } }

    /// 上游 `showUrls` 只截到 `maxCount`。
    public var displayedImages: ArraySlice<String> { sources.prefix(maxCount) }

    /// 对应上游 `showUrls`：`autoWrap` 时全部塞进一行，否则按 `rowCount` 分行。
    public var rows: [[String]] {
        let visible = Array(displayedImages)
        guard !autoWrap else { return visible.isEmpty ? [] : [visible] }
        return stride(from: 0, to: visible.count, by: rowCount).map {
            Array(visible[$0..<min($0 + rowCount, visible.count)])
        }
    }

    /// 上游 `showMore && urls.length > rowCount * showUrls.length`：
    /// 只在最后一格上盖「+N」。
    public var overflowCount: Int { max(0, sources.count - maxCount) }

    /// 上游的判断条件只用了 `rowCount * showUrls.length`，`autoWrap` 下
    /// `showUrls.length` 恒为 1，于是 `urls.length > rowCount` 就会显示提示，
    /// 此时 `+${urls.length - maxCount}` 可能是 0 或负数；这属于显示缺陷，
    /// 原生额外要求 `overflowCount > 0`。
    public var showsOverflowBadge: Bool {
        showMore && sources.count > rowCount * rows.count && overflowCount > 0
    }

    /// 上游 `albumWidth`：单图取实际宽度，多图取首行宽度加间隔。
    public var albumWidth: CGFloat {
        if sources.count == 1 { return singleImageSize.width }
        guard let first = rows.first, !first.isEmpty else { return 0 }
        return CGFloat(first.count) * multipleSize + space * CGFloat(first.count - 1)
    }

    /// 单图尺寸：上游用 `uni.getImageInfo` 取原图长宽比，让长边等于 `singleSize`。
    /// 原生用 `AsyncImage` 拿到的比例做同样换算，取不到时按上游 fail 分支退化成方形。
    public var singleImageSize: CGSize {
        guard let ratio = singleAspectRatio, ratio > 0 else {
            return CGSize(width: singleSize, height: singleSize)
        }
        return ratio >= 1
            ? CGSize(width: singleSize, height: singleSize / ratio)
            : CGSize(width: singleSize * ratio, height: singleSize)
    }

    /// 上游模板：单图用 `singleMode`（拿不到尺寸时退 `widthFix`），多图用 `multipleMode`。
    public var imageMode: String {
        sources.count == 1 ? (singleAspectRatio == nil ? "widthFix" : singleMode) : multipleMode
    }

    /// 上游 `shape == 'circle'` 时圆角写死 10000px。
    public var cornerRadius: CGFloat {
        shape.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "circle"
            ? max(singleImageSize.width, multipleSize)
            : radius
    }

    // MARK: - 行为

    /// 对应上游 `onPreviewTap`：`previewFullImage` 为真时走系统预览（原生没有
    /// 预览层，只把点击回调给宿主），否则抛 `preview` 事件。
    public func select(_ index: Int) {
        let sources = self.sources
        guard sources.indices.contains(index) else { return }
        state.current = index
        onClickHandler?(index, sources[index])
        guard !previewFullImage else { return }
        onPreviewHandler?(UPAlbumPreview(urls: sources, currentIndex: index))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: space) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                rowView(row, rowIndex: rowIndex)
            }
        }
        .onAppear { onAlbumWidthHandler?(albumWidth) }
        .onChange(of: albumWidth) { _, width in onAlbumWidthHandler?(width) }
    }

    @ViewBuilder
    private func rowView(_ row: [String], rowIndex: Int) -> some View {
        // `autoWrap` 让图片自动折行，对应上游 `flexWrap: 'wrap'`。
        if autoWrap {
            UPAlbumWrapLayout(spacing: space, lineSpacing: space) {
                ForEach(Array(row.enumerated()), id: \.offset) { index, source in
                    cell(source, index: index, rowIndex: rowIndex, rowCount: row.count)
                }
            }
        } else {
            HStack(spacing: space) {
                ForEach(Array(row.enumerated()), id: \.offset) { index, source in
                    cell(source, index: index, rowIndex: rowIndex, rowCount: row.count)
                }
            }
        }
    }

    private func cell(_ source: String, index: Int, rowIndex: Int, rowCount: Int) -> some View {
        let flatIndex = autoWrap ? index : rowIndex * self.rowCount + index
        let isLast = rowIndex == rows.count - 1 && index == rowCount - 1
        let size = sources.count == 1 ? singleImageSize : CGSize(width: multipleSize, height: multipleSize)
        return image(source, size: size)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: min(cornerRadius, min(size.width, size.height) / 2)))
            .overlay {
                if showsOverflowBadge, isLast {
                    ZStack {
                        Color.black.opacity(0.3)
                        Text("+\(overflowCount)")
                            .font(.system(size: multipleSize * 0.3))
                            .foregroundStyle(.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: min(cornerRadius, min(size.width, size.height) / 2)))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { select(flatIndex) }
    }

    @ViewBuilder
    private func image(_ source: String, size: CGSize) -> some View {
        if sources.count == 1, let url = UPParseURL.remote(source) {
            // 上游 `getImageRect` 用 `uni.getImageInfo` 量原图，原生借 AsyncImage 的
            // 解码结果拿长宽比，再按 `singleSize` 换算长短边。
            AsyncImage(url: url) { phase in
                if case .success(let loaded) = phase {
                    loaded
                        .resizable()
                        .aspectRatio(contentMode: UPIcon.usesAspectFill(for: imageMode) ? .fill : .fit)
                        .onAppear { measureSingleImage(url) }
                } else {
                    UPColor.parse(UPConfig.image.bgColor)
                }
            }
        } else {
            UPImage(src: source,
                    mode: imageMode,
                    width: size.width,
                    height: size.height,
                    shape: shape,
                    radius: radius)
        }
    }

    /// 只在单图模式下量一次原图尺寸。
    private func measureSingleImage(_ url: URL) {
        guard singleAspectRatio == nil else { return }
        Task {
            guard let ratio = await Self.aspectRatio(of: url) else { return }
            singleAspectRatio = ratio
        }
    }

    /// 上游 `getImageInfo` 的原生等价物；失败时返回 nil，走方形兜底。
    nonisolated static func aspectRatio(of url: URL) async -> CGFloat? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        #if canImport(UIKit)
        guard let image = UIImage(data: data), image.size.height > 0 else { return nil }
        return image.size.width / image.size.height
        #else
        return nil
        #endif
    }
}

/// `autoWrap` 用的折行布局，对应上游 `flexWrap: 'wrap'` 的一行 flex 容器。
struct UPAlbumWrapLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? lineWidth(of: subviews)
        let lines = self.lines(in: max(width, 0), subviews: subviews)
        let height = lines.reduce(CGFloat.zero) { $0 + $1.height } + lineSpacing * CGFloat(max(lines.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(in: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    /// 没有宽度提案时的兜底：所有子视图排成一行。
    private func lineWidth(of subviews: Subviews) -> CGFloat {
        let widths = subviews.indices.map { subviews[$0].sizeThatFits(.unspecified).width }
        return widths.reduce(0, +) + spacing * CGFloat(max(widths.count - 1, 0))
    }

    private func lines(in width: CGFloat, subviews: Subviews) -> [Line] {
        var result: [Line] = []
        var line = Line()
        var used: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let advance = line.indices.isEmpty ? size.width : size.width + spacing
            if !line.indices.isEmpty, used + advance > width {
                result.append(line)
                line = Line()
                used = 0
                line.indices.append(index)
                line.height = size.height
                used = size.width
                continue
            }
            line.indices.append(index)
            line.height = max(line.height, size.height)
            used += advance
        }
        if !line.indices.isEmpty { result.append(line) }
        return result
    }
}
