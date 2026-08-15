import SwiftUI

public struct UPTheme: Equatable, Sendable {
    public var main: Color = .init(hex: 0x303133)
    public var content: Color = .init(hex: 0x606266)
    public var tips: Color = .init(hex: 0x909193)
    public var light: Color = .init(hex: 0xC0C4CC)
    public var border: Color = .init(hex: 0xDADBDE)
    public var bg: Color = .init(hex: 0xF3F4F6)
    public var disabled: Color = .init(hex: 0xC8C9CC)
    public var primary: Color = .init(hex: 0x3C9CFF)
    public var primaryDark: Color = .init(hex: 0x398ADE)
    public var primaryDisabled: Color = .init(hex: 0x9ACAFC)
    public var primaryLight: Color = .init(hex: 0xECF5FF)
    public var warning: Color = .init(hex: 0xF9AE3D)
    public var warningDark: Color = .init(hex: 0xF1A532)
    public var warningDisabled: Color = .init(hex: 0xF9D39B)
    public var warningLight: Color = .init(hex: 0xFDF6EC)
    public var success: Color = .init(hex: 0x5AC725)
    public var successDark: Color = .init(hex: 0x53C21D)
    public var successDisabled: Color = .init(hex: 0xA9E08F)
    public var successLight: Color = .init(hex: 0xF5FFF0)
    public var error: Color = .init(hex: 0xF56C6C)
    public var errorDark: Color = .init(hex: 0xE45656)
    public var errorDisabled: Color = .init(hex: 0xF7B2B2)
    public var errorLight: Color = .init(hex: 0xFEF0F0)
    public var info: Color = .init(hex: 0x909399)
    public var infoDark: Color = .init(hex: 0x767A82)
    public var infoDisabled: Color = .init(hex: 0xC4C6C9)
    public var infoLight: Color = .init(hex: 0xF4F4F5)

    public static let `default` = UPTheme()
}

public extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private struct UPThemeKey: EnvironmentKey {
    static let defaultValue = UPTheme.default
}

public extension EnvironmentValues {
    var upTheme: UPTheme {
        get { self[UPThemeKey.self] }
        set { self[UPThemeKey.self] = newValue }
    }
}
