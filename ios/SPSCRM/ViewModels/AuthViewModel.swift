import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    private(set) var user: User?
    private(set) var isRestoring = true
    var isSubmitting = false
    var errorMessage: String?

    let settings: AppSettings
    let api: APIClient

    var isLoggedIn: Bool { user != nil }

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        let client = APIClient(
            baseURL: { settings.baseURL },
            token: { KeychainStore.token }
        )
        self.api = client
        client.onUnauthorized = { [weak self] in
            Task { @MainActor in
                self?.handleUnauthorized()
            }
        }
    }

    func restoreSession() async {
        isRestoring = true
        defer { isRestoring = false }
        guard KeychainStore.token != nil else {
            user = nil
            return
        }
        if let cached = KeychainStore.storedUser {
            user = cached
        }
        do {
            let me = try await api.me()
            user = me
            KeychainStore.storedUser = me
        } catch {
            KeychainStore.clearSession()
            user = nil
        }
    }

    func login(email: String, password: String) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let res = try await api.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            KeychainStore.token = res.accessToken
            KeychainStore.storedUser = res.user
            user = res.user
        } catch {
            KeychainStore.clearSession()
            user = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func logout() {
        KeychainStore.clearSession()
        user = nil
        errorMessage = nil
    }

    func handleUnauthorized() {
        KeychainStore.clearSession()
        user = nil
    }
}
