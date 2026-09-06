import SwiftUI

struct DealDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    let dealID: Int
    var preview: Deal? = nil

    @State private var model: DealDetailViewModel?
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
                    .task {
                        model = DealDetailViewModel(id: dealID, api: auth.api, preview: preview)
                    }
            }
        }
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("Deal")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ model: DealDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = model.errorMessage {
                    ErrorBanner(message: error)
                }
                if model.isLoading && model.deal == nil {
                    ProgressView().frame(maxWidth: .infinity)
                }
                if let deal = model.deal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(deal.title)
                            .font(.title2.bold())
                            .foregroundStyle(SPSTheme.ink)
                        Text(SPSFormat.hkd(deal.valueHkd))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(SPSTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stage")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SPSTheme.muted)
                            .textCase(.uppercase)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(DealStage.allCases) { stage in
                                Button {
                                    Task { await model.changeStage(to: stage) }
                                } label: {
                                    Text(stage.label)
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(deal.stage == stage ? Color.white : stage.chipColor)
                                        .background(deal.stage == stage ? stage.chipColor : stage.chipColor.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .disabled(model.isUpdatingStage)
                            }
                        }
                        Text("lead → contacted → proposal → won or lost")
                            .font(.caption2)
                            .foregroundStyle(SPSTheme.muted)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SPSTheme.border, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Company", value: model.companyName(for: deal.companyId))
                        DetailRow(label: "Contact", value: deal.contactName ?? "—")
                        DetailRow(label: "Contact email", value: deal.contactEmail ?? "—")
                        DetailRow(label: "Expected close", value: SPSFormat.date(deal.expectedClose))
                        DetailRow(label: "Notes", value: deal.notes ?? "—")
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SPSTheme.border, lineWidth: 1)
                    )

                    Button("Delete deal", role: .destructive) {
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
                    .disabled(model.deal == nil)
            }
        }
        .sheet(isPresented: $showEdit) {
            if let deal = model.deal {
                DealFormView(deal: deal) {
                    Task { await model.load() }
                }
            }
        }
        .confirmationDialog("Delete this deal?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await auth.api.deleteDeal(id: dealID)
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
