import SwiftUI

public struct UPDropdownOption: Identifiable, Equatable, Sendable { public var value: String; public var title: String; public var id: String { value }; public init(value: String, title: String) { self.value = value; self.title = title } }
@MainActor public struct UPDropdownItem: View, Identifiable {
    public let id: String; public var title: String; public var options: [UPDropdownOption]; public var disabled: Bool; public var height: String; public var closeOnClickOverlay: Bool
    private var modelValue: Binding<String>?; private var onChangeHandler: ((String) -> Void)?
    public init(title: String = "", options: [UPDropdownOption] = [], modelValue: Binding<String>? = nil, disabled: Bool = false, height: String = "auto", closeOnClickOverlay: Bool = true) { self.id = title; self.title = title; self.options = options; self.modelValue = modelValue; self.disabled = disabled; self.height = height; self.closeOnClickOverlay = closeOnClickOverlay }
    public var body: some View { Menu(title) { ForEach(options) { option in Button(option.title) { select(option.value) } } }.disabled(disabled) }
    public func select(_ value: String) { guard !disabled, options.contains(where: { $0.value == value }) else { return }; modelValue?.wrappedValue = value; onChangeHandler?(value) }; public func onChange(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onChangeHandler = a; return c }
}
@MainActor private final class UPDropdownState { var current: Int? }
@MainActor public struct UPDropdown: View {
    public var items: [UPDropdownItem]; public var activeColor: String; public var inactiveColor: String; public var closeOnClickMask: Bool; public var closeOnClickSelf: Bool; public var duration: Int; public var height: CGFloat; public var borderBottom: Bool; public var titleSize: CGFloat; public var borderRadius: CGFloat; public var menuIcon: String; public var menuIconSize: CGFloat
    private let state = UPDropdownState(); private var onOpenHandler: ((Int) -> Void)?; private var onCloseHandler: ((Int) -> Void)?
    public init(items: [UPDropdownItem] = [], activeColor: String = "#2979ff", inactiveColor: String = "#606266", closeOnClickMask: Bool = true, closeOnClickSelf: Bool = true, duration: Int = 300, height: some UPImageUnitValue = 40, borderBottom: Bool = false, titleSize: some UPImageUnitValue = 14, borderRadius: some UPImageUnitValue = 0, menuIcon: String = "arrow-down", menuIconSize: some UPImageUnitValue = 14) { self.items = items; self.activeColor = activeColor; self.inactiveColor = inactiveColor; self.closeOnClickMask = closeOnClickMask; self.closeOnClickSelf = closeOnClickSelf; self.duration = duration; self.height = UPUnit.parse(height.upImageUnitValue); self.borderBottom = borderBottom; self.titleSize = UPUnit.parse(titleSize.upImageUnitValue); self.borderRadius = UPUnit.parse(borderRadius.upImageUnitValue); self.menuIcon = menuIcon; self.menuIconSize = UPUnit.parse(menuIconSize.upImageUnitValue) }
    public var body: some View { HStack { ForEach(Array(items.enumerated()), id: \.element.id) { index, item in Button(item.title) { open(index) }.disabled(item.disabled) } }.frame(height: height) }
    public func open(_ index: Int) { guard items.indices.contains(index), !items[index].disabled else { return }; if state.current == index, closeOnClickSelf { close(); return }; state.current = index; onOpenHandler?(index) }; public func close() { guard let index = state.current else { return }; state.current = nil; onCloseHandler?(index) }
    public func onOpen(_ a: @escaping (Int) -> Void) -> Self { var c = self; c.onOpenHandler = a; return c }; public func onClose(_ a: @escaping (Int) -> Void) -> Self { var c = self; c.onCloseHandler = a; return c }
}
