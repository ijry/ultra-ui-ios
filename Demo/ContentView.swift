import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            #if DEBUG
            // 开发期直接跳到某个组件页，便于截图核对单页渲染，
            // 例如 `xcrun simctl launch <device> <bundle> --UP_DEMO_SLUG tag`。
            if let slug = ProcessInfo.processInfo.environment["UP_DEMO_SLUG"],
               let entry = DemoCatalog.allEntries.first(where: { $0.slug == slug }) {
                DemoComponentPage(entry: entry)
            } else {
                HomeView()
            }
            #else
            HomeView()
            #endif
        }
    }
}
