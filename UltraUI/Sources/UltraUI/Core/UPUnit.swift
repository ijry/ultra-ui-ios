import SwiftUI

public enum UPUnit {
    /// rpx → pt，375 基准宽度
    public static func rpx(_ value: Double) -> Double { value * 375.0 / 375.0 }
    public static func rpx(_ value: CGFloat) -> CGFloat { CGFloat(rpx(Double(value))) }

    /// 解析 "650rpx" / "20px" / 数值 → pt
    public static func parse(_ value: Any) -> CGFloat {
        if let n = value as? NSNumber { return CGFloat(truncating: n) }
        if let s = value as? String {
            if s.hasSuffix("rpx") { return rpx(CGFloat(Double(s.dropLast(3)) ?? 0)) }
            if s.hasSuffix("px") { return CGFloat(Double(s.dropLast(2)) ?? 0) }
            if let d = Double(s) { return CGFloat(d) }
        }
        return 0
    }
}
