import SwiftUI
import CoreText

public enum UltraUI {
    /// 注册内置图标字体，App 启动时调用一次
    public static func registerFonts() {
        guard let url = Bundle.module.url(forResource: "upicon", withExtension: "ttf"),
              let data = try? Data(contentsOf: url) as CFData,
              let provider = CGDataProvider(data: data),
              let font = CGFont(provider) else { return }
        CTFontManagerRegisterGraphicsFont(font, nil)
    }
}
