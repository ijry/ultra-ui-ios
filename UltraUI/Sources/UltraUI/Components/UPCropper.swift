import Observation
import SwiftUI

/// `confirm` 的事件负载。上游是 `{ avatar, path, index, data }`：
/// `avatar` 是原图、`path` 是裁剪结果、`index` / `data` 是 `chooseImage` 时带进来的。
public struct UPCropResult: Equatable, Sendable {
    public let source: String
    public let rect: CGRect
    /// 上游 `index`，由 `chooseImage(index:)` 带入。
    public let index: Int?
    /// 上游 `data`，由 `chooseImage(data:)` 带入。
    public let data: String?

    public init(source: String, rect: CGRect, index: Int? = nil, data: String? = nil) {
        self.source = source
        self.rect = rect
        self.index = index
        self.data = data
    }
}

/// 对应上游 `data` 里的裁剪状态。
@MainActor
@Observable
private final class UPCropperState {
    var cropRect: CGRect
    /// 上游 `rotateDeg`。
    var rotation: Double = 0
    /// 上游 `scaleSize`。
    var scale: Double = 1
    /// 上游 `indx` / `rtn`，`chooseImage` 时写入。
    var index: Int?
    var data: String?
    /// 上游 `showOper`：false 时切到预览态的调色条。
    var previewing = false

    init(cropRect: CGRect) {
        self.cropRect = cropRect
    }
}

/// Native SwiftUI counterpart of uview-plus `u-cropper`.
///
/// 上游是三层 canvas 叠出来的裁剪器：底层画图、中层画裁剪框并接手势、上层做预览，
/// 底部一排按钮是「重选 / 关闭 / 旋转 / 预览 / 确定」；`chooseImage(index, params, data)`
/// 既能从相册选图也能直接给 `params.imageSrc`，`params` 还能临时覆盖各项开关。
///
/// 原生保留同一套数值语义（裁剪框 clamp、旋转 90° 递增、缩放夹在 min/max），
/// 渲染改成「图片 + 半透明遮罩 + 白框」，手势按 `canScale` / `canChangeSize` 开关。
/// 「从相册选图」需要宿主接 `PhotosPicker`，`chooseImage` 只把参数带出去。
@MainActor
public struct UPCropper: View {
    public let src: String
    public let sourceSize: CGSize
    public var canScale: Bool
    public var canRotate: Bool
    public var canChangeSize: Bool
    /// 上游 `noTab` 为真时不显示 tabBar（`uni.showTabBar`）；iOS 没有全局 tabBar，
    /// 保留取值。
    public var noTab: Bool
    /// 上游 `inner` 为真时按钮变四个（去掉旋转），且强制禁用旋转。
    public var inner: Bool
    public var fillColor: String
    public var areaWidth: String
    public var areaHeight: String
    public var exportWidth: String
    public var exportHeight: String
    public var quality: Double
    public var minScale: Double
    public var maxScale: Double

    public var cropRect: CGRect { state.cropRect }
    /// 上游 `rotateDeg` / `scaleSize`。
    public var rotation: Double { state.rotation }
    public var scale: Double { state.scale }
    public var previewing: Bool { state.previewing }
    /// 上游 `letRotate`：`canRotate === false || inner === true` 时禁用旋转。
    public var rotationEnabled: Bool { canRotate && !inner }

