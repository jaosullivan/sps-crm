import Foundation
import Observation

@Observable
@MainActor
final class MembersViewModel {
    var members: [Member] = []
    var query = ""
    var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            members = try await api.listMembers(q: blankToNil(query))
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(_ member: Member) async {
        do {
            try await api.deleteMember(id: member.id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class MemberDetailViewModel {
    var member: Member?
    var isLoading = false
    var errorMessage: String?

    private let api: APIClient
    private let id: Int

    init(id: Int, api: APIClient, preview: Member? = nil) {
        self.id = id
        self.api = api
        self.member = preview
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            member = try await api.getMember(id: id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class MemberFormViewModel {
    var form: MemberWrite
    var isSaving = false
    var errorMessage: String?
    let editingID: Int?

    var title: String { editingID == nil ? "Add member" : "Edit member" }

    private let api: APIClient

    init(api: APIClient, member: Member? = nil) {
        self.api = api
        if let member {
            editingID = member.id
            form = .from(member)
        } else {
            editingID = nil
            form = .blank()
        }
    }

    func save() async -> Member? {
        errorMessage = nil
        let cleaned = form.cleaned()
        guard !cleaned.firstName.isEmpty, !cleaned.lastName.isEmpty, !cleaned.email.isEmpty else {
            errorMessage = "First name, last name, and email are required."
            return nil
        }
        isSaving = true
        defer { isSaving = false }
        do {
            if let editingID {
                return try await api.updateMember(id: editingID, cleaned)
            }
            return try await api.createMember(cleaned)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
