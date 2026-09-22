#if canImport(UltraUIDemo)
import SwiftUI
import XCTest
@testable import UltraUIDemo

@MainActor
final class DemoRouteContractTests: XCTestCase {
    private let approvedSlugs = [
        "actionSheet",
        "agreement",
        "alert",
        "avatar",
        "backtop",
        "barcode",
        "box",
        "card",
        "list",
        "virtualList",
        "progress",
        "table",
        "table2",
        "countDown",
        "countTo",
        "tooltip",
        "guide",
        "popover",
        "noticeBar",
        "notify",
        "swipeAction",
        "collapse",
        "copy",
        "floatButton",
        "pullRefresh",
        "signature",
        "scrollList",
        "noNetwork",
        "grid",
        "swiper",
        "skeleton",
        "sticky",
        "waterfall",
        "divider",
        "cateTab",
        "title",
        "shortVideo",
        "dropdown",
        "tabbar",
        "navbar",
        "navbarMini",
        "tabs",
        "subsection",
        "indexList",
        "steps",
        "empty",
        "pagination",
        "tree",
        "parse",
        "markdown",
        "codeInput",
        "dragsort",
        "cropper",
        "loadmore",
        "readMore",
        "lazyLoad",
        "link",
        "transition",
        "qrcode",
        "coupon",
        "colorPicker",
        "poster",
        "goodsSku",
        "cityLocate",
        "pdfReader",
        "novelReader"
    ]

    func testApprovedEntriesExistInCatalog() {
        let catalogSlugs = Set(DemoCatalog.allEntries.map(\.slug))

        for slug in approvedSlugs {
            XCTAssertTrue(catalogSlugs.contains(slug), "Missing catalog entry for \(slug)")
        }
    }

    func testApprovedSlugsHaveDedicatedRoutes() {
        for slug in approvedSlugs {
            XCTAssertTrue(
                DemoComponentPage.implementedSlugs.contains(slug),
                "Missing dedicated route for \(slug)"
            )
        }
    }

    func testApprovedPageTypesCanBeConstructed() {
        let pages: [AnyView] = [
            AnyView(ActionSheetDemoView()),
            AnyView(AgreementDemoView()),
            AnyView(AlertDemoView()),
            AnyView(AvatarDemoView()),
            AnyView(BackTopDemoView()),
            AnyView(BarcodeDemoView()),
            AnyView(BoxDemoView()),
            AnyView(CardDemoView()),
            AnyView(ListDemoView()),
            AnyView(VirtualListDemoView()),
            AnyView(ProgressDemoView()),
            AnyView(TableDemoView()),
            AnyView(Table2DemoView()),
            AnyView(CountDownDemoView()),
            AnyView(CountToDemoView()),
            AnyView(TooltipDemoView()),
            AnyView(GuideDemoView()),
            AnyView(PopoverDemoView()),
            AnyView(NoticeBarDemoView()),
            AnyView(NotifyDemoView()),
            AnyView(SwipeActionDemoView()),
            AnyView(CollapseDemoView()),
            AnyView(CopyDemoView()),
            AnyView(FloatButtonDemoView()),
            AnyView(PullRefreshDemoView()),
            AnyView(SignatureDemoView()),
            AnyView(ScrollListDemoView()),
            AnyView(NoNetworkDemoView()),
            AnyView(GridDemoView()),
            AnyView(SwiperDemoView()),
            AnyView(SkeletonDemoView()),
            AnyView(StickyDemoView()),
            AnyView(WaterfallDemoView()),
            AnyView(DividerDemoView()),
            AnyView(CateTabDemoView()),
            AnyView(TitleDemoView()),
            AnyView(ShortVideoDemoView()),
            AnyView(DropdownDemoView()),
            AnyView(TabbarDemoView()),
            AnyView(NavbarDemoView()),
            AnyView(NavbarMiniDemoView()),
            AnyView(TabsDemoView()),
            AnyView(SubsectionDemoView()),
            AnyView(IndexListDemoView()),
            AnyView(StepsDemoView()),
            AnyView(EmptyDemoView()),
            AnyView(PaginationDemoView()),
            AnyView(TreeDemoView()),
            AnyView(ParseDemoView()),
            AnyView(MarkdownDemoView()),
            AnyView(CodeInputDemoView()),
            AnyView(DragsortDemoView()),
            AnyView(CropperDemoView()),
            AnyView(LoadmoreDemoView()),
            AnyView(ReadMoreDemoView()),
            AnyView(LazyLoadDemoView()),
            AnyView(LinkDemoView()),
            AnyView(TransitionDemoView()),
            AnyView(QrcodeDemoView()),
            AnyView(CouponDemoView()),
            AnyView(ColorPickerDemoView()),
            AnyView(PosterDemoView()),
            AnyView(GoodsSkuDemoView()),
            AnyView(CityLocateDemoView()),
            AnyView(PdfReaderDemoView()),
            AnyView(NovelReaderDemoView())
        ]

        XCTAssertEqual(pages.count, approvedSlugs.count)
    }
}
#endif
