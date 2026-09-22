import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/dragsort/dragsort`。
@MainActor
struct DragsortDemoView: View {
    private struct DragItem: Equatable, Identifiable {
        let id: Int
        let label: String
        var draggable = true
    }

    private static let list = (1...8).map { index in
        DragItem(id: index, label: "项目 " + String(UnicodeScalar(64 + index)!))
    }

    /// 上游支持 `item.draggable === false` 单独锁住某项。
    private static let mixedList = (1...6).map { index in
        DragItem(id: index,
                 label: "项目 " + String(UnicodeScalar(64 + index)!),
                 draggable: index != 3)
    }

    @State private var eventLog = "尚未排序"

    var body: some View {
        DemoPage {
            UPAlert(description: "按住任意一行上下拖动即可换序")

            DemoSection("单列多行模式（vertical）") {
                UPDragsort(initialList: Self.list) { item, index in
                    row(index: index, label: item.label)
                }
                .onDragEnd { list in
                    eventLog = "drag-end：" + list.map(\.label).joined(separator: " / ")
                }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("自定义拖动句柄（handler 插槽）") {
                UPDragsort(initialList: Self.list) { item, index in
                    row(index: index, label: item.label)
                }
                .handler { _, _ in handle }
                .onDragEnd { list in
                    eventLog = "handler drag-end：共 \(list.count) 项"
                }

                tip("提供 handler 插槽后只有把手能发起拖动，整行不再响应。")
            }

            DemoSection("多行多列模式（all + columns）") {
                UPDragsort(initialList: Self.list, direction: "all", columns: 3) { item, _ in
                    Text(item.label)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(UPColor.parse("#dadbde"), lineWidth: 1)
                        }
                        .padding(4)
                }

                tip("direction 为 all 时按 columns 排成网格。")
            }

            DemoSection("单行横向拖动（horizontal）") {
                UPDragsort(initialList: Self.list, direction: "horizontal") { item, _ in
                    Text(item.label)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(UPColor.parse("#dadbde"), lineWidth: 1)
                        }
                        .padding(.trailing, 8)
                }

                tip("direction 为 horizontal 时左右拖动换序。")
            }

            DemoSection("禁用与逐项锁定") {
                UPDragsort(initialList: Self.list, draggable: false) { item, index in
                    row(index: index, label: item.label + "（整体禁用）")
                }

                UPDragsort(initialList: Self.mixedList,
                           vibrate: false,
                           itemDraggable: { $0.draggable }) { item, index in
                    row(index: index, label: item.label + (item.draggable ? "" : "（已锁定）"))
                }

                tip("draggable 为 false 时整体不可拖；itemDraggable 对应上游 item.draggable === false。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPDragsort 已覆盖上游 5 个 prop：initialList / draggable / vibrate / direction / columns（另用 itemDraggable 闭包表达 item.draggable === false），事件为 onDragEnd((\\[Item]) -> Void) 外加仓库既有的 onStart / onChange / onEnd，方法 begin(at:) / move(from:to:) / end() / isDraggable(_:)，并提供 handler 作用域插槽。列表由组件自己持有（对应上游 data.list），换序后就地更新并抛 drag-end。两点差异：上游用 movable-view 的 x/y 做逐帧跟手动画，原生用 DragGesture 按固定步长换序，拖拽中不做位移动画；上游会实测每项宽高来定步长，原生取 44pt 的近似值。vibrate 走 UIImpactFeedbackGenerator。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(index: Int, label: String) -> some View {
        HStack(spacing: 8) {
            Text("序号：\(index + 1) - \(label)")
                .font(.system(size: 14))
            Spacer(minLength: 0)
        }
        .padding(10)
        .overlay {
            RoundedRectangle(cornerRadius: 8).stroke(UPColor.parse("#dadbde"), lineWidth: 1)
        }
        .padding(.bottom, 8)
    }

    /// 上游 handler 插槽里的三横线句柄。
    private var handle: some View {
        VStack(spacing: 3) {
            ForEach(Array(0..<3), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(UPColor.parse("#c0c4cc"))
                    .frame(width: 16, height: 2)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
