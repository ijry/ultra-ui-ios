import SwiftUI
import UltraUI

@main
struct UltraUIDemoApp: App {
    init() {
        UltraUI.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay { UPToastView() }
        }
    }
}
