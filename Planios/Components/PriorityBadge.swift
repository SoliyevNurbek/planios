import SwiftUI

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: priority.icon)
                .font(.caption.weight(.bold))
            Text(priority.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(priority.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(priority.color.opacity(0.12), in: Capsule())
    }
}
