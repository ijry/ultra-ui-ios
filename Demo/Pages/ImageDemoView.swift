import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/image/image`。
struct ImageDemoView: View {
    private let sample = "https://uview-plus.jiangruyi.com/common/logo.png"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPImage(src: sample, width: 100, height: 100)
            }

            DemoSection("圆形与圆角") {
                HStack(spacing: 16) {
                    UPImage(src: sample, width: 80, height: 80, shape: "circle")
                    UPImage(src: sample, width: 80, height: 80, radius: 12)
                }
            }

            DemoSection("裁剪模式") {
                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        UPImage(src: sample, mode: "aspectFit", width: 80, height: 80)
                        Text("aspectFit").font(.caption)
                    }
                    VStack(spacing: 6) {
                        UPImage(src: sample, mode: "aspectFill", width: 80, height: 80)
                        Text("aspectFill").font(.caption)
                    }
                    VStack(spacing: 6) {
                        UPImage(src: sample, mode: "scaleToFill", width: 80, height: 80)
                        Text("scaleToFill").font(.caption)
                    }
                }
            }

            DemoSection("加载失败") {
                UPImage(src: "https://example.invalid/missing.png", width: 100, height: 100)
            }
        }
    }
}
