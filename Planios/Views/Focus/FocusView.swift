import SwiftUI

struct FocusView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tasks: TaskViewModel
    @StateObject private var viewModel: FocusViewModel

    init(task: PlanTask) {
        _viewModel = StateObject(wrappedValue: FocusViewModel(task: task) { completedTask in
            StorageManager.shared.markTaskCompleted(id: completedTask.id)
            NotificationManager.shared.cancelNotifications(for: completedTask.id)
        })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.planGreenDark, Color.planGreen, Color.planMint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                header
                timerRing
                taskInfo
                controls
            }
            .padding(24)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            viewModel.start()
        }
        .onChange(of: viewModel.hasCompletedSession) { completed in
            if completed {
                tasks.markTaskCompleted(viewModel.task)
            }
        }
        .alert("Leave focus mode?", isPresented: $viewModel.showExitAlert) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive) {
                viewModel.pause()
                dismiss()
            }
        } message: {
            Text("This session was meant to protect your momentum. Finish the block unless you need to stop.")
        }
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.requestExit()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Focus Mode")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
            Text(viewModel.randomMotivation)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding(.top, 50)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.14), lineWidth: 20)
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: min(viewModel.progress, 1))
                .stroke(.white, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 260, height: 260)

            VStack(spacing: 8) {
                Text(viewModel.formattedTime)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Remaining")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .padding(.vertical, 16)
    }

    private var taskInfo: some View {
        VStack(spacing: 10) {
            Text(viewModel.task.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text(viewModel.task.description.isEmpty ? viewModel.task.focusProgressLabel : viewModel.task.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.84))
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            PrimaryButton(
                title: viewModel.isRunning ? "Pause Session" : "Resume Session",
                icon: viewModel.isRunning ? "pause.fill" : "play.fill"
            ) {
                viewModel.isRunning ? viewModel.pause() : viewModel.start()
            }

            Button {
                viewModel.completeSession()
                dismiss()
            } label: {
                Text("Mark Complete")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}
