import SwiftUI
import UltraUI

struct PopupDemoView: View {
    @State private var showPopup = false
    @State private var mode = "bottom"

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("通过 mode 控制弹出方向")
                        .foregroundStyle(.secondary)
                    Picker("方向", selection: $mode) {
                        Text("Bottom").tag("bottom")
                        Text("Top").tag("top")
                        Text("Left").tag("left")
                        Text("Right").tag("right")
                        Text("Center").tag("center")
                    }
                    .pickerStyle(.segmented)
                    UPButton(type: "primary", text: "打开 \(mode) Popup") {
                        showPopup = true
                    }
                }
                .padding(20)
            }

            UPPopup(show: $showPopup,
                    mode: mode,
                    closeable: true,
                    closeOnClickOverlay: true) {
                VStack(spacing: 14) {
                    Text("u-popup")
                        .font(.headline)
                    Text("当前弹出方向：\(mode)")
                        .foregroundStyle(.secondary)
                    UPButton(type: "primary", text: "关闭") {
                        showPopup = false
                    }
                }
                .padding(24)
                .frame(maxWidth: mode == "center" ? 280 : nil)
            }
        }
        .navigationTitle("Popup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
