import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    weeklyChart
                    summaryCards
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Statistics")
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private var header: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance overview")
                    .font(.title2.weight(.bold))
                Text("Use your weekly trend to decide whether your plans are realistic or overloaded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var weeklyChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Last 7 days")
                    .font(.headline.weight(.bold))

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(viewModel.weeklyData) { day in
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.planGreen.opacity(0.55), Color.planGreen],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: max(18, day.completionRate * 160))

                            Text(day.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 210, alignment: .bottom)
            }
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 14) {
            StatCard(
                title: "Today",
                value: "\(Int(viewModel.todayRate * 100))%",
                caption: "Completion rate today",
                icon: "sun.max.fill",
                iconColor: .planAmber
            )

            StatCard(
                title: "Completed this week",
                value: "\(viewModel.completedThisWeek)",
                caption: "Finished tasks in the current week",
                icon: "checkmark.circle.fill",
                iconColor: .planGreen
            )

            StatCard(
                title: "Current streak",
                value: "\(viewModel.streak) days",
                caption: viewModel.bestDay.map { "Best day: \($0.label)" } ?? "Start with today's plan",
                icon: "flame.fill",
                iconColor: .orange
            )
        }
    }
}
