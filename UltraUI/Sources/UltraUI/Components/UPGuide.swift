import SwiftUI

/// Semantic alias for the String-or-Number props accepted by uview-plus `u-guide`.
public typealias UPGuideUnitValue = UPCheckboxUnitValue

/// One entry of the upstream `list` prop (`image`/`title`/`desc`/`backgroundColor`).
public struct UPGuideStep: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var message: String
    public var image: String
    public var desc: String
    public var backgroundColor: String
    /// 上游模板渲染 `item.desc`；原生保留既有的 `message`，`desc` 为空时回落到它。
    public var resolvedDesc: String { desc.isEmpty ? message : desc }
    public init(id: String, title: String = "", message: String = "", image: String = "", desc: String = "", backgroundColor: String = "") { self.id = id; self.title = title; self.message = message; self.image = image; self.desc = desc; self.backgroundColor = backgroundColor }
}

@MainActor
private final class UPGuideState { var current: Int; var innerShow: Bool; var closing = false; init(current: Int, innerShow: Bool) { self.current = current; self.innerShow = innerShow } }

/// Step-based overlay guide corresponding to uview-plus `u-guide`.
///
/// `show` maps to the upstream `show` prop plus its `update:show` emit: pass a
/// Binding for v-model behaviour or observe `onUpdateShow(_:)`. The upstream
/// `mounted → bootstrap()` hook runs while the value is built so `show` already
/// reflects the remembered flag, and it stays silent there because emitting
/// during view construction would write SwiftUI state mid-update; call
/// `bootstrap()` explicitly to replay it with events.
@MainActor
public struct UPGuide: View {
    public var steps: [UPGuideStep]
    public var storageKey: String
    public var once: Bool
    public var showSkip: Bool
    public var skipText: String
    public var nextText: String
    public var finishText: String
    public var indicator: Bool
    public var bgColor: String
    public var zIndex: Double
    public var current: Int { state.current }
    /// 上游渲染条件 `innerShow && pageList.length`。
    public var show: Bool { state.innerShow && !steps.isEmpty }
    /// 上游 `isLastPage()`：末屏（含空列表）时主按钮显示 `finishText`。
    public var isLastStep: Bool { current >= steps.count - 1 }
    public var actionText: String { isLastStep ? finishText : nextText }
    /// 上游 `resolvedStorageKey`：空串回落到 `up-guide-default`。
    public var resolvedStorageKey: String { storageKey.isEmpty ? UPConfig.guide.storageKey : storageKey }
    /// 上游页面背景 `item.backgroundColor || bgColor`。
    public var currentBackgroundColor: String { steps.indices.contains(safeCurrent) && !steps[safeCurrent].backgroundColor.isEmpty ? steps[safeCurrent].backgroundColor : bgColor }
    private var requestedShow: Bool
    private let storage: UserDefaults
    private let state: UPGuideState
    private var showBinding: Binding<Bool>?
    private var onChangeHandler: ((Int) -> Void)?
    private var onFinishHandler: (() -> Void)?
    private var onSkipHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onUpdateShowHandler: ((Bool) -> Void)?
    private var safeCurrent: Int { steps.isEmpty ? 0 : min(max(state.current, 0), steps.count - 1) }
    @Environment(\.upTheme) private var theme

    public init(steps: [UPGuideStep] = UPConfig.guide.list, show: Bool = UPConfig.guide.show, storageKey: String = UPConfig.guide.storageKey, once: Bool = UPConfig.guide.once, showSkip: Bool = UPConfig.guide.showSkip, skipText: String = UPConfig.guide.skipText, nextText: String = UPConfig.guide.nextText, finishText: String = UPConfig.guide.finishText, indicator: Bool = UPConfig.guide.indicator, bgColor: String = UPConfig.guide.bgColor, zIndex: some UPGuideUnitValue = UPConfig.guide.zIndex, current: Int = 0, storage: UserDefaults = .standard) {
        self.init(steps: steps, show: show, storageKey: storageKey, once: once, showSkip: showSkip, skipText: skipText, nextText: nextText, finishText: finishText, indicator: indicator, bgColor: bgColor, zIndex: zIndex.upCheckboxUnitValue, current: current, storage: storage, showBinding: nil)
    }

    public init(steps: [UPGuideStep] = UPConfig.guide.list, show: Binding<Bool>, storageKey: String = UPConfig.guide.storageKey, once: Bool = UPConfig.guide.once, showSkip: Bool = UPConfig.guide.showSkip, skipText: String = UPConfig.guide.skipText, nextText: String = UPConfig.guide.nextText, finishText: String = UPConfig.guide.finishText, indicator: Bool = UPConfig.guide.indicator, bgColor: String = UPConfig.guide.bgColor, zIndex: some UPGuideUnitValue = UPConfig.guide.zIndex, current: Int = 0, storage: UserDefaults = .standard) {
        self.init(steps: steps, show: show.wrappedValue, storageKey: storageKey, once: once, showSkip: showSkip, skipText: skipText, nextText: nextText, finishText: finishText, indicator: indicator, bgColor: bgColor, zIndex: zIndex.upCheckboxUnitValue, current: current, storage: storage, showBinding: show)
    }

    private init(steps: [UPGuideStep], show: Bool, storageKey: String, once: Bool, showSkip: Bool, skipText: String, nextText: String, finishText: String, indicator: Bool, bgColor: String, zIndex: String, current: Int, storage: UserDefaults, showBinding: Binding<Bool>?) {
        self.steps = steps; self.requestedShow = show; self.storageKey = storageKey; self.once = once
        self.showSkip = showSkip; self.skipText = skipText; self.nextText = nextText; self.finishText = finishText
        self.indicator = indicator; self.bgColor = bgColor; self.zIndex = Self.resolveZIndex(zIndex, fallback: UPConfig.guide.zIndex)
        self.storage = storage; self.showBinding = showBinding
        let key = storageKey.isEmpty ? UPConfig.guide.storageKey : storageKey
        let remembered = once && Self.remembered(in: storage, key: key)
        self.state = UPGuideState(current: steps.isEmpty ? 0 : min(max(current, 0), steps.count - 1), innerShow: steps.isEmpty ? false : (remembered ? false : show))
    }

