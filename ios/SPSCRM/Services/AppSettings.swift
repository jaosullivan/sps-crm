import Foundation
import Observation

/// API base URL. Default is Simulator → host Compose (`http://localhost:8000`).
/// Change in-app (More tab) or in iOS Settings. Stored in UserDefaults.
@Observable
final class AppSettings {
    static let defaultBaseURL = "http://localhost:8000"
    static let baseURLKey = "sps_crm_api_base_url"

    var baseURLString: String {
        didSet {
            let trimmed = Self.normalize(baseURLString)
            if trimmed != baseURLString {
                baseURLString = trimmed
                return
            }
            UserDefaults.standard.set(trimmed, forKey: Self.baseURLKey)
        }
    }

    var baseURL: URL {
        URL(string: baseURLString) ?? URL(string: Self.defaultBaseURL)!
    }

    init() {
        Self.registerDefaults()
        let stored = UserDefaults.standard.string(forKey: Self.baseURLKey) ?? Self.defaultBaseURL
        self.baseURLString = Self.normalize(stored)
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [baseURLKey: defaultBaseURL])
    }

    static func normalize(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") { value.removeLast() }
        return value.isEmpty ? defaultBaseURL : value
    }
}
