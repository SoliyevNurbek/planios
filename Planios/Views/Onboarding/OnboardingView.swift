import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.planBackground, Color.white, Color.planMint.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageCard(page: page)
                            .padding(.horizontal, 24)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.planGreen : Color.secondary.opacity(0.18))
                            .frame(width: index == currentPage ? 30 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                PrimaryButton(
                    title: currentPage == pages.count - 1 ? "Start Planning" : "Continue",
                    icon: currentPage == pages.count - 1 ? "arrow.right.circle.fill" : "arrow.right"
                ) {
                    if currentPage == pages.count - 1 {
                        appState.completeOnboarding()
                    } else {
                        currentPage += 1
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .padding(.top, 18)
        }
    }
}

private struct OnboardingPageCard: View {
    let page: OnboardingPage

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.planGreen.opacity(0.95), Color.planMint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 280)

                    VStack(spacing: 20) {
                        Image(systemName: page.icon)
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(.white)
                        Text(page.highlight)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(page.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let highlight: String
    let title: String
    let subtitle: String

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "calendar.badge.plus",
            highlight: "Design your day with intent",
            title: "Capture daily, weekly, and tomorrow plans in one place.",
            subtitle: "Build a system that keeps the next action clear instead of scattered across notes and reminders."
        ),
        OnboardingPage(
            icon: "scope",
            highlight: "Protect focused work",
            title: "Turn any task into a guided focus session.",
            subtitle: "A clean countdown, friction on exit, and reminder cues help you stay with the work until it is done."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            highlight: "See progress every week",
            title: "Track completion, streaks, and performance trends.",
            subtitle: "Daily discipline becomes visible when the dashboard and stats reflect what you actually finished."
        )
    ]
}
