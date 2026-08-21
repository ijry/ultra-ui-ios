import SwiftUI

/// Native counterpart of uview-plus `u-toolbar`.
@MainActor
public struct UPToolbar<RightContent: View>: View {
    public var show: Bool
    public var cancelText: String
    public var confirmText: String
    public var cancelColor: String
    public var confirmColor: String
    public var title: String
    public var rightSlot: Bool

    private let right: RightContent
    private var onConfirmHandler: (() -> Void)?
    private var onCancelHandler: (() -> Void)?

    public init(
        show: Bool = true, cancelText: String = "取消", confirmText: String = "确认",
        cancelColor: String = "#909193", confirmColor: String = "", title: String = "",
        rightSlot: Bool = false, @ViewBuilder right: () -> RightContent
    ) {
        self.show = show
        self.cancelText = cancelText
        self.confirmText = confirmText
        self.cancelColor = cancelColor
        self.confirmColor = confirmColor
        self.title = title
        self.rightSlot = rightSlot
        self.right = right()
    }

    public var body: some View {
        if show {
            HStack {
                Button(cancelText, action: triggerCancel)
                    .foregroundColor(UPColor.parse(cancelColor))
                Spacer()
                Text(title).fontWeight(.medium)
                Spacer()
                Button(action: triggerConfirm) {
                    if rightSlot { right } else { Text(confirmText) }
                }
                .foregroundColor(UPColor.parse(confirmColor.isEmpty ? "#3c9cff" : confirmColor))
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
        }
    }

    public func onConfirm(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCancelHandler = action
        return copy
    }

    public func triggerConfirm() { onConfirmHandler?() }
    public func triggerCancel() { onCancelHandler?() }
}

public extension UPToolbar where RightContent == EmptyView {
    init(
        show: Bool = true, cancelText: String = "取消", confirmText: String = "确认",
        cancelColor: String = "#909193", confirmColor: String = "", title: String = "",
        rightSlot: Bool = false
    ) {
        self.init(show: show, cancelText: cancelText, confirmText: confirmText,
                  cancelColor: cancelColor, confirmColor: confirmColor, title: title,
                  rightSlot: rightSlot, right: EmptyView.init)
    }
}
