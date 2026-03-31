import SwiftUI

final class FocusViewModel: ObservableObject {
    @Published private(set) var task: PlanTask
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var totalSeconds: Int
    @Published var isRunning = false
    @Published var showExitAlert = false
    @Published var hasCompletedSession = false

    private var timer: Timer?
    private let onComplete: (PlanTask) -> Void

    let motivationalMessages = [
        "One focused block moves the day forward.",
        "Protect the next few minutes. They matter.",
        "Discipline compounds faster than motivation.",
        "Stay with the task until the timer ends.",
        "Momentum is built by finishing, not switching."
    ]

    init(task: PlanTask, onComplete: @escaping (PlanTask) -> Void) {
        self.task = task
        self.totalSeconds = task.durationSeconds
        self.remainingSeconds = task.durationSeconds
        self.onComplete = onComplete
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var randomMotivation: String {
        motivationalMessages.randomElement() ?? motivationalMessages[0]
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func requestExit() {
        showExitAlert = true
    }

    func completeSession() {
        pause()
        hasCompletedSession = true
        task.isCompleted = true
        onComplete(task)
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            completeSession()
            return
        }
        remainingSeconds -= 1
    }

    deinit {
        timer?.invalidate()
    }
}
