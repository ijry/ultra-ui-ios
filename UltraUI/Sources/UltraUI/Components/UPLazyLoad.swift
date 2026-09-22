import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-lazy-load` unit props.
public typealias UPLazyLoadUnitValue = UPImageUnitValue

/// 上游 `data.loadStatus` 的三个取值：`''` / `'lazyed'` / `'loaded'`。
public enum UPLazyLoadStatus: String, Equatable, Sendable {
    /// 上游 `''`：还在懒加载中，元素上挂的是占位图。
    case lazy = ""
    /// 上游 `'lazyed'`：占位图已加载完成。
    case lazyed
    /// 上游 `'loaded'`：真正的图片已加载完成。
    case loaded
}

/// 上游 `clickImg()` 里算出来的 `whichImg`。
///
/// 照抄上游：这个变量算完之后没有被用上（`$emit('click', this.index)` 只带 `index`），
/// 原生把它暴露成只读计算属性，方便单测覆盖同一套判定顺序。
public enum UPLazyLoadClickedImage: String, Equatable, Sendable {
    case lazyImg
    case errorImg
    case realImg
}

/// 对应上游 `data`：`isShow` / `opacity` / `time` / `loadStatus` / `isError`。
@MainActor
@Observable
private final class UPLazyLoadState {
    /// 仓库既有语义：是否已触发加载。上游对应 `isShow`。
    var isShow = false
    var isError = false
    var loadStatus: UPLazyLoadStatus = .lazy
    var opacity: Double = 1
    /// 上游 `time`，初始值就是 `duration`。
    var time: Double
    var containerWidth: CGFloat = 0

    init(time: Double) { self.time = time }
}

/// Native SwiftUI counterpart of uview-plus `u-lazy-load`.
///
/// 上游用 `IntersectionObserver` 监听元素是否进入「视口 + threshold」区域，进入后把 `isShow`
/// 翻成真、把 `<image>` 的 `src` 从占位图换成真图，并借 `opacity 1 → 0 → 1` 做淡入。
/// 原生保留同一套状态机（`loadStatus` 两段式、`isError`、`opacity` / `time`），
/// 触发时机换成 `onAppear`，也保留仓库既有的 `content` / `placeholder` 双插槽形态。
@MainActor
public struct UPLazyLoad<Content: View, Placeholder: View>: View {
    /// 上游 `index`：事件回调时带回，用来区分是哪张图。无默认值，未传时是空串。
    public var index: String
    /// 上游 `image`：要显示的图片。
    public var image: String
    /// 上游 `imgMode`。
    public var imgMode: String
    /// 上游 `loadingImg`：预加载占位图。
    public var loadingImg: String
    /// 上游 `errorImg`：加载失败占位图。
    public var errorImg: String
    /// 上游 `getThreshold`：`threshold` 取绝对值转 px 后再还原符号，正数表示提前触发。
    public var threshold: CGFloat
    /// 上游 `duration`：淡入淡出时长，单位 ms。
    public var duration: Double
    /// 上游 `effect`：过渡的速度曲线。
    public var effect: String
    /// 上游 `isEffect`：是否启用淡入淡出。
    public var isEffect: Bool
    /// 上游 `borderRadius`，单位 rpx。
    public var borderRadius: CGFloat
    /// 上游 `height`，走 `addUnit` 后可能是 `auto` 或带 `%`。
    public var height: String
    /// 仓库既有属性：触发过一次之后就不再重复触发。
    public var once: Bool

    private let content: Content
    private let placeholder: Placeholder
    /// 走上游那套「组件自己渲染图片」的形态时为真。
    private let usesImagePipeline: Bool

    private let state: UPLazyLoadState
    private var onLoadHandler: ((String) -> Void)?
    private var onErrorHandler: ((String) -> Void)?
    private var onClickHandler: ((String) -> Void)?

    fileprivate init(index: String,
                     image: String,
                     imgMode: String,
                     loadingImg: String,
                     errorImg: String,
                     threshold: CGFloat,
                     duration: Double,
                     effect: String,
                     isEffect: Bool,
                     borderRadius: CGFloat,
                     height: String,
                     once: Bool,
                     usesImagePipeline: Bool,
                     content: Content,
                     placeholder: Placeholder) {
        self.index = index
        self.image = image
        self.imgMode = imgMode
        self.loadingImg = loadingImg
        self.errorImg = errorImg
        self.threshold = threshold
        self.duration = duration
        self.effect = effect
        self.isEffect = isEffect
        self.borderRadius = borderRadius
        self.height = height
        self.once = once
        self.usesImagePipeline = usesImagePipeline
        self.content = content
        self.placeholder = placeholder
        let state = UPLazyLoadState(time: duration)
        // 上游 `loadStatus` 从 `''` 起步，靠占位图那次 `@load` 推进到 `'lazyed'`。
        // 原生 `loadingImg` 默认是空串（不搬上游那段 4KB base64），此时没有占位图那一次
        // 加载回调，直接从 `'lazyed'` 起步，真图加载完才能照常抛 `load`。
        if usesImagePipeline, loadingImg.isEmpty { state.loadStatus = .lazyed }
        // 上游 `watch.image`：传入空值直接标记为错误状态。
        if usesImagePipeline, image.isEmpty { state.isError = true }
        self.state = state
    }

    /// 仓库既有签名：`content` / `placeholder` 双插槽，`threshold` 是 pt。
    public init(threshold: CGFloat = 0,
                once: Bool = true,
                @ViewBuilder content: () -> Content,
                @ViewBuilder placeholder: () -> Placeholder) {
        self.init(index: "",
                  image: UPConfig.lazyLoad.image,
                  imgMode: UPConfig.lazyLoad.imgMode,
                  loadingImg: UPConfig.lazyLoad.loadingImg,
                  errorImg: UPConfig.lazyLoad.errorImg,
                  threshold: threshold,
                  duration: UPConfig.lazyLoad.duration,
                  effect: UPConfig.lazyLoad.effect,
                  isEffect: false,
                  borderRadius: CGFloat(UPConfig.lazyLoad.borderRadius),
                  height: UPConfig.lazyLoad.height,
                  once: once,
                  usesImagePipeline: false,
                  content: content(),
                  placeholder: placeholder())
    }

    // MARK: - 上游 methods

    /// 上游 `init()`：重置错误标记与加载状态。
    public func reset() {
        state.isShow = false
        state.isError = false
        state.loadStatus = usesImagePipeline && loadingImg.isEmpty ? .lazyed : .lazy
        state.opacity = 1
        state.time = duration
    }

    /// 上游 `IntersectionObserver` 的回调：进入区域后翻 `isShow`，图片为空时直接报错。
    public func appear(distanceToBottom: CGFloat) {
        guard distanceToBottom <= threshold, !once || !state.isShow else { return }
        state.isShow = true
        if usesImagePipeline, image.isEmpty { loadError() }
        if !usesImagePipeline { onLoadHandler?(index) }
    }

    /// 上游 `imgLoaded()`：占位图那次只推进状态，真图那次才抛 `load`。
    public func imgLoaded() {
        switch state.loadStatus {
        case .lazy:
            state.loadStatus = .lazyed
        case .lazyed:
            state.loadStatus = .loaded
            onLoadHandler?(index)
        case .loaded:
            break
        }
    }

    /// 上游 `errorImgLoaded()`：错误占位图加载完成后抛 `error`。
    public func errorImgLoaded() {
        onErrorHandler?(index)
    }

    /// 上游 `loadError()`。
    public func loadError() {
        state.isError = true
    }

    /// 上游 `clickImg()`：只带 `index`。
    public func clickImg() {
        onClickHandler?(index)
    }

    // MARK: - 解析后的呈现值

    /// 仓库既有名：是否已触发加载。
    public var loaded: Bool { state.isShow }
    /// 上游 `isShow`。
    public var isShow: Bool { state.isShow }
    /// 上游 `isError`。
    public var isError: Bool { state.isError }
    /// 上游 `loadStatus`。
    public var loadStatus: UPLazyLoadStatus { state.loadStatus }
    /// 上游 `opacity`。
    public var opacity: Double { isEffect ? state.opacity : 1 }
    /// 上游 `time`：过渡真正生效的时长，单位 ms。
    public var time: Double { state.time }

    /// 上游模板 `:src="isShow ? image : loadingImg"`，`isError` 时换成 `errorImg`。
    public var currentSource: String {
        if state.isError { return errorImg }
        return state.isShow ? image : loadingImg
    }

    /// 上游 `clickImg()` 里的 `whichImg` 判定顺序。
    public var clickedImage: UPLazyLoadClickedImage {
        if !state.isShow { return .lazyImg }
        if state.isError { return .errorImg }
        return .realImg
    }

    /// 上游 `imgHeight`：`addUnit(height)`，数值补 `px`，`auto` / 带 `%` 原样返回。
    public var imgHeight: String { Self.addUnit(height) }

    // MARK: - 可单测的纯函数

    /// 上游 `addUnit(value, 'px')`：能当数值解析的补单位，否则原样返回。
    nonisolated static func addUnit(_ value: String, unit: String = "px") -> String {
        Double(value) != nil ? value + unit : value
    }

    /// 上游 `getThreshold`：先取绝对值转 px，再按原符号还原。
    nonisolated static func resolveThreshold(_ value: String) -> CGFloat {
        let parsed = UPUnit.parse(value)
        guard parsed.isFinite else { return 0 }
        let points = UPUnit.rpx(abs(parsed))
        return parsed < 0 ? -points : points
    }

    /// 上游 `transition: opacity {time}s {effect}` 里的速度曲线。
    nonisolated static func animation(effect: String, duration: Double) -> Animation? {
        guard duration > 0 else { return nil }
        let seconds = duration / 1000
        switch effect.trimmingCharacters(in: .whitespaces).lowercased() {
        case "linear": return .linear(duration: seconds)
        case "ease-in": return .easeIn(duration: seconds)
        case "ease-out": return .easeOut(duration: seconds)
        // `ease` 与 `ease-in-out` 在 SwiftUI 里都落到 easeInOut，
        // `cubic-bezier(...)` 这类无法直译，同样兜底 easeInOut。
        default: return .easeInOut(duration: seconds)
        }
    }

    nonisolated static func parseDuration(_ value: String) -> Double {
        let parsed = Double(UPUnit.parse(value))
        guard parsed.isFinite, parsed > 0 else { return 0 }
        return parsed
    }

    // MARK: - 事件

    /// 仓库既有签名：不关心 `index` 的加载回调。
    public func onLoad(_ action: @escaping () -> Void) -> Self {
        onLoad { _ in action() }
    }

    /// 对应上游 `load` 事件，负载是 `index`。
    public func onLoad(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    /// 对应上游 `error` 事件，负载是 `index`。
    public func onError(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    /// 对应上游 `click` 事件，负载是 `index`。
    public func onClick(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        Group {
            if usesImagePipeline { imageBody } else { slotBody }
        }
        // 上游 `.u-wrap { background-color: #eee; overflow: hidden }`。
        .background(usesImagePipeline ? Color(white: 0.933) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: borderRadius, style: .continuous))
        .opacity(opacity)
        .animation(Self.animation(effect: effect, duration: state.time), value: state.opacity)
        .onAppear { appear(distanceToBottom: 0) }
    }

    private var slotBody: some View {
        Group {
            if state.isShow { content } else { placeholder }
        }
    }

    private var imageBody: some View {
        UPImage(src: currentSource,
                mode: imgMode,
                width: state.containerWidth > 0 ? state.containerWidth : resolvedFallbackWidth,
                height: resolvedHeight,
                radius: borderRadius,
                bgColor: "#eeeeee")
            .onLoad { _ in state.isError ? errorImgLoaded() : imgLoaded() }
            .onError { _ in loadError() }
            .onClick { clickImg() }
            .frame(maxWidth: .infinity)
            .background(widthProbe)
            // 上游 `watch.isShow`：time 归零、opacity 归零，30ms 后再复原以拿到过渡。
            .task(id: state.isShow) { await runFadeIn() }
    }

    private var widthProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { state.containerWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { _, value in state.containerWidth = value }
        }
    }

    private func runFadeIn() async {
        guard isEffect, state.isShow else { return }
        state.time = 0
        state.opacity = 0
        try? await Task.sleep(for: .milliseconds(UPConfig.lazyLoad.effectDelay))
        guard !Task.isCancelled else { return }
        state.time = duration
        state.opacity = 1
    }

    /// 上游 `imgHeight` 可能是 `auto` / 带 `%`，SwiftUI 需要具体值时退回默认高度。
    private var resolvedHeight: CGFloat {
        let parsed = UPUnit.parse(height)
        return parsed > 0 ? parsed : UPUnit.parse(UPConfig.lazyLoad.height)
    }

    /// 容器宽度还没量到时的兜底值（上游是 `width: 100%`）。
    private var resolvedFallbackWidth: CGFloat { UPConfig.waterfall.windowWidth }
}

