import SwiftUI

struct MembersListView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var model: MembersViewModel?
    @State private var showCreate = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
                    .task { model = MembersViewModel(api: auth.api) }
            }
        }
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("Members")
    }

    @ViewBuilder
    private func content(_ model: MembersViewModel) -> some View {
        @Bindable var model = model
        List {
            if let error = model.errorMessage {
                Section { ErrorBanner(message: error) }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if model.members.isEmpty && !model.isLoading {
                EmptyStateView(
                    title: "No members found",
                    description: "Add a society member or adjust your search.",
                    actionTitle: "Add member"
                ) { showCreate = true }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.members) { member in
                NavigationLink(value: member.id) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.fullName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(SPSTheme.ink)
                            Text(member.email)
                                .font(.caption)
                                .foregroundStyle(SPSTheme.muted)
                            if let company = member.companyName, !company.isEmpty {
                                Text(company)
                                    .font(.caption)
                                    .foregroundStyle(SPSTheme.bodyGreen)
                            }
                        }
                        Spacer()
                        StatusChip(text: member.status.label, tint: member.status.chipColor)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $model.query, prompt: "Search members")
        .onSubmit(of: .search) {
            Task { await model.load() }
        }
        .onChange(of: model.query) { _, newValue in
            if newValue.isEmpty {
                Task { await model.load() }
            }
        }
        .refreshable { await model.load() }
        .overlay {
            if model.isLoading && model.members.isEmpty {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add member")
            }
        }
        .navigationDestination(for: Int.self) { id in
            MemberDetailView(memberID: id)
        }
        .sheet(isPresented: $showCreate) {
            MemberFormView(member: nil) {
                Task { await model.load() }
            }
        }
        .task { await model.load() }
    }
}
