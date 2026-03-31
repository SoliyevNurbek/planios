import SwiftUI

struct TaskCard: View {
    let task: PlanTask
    var onToggle: () -> Void = {}
    var onTap: () -> Void = {}
    var onFocus: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? Color.planGreen : Color.secondary.opacity(0.25), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if task.isCompleted {
                            Circle()
                                .fill(Color.planGreen)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title)
                                .font(.headline)
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                .strikethrough(task.isCompleted)

                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: 8)
                        PriorityBadge(priority: task.priority)
                    }

                    HStack(spacing: 12) {
                        Label(task.formattedTimeRange, systemImage: "clock")
                        Label(task.formattedDate, systemImage: "calendar")
                        if task.repeatType != .none {
                            Label(task.repeatType.rawValue, systemImage: task.repeatType.icon)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    if !task.isCompleted {
                        Button(action: onFocus) {
                            Label("Start Focus", systemImage: "scope")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.planGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: AppTheme.cardShadow, radius: 14, x: 0, y: 8)
            )
            .opacity(task.isCompleted ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }
}
