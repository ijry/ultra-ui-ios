import SwiftUI
import UltraUI

struct ButtonDemoView: View {
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionTitle("主题类型")
                UPButton(type: "primary", size: "large", text: "主按钮")
                UPButton(type: "success", text: "成功")
                UPButton(type: "error", text: "错误")
                UPButton(type: "warning", text: "警告")
                UPButton(type: "info", text: "信息")

                sectionTitle("形状和状态")
                UPButton(type: "primary", shape: "circle", text: "胶囊按钮")
                UPButton(type: "primary", plain: true, text: "镂空按钮")
                UPButton(type: "primary", disabled: true, text: "禁用按钮")
                UPButton(type: "primary", loading: loading, loadingText: "加载中", text: "模拟加载")
                    .onTap {
                        Task { @MainActor in
                            loading = true
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            loading = false
                        }
                    }

                sectionTitle("尺寸和图标")
                HStack(spacing: 12) {
                    UPButton(type: "primary", size: "small", text: "Small")
                    UPButton(type: "primary", size: "mini", text: "Mini")
                }
                UPButton(type: "primary", text: "带图标的按钮", icon: "uicon-checkmark")
                    .onTap { UPToast.show(message: "点击了按钮", type: "success") }
            }
            .padding(20)
        }
        .navigationTitle("Button")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}
