import SwiftUI

struct SettingsView: View {
    @StateObject private var notifications = NotificationManager.shared
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    settingsCard
                    aboutCard
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    private var settingsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Notifications")
                    .font(.headline.weight(.bold))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Permission status")
                            .font(.subheadline.weight(.semibold))
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Enable") {
                        notifications.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.planGreen)
                }

                Divider()

                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("Reset demo data", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .alert("Reset app data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                StorageManager.shared.resetAll()
            }
        } message: {
            Text("This clears tasks and onboarding state.")
        }
    }

    private var aboutCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("About Planios")
                    .font(.headline.weight(.bold))
                Text("Planios is a green, minimal productivity app built around realistic planning, focused execution, and visible progress.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("MVP features")
                        .font(.subheadline.weight(.semibold))
                    Text("Daily, tomorrow, and weekly task planning")
                    Text("Local reminders before and after tasks")
                    Text("Focus mode with countdown and guarded exit")
                    Text("Completion rate and streak tracking")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var statusText: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled."
        case .denied:
            return "Permission is denied. Update this from iOS Settings."
        case .notDetermined:
            return "Permission has not been requested yet."
        @unknown default:
            return "Unknown notification status."
        }
    }
}
