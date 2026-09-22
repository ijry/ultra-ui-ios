import CoreImage
import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-qrcode` unit props.
public typealias UPQRCodeUnitValue = UPImageUnitValue

/// 上游 `lv`：`RS_BLOCK_TABLE` 的纠错档位下标。
///
/// 0=L、1=M、2=Q、3=H，与 Core Image `inputCorrectionLevel` 的四个字母一一对应。
public enum UPQRCodeCorrectLevel: Int, Equatable, Sendable {
    case low = 0
    case medium = 1
    case quartile = 2
    case high = 3

    public var coreImageValue: String {
        switch self {
        case .low: return "L"
        case .medium: return "M"
        case .quartile: return "Q"
        case .high: return "H"
        }
    }
}

/// 对应上游 `data`：`loading`、`result`、量出来的根节点尺寸。
@MainActor
@Observable
private final class UPQRCodeState {
    var loading = false
    /// 上游 `result`：生成后的临时文件路径。
    var result = ""
    /// 上游 `sizeLocal`：`useRootHeightAndWidth` 时改成根节点的短边。
    var sizeLocal: CGFloat
    var rootSize: CGSize = .zero

    init(sizeLocal: CGFloat) { self.sizeLocal = sizeLocal }
}

/// Native SwiftUI counterpart of uview-plus `u-qrcode`.
///
/// 上游用自带的 `qrcode.js` 算出模块矩阵，再往 canvas 上逐格填色：定位角点用
/// `pdground`、其余用 `foreground`、空白格用 `background`，`quietZone` 在四周多留几圈，
/// 中心可叠一个带圆角白边的 `icon`；画完导出临时图片并通过 `result` 抛出。
///
/// 原生改用 Core Image 的 `CIQRCodeGenerator` 出矩阵（`lv` 映射到
/// `inputCorrectionLevel`），再用同一套「按格填色 + 中心图标」的规则重绘，
/// 因此 `pdground` / `quietZone` / `icon` 这些上游能力都能表达。
@MainActor
public struct UPQRCode: View {
    /// 上游 `cid`：canvas id。原生不需要 canvas，仅作标识保留。
    public var cid: String
    /// 上游 `size`：二维码边长，配合 `unit` 使用。
    public var size: CGFloat
    /// 上游 `unit`：`size` 的单位。
    public var unit: String
    /// 上游 `show`。
    public var show: Bool
    /// 上游 `val`：二维码内容。
    public var val: String
    public var background: String
    public var foreground: String
    /// 上游 `pdground`：三个定位角点的颜色。
    public var pdground: String
    /// 上游 `icon`：中心图标。
    public var icon: String
    public var iconSize: CGFloat
    /// 上游 `lv`：纠错级别。
    public var lv: UPQRCodeCorrectLevel
    /// 上游 `quietZone`：四周留白的格数。
    public var quietZone: Int
    /// 上游 `onval`：`val` / `size` 变化时是否自动重绘。
    public var onval: Bool
    /// 上游 `loadMake`：挂载后是否自动生成。
    public var loadMake: Bool
    /// 上游 `usingComponents`：只影响上游那条 100ms/200ms 的回调延时。
    public var usingComponents: Bool
    public var showLoading: Bool
    public var loadingText: String
    /// 上游 `allowPreview`：点击是否调 `previewImage`。
    public var allowPreview: Bool
    /// 上游 `useRootHeightAndWidth`：用根节点短边当边长。
    public var useRootHeightAndWidth: Bool

    @State private var state: UPQRCodeState
    private var onResultHandler: ((String) -> Void)?
    private var onPreviewHandler: ((String) -> Void)?
    private var onLongpressHandler: ((String) -> Void)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器。
    public init(val: String = UPConfig.qrcode.val,
                cid: String = "",
                size: any UPQRCodeUnitValue = UPConfig.qrcode.size,
                unit: String = UPConfig.qrcode.unit,
                show: Bool = UPConfig.qrcode.show,
                background: String = UPConfig.qrcode.background,
                foreground: String = UPConfig.qrcode.foreground,
                pdground: String = UPConfig.qrcode.pdground,
                icon: String = UPConfig.qrcode.icon,
                iconSize: any UPQRCodeUnitValue = UPConfig.qrcode.iconSize,
                lv: UPQRCodeCorrectLevel = UPQRCodeCorrectLevel(rawValue: UPConfig.qrcode.lv) ?? .high,
                quietZone: Int = UPConfig.qrcode.quietZone,
                onval: Bool = UPConfig.qrcode.onval,
                loadMake: Bool = UPConfig.qrcode.loadMake,
                usingComponents: Bool = UPConfig.qrcode.usingComponents,
                showLoading: Bool = UPConfig.qrcode.showLoading,
                loadingText: String = UPConfig.qrcode.loadingText,
                allowPreview: Bool = UPConfig.qrcode.allowPreview,
                useRootHeightAndWidth: Bool = UPConfig.qrcode.useRootHeightAndWidth) {
        let resolvedSize = max(0, UPUnit.parse(size.upImageUnitValue))
        self.val = val
        // 上游 `cid` 默认是 `u-qrcode-canvas` + 随机数，原生取内容哈希保持稳定。
        self.cid = cid.isEmpty ? "u-qrcode-canvas\(abs(val.hashValue % 1_000_000))" : cid
        self.size = resolvedSize
        self.unit = unit
        self.show = show
        self.background = background
        self.foreground = foreground
        self.pdground = pdground
        self.icon = icon
        self.iconSize = max(0, UPUnit.parse(iconSize.upImageUnitValue))
        self.lv = lv
        self.quietZone = max(0, quietZone)
        self.onval = onval
        self.loadMake = loadMake
        self.usingComponents = usingComponents
        self.showLoading = showLoading
        self.loadingText = loadingText
        self.allowPreview = allowPreview
        self.useRootHeightAndWidth = useRootHeightAndWidth
        self._state = State(initialValue: UPQRCodeState(sizeLocal: resolvedSize))
    }

    /// 仓库既有签名：`value` 是 `val` 的旧名。
    public init(value: String = "", size: some UPQRCodeUnitValue = UPConfig.qrcode.size) {
        self.init(val: value, size: size)
    }

    // MARK: - 解析后的呈现值

    /// 仓库既有名。
    public var value: String { val }
    /// 上游 `sizeLocal`。
    public var sizeLocal: CGFloat { state.sizeLocal }
    /// 上游 `loading`。
    public var loading: Bool { state.loading }
    /// 上游 `result`。
    public var result: String { state.result }

    public var payload: Data { val.data(using: .utf8) ?? Data() }

    /// 上游 `_empty(v)`：空串与 `'undefined'`、`'null'`、`'{}'`、`'[]'` 都算空。
    public var isEmptyValue: Bool { Self.isEmpty(val) }

    nonisolated static func isEmpty(_ value: String) -> Bool {
        ["", "undefined", "null", "{}", "[]"].contains(value)
    }

    /// 上游 `setNewSize()`：取根节点宽高里较短的一边。
    nonisolated static func rootSideLength(_ size: CGSize) -> CGFloat {
        size.width > size.height ? size.height : size.width
    }

    /// Core Image 出的原始矩阵（含它自带的一圈静区），供上层按格重绘。
    public var modules: [[Bool]]? { Self.modules(of: val, level: lv) }

    /// 上游 `qrCodeAlg.getModuleCount()`。
    public var moduleCount: Int { modules?.count ?? 0 }

    /// 上游 `renderCount = count + quietZone * 2`。
    public var renderCount: Int { moduleCount + quietZone * 2 }

    /// 上游 `getForeGround(config)`：命中三个定位角点区域时用 `pdground`。
    ///
    /// 照抄上游那三段边界判定（都是开区间，因此实际只覆盖角点方块的内圈 3×3）。
    public func isPositionDetector(row: Int, col: Int) -> Bool {
        let count = moduleCount
        guard count > 0 else { return false }
        if row > 1, row < 5, col > 1, col < 5 { return true }
        if row > count - 6, row < count - 2, col > 1, col < 5 { return true }
        if row > 1, row < 5, col > count - 6, col < count - 2 { return true }
        return false
    }

    /// 上游 `isDark`：静区范围内一律当白格。
    public func isDark(row: Int, col: Int) -> Bool {
        guard let modules else { return false }
        let qrRow = row - quietZone
        let qrCol = col - quietZone
        guard qrRow >= 0, qrCol >= 0, qrRow < modules.count, qrCol < modules.count else { return false }
        return modules[qrRow][qrCol]
    }

    /// 上游 `tileW = (size / renderCount).toPrecision(4)`。
    public var tileSize: CGFloat {
        guard renderCount > 0 else { return 0 }
        return state.sizeLocal / CGFloat(renderCount)
    }

    /// 上游内嵌图标的落点：`(size - imageSize) / 2`。
    public var iconOrigin: CGFloat { (state.sizeLocal - iconSize) / 2 }

    nonisolated static func modules(of value: String, level: UPQRCodeCorrectLevel) -> [[Bool]]? {
        guard !isEmpty(value),
              let filter = CIFilter(name: "CIQRCodeGenerator"),
              let data = value.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(level.coreImageValue, forKey: "inputCorrectionLevel")
        guard let image = filter.outputImage else { return nil }
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        guard width > 0, height > 0 else { return nil }

        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        bytes.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            CIContext(options: nil).render(image,
                                           toBitmap: base,
                                           rowBytes: width * 4,
                                           bounds: image.extent,
                                           format: .RGBA8,
                                           colorSpace: space)
        }
        return (0..<height).map { row in
            (0..<width).map { col in bytes[(row * width + col) * 4] < 128 }
        }
    }

    /// 仓库既有属性：Core Image 直接出的整张位图。
    public var generatedImage: CIImage? {
        upGeneratedImage(filterName: "CIQRCodeGenerator", value: val, width: size, height: size)
    }

    // MARK: - 上游 methods

    /// 上游 `_makeCode()`：内容为空时先 toast 再返回，否则置 loading 并生成。
    @discardableResult
    public func makeCode(scale: CGFloat = 2) -> String {
        guard !isEmptyValue else {
            UPToast.show(message: UPConfig.qrcode.emptyToast)
            return ""
        }
        state.loading = true
        let path = exportTempFilePath(scale: scale)
        reportResult(path)
        return path
    }

    /// 上游 `_clearCode()`：抛一次空 `result` 再清画布。
    public func clearCode() {
        reportResult("")
    }

    /// 上游 `_result(res)`：先关 loading、写 result，再抛 `result`。
    private func reportResult(_ path: String) {
        state.loading = false
        state.result = path
        onResultHandler?(path)
    }

    /// 上游 `toTempFilePath({ success, fail })`：把画布导出成临时文件。
    @discardableResult
    public func toTempFilePath(scale: CGFloat = 2) -> String? {
        let path = exportTempFilePath(scale: scale)
        return path.isEmpty ? nil : path
    }

    private func exportTempFilePath(scale: CGFloat) -> String {
        let renderer = ImageRenderer(content: codeCanvas)
        renderer.scale = scale
        guard let data = Self.pngData(from: renderer) else { return "" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("up-qrcode-\(UUID().uuidString).png")
        guard (try? data.write(to: url)) != nil else { return "" }
        return url.path
    }

    /// `ImageRenderer` 在 iOS 出 `UIImage`、在 macOS 出 `NSImage`，统一转成 PNG。
    private static func pngData(from renderer: ImageRenderer<some View>) -> Data? {
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff) else { return nil }
        return representation.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    /// 上游 `_saveCode()`：`result` 为空时先导出再存相册。存相册由宿主负责。
    @discardableResult
    public func saveCode() -> String {
        if state.result.isEmpty {
            let path = exportTempFilePath(scale: 2)
            state.result = path
        }
        guard !state.result.isEmpty else { return "" }
        UPToast.show(message: UPConfig.qrcode.savedToast)
        return state.result
    }

    /// 上游 `preview(e)`：`allowPreview` 只决定是否调系统预览，`preview` 事件总会抛。
    public func preview() {
        onPreviewHandler?(state.result)
    }

    /// 上游 `longpress()`：导出成功后抛 `longpressCallback`，失败什么都不抛。
    public func longpress() {
        guard let path = toTempFilePath() else { return }
        state.result = path
        onLongpressHandler?(path)
    }

    // MARK: - 事件

    /// 对应上游 `result` 事件，负载是临时文件路径。
    public func onResult(_ action: @escaping (String) -> Void) -> UPQRCode {
        var copy = self
        copy.onResultHandler = action
        return copy
    }

    /// 对应上游 `preview` 事件，负载是 `{ url }`。
    public func onPreview(_ action: @escaping (String) -> Void) -> UPQRCode {
        var copy = self
        copy.onPreviewHandler = action
        return copy
    }

    /// 对应上游 `longpressCallback` 事件，负载是临时文件路径。
    public func onLongpressCallback(_ action: @escaping (String) -> Void) -> UPQRCode {
        var copy = self
        copy.onLongpressHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        Group {
            if show { content } else { EmptyView() }
        }
        // 上游根节点在 `useRootHeightAndWidth` 时撑满父级。
        .frame(maxWidth: useRootHeightAndWidth ? .infinity : nil,
               maxHeight: useRootHeightAndWidth ? .infinity : nil)
        .background(rootProbe)
    }

    private var content: some View {
        codeCanvas
            .frame(width: state.sizeLocal, height: state.sizeLocal)
            .overlay {
                // 上游 `.u-qrcode__loading`：铺满内容区的灰底加载态。
                if showLoading, state.loading {
                    UPLoadingIcon(show: true, vertical: true, textSize: 14, text: loadingText)
                        .frame(width: state.sizeLocal, height: state.sizeLocal)
                        .background(UPColor.parse(UPConfig.qrcode.loadingBackgroundColor, theme: theme))
                }
            }
            .onTapGesture { preview() }
            .onLongPressGesture { longpress() }
            .task(id: makeTaskID) {
                // 上游 `mounted` 里 `loadMake` 为真且内容非空时自动生成，
                // `val` / `size` 变化后由 `onval` 决定是否重绘。
                guard loadMake || onval, !isEmptyValue else { return }
                makeCode()
            }
    }

    private var makeTaskID: String {
        onval ? "\(val)|\(state.sizeLocal)|\(lv.rawValue)|\(icon)" : val
    }

    /// 上游 `createCanvas`：逐格填色，定位角点用 `pdground`，中心叠 `icon`。
    private var codeCanvas: some View {
        Canvas { context, _ in
            let tile = tileSize
            guard tile > 0 else { return }
            let backgroundShading = GraphicsContext.Shading.color(UPColor.parse(background, theme: theme))
            let foregroundShading = GraphicsContext.Shading.color(UPColor.parse(foreground, theme: theme))
            let detectorShading = GraphicsContext.Shading.color(UPColor.parse(pdground, theme: theme))

            for row in 0..<renderCount {
                for col in 0..<renderCount {
                    let dark = isDark(row: row, col: col)
                    let shading: GraphicsContext.Shading
                    if !dark {
                        shading = backgroundShading
                    } else if isPositionDetector(row: row - quietZone, col: col - quietZone) {
                        shading = detectorShading
                    } else {
                        shading = foregroundShading
                    }
                    let rect = CGRect(x: (CGFloat(col) * tile).rounded(),
                                      y: (CGFloat(row) * tile).rounded(),
                                      width: ceil(CGFloat(col + 1) * tile) - floor(CGFloat(col) * tile),
                                      height: ceil(CGFloat(row + 1) * tile) - floor(CGFloat(row) * tile))
                    context.fill(Path(rect), with: shading)
                }
            }

            if !icon.isEmpty {
                // 上游先画一个背景色圆角矩形垫底，再把图标画上去。
                let rect = CGRect(x: iconOrigin, y: iconOrigin, width: iconSize, height: iconSize)
                context.fill(Path(roundedRect: rect, cornerRadius: UPConfig.qrcode.iconCornerRadius),
                             with: backgroundShading)
                context.stroke(Path(roundedRect: rect, cornerRadius: UPConfig.qrcode.iconCornerRadius),
                               with: backgroundShading,
                               lineWidth: UPConfig.qrcode.iconBorderWidth)
            }
        }
        .overlay {
            // 图标本体交给 UPImage，网络图与本地图都能走。
            if !icon.isEmpty {
                UPImage(src: icon, mode: "aspectFit", width: iconSize, height: iconSize)
            }
        }
    }

    /// 上游 `getRootNode()` 用 selectorQuery 量根节点，原生用 GeometryReader。
    private var rootProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { applyRootSize(proxy.size) }
                .onChange(of: proxy.size) { _, value in applyRootSize(value) }
        }
    }

    private func applyRootSize(_ size: CGSize) {
        state.rootSize = size
        guard useRootHeightAndWidth else { return }
        let side = Self.rootSideLength(size)
        guard side > 0, side != state.sizeLocal else { return }
        state.sizeLocal = side
    }
}
