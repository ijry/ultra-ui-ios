import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/swipeAction/swipeAction`。
@MainActor
struct SwipeActionDemoView: View {
    @State private var openedID: String?
    @State private var group = UPSwipeActionGroup()
    @State private var lastEvent = "尚未触发"
    @State private var clickPayload = "尚未触发"
    @State private var freeOpened: [String] = []
    @State private var freeGroup = UPSwipeActionGroup(autoClose: false)

    private let durationSamples = ["300", "350ms", "0.3s", "1"]

    private let options1 = [
        UPSwipeAction(id: "delete", title: "删除", color: "#f56c6c")
    ]
    private let options2 = [
        UPSwipeAction(id: "favorite", title: "收藏", color: "#3c9cff"),
        UPSwipeAction(id: "delete", title: "删除", color: "#f56c6c")
    ]
    private let options3 = [
        UPSwipeAction(id: "favorite", title: "收藏", color: "#f9ae3d", icon: "star")
    ]
    private let options4 = [
        UPSwipeAction(id: "top", title: "置顶", color: "#3c9cff"),
        UPSwipeAction(id: "cancel", title: "取消", color: "#f9ae3d")
    ]
    private let options5 = [
        UPSwipeAction(id: "trash", title: "", icon: "trash",
                      style: UPStyle(["backgroundColor": "#f56c6c", "borderRadius": "100px"])),
        UPSwipeAction(id: "heart", title: "", icon: "heart",
                      style: UPStyle(["backgroundColor": "#5ac725", "borderRadius": "100px"]))
    ]

    var body: some View {
        DemoPage {
            DemoSection("演示案例") {
                row(id: "basic", text: "基础使用", actions: options1)
            }

            DemoSection("按钮组") {
                row(id: "buttons", text: "两个按钮并列", actions: options2)
            }

            DemoSection("带图标") {
                row(id: "icon", text: "自定义图标", actions: options3)

                tip("item.icon 与 item.iconSize 都可用；未给 iconSize 时上游取 style.fontSize × 1.2，两者都没给才兜底 17。")
            }

            DemoSection("组合使用") {
                row(id: "combo-disabled", text: "禁用状态", actions: options4, disabled: true)
                row(id: "combo-normal", text: "正常状态", actions: options4)
                row(id: "combo-auto", text: "自动关闭", actions: options4)
            }

            DemoSection("自定义按钮形状") {
                row(id: "shape", text: "圆形按钮", actions: options5)

                tip("style.borderRadius 一设，上游就把按钮从撑满整高改成只包内容（alignItems: center）、内边距归零。")
            }

            DemoSection("拖拽手势") {
                tip("左滑越过 threshold 展开、右滑越过阈值收起，位移夹在按钮总宽内；横向位移小于纵向时判为页面滚动。")

                row(id: "drag", text: "试着左滑我", actions: options2)

                tip("照抄上游两处：展开态下 moveX == 0（点了内容区）直接收起，moveX < 0（继续左滑）直接 return —— 此时内容停在手指位置而不回弹。")
            }

            DemoSection("button 插槽") {
                UPSwipeActionItem(id: "slot", show: openedID == "slot", actions: options2) {
                    Text("按钮区完全自定义")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { toggle("slot", text: "按钮区完全自定义", disabled: false) }
                }
                .buttonContent {
                    HStack(spacing: 0) {
                        Text("标记")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(maxHeight: .infinity)
                            .background(UPColor.parse("primary"))

                        Text("移除")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(maxHeight: .infinity)
                            .background(UPColor.parse("error"))
                    }
                }
                .overlay(alignment: .bottom) { Divider() }

                tip("给了 button 插槽后内建按钮组不再渲染，按钮区宽度仍由组件自己量出来驱动位移。")
            }

            DemoSection("标识符与过渡时间") {
                row(id: "named", text: "name = 7，duration = 0.3s", actions: options2, name: 7, duration: "0.3s")

                tip("click payload：\(clickPayload)")

                ForEach(durationSamples, id: \.self) { sample in
                    tip("duration \"\(sample)\" → \(Int(UPSwipeActionItem(id: "d", duration: sample).resolvedDuration)) ms")
                }

                tip("上游 getDuration 以 30 为阈值推断单位：带 ms 取数值，带 s 乘 1000，裸数字小于 30 视为秒。")
            }

            DemoSection("滑动状态") {
                tip("scrolling: true 初始化 → isScrolling = \(UPSwipeActionItem(id: "s", scrolling: true).isScrolling)")

                tip("再叠加 disabled: true → isScrolling = \(UPSwipeActionItem(id: "s", disabled: true, scrolling: true).isScrolling)，对应上游 watch.disabled 里的 setScrolling(false)。")

                tip("setScrolling 会先对内部值去重，再同时派发 update:scrolling 与 scrolling，收起单元格时也会复位。")
            }

            DemoSection("关闭其他（autoClose）") {
                freeRow(id: "free-a", text: "可与下一行同时展开", actions: options4)
                freeRow(id: "free-b", text: "autoClose 为 false", actions: options4)

                tip("UPSwipeActionGroup(autoClose: false) 展开：\(freeOpened.isEmpty ? "无" : freeOpened.joined(separator: "、"))")

                Button("closeAll()") {
                    freeGroup.updateOpendItem(false)
                    freeOpened = freeGroup.openedIDs
                }
                .font(.system(size: 14))

                tip("opendItem 置为 false 时上游 watch 调用 closeAll()；setOpendItem 派发的是拼写反常的 opendItem:update，值恒为 true。")
            }

            DemoSection("互斥状态") {
                Text("当前展开：\(openedID ?? "无")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("UPSwipeActionGroup 记录：\(group.openedID ?? "无")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("事件：\(lastEvent)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSwipeActionItem 覆盖上游全部 9 个 prop：show / closeOnClick / name / disabled / autoClose / scrolling / threshold / options（别名 actions）/ duration，事件为 click（payload 为 index 与 name）、update:show（open/close）、scrolling，另有 button 插槽。本轮补齐渲染与手势：按钮区绝对定位在右侧、内容层盖在上面靠 translateX 左移露出按钮，外层裁切；按钮配色按上游 item.style 的 backgroundColor / color / fontSize / borderRadius 四个键解析（默认底色 #C7C6CD、暗色回落 #4b5563，文字白色 16px，图标兜底 17 或 fontSize × 1.2），borderRadius 一设就改成只包内容且内边距归零；touchstart / touchmove / touchend / touchcancel 逐条照抄上游 other.js，位移夹在按钮总宽内，横向位移小于纵向时判为页面滚动，duration 现在驱动展开收起动画。照抄上游两处反直觉：展开态下 moveX == 0 视为点了内容区直接收起，moveX < 0 直接 return 让内容停在手指位置。UPSwipeActionGroup 覆盖 autoClose 与 opendItem，对应上游 closeOther / closeAll / setOpendItem。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(
        id: String,
        text: String,
        actions: [UPSwipeAction],
        disabled: Bool = false,
        name: UPCellName = "",
        duration: String = "300"
    ) -> some View {
        UPSwipeActionItem(id: id, show: openedID == id, name: name, disabled: disabled, actions: actions, duration: duration) {
            Text(text)
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { toggle(id, text: text, disabled: disabled) }
        }
        .onClick { payload in clickPayload = "index=\(payload.index)，name=\(payload.name.description)" }
        .onAction { action in
            lastEvent = "\(text) → \(action.title)"
            openedID = nil
            group.close()
        }
        .overlay(alignment: .bottom) { Divider() }
    }

    private func freeRow(id: String, text: String, actions: [UPSwipeAction]) -> some View {
        UPSwipeActionItem(id: id, show: freeOpened.contains(id), autoClose: false, actions: actions) {
            Text(text)
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    freeGroup.register(id)
                    if freeOpened.contains(id) {
                        freeGroup.close(id)
                    } else {
                        freeGroup.open(id)
                    }
                    freeOpened = freeGroup.openedIDs
                }
        }
        .onAction { action in
            lastEvent = "\(text) → \(action.title)"
            freeGroup.close(id)
            freeOpened = freeGroup.openedIDs
        }
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }

    private func toggle(_ id: String, text: String, disabled: Bool) {
        guard !disabled else {
            lastEvent = "\(text) 已禁用，不响应展开"
            return
        }

        group.register(id)
        if openedID == id {
            openedID = nil
            group.close()
        } else {
            openedID = id
            group.open(id)
        }
    }
}
