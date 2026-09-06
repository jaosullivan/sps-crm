import Foundation
import Observation

@Observable
@MainActor
final class DealsViewModel {
    var deals: [Deal] = []
    var companies: [Company] = []
    var query = ""
    var stageFilter: DealStage?
    var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func companyName(for id: Int?) -> String {
        guard let id else { return "—" }
        return companies.first(where: { $0.id == id })?.name ?? "#\(id)"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let dealsTask = api.listDeals(q: blankToNil(query), stage: stageFilter)
            async let companiesTask = api.listCompanies()
            deals = try await dealsTask
            companies = try await companiesTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(_ deal: Deal) async {
        do {
            try await api.deleteDeal(id: deal.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class DealDetailViewModel {
    var deal: Deal?
    var companies: [Company] = []
    var isLoading = false
    var isUpdatingStage = false
    var errorMessage: String?

    private let api: APIClient
    private let id: Int

    init(id: Int, api: APIClient, preview: Deal? = nil) {
        self.id = id
        self.api = api
        self.deal = preview
    }

    func companyName(for id: Int?) -> String {
        guard let id else { return "—" }
        return companies.first(where: { $0.id == id })?.name ?? "#\(id)"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let dealTask = api.getDeal(id: id)
            async let companiesTask = api.listCompanies()
            deal = try await dealTask
            companies = try await companiesTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func changeStage(to stage: DealStage) async {
        isUpdatingStage = true
        errorMessage = nil
        defer { isUpdatingStage = false }
        do {
            deal = try await api.patchDealStage(id: id, stage: stage)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class DealFormViewModel {
    var form: DealWrite
    var valueText: String
    var companies: [Company] = []
    var isSaving = false
    var isLoadingCompanies = false
    var errorMessage: String?
    let editingID: Int?

    var title: String { editingID == nil ? "Add deal" : "Edit deal" }

    private let api: APIClient

    init(api: APIClient, deal: Deal? = nil) {
        self.api = api
        if let deal {
            editingID = deal.id
            form = .from(deal)
            if let value = deal.valueHkd {
                valueText = NSDecimalNumber(decimal: value).stringValue
            } else {
                valueText = ""
            }
        } else {
            editingID = nil
            form = .blank()
            valueText = ""
        }
    }

    func loadCompanies() async {
        isLoadingCompanies = true
        defer { isLoadingCompanies = false }
        do {
            companies = try await api.listCompanies()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func save() async -> Deal? {
        errorMessage = nil
        var cleaned = form.cleaned()
        let trimmedValue = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            cleaned.valueHkd = nil
        } else if let d = Decimal(string: trimmedValue) {
            cleaned.valueHkd = d
        } else {
            errorMessage = "Value (HKD) must be a number."
            return nil
        }
        guard !cleaned.title.isEmpty else {
            errorMessage = "Title is required."
            return nil
        }
        isSaving = true
        defer { isSaving = false }
        do {
            if let editingID {
                return try await api.updateDeal(id: editingID, cleaned)
            }
            return try await api.createDeal(cleaned)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
