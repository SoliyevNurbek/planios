import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if appState.isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeOut(duration: 0.25), value: appState.isShowingSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                appState.isShowingSplash = false
            }
        }
    }
}
