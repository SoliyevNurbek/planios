import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var tasks: TaskViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    progressSection
                    recommendationSection
                    nextDaySection
                    todaySection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.bottom, 30)
            }
            .background(background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        tasks.prepareNewTask()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.planGreen)
                    }
                }
            }
            .sheet(isPresented: $tasks.isPresentingEditor, onDismiss: tasks.closeEditor) {
                AddEditTaskView(existingTask: tasks.editingTask)
                    .environmentObject(tasks)
            }
            .fullScreenCover(item: $tasks.selectedFocusTask) { task in
                FocusView(task: task)
                    .environmentObject(tasks)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.planBackground, Color(.systemGroupedBackground), Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var heroSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(greeting)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's target")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(tasks.todayCompletedCount) of \(tasks.todayTasks.count) tasks complete")
                            .font(.title3.weight(.bold))
                    }

                    Spacer()

                    ProgressRing(progress: tasks.todayCompletionRate, size: 92)
                }
            }
        }
        .padding(.top, 8)
    }

    private var progressSection: some View {
        HStack(spacing: 14) {
            StatCard(
                title: "Streak",
                value: "\(tasks.currentStreak)d",
                caption: "Days with full completion",
                icon: "flame.fill",
                iconColor: .orange
            )

            StatCard(
                title: "Weekly Avg",
                value: "\(Int(tasks.weeklyCompletionRate * 100))%",
                caption: "Average completion rate",
                icon: "chart.bar.fill",
                iconColor: .planGreen
            )
        }
    }

    private var recommendationSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Focus recommendation", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.planGreen)

                if let nextTask = tasks.todayTasks.first(where: { !$0.isCompleted }) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(nextTask.title)
                                .font(.title3.weight(.bold))
                            Text("\(nextTask.formattedTimeRange) • \(nextTask.focusProgressLabel)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Focus") {
                            tasks.selectedFocusTask = nextTask
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.planGreen)
                    }
                } else {
                    Text("Your next focus block will appear here when there is an unfinished task scheduled for today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var nextDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tomorrow Planner")
                .font(.title3.weight(.bold))

            if tasks.tomorrowTasks.isEmpty {
                EmptyStateView(
                    icon: "sunrise.fill",
                    title: "Nothing planned for tomorrow",
                    subtitle: "Set tomorrow's most important tasks now while context is still fresh.",
                    buttonTitle: "Plan Tomorrow"
                ) {
                    tasks.prepareNewTask(defaultDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                }
            } else {
                ForEach(tasks.tomorrowTasks.prefix(2)) { task in
                    TaskCard(task: task, onToggle: { tasks.toggleCompletion(id: task.id) }, onTap: {
                        tasks.prepareEdit(task)
                    }, onFocus: {
                        tasks.selectedFocusTask = task
                    })
                }
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(.title3.weight(.bold))
                Spacer()
                Button("See all") {
                    appState.selectedTab = .tasks
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.planGreen)
            }

            if tasks.todayTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.badge.plus",
                    title: "No tasks for today",
                    subtitle: "Create a realistic plan with clear start and end times.",
                    buttonTitle: "Add Task"
                ) {
                    tasks.prepareNewTask()
                }
            } else {
                ForEach(tasks.todayTasks.prefix(4)) { task in
                    TaskCard(task: task, onToggle: { tasks.toggleCompletion(id: task.id) }, onTap: {
                        tasks.prepareEdit(task)
                    }, onFocus: {
                        tasks.selectedFocusTask = task
                    })
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Reset the day"
        }
    }
}
