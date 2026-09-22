import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-steps-item`.
///
/// 上游一个子项由三块组成：连线（只在不是最后一项时画）、圆点/图标/序号圈，以及
/// 标题 + 描述。父级的 7 个 prop 通过 `getParentData('u-steps')` 拿到，
/// 原生改用 Environment 下发，同时用 PreferenceKey 把自身 `error` 回报给父级
/// （上游 `lineStyle` 需要看下一个兄弟的 `error`）。
@MainActor
public struct UPStepsItem<Content: View>: View {
    public var title: String
    public var desc: String
    public var iconSize: String
    /// 上游 `error`：当前步骤是否失败。
    public var error: Bool
    /// 上游 `itemStyle`：作用在 `.__wrapper` 上。
    public var itemStyle: UPStyle

    private let content: Content
    private let identity = UUID()
    private var onClickHandler: (() -> Void)?
    private var iconSlot: AnyView?
    private var titleSlot: AnyView?
    private var descSlot: AnyView?
    private var contentSlot: ((Int) -> AnyView)?

    @Environment(\.upStepsParentData) private var parentData
    @Environment(\.upTheme) private var theme

    public init(title: String = UPConfig.stepsItem.title,
                desc: String = UPConfig.stepsItem.desc,
                iconSize: some UPImageUnitValue = UPConfig.stepsItem.iconSize,
                error: Bool = UPConfig.stepsItem.error,
                itemStyle: UPStyle = UPStyle(),
                @ViewBuilder content: () -> Content) {
        self.title = title
        self.desc = desc
        self.iconSize = iconSize.upImageUnitValue
        self.error = error
        self.itemStyle = itemStyle
        self.content = content()
    }

    // MARK: - 解析后的呈现值

    public var resolvedIconSize: CGFloat { UPUnit.parse(iconSize) }

    /// 上游 `parentData`。未挂在 `u-steps` 里时上游会 `error('必须搭配 u-steps 使用')`，
    /// 原生退回一份占位数据而不是崩溃。
    var resolvedParentData: UPStepsParentData { parentData ?? .placeholder }

    /// 上游 `index = parent.children.indexOf(this)`。
    ///
    /// 原生用 PreferenceKey 把自身登记给父级，再从父级下发的登记顺序里反查下标，
    /// 因此首帧（父级还没收到登记）会是 0，第二帧才稳定 —— 与上游
    /// `mounted` 里先 `updateFromChild()` 再重排的两段式一致。
    public var index: Int {
        resolvedParentData.childIDs.firstIndex(of: identity) ?? 0
    }

    /// 上游 `statusClass`。
    public func status(index: Int) -> UPStepStatus {
        UPSteps<EmptyView>.status(index: index,
                                 current: resolvedParentData.current,
                                 error: error)
    }

    /// 上游 `statusColor`。
    public func statusColor(index: Int) -> String {
        UPSteps<EmptyView>.statusColor(status: status(index: index),
                                       activeColor: resolvedParentData.activeColor,
                                       inactiveColor: resolvedParentData.inactiveColor,
                                       dot: resolvedParentData.dot)
    }

    /// 上游 `contentStyle`：dot 模式两个方向都是 2px，非 dot 是 6px。
    public var contentSpacing: CGFloat {
        resolvedParentData.dot
            ? UPConfig.stepsItem.dotContentSpacing
            : UPConfig.stepsItem.circleContentSpacing
    }

    /// 上游 `v-if="index + 1 < childLength"`：最后一项不画连线。
    public func showsLine(index: Int) -> Bool {
        index + 1 < resolvedParentData.childLength
    }

    // MARK: - 事件与插槽

    /// 仓库既有事件。上游 `.__content__title` 只在 H5 上加了 `cursor: pointer`，
    /// 没有绑定任何点击回调，因此这是原生扩展。
    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public func triggerClick() { onClickHandler?() }

    /// 对应上游具名插槽 `icon`。
    public func icon<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.iconSlot = AnyView(builder())
        return copy
    }

    /// 对应上游具名插槽 `title`。
    public func titleContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.titleSlot = AnyView(builder())
        return copy
    }

    /// 对应上游具名插槽 `desc`。
    public func descContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.descSlot = AnyView(builder())
        return copy
    }

    /// 对应上游作用域插槽 `content`（参数是 `index`）。给了它就不再渲染标题与描述。
    public func stepContent<Slot: View>(@ViewBuilder _ builder: @escaping (Int) -> Slot) -> Self {
        var copy = self
        copy.contentSlot = { AnyView(builder($0)) }
        return copy
    }

    public var hasIconSlot: Bool { iconSlot != nil }
    public var hasTitleSlot: Bool { titleSlot != nil }
    public var hasDescSlot: Bool { descSlot != nil }
    public var hasContentSlot: Bool { contentSlot != nil }

    // MARK: - 视图

    public var body: some View {
        Group {
            if resolvedParentData.direction == "column" { columnBody } else { rowBody }
        }
        .preference(key: UPStepsRegistrationKey.self,
                    value: [UPStepsItemRegistration(id: identity, error: error)])
    }

    /// 上游 `--row`：竖排（圈在上、文字在下），连线横着穿过圈的中心。
    private var rowBody: some View {
        VStack(spacing: 0) {
            marker
            stepBody
                .padding(.top, contentSpacing)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { rowLine }
    }

    /// 上游 `--column`：横排（圈在左、文字在右），连线竖着落在 `left: 10px`。
    private var columnBody: some View {
        HStack(alignment: .top, spacing: 0) {
            marker
            stepBody
                .padding(.leading, UPConfig.stepsItem.columnContentMarginLeft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, UPConfig.stepsItem.columnPaddingBottom)
        .overlay(alignment: .topLeading) { columnLine }
    }

    /// 上游 `.__line--row { top: 10px; height: 1px }`，宽度是整项宽、左移半格。
    @ViewBuilder
    private var rowLine: some View {
        if resolvedParentData.direction != "column" {
            UPColor.parse(lineColor, theme: theme)
                .frame(height: UPConfig.stepsItem.lineThickness)
                .padding(.leading, UPConfig.stepsItem.lineOffset * 2)
                .offset(y: UPConfig.stepsItem.lineOffset)
                .opacity(resolvedParentData.childLength > 1 ? 1 : 0)
        }
    }

    /// 上游 `.__line--column { left: 10px; width: 1px }`，高度撑满整项。
    @ViewBuilder
    private var columnLine: some View {
        if resolvedParentData.direction == "column" {
            UPColor.parse(lineColor, theme: theme)
                .frame(width: UPConfig.stepsItem.lineThickness)
                .padding(.top, UPConfig.stepsItem.wrapperSize)
                .offset(x: UPConfig.stepsItem.lineOffset)
                .opacity(resolvedParentData.childLength > 1 ? 1 : 0)
        }
    }

    /// 连线颜色需要下一个兄弟的 `error`，index 由父级下发的登记表推断不到时按 0 处理。
    private var lineColor: String {
        UPSteps<EmptyView>.lineColor(index: index,
                                     current: resolvedParentData.current,
                                     childErrors: resolvedParentData.childErrors,
                                     activeColor: resolvedParentData.activeColor,
                                     inactiveColor: resolvedParentData.inactiveColor)
    }

    /// 上游 `.__wrapper`：dot / 图标 / 序号圈三选一，外面套一层白底圆。
    private var marker: some View {
        Group {
            if let iconSlot {
                iconSlot
            } else if resolvedParentData.dot {
                Circle()
                    .fill(UPColor.parse(statusColor(index: index), theme: theme))
                    .frame(width: UPConfig.stepsItem.dotSize, height: UPConfig.stepsItem.dotSize)
            } else if !resolvedParentData.activeIcon.isEmpty || !resolvedParentData.inactiveIcon.isEmpty {
                UPIcon(name: index <= resolvedParentData.current
                       ? resolvedParentData.activeIcon
                       : resolvedParentData.inactiveIcon,
                       color: index <= resolvedParentData.current
                       ? resolvedParentData.activeColor
                       : resolvedParentData.inactiveColor,
                       size: iconSize)
            } else {
                circleMarker
            }
        }
        .frame(width: UPConfig.stepsItem.wrapperSize, height: UPConfig.stepsItem.wrapperSize)
        .background(UPColor.parse(UPConfig.stepsItem.wrapperBackgroundColor, theme: theme))
        .clipShape(Circle())
        .upStyle(itemStyle)
    }

    /// 上游 `.__circle`：process/wait 显示序号，finish 显示对勾，error 显示叉。
    private var circleMarker: some View {
        let currentStatus = status(index: index)
        return ZStack {
            Circle()
                .fill(currentStatus == .process
                      ? UPColor.parse(resolvedParentData.activeColor, theme: theme)
                      : Color.clear)
                .overlay {
                    Circle().stroke(UPColor.parse(statusColor(index: index), theme: theme),
                                    lineWidth: UPConfig.stepsItem.circleBorderWidth)
                }

            if currentStatus == .process || currentStatus == .wait {
                Text("\(index + 1)")
                    .font(.system(size: UPConfig.stepsItem.circleTextFontSize))
                    .foregroundStyle(UPColor.parse(index == resolvedParentData.current
                                                   ? UPConfig.stepsItem.activeStepTextColor
                                                   : resolvedParentData.inactiveColor,
                                                   theme: theme))
            } else {
                UPIcon(name: currentStatus == .error ? "close" : "checkmark",
                       color: currentStatus == .error ? "error" : resolvedParentData.activeColor,
                       size: UPConfig.stepsItem.statusIconSize)
            }
        }
        .frame(width: UPConfig.stepsItem.circleSize, height: UPConfig.stepsItem.circleSize)
    }

    /// 上游 `.__content`：`content` 插槽优先，否则标题 + 描述。
    @ViewBuilder
    private var stepBody: some View {
        if let contentSlot {
            contentSlot(index)
        } else {
            VStack(alignment: resolvedParentData.direction == "column" ? .leading : .center, spacing: 0) {
                titleView
                descView
                content
            }
            .contentShape(Rectangle())
            .onTapGesture { triggerClick() }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if let titleSlot {
            titleSlot
        } else if !title.isEmpty {
            let isCurrent = index == resolvedParentData.current
            UPText(type: isCurrent ? "main" : "content",
                   text: title,
                   size: isCurrent
                   ? UPConfig.stepsItem.activeTitleFontSize
                   : UPConfig.stepsItem.inactiveTitleFontSize,
                   lineHeight: UPConfig.stepsItem.titleLineHeight)
        }
    }

    @ViewBuilder
    private var descView: some View {
        if let descSlot {
            descSlot
        } else if !desc.isEmpty {
            UPText(type: "tips", text: desc, size: UPConfig.stepsItem.descFontSize)
        }
    }
}

public extension UPStepsItem where Content == EmptyView {
    init(title: String = UPConfig.stepsItem.title,
         desc: String = UPConfig.stepsItem.desc,
         iconSize: some UPImageUnitValue = UPConfig.stepsItem.iconSize,
         error: Bool = UPConfig.stepsItem.error,
         itemStyle: UPStyle = UPStyle()) {
        self.init(title: title,
                  desc: desc,
                  iconSize: iconSize,
                  error: error,
                  itemStyle: itemStyle,
                  content: EmptyView.init)
    }
}
