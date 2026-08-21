import SwiftUI

public struct UPSwiperItem: Identifiable, Equatable, Sendable {
    public let id: String; public let source: String; public let title: String
    public init(id: String? = nil, source: String, title: String = "") { self.id = id ?? source; self.source = source; self.title = title }
}

public enum UPSwiperChangeSource: String, Equatable, Sendable {
    case user
    case programmatic
    case autoplay
}

public struct UPSwiperChange: Equatable, Sendable {
    public var index: Int
    public var item: UPSwiperItem
    public var source: UPSwiperChangeSource

    public init(index: Int, item: UPSwiperItem, source: UPSwiperChangeSource) {
        self.index = index
        self.item = item
        self.source = source
    }
}

@MainActor
public struct UPSwiper: View {
    public var items: [UPSwiperItem]; public var indicator: Bool; public var indicatorActiveColor: String; public var indicatorInactiveColor: String
    public var indicatorStyle: UPStyle; public var indicatorMode: String; public var autoplay: Bool; public var current: Int
    public var currentItemId: String
    public var interval: Int; public var duration: Int; public var circular: Bool; public var vertical: Bool
    public var previousMargin: String; public var nextMargin: String; public var acceleration: Bool; public var displayMultipleItems: Int
    public var easingFunction: String; public var keyName: String; public var imgMode: String; public var height: CGFloat; public var bgColor: String; public var radius: CGFloat; public var loading: Bool; public var showTitle: Bool
    private var currentBinding: Binding<Int>?; private var onChangeHandler: ((Int) -> Void)?; private var onChangePayloadHandler: ((UPSwiperChange) -> Void)?; private var onClickHandler: ((Int) -> Void)?
    public init(list: [String] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Int = 0, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false) {
        self.init(list: list.map { UPSwiperItem(source: $0) }, indicator: indicator, indicatorActiveColor: indicatorActiveColor, indicatorInactiveColor: indicatorInactiveColor, indicatorStyle: indicatorStyle, indicatorMode: indicatorMode, autoplay: autoplay, current: current, currentItemId: currentItemId, interval: interval, duration: duration, circular: circular, vertical: vertical, previousMargin: previousMargin, nextMargin: nextMargin, acceleration: acceleration, displayMultipleItems: displayMultipleItems, easingFunction: easingFunction, keyName: keyName, imgMode: imgMode, height: height, bgColor: bgColor, radius: radius, loading: loading, showTitle: showTitle)
    }

