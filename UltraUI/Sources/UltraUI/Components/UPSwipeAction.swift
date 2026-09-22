import SwiftUI

/// Semantic alias for the `String | Number` props accepted by uview-plus
/// `u-swipe-action-item`.
public typealias UPSwipeActionUnitValue = UPCheckboxUnitValue

/// Semantic alias for the upstream `name` identifier prop.
public typealias UPSwipeActionNameValue = UPCellNameValue

/// 上游 `options` 里的一项：`{ text, icon, iconSize, style }`。
///
/// `style` 里上游只读 `backgroundColor` / `borderRadius` / `color` / `fontSize` 四个键。
public struct UPSwipeAction: Identifiable, Equatable, Sendable {
    public let id: String
    /// 上游 `item.text`。仓库既有字段名是 `title`，两者互为别名。
    public var title: String
    /// 仓库既有字段：按钮底色。等价于上游 `item.style.backgroundColor`。
    public var color: String
    public var disabled: Bool
    /// 上游 `item.icon`。
    public var icon: String
    /// 上游 `item.iconSize`：给了它就优先于 `style.fontSize * 1.2`。
    public var iconSize: String
    /// 上游 `item.style`。
    public var style: UPStyle

    public init(id: String,
                title: String,
                color: String = "#f56c6c",
                disabled: Bool = false,
                icon: String = "",
                iconSize: String = "",
                style: UPStyle = UPStyle()) {
        self.id = id
        self.title = title
        self.color = color
        self.disabled = disabled
        self.icon = icon
        self.iconSize = iconSize
        self.style = style
    }

    /// 上游字段名。
    public var text: String { title }

    /// 上游 `item.style.backgroundColor ? ... : defaultButtonBgColor`。
    /// 仓库既有的 `color` 字段落在同一个位置。
    public var resolvedBackgroundColor: String {
        if let value = style["backgroundColor"], !value.isEmpty { return value }
        return color.isEmpty ? UPConfig.swipeActionItem.buttonBackgroundColor : color
    }

    /// 上游 `item.style.color ? ... : defaultButtonColor`。
    public var resolvedTextColor: String {
        if let value = style["color"], !value.isEmpty { return value }
        return UPConfig.swipeActionItem.buttonColor
    }

    /// 上游 `item.style.fontSize ? ... : '16px'`，文字与行高共用同一个值。
    public var resolvedFontSize: CGFloat {
        guard let value = style["fontSize"], !value.isEmpty else {
            return UPConfig.swipeActionItem.buttonFontSize
        }
        let parsed = UPUnit.parse(value)
        return parsed > 0 ? parsed : UPConfig.swipeActionItem.buttonFontSize
    }

    /// 上游 `item.style.borderRadius`：设了它按钮就不再撑满整高、内边距归零。
    public var resolvedCornerRadius: CGFloat {
        guard let value = style["borderRadius"], !value.isEmpty else { return 0 }
        return max(UPUnit.parse(value), 0)
    }

    /// 上游 `borderRadius` 决定 `alignItems: center | stretch` 与 `padding: 0 | 0 15px`。
    public var hasCornerRadius: Bool { resolvedCornerRadius > 0 }

    /// 上游图标尺寸：`iconSize` 优先，其次 `style.fontSize * 1.2`，最后兜底 17。
    public var resolvedIconSize: CGFloat {
        if !iconSize.isEmpty {
            let parsed = UPUnit.parse(iconSize)
            if parsed > 0 { return parsed }
        }
        if let value = style["fontSize"], !value.isEmpty {
            let parsed = UPUnit.parse(value)
            if parsed > 0 { return parsed * UPConfig.swipeActionItem.buttonIconScale }
        }
        return UPConfig.swipeActionItem.buttonIconSize
    }
}

/// Payload of the upstream `click` emit, which passes `{ index, name }`.
public struct UPSwipeActionClickEvent: Equatable, Sendable {
    public let index: Int
    public let name: UPCellName
    public init(index: Int, name: UPCellName) { self.index = index; self.name = name }
}

@MainActor
@Observable
private final class UPSwipeActionState {
    var opened: Bool
    var scrolling: Bool
    /// 上游 `sliderStyle.transform` 里的 `translateX`，展开时是负值。
    var offset: CGFloat = 0
    /// 上游 `state.buttonsWidth`：`queryRect` 量到的按钮区总宽。
    var buttonsWidth: CGFloat = 0
    /// 上游 `state.moving`。
    var moving = false

    init(opened: Bool, scrolling: Bool) {
        self.opened = opened
        self.scrolling = scrolling
    }
}

