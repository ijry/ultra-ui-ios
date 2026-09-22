import SwiftUI

/// 对应上游 `.up-color-picker__content`：分段切换、渐变轨道与方向、饱和度方块、
/// 色相与透明度条、常用色板、预览与两个按钮。
@MainActor
struct UPColorPickerPanel: View {
    let picker: UPColorPicker
    @Environment(\.upTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            Text("选择颜色")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.main)

            UPSubsection(list: ["纯色", "渐变"],
                         current: picker.colorTypeIndex,
                         fontSize: 14)
                .onChange { picker.changeColorType($0) }

            if picker.colorTypeIndex == 1 { gradientSection }

            solidSection

            if !picker.commonColors.isEmpty { commonSection }

            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 渐变

    private var gradientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            gradientTrack

            HStack(spacing: 12) {
                UPButton(type: "primary", size: "mini", plain: true, text: "添加颜色") {
                    picker.addStop()
                }

                if picker.stops.count > UPColorPicker.minStops,
                   picker.stops.indices.contains(picker.editingStopIndex) {
                    UPButton(size: "mini", plain: true, text: "删除节点") {
                        picker.removeStop(picker.editingStopIndex)
                    }
                }
            }

            // 上游是一个圆形方向盘（拖动取角度），原生换成八个方向按钮。
            VStack(alignment: .leading, spacing: 6) {
                Text("方向：\(picker.direction.label)")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.content)

                UPAlbumWrapLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(UPColorPickerDirection.allCases, id: \.self) { item in
                        Text(item.label)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .foregroundStyle(item == picker.direction ? Color.white : theme.content)
                            .background(item == picker.direction ? theme.primary : theme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .contentShape(Rectangle())
                            .onTapGesture { picker.setDirection(item) }
                    }
                }
            }
        }
    }

    private var gradientTrack: some View {
        LinearGradient(colors: picker.stops.map { UPColor.parse($0.color, theme: theme) },
                       startPoint: picker.direction.unitPoints.start,
                       endPoint: picker.direction.unitPoints.end)
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(alignment: .leading) { pointers }
    }

    private var pointers: some View {
        GeometryReader { proxy in
            ForEach(Array(picker.stops.enumerated()), id: \.offset) { index, stop in
                Circle()
                    .fill(UPColor.parse(stop.color, theme: theme))
                    .frame(width: 16, height: 16)
                    .overlay { Circle().strokeBorder(Color.white, lineWidth: 2) }
                    .position(x: CGFloat(stop.percent) * proxy.size.width, y: proxy.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                picker.moveStop(index, percent: value.location.x / max(proxy.size.width, 1))
                            }
                    )
                    .onTapGesture { picker.editStop(index) }
            }
        }
    }

    // MARK: - 纯色

    private var solidSection: some View {
        VStack(spacing: 15) {
            saturationBox
            hueBar
            if picker.colorTypeIndex == 0 { alphaBar }
        }
    }

    /// 上游用两层 `linear-gradient` 叠出饱和度（横）与明度（纵）。
    private var saturationBox: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color(hue: picker.hue / 360, saturation: 1, brightness: 1)
                LinearGradient(colors: [.white, .white.opacity(0)],
                               startPoint: .leading,
                               endPoint: .trailing)
                LinearGradient(colors: [.black.opacity(0), .black],
                               startPoint: .top,
                               endPoint: .bottom)

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .position(x: CGFloat(picker.saturation / 100) * proxy.size.width,
                              y: CGFloat(1 - picker.lightness / 100) * proxy.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        picker.setSaturationPoint(value.location, in: proxy.size)
                    }
            )
        }
        .frame(height: UPColorPicker.saturationHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var hueBar: some View {
        GeometryReader { proxy in
            LinearGradient(colors: (0...6).map { Color(hue: Double($0) / 6, saturation: 1, brightness: 1) },
                           startPoint: .leading,
                           endPoint: .trailing)
                .overlay(alignment: .leading) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .offset(x: CGFloat(picker.hue / 360) * proxy.size.width - 7)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            picker.setHue(Double(value.location.x / max(proxy.size.width, 1)) * 360)
                        }
                )
        }
        .frame(height: 16)
        .clipShape(Capsule())
    }

    private var alphaBar: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [UPColor.parse(picker.currentColor, theme: theme).opacity(0),
                                    UPColor.parse(picker.currentColor, theme: theme)],
                           startPoint: .leading,
                           endPoint: .trailing)
                .overlay(alignment: .leading) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .offset(x: CGFloat(picker.alpha) * proxy.size.width - 7)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            picker.setAlpha(Double(value.location.x / max(proxy.size.width, 1)))
                        }
                )
        }
        .frame(height: 16)
        .background(theme.bg)
        .clipShape(Capsule())
    }

    // MARK: - 常用色与底部

    private var commonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("常用颜色")
                .font(.system(size: 13))
                .foregroundStyle(theme.content)

            UPAlbumWrapLayout(spacing: 8, lineSpacing: 8) {
                ForEach(picker.commonColors, id: \.self) { value in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(UPColor.parse(value, theme: theme))
                        .frame(width: 28, height: 28)
                        .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(theme.border, lineWidth: 1) }
                        .contentShape(Rectangle())
                        .onTapGesture { picker.selectCommonColor(value) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            preview
            Spacer(minLength: 0)
            UPButton(size: "small", plain: true, text: "取消") { picker.close() }
            UPButton(type: "primary", size: "small", text: "确定") { picker.confirm() }
        }
    }

    private var preview: some View {
        HStack(spacing: 8) {
            if picker.colorTypeIndex == 1 {
                LinearGradient(colors: picker.stops.map { UPColor.parse($0.color, theme: theme) },
                               startPoint: picker.direction.unitPoints.start,
                               endPoint: picker.direction.unitPoints.end)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(UPColor.parse(picker.displayColor, theme: theme))
                    .frame(width: 28, height: 28)
            }

            Text(picker.displayColor)
                .font(.system(size: 12))
                .foregroundStyle(theme.content)
                .lineLimit(1)
        }
    }
}
