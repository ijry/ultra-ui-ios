import SwiftUI

/// String-or-number values accepted by uview-plus `u-collapse` names.
public typealias UPCollapseName = UPCellName
public typealias UPCollapseNameValue = UPCellNameValue

/// The three value shapes accepted by uview-plus `u-collapse`.
public enum UPCollapseValue: Equatable, Sendable {
    case none
    case single(UPCollapseName)
    case multiple([UPCollapseName])

    public init(_ value: UPCollapseName) {
        self = .single(value)
    }

    public init(_ value: [UPCollapseName]) {
        self = .multiple(value)
    }

    public var names: [UPCollapseName] {
        switch self {
        case .none: return []
        case .single(let name): return [name]
        case .multiple(let names): return names
        }
    }
}

/// Native status reported by the upstream collapse `change` event.
public enum UPCollapseStatus: String, Equatable, Sendable {
    case open
    case close
}

/// One item in the upstream collapse `change` event payload.
public struct UPCollapseChange: Equatable, Sendable {
    public let name: UPCollapseName
    public let status: UPCollapseStatus

    public init(name: UPCollapseName, status: UPCollapseStatus) {
        self.name = name
        self.status = status
    }
}

/// Native alignment equivalent of uview-plus collapse-item's `align` prop.
public enum UPCollapseAlignment: String, Equatable, Sendable {
    case leading
    case center
    case trailing

    var swiftUIAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

/// Pure state rules shared by the SwiftUI view and native adapters.
public enum UPCollapseState {
    /// Normalizes uview-plus's scalar/array value according to accordion mode.
    /// Invalid upstream shape combinations are handled gracefully on Apple
    /// platforms by retaining the first scalar/array name.
    public static func normalizedNames(
        value: UPCollapseValue,
        accordion: Bool
    ) -> [UPCollapseName] {
        let names: [UPCollapseName]
        switch value {
        case .none:
            names = []
        case .single(let name):
            names = [name]
        case .multiple(let values):
            names = values
        }

        let unique = uniqueNames(names)
        return accordion ? Array(unique.prefix(1)) : unique
    }

    /// Computes the state after a collapse item is tapped.
    public static func nextNames(
        current: [UPCollapseName],
        target: UPCollapseName,
        accordion: Bool,
        disabled: Bool = false
    ) -> [UPCollapseName] {
        guard !disabled else { return current }

        let current = uniqueNames(current)
        if accordion {
            return current.contains(target) ? [] : [target]
        }

        if current.contains(target) {
            return current.filter { $0 != target }
        }
        return current + [target]
    }

    /// Builds the exact per-item status array emitted by uview-plus.
    public static func changePayload(
        activeNames: [UPCollapseName],
        itemNames: [UPCollapseName]
    ) -> [UPCollapseChange] {
        return itemNames.map { name in
            UPCollapseChange(name: name, status: activeNames.contains(name) ? .open : .close)
        }
    }

    private static func uniqueNames(_ names: [UPCollapseName]) -> [UPCollapseName] {
        var result: [UPCollapseName] = []
        result.reserveCapacity(names.count)
        for name in names where !result.contains(name) {
            result.append(name)
        }
        return result
    }
}

private struct UPCollapseItemRegistration: Equatable, Sendable {
    let id: UUID
    let explicitName: UPCollapseName?
}

private struct UPCollapseRegistrationKey: PreferenceKey {
    static let defaultValue: [UPCollapseItemRegistration] = []