/// Swipeable row corresponding to uview-plus `u-swipe-action-item`.
@MainActor
public struct UPSwipeActionItem<Content: View>: View {
    public var id: String
    public var closeOnClick: Bool
    public var name: UPCellName
    public var disabled: Bool
    public var autoClose: Bool
    public var actions: [UPSwipeAction]
    public var threshold: CGFloat
    public var duration: String
    /// Upstream prop name for the right-hand buttons; `actions` is the native alias.
    public var options: [UPSwipeAction] { actions }
    public var opened: Bool { state.opened }
    /// Mirrors upstream `innerScrolling`, the cached value behind `v-model:scrolling`.
    public var isScrolling: Bool { state.scrolling }
    /// Upstream resolves `duration` through `getDuration`, which infers the unit
    /// from a 30 threshold: `ms` suffixes keep their number, `s` suffixes below
    /// the threshold are multiplied by 1000, and bare numbers under 30 are read
    /// as seconds. Parsing uses `Double` so `"0.3s"` yields 300 instead of the
    /// `parseInt` result of 0.
    public var resolvedDuration: Double { Self.resolveDuration(duration) }
    @State private var state: UPSwipeActionState
    private let content: Content
    private var onActionHandler: ((UPSwipeAction) -> Void)?
    private var onClickHandler: ((UPSwipeActionClickEvent) -> Void)?
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onScrollingHandler: ((Bool) -> Void)?
    private var buttonSlot: AnyView?

    @Environment(\.upTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    public init(id: String, show: Bool = UPConfig.swipeActionItem.show, closeOnClick: Bool = UPConfig.swipeActionItem.closeOnClick, name: some UPSwipeActionNameValue = UPConfig.swipeActionItem.name, disabled: Bool = UPConfig.swipeActionItem.disabled, autoClose: Bool = UPConfig.swipeActionItem.autoClose, scrolling: Bool = UPConfig.swipeActionItem.scrolling, threshold: CGFloat = UPConfig.swipeActionItem.threshold, actions: [UPSwipeAction] = UPConfig.swipeActionItem.options, options: [UPSwipeAction] = UPConfig.swipeActionItem.options, duration: some UPSwipeActionUnitValue = UPConfig.swipeActionItem.duration, @ViewBuilder content: () -> Content) {
        self.id = id; self.closeOnClick = closeOnClick; self.name = name.upCellNameValue; self.disabled = disabled
        self.autoClose = autoClose; self.actions = actions.isEmpty ? options : actions; self.threshold = max(threshold, 0)
        self.duration = duration.upCheckboxUnitValue
        self._state = State(initialValue: UPSwipeActionState(opened: show && !disabled, scrolling: scrolling && !disabled)); self.content = content()
    }
    public init(id: String, show: Bool = UPConfig.swipeActionItem.show, closeOnClick: Bool = UPConfig.swipeActionItem.closeOnClick, name: some UPSwipeActionNameValue = UPConfig.swipeActionItem.name, disabled: Bool = UPConfig.swipeActionItem.disabled, autoClose: Bool = UPConfig.swipeActionItem.autoClose, scrolling: Bool = UPConfig.swipeActionItem.scrolling, threshold: CGFloat = UPConfig.swipeActionItem.threshold, actions: [UPSwipeAction] = UPConfig.swipeActionItem.options, options: [UPSwipeAction] = UPConfig.swipeActionItem.options, duration: some UPSwipeActionUnitValue = UPConfig.swipeActionItem.duration) where Content == EmptyView {
        self.id = id; self.closeOnClick = closeOnClick; self.name = name.upCellNameValue; self.disabled = disabled
        self.autoClose = autoClose; self.actions = actions.isEmpty ? options : actions; self.threshold = max(threshold, 0)
        self.duration = duration.upCheckboxUnitValue
        self._state = State(initialValue: UPSwipeActionState(opened: show && !disabled, scrolling: scrolling && !disabled)); self.content = EmptyView()
    }

    // MARK: - 视图

    /// 上游结构：`__right` 绝对定位在右侧（z-index 1），`__content` 盖在上面（z-index 10）
    /// 并靠 `translateX` 左移把按钮露出来，外层 `overflow: hidden` 负责裁切。
    public var body: some View {
        ZStack(alignment: .trailing) {
            buttonRow

            content
                .frame(maxWidth: .infinity)
                .background(UPColor.parse(UPConfig.swipeActionItem.contentBackgroundColor, theme: theme))
                .offset(x: state.offset)
                .animation(.easeOut(duration: resolvedDuration / 1000), value: state.opened)
        }
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture)
        .onChange(of: state.opened) { _, opened in
            state.offset = opened ? -state.buttonsWidth : 0
        }
    }

    /// 上游 `__right` 里的按钮组，或 `button` 插槽。
    private var buttonRow: some View {
        HStack(spacing: 0) {
            if let buttonSlot {
                buttonSlot
            } else {
                ForEach(actions) { action in
                    buttonCell(action)
                }
            }
        }
        .background(widthProbe)
    }

