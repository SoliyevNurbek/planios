import Foundation

struct PlanTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var repeatType: RepeatType

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        priority: TaskPriority,
        isCompleted: Bool = false,
        repeatType: RepeatType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.isCompleted = isCompleted
        self.repeatType = repeatType
    }

    var startDate: Date {
        Self.merge(day: date, time: startTime)
    }

    var endDate: Date {
        let mergedEnd = Self.merge(day: date, time: endTime)
        if mergedEnd >= startDate {
            return mergedEnd
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: mergedEnd) ?? mergedEnd
    }

    var durationSeconds: Int {
        max(60, Int(endDate.timeIntervalSince(startDate)))
    }

    var durationMinutes: Int {
        max(1, durationSeconds / 60)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var focusProgressLabel: String {
        "\(durationMinutes) min session"
    }

    static func empty(referenceDate: Date = Date()) -> PlanTask {
        let start = referenceDate
        let end = Calendar.current.date(byAdding: .minute, value: 45, to: referenceDate) ?? referenceDate
        return PlanTask(
            title: "",
            description: "",
            date: referenceDate,
            startTime: start,
            endTime: end,
            priority: .medium,
            repeatType: .none
        )
    }

    static func merge(day: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dayComponents.year
        merged.month = dayComponents.month
        merged.day = dayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        return calendar.date(from: merged) ?? day
    }
}
