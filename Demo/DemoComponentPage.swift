import SwiftUI

/// 按上游 slug 把每一项分发到它自己的页面。
///
/// 上游是一个组件一个 `.vue` 页面，这里对应一个 `slug` 一个 SwiftUI 视图。
/// 尚未逐页对齐的条目显示明确的待建状态，而不是渲染一个看起来像完成品的空页
/// —— 否则很难分辨「这页做完了」和「这页还没做」。
struct DemoComponentPage: View {
    let entry: DemoComponentEntry

    /// 页面已经有专属 SwiftUI Demo 的 slug，供路由契约测试复用。
    static let implementedSlugs: Set<String> = [
        "color", "icon", "image", "button", "text", "layout", "cell", "badge",
        "tag", "loading-icon", "loading-page", "form", "input", "textarea", "search",
        "numberBox", "code", "rate", "switch", "slider", "checkbox", "radio", "picker",
        "datetimePicker", "select", "cascader", "choose", "calendar", "keyboard", "upload",
        "album", "popup", "modal", "toast", "line", "overlay", "gap", "actionSheet",
        "agreement", "alert", "avatar", "backtop", "barcode", "box", "card", "list",
        "virtualList", "progress", "table", "table2", "countDown", "countTo",
        "tooltip", "guide", "popover", "noticeBar", "notify", "swipeAction", "collapse",
        "copy", "floatButton", "pullRefresh", "signature", "scrollList", "noNetwork",
        "grid", "swiper", "skeleton", "sticky", "waterfall", "divider", "cateTab",
        "title", "shortVideo", "dropdown", "tabbar", "navbar", "navbarMini", "tabs",
        "subsection", "indexList", "steps", "empty", "pagination", "tree",
        "parse", "markdown", "codeInput", "dragsort", "cropper", "loadmore",
        "readMore", "lazyLoad", "link", "transition", "qrcode", "coupon",
        "colorPicker", "poster", "goodsSku", "cityLocate", "pdfReader", "novelReader"
    ]

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
        case "calendar": CalendarDemoView()
        case "keyboard": KeyboardDemoView()
        case "upload": UploadDemoView()
        case "album": AlbumDemoView()
        // 反馈组件
        case "actionSheet": ActionSheetDemoView()
        case "agreement": AgreementDemoView()
        case "alert": AlertDemoView()
        case "popup": PopupDemoView()
        case "modal": ModalDemoView()
        case "toast": ToastDemoView()
        case "tooltip": TooltipDemoView()
        case "guide": GuideDemoView()
        case "popover": PopoverDemoView()
        case "noticeBar": NoticeBarDemoView()
        case "notify": NotifyDemoView()
        case "swipeAction": SwipeActionDemoView()
        case "collapse": CollapseDemoView()
        case "copy": CopyDemoView()
        case "floatButton": FloatButtonDemoView()
        case "pullRefresh": PullRefreshDemoView()
        case "signature": SignatureDemoView()
        // 布局组件
        case "box": BoxDemoView()
        case "card": CardDemoView()
        case "line": LineDemoView()
        case "overlay": OverlayDemoView()
        case "scrollList": ScrollListDemoView()
        case "noNetwork": NoNetworkDemoView()
        case "grid": GridDemoView()
        case "swiper": SwiperDemoView()
        case "skeleton": SkeletonDemoView()
        case "sticky": StickyDemoView()
        case "waterfall": WaterfallDemoView()
        case "divider": DividerDemoView()
        case "cateTab": CateTabDemoView()
        case "title": TitleDemoView()
        case "shortVideo": ShortVideoDemoView()
        // 导航组件
        case "dropdown": DropdownDemoView()
        case "tabbar": TabbarDemoView()
        case "navbar": NavbarDemoView()
        case "navbarMini": NavbarMiniDemoView()
        case "tabs": TabsDemoView()
        case "subsection": SubsectionDemoView()
        case "indexList": IndexListDemoView()
        case "steps": StepsDemoView()
        case "empty": EmptyDemoView()
        case "pagination": PaginationDemoView()
        case "tree": TreeDemoView()
        // 数据组件
        case "list": ListDemoView()
        case "virtualList": VirtualListDemoView()
        case "progress": ProgressDemoView()
        case "table": TableDemoView()
        case "table2": Table2DemoView()
        case "countDown": CountDownDemoView()
        case "countTo": CountToDemoView()
        // 其他组件
        case "gap": GapDemoView()
        case "avatar": AvatarDemoView()
        case "backtop": BackTopDemoView()
        case "barcode": BarcodeDemoView()
        case "parse": ParseDemoView()
        case "markdown": MarkdownDemoView()
        case "codeInput": CodeInputDemoView()
        case "dragsort": DragsortDemoView()
        case "cropper": CropperDemoView()
        case "loadmore": LoadmoreDemoView()
        case "readMore": ReadMoreDemoView()
        case "lazyLoad": LazyLoadDemoView()
        case "link": LinkDemoView()
        case "transition": TransitionDemoView()
        case "qrcode": QrcodeDemoView()
        case "coupon": CouponDemoView()
        case "colorPicker": ColorPickerDemoView()
        case "poster": PosterDemoView()
        case "goodsSku": GoodsSkuDemoView()
        case "cityLocate": CityLocateDemoView()
        case "pdfReader": PdfReaderDemoView()
        case "novelReader": NovelReaderDemoView()
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
