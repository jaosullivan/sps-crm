import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var confirmLogout = false

    var body: some View {
        @Bindable var settings = auth.settings

        Form {
            Section {
                if let user = auth.user {
                    LabeledContent("Name", value: user.fullName)
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Role", value: user.isAdmin ? "Admin" : "User")
                }
            } header: {
                Text("Signed in")
            }

            Section {
                TextField("API base URL", text: $settings.baseURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Text("Default for Simulator is http://localhost:8000 (docker compose). On a physical device use your Mac’s LAN IP, e.g. http://192.168.1.20:8000. HTTP to local networks is allowed via ATS (NSAllowsLocalNetworking).")
                    .font(.caption)
                    .foregroundStyle(SPSTheme.muted)
                Button("Reset to localhost") {
                    settings.baseURLString = AppSettings.defaultBaseURL
                }
            } header: {
                Text("API server")
            }

            Section {
                Link("St. Patrick's Society HK", destination: URL(string: "https://www.stpatrickshk.com/")!)
                Link("API contract", destination: URL(string: "https://github.com/jaosullivan/sps-crm/blob/main/api/API_CONTRACT.md")!)
            } header: {
                Text("About")
            } footer: {
                Text("SPS CRM iOS companion · KAN-7")
            }

            Section {
                Button("Sign out", role: .destructive) {
                    confirmLogout = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("More")
        .confirmationDialog("Sign out and clear the saved token?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                auth.logout()
            }
        }
    }
}
