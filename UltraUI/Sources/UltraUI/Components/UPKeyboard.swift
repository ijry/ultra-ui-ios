import SwiftUI

@MainActor
public struct UPKeyboard: View {
    public var show: Bool
    public var mode: String
    public var zIndex: CGFloat
    public var overlay: Bool
    public var closeOnClickOverlay: Bool
    public var safeAreaInsetBottom: Bool
    public var disabled: Bool
    public var keys: [UPKeyboardKey]
    private var onInputHandler: ((String) -> Void)?
    private var onDeleteHandler: (() -> Void)?
    private var onConfirmHandler: (() -> Void)?
    private var onCancelHandler: (() -> Void)?

    public init(show: Bool = false, mode: String = "number", zIndex: some UPImageUnitValue = 10075,
                overlay: Bool = true, closeOnClickOverlay: Bool = true, safeAreaInsetBottom: Bool = true,
                disabled: Bool = false, keys: [UPKeyboardKey] = []) {
        self.show = show; self.mode = mode; self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.overlay = overlay; self.closeOnClickOverlay = closeOnClickOverlay
        self.safeAreaInsetBottom = safeAreaInsetBottom; self.disabled = disabled; self.keys = keys
    }

    public var body: some View {
        if show {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(keys) { key in Button(key.label) { press(key) }.disabled(disabled || key.disabled) }
            }
        }
    }
    public func press(_ key: UPKeyboardKey) { guard !disabled, !key.disabled else { return }; switch key.kind { case .input: onInputHandler?(key.value); case .delete: onDeleteHandler?(); case .confirm: onConfirmHandler?(); case .cancel: onCancelHandler?(); case .spacer: break } }
    public func cancel() { guard !disabled else { return }; onCancelHandler?() }
    public func onInput(_ action: @escaping (String) -> Void) -> Self { var c = self; c.onInputHandler = action; return c }
    public func onDelete(_ action: @escaping () -> Void) -> Self { var c = self; c.onDeleteHandler = action; return c }
    public func onConfirm(_ action: @escaping () -> Void) -> Self { var c = self; c.onConfirmHandler = action; return c }
    public func onCancel(_ action: @escaping () -> Void) -> Self { var c = self; c.onCancelHandler = action; return c }
}
