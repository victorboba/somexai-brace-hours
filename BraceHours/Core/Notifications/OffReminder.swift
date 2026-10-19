import Foundation
import UserNotifications

/// One local notification: the brace has been off longer than the limit. Scheduled when a session ends,
/// cancelled when the next one starts, and only during waking hours.
enum OffReminder {
    static let enabledKey = "reminder.off.enabled"
    static let hoursKey = "reminder.off.hours"
    static let identifier = "brace.off"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) == nil ? true : UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var limitHours: Double {
        let v = UserDefaults.standard.double(forKey: hoursKey)
        return v == 0 ? AppConfig.defaultOffReminderHours : v
    }

    static func ensurePermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied: return false
        default: return true
        }
    }

    static func scheduleAfterStop(at stop: Date) async {
        cancel()
        guard isEnabled, await ensurePermission() else { return }
        var fireAt = stop.addingTimeInterval(limitHours * 3600)
        // Don't nag between 10 pm and 7 am; push a night-time reminder to 7 am.
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: fireAt)
        if hour >= 22 || hour < 7 {
            let base = hour >= 22 ? calendar.date(byAdding: .day, value: 1, to: fireAt) ?? fireAt : fireAt
            fireAt = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: base) ?? fireAt
        }
        let seconds = fireAt.timeIntervalSinceNow
        guard seconds > 30 else { return }
        let content = UNMutableNotificationContent()
        content.title = AppConfig.appName
        content.body = "The brace has been off for \(Formatters.hours(limitHours)). Time to put it back on?"
        content.sound = .default
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content,
                                                                                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
