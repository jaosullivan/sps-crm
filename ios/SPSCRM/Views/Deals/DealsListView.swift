import SwiftUI

struct DealsListView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var model: DealsViewModel?
    @State private var showCreate = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
                    .task { model = DealsViewModel(api: auth.api) }
            }
        }
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("Deals")
    }

    @ViewBuilder
    private func content(_ model: DealsViewModel) -> some View {
        @Bindable var model = model
        List {
            Section {
                Picker("Stage", selection: $model.stageFilter) {
                    Text("All stages").tag(Optional<DealStage>.none)
                    ForEach(DealStage.allCases) { stage in
                        Text(stage.label).tag(Optional(stage))
                    }
                }
                .pickerStyle(.menu)
            }

            if let error = model.errorMessage {
                Section { ErrorBanner(message: error) }
                    .listRowBackground(Color.clear)
            }

            if model.deals.isEmpty && !model.isLoading {
                EmptyStateView(
                    title: "No deals found",
                    description: "Filter by stage or add a pipeline deal.",
                    actionTitle: "Add deal"
                ) { showCreate = true }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.deals) { deal in
                NavigationLink(value: deal.id) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(deal.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(SPSTheme.ink)
                            Spacer()
                            StatusChip(text: deal.stage.label, tint: deal.stage.chipColor)
                        }
                        HStack {
                            Text(model.companyName(for: deal.companyId))
                            Spacer()
                            Text(SPSFormat.hkd(deal.valueHkd))
                        }
                        .font(.caption)
                        .foregroundStyle(SPSTheme.muted)
                        if let close = deal.expectedClose, !close.isEmpty {
                            Text("Close \(SPSFormat.date(close))")
                                .font(.caption2)
                                .foregroundStyle(SPSTheme.bodyGreen)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $model.query, prompt: "Search deals")
        .onSubmit(of: .search) {
            Task { await model.load() }
        }
        .onChange(of: model.query) { _, newValue in
            if newValue.isEmpty {
                Task { await model.load() }
            }
        }
        .onChange(of: model.stageFilter) { _, _ in
            Task { await model.load() }
        }
        .refreshable { await model.load() }
        .overlay {
            if model.isLoading && model.deals.isEmpty {
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
                .accessibilityLabel("Add deal")
            }
        }
        .navigationDestination(for: Int.self) { id in
            DealDetailView(dealID: id)
        }
        .sheet(isPresented: $showCreate) {
            DealFormView(deal: nil) {
                Task { await model.load() }
            }
        }
        .task { await model.load() }
    }
}
