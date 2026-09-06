import SwiftUI

struct DealFormView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let deal: Deal?
    var onSaved: () -> Void

    @State private var model: DealFormViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    form(model)
                } else {
                    ProgressView()
                        .task { model = DealFormViewModel(api: auth.api, deal: deal) }
                }
            }
            .background(SPSTheme.cream.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func form(_ model: DealFormViewModel) -> some View {
        @Bindable var model = model
        Form {
            if let error = model.errorMessage {
                Section { ErrorBanner(message: error) }
            }
            Section("Deal") {
                TextField("Title", text: $model.form.title)
                Picker("Stage", selection: $model.form.stage) {
                    ForEach(DealStage.allCases) { stage in
                        Text(stage.label).tag(stage)
                    }
                }
                Picker("Company", selection: $model.form.companyId) {
                    Text("None").tag(Optional<Int>.none)
                    ForEach(model.companies) { company in
                        Text(company.name).tag(Optional(company.id))
                    }
                }
                TextField("Value (HKD)", text: $model.valueText)
                    .keyboardType(.decimalPad)
                OptionalDateField(title: "Expected close", isoDate: $model.form.expectedClose)
            }
            Section("Contact") {
                TextField("Contact name", text: optionalString($model.form.contactName))
                    .textContentType(.name)
                TextField("Contact email", text: optionalString($model.form.contactEmail))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
            }
            Section("Notes") {
                TextField("Notes", text: optionalString($model.form.notes), axis: .vertical)
                    .lineLimit(3 ... 8)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(model.isSaving ? "Saving…" : "Save") {
                    Task {
                        if await model.save() != nil {
                            onSaved()
                            dismiss()
                        }
                    }
                }
                .disabled(model.isSaving)
                .fontWeight(.semibold)
            }
        }
        .task { await model.loadCompanies() }
    }
}
