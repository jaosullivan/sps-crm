import XCTest
@testable import SPSCRM

final class ModelDecodingTests: XCTestCase {
    func testLoginResponseMatchesContract() throws {
        let json = """
        {
          "access_token": "jwt-token",
          "token_type": "bearer",
          "user": {
            "id": 1,
            "email": "admin@stpatrickshk.com",
            "full_name": "SPS Admin",
            "is_active": true,
            "is_admin": true,
            "created_at": "2026-01-01T00:00:00Z"
          }
        }
        """.data(using: .utf8)!
        let res = try JSONDecoder().decode(LoginResponse.self, from: json)
        XCTAssertEqual(res.accessToken, "jwt-token")
        XCTAssertEqual(res.tokenType, "bearer")
        XCTAssertEqual(res.user.email, "admin@stpatrickshk.com")
        XCTAssertTrue(res.user.isAdmin)
    }

    func testMemberRoundTripFields() throws {
        let json = """
        {
          "id": 2,
          "first_name": "Aoife",
          "last_name": "Murphy",
          "email": "aoife.murphy@example.com",
          "phone": "+852 5550 1001",
          "company_name": "Independent",
          "status": "active",
          "green_card_number": "GC-1001",
          "joined_on": "2024-03-17",
          "notes": null,
          "created_at": "2026-01-01T00:00:00Z",
          "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let member = try JSONDecoder().decode(Member.self, from: json)
        XCTAssertEqual(member.fullName, "Aoife Murphy")
        XCTAssertEqual(member.status, .active)
        XCTAssertEqual(member.joinedOn, "2024-03-17")
    }

    func testDealDecodesNumericOrStringHkd() throws {
        let number = """
        {"id":1,"title":"Ball Gold","company_id":9,"stage":"proposal","value_hkd":120000,
         "contact_name":"Partnerships","contact_email":null,"expected_close":null,"notes":null,
         "created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let string = """
        {"id":1,"title":"Ball Gold","company_id":9,"stage":"won","value_hkd":"120000.50",
         "contact_name":null,"contact_email":null,"expected_close":null,"notes":null}
        """.data(using: .utf8)!
        let a = try JSONDecoder().decode(Deal.self, from: number)
        let b = try JSONDecoder().decode(Deal.self, from: string)
        XCTAssertEqual(a.stage, .proposal)
        XCTAssertEqual(a.valueHkd, Decimal(120000))
        XCTAssertEqual(b.stage, .won)
        XCTAssertEqual(b.valueHkd, Decimal(string: "120000.50"))
    }

    func testDashboardStatsMatchesContract() throws {
        let json = """
        {
          "members_total": 2,
          "members_active": 2,
          "sponsors_total": 1,
          "companies_total": 1,
          "deals_total": 1,
          "deals_by_stage": {"lead":0,"contacted":0,"proposal":1,"won":0,"lost":0},
          "pipeline_value_hkd": "120000",
          "won_value_hkd": 0
        }
        """.data(using: .utf8)!
        let stats = try JSONDecoder().decode(DashboardStats.self, from: json)
        XCTAssertEqual(stats.membersTotal, 2)
        XCTAssertEqual(stats.count(for: .proposal), 1)
        XCTAssertEqual(stats.pipelineValueHkd, Decimal(120000))
        XCTAssertEqual(stats.wonValueHkd, 0)
    }

    func testMemberWriteOmitsBlankOptionals() throws {
        var form = MemberWrite.blank()
        form.firstName = "Pat"
        form.lastName = "Murphy"
        form.email = "pat@example.com"
        form.phone = "  "
        form.notes = ""
        let cleaned = form.cleaned()
        XCTAssertNil(cleaned.phone)
        XCTAssertNil(cleaned.notes)
        let data = try JSONEncoder().encode(cleaned)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["first_name"] as? String, "Pat")
        XCTAssertEqual(obj?["status"] as? String, "active")
    }

    func testURLBuilderStageFilter() throws {
        let client = APIClient(
            baseURL: { URL(string: "http://localhost:8000")! },
            token: { nil }
        )
        let url = try client.makeURL(path: "/api/deals", query: ["q": nil, "stage": "proposal"])
        XCTAssertEqual(url.absoluteString, "http://localhost:8000/api/deals?stage=proposal")
    }

    func testHeaderLogoURLMatchesWebCDN() {
        XCTAssertEqual(
            SPSBrandAssets.headerLogoURL.absoluteString,
            "https://static.wixstatic.com/media/ef9572_9049fdb0d6484286a126e71bad334748~mv2.png/v1/fill/w_378,h_194,al_c,q_85,usm_0.66_1.00_0.01,enc_avif,quality_auto/stpatslogo.png"
        )
    }

    func testParseFastAPIDetail() {
        let data = #"{"detail":"Incorrect email or password"}"#.data(using: .utf8)!
        XCTAssertEqual(APIClient.parseDetail(data, status: 401), "Incorrect email or password")
    }
}
