import SwiftUI
import UIKit

@main
struct SPSCRMApp: App {
    @State private var auth = AuthViewModel()

    init() {
        AppSettings.registerDefaults()
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(SPSTheme.cream)
        nav.titleTextAttributes = [.foregroundColor: UIColor(SPSTheme.ink)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(SPSTheme.primary)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(SPSTheme.primary)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .tint(SPSTheme.primary)
        }
    }
}
