import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

private func upGeneratedImage(filterName: String, value: String, width: CGFloat, height: CGFloat) -> CIImage? {
    guard let filter = CIFilter(name: filterName), let data = value.data(using: .utf8) else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    guard let image = filter.outputImage else { return nil }
    let targetWidth = max(width, 1)
    let targetHeight = max(height, 1)
    let scaleX = targetWidth / max(image.extent.width, 1)
    let scaleY = targetHeight / max(image.extent.height, 1)
    return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
}

private func upCGImage(_ image: CIImage) -> CGImage? {
    CIContext(options: nil).createCGImage(image, from: image.extent)
}

public struct UPQRCode: View {
    public var value: String
    public var size: CGFloat
    public var payload: Data { value.data(using: .utf8) ?? Data() }
    public var generatedImage: CIImage? { upGeneratedImage(filterName: "CIQRCodeGenerator", value: value, width: size, height: size) }

    public init(value: String = "", size: some UPImageUnitValue = 200) {
        self.value = value
        self.size = max(0, UPUnit.parse(size.upImageUnitValue))
    }

    public var body: some View {
        Group {
            if let generatedImage, let cgImage = upCGImage(generatedImage) {
                Image(decorative: cgImage, scale: 1, orientation: .up)
            }
            else { Color.clear }
        }.frame(width: size, height: size)
    }
}

public struct UPBarcode: View {
    public var value: String
    public var width: CGFloat
    public var height: CGFloat
    public var generatedImage: CIImage? { upGeneratedImage(filterName: "CICode128BarcodeGenerator", value: value, width: width, height: height) }

    public init(value: String = "", width: some UPImageUnitValue = 300, height: some UPImageUnitValue = 100) {
        self.value = value
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
    }

    public var body: some View {
        Group {
            if let generatedImage, let cgImage = upCGImage(generatedImage) {
                Image(decorative: cgImage, scale: 1, orientation: .up)
            }
            else { Color.clear }
        }.frame(width: width, height: height)
    }
}
