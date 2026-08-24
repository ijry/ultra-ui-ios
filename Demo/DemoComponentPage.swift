import SwiftUI

/// 按上游 slug 把每一项分发到它自己的页面。
///
/// 上游是一个组件一个 `.vue` 页面，这里对应一个 `slug` 一个 SwiftUI 视图。
/// 尚未逐页对齐的条目显示明确的待建状态，而不是渲染一个看起来像完成品的空页
/// —— 否则很难分辨「这页做完了」和「这页还没做」。
struct DemoComponentPage: View {
    let entry: DemoComponentEntry

    var body: some View {
        content
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.slug {
        // 基础组件
        case "color": ColorDemoView()
        case "icon": IconDemoView()
        case "image": ImageDemoView()
        case "button": ButtonDemoView()
        case "text": TextDemoView()
        case "layout": LayoutDemoView()
        case "cell": CellDemoView()
        case "badge": BadgeDemoView()
        case "tag": TagDemoView()
        case "loading-icon": LoadingIconDemoView()
        case "loading-page": LoadingPageDemoView()
        // 表单组件
        case "form": FormDemoView()
        case "input": InputDemoView()
        case "textarea": TextareaDemoView()
        case "search": SearchDemoView()
        case "numberBox": NumberBoxDemoView()
        case "code": CodeDemoView()
        case "rate": RateDemoView()
        case "switch": SwitchDemoView()
        case "slider": SliderDemoView()
        case "checkbox": CheckboxDemoView()
        case "radio": RadioDemoView()
        case "picker": PickerDemoView()
        case "datetimePicker": DatetimePickerDemoView()
        case "select": SelectDemoView()
        case "cascader": CascaderDemoView()
        case "choose": ChooseDemoView()
        // 反馈组件
        case "popup": PopupDemoView()
        case "modal": ModalDemoView()
        case "toast": ToastDemoView()
        // 布局组件
        case "line": LineDemoView()
        case "overlay": OverlayDemoView()
        // 其他组件
        case "gap": GapDemoView()
        default: DemoPendingPage(entry: entry)
        }
    }
}

/// 待建页面的占位。写明上游对应路径，方便逐页补齐时定位来源。
private struct DemoPendingPage: View {
    let entry: DemoComponentEntry

    var body: some View {
        VStack(spacing: 12) {
            DemoIcon(name: entry.icon)
                .scaleEffect(2)
                .padding(.bottom, 8)

            Text(entry.title)
                .font(.headline)

            Text("此页尚未逐项对齐上游示例")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(entry.upstreamPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
