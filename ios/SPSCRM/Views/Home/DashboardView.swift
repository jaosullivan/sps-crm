import SwiftUI

struct DashboardView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var model: DashboardViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView()
                    .task { model = DashboardViewModel(api: auth.api) }
            }
        }
        .background(SPSTheme.cream.ignoresSafeArea())
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func content(_ model: DashboardViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Overview of St. Patrick's Society HK CRM.")
                    .font(.subheadline)
                    .foregroundStyle(SPSTheme.muted)

                if let error = model.errorMessage {
                    ErrorBanner(message: error)
                }

                if model.isLoading && model.stats == nil {
                    ProgressView("Loading stats…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }

                if let stats = model.stats {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            label: "Members",
                            value: "\(stats.membersTotal)",
                            subtitle: "\(stats.membersActive) active",
                            systemImage: "person.2.fill"
                        )
                        StatCard(
                            label: "Deals",
                            value: "\(stats.dealsTotal)",
                            subtitle: "Pipeline \(SPSFormat.hkd(stats.pipelineValueHkd))",
                            systemImage: "briefcase.fill"
                        )
                        StatCard(
                            label: "Sponsors",
                            value: "\(stats.sponsorsTotal)",
                            subtitle: "All tiers",
                            systemImage: "rosette"
                        )
                        StatCard(
                            label: "Companies",
                            value: "\(stats.companiesTotal)",
                            subtitle: "Organisations",
                            systemImage: "building.2.fill"
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Deals by stage")
                            .font(.headline)
                        ForEach(DealStage.allCases) { stage in
                            HStack {
                                Text(stage.label)
                                    .foregroundStyle(SPSTheme.ink)
                                Spacer()
                                Text("\(stats.count(for: stage))")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(SPSTheme.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(SPSTheme.cream)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SPSTheme.border, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pipeline value")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OPEN PIPELINE")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SPSTheme.muted)
                            Text(SPSFormat.hkd(stats.pipelineValueHkd))
                                .font(.title2.bold())
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WON VALUE")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SPSTheme.muted)
                            Text(SPSFormat.hkd(stats.wonValueHkd))
                                .font(.title2.bold())
                                .foregroundStyle(SPSTheme.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SPSTheme.border, lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }
}