    private func buttonCell(_ action: UPSwipeAction) -> some View {
        Button { trigger(action.id) } label: {
            HStack(spacing: action.icon.isEmpty || action.title.isEmpty
                   ? 0
                   : UPConfig.swipeActionItem.buttonIconSpacing) {
                if !action.icon.isEmpty {
                    UPIcon(name: action.icon,
                           color: action.resolvedTextColor,
                           size: String(describing: Double(action.resolvedIconSize)))
                }

                if !action.title.isEmpty {
                    Text(action.title)
                        .font(.system(size: action.resolvedFontSize))
                        .foregroundStyle(UPColor.parse(action.resolvedTextColor, theme: theme))
                        .lineLimit(1)
                }
            }
            // 上游：设了 borderRadius 时内边距归零，否则左右各 15px。
            .padding(.horizontal, action.hasCornerRadius ? 0 : UPConfig.swipeActionItem.buttonPadding)
            // 上游：设了 borderRadius 时按钮只包住内容（alignItems: center），否则撑满整高。
            .frame(maxHeight: action.hasCornerRadius ? nil : .infinity)
            .background(UPColor.parse(resolvedBackgroundColor(action), theme: theme),
                        in: RoundedRectangle(cornerRadius: action.resolvedCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled || action.disabled)
    }

    /// 上游 `defaultButtonBgColor` 会随暗色模式回落到 `#4b5563`。
    private func resolvedBackgroundColor(_ action: UPSwipeAction) -> String {
        let resolved = action.resolvedBackgroundColor
        guard resolved == UPConfig.swipeActionItem.buttonBackgroundColor, colorScheme == .dark else {
            return resolved
        }
        return UPConfig.swipeActionItem.darkButtonBackgroundColor
    }

    /// 上游 `queryRect` 量 `.u-swipe-action-item__right__button` 的总宽。
    private var widthProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { recordButtonsWidth(proxy.size.width) }
                .onChange(of: proxy.size.width) { _, value in recordButtonsWidth(value) }
        }
    }

    public func recordButtonsWidth(_ width: CGFloat) {
        guard width > 0, width != state.buttonsWidth else { return }
        state.buttonsWidth = width
        if state.opened { state.offset = -width }
    }

    /// 上游 `buttonsWidth`。
    public var buttonsWidth: CGFloat { state.buttonsWidth }

    /// 上游 `sliderStyle` 里的 `translateX`。
    public var offset: CGFloat { state.offset }

