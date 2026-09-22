import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 一笔手写轨迹，对应上游 `pathStack` 的元素。上游每笔额外记录了当时的
/// 颜色与粗细（改色改粗后旧笔画不变），原生同样带上。
public struct UPSignatureStroke: Equatable, Sendable, Codable {
    public var points: [CGPoint]
    public var color: String
    public var lineWidth: CGFloat

    public init(points: [CGPoint], color: String = UPConfig.signature.color, lineWidth: CGFloat = 3) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }
}

/// 对应上游 `data`：`pathStack` / `lineColor` / `lineWidth` 与两个设置面板开关。
@MainActor
@Observable
private final class UPSignatureState {
    var strokes: [UPSignatureStroke] = []
    var lineColor: String
    var lineWidth: CGFloat
    var showBrushSettings = false
    var showColorSettings = false

    init(lineColor: String, lineWidth: CGFloat) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
    }
}

/// Native SwiftUI counterpart of uview-plus `u-signature`.
///
/// 上游是「canvas 画板 + 工具栏」：工具栏里有撤销、清空、笔画粗细滑块、
/// 颜色色板与导出五个按钮，导出成功抛 `confirm(临时图片路径)`、失败抛 `error`。
/// 原生用 `Canvas` 渲染、`DragGesture` 收笔，导出改用 `ImageRenderer` 出 PNG。
@MainActor
public struct UPSignature: View {
    public let width: CGFloat
    public let height: CGFloat
    public var bgColor: String
    /// 上游 `color` 是「默认笔画颜色」，改色后由 `lineColor` 接管。
    public var color: String
    /// 上游 `thickness` 是「默认笔画粗细」，滑块调整后由 `lineWidth` 接管。
    public var thickness: CGFloat
    public var showToolbar: Bool
    /// 上游 `presetColors`。
    public var presetColors: [String]

    public var strokes: [UPSignatureStroke] { state.strokes }
    /// 当前笔色与笔宽，对应上游 `data.lineColor` / `data.lineWidth`。
    public var lineColor: String { state.lineColor }
    public var lineWidth: CGFloat { state.lineWidth }
    public var showBrushSettings: Bool { state.showBrushSettings }
    public var showColorSettings: Bool { state.showColorSettings }

    @State private var state: UPSignatureState
    @State private var draft: [CGPoint] = []
    @Environment(\.upTheme) private var theme
    private var onChangeHandler: (([UPSignatureStroke]) -> Void)?
    private var onClearHandler: (() -> Void)?
    private var onConfirmHandler: ((String) -> Void)?
    private var onErrorHandler: ((String) -> Void)?

    public init(width: some UPImageUnitValue = UPConfig.signature.width,
                height: some UPImageUnitValue = UPConfig.signature.height,
                bgColor: String = UPConfig.signature.bgColor,
                color: String = UPConfig.signature.color,
                thickness: some UPImageUnitValue = UPConfig.signature.thickness,
                showToolbar: Bool = UPConfig.signature.showToolbar,
                presetColors: [String] = UPConfig.signature.presetColors,
                onChange: (([UPSignatureStroke]) -> Void)? = nil) {
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
        self.bgColor = bgColor
        self.color = color
        self.thickness = max(0, UPUnit.parse(thickness.upImageUnitValue))
        self.showToolbar = showToolbar
        self.presetColors = presetColors
        self.onChangeHandler = onChange
        self._state = State(initialValue: UPSignatureState(
            lineColor: color,
            lineWidth: max(0, UPUnit.parse(thickness.upImageUnitValue))
        ))
    }

    /// 仓库既有签名：`lineWidth` 是 `thickness` 的旧名。
    public init(width: some UPImageUnitValue = UPConfig.signature.width,
                height: some UPImageUnitValue = UPConfig.signature.height,
                color: String = UPConfig.signature.color,
                lineWidth: some UPImageUnitValue,
                onChange: (([UPSignatureStroke]) -> Void)? = nil) {
        self.init(width: width,
                  height: height,
                  color: color,
                  thickness: lineWidth,
                  onChange: onChange)
    }

    // MARK: - 状态

    /// 对应上游 `data.isEmpty`。
    public var isEmpty: Bool { strokes.isEmpty }

    /// 上游 `resolvedBgColor`：只有仍是默认白底时才跟随暗色主题换成 `#1c1c1e`，
    /// 显式传入的颜色原样使用。
    public var resolvedBgColor: String {
        guard bgColor == UPConfig.signature.bgColor else { return bgColor }
        return isDarkAppearance ? "#1c1c1e" : bgColor
    }

    private var isDarkAppearance: Bool {
        #if canImport(UIKit)
        return UITraitCollection.current.userInterfaceStyle == .dark
        #else
        return false
        #endif
    }

    // MARK: - 上游方法

    public func addStroke(_ points: [CGPoint]) {
        guard points.count > 1 else { return }
        state.strokes.append(UPSignatureStroke(points: points,
                                              color: state.lineColor,
                                              lineWidth: state.lineWidth))
        onChangeHandler?(state.strokes)
    }

    /// 对应上游 `undo()`：弹掉最后一笔并重绘。
    @discardableResult
    public func undo() -> Bool {
        guard !state.strokes.isEmpty else { return false }
        state.strokes.removeLast()
        onChangeHandler?(state.strokes)
        return true
    }

