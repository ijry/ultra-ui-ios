import SwiftUI

/// 上游首页 `getIcon` 把 `icon` 字段拼成 `/static/uview/demo/<icon>.png`。
/// 这里对应 `Demo/Resources/DemoIcons` 下的同名 PNG。
struct DemoIcon: View {
    let name: String

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
        } else {
            // 上游 components.config.js 里的 `file-text`（novelReader 一项）
            // 在上游 static/uview/demo/ 下并无对应 PNG，其首页该行图标同样为空。
            // 这里用系统图标兜底，以免整行塌成空白。
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
        }
    }
}
