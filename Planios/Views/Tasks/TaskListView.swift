import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var tasks: TaskViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                filterBar
                searchBar
                taskContent
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tasks")
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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskViewModel.TaskFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            tasks.selectedFilter = filter
                        }
                    } label: {
                        FilterChip(title: filter.rawValue, isSelected: tasks.selectedFilter == filter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search title or description", text: $tasks.searchText)

            if !tasks.searchText.isEmpty {
                Button {
                    tasks.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var taskContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if tasks.filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: "No tasks in this view",
                        subtitle: "Adjust the filter or create a new task with a realistic schedule.",
                        buttonTitle: "Create Task"
                    ) {
                        tasks.prepareNewTask()
                    }
                } else {
                    ForEach(tasks.filteredTasks) { task in
                        TaskCard(task: task, onToggle: {
                            tasks.toggleCompletion(id: task.id)
                        }, onTap: {
                            tasks.prepareEdit(task)
                        }, onFocus: {
                            tasks.selectedFocusTask = task
                        })
                        .contextMenu {
                            Button {
                                tasks.prepareEdit(task)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                tasks.deleteTask(id: task.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }
}
