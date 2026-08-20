import Foundation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-image` unit props.
public protocol UPImageUnitValue {
    var upImageUnitValue: String { get }
}

extension String: UPImageUnitValue {
    public var upImageUnitValue: String { self }
}

extension Int: UPImageUnitValue {
    public var upImageUnitValue: String { String(self) }
}

extension Double: UPImageUnitValue {
    public var upImageUnitValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPImageUnitValue {
    public var upImageUnitValue: String { Double(self).upImageUnitValue }
}

extension CGFloat: UPImageUnitValue {
    public var upImageUnitValue: String { Double(self).upImageUnitValue }
}

/// The native loading state corresponding to uview-plus `u-image`'s internal
/// `loading` and `isError` flags.
public enum UPImageLoadState: Equatable, Sendable {
    case loading
    case loaded
    case error
}

/// Native Swift value emitted through `UPImage.onLoad(_:)`.
public struct UPImageLoadEvent: Equatable, Sendable {
    public let source: String

    public init(source: String) {
        self.source = source
    }
}

/// Native Swift value emitted through `UPImage.onError(_:)`.
public struct UPImageErrorEvent: Equatable, Sendable {
    public let source: String
    public let message: String

    public init(source: String, message: String) {
        self.source = source
        self.message = message
    }
}

/// Native SwiftUI counterpart of uview-plus `u-image`.
///
/// The component retains uview-plus property names and defaults. `lazyLoad`,
/// `showMenuByLongpress`, and `webp` are preserved as compatibility metadata:
/// image scheduling, long-press menus, and image decoding remain native Apple
/// platform responsibilities. The `click`, `load`, and `error` emits map to
/// typed Swift closures.
public struct UPImage: View {
    var src: String
    var mode: String
    var width: String
    var height: String
    var shape: String
    var radius: String
    var lazyLoad: Bool
    var showMenuByLongpress: Bool
    var loadingIcon: String
    var errorIcon: String
    var showLoading: Bool
    var showError: Bool
    var fade: Bool
    var webp: Bool
    var duration: Int
    var bgColor: String
    var customStyle: UPStyle
    var onClickHandler: (() -> Void)?
    var onErrorHandler: ((UPImageErrorEvent) -> Void)?
    var onLoadHandler: ((UPImageLoadEvent) -> Void)?
    private var loadingContent: AnyView
    private var errorContent: AnyView
    var hasLoadingSlot: Bool
    var hasErrorSlot: Bool

    @Environment(\.upTheme) private var theme
    @State private var loadState: UPImageLoadState

    public init(
        src: String = UPConfig.image.src,
        mode: String = UPConfig.image.mode,
        width: some UPImageUnitValue = UPConfig.image.width,
        height: some UPImageUnitValue = UPConfig.image.height,
        shape: String = UPConfig.image.shape,
        radius: some UPImageUnitValue = UPConfig.image.radius,
        lazyLoad: Bool = UPConfig.image.lazyLoad,
        showMenuByLongpress: Bool = UPConfig.image.showMenuByLongpress,
        loadingIcon: String = UPConfig.image.loadingIcon,
        errorIcon: String = UPConfig.image.errorIcon,
        showLoading: Bool = UPConfig.image.showLoading,
        showError: Bool = UPConfig.image.showError,
        fade: Bool = UPConfig.image.fade,
        webp: Bool = UPConfig.image.webp,
        duration: some UPImageUnitValue = UPConfig.image.duration,
        bgColor: String = UPConfig.image.bgColor,
        customStyle: UPStyle = UPStyle(),
        onClick: (() -> Void)? = nil,
        onError: ((UPImageErrorEvent) -> Void)? = nil,
        onLoad: ((UPImageLoadEvent) -> Void)? = nil
    ) {
        self.init(
            src: src,
            mode: mode,
            width: width.upImageUnitValue,
            height: height.upImageUnitValue,
            shape: shape,
            radius: radius.upImageUnitValue,
            lazyLoad: lazyLoad,
            showMenuByLongpress: showMenuByLongpress,
            loadingIcon: loadingIcon,
            errorIcon: errorIcon,
            showLoading: showLoading,
            showError: showError,
            fade: fade,
            webp: webp,
            duration: Self.durationValue(duration.upImageUnitValue),
            bgColor: bgColor,
            customStyle: customStyle,
            onClick: onClick,
            onError: onError,
            onLoad: onLoad,
            loadingContent: AnyView(EmptyView()),
            errorContent: AnyView(EmptyView()),
            hasLoadingSlot: false,
            hasErrorSlot: false
        )
    }

    /// Creates an image with SwiftUI counterparts of the named `loading` and
    /// `error` slots from uview-plus.
    public init<LoadingContent: View, ErrorContent: View>(
        src: String = UPConfig.image.src,
        mode: String = UPConfig.image.mode,
        width: some UPImageUnitValue = UPConfig.image.width,
        height: some UPImageUnitValue = UPConfig.image.height,
        shape: String = UPConfig.image.shape,
        radius: some UPImageUnitValue = UPConfig.image.radius,
        lazyLoad: Bool = UPConfig.image.lazyLoad,
        showMenuByLongpress: Bool = UPConfig.image.showMenuByLongpress,
        loadingIcon: String = UPConfig.image.loadingIcon,
        errorIcon: String = UPConfig.image.errorIcon,
        showLoading: Bool = UPConfig.image.showLoading,
        showError: Bool = UPConfig.image.showError,
        fade: Bool = UPConfig.image.fade,
        webp: Bool = UPConfig.image.webp,
        duration: some UPImageUnitValue = UPConfig.image.duration,
        bgColor: String = UPConfig.image.bgColor,
        customStyle: UPStyle = UPStyle(),
        onClick: (() -> Void)? = nil,
        onError: ((UPImageErrorEvent) -> Void)? = nil,
        onLoad: ((UPImageLoadEvent) -> Void)? = nil,
        @ViewBuilder loading: () -> LoadingContent,
        @ViewBuilder error: () -> ErrorContent
    ) {
        self.init(
            src: src,
            mode: mode,
            width: width.upImageUnitValue,
            height: height.upImageUnitValue,
            shape: shape,
            radius: radius.upImageUnitValue,
            lazyLoad: lazyLoad,
            showMenuByLongpress: showMenuByLongpress,
            loadingIcon: loadingIcon,
            errorIcon: errorIcon,
            showLoading: showLoading,
            showError: showError,
            fade: fade,
            webp: webp,
            duration: Self.durationValue(duration.upImageUnitValue),
            bgColor: bgColor,
            customStyle: customStyle,
            onClick: onClick,
            onError: onError,
            onLoad: onLoad,
            loadingContent: AnyView(loading()),
            errorContent: AnyView(error()),
            hasLoadingSlot: true,
            hasErrorSlot: true
        )
    }

    public var body: some View {
        imageContent
            .frame(width: resolvedWidth, height: resolvedHeight)
            .clipShape(RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous))
            .contentShape(Rectangle())
            .animation(fade ? .easeInOut(duration: Double(duration) / 1_000) : nil, value: loadState)
            .upStyle(customStyle)
            .onTapGesture { onClickHandler?() }
            .onChange(of: src) { _, newSource in
                loadState = Self.state(for: newSource)
            }
    }

    /// The initial uview-plus state derived from the current source. An empty
    /// source is an error presentation but does not emit a native error event,
    /// matching the upstream source watcher.
    var initialLoadState: UPImageLoadState {
        Self.state(for: src)
    }

    var showsLoadingPlaceholder: Bool {
        initialLoadState == .loading && showLoading
    }

    var showsErrorPlaceholder: Bool {
        initialLoadState == .error && showError
    }

    var resolvedWidth: CGFloat {
        max(UPUnit.parse(width), 0)
    }

    var resolvedHeight: CGFloat {
        max(UPUnit.parse(height), 0)
    }

    var resolvedRadius: CGFloat {
        shape.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "circle"
            ? max(resolvedWidth, resolvedHeight) / 2
            : max(UPUnit.parse(radius), 0)
    }

    /// SwiftUI event modifier corresponding to uview-plus `@click`.
    public func onClick(_ action: @escaping () -> Void) -> UPImage {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    /// Native alias for the click event when using SwiftUI naming conventions.
    public func onTap(_ action: @escaping () -> Void) -> UPImage {
        onClick(action)
    }

    /// SwiftUI event modifier corresponding to uview-plus `@load`.
    public func onLoad(_ action: @escaping (UPImageLoadEvent) -> Void) -> UPImage {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    /// SwiftUI event modifier corresponding to uview-plus `@error`.
    public func onError(_ action: @escaping (UPImageErrorEvent) -> Void) -> UPImage {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    @ViewBuilder
    private var imageContent: some View {
        if src.isEmpty {
            placeholder(for: .error)
        } else if let url = remoteImageURL(src) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder(for: .loading)
                        .onAppear { loadState = .loading }
                case .success(let image):
                    renderedImage(image)
                        .onAppear { reportLoad() }
                case .failure(let error):
                    placeholder(for: .error)
                        .onAppear { reportError(message: error.localizedDescription) }
                @unknown default:
                    placeholder(for: .loading)
                }
            }
        } else {
            renderedImage(Image(src))
                .onAppear { reportLoad() }
        }
    }

    @ViewBuilder
    private func placeholder(for state: UPImageLoadState) -> some View {
        if shouldShowPlaceholder(for: state) {
            ZStack {
                UPColor.parse(bgColor, theme: theme)
                if state == .loading {
                    if hasLoadingSlot {
                        loadingContent
                    } else {
                        UPIcon(name: loadingIcon)
                    }
                } else if hasErrorSlot {
                    errorContent
                } else {
                    UPIcon(name: errorIcon)
                }
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func renderedImage(_ image: Image) -> some View {
        if UPIcon.usesAspectFill(for: mode) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: resolvedWidth, height: resolvedHeight)
                .clipped()
        } else {
            image
                .resizable()
                .scaledToFit()
                .frame(width: resolvedWidth, height: resolvedHeight)
        }
    }

    private func shouldShowPlaceholder(for state: UPImageLoadState) -> Bool {
        switch state {
        case .loading:
            return showLoading
        case .error:
            return showError
        case .loaded:
            return false
        }
    }

    private func reportLoad() {
        guard loadState != .loaded else { return }
        loadState = .loaded
        onLoadHandler?(UPImageLoadEvent(source: src))
    }

    private func reportError(message: String) {
        guard loadState != .error else { return }
        loadState = .error
        onErrorHandler?(UPImageErrorEvent(source: src, message: message))
    }

    private func remoteImageURL(_ source: String) -> URL? {
        guard let url = URL(string: source), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        return ["http", "https", "file"].contains(scheme) ? url : nil
    }

    private static func state(for source: String) -> UPImageLoadState {
        source.isEmpty ? .error : .loading
    }

    private static func durationValue(_ value: String) -> Int {
        max(Int(UPUnit.parse(value)), 0)
    }

    private init(
        src: String,
        mode: String,
        width: String,
        height: String,
        shape: String,
        radius: String,
        lazyLoad: Bool,
        showMenuByLongpress: Bool,
        loadingIcon: String,
        errorIcon: String,
        showLoading: Bool,
        showError: Bool,
        fade: Bool,
        webp: Bool,
        duration: Int,
        bgColor: String,
        customStyle: UPStyle,
        onClick: (() -> Void)?,
        onError: ((UPImageErrorEvent) -> Void)?,
        onLoad: ((UPImageLoadEvent) -> Void)?,
        loadingContent: AnyView,
        errorContent: AnyView,
        hasLoadingSlot: Bool,
        hasErrorSlot: Bool
    ) {
        self.src = src
        self.mode = mode
        self.width = width
        self.height = height
        self.shape = shape
        self.radius = radius
        self.lazyLoad = lazyLoad
        self.showMenuByLongpress = showMenuByLongpress
        self.loadingIcon = loadingIcon
        self.errorIcon = errorIcon
        self.showLoading = showLoading
        self.showError = showError
        self.fade = fade
        self.webp = webp
        self.duration = max(duration, 0)
        self.bgColor = bgColor
        self.customStyle = customStyle
        self.onClickHandler = onClick
        self.onErrorHandler = onError
        self.onLoadHandler = onLoad
        self.loadingContent = loadingContent
        self.errorContent = errorContent
        self.hasLoadingSlot = hasLoadingSlot
        self.hasErrorSlot = hasErrorSlot
        self._loadState = State(initialValue: Self.state(for: src))
    }
}