    public var body: some View {
        if show {
            VStack(spacing: 0) {
                pageContent(steps[safeCurrent])
                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UPColor.parse(currentBackgroundColor, theme: theme))
            .ignoresSafeArea()
            .zIndex(zIndex)
        }
    }

    /// 上游 `mounted → bootstrap()`：空列表直接 return（只打印告警），`once`
    /// 且已记忆时关闭并回抛 `update:show=false`，否则跟随 `show`。
    public func bootstrap() {
        guard !steps.isEmpty else { state.innerShow = false; return }
        if once, readRemembered() { state.innerShow = false; emitUpdateShow(false); return }
        state.innerShow = requestedShow
    }

    /// 上游 `onPrimaryAction()`：末屏先派发 `finish` 再 `close(true)`。
    @discardableResult public func next() -> Bool {
        guard !isLastStep else { onFinishHandler?(); close(); return false }
        state.current += 1; onChangeHandler?(state.current); return true
    }

    /// 原生补充的回退能力，上游只提供 swiper 手势回退。
    @discardableResult public func previous() -> Bool {
        guard current > 0 else { return false }
        state.current -= 1; onChangeHandler?(state.current); return true
    }

    /// 上游 `onSwiperChange(event)`：同步 `current` 并派发 `change`。
    public func select(_ index: Int) {
        guard !steps.isEmpty else { return }
        state.current = min(max(index, 0), steps.count - 1); onChangeHandler?(state.current)
    }

    /// 上游 `onSkip()`：先派发 `skip`，再 `close(true)`。
    public func skip() { onSkipHandler?(); close() }

    /// 上游 `open()`：重置 `current` 并显示，不清除记忆。
    public func open() { state.current = 0; state.innerShow = true; emitUpdateShow(true) }

    /// 上游 `close(remember = true)`：`closing` 标记在同一 tick 内去重，
    /// `$nextTick` 后恢复。
    public func close(remember: Bool = true) {
        guard !state.closing else { return }
        state.closing = true
        if remember, once { writeRemembered() }
        state.innerShow = false
        emitUpdateShow(false)
        onCloseHandler?()
        let state = state
        Task { @MainActor in state.closing = false }
    }

    /// 上游 `reset()`：清除记忆键。
    public func reset() { storage.removeObject(forKey: resolvedStorageKey) }

    /// 上游 `readRemembered()`：只认 `true` / `1` / `'1'`。
    public func readRemembered() -> Bool { Self.remembered(in: storage, key: resolvedStorageKey) }

    /// 上游 `writeRemembered()`：写入的是数字 `1`。
    public func writeRemembered() { storage.set(1, forKey: resolvedStorageKey) }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onFinish(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onFinishHandler = action; return copy }
    public func onSkip(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onSkipHandler = action; return copy }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
    public func onUpdateShow(_ action: @escaping (Bool) -> Void) -> Self { var copy = self; copy.onUpdateShowHandler = action; return copy }

    private func emitUpdateShow(_ value: Bool) { showBinding?.wrappedValue = value; onUpdateShowHandler?(value) }

    @ViewBuilder
    private func pageContent(_ step: UPGuideStep) -> some View {
        VStack(spacing: 0) {
            if step.image.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: Self.mediaSide, height: Self.mediaSide)
                    .overlay(Text("暂无引导图").font(.system(size: 14)).foregroundStyle(.white))
            } else {
                UPImage(src: step.image, mode: "aspectFit", width: Self.mediaSide, height: Self.mediaSide)
            }

            if !step.title.isEmpty {
                Text(step.title).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white).padding(.top, 24)
            }

            if !step.resolvedDesc.isEmpty {
                Text(step.resolvedDesc).font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center).padding(.top, 9)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 13) {
            if indicator {
                HStack(spacing: 6) {
                    ForEach(Array(steps.indices), id: \.self) { index in
                        Capsule()
                            .fill(index == safeCurrent ? Color.white : Color.white.opacity(0.35))
                            .frame(width: index == safeCurrent ? 17 : 7, height: 7)
                    }
                }
            }

            HStack(spacing: 8) {
                if showSkip {
                    Button { skip() } label: {
                        actionLabel(skipText, foreground: .white).overlay(Capsule().stroke(Color.white.opacity(0.42), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Button { next() } label: {
                    actionLabel(actionText, foreground: UPColor.parse("#111111", theme: theme), weight: .semibold).background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func actionLabel(_ text: String, foreground: Color, weight: Font.Weight = .regular) -> some View {
        Text(text).font(.system(size: 14, weight: weight)).foregroundStyle(foreground).frame(maxWidth: .infinity).frame(height: 42)
    }

    /// 上游图片与占位块都是 560rpx，按 375pt 基准宽度折算为 280pt。
    private static let mediaSide: CGFloat = 280

    private nonisolated static func remembered(in storage: UserDefaults, key: String) -> Bool {
        let value = storage.object(forKey: key)
        if let number = value as? NSNumber { return number.intValue == 1 }
        if let text = value as? String { return text == "1" }
        return false
    }

    private nonisolated static func resolveZIndex(_ value: String, fallback: Double) -> Double {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let parsed = Double(UPUnit.parse(trimmed))
        return parsed.isFinite ? parsed : fallback
    }
}
