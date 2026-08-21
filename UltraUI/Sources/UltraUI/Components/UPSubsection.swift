import SwiftUI

public struct UPSubsectionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var activeColorKey: String?
    public var inactiveColorKey: String?

    public init(id: String? = nil, name: String, activeColorKey: String? = nil, inactiveColorKey: String? = nil) {
        self.id = id ?? name
        self.name = name
        self.activeColorKey = activeColorKey
        self.inactiveColorKey = inactiveColorKey
    }
}

/// Native segmented control corresponding to uview-plus `u-subsection`.
@MainActor
public struct UPSubsection: View {
    public var list: [UPSubsectionItem]
    public var current: Int
    public var activeColor: String
    public var inactiveColor: String
    public var mode: String
    public var fontSize: CGFloat
    public var bold: Bool
    public var bgColor: String
    public var keyName: String
    public var activeColorKeyName: String
    public var inactiveColorKeyName: String
    public var disabled: Bool
    public var customStyle: UPStyle

    private var currentBinding: Binding<Int>?
    private var onChangeHandler: ((Int) -> Void)?

    public init(
        list: [String] = [], current: Binding<Int>? = nil,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list.map { UPSubsectionItem(name: $0) }, current: current,
                  activeColor: activeColor, inactiveColor: inactiveColor, mode: mode,
                  fontSize: fontSize, bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
    }

    public init(
        list: [UPSubsectionItem], current: Binding<Int>? = nil,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list, current: current, activeColor: activeColor,
                  inactiveColor: inactiveColor, mode: mode, fontSize: fontSize,
                  bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
    }

    public init(
        list: [String] = [], current: Int,
        activeColor: String = "#3c9cff", inactiveColor: String = "#303133",
        mode: String = "button", fontSize: CGFloat = 12, bold: Bool = true,
        bgColor: String = "#eeeeef", keyName: String = "name",
        activeColorKeyName: String = "activeColorKey",
        inactiveColorKeyName: String = "inactiveColorKey", disabled: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(items: list.map { UPSubsectionItem(name: $0) }, current: nil,
                  activeColor: activeColor, inactiveColor: inactiveColor, mode: mode,
                  fontSize: fontSize, bold: bold, bgColor: bgColor, keyName: keyName,
                  activeColorKeyName: activeColorKeyName,
                  inactiveColorKeyName: inactiveColorKeyName, disabled: disabled,
                  customStyle: customStyle)
        self.current = current
    }

    private init(
        items: [UPSubsectionItem], current: Binding<Int>?, activeColor: String,
        inactiveColor: String, mode: String, fontSize: CGFloat, bold: Bool,
        bgColor: String, keyName: String, activeColorKeyName: String,
        inactiveColorKeyName: String, disabled: Bool, customStyle: UPStyle
    ) {
        self.list = items
        self.current = current?.wrappedValue ?? 0
        self.currentBinding = current
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.mode = mode
        self.fontSize = fontSize
        self.bold = bold
        self.bgColor = bgColor
        self.keyName = keyName
        self.activeColorKeyName = activeColorKeyName
        self.inactiveColorKeyName = inactiveColorKeyName
        self.disabled = disabled
        self.customStyle = customStyle
    }

    public var body: some View {
        HStack(spacing: mode == "subsection" ? 0 : 4) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                Button { select(index) } label: {
                    Text(item.name)
                        .font(.system(size: fontSize, weight: bold ? .bold : .regular))
                        .foregroundColor(UPColor.parse(color(for: item, selected: index == selectedIndex)))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(index == selectedIndex ? UPColor.parse(activeColor).opacity(0.12) : Color.clear)
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
        }
        .padding(mode == "button" ? 3 : 0)
        .background(UPColor.parse(bgColor))
        .clipShape(RoundedRectangle(cornerRadius: mode == "button" ? 5 : 0))
        .upStyle(customStyle)
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func select(_ index: Int) {
        guard !disabled, list.indices.contains(index), index != selectedIndex else { return }
        currentBinding?.wrappedValue = index
        onChangeHandler?(index)
    }

    private var selectedIndex: Int {
        let raw = currentBinding?.wrappedValue ?? current
        guard !list.isEmpty else { return 0 }
        return Swift.min(Swift.max(raw, 0), list.count - 1)
    }

    private func color(for item: UPSubsectionItem, selected: Bool) -> String {
        if selected { return item.activeColorKey ?? activeColor }
        return item.inactiveColorKey ?? inactiveColor
    }
}
