import SwiftUI

struct MainTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            SPSBrandLockup(style: .header, compact: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Divider().background(SPSTheme.border)
                }

            tabRoot
        }
        .background(SPSTheme.cream.ignoresSafeArea())
    }

    private var tabRoot: some View {
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
