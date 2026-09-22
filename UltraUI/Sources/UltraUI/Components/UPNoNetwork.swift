import Observation
import SwiftUI

public enum UPNetworkStatus: Equatable, Sendable {
    case unknown
    case offline
    case wifi
    case cellular
    case wired
}

/// SwiftUI requires views to be value types, so the mutable network status lives
/// in a small reference box rather than making the view itself a class.
@MainActor
@Observable
private final class UPNoNetworkState {
    var status: UPNetworkStatus

    init(status: UPNetworkStatus) {
        self.status = status
    }
}

@MainActor
public struct UPNoNetwork: View {
    public var status: UPNetworkStatus { state.status }
    /// 断网提示语，上游 `tips` 默认取 `up.noNetwork.text`。
    public var tips: String
    /// 无网络时的图片提示，可用的 src 地址或 base64 图片。
    public var image: String
    /// 上游 `zIndex` 为 `String | Number`，空串表示交由 `u-overlay` 决定层级。
    public var zIndex: String

    @State private var state: UPNoNetworkState
    private var onChangeHandler: ((UPNetworkStatus) -> Void)?
    private var onConnectedHandler: (() -> Void)?
    private var onDisconnectedHandler: (() -> Void)?
    private var onRetryHandler: (() -> Void)?
    private var onOpenSettingsHandler: (() -> Void)?

    public init(status: UPNetworkStatus = .unknown,
                tips: String = UPConfig.noNetwork.tips,
                image: String = UPConfig.noNetwork.image,
                zIndex: some UPImageUnitValue = UPConfig.noNetwork.zIndex,
                onChange: ((UPNetworkStatus) -> Void)? = nil) {
        self._state = State(initialValue: UPNoNetworkState(status: status))
        self.tips = tips
        self.image = image
        self.zIndex = zIndex.upImageUnitValue
        self.onChangeHandler = onChange
    }

    public var isOffline: Bool { status == .offline }

    /// 空 `zIndex` 时回落到 `u-overlay` 的默认层级，与上游把空串直接传给遮罩等价。
    public var resolvedZIndex: Double {
        let trimmed = zIndex.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? UPConfig.overlay.zIndex : Double(UPUnit.parse(trimmed))
    }

    public var showsCustomImage: Bool { !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    public func onChange(_ action: @escaping (UPNetworkStatus) -> Void) -> UPNoNetwork {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游 `connected` 事件：`emitEvent` 在 `networkType !== 'none'` 时抛。
    public func onConnected(_ action: @escaping () -> Void) -> UPNoNetwork {
        var copy = self
        copy.onConnectedHandler = action
        return copy
    }

    /// 对应上游 `disconnected` 事件：`emitEvent` 在 `networkType === 'none'` 时抛。
    public func onDisconnected(_ action: @escaping () -> Void) -> UPNoNetwork {
        var copy = self
        copy.onDisconnectedHandler = action
        return copy
    }

    /// 对应上游 `retry` 事件。上游把它写在文档注释的 `@event` 里，`emits` 数组里没声明，
    /// 但 `retry()` 方法体确实 `$emit('retry')`，所以原生按实际行为建模。
    public func onRetry(_ action: @escaping () -> Void) -> UPNoNetwork {
        var copy = self
        copy.onRetryHandler = action
        return copy
    }

    /// 对应上游 `openSettings()`：仅 APP 平台可跳系统设置页，跳转由宿主执行。
    public func onOpenSettings(_ action: @escaping () -> Void) -> UPNoNetwork {
        var copy = self
        copy.onOpenSettingsHandler = action
        return copy
    }

    public func update(_ newStatus: UPNetworkStatus) {
        state.status = newStatus
        onChangeHandler?(newStatus)
        emitEvent(newStatus)
    }

    /// 上游 `emitEvent(networkType)`：`'none'` 抛 `disconnected`，其余一律抛 `connected`。
    /// 照抄上游：`unknown` 在上游不是 `'none'`，因此也走 `connected` 分支。
    public func emitEvent(_ status: UPNetworkStatus) {
        if status == .offline {
            onDisconnectedHandler?()
        } else {
            onConnectedHandler?()
        }
    }

    /// 上游 `retry()`：重新取一次网络类型 → `emitEvent` → toast → 最后抛 `retry`。
    public func retry(status: UPNetworkStatus? = nil) {
        let resolved = status ?? state.status
        state.status = resolved
        onChangeHandler?(resolved)
        emitEvent(resolved)
        UPToast.show(message: resolved == .offline
                        ? UPConfig.noNetwork.disconnectToast
                        : UPConfig.noNetwork.connectToast)
        onRetryHandler?()
    }

    /// 上游 `openSettings()`：只在当前确实断网时才跳设置页，联网状态下直接 return。
    public func openSettings() {
        guard state.status == .offline else { return }
        onOpenSettingsHandler?()
    }

    public var body: some View {
        Group {
            if isOffline { offlineContent.zIndex(resolvedZIndex) }
            else { EmptyView() }
        }
    }

    /// 上游图标固定 `size="150"`、`imgMode="widthFit"`，提示语为 14pt 的 `$u-tips-color`。
    @ViewBuilder
    private var offlineContent: some View {
        if showsCustomImage {
            VStack(spacing: 15) {
                UPIcon(name: image, size: "150", imgMode: "widthFit")
                Text(tips)
                    .font(.system(size: 14))
                    .foregroundStyle(UPColor.parse("tips"))
                    .multilineTextAlignment(.center)
                settingsRow
                retryButton
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 15) {
                ContentUnavailableView(tips, systemImage: "wifi.slash")
                settingsRow
                retryButton
            }
        }
    }

    /// 上游 `#ifdef APP-PLUS` 里的「请检查网络，或前往 设置」一行。iOS 原生就是 APP 平台，故渲染。
    private var settingsRow: some View {
        HStack(spacing: 4) {
            Text(UPConfig.noNetwork.pleaseCheckText)
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse("tips"))
            Text(UPConfig.noNetwork.settingsText)
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse("primary"))
                .onTapGesture { openSettings() }
        }
    }

    /// 上游 `<up-button size="mini" type="primary" plain :text="t('up.common.retry')" @click="retry">`。
    private var retryButton: some View {
        UPButton(type: "primary", size: "mini", plain: true, text: UPConfig.noNetwork.retryText) {
            retry()
        }
    }
}