    /// 对应上游 `clear()`：清空并抛 `clear`。
    public func clear() {
        state.strokes.removeAll()
        draft.removeAll()
        onChangeHandler?(state.strokes)
        onClearHandler?()
    }

    /// 对应上游 `selectColor(color)`。
    public func selectColor(_ value: String) {
        state.lineColor = value
    }

    /// 对应上游滑块的 `v-model="lineWidth"`，范围 1…20。
    public func setLineWidth(_ value: CGFloat) {
        state.lineWidth = min(max(value, 1), 20)
    }

    /// 对应上游 `toggleBrushSettings()` / `toggleColorSettings()`。
    public func toggleBrushSettings() { state.showBrushSettings.toggle() }

    public func toggleColorSettings() { state.showColorSettings.toggle() }

    /// 对应上游 `exportSignature()`：空签名直接返回，成功抛 `confirm(path)`、失败抛 `error`。
    @discardableResult
    public func exportSignature(scale: CGFloat = 1) -> String? {
        guard !isEmpty else { return nil }
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = scale
        guard let data = Self.pngData(from: renderer) else {
            onErrorHandler?("导出签名图片失败")
            return nil
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("up-signature-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
        } catch {
            onErrorHandler?(error.localizedDescription)
            return nil
        }
        onConfirmHandler?(url.path)
        return url.path
    }

    /// 仓库既有 API：把笔画序列化成 JSON。
    public func exportData() -> Data {
        (try? JSONEncoder().encode(strokes)) ?? Data()
    }

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

    // MARK: - 事件

    public func onChange(_ action: @escaping ([UPSignatureStroke]) -> Void) -> UPSignature {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游 `clear` 事件。
    public func onClear(_ action: @escaping () -> Void) -> UPSignature {
        var copy = self
        copy.onClearHandler = action
        return copy
    }

    /// 对应上游 `confirm` 事件，负载是导出的图片路径。
    public func onConfirm(_ action: @escaping (String) -> Void) -> UPSignature {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    /// 对应上游 `error` 事件。
    public func onError(_ action: @escaping (String) -> Void) -> UPSignature {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        VStack(spacing: 0) {
            canvas
                // 上游 canvas 的 touchstart/move/end 收笔，原生用 DragGesture。
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in draft.append(value.location) }
                        .onEnded { _ in
                            addStroke(draft)
                            draft.removeAll()
                        }
                )

            if showToolbar { toolbar }
        }
    }

    /// 只画内容，不带手势，供导出复用。
    private var canvas: some View {
        Canvas { context, _ in
            for stroke in strokes {
                context.stroke(Self.path(of: stroke.points),
                               with: .color(UPColor.parse(stroke.color, theme: theme)),
                               lineWidth: stroke.lineWidth)
            }
            if draft.count > 1 {
                context.stroke(Self.path(of: draft),
                               with: .color(UPColor.parse(state.lineColor, theme: theme)),
                               lineWidth: state.lineWidth)
            }
        }
        .frame(width: width, height: height)
        .background(UPColor.parse(resolvedBgColor, theme: theme))
    }

    nonisolated static func path(of points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }

    /// 上游工具栏五个图标：撤销、清空、笔画、颜色、确认。
    private var toolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                toolbarIcon("uicon-arrow-left", size: 22, disabled: isEmpty) { undo() }
                toolbarIcon("uicon-trash", size: 25) { clear() }
                toolbarIcon("uicon-edit-pen", size: 25) { toggleBrushSettings() }
                toolbarIcon("uicon-grid", size: 24) { toggleColorSettings() }
                toolbarIcon("uicon-checkmark", size: 25, disabled: isEmpty) { exportSignature() }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            if showBrushSettings { brushSettings }
            if showColorSettings { colorSettings }
        }
    }

    private func toolbarIcon(_ name: String,
                             size: CGFloat,
                             disabled: Bool = false,
                             action: @escaping () -> Void) -> some View {
        UPIcon(name: name, size: String(describing: Int(size)))
            .foregroundStyle(disabled ? theme.disabled : theme.info)
            .contentShape(Rectangle())
            .onTapGesture { guard !disabled else { return }; action() }
    }

    /// 上游是 `u-slider` 的 1…20，原生用 `Slider`。
    private var brushSettings: some View {
        HStack(spacing: 12) {
            Text("笔画大小:")
                .font(.system(size: 13))
                .foregroundStyle(theme.content)
            Slider(value: Binding(get: { Double(state.lineWidth) },
                                  set: { setLineWidth(CGFloat($0)) }),
                   in: 1...20,
                   step: 1)
            Text(String(Int(state.lineWidth)))
                .font(.system(size: 13))
                .foregroundStyle(theme.content)
        }
        .padding(.horizontal, 12)
    }

    private var colorSettings: some View {
        HStack(spacing: 8) {
            Text("笔画颜色:")
                .font(.system(size: 13))
                .foregroundStyle(theme.content)

            ForEach(presetColors, id: \.self) { value in
                Circle()
                    .fill(UPColor.parse(value, theme: theme))
                    .frame(width: 22, height: 22)
                    .overlay {
                        Circle().strokeBorder(value == state.lineColor ? theme.primary : theme.border,
                                              lineWidth: value == state.lineColor ? 2 : 1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectColor(value) }
            }
        }
        .padding(.horizontal, 12)
    }
}
