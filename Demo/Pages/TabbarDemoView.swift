import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/tabbar/tabbar`。
@MainActor
struct TabbarDemoView: View {
    @State private var value1 = "home"
    @State private var value2 = "home"
    @State private var value3 = "play-right"
    @State private var value4 = "home"
    @State private var value5 = "home"
    @State private var value7 = "account"
    @State private var valuePill = "home"
    @State private var valueLift = "home"
    @State private var valueMid = "home"
    @State private var valueMidIcon = "home"
    @State private var valueGlow = "home"
    @State private var valueFixed = "home"
    @State private var clickLog = "尚未点击"
    @State private var interceptLog = "尚未拦截"

    private static let basicItems: [(name: String, text: String, icon: String)] = [
        ("home", "首页", "house"),
        ("photo", "放映厅", "photo"),
        ("play-right", "直播", "play.fill"),
        ("account", "我的", "person")
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPTabbar(
                    items: Self.basicItems.map { item in
                        UPTabbarItem(name: item.name, icon: item.icon, text: item.text)
                            .onClick { name in clickLog = "点击了 \(name)" }
                    },
                    value: $value1,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )

                Text("当前 value1=\(value1)　最近点击：\(clickLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("显示徽标") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", dot: true, text: "首页"),
                        UPTabbarItem(name: "photo", icon: "photo", badge: "3", text: "放映厅"),
                        UPTabbarItem(name: "play-right", icon: "play.fill", text: "直播"),
                        UPTabbarItem(name: "account", icon: "person", text: "我的")
                    ],
                    value: $value2,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )
            }

            DemoSection("匹配标签的名称") {
                UPTabbar(
                    items: Self.basicItems.map { UPTabbarItem(name: $0.name, icon: $0.icon, text: $0.text) },
                    value: $value3,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )

                Text("初值为 play-right，当前 value3=\(value3)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义图标/颜色") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", activeIcon: "bell.fill", inactiveIcon: "bell", text: "首页"),
                        UPTabbarItem(name: "photo", icon: "photo", text: "放映厅"),
                        UPTabbarItem(name: "play-right", icon: "play.fill", text: "直播"),
                        UPTabbarItem(name: "account", icon: "person", text: "我的")
                    ],
                    value: $value4,
                    safeAreaInsetBottom: false,
                    activeColor: "#d81e06",
                    fixed: false,
                    placeholder: false
                )

                Text("上游第一项用图片插槽切换 bell-selected.png / bell.png，这里改用 SF Symbol 的 activeIcon / inactiveIcon。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("拦截切换事件(点击第二个标签)") {
                UPTabbar(
                    items: Self.basicItems.map { item in
                        UPTabbarItem(name: item.name, icon: item.icon, text: item.text)
                            .onClick { name in
                                guard name == "photo" else { return }
                                interceptLog = "请您先登录"
                                UPToast.show(message: "请您先登录")
                            }
                    },
                    value: interceptedValue,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )

                Text("当前 value5=\(value5)　\(interceptLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("去除上边框") {
                UPTabbar(
                    items: Self.basicItems.map { UPTabbarItem(name: $0.name, icon: $0.icon, text: $0.text) },
                    value: $value7,
                    safeAreaInsetBottom: false,
                    border: false,
                    fixed: false,
                    placeholder: false
                )
            }

            DemoSection("首页导航推荐：胶囊风格") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页"),
                        UPTabbarItem(name: "discover", icon: "safari", text: "发现"),
                        UPTabbarItem(name: "message", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "profile", icon: "person", text: "我的")
                    ],
                    value: $valuePill,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false,
                    styleType: "pill",
                    animationType: "scale",
                    activeBackgroundColor: "#3b82f61a"
                )
            }

            DemoSection("首页导航推荐：上浮风格") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页"),
                        UPTabbarItem(name: "discover", icon: "safari", text: "发现"),
                        UPTabbarItem(name: "message", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "profile", icon: "person", text: "我的")
                    ],
                    value: $valueLift,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false,
                    styleType: "lift",
                    animationType: "lift",
                    textMode: "active"
                )
            }

            DemoSection("中间按钮自定义背景色") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页"),
                        UPTabbarItem(name: "search", icon: "magnifyingglass", text: "发现"),
                        UPTabbarItem(
                            name: "plus", icon: "plus", text: "发布", mode: "midButton",
                            midButtonBgColor: "#E8FFF7", midButtonIconColor: "#10B981",
                            midButtonOffsetY: -12
                        ),
                        UPTabbarItem(name: "chat", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "account", icon: "person", text: "我的")
                    ],
                    value: $valueMid,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )
            }

            DemoSection("中间按钮自定义图标") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页"),
                        UPTabbarItem(name: "search", icon: "magnifyingglass", text: "发现"),
                        UPTabbarItem(
                            name: "camera", icon: "camera.fill", text: "拍摄", mode: "midButton",
                            midButtonBgColor: "#EEF4FF", midButtonIconColor: "#3B82F6",
                            midButtonIconSize: 30, midButtonOffsetY: -12
                        ),
                        UPTabbarItem(name: "chat", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "account", icon: "person", text: "我的")
                    ],
                    value: $valueMidIcon,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false
                )
            }

            DemoSection("首页导航推荐：发光风格") {
                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页"),
                        UPTabbarItem(name: "discover", icon: "safari", text: "发现"),
                        UPTabbarItem(name: "message", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "profile", icon: "person", text: "我的")
                    ],
                    value: $valueGlow,
                    safeAreaInsetBottom: false,
                    fixed: false,
                    placeholder: false,
                    styleType: "glow",
                    animationType: "scale",
                    activeBackgroundColor: "#7dd3fc1f"
                )
            }

            DemoSection("固定在底部及中间按钮") {
                UPGap(height: 150)

                UPTabbar(
                    items: [
                        UPTabbarItem(name: "home", icon: "house", text: "首页")
                            .onClick { _ in UPToast.show(message: "跳转下一页") },
                        UPTabbarItem(name: "search", icon: "magnifyingglass", text: "发现"),
                        UPTabbarItem(name: "plus", icon: "plus", mode: "midButton")
                            .onClick { _ in UPToast.show(message: "点击了中间按钮") },
                        UPTabbarItem(name: "chat", icon: "bubble.left", text: "消息"),
                        UPTabbarItem(name: "account", icon: "person", text: "我的")
                    ],
                    value: $valueFixed,
                    borderColor: "#f56c6c",
                    fixed: false,
                    placeholder: false
                )
            }

            DemoSection("当前原生范围") {
                Text("原生 UPTabbar 已落地图标/文字/激活色/上边框/背景色与 textMode，dot、badge、badgeStyle、styleType、animationType、activeBackgroundColor、itemShape、iconScale 目前只作为参数保存；midButton 的上浮与自定义底色由 UPTabbarItem 自身承担，UPTabbar 重画 items 时不会应用。fixed/placeholder 在 Demo 中统一置为 false，避免脱离 ScrollView 布局。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var interceptedValue: Binding<String> {
        Binding(
            get: { value5 },
            set: { newValue in
                guard newValue != "photo" else { return }
                value5 = newValue
            }
        )
    }
}
