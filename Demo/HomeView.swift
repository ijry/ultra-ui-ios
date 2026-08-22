import SwiftUI

/// 上游示例首页：按 `components.config.js` 的 7 个分组、103 项逐条列出，
/// 每行左侧是与上游同名的 PNG 图标，右侧箭头进入该组件的单独页面。
struct HomeView: View {
    var body: some View {
        List {
            ForEach(DemoCatalog.groups) { group in
                Section {
                    ForEach(group.list) { entry in
                        NavigationLink {
                            DemoComponentPage(entry: entry)
                        } label: {
                            DemoCatalogRow(entry: entry)
                        }
                    }
                } header: {
                    Text(group.name)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("UltraUI Demo")
    }
}

/// 上游每行是「图标 + 中文标题（含组件名）」，标题里已带英文，
/// 所以这里不再额外重复 `titleEn`。
private struct DemoCatalogRow: View {
    let entry: DemoComponentEntry

    var body: some View {
        HStack(spacing: 12) {
            DemoIcon(name: entry.icon)
            Text(entry.title)
        }
    }
}
