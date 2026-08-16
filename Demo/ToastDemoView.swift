import SwiftUI
import UltraUI

struct ToastDemoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                UPButton(type: "primary", text: "默认 Toast") {
                    UPToast.show(message: "这是一条默认消息")
                }
                UPButton(type: "success", text: "成功 Toast") {
                    UPToast.show(message: "操作成功", type: "success")
                }
                UPButton(type: "error", text: "错误 Toast") {
                    UPToast.show(message: "操作失败", type: "error")
                }
                UPButton(type: "warning", text: "警告 Toast") {
                    UPToast.show(message: "请检查输入内容", type: "warning")
                }
                UPButton(type: "info", text: "Loading Toast") {
                    UPToast.show(message: "正在加载…", type: "loading", duration: 1_800)
                }
                UPButton(type: "primary", plain: true, text: "顶部 Toast") {
                    UPToast.show(message: "顶部提示", type: "success", position: "top")
                }
                UPButton(type: "primary", plain: true, text: "底部 Toast") {
                    UPToast.show(message: "底部提示", type: "success", position: "bottom")
                }
            }
            .padding(20)
        }
        .navigationTitle("Toast")
        .navigationBarTitleDisplayMode(.inline)
    }
}
