import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                MembersListView()
            }
            .tabItem { Label("Members", systemImage: "person.2.fill") }

            NavigationStack {
                DealsListView()
            }
            .tabItem { Label("Deals", systemImage: "briefcase.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .toolbarBackground(SPSTheme.cream, for: .tabBar)
    }
}
