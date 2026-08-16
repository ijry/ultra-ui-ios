import SwiftUI
import UltraUI

struct ModalDemoView: View {
    @State private var showConfirm = false
    @State private var showAsync = false

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                UPButton(type: "primary", text: "确认弹窗") {
                    showConfirm = true
                }
                UPButton(type: "warning", text: "异步关闭") {
                    showAsync = true
                }
            }
            .padding(20)

            UPModal(show: $showConfirm,
                    title: "提示",
                    content: "确定要执行此操作吗？",
                    showCancelButton: true,
                    onConfirm: {
                        UPToast.show(message: "已确认", type: "success")
                    },
                    onCancel: {
                        UPToast.show(message: "已取消", type: "default")
                    })

            UPModal(show: $showAsync,
                    title: "异步操作",
                    content: "确认后按钮进入 loading 状态，请在回调完成后手动修改 show。",
                    showCancelButton: true,
                    asyncClose: true,
                    onConfirm: {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            showAsync = false
                            UPToast.show(message: "异步操作完成", type: "success")
                        }
                    })
        }
        .navigationTitle("Modal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
