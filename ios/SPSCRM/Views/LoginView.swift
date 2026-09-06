import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var email = "admin@stpatrickshk.com"
    @State private var password = ""
    @State private var showAPISettings = false

    var body: some View {
        @Bindable var settings = auth.settings

        ScrollView {
            VStack(spacing: 24) {
                formCard
                Button {
                    showAPISettings.toggle()
                } label: {
                    Label("API server", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SPSTheme.bodyGreen)
                }
                if showAPISettings {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API base URL")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SPSTheme.muted)
                        TextField("http://localhost:8000", text: $settings.baseURLString)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(SPSTheme.border, lineWidth: 1)
                            )
                        Text("Simulator: leave as localhost. Physical device: use your Mac’s LAN IP (see ios/README.md).")
                            .font(.caption)
                            .foregroundStyle(SPSTheme.muted)
                    }
                    .padding(16)
                    .background(SPSTheme.greenLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(24)
        }
        .background(SPSTheme.cream.ignoresSafeArea())
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SPSBrandLockup(style: .favicon)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Divider().background(SPSTheme.border)
                }

            VStack(alignment: .leading, spacing: 16) {
                Text("Sign in")
                    .font(.title2.bold())
                    .foregroundStyle(SPSTheme.ink)
                Text("Manage members, sponsors, companies, and deals.")
                    .font(.subheadline)
                    .foregroundStyle(SPSTheme.muted)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SPSTheme.ink)
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(SPSTheme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SPSTheme.ink)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(12)
                        .background(SPSTheme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if let error = auth.errorMessage {
                    ErrorBanner(message: error)
                }

                Button {
                    Task { await auth.login(email: email, password: password) }
                } label: {
                    Group {
                        if auth.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign in")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(SPSTheme.primary)
                .disabled(auth.isSubmitting || email.isEmpty || password.isEmpty)

                Text("Local seed: admin@stpatrickshk.com / changeme")
                    .font(.caption)
                    .foregroundStyle(SPSTheme.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SPSTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