    // MARK: - 手势

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard !disabled else { return }
                if !state.moving { touchStart() }
                touchMove(translation: value.translation)
            }
            .onEnded { value in
                touchEnd(translation: value.translation)
            }
    }

    /// 上游 `touchstart`：标记滑动中并记录起点（原生的 `DragGesture` 自带位移，
    /// 因此只需要立起 `moving` 标记）。上游同时会让父组件关掉其他单元格，
    /// 那一步由 `UPSwipeActionGroup.closeOther(_:)` 承担。
    public func touchStart() {
        guard !disabled else { return }
        state.moving = true
    }

    /// 上游 `touchcancel`：清掉滑动标记并复位滑动状态。
    public func touchCancel() {
        state.moving = false
        setScrolling(false)
    }

    /// 上游 `state.moving`。
    public var isMoving: Bool { state.moving }

    /// 上游 `touchmove`：横向位移小于纵向时判为页面滚动直接 return；
    /// 展开态下只认右滑收起、关闭态下只认左滑展开，位移都夹在按钮总宽内。
    public func touchMove(translation: CGSize) {
        guard !disabled, state.moving else { return }
        var moveX = translation.width
        guard abs(moveX) >= abs(translation.height) else { return }
        setScrolling(true)

        if state.opened {
            if moveX < 0 { moveX = 0 }
            if moveX > state.buttonsWidth { moveX = state.buttonsWidth }
            state.offset = -state.buttonsWidth + moveX
        } else {
            if moveX > 0 { moveX = 0 }
            if abs(moveX) > state.buttonsWidth { moveX = -state.buttonsWidth }
            state.offset = moveX
        }
    }

    /// 上游 `touchend`：按 `threshold` 决定是回弹还是切换状态。
    ///
    /// 照抄上游：展开态下继续左滑（`moveX < 0`）直接 return，此时内容停在手指
    /// 拖到的位置而不回弹；`moveX == 0` 视为点了内容区，直接收起。
    public func touchEnd(translation: CGSize) {
        guard state.moving, !disabled else {
            setScrolling(false)
            return
        }
        state.moving = false
        setScrolling(false)
        let moveX = translation.width

        if state.opened {
            if moveX < 0 { return }
            if moveX == 0 { close(); return }
            if abs(moveX) < threshold { open() } else { close() }
        } else {
            if moveX > 0 { return }
            if abs(moveX) < threshold { close() } else { open() }
        }
    }

    // MARK: - 插槽

    /// 对应上游具名插槽 `button`：给了它就不再渲染内建按钮组。
    public func buttonContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.buttonSlot = AnyView(builder())
        return copy
    }

    public var hasButtonSlot: Bool { buttonSlot != nil }

    /// 上游 `openSwipeAction`：把内容左移一个按钮总宽并置 `open`。
    public func open() {
        guard !disabled else { return }
        state.offset = -state.buttonsWidth
        guard !state.opened else { return }
        state.opened = true
        onOpenHandler?()
    }

    /// 上游 `closeHandler` / `closeSwipeAction`：收起前先复位滑动状态。
    public func close() {
        setScrolling(false)
        state.offset = 0
        guard state.opened else { return }
        state.opened = false
        onCloseHandler?()
    }
    /// Mirrors upstream `setScrolling`: deduplicates against the cached value and
    /// then emits `update:scrolling` and `scrolling` with the same payload.
    public func setScrolling(_ value: Bool) { guard state.scrolling != value else { return }; state.scrolling = value; onScrollingHandler?(value) }
    public func trigger(_ id: String) {
        guard !disabled, let index = actions.firstIndex(where: { $0.id == id }), !actions[index].disabled else { return }
        let action = actions[index]
        onClickHandler?(UPSwipeActionClickEvent(index: index, name: name))
        onActionHandler?(action)
        if closeOnClick { close() }
    }
    nonisolated static func resolveDuration(_ value: String) -> Double {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return UPConfig.swipeActionItem.duration }
        if normalized.hasSuffix("ms") {
            guard let number = Double(normalized.dropLast(2)), number.isFinite else { return UPConfig.swipeActionItem.duration }
            return max(0, number)
        }
        if normalized.hasSuffix("s") {
            guard let number = Double(normalized.dropLast()), number.isFinite else { return UPConfig.swipeActionItem.duration }
            return max(0, number > 30 ? number : number * 1_000)
        }
        guard let number = Double(normalized), number.isFinite else { return UPConfig.swipeActionItem.duration }
        return max(0, number < 30 ? number * 1_000 : number)
    }
    public func onAction(_ action: @escaping (UPSwipeAction) -> Void) -> Self { var copy = self; copy.onActionHandler = action; return copy }
    public func onClick(_ action: @escaping (UPSwipeActionClickEvent) -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func onOpen(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onOpenHandler = action; return copy }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
    public func onScrolling(_ action: @escaping (Bool) -> Void) -> Self { var copy = self; copy.onScrollingHandler = action; return copy }
}

/// Coordinator for uview-plus `u-swipe-action` mutual exclusion.
@MainActor
public final class UPSwipeActionGroup {
    public let autoClose: Bool
    /// Opened cells in the order they were opened. Upstream keeps at most one
    /// entry while `autoClose` is on, and allows several once it is off.
    public private(set) var openedIDs: [String]
    public var openedID: String? { openedIDs.last }
    /// Mirrors the upstream `opendItem` model, which tracks whether any cell is open.
    public var opendItem: Bool { !openedIDs.isEmpty }
    private var registeredIDs: Set<String>
    private var onOpendItemUpdateHandler: ((Bool) -> Void)?
    public init(autoClose: Bool = UPConfig.swipeAction.autoClose) { self.autoClose = autoClose; openedIDs = []; registeredIDs = [] }
    @discardableResult public func register(_ id: String) -> Self { registeredIDs.insert(id); return self }
    @discardableResult public func open(_ id: String) -> Self {
        guard registeredIDs.contains(id) else { return self }
        closeOther(id)
        if !openedIDs.contains(id) { openedIDs.append(id) }
        onOpendItemUpdateHandler?(true)
        return self
    }
    /// Mirrors upstream `closeOther`, which only collapses the siblings when `autoClose` is on.
    public func closeOther(_ id: String) { guard autoClose else { return }; openedIDs = openedIDs.filter { $0 == id } }
    public func close(_ id: String) { openedIDs.removeAll { $0 == id } }
    public func closeAll() { openedIDs = [] }
    public func close() { closeAll() }
    /// Mirrors the upstream `opendItem` watcher: only a `false` value acts, and it closes every cell.
    public func updateOpendItem(_ value: Bool) { guard !value else { return }; closeAll() }
    /// Upstream emits the reversed spelling `opendItem:update`, always with `true`.
    @discardableResult public func onOpendItemUpdate(_ action: @escaping (Bool) -> Void) -> Self { onOpendItemUpdateHandler = action; return self }
}
