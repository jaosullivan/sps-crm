import SwiftUI
import UIKit

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            if auth.isRestoring {
                ZStack {
                    SPSTheme.cream.ignoresSafeArea()
                    VStack(spacing: 12) {
                        ShamrockMark(size: 40, color: SPSTheme.orange)
                        ProgressView()
                            .tint(SPSTheme.primary)
                    }
                }
            } else if auth.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .tint(SPSTheme.primary)
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if let stored = UserDefaults.standard.string(forKey: AppSettings.baseURLKey) {
                auth.settings.baseURLString = AppSettings.normalize(stored)
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}
