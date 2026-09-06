import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case http(status: Int, detail: String)
    case decoding(String)
    case transport(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API base URL."
        case .http(_, let detail):
            return detail
        case .decoding(let message):
            return "Could not read the server response. \(message)"
        case .transport(let message):
            return message
        case .unauthorized:
            return "Session expired. Please sign in again."
        }
    }
}

/// Thin client for `api/API_CONTRACT.md` v0.1. Paths are `/api/...` on the configured base.
final class APIClient {
    var onUnauthorized: () -> Void = {}

    private let session: URLSession
    private let baseURL: () -> URL
    private let token: () -> String?

    init(
        session: URLSession = .shared,
        baseURL: @escaping () -> URL,
        token: @escaping () -> String?,
        onUnauthorized: @escaping () -> Void = {}
    ) {
        self.session = session
        self.baseURL = baseURL
        self.token = token
        self.onUnauthorized = onUnauthorized
    }

    // MARK: Auth

    func login(email: String, password: String) async throws -> LoginResponse {
        try await request(
            "/api/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password),
            auth: false
        )
    }

    func me() async throws -> User {
        try await request("/api/auth/me")
    }

    // MARK: Dashboard

    func dashboardStats() async throws -> DashboardStats {
        try await request("/api/dashboard/stats")
    }

    // MARK: Members

    func listMembers(q: String? = nil) async throws -> [Member] {
        try await request("/api/members", query: ["q": q])
    }

    func getMember(id: Int) async throws -> Member {
        try await request("/api/members/\(id)")
    }

    func createMember(_ body: MemberWrite) async throws -> Member {
        try await request("/api/members", method: "POST", body: body.cleaned())
    }

    func updateMember(id: Int, _ body: MemberWrite) async throws -> Member {
        try await request("/api/members/\(id)", method: "PATCH", body: body.cleaned())
    }

    func deleteMember(id: Int) async throws {
        let _: Empty = try await request("/api/members/\(id)", method: "DELETE")
    }

    // MARK: Deals

    func listDeals(q: String? = nil, stage: DealStage? = nil) async throws -> [Deal] {
        try await request("/api/deals", query: ["q": q, "stage": stage?.rawValue])
    }

    func getDeal(id: Int) async throws -> Deal {
        try await request("/api/deals/\(id)")
    }

    func createDeal(_ body: DealWrite) async throws -> Deal {
        try await request("/api/deals", method: "POST", body: body.cleaned())
    }

    func updateDeal(id: Int, _ body: DealWrite) async throws -> Deal {
        try await request("/api/deals/\(id)", method: "PATCH", body: body.cleaned())
    }

    func patchDealStage(id: Int, stage: DealStage) async throws -> Deal {
        try await request("/api/deals/\(id)", method: "PATCH", body: StagePatch(stage: stage))
    }

    func deleteDeal(id: Int) async throws {
        let _: Empty = try await request("/api/deals/\(id)", method: "DELETE")
    }

    // MARK: Companies (read-only)

    func listCompanies(q: String? = nil) async throws -> [Company] {
        try await request("/api/companies", query: ["q": q])
    }

    func getCompany(id: Int) async throws -> Company {
        try await request("/api/companies/\(id)")
    }

    // MARK: Internals

    func makeURL(path: String, query: [String: String?] = [:]) throws -> URL {
        let root = baseURL()
        guard var components = URLComponents(url: root, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        let prefix = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = prefix + path
        let items = query.compactMap { key, value -> URLQueryItem? in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        .sorted { $0.name < $1.name }
        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [String: String?] = [:],
        body: Encodable? = nil,
        auth: Bool = true
    ) async throws -> T {
        let url = try makeURL(path: path, query: query)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        if auth, let token = token() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("Unexpected response.")
        }

        if http.statusCode == 401 {
            onUnauthorized()
            throw APIError.unauthorized
        }

        if http.statusCode == 204 {
            if T.self == Empty.self, let empty = Empty() as? T {
                return empty
            }
            throw APIError.decoding("Empty 204 response.")
        }

        if !(200 ..< 300).contains(http.statusCode) {
            throw APIError.http(status: http.statusCode, detail: Self.parseDetail(data, status: http.statusCode))
        }

        if T.self == Empty.self, let empty = Empty() as? T {
            return empty
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    static func parseDetail(_ data: Data, status: Int) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let detail = obj["detail"] as? String { return detail }
            if let detail = obj["detail"] as? [[String: Any]] {
                let msgs = detail.compactMap { $0["msg"] as? String }
                if !msgs.isEmpty { return msgs.joined(separator: " ") }
            }
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty { return text }
        return "Request failed (\(status))"
    }
}

struct Empty: Codable, Sendable {}

private struct StagePatch: Encodable {
    var stage: DealStage
}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
