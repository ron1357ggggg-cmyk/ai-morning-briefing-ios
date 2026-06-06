import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("晨報", systemImage: "sun.max.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
        .tint(.pink)
    }
}
