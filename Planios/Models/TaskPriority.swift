import SwiftUI

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .low:
            return .planGreen
        case .medium:
            return .planAmber
        case .high:
            return .planRed
        }
    }

    var icon: String {
        switch self {
        case .low:
            return "leaf.fill"
        case .medium:
            return "bolt.fill"
        case .high:
            return "flame.fill"
        }
    }

    var rank: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }
}
