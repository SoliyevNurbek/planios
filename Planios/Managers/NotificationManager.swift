import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configure() {
        center.delegate = self
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            self?.refreshAuthorizationStatus()
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func scheduleNotifications(for task: PlanTask, reminderLeadMinutes: Int = 10) {
        cancelNotifications(for: task.id)

        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "Focus starts soon"
        reminderContent.body = task.title
        reminderContent.sound = .default

        let reminderDate = Calendar.current.date(byAdding: .minute, value: -reminderLeadMinutes, to: task.startDate) ?? task.startDate
        let reminderTrigger = makeTrigger(for: reminderDate, repeatType: task.repeatType)
        let reminderRequest = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: reminderContent,
            trigger: reminderTrigger
        )

        let followUpContent = UNMutableNotificationContent()
        followUpContent.title = "Task still open"
        followUpContent.body = "Finish \(task.title) before momentum drops."
        followUpContent.sound = .default

        let followUpDate = Calendar.current.date(byAdding: .minute, value: 15, to: task.endDate) ?? task.endDate
        let followUpTrigger = makeTrigger(for: followUpDate, repeatType: task.repeatType)
        let followUpRequest = UNNotificationRequest(
            identifier: "\(task.id.uuidString).followup",
            content: followUpContent,
            trigger: followUpTrigger
        )

        center.add(reminderRequest)
        center.add(followUpRequest)
    }

    func cancelNotifications(for taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID.uuidString, "\(taskID.uuidString).followup"])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private func makeTrigger(for date: Date, repeatType: RepeatType) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        switch repeatType {
        case .none:
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .daily:
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            var components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
            components.weekday = calendar.component(.weekday, from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