public extension UPLazyLoad where Content == EmptyView, Placeholder == EmptyView {
    /// 与上游 `props` 对齐的初始化器：图片由组件自己渲染。
    ///
    /// `image` 上游默认是空串，这里刻意不给默认值：留默认值会让
    /// `UPLazyLoad(threshold: 10)` 这种调用因整数字面量优先匹配
    /// `any UPLazyLoadUnitValue` 而错落到本 init 上，与仓库既有签名撞车。
    init(image: String,
         index: (any UPLazyLoadUnitValue)? = nil,
         imgMode: String = UPConfig.lazyLoad.imgMode,
         loadingImg: String = UPConfig.lazyLoad.loadingImg,
         errorImg: String = UPConfig.lazyLoad.errorImg,
         threshold: any UPLazyLoadUnitValue = UPConfig.lazyLoad.threshold,
         duration: any UPLazyLoadUnitValue = UPConfig.lazyLoad.duration,
         effect: String = UPConfig.lazyLoad.effect,
         isEffect: Bool = UPConfig.lazyLoad.isEffect,
         borderRadius: any UPLazyLoadUnitValue = UPConfig.lazyLoad.borderRadius,
         height: any UPLazyLoadUnitValue = UPConfig.lazyLoad.height) {
        self.init(index: index?.upImageUnitValue ?? "",
                  image: image,
                  imgMode: imgMode,
                  loadingImg: loadingImg,
                  errorImg: errorImg,
                  threshold: UPLazyLoad.resolveThreshold(threshold.upImageUnitValue),
                  duration: UPLazyLoad.parseDuration(duration.upImageUnitValue),
                  effect: effect,
                  isEffect: isEffect,
                  borderRadius: UPUnit.rpx(max(UPUnit.parse(borderRadius.upImageUnitValue), 0)),
                  height: height.upImageUnitValue,
                  once: true,
                  usesImagePipeline: true,
                  content: EmptyView(),
                  placeholder: EmptyView())
    }

    /// 仓库既有签名：不带插槽的空壳，只用来做触发判定。
    init(threshold: CGFloat = 0, once: Bool = true) {
        self.init(threshold: threshold,
                  once: once,
                  content: EmptyView.init,
                  placeholder: EmptyView.init)
    }
}

public extension UPLazyLoad where Placeholder == EmptyView {
    /// 仓库既有签名：只给 `content`，占位为空。
    init(threshold: CGFloat = 0,
         once: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.init(threshold: threshold, once: once, content: content, placeholder: EmptyView.init)
    }
}
