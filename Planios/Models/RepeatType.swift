import Foundation

enum RepeatType: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none:
            return "minus.circle"
        case .daily:
            return "repeat"
        case .weekly:
            return "calendar.badge.clock"
        }
    }
}
