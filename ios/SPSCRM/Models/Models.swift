import Foundation

// MARK: - Enums (api/API_CONTRACT.md)

enum MemberStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case lapsed
    case complimentary

    var id: String { rawValue }

    var label: String { SPSFormat.titleCase(rawValue) }
}

enum DealStage: String, Codable, CaseIterable, Identifiable, Sendable {
    case lead
    case contacted
    case proposal
    case won
    case lost

    var id: String { rawValue }

    var label: String { SPSFormat.titleCase(rawValue) }

    /// Pipeline order from the contract: lead → contacted → proposal → won | lost.
    var sortOrder: Int {
        switch self {
        case .lead: 0
        case .contacted: 1
        case .proposal: 2
        case .won: 3
        case .lost: 4
        }
    }
}

// MARK: - User / auth

struct User: Codable, Hashable, Sendable, Identifiable {
    var id: Int
    var email: String
    var fullName: String
    var isActive: Bool
    var isAdmin: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case isActive = "is_active"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }
}

struct LoginRequest: Codable, Sendable {
    var email: String
    var password: String
}

struct LoginResponse: Codable, Sendable {
    var accessToken: String
    var tokenType: String
    var user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

// MARK: - Member

struct Member: Codable, Hashable, Sendable, Identifiable {
    var id: Int
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var companyName: String?
    var status: MemberStatus
    var greenCardNumber: String?
    var joinedOn: String?
    var notes: String?
    var createdAt: String?
    var updatedAt: String?

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id, email, phone, status, notes
        case firstName = "first_name"
        case lastName = "last_name"
        case companyName = "company_name"
        case greenCardNumber = "green_card_number"
        case joinedOn = "joined_on"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MemberWrite: Codable, Sendable, Equatable {
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var companyName: String?
    var status: MemberStatus
    var greenCardNumber: String?
    var joinedOn: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case email, phone, status, notes
        case firstName = "first_name"
        case lastName = "last_name"
        case companyName = "company_name"
        case greenCardNumber = "green_card_number"
        case joinedOn = "joined_on"
    }

    static func blank() -> MemberWrite {
        MemberWrite(
            firstName: "",
            lastName: "",
            email: "",
            phone: nil,
            companyName: nil,
            status: .active,
            greenCardNumber: nil,
            joinedOn: nil,
            notes: nil
        )
    }

    static func from(_ member: Member) -> MemberWrite {
        MemberWrite(
            firstName: member.firstName,
            lastName: member.lastName,
            email: member.email,
            phone: member.phone,
            companyName: member.companyName,
            status: member.status,
            greenCardNumber: member.greenCardNumber,
            joinedOn: member.joinedOn,
            notes: member.notes
        )
    }

    func cleaned() -> MemberWrite {
        var copy = self
        copy.phone = blankToNil(phone)
        copy.companyName = blankToNil(companyName)
        copy.greenCardNumber = blankToNil(greenCardNumber)
        copy.joinedOn = blankToNil(joinedOn)
        copy.notes = blankToNil(notes)
        return copy
    }
}

// MARK: - Deal

struct Deal: Codable, Hashable, Sendable, Identifiable {
    var id: Int
    var title: String
    var companyId: Int?
    var stage: DealStage
    var valueHkd: Decimal?
    var contactName: String?
    var contactEmail: String?
    var expectedClose: String?
    var notes: String?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, stage, notes
        case companyId = "company_id"
        case valueHkd = "value_hkd"
        case contactName = "contact_name"
        case contactEmail = "contact_email"
        case expectedClose = "expected_close"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        companyId = try c.decodeIfPresent(Int.self, forKey: .companyId)
        stage = try c.decode(DealStage.self, forKey: .stage)
        valueHkd = try c.decodeFlexibleDecimalIfPresent(forKey: .valueHkd)
        contactName = try c.decodeIfPresent(String.self, forKey: .contactName)
        contactEmail = try c.decodeIfPresent(String.self, forKey: .contactEmail)
        expectedClose = try c.decodeIfPresent(String.self, forKey: .expectedClose)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

struct DealWrite: Codable, Sendable, Equatable {
    var title: String
    var companyId: Int?
    var stage: DealStage
    var valueHkd: Decimal?
    var contactName: String?
    var contactEmail: String?
    var expectedClose: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case title, stage, notes
        case companyId = "company_id"
        case valueHkd = "value_hkd"
        case contactName = "contact_name"
        case contactEmail = "contact_email"
        case expectedClose = "expected_close"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        if let companyId {
            try c.encode(companyId, forKey: .companyId)
        } else {
            try c.encodeNil(forKey: .companyId)
        }
        try c.encode(stage, forKey: .stage)
        if let valueHkd {
            try c.encode(NSDecimalNumber(decimal: valueHkd).doubleValue, forKey: .valueHkd)
        } else {
            try c.encodeNil(forKey: .valueHkd)
        }
        try c.encodeIfPresent(contactName, forKey: .contactName)
        try c.encodeIfPresent(contactEmail, forKey: .contactEmail)
        try c.encodeIfPresent(expectedClose, forKey: .expectedClose)
        try c.encodeIfPresent(notes, forKey: .notes)
    }