    @State private var state: UPCropperState
    @Environment(\.upTheme) private var theme
    private var onConfirmHandler: ((UPCropResult) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onInitHandler: (() -> Void)?
    private var onSelectHandler: ((UPCropperPickRequest) -> Void)?
    private var placeholderSlot: AnyView?

    public init(src: String = "",
                sourceSize: CGSize = CGSize(width: 300, height: 300),
                cropRect: CGRect? = nil,
                canScale: Bool = UPConfig.cropper.canScale,
                canRotate: Bool = UPConfig.cropper.canRotate,
                canChangeSize: Bool = UPConfig.cropper.canChangeSize,
                noTab: Bool = UPConfig.cropper.noTab,
                inner: Bool = UPConfig.cropper.inner,
                fillColor: String = UPConfig.cropper.fillColor,
                areaWidth: String = UPConfig.cropper.areaWidth,
                areaHeight: String = UPConfig.cropper.areaHeight,
                exportWidth: String = UPConfig.cropper.exportWidth,
                exportHeight: String = UPConfig.cropper.exportHeight,
                quality: Double = UPConfig.cropper.quality,
                minScale: Double = UPConfig.cropper.minScale,
                maxScale: Double = UPConfig.cropper.maxScale,
                onConfirm: ((UPCropResult) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.src = src
        self.sourceSize = CGSize(width: max(0, sourceSize.width), height: max(0, sourceSize.height))
        self.canScale = canScale
        self.canRotate = canRotate
        self.canChangeSize = canChangeSize
        self.noTab = noTab
        self.inner = inner
        self.fillColor = fillColor
        self.areaWidth = areaWidth
        self.areaHeight = areaHeight
        self.exportWidth = exportWidth
        self.exportHeight = exportHeight
        // 上游 `created` 里 `parseInt(quality) || 0.9` 这类兜底。
        self.quality = quality > 0 ? quality : UPConfig.cropper.quality
        self.minScale = minScale > 0 ? minScale : UPConfig.cropper.minScale
        self.maxScale = maxScale > 0 ? maxScale : UPConfig.cropper.maxScale
        self.onConfirmHandler = onConfirm
        self.onCancelHandler = onCancel
        // 上游 `areaWidth` / `areaHeight` 决定初始裁剪框大小（居中）。
        let area = CGSize(width: UPUnit.parse(areaWidth), height: UPUnit.parse(areaHeight))
        let seeded = cropRect ?? Self.centered(area, in: self.sourceSize)
        self._state = State(initialValue: UPCropperState(cropRect: Self.clamped(seeded, to: self.sourceSize)))
    }

    // MARK: - 解析后的呈现值

    /// 上游导出尺寸，`rpx` 走 `UPUnit`。
    public var exportSize: CGSize {
        CGSize(width: UPUnit.parse(exportWidth), height: UPUnit.parse(exportHeight))
    }

    /// 上游 `btnWidth` / `btnDsp`：`inner` 时四个按钮各 24%，否则五个各 19%。
    public var buttonTitles: [String] {
        inner ? ["重新选择", "关闭", "预览", "确定"] : ["重新选择", "关闭", "旋转", "预览", "确定"]
    }

    // MARK: - 上游方法

    /// 程序化设置裁剪框（会 clamp 到画布内）。上游没有对应方法，
    /// `canChangeSize` 约束的是「手势能否改大小」，见 `dragCropRect(by:)`。
    public func setCropRect(_ rect: CGRect) {
        state.cropRect = Self.clamped(rect, to: sourceSize)
    }

    /// 对应上游 `move` 里的平移分支：`letChangeSize` 为假时只能移动、不能改大小。
    public func dragCropRect(by translation: CGSize) {
        let origin = CGPoint(x: cropRect.minX + translation.width, y: cropRect.minY + translation.height)
        setCropRect(CGRect(origin: origin, size: cropRect.size))
    }

    /// 手势改大小，`canChangeSize` 为假时忽略。
    public func resizeCropRect(to size: CGSize) {
        guard canChangeSize else { return }
        setCropRect(CGRect(origin: cropRect.origin, size: size))
    }

    /// 对应上游 `rotate()`：补到下一个 90° 整数倍。
    public func rotate() {
        guard rotationEnabled else { return }
        state.rotation += 90 - state.rotation.truncatingRemainder(dividingBy: 90)
    }

    /// 对应上游双指缩放：夹在 `minScale`…`maxScale`。
    public func setScale(_ value: Double) {
        guard canScale else { return }
        state.scale = min(max(value, minScale), maxScale)
    }

    /// 对应上游 `preview()` / `hideImg()`。
    public func preview() { state.previewing = true }

    public func hidePreview() { state.previewing = false }

    /// 对应上游 `chooseImage(index, params, data)`：记录 index/data，
    /// 有 `imageSrc` 就直接加载，否则弹相册（原生交给宿主）。
    public func chooseImage(index: Int? = nil, imageSrc: String = "", data: String? = nil) {
        state.index = index
        state.data = data
        onSelectHandler?(UPCropperPickRequest(index: index, imageSrc: imageSrc, data: data))
    }

    /// 对应上游 `avtinit` 事件（画布初始化完毕）。
    public func initialized() { onInitHandler?() }

    @discardableResult
    public func confirm() -> UPCropResult {
        let result = UPCropResult(source: src, rect: cropRect, index: state.index, data: state.data)
        onConfirmHandler?(result)
        return result
    }

    /// 对应上游 `close()`：收起并抛 `cancel`。
    public func cancel() {
        state.previewing = false
        onCancelHandler?()
    }

    // MARK: - 事件与插槽

    public func onConfirm(_ action: @escaping (UPCropResult) -> Void) -> UPCropper {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    public func onCancel(_ action: @escaping () -> Void) -> UPCropper {
        var copy = self
        copy.onCancelHandler = action
        return copy
    }

    /// 对应上游 `avtinit` 事件。
    public func onInit(_ action: @escaping () -> Void) -> UPCropper {
        var copy = self
        copy.onInitHandler = action
        return copy
    }

    /// `chooseImage` 需要弹相册时回调宿主。
    public func onSelect(_ action: @escaping (UPCropperPickRequest) -> Void) -> UPCropper {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    /// 对应上游默认插槽：未打开裁剪器时显示的触发内容。
    public func placeholder<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPCropper {
        var copy = self
        copy.placeholderSlot = AnyView(builder())
        return copy
    }

    public var hasPlaceholderSlot: Bool { placeholderSlot != nil }

    // MARK: - 视图

    public var body: some View {
        VStack(spacing: 0) {
            stage
            toolbar
        }
        .background(fillColor == "transparent" ? Color.black : UPColor.parse(fillColor, theme: theme))
        .onAppear { initialized() }
    }

    private var stage: some View {
        GeometryReader { proxy in
            ZStack {
                image
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                // 上游中层 canvas 画的半透明遮罩与白色裁剪框。
                Color.black.opacity(0.5)
                    .reverseMask(alignment: .topLeading) {
                        Rectangle()
                            .frame(width: cropRect.width, height: cropRect.height)
                            .offset(x: cropRect.minX, y: cropRect.minY)
                    }

                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .offset(x: cropRect.minX, y: cropRect.minY)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .modifier(UPCropperZoom(enabled: canScale, apply: setScale))
        }
        .aspectRatio(sourceSize.width > 0 && sourceSize.height > 0
                     ? sourceSize.width / sourceSize.height
                     : 1,
                     contentMode: .fit)
    }

    @ViewBuilder
    private var image: some View {
        if src.isEmpty {
            if let placeholderSlot {
                placeholderSlot
            } else {
                Color.black.opacity(0.08)
            }
        } else {
            UPImage(src: src, mode: "aspectFit", width: sourceSize.width, height: sourceSize.height)
        }
    }

    /// 拖动裁剪框：上游 `move` 里按触点差值平移。
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragCropRect(by: CGSize(width: value.translation.width / 20,
                                        height: value.translation.height / 20))
            }
    }

    /// 上游底部按钮条：预览态换成调色滑块 + 确定。
    @ViewBuilder
    private var toolbar: some View {
        if previewing {
            HStack(spacing: 12) {
                Slider(value: .constant(0), in: -100...100)
                    .tint(theme.error)
                button("确定") { _ = confirm() }
            }
            .padding(12)
        } else {
            HStack(spacing: 0) {
                ForEach(buttonTitles, id: \.self) { title in
                    button(title) { handleButton(title) }
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)
        }
    }

    private func button(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundStyle(Color.white)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private func handleButton(_ title: String) {
        switch title {
        case "重新选择": chooseImage()
        case "关闭": cancel()
        case "旋转": rotate()
        case "预览": preview()
        default: _ = confirm()
        }
    }

    // MARK: - 纯函数工具

    /// 上游 `selStyle` 把裁剪框放在画布正中。
    nonisolated static func centered(_ area: CGSize, in size: CGSize) -> CGRect {
        let width = area.width > 0 ? min(area.width, size.width) : size.width
        let height = area.height > 0 ? min(area.height, size.height) : size.height
        return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
    }

    nonisolated static func clamped(_ rect: CGRect, to size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let width = min(max(rect.width, 0), size.width)
        let height = min(max(rect.height, 0), size.height)
        let x = min(max(rect.minX, 0), size.width - width)
        let y = min(max(rect.minY, 0), size.height - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

/// `chooseImage` 的参数，对应上游 `chooseImage(index, params, data)`。
public struct UPCropperPickRequest: Equatable, Sendable {
    public let index: Int?
    /// 非空时上游直接 `loadImage(imageSrc)`，不弹相册。
    public let imageSrc: String
    public let data: String?

    public init(index: Int?, imageSrc: String, data: String?) {
        self.index = index
        self.imageSrc = imageSrc
        self.data = data
    }

    public var needsPicker: Bool { imageSrc.isEmpty }
}

/// `canScale` 为假时不装缩放手势。
private struct UPCropperZoom: ViewModifier {
    let enabled: Bool
    let apply: (Double) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(MagnifyGesture().onChanged { apply($0.magnification) })
        } else {
            content
        }
    }
}

private extension View {
    /// 挖洞遮罩：裁剪框内部透出原图。
    func reverseMask<Mask: View>(alignment: Alignment = .center,
                                 @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(alignment: alignment) {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
}
