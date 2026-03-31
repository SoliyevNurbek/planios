import SwiftUI

@main
struct PlaniosApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var taskViewModel = TaskViewModel()

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(taskViewModel)
        }
    }
}