    static func blank() -> DealWrite {
        DealWrite(
            title: "",
            companyId: nil,
            stage: .lead,
            valueHkd: nil,
            contactName: nil,
            contactEmail: nil,
            expectedClose: nil,
            notes: nil
        )
    }

    static func from(_ deal: Deal) -> DealWrite {
        DealWrite(
            title: deal.title,
            companyId: deal.companyId,
            stage: deal.stage,
            valueHkd: deal.valueHkd,
            contactName: deal.contactName,
            contactEmail: deal.contactEmail,
            expectedClose: deal.expectedClose,
            notes: deal.notes
        )
    }

    func cleaned() -> DealWrite {
        var copy = self
        copy.contactName = blankToNil(contactName)
        copy.contactEmail = blankToNil(contactEmail)
        copy.expectedClose = blankToNil(expectedClose)
        copy.notes = blankToNil(notes)
        return copy
    }
}

// MARK: - Company (read-only for deal company_id)

struct Company: Codable, Hashable, Sendable, Identifiable {
    var id: Int
    var name: String
    var website: String?
    var industry: String?
    var notes: String?
}

// MARK: - Dashboard

struct DashboardStats: Codable, Hashable, Sendable {
    var membersTotal: Int
    var membersActive: Int
    var sponsorsTotal: Int
    var companiesTotal: Int
    var dealsTotal: Int
    var dealsByStage: [String: Int]
    var pipelineValueHkd: Decimal
    var wonValueHkd: Decimal

    enum CodingKeys: String, CodingKey {
        case membersTotal = "members_total"
        case membersActive = "members_active"
        case sponsorsTotal = "sponsors_total"
        case companiesTotal = "companies_total"
        case dealsTotal = "deals_total"
        case dealsByStage = "deals_by_stage"
        case pipelineValueHkd = "pipeline_value_hkd"
        case wonValueHkd = "won_value_hkd"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        membersTotal = try c.decode(Int.self, forKey: .membersTotal)
        membersActive = try c.decode(Int.self, forKey: .membersActive)
        sponsorsTotal = try c.decode(Int.self, forKey: .sponsorsTotal)
        companiesTotal = try c.decode(Int.self, forKey: .companiesTotal)
        dealsTotal = try c.decode(Int.self, forKey: .dealsTotal)
        dealsByStage = try c.decodeIfPresent([String: Int].self, forKey: .dealsByStage) ?? [:]
        pipelineValueHkd = try c.decodeFlexibleDecimal(forKey: .pipelineValueHkd)
        wonValueHkd = try c.decodeFlexibleDecimal(forKey: .wonValueHkd)
    }

    func count(for stage: DealStage) -> Int {
        dealsByStage[stage.rawValue] ?? 0
    }
}

// MARK: - Helpers

func blankToNil(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

extension KeyedDecodingContainer {
    func decodeFlexibleDecimal(forKey key: Key) throws -> Decimal {
        if let d = try? decode(Decimal.self, forKey: key) { return d }
        if let n = try? decode(Double.self, forKey: key) { return Decimal(n) }
        if let i = try? decode(Int.self, forKey: key) { return Decimal(i) }
        if let s = try? decode(String.self, forKey: key), let d = Decimal(string: s) { return d }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected decimal")
    }

    func decodeFlexibleDecimalIfPresent(forKey key: Key) throws -> Decimal? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }
        return try decodeFlexibleDecimal(forKey: key)
    }
}
