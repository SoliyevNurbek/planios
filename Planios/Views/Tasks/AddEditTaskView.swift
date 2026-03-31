import SwiftUI

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tasks: TaskViewModel

    let existingTask: PlanTask?

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .minute, value: 45, to: Date()) ?? Date()
    @State private var priority: TaskPriority = .medium
    @State private var repeatType: RepeatType = .none

    private var isEditing: Bool {
        existingTask != nil
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        PlanTask.merge(day: date, time: endTime) > PlanTask.merge(day: date, time: startTime)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Task details")
                                .font(.headline.weight(.bold))

                            TextField("Title", text: $title)
                                .textInputAutocapitalization(.sentences)
                                .padding(14)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            TextField("Description", text: $description, axis: .vertical)
                                .lineLimit(3...5)
                                .textInputAutocapitalization(.sentences)
                                .padding(14)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Schedule")
                                .font(.headline.weight(.bold))

                            DatePicker("Date", selection: $date, displayedComponents: .date)
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Priority")
                                .font(.headline.weight(.bold))
                            Picker("Priority", selection: $priority) {
                                ForEach(TaskPriority.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Repeat")
                                .font(.headline.weight(.bold))
                            Picker("Repeat", selection: $repeatType) {
                                ForEach(RepeatType.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(AppTheme.horizontalPadding)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        tasks.closeEditor()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear(perform: populateIfNeeded)
        }
    }

    private func populateIfNeeded() {
        guard let task = existingTask else { return }
        title = task.title
        description = task.description
        date = task.date
        startTime = task.startTime
        endTime = task.endTime
        priority = task.priority
        repeatType = task.repeatType
    }

    private func saveTask() {
        let task = PlanTask(
            id: existingTask?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            startTime: startTime,
            endTime: endTime,
            priority: priority,
            isCompleted: existingTask?.isCompleted ?? false,
            repeatType: repeatType
        )

        if isEditing {
            tasks.updateTask(task)
        } else {
            tasks.addTask(task)
        }

        tasks.closeEditor()
        dismiss()
    }
}
