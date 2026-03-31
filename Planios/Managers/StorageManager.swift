import Foundation
import Combine

struct DayStats: Identifiable {
    let id = UUID()
    let label: String
    let completionRate: Double
    let date: Date
}

final class StorageManager: ObservableObject {
    static let shared = StorageManager()

    @Published private(set) var tasks: [PlanTask] = []
    @Published private(set) var currentStreak: Int = 0

    private let defaults = UserDefaults.standard
    private let tasksKey = "planios.tasks"
    private let onboardingKey = "planios.onboarding"

    private init() {
        loadTasks()
        recalculateStreak()
    }

    var isOnboardingDone: Bool {
        get { defaults.bool(forKey: onboardingKey) }
        set { defaults.set(newValue, forKey: onboardingKey) }
    }

    func loadTasks() {
        guard let data = defaults.data(forKey: tasksKey),
              let decoded = try? JSONDecoder().decode([PlanTask].self, from: data) else {
            tasks = Self.seedTasks()
            saveTasks()
            return
        }

        tasks = decoded.sorted(by: Self.sort)
    }

    func addTask(_ task: PlanTask) {
        tasks.append(task)
        tasks.sort(by: Self.sort)
        saveTasks()
    }

    func updateTask(_ task: PlanTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        tasks.sort(by: Self.sort)
        saveTasks()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    func toggleCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }

    func markTaskCompleted(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted = true
        saveTasks()
    }

    func saveTasks() {
        guard let encoded = try? JSONEncoder().encode(tasks) else { return }
        defaults.set(encoded, forKey: tasksKey)
        recalculateStreak()
    }

    func resetAll() {
        defaults.removeObject(forKey: tasksKey)
        defaults.removeObject(forKey: onboardingKey)
        tasks = Self.seedTasks()
        currentStreak = 0
        saveTasks()
    }

    func completionRate(for date: Date) -> Double {
        let dayTasks = tasksForDay(date)
        guard !dayTasks.isEmpty else { return 0 }
        let completed = dayTasks.filter(\.isCompleted).count
        return Double(completed) / Double(dayTasks.count)
    }

    func tasksForDay(_ date: Date) -> [PlanTask] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func weeklyData(referenceDate: Date = Date()) -> [DayStats] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset -> DayStats? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: referenceDate) else { return nil }
            let label = offset == 0 ? "Today" : day.formatted(.dateTime.weekday(.abbreviated))
            return DayStats(label: label, completionRate: completionRate(for: day), date: day)
        }
        .reversed()
    }

    private func recalculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: Date())

        while true {
            let dayTasks = tasksForDay(day)
            guard !dayTasks.isEmpty else { break }
            guard dayTasks.allSatisfy(\.isCompleted) else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        currentStreak = streak
    }

    private static func sort(lhs: PlanTask, rhs: PlanTask) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
        if lhs.priority.rank != rhs.priority.rank { return lhs.priority.rank < rhs.priority.rank }
        return lhs.startDate < rhs.startDate
    }

    private static func seedTasks() -> [PlanTask] {
        let calendar = Calendar.current
        let now = Date()
        let morning = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now) ?? now
        let workoutEnd = calendar.date(byAdding: .minute, value: 45, to: morning) ?? morning
        let deepWork = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
        let deepWorkEnd = calendar.date(byAdding: .minute, value: 90, to: deepWork) ?? deepWork
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let planning = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let planningEnd = calendar.date(byAdding: .minute, value: 30, to: planning) ?? planning

        return [
            PlanTask(
                title: "Morning workout",
                description: "Start the day with a short, energizing session.",
                date: now,
                startTime: morning,
                endTime: workoutEnd,
                priority: .medium,
                repeatType: .daily
            ),
            PlanTask(
                title: "Deep work block",
                description: "Ship one meaningful task with notifications off.",
                date: now,
                startTime: deepWork,
                endTime: deepWorkEnd,
                priority: .high,
                repeatType: .none
            ),
            PlanTask(
                title: "Plan tomorrow",
                description: "Set the top three outcomes before the day ends.",
                date: tomorrow,
                startTime: planning,
                endTime: planningEnd,
                priority: .low,
                repeatType: .daily
            )
        ]
    }
}