    static func reduce(
        value: inout [UPCollapseItemRegistration],
        nextValue: () -> [UPCollapseItemRegistration]
    ) {
        value.append(contentsOf: nextValue())
    }
}

/// Environment context shared by nested collapse items.
private struct UPCollapseContext: @unchecked Sendable {
    let isExpanded: (UPCollapseName) -> Bool
    let resolvedName: (UUID, UPCollapseName?) -> UPCollapseName
    let allNames: () -> [UPCollapseName]
    let toggle: (UPCollapseName, Bool) -> Void
}

private struct UPCollapseContextKey: EnvironmentKey {
    static let defaultValue: UPCollapseContext? = nil
}

private extension EnvironmentValues {
    var upCollapseContext: UPCollapseContext? {
        get { self[UPCollapseContextKey.self] }
        set { self[UPCollapseContextKey.self] = newValue }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-collapse`.
@MainActor
public struct UPCollapse<Content: View>: View {
    public let value: UPCollapseValue
    public let accordion: Bool
    public let border: Bool

    private let modelValue: Binding<UPCollapseValue>?
    private let onChangeHandler: (([UPCollapseChange]) -> Void)?
    private let onOpenHandler: ((UPCollapseName) -> Void)?
    private let onCloseHandler: ((UPCollapseName) -> Void)?
    private let content: Content
    @State private var localValue: UPCollapseValue
    @State private var registrations: [UPCollapseItemRegistration] = []
    @Environment(\.upTheme) private var theme

    public init(
        value: UPCollapseValue = UPConfig.collapse.value,
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.value = value
        self.accordion = accordion
        self.border = border
        self.modelValue = modelValue
        self.onChangeHandler = onChange
        self.onOpenHandler = onOpen
        self.onCloseHandler = onClose
        self.content = content()
        self._localValue = State(initialValue: modelValue?.wrappedValue ?? value)
    }

    /// Scalar `value` overload matching accordion-mode uview-plus usage.
    public init<Name: UPCollapseNameValue>(
        value: Name,
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            value: .single(value.upCellNameValue),
            accordion: accordion,
            border: border,
            modelValue: modelValue,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose,
            content: content
        )
    }

    /// Array `value` overload matching non-accordion uview-plus usage.
    public init<Name: UPCollapseNameValue>(
        value: [Name],
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            value: .multiple(value.map(\.upCellNameValue)),
            accordion: accordion,
            border: border,
            modelValue: modelValue,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose,
            content: content
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            if border {
                Divider().overlay(theme.border)
            }
            content
        }
        .environment(\.upCollapseContext, makeContext())
        .onPreferenceChange(UPCollapseRegistrationKey.self) { newRegistrations in
            if registrations != newRegistrations {
                registrations = newRegistrations
            }
        }
        .onChange(of: value) { _, newValue in
            guard modelValue == nil else { return }
            localValue = newValue
        }
    }

    /// The currently selected names after applying accordion normalization.
    var currentNames: [UPCollapseName] {
        UPCollapseState.normalizedNames(value: selectionBinding.wrappedValue, accordion: accordion)
    }

    /// Testable/native counterpart of a child header tap.
    func triggerChange(name: UPCollapseName, disabled: Bool = false) {
        makeContext().toggle(name, disabled)
    }

    private var selectionBinding: Binding<UPCollapseValue> {
        modelValue ?? $localValue
    }

    private func makeContext() -> UPCollapseContext {
        let selection = selectionBinding
        let accordion = self.accordion
        let currentRegistrations = registrations
        let onChange = onChangeHandler
        let onOpen = onOpenHandler
        let onClose = onCloseHandler

        return UPCollapseContext(
            isExpanded: { name in
                UPCollapseState.normalizedNames(
                    value: selection.wrappedValue,
                    accordion: accordion
                ).contains(name)
            },
            resolvedName: { id, explicitName in
                if let explicitName {
                    return explicitName
                }
                if let index = currentRegistrations.firstIndex(where: { $0.id == id }) {
                    return .number(Double(index))
                }
                return .number(0)
            },
            allNames: {
                currentRegistrations.enumerated().map { index, registration in
                    registration.explicitName ?? .number(Double(index))
                }
            },
            toggle: { name, disabled in
                guard !disabled else { return }

                let current = UPCollapseState.normalizedNames(
                    value: selection.wrappedValue,
                    accordion: accordion
                )
                let next = UPCollapseState.nextNames(
                    current: current,
                    target: name,
                    accordion: accordion
                )
                guard current != next else { return }

                selection.wrappedValue = accordion
                    ? (next.first.map(UPCollapseValue.single) ?? .none)
                    : .multiple(next)

                let itemNames = currentRegistrations.enumerated().map { index, registration in
                    registration.explicitName ?? .number(Double(index))
                }
                let payloadNames = itemNames.isEmpty ? [name] : itemNames
                onChange?(UPCollapseState.changePayload(
                    activeNames: next,
                    itemNames: payloadNames
                ))
                if next.contains(name) {
                    onOpen?(name)
                } else {
                    onClose?(name)
                }
            }
        )
    }
}

public extension UPCollapse where Content == EmptyView {
    init(
        value: UPCollapseValue = UPConfig.collapse.value,
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil
    ) {
        self.init(
            value: value,
            accordion: accordion,
            border: border,
            modelValue: modelValue,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose
        ) {
            EmptyView()
        }
    }

    init<Name: UPCollapseNameValue>(
        value: Name,
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil
    ) {
        self.init(
            value: value,
            accordion: accordion,
            border: border,
            modelValue: modelValue,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose
        ) {
            EmptyView()
        }
    }

    init<Name: UPCollapseNameValue>(
        value: [Name],
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        modelValue: Binding<UPCollapseValue>? = nil,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil
    ) {
        self.init(
            value: value,
            accordion: accordion,
            border: border,
            modelValue: modelValue,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose
        ) {
            EmptyView()
        }
    }

    init(
        modelValue: Binding<[UPCollapseName]>,
        accordion: Bool = UPConfig.collapse.accordion,
        border: Bool = UPConfig.collapse.border,
        onChange: (([UPCollapseChange]) -> Void)? = nil,
        onOpen: ((UPCollapseName) -> Void)? = nil,
        onClose: ((UPCollapseName) -> Void)? = nil
    ) {
        let erased = Binding<UPCollapseValue>(
            get: { .multiple(modelValue.wrappedValue) },
            set: { newValue in
                modelValue.wrappedValue = newValue.names
            }
        )
        self.init(
            value: erased.wrappedValue,
            accordion: accordion,
            border: border,
            modelValue: erased,
            onChange: onChange,
            onOpen: onOpen,
            onClose: onClose
        ) {
            EmptyView()
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-collapse-item`.
@MainActor
public struct UPCollapseItem<Content: View>: View {
    public let title: String
    public let value: String
    public let label: String
    public let disabled: Bool
    public let isLink: Bool
    public let clickable: Bool
    public let border: Bool
    public let align: String
    private let rawName: UPCollapseName
    public let icon: String
    public let duration: Int
    public let showRight: Bool
    public let titleStyle: UPStyle
    public let iconStyle: UPStyle
    public let rightIconStyle: UPStyle
    public let cellCustomStyle: UPStyle
    public let cellCustomClass: String

    private let identity: UUID
    private let content: Content
    private var titleContent: AnyView?
    private var iconContent: AnyView?
    private var valueContent: AnyView?
    private var rightIconContent: AnyView?
    private let contentSlotEnabled: Bool
    private var hasTitleContent: Bool
    private var hasIconContent: Bool
    private var hasValueContent: Bool
    private var hasRightIconContent: Bool
    @Environment(\.upCollapseContext) private var context
    @Environment(\.upTheme) private var theme

    public init<Title: UPCellTextValue, Value: UPCellTextValue, Label: UPCellTextValue, Name: UPCellNameValue>(
        title: Title = UPConfig.collapseItem.title,
        value: Value = UPConfig.collapseItem.value,
        label: Label = UPConfig.collapseItem.label,
        disabled: Bool = UPConfig.collapseItem.disabled,
        isLink: Bool = UPConfig.collapseItem.isLink,
        clickable: Bool = UPConfig.collapseItem.clickable,
        border: Bool = UPConfig.collapseItem.border,
        align: String = UPConfig.collapseItem.align,
        name: Name = UPConfig.collapseItem.name,
        icon: String = UPConfig.collapseItem.icon,
        duration: Int = UPConfig.collapseItem.duration,
        showRight: Bool = UPConfig.collapseItem.showRight,
        titleStyle: UPStyle = UPConfig.collapseItem.titleStyle,
        iconStyle: UPStyle = UPConfig.collapseItem.iconStyle,
        rightIconStyle: UPStyle = UPConfig.collapseItem.rightIconStyle,
        cellCustomClass: String = UPConfig.collapseItem.cellCustomClass,
        cellCustomStyle: UPStyle = UPConfig.collapseItem.cellCustomStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title.upCellTextValue,
            value: value.upCellTextValue,
            label: label.upCellTextValue,
            disabled: disabled,
            isLink: isLink,
            clickable: clickable,
            border: border,
            align: align,
            rawName: name.upCellNameValue,
            icon: icon,
            duration: duration,
            showRight: showRight,
            titleStyle: titleStyle,
            iconStyle: iconStyle,
            rightIconStyle: rightIconStyle,
            cellCustomStyle: cellCustomStyle,
            cellCustomClass: cellCustomClass,
            identity: UUID(),
            content: content(),
            hasContentSlot: true
        )
    }

    private init(
        title: String,
        value: String,
        label: String,
        disabled: Bool,
        isLink: Bool,
        clickable: Bool,
        border: Bool,
        align: String,
        rawName: UPCollapseName,
        icon: String,
        duration: Int,
        showRight: Bool,
        titleStyle: UPStyle,
        iconStyle: UPStyle,
        rightIconStyle: UPStyle,
        cellCustomStyle: UPStyle,
        cellCustomClass: String,
        identity: UUID,
        content: Content,
        hasContentSlot: Bool
    ) {
        self.title = title
        self.value = value
        self.label = label
        self.disabled = disabled
        self.isLink = isLink
        self.clickable = clickable
        self.border = border
        self.align = align
        self.rawName = rawName
        self.icon = icon
        self.duration = duration
        self.showRight = showRight
        self.titleStyle = titleStyle
        self.iconStyle = iconStyle
        self.rightIconStyle = rightIconStyle
        self.cellCustomStyle = cellCustomStyle
        self.cellCustomClass = cellCustomClass
        self.identity = identity
        self.content = content
        self.contentSlotEnabled = hasContentSlot
        self.titleContent = nil
        self.iconContent = nil
        self.valueContent = nil
        self.rightIconContent = nil
        self.hasTitleContent = false
        self.hasIconContent = false
        self.hasValueContent = false
        self.hasRightIconContent = false
    }

    public var name: UPCollapseName? {
        if case .string(let name) = rawName, name.isEmpty {
            return nil
        }
        return rawName
    }

    public var resolvedAlignment: UPCollapseAlignment {
        switch align.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "center": return .center
        case "right", "end", "trailing": return .trailing
        default: return .leading
        }
    }

