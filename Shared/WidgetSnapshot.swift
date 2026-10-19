import Foundation

/// Summary the app writes to the App Group for the widget.
struct WidgetSnapshot: Codable {
    var hasProfile: Bool = false
    var wearerName: String = ""
    var goalHours: Double = 18
    /// Seconds worn today not counting the running session.
    var secondsBeforeSession: Double = 0
    /// Start of the running session, nil when the brace is off.
    var sessionStart: Date? = nil
    /// When the brace last came off, for "Off since".
    var lastOff: Date? = nil
    var streakDays: Int = 0
    var nextAppointment: Date? = nil
    var updatedAt: Date = .now

    static let storageKey = "widget.snapshot"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConfig.appGroupID) ?? .standard
    }

    static func load() -> WidgetSnapshot {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return WidgetSnapshot()
        }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    /// Total seconds worn today as of `now`, including the running session.
    func secondsToday(now: Date = .now) -> Double {
        secondsBeforeSession + (sessionStart.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }

    static let placeholder = WidgetSnapshot(hasProfile: true, wearerName: "Ava", goalHours: 18, secondsBeforeSession: 9.5 * 3600,
                                            sessionStart: Date.now.addingTimeInterval(-95 * 60), streakDays: 12,
                                            nextAppointment: Calendar.current.date(byAdding: .day, value: 16, to: .now))
}
