import SwiftUI

struct HomeView: View {
    var body: some View {
        List {
            Section("基础") {
                NavigationLink("Button") { ButtonDemoView() }
                NavigationLink("Icon") { IconDemoView() }
                NavigationLink("Line / Gap / Loading / Overlay") { MiscDemoView() }
            }
            Section("反馈") {
                NavigationLink("Popup") { PopupDemoView() }
                NavigationLink("Modal") { ModalDemoView() }
                NavigationLink("Toast") { ToastDemoView() }
            }
        }
        .navigationTitle("UltraUI Demo")
    }
}