    public var resolvedDuration: Double {
        Double(max(duration, 0)) / 1000
    }

    var hasContentSlot: Bool { contentSlotEnabled }
    var hasTitleSlot: Bool { hasTitleContent }
    var hasIconSlot: Bool { hasIconContent }
    var hasValueSlot: Bool { hasValueContent }
    var hasRightIconSlot: Bool { hasRightIconContent }

    public var body: some View {
        let resolvedName = context?.resolvedName(identity, name) ?? (name ?? .number(0))
        let expanded = context?.isExpanded(resolvedName) ?? false

        VStack(spacing: 0) {
            Button {
                context?.toggle(resolvedName, disabled)
            } label: {
                header(expanded: expanded)
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .opacity(disabled ? 0.55 : 1)

            contentArea(expanded: expanded)

            if (context != nil ? true : false) && border {
                Divider().overlay(theme.border)
            }
        }
        .background(Color.clear)
        .upStyle(cellCustomStyle)
        .preference(
            key: UPCollapseRegistrationKey.self,
            value: [UPCollapseItemRegistration(id: identity, explicitName: name)]
        )
    }

    func triggerTap() {
        let resolvedName = context?.resolvedName(identity, name) ?? (name ?? .number(0))
        context?.toggle(resolvedName, disabled)
    }

    @ViewBuilder
    private func header(expanded: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            if hasIconContent {
                iconContent?.upStyle(iconStyle)
                    .frame(width: 22, height: 22)
            } else if !icon.isEmpty {
                UPIcon(name: icon, size: "22")
                    .upStyle(iconStyle)
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: resolvedAlignment.swiftUIAlignment, spacing: label.isEmpty ? 0 : 4) {
                if hasTitleContent {
                    titleContent?.upStyle(titleStyle)
                } else if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.main)
                        .upStyle(titleStyle)
                }

                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.tips)
                }
            }
            .frame(maxWidth: .infinity, alignment: resolvedAlignment.frameAlignment)

            if hasValueContent {
                valueContent?.upStyle(titleStyle)
            } else if !value.isEmpty {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(theme.content)
            }

            if showRight && isLink {
                if hasRightIconContent {
                    rightIconContent?.upStyle(rightIconStyle)
                        .rotationEffect(.degrees(expanded ? -90 : 90))
                } else {
                    UPIcon(name: "arrow-right", size: "16")
                        .upStyle(rightIconStyle)
                        .rotationEffect(.degrees(expanded ? -90 : 90))
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func contentArea(expanded: Bool) -> some View {
        if contentSlotEnabled {
            ZStack(alignment: .topLeading) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(expanded ? 1 : 0)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, expanded ? 12 : 0)
            .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : 0, alignment: .top)
            .clipped()
            .animation(.easeInOut(duration: resolvedDuration), value: expanded)
        }
    }
}

