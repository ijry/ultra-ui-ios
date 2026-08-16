import SwiftUI
import UltraUI

struct MiscDemoView: View {
    @State private var showOverlay = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Line")
                        .font(.headline)
                    UPLine()
                    UPLine(color: "primary", dashed: true)
                    HStack {
                        Text("vertical")
                        UPLine(color: "error", direction: "col")
                            .frame(height: 30)
                        Text("line")
                    }

                    Text("Gap")
                        .font(.headline)
                    Text("上方有一个 30px 间隔")
                    UPGap(bgColor: "bg", height: 30)
                    Text("Gap 之后")

                    Text("Loading")
                        .font(.headline)
                    HStack(spacing: 24) {
                        UPLoadingIcon(color: "primary", text: "spinner")
                        UPLoadingIcon(color: "success", mode: "circle", text: "circle")
                        UPLoadingIcon(color: "warning", vertical: true, text: "vertical")
                    }

                    UPButton(type: "primary", text: "显示 Overlay") {
                        showOverlay = true
                    }
                }
                .padding(20)
            }

            if showOverlay {
                UPOverlay(show: true) {
                    showOverlay = false
                }
                VStack(spacing: 12) {
                    Text("u-overlay")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("点击遮罩关闭")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .allowsHitTesting(false)
            }
        }
        .navigationTitle("Basic Components")
        .navigationBarTitleDisplayMode(.inline)
    }
}
