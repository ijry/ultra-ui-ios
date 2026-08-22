import SwiftUI

/// 上游 `pages/example/components.config.js` 的逐项映射。
/// 分组、顺序、图标名与中英文标题均与上游一致，便于逐页对照。
struct DemoComponentEntry: Identifiable, Hashable {
    /// 上游 path 末段，用作稳定标识与页面路由 key。
    let slug: String
    /// 上游 icon 字段，对应 Demo/Resources/DemoIcons 下的同名 PNG。
    let icon: String
    let title: String
    let titleEn: String
    /// 上游页面路径，保留以便与上游示例逐项核对。
    let upstreamPath: String

    var id: String { upstreamPath }
}

struct DemoComponentGroup: Identifiable, Hashable {
    let name: String
    let nameEn: String
    let list: [DemoComponentEntry]

    var id: String { name }
}

enum DemoCatalog {
    /// 7 个分组、103 项，与上游 components.config.js 完全对应。
    static let groups: [DemoComponentGroup] = [
        DemoComponentGroup(
            name: "基础组件",
            nameEn: "Basic components",
            list: [
                DemoComponentEntry(slug: "color", icon: "color", title: "Color 色彩", titleEn: "Color", upstreamPath: "/pages/componentsB/color/color"),
                DemoComponentEntry(slug: "icon", icon: "icon", title: "Icon 图标", titleEn: "Icon", upstreamPath: "/pages/componentsA/icon/icon"),
                DemoComponentEntry(slug: "image", icon: "image", title: "Image 图片", titleEn: "Image", upstreamPath: "/pages/componentsA/image/image"),
                DemoComponentEntry(slug: "button", icon: "button", title: "Button 按钮", titleEn: "Button", upstreamPath: "/pages/componentsA/button/button"),
                DemoComponentEntry(slug: "text", icon: "text", title: "Text 文本", titleEn: "Text", upstreamPath: "/pages/componentsC/text/text"),
                DemoComponentEntry(slug: "layout", icon: "layout", title: "Layout 布局", titleEn: "Layout", upstreamPath: "/pages/componentsC/layout/layout"),
                DemoComponentEntry(slug: "cell", icon: "cell", title: "Cell 单元格", titleEn: "Cell", upstreamPath: "/pages/componentsA/cell/cell"),
                DemoComponentEntry(slug: "badge", icon: "badge", title: "Badge 徽标数", titleEn: "Badge", upstreamPath: "/pages/componentsB/badge/badge"),
                DemoComponentEntry(slug: "tag", icon: "tag", title: "Tag 标签", titleEn: "Tag", upstreamPath: "/pages/componentsB/tag/tag"),
                DemoComponentEntry(slug: "loading-icon", icon: "loading", title: "Loading 加载动画", titleEn: "loading Icon", upstreamPath: "/pages/componentsA/loading-icon/loading-icon"),
                DemoComponentEntry(slug: "loading-page", icon: "loading-page", title: "Loading page 加载页", titleEn: "Loading Page", upstreamPath: "/pages/componentsA/loading-page/loading-page"),
            ]
        ),
        DemoComponentGroup(
            name: "表单组件",
            nameEn: "Form components",
            list: [
                DemoComponentEntry(slug: "form", icon: "form", title: "Form 表单", titleEn: "Form", upstreamPath: "/pages/componentsC/form/form"),
                DemoComponentEntry(slug: "calendar", icon: "calendar", title: "Calendar 日历", titleEn: "Calendar", upstreamPath: "/pages/componentsC/calendar/calendar"),
                DemoComponentEntry(slug: "keyboard", icon: "keyboard", title: "Keyboard 键盘", titleEn: "Keyboard", upstreamPath: "/pages/componentsB/keyboard/keyboard"),
                DemoComponentEntry(slug: "picker", icon: "picker", title: "Picker 选择器", titleEn: "Picker", upstreamPath: "/pages/componentsC/picker/picker"),
                DemoComponentEntry(slug: "select", icon: "picker", title: "Select 经典下拉框", titleEn: "Picker", upstreamPath: "/pages/componentsD/select/select"),
                DemoComponentEntry(slug: "cascader", icon: "cascader", title: "Cascader 级联选择器", titleEn: "Cascader", upstreamPath: "/pages/componentsD/cascader/cascader"),
                DemoComponentEntry(slug: "choose", icon: "choose", title: "Choose 选项选择器", titleEn: "Choose", upstreamPath: "/pages/componentsD/choose/choose"),
                DemoComponentEntry(slug: "datetimePicker", icon: "datetimePicker", title: "DatetimePicker 时间选择器", titleEn: "Picker", upstreamPath: "/pages/componentsC/datetimePicker/datetimePicker"),
                DemoComponentEntry(slug: "rate", icon: "rate", title: "Rate 评分", titleEn: "Rate", upstreamPath: "/pages/componentsA/rate/rate"),
                DemoComponentEntry(slug: "search", icon: "search", title: "Search 搜索", titleEn: "Search", upstreamPath: "/pages/componentsB/search/search"),
                DemoComponentEntry(slug: "numberBox", icon: "numberBox", title: "NumberBox 步进器", titleEn: "NumberBox", upstreamPath: "/pages/componentsB/numberBox/numberBox"),
                DemoComponentEntry(slug: "upload", icon: "upload", title: "Upload 上传", titleEn: "Upload", upstreamPath: "/pages/componentsB/upload/upload"),
                DemoComponentEntry(slug: "code", icon: "code", title: "Code 验证码倒计时", titleEn: "VerificationCode", upstreamPath: "/pages/componentsB/code/code"),
                DemoComponentEntry(slug: "input", icon: "field", title: "Input 输入框", titleEn: "Input", upstreamPath: "/pages/componentsC/input/input"),
                DemoComponentEntry(slug: "textarea", icon: "textarea", title: "Textarea 文本域", titleEn: "Textarea", upstreamPath: "/pages/componentsC/textarea/textarea"),
                DemoComponentEntry(slug: "checkbox", icon: "checkbox", title: "Checkbox 复选框", titleEn: "Checkbox", upstreamPath: "/pages/componentsA/checkbox/checkbox"),
                DemoComponentEntry(slug: "radio", icon: "radio", title: "Radio 单选框", titleEn: "Radio", upstreamPath: "/pages/componentsA/radio/radio"),
                DemoComponentEntry(slug: "switch", icon: "switch", title: "Switch 开关选择器", titleEn: "Switch", upstreamPath: "/pages/componentsB/switch/switch"),
                DemoComponentEntry(slug: "slider", icon: "slider", title: "Slider 滑动选择器", titleEn: "Slider", upstreamPath: "/pages/componentsB/slider/slider"),
                DemoComponentEntry(slug: "album", icon: "album", title: "Album 相册", titleEn: "Album", upstreamPath: "/pages/componentsC/album/album"),
            ]
        ),
        DemoComponentGroup(
            name: "数据组件",
            nameEn: "Data components",
            list: [
                DemoComponentEntry(slug: "list", icon: "list", title: "List 列表", titleEn: "List", upstreamPath: "/pages/componentsC/list/list"),
                DemoComponentEntry(slug: "virtualList", icon: "virtualList", title: "VirtualList 虚拟列表", titleEn: "virtualList", upstreamPath: "/pages/componentsD/virtualList/virtualList"),
                DemoComponentEntry(slug: "progress", icon: "progress", title: "Progress 进度条", titleEn: "Progress", upstreamPath: "/pages/componentsB/progress/progress"),
                DemoComponentEntry(slug: "table", icon: "table", title: "Table 表格", titleEn: "Table", upstreamPath: "/pages/componentsB/table/table"),
                DemoComponentEntry(slug: "table2", icon: "table", title: "Table2 表格2", titleEn: "Table2", upstreamPath: "/pages/componentsB/table2/table2"),
                DemoComponentEntry(slug: "countDown", icon: "countDown", title: "CountDown 倒计时", titleEn: "CountDown", upstreamPath: "/pages/componentsB/countDown/countDown"),
                DemoComponentEntry(slug: "countTo", icon: "countTo", title: "CountTo 数字滚动", titleEn: "CountTo", upstreamPath: "/pages/componentsB/countTo/countTo"),
            ]
        ),
        DemoComponentGroup(
            name: "反馈组件",
            nameEn: "Feedback components",
            list: [
                DemoComponentEntry(slug: "tooltip", icon: "tooltip", title: "Tooltip 长按提示", titleEn: "ActionSheet", upstreamPath: "/pages/componentsC/tooltip/tooltip"),
                DemoComponentEntry(slug: "guide", icon: "tooltip", title: "Guide 首屏引导", titleEn: "Guide", upstreamPath: "/pages/componentsC/guide/guide"),
                DemoComponentEntry(slug: "popover", icon: "popover", title: "Popover 弹窗提示", titleEn: "Popover", upstreamPath: "/pages/componentsC/popover/popover"),
                DemoComponentEntry(slug: "actionSheet", icon: "actionSheet", title: "ActionSheet 上拉菜单", titleEn: "ActionSheet", upstreamPath: "/pages/componentsB/actionSheet/actionSheet"),
                DemoComponentEntry(slug: "alert", icon: "alert", title: "Alert 警告提示", titleEn: "Alert", upstreamPath: "/pages/componentsB/alert/alert"),
                DemoComponentEntry(slug: "toast", icon: "toast", title: "Toast 消息提示", titleEn: "Toast", upstreamPath: "/pages/componentsB/toast/toast"),
                DemoComponentEntry(slug: "noticeBar", icon: "noticeBar", title: "NoticeBar 滚动通知", titleEn: "NoticeBar", upstreamPath: "/pages/componentsB/noticeBar/noticeBar"),
                DemoComponentEntry(slug: "notify", icon: "notify", title: "Notify 消息提示", titleEn: "Notify", upstreamPath: "/pages/componentsB/notify/notify"),
                DemoComponentEntry(slug: "swipeAction", icon: "swipeAction", title: "SwipeAction 滑动单元格", titleEn: "SwipeAction", upstreamPath: "/pages/componentsA/swipeAction/swipeAction"),
                DemoComponentEntry(slug: "collapse", icon: "collapse", title: "Collapse 折叠面板", titleEn: "Collapse", upstreamPath: "/pages/componentsB/collapse/collapse"),
                DemoComponentEntry(slug: "popup", icon: "popup", title: "Popup 弹出层", titleEn: "Popup", upstreamPath: "/pages/componentsA/popup/popup"),
                DemoComponentEntry(slug: "modal", icon: "modal", title: "Modal 模态框", titleEn: "Modal", upstreamPath: "/pages/componentsC/modal/modal"),
                DemoComponentEntry(slug: "copy", icon: "copy", title: "Copy 复制", titleEn: "Copy", upstreamPath: "/pages/componentsD/copy/copy"),
                DemoComponentEntry(slug: "floatButton", icon: "copy", title: "FloatButton 悬浮按钮", titleEn: "Float Button", upstreamPath: "/pages/componentsD/floatButton/floatButton"),
                DemoComponentEntry(slug: "pullRefresh", icon: "pullRefresh", title: "PullRefresh 下拉刷新", titleEn: "Pull Refresh", upstreamPath: "/pages/componentsD/pullRefresh/pullRefresh"),
                DemoComponentEntry(slug: "signature", icon: "signature", title: "Signature 签名签字", titleEn: "Signature Refresh", upstreamPath: "/pages/componentsD/signature/signature"),
                DemoComponentEntry(slug: "agreement", icon: "agreement", title: "agreement 弹窗协议", titleEn: "Agreement", upstreamPath: "/pages/componentsD/agreement/agreement"),
            ]
        ),
        DemoComponentGroup(
            name: "布局组件",
            nameEn: "Layout components",
            list: [
                DemoComponentEntry(slug: "scrollList", icon: "scrollList", title: "ScrollList 横向滚动列表", titleEn: "ScrollList", upstreamPath: "/pages/componentsC/scrollList/scrollList"),
                DemoComponentEntry(slug: "line", icon: "line", title: "Line 线条", titleEn: "Line", upstreamPath: "/pages/componentsA/line/line"),
                DemoComponentEntry(slug: "card", icon: "empty", title: "Card 卡片", titleEn: "Card", upstreamPath: "/pages/componentsB/card/card"),
                DemoComponentEntry(slug: "overlay", icon: "mask", title: "Overlay 遮罩层", titleEn: "Overlay", upstreamPath: "/pages/componentsA/overlay/overlay"),
                DemoComponentEntry(slug: "noNetwork", icon: "noNetwork", title: "NoNetwork 无网络提示", titleEn: "NoNetwork", upstreamPath: "/pages/componentsC/noNetwork/noNetwork"),
                DemoComponentEntry(slug: "grid", icon: "grid", title: "Grid 宫格布局", titleEn: "Grid", upstreamPath: "/pages/componentsA/grid/grid"),
                DemoComponentEntry(slug: "swiper", icon: "swiper", title: "Swiper 轮播图", titleEn: "Swiper", upstreamPath: "/pages/componentsC/swiper/swiper"),
                DemoComponentEntry(slug: "skeleton", icon: "skeleton", title: "Skeleton 骨架屏", titleEn: "Skeleton", upstreamPath: "/pages/componentsC/skeleton/skeleton"),
                DemoComponentEntry(slug: "sticky", icon: "sticky", title: "Sticky 吸顶", titleEn: "Sticky", upstreamPath: "/pages/componentsA/sticky/sticky"),
                DemoComponentEntry(slug: "waterfall", icon: "waterfall", title: "Waterfall 瀑布流", titleEn: "Waterfall", upstreamPath: "/pages/componentsB/waterfall/waterfall"),
                DemoComponentEntry(slug: "divider", icon: "divider", title: "Divider 分割线", titleEn: "Divider", upstreamPath: "/pages/componentsA/divider/divider"),
                DemoComponentEntry(slug: "box", icon: "box", title: "Box 盒子", titleEn: "Box", upstreamPath: "/pages/componentsD/box/box"),
                DemoComponentEntry(slug: "cateTab", icon: "box", title: "CateTab 垂直TAB", titleEn: "CateTab", upstreamPath: "/pages/componentsD/cateTab/cateTab"),
                DemoComponentEntry(slug: "title", icon: "title", title: "Title 标题", titleEn: "Title", upstreamPath: "/pages/componentsD/title/title"),
                DemoComponentEntry(slug: "shortVideo", icon: "shortVideo", title: "ShortVideo 短视频切换", titleEn: "ShortVideo", upstreamPath: "/pages/componentsD/shortVideo/shortVideo"),
            ]
        ),
        DemoComponentGroup(
            name: "导航组件",
            nameEn: "Navigation components",
            list: [
                DemoComponentEntry(slug: "dropdown", icon: "dropdown", title: "Dropdown 下拉菜单", titleEn: "Dropdown", upstreamPath: "/pages/componentsB/dropdown/dropdown"),
                DemoComponentEntry(slug: "tabbar", icon: "tabbar", title: "Tabbar 底部导航栏", titleEn: "Tabbar", upstreamPath: "/pages/componentsB/tabbar/tabbar"),
                DemoComponentEntry(slug: "backtop", icon: "backTop", title: "BackTop 返回顶部", titleEn: "BackTop", upstreamPath: "/pages/componentsA/backtop/backtop"),
                DemoComponentEntry(slug: "navbar", icon: "navbar", title: "Navbar 导航栏", titleEn: "Navbar", upstreamPath: "/pages/componentsC/navbar/navbar"),
                DemoComponentEntry(slug: "navbarMini", icon: "navbar", title: "NavbarMini 迷你导航栏", titleEn: "Navbar", upstreamPath: "/pages/componentsD/navbarMini/navbarMini"),
                DemoComponentEntry(slug: "tabs", icon: "tabs", title: "Tabs 标签", titleEn: "Tabs", upstreamPath: "/pages/componentsC/tabs/tabs"),
                DemoComponentEntry(slug: "subsection", icon: "subsection", title: "Subsection 分段器", titleEn: "Subsection", upstreamPath: "/pages/componentsC/subsection/subsection"),
                DemoComponentEntry(slug: "indexList", icon: "indexList", title: "IndexList 索引列表", titleEn: "IndexList", upstreamPath: "/pages/componentsC/indexList/indexList"),
                DemoComponentEntry(slug: "steps", icon: "steps", title: "Steps 步骤条", titleEn: "Steps", upstreamPath: "/pages/componentsC/steps/steps"),
                DemoComponentEntry(slug: "empty", icon: "empty", title: "Empty 内容为空", titleEn: "Empty", upstreamPath: "/pages/componentsA/empty/empty"),
                DemoComponentEntry(slug: "pagination", icon: "pagination", title: "Pagination 分页器", titleEn: "Pagination", upstreamPath: "/pages/componentsD/pagination/pagination"),
                DemoComponentEntry(slug: "tree", icon: "tree", title: "Tree 树形", titleEn: "Tree", upstreamPath: "/pages/componentsD/tree/tree"),
            ]
        ),
        DemoComponentGroup(
            name: "其他组件",
            nameEn: "Other components",
            list: [
                DemoComponentEntry(slug: "parse", icon: "parse", title: "Parse 富文本解析器", titleEn: "Parse", upstreamPath: "/pages/componentsB/parse/parse"),
                DemoComponentEntry(slug: "markdown", icon: "markdown", title: "Markdown 解析器", titleEn: "Markdown", upstreamPath: "/pages/componentsD/markdown/markdown"),
                DemoComponentEntry(slug: "codeInput", icon: "messageInput", title: "CodeInput 验证码输入", titleEn: "CodeInput", upstreamPath: "/pages/componentsC/codeInput/codeInput"),
                DemoComponentEntry(slug: "dragsort", icon: "dragsort", title: "Dragsort 拖动排序", titleEn: "Dragsort", upstreamPath: "/pages/componentsD/dragsort/dragsort"),
                DemoComponentEntry(slug: "cropper", icon: "cropper", title: "cropper 图片裁剪", titleEn: "Cropper", upstreamPath: "/pages/componentsD/cropper/cropper"),
                DemoComponentEntry(slug: "loadmore", icon: "loadmore", title: "Loadmore 加载更多", titleEn: "Loadmore", upstreamPath: "/pages/componentsC/loadmore/loadmore"),
                DemoComponentEntry(slug: "readMore", icon: "readMore", title: "ReadMore 展开阅读更多", titleEn: "ReadMore", upstreamPath: "/pages/componentsC/readMore/readMore"),
                DemoComponentEntry(slug: "lazyLoad", icon: "lazyLoad", title: "LazyLoad 懒加载", titleEn: "LazyLoad", upstreamPath: "/pages/componentsA/lazyLoad/lazyLoad"),
                DemoComponentEntry(slug: "gap", icon: "gap", title: "Gap 间隔槽", titleEn: "Gap", upstreamPath: "/pages/componentsA/gap/gap"),
                DemoComponentEntry(slug: "avatar", icon: "avatar", title: "Avatar 头像", titleEn: "Avatar", upstreamPath: "/pages/componentsC/avatar/avatar"),
                DemoComponentEntry(slug: "link", icon: "link", title: "Link 超链接", titleEn: "Link", upstreamPath: "/pages/componentsA/link/link"),
                DemoComponentEntry(slug: "transition", icon: "transition", title: "transition 动画", titleEn: "Transition", upstreamPath: "/pages/componentsA/transition/transition"),
                DemoComponentEntry(slug: "qrcode", icon: "qrcode", title: "Qrcode 二维码", titleEn: "Qrcode", upstreamPath: "/pages/componentsD/qrcode/qrcode"),
                DemoComponentEntry(slug: "coupon", icon: "coupon", title: "Coupon 优惠券", titleEn: "优惠券", upstreamPath: "/pages/componentsD/coupon/coupon"),
                DemoComponentEntry(slug: "barcode", icon: "barcode", title: "Barcode 条码", titleEn: "Barcode", upstreamPath: "/pages/componentsD/barcode/barcode"),
                DemoComponentEntry(slug: "colorPicker", icon: "colorPicker", title: "ColorPicker 颜色选择器", titleEn: "ColorPicker", upstreamPath: "/pages/componentsD/colorPicker/colorPicker"),
                DemoComponentEntry(slug: "poster", icon: "poster", title: "Poster 海报生成", titleEn: "Poster", upstreamPath: "/pages/componentsD/poster/poster"),
                DemoComponentEntry(slug: "goodsSku", icon: "goodsSku", title: "GoodsSku 商品SKU", titleEn: "GoodsSku", upstreamPath: "/pages/componentsD/goodsSku/goodsSku"),
                DemoComponentEntry(slug: "cityLocate", icon: "cityLocate", title: "CityLocate 城市定位", titleEn: "CityLocate", upstreamPath: "/pages/componentsD/cityLocate/cityLocate"),
                DemoComponentEntry(slug: "pdfReader", icon: "pdfReader", title: "PdfReader PDF阅读器", titleEn: "PdfReader", upstreamPath: "/pages/componentsD/pdfReader/pdfReader"),
                DemoComponentEntry(slug: "novelReader", icon: "file-text", title: "NovelReader 小说阅读器", titleEn: "NovelReader", upstreamPath: "/pages/componentsD/novelReader/novelReader"),
            ]
        ),
    ]

    static var allEntries: [DemoComponentEntry] { groups.flatMap(\.list) }
}
