import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/readMore/readMore`。
@MainActor
struct ReadMoreDemoView: View {
    /// 与上游同页一致的《琵琶行》全文，用 `<p>` 包裹后交给 UPParse。
    private static let content = """
    <p>浔阳江头夜送客，枫叶荻花秋瑟瑟。主人下马客在船，举酒欲饮无管弦。醉不成欢惨将别，别时茫茫江浸月。\
    忽闻水上琵琶声，主人忘归客不发。寻声暗问弹者谁，琵琶声停欲语迟。移船相近邀相见，添酒回灯重开宴。千呼万唤始出来，犹抱琵琶半遮面。\
    转轴拨弦三两声，未成曲调先有情。弦弦掩抑声声思，似诉平生不得志。低眉信手续续弹，说尽心中无限事。轻拢慢捻抹复挑，初为《霓裳》后《六幺》。\
    大弦嘈嘈如急雨，小弦切切如私语。嘈嘈切切错杂弹，大珠小珠落玉盘。间关莺语花底滑，幽咽泉流冰下难。冰泉冷涩弦凝绝，凝绝不通声暂歇。\
    别有幽愁暗恨生，此时无声胜有声。银瓶乍破水浆迸，铁骑突出刀枪鸣。曲终收拨当心画，四弦一声如裂帛。东船西舫悄无言，唯见江心秋月白。\
    沉吟放拨插弦中，整顿衣裳起敛容。自言本是京城女，家在虾蟆陵下住。十三学得琵琶成，名属教坊第一部。曲罢曾教善才服，妆成每被秋娘妒。\
    五陵年少争缠头，一曲红绡不知数。钿头银篦击节碎，血色罗裙翻酒污。今年欢笑复明年，秋月春风等闲度。弟走从军阿姨死，暮去朝来颜色故。\
    门前冷落鞍马稀，老大嫁作商人妇。商人重利轻别离，前月浮梁买茶去。去来江口守空船，绕船月明江水寒。夜深忽梦少年事，梦啼妆泪红阑干。\
    我闻琵琶已叹息，又闻此语重唧唧。同是天涯沦落人，相逢何必曾相识！我从去年辞帝京，谪居卧病浔阳城。浔阳地僻无音乐，终岁不闻丝竹声。\
    住近湓江地低湿，黄芦苦竹绕宅生。其间旦暮闻何物？杜鹃啼血猿哀鸣。春江花朝秋月夜，往往取酒还独倾。岂无山歌与村笛？呕哑嘲哳难为听。\
    今夜闻君琵琶语，如听仙乐耳暂明。莫辞更坐弹一曲，为君翻作《琵琶行》。感我此言良久立，却坐促弦弦转急。凄凄不似向前声，满座重闻皆掩泣。\
    座中泣下谁最多？江州司马青衫湿。</p>
    """

    /// 上游用 tag-style 给 `<p>` 上色和设置行高，原生改由内容视图自己带修饰符。
    private static var poem: AnyView {
        AnyView(
            UPParse(containerStyle: UPStyle(["font-size": "15", "color": "#606266"]),
                    content: ReadMoreDemoView.content,
                    selectable: true)
                .lineSpacing(6)
        )
    }

    /// 上游同页传 `:showHeight="200"` 与 `toggle`。
    @State private var readMore = UPReadMore(lines: 5, showHeight: 200, toggle: true, name: "poem") {
        ReadMoreDemoView.poem
    }
    @State private var noToggle = UPReadMore(lines: 3, showToggle: false) { ReadMoreDemoView.poem }
    @State private var styled = UPReadMore(lines: 4,
                                          showHeight: 120,
                                          toggle: true,
                                          closeText: "查看全文",
                                          openText: "收起全文",
                                          color: "#3c9cff",
                                          fontSize: 16,
                                          shadowStyle: UPStyle([
                                              "background": "#f8f8f8",
                                              "paddingTop": "60px",
                                              "marginTop": "-60px"
                                          ]),
                                          textIndent: "1em",
                                          name: 2) {
        ReadMoreDemoView.poem
    }
    @State private var eventLog = "尚未触发"
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                readMore
                    .id(tick)

                tip(readMore.isExpanded ? "当前状态：已展开（收起后限制 5 行 / \(Int(readMore.showHeight))px）" : "当前状态：已收起（lines = 5，showHeight = \(Int(readMore.showHeight))）")
                tip("最近事件：\(eventLog)")
            }

            DemoSection("外部控制展开与收起") {
                HStack(spacing: 10) {
                    UPButton(type: "primary", size: "mini", text: "toggle") {
                        readMore.toggleReadMore()
                        tick += 1
                    }

                    UPButton(type: "success", size: "mini", text: "expand") {
                        readMore.expand()
                        tick += 1
                    }

                    UPButton(type: "warning", size: "mini", text: "collapse") {
                        readMore.collapse()
                        tick += 1
                    }
                }

                tip("expand / collapse 只在状态确实变化时才回调 onChange，重复点击同一个按钮不会重复触发。")
            }

            DemoSection("提示文字与遮罩样式") {
                styled
                    .id(tick)

                tip("color / fontSize 控制提示文字与箭头（当前 \(styled.color) · \(Int(styled.fontSize))px，图标固定 fontSize + 2 = \(Int(styled.toggleIconSize))px，图标名随状态切换为 \(styled.toggleIconName)）。")
                tip("shadowStyle 的 background 决定渐变落地色（\(styled.shadowFadeColor)），paddingTop 决定遮罩高度（\(Int(styled.shadowFadeHeight))px），展开后遮罩自动消失。")
                tip("textIndent 支持 em / px，当前 \(styled.textIndent) 换算为 \(Int(styled.textIndentLength))pt 的首行缩进。")
            }

            DemoSection("隐藏内置按钮") {
                noToggle
                    .id(tick)

                tip("showToggle=false 时组件不再渲染「展开阅读全文 / 收起」按钮，只能由外部调用 toggle / expand / collapse。")
                tip("上游的 toggle=false 是另一层含义：点开一次后隐藏「收起」按钮，本页基础用法传了 toggle=true 所以按钮常驻。")

                UPButton(size: "mini", text: noToggle.isExpanded ? "外部收起" : "外部展开") {
                    noToggle.toggleReadMore()
                    tick += 1
                }
            }

            DemoSection("当前原生范围") {
                Text("原生 UPReadMore 已覆盖上游 9 个 prop：showHeight / toggle / closeText / openText / color / fontSize / shadowStyle / textIndent / name，并额外用 lines 同时限制折叠后的行数（上游只按高度截断）。事件为 onOpen((String) -> Void) / onClose((String) -> Void)（参数即 name，与上游 $emit(status, name) 一致）外加原生的 onChange((Bool) -> Void)。shadowStyle 只取用 background / backgroundImage 的落地色与 paddingTop 高度，上游 CSS linear-gradient 的角度与色标停靠点不解析。没有 init() 重新测量高度的方法：原生用 frame(maxHeight:) 截断，内容变化后不需要重新测量，因此上游 UPParse @load 后手动 init() 的写法在这里不需要。组件用私有 class 保存展开状态，外部读 isExpanded 不会自动触发刷新，所以本页用 tick + .id(tick) 让 SwiftUI 重新求值。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        readMore = readMore
            .onOpen { name in eventLog = "open · name=\(name)" }
            .onClose { name in eventLog = "close · name=\(name)" }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
