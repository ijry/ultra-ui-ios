import SwiftUI

public struct UPColorPicker: View {
    @Binding public var color: String
    public var showAlpha: Bool
    private var onChangeHandler: ((String) -> Void)?

    public init(color: Binding<String>, showAlpha: Bool = false,
                onChange: ((String) -> Void)? = nil) {
        _color = color
        self.showAlpha = showAlpha
        self.onChangeHandler = onChange
    }

    public func onChange(_ action: @escaping (String) -> Void) -> UPColorPicker {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func select(_ value: String) {
        color = value
        onChangeHandler?(value)
    }

    public var body: some View {
        ColorPicker("", selection: Binding(
            get: { UPColor.parse(color) },
            set: { _ in }
        ), supportsOpacity: showAlpha)
        .labelsHidden()
    }
}
