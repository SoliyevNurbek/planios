import SwiftUI
import Combine

final class TaskViewModel: ObservableObject {
    enum TaskFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case week = "This Week"

        var id: String { rawValue }
    }

    @Published var tasks: [PlanTask] = []
    @Published var selectedFilter: TaskFilter = .today
    @Published var searchText = ""
    @Published var isPresentingEditor = false
    @Published var editingTask: PlanTask?
    @Published var selectedFocusTask: PlanTask?

    private let storage: StorageManager
    private let notifications: NotificationManager

    init(storage: StorageManager = .shared, notifications: NotificationManager = .shared) {
        self.storage = storage
        self.notifications = notifications

        storage.$tasks
            .receive(on: RunLoop.main)
            .assign(to: &$tasks)
    }

    var filteredTasks: [PlanTask] {
        let filteredByType: [PlanTask]
        switch selectedFilter {
        case .today:
            filteredByType = tasks.filter(\.isToday)
        case .tomorrow:
            filteredByType = tasks.filter(\.isTomorrow)
        case .week:
            filteredByType = tasks.filter(\.isThisWeek)
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return filteredByType }

        return filteredByType.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.description.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var todayTasks: [PlanTask] {
        tasks.filter(\.isToday)
    }

    var tomorrowTasks: [PlanTask] {
        tasks.filter(\.isTomorrow)
    }

    var todayCompletionRate: Double {
        storage.completionRate(for: Date())
    }

    var todayCompletedCount: Int {
        todayTasks.filter(\.isCompleted).count
    }

    var currentStreak: Int {
        storage.currentStreak
    }

    var weeklyCompletionRate: Double {
        let weekly = storage.weeklyData()
        guard !weekly.isEmpty else { return 0 }
        let total = weekly.reduce(0) { $0 + $1.completionRate }
        return total / Double(weekly.count)
    }

    func addTask(_ task: PlanTask) {
        storage.addTask(task)
        notifications.scheduleNotifications(for: task)
    }

    func updateTask(_ task: PlanTask) {
        storage.updateTask(task)
        if task.isCompleted {
            notifications.cancelNotifications(for: task.id)
        } else {
            notifications.scheduleNotifications(for: task)
        }
    }

    func deleteTask(id: UUID) {
        storage.deleteTask(id: id)
        notifications.cancelNotifications(for: id)
    }

    func toggleCompletion(id: UUID) {
        storage.toggleCompletion(id: id)
        if let task = tasks.first(where: { $0.id == id }), task.isCompleted {
            notifications.cancelNotifications(for: id)
        } else if let task = tasks.first(where: { $0.id == id }) {
            notifications.scheduleNotifications(for: task)
        }
    }

    func markTaskCompleted(_ task: PlanTask) {
        storage.markTaskCompleted(id: task.id)
        notifications.cancelNotifications(for: task.id)
    }

    func prepareNewTask(defaultDate: Date = Date()) {
        editingTask = PlanTask.empty(referenceDate: defaultDate)
        isPresentingEditor = true
    }

    func prepareEdit(_ task: PlanTask) {
        editingTask = task
        isPresentingEditor = true
    }

    func closeEditor() {
        editingTask = nil
        isPresentingEditor = false
    }
}
