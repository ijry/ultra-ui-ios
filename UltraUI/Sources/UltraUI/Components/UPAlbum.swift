import SwiftUI

/// Native counterpart of `u-album`. Sources remain strings so callers can use
/// the same URL/path values as the Vue component.
@MainActor
public final class UPAlbum: View {
    public var images: [String]
    public var singleSize: CGFloat
    public var multipleSize: CGFloat
    public var maxCount: Int
    public private(set) var current: Int = 0
    private var onClickHandler: ((Int, String) -> Void)?

    public init(images: [String] = [], singleSize: some UPImageUnitValue = 80,
                multipleSize: some UPImageUnitValue = 60, maxCount: Int = 9,
                onClick: ((Int, String) -> Void)? = nil) {
        self.images = images
        self.singleSize = max(0, UPUnit.parse(singleSize.upImageUnitValue))
        self.multipleSize = max(0, UPUnit.parse(multipleSize.upImageUnitValue))
        self.maxCount = max(0, maxCount)
        self.onClickHandler = onClick
    }

    public func onClick(_ action: @escaping (Int, String) -> Void) -> UPAlbum {
        onClickHandler = action
        return self
    }

    public func select(_ index: Int) {
        guard images.indices.contains(index) else { return }
        current = index
        onClickHandler?(index, images[index])
    }

    public var displayedImages: ArraySlice<String> {
        images.prefix(maxCount)
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: max(multipleSize, 1)))], spacing: 8) {
            ForEach(Array(displayedImages.enumerated()), id: \.offset) { index, source in
                Button { self.select(index) } label: {
                    UPImage(src: source, width: self.multipleSize, height: self.multipleSize)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
