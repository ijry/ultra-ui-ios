import SwiftUI
import UltraUI

struct IconDemoView: View {
    private let icons = [
        "uicon-home", "uicon-search", "uicon-calendar", "uicon-plus",
        "uicon-checkmark", "uicon-close", "uicon-info-circle", "uicon-setting",
        "uicon-heart", "uicon-camera", "uicon-bell", "uicon-star"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 4)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(icons, id: \.self) { icon in
                    VStack(spacing: 8) {
                        UPIcon(name: icon, color: "primary", size: "30px")
                        Text(icon.replacingOccurrences(of: "uicon-", with: ""))
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
