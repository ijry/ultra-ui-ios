import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

func upGeneratedImage(filterName: String, value: String, width: CGFloat, height: CGFloat) -> CIImage? {
    guard let filter = CIFilter(name: filterName), let data = value.data(using: .utf8) else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    guard let image = filter.outputImage else { return nil }
    let targetWidth = max(width, 1)
    let targetHeight = max(height, 1)
    let scaleX = targetWidth / max(image.extent.width, 1)
    let scaleY = targetHeight / max(image.extent.height, 1)
    return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
}

func upCGImage(_ image: CIImage) -> CGImage? {
    CIContext(options: nil).createCGImage(image, from: image.extent)
}
