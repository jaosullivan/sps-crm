import SwiftUI

struct MemberDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    let memberID: Int
    var preview: Member? = nil

    @State private var model: MemberDetailViewModel?
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
                    .task {
                        model = MemberDetailViewModel(id: memberID, api: auth.api, preview: preview)
                    }
            }
        }
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("Member")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ model: MemberDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = model.errorMessage {
                    ErrorBanner(message: error)
                }
                if model.isLoading && model.member == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                if let member = model.member {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(member.fullName)
                            .font(.title2.bold())
                            .foregroundStyle(SPSTheme.ink)
                        StatusChip(text: member.status.label, tint: member.status.chipColor)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Email", value: member.email)
                        DetailRow(label: "Phone", value: member.phone ?? "—")
                        DetailRow(label: "Company", value: member.companyName ?? "—")
                        DetailRow(label: "Green card #", value: member.greenCardNumber ?? "—")
                        DetailRow(label: "Joined on", value: SPSFormat.date(member.joinedOn))
                        DetailRow(label: "Notes", value: member.notes ?? "—")
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SPSTheme.border, lineWidth: 1)
                    )

                    Button("Delete member", role: .destructive) {
                        confirmDelete = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
        .refreshable { await model.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
                    .disabled(model.member == nil)
            }
        }
        .sheet(isPresented: $showEdit) {
            if let member = model.member {
                MemberFormView(member: member) {
                    Task { await model.load() }
                }
            }
        }
        .confirmationDialog("Delete this member?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await auth.api.deleteMember(id: memberID)
                        dismiss()
                    } catch {
                        model.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .task { await model.load() }
    }
}