public extension UPCollapseItem where Content == EmptyView {
    init<Title: UPCellTextValue, Value: UPCellTextValue, Label: UPCellTextValue, Name: UPCellNameValue>(
        title: Title = UPConfig.collapseItem.title,
        value: Value = UPConfig.collapseItem.value,
        label: Label = UPConfig.collapseItem.label,
        disabled: Bool = UPConfig.collapseItem.disabled,
        isLink: Bool = UPConfig.collapseItem.isLink,
        clickable: Bool = UPConfig.collapseItem.clickable,
        border: Bool = UPConfig.collapseItem.border,
        align: String = UPConfig.collapseItem.align,
        name: Name = UPConfig.collapseItem.name,
        icon: String = UPConfig.collapseItem.icon,
        duration: Int = UPConfig.collapseItem.duration,
        showRight: Bool = UPConfig.collapseItem.showRight,
        titleStyle: UPStyle = UPConfig.collapseItem.titleStyle,
        iconStyle: UPStyle = UPConfig.collapseItem.iconStyle,
        rightIconStyle: UPStyle = UPConfig.collapseItem.rightIconStyle,
        cellCustomClass: String = UPConfig.collapseItem.cellCustomClass,
        cellCustomStyle: UPStyle = UPConfig.collapseItem.cellCustomStyle
    ) {
        self.init(
            title: title.upCellTextValue,
            value: value.upCellTextValue,
            label: label.upCellTextValue,
            disabled: disabled,
            isLink: isLink,
            clickable: clickable,
            border: border,
            align: align,
            rawName: name.upCellNameValue,
            icon: icon,
            duration: duration,
            showRight: showRight,
            titleStyle: titleStyle,
            iconStyle: iconStyle,
            rightIconStyle: rightIconStyle,
            cellCustomStyle: cellCustomStyle,
            cellCustomClass: cellCustomClass,
            identity: UUID(),
            content: EmptyView(),
            hasContentSlot: false
        )
    }
}

public extension UPCollapseItem {
    /// Registers the `title` named slot.
    func title<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPCollapseItem {
        var copy = self
        copy.titleContent = AnyView(content())
        copy.hasTitleContent = true
        return copy
    }

    /// Registers the `icon` named slot.
    func icon<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPCollapseItem {
        var copy = self
        copy.iconContent = AnyView(content())
        copy.hasIconContent = true
        return copy
    }

    /// Registers the `value` named slot.
    func value<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPCollapseItem {
        var copy = self
        copy.valueContent = AnyView(content())
        copy.hasValueContent = true
        return copy
    }

    /// Registers the `right-icon` named slot.
    func rightIcon<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPCollapseItem {
        var copy = self
        copy.rightIconContent = AnyView(content())
        copy.hasRightIconContent = true
        return copy
    }

    /// Legacy spelling accepted by existing UltraUI named-slot APIs.
    func righticon<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPCollapseItem {
        rightIcon(content)
    }
}
