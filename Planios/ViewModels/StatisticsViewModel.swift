import Foundation

final class StatisticsViewModel: ObservableObject {
    @Published private(set) var weeklyData: [DayStats] = []
    @Published private(set) var todayRate: Double = 0
    @Published private(set) var streak = 0
    @Published private(set) var completedThisWeek = 0

    private let storage: StorageManager

    init(storage: StorageManager = .shared) {
        self.storage = storage
        refresh()
    }

    var weeklyAverage: Double {
        guard !weeklyData.isEmpty else { return 0 }
        let total = weeklyData.reduce(0) { $0 + $1.completionRate }
        return total / Double(weeklyData.count)
    }

    var bestDay: DayStats? {
        weeklyData.max(by: { $0.completionRate < $1.completionRate })
    }

    func refresh() {
        weeklyData = storage.weeklyData()
        todayRate = storage.completionRate(for: Date())
        streak = storage.currentStreak

        let calendar = Calendar.current
        completedThisWeek = storage.tasks.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) && $0.isCompleted
        }.count
    }
}
