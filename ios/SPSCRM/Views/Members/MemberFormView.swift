import SwiftUI

struct MemberFormView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let member: Member?
    var onSaved: () -> Void

    @State private var model: MemberFormViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    form(model)
                } else {
                    ProgressView()
                        .task { model = MemberFormViewModel(api: auth.api, member: member) }
                }
            }
            .background(SPSTheme.cream.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func form(_ model: MemberFormViewModel) -> some View {
        @Bindable var model = model
        Form {
            if let error = model.errorMessage {
                Section { ErrorBanner(message: error) }
            }
            Section("Identity") {
                TextField("First name", text: $model.form.firstName)
                    .textContentType(.givenName)
                TextField("Last name", text: $model.form.lastName)
                    .textContentType(.familyName)
                TextField("Email", text: $model.form.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
            }
            Section("Membership") {
                Picker("Status", selection: $model.form.status) {
                    ForEach(MemberStatus.allCases) { status in
                        Text(status.label).tag(status)
                    }
                }
                TextField("Phone", text: optionalString($model.form.phone))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                TextField("Company", text: optionalString($model.form.companyName))
                TextField("Green card #", text: optionalString($model.form.greenCardNumber))
                OptionalDateField(title: "Joined on", isoDate: $model.form.joinedOn)
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
    }
}

func optionalString(_ binding: Binding<String?>) -> Binding<String> {
    Binding(
        get: { binding.wrappedValue ?? "" },
        set: { binding.wrappedValue = $0 }
    )
}
