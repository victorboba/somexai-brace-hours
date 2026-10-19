import Foundation
import WidgetKit

enum WidgetSync {
    static func update(profile: Profile?, sessions: [WearSession]) {
        var snapshot = WidgetSnapshot()
        if let profile {
            snapshot.hasProfile = true
            snapshot.wearerName = profile.name
            snapshot.goalHours = profile.goalHours
            snapshot.nextAppointment = profile.nextAppointment
            let active = sessions.first { $0.isActive }
            snapshot.sessionStart = active?.startedAt
            snapshot.secondsBeforeSession = WearMath.seconds(sessions: sessions.filter { !$0.isActive }, on: .now)
            snapshot.lastOff = sessions.compactMap(\.endedAt).max()
            snapshot.streakDays = WearMath.streak(sessions: sessions, goalHours: profile.goalHours)
        }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
