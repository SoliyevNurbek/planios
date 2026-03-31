import SwiftUI

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var isShowingSplash = true
    @Published var selectedTab: AppTab = .dashboard

    init(storage: StorageManager = .shared) {
        hasCompletedOnboarding = storage.isOnboardingDone
    }

    func completeOnboarding() {
        StorageManager.shared.isOnboardingDone = true
        withAnimation(.easeInOut(duration: 0.35)) {
            hasCompletedOnboarding = true
        }
    }
}

enum AppTab: Hashable {
    case dashboard
    case tasks
    case statistics
    case settings
}