    public init(list: [UPSwiperItem] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Binding<Int>, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false) {
        self.init(list: list, indicator: indicator, indicatorActiveColor: indicatorActiveColor, indicatorInactiveColor: indicatorInactiveColor, indicatorStyle: indicatorStyle, indicatorMode: indicatorMode, autoplay: autoplay, current: current.wrappedValue, currentItemId: currentItemId, interval: interval, duration: duration, circular: circular, vertical: vertical, previousMargin: previousMargin, nextMargin: nextMargin, acceleration: acceleration, displayMultipleItems: displayMultipleItems, easingFunction: easingFunction, keyName: keyName, imgMode: imgMode, height: height, bgColor: bgColor, radius: radius, loading: loading, showTitle: showTitle, current: current)
    }
    public init(list: [UPSwiperItem] = [], indicator: Bool = false, indicatorActiveColor: String = "#FFFFFF", indicatorInactiveColor: String = "rgba(255, 255, 255, 0.35)", indicatorStyle: UPStyle = UPStyle(), indicatorMode: String = "line", autoplay: Bool = true, current: Int = 0, currentItemId: String = "", interval: Int = 3000, duration: Int = 300, circular: Bool = false, vertical: Bool = false, previousMargin: some UPImageUnitValue = "0", nextMargin: some UPImageUnitValue = "0", acceleration: Bool = false, displayMultipleItems: Int = 1, easingFunction: String = "default", keyName: String = "url", imgMode: String = "aspectFill", height: some UPImageUnitValue = "130", bgColor: String = "#f3f4f6", radius: some UPImageUnitValue = "4", loading: Bool = false, showTitle: Bool = false, current binding: Binding<Int>? = nil) {
        self.items = list; self.indicator = indicator; self.indicatorActiveColor = indicatorActiveColor; self.indicatorInactiveColor = indicatorInactiveColor; self.indicatorStyle = indicatorStyle; self.indicatorMode = indicatorMode; self.autoplay = autoplay; self.current = binding?.wrappedValue ?? current; self.currentBinding = binding; self.currentItemId = currentItemId; self.interval = interval; self.duration = duration; self.circular = circular; self.vertical = vertical; self.previousMargin = previousMargin.upImageUnitValue; self.nextMargin = nextMargin.upImageUnitValue; self.acceleration = acceleration; self.displayMultipleItems = max(1, displayMultipleItems); self.easingFunction = easingFunction; self.keyName = keyName; self.imgMode = imgMode; self.height = UPUnit.parse(height.upImageUnitValue); self.bgColor = bgColor; self.radius = UPUnit.parse(radius.upImageUnitValue); self.loading = loading; self.showTitle = showTitle
    }
    public var body: some View { TabView(selection: selectionBinding) { ForEach(Array(items.enumerated()), id: \.element.id) { index, item in Text(item.title.isEmpty ? item.source : item.title).tag(index) } }.frame(height: height).background(UPColor.parse(bgColor)).clipShape(RoundedRectangle(cornerRadius: radius)) }
    public var selectedIndex: Int {
        if !currentItemId.isEmpty, let index = items.firstIndex(where: { $0.id == currentItemId }) { return index }
        let raw = currentBinding?.wrappedValue ?? current
        return items.isEmpty ? 0 : min(max(raw, 0), items.count - 1)
    }
    public var selectionBinding: Binding<Int> { Binding(get: { selectedIndex }, set: { select($0, source: .user) }) }
    public func select(_ index: Int) { select(index, source: .programmatic) }
    public func select(_ index: Int, source: UPSwiperChangeSource) {
        guard items.indices.contains(index), index != selectedIndex else { return }
        currentBinding?.wrappedValue = index
        onChangeHandler?(index)
        onChangePayloadHandler?(UPSwiperChange(index: index, item: items[index], source: source))
    }
    public func nextIndex(from index: Int) -> Int { guard !items.isEmpty else { return 0 }; if index + 1 < items.count { return index + 1 }; return circular ? 0 : index }
    public func previousIndex(from index: Int) -> Int { guard !items.isEmpty else { return 0 }; if index > 0 && index < items.count { return index - 1 }; return circular ? items.count - 1 : max(0, min(index, items.count - 1)) }
    public func onChange(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onChangePayload(_ action: @escaping (UPSwiperChange) -> Void) -> Self { var copy = self; copy.onChangePayloadHandler = action; return copy }
    public func onClick(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func triggerClick(_ index: Int) { guard items.indices.contains(index) else { return }; onClickHandler?(index) }
}

@MainActor
public struct UPSwiperIndicator: View {
    public var length: String; public var current: String; public var indicatorActiveColor: String; public var indicatorInactiveColor: String; public var indicatorMode: String
    public init(length: some UPImageUnitValue = "0", current: some UPImageUnitValue = "0", indicatorActiveColor: String = "", indicatorInactiveColor: String = "", indicatorMode: String = "line") { self.length = length.upImageUnitValue; self.current = current.upImageUnitValue; self.indicatorActiveColor = indicatorActiveColor; self.indicatorInactiveColor = indicatorInactiveColor; self.indicatorMode = indicatorMode }
    public var resolvedLength: Int { max(0, Int(UPUnit.parse(length))) }
    public var resolvedCurrent: Int { resolvedLength == 0 ? 0 : min(max(Int(UPUnit.parse(current)), 0), resolvedLength - 1) }
    public var lineOffset: CGFloat { CGFloat(resolvedCurrent * 22) }
    public var body: some View { HStack(spacing: 4) { ForEach(0..<resolvedLength, id: \.self) { index in Capsule().fill(UPColor.parse(index == resolvedCurrent ? indicatorActiveColor : indicatorInactiveColor)).frame(width: indicatorMode == "line" && index == resolvedCurrent ? 22 : 5, height: 5) } } }
}
