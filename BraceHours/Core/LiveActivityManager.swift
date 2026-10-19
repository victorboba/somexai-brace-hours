import ActivityKit
import Foundation

/// Lock Screen and Dynamic Island timer while the brace is on. Ends when it comes off.
enum LiveActivityManager {
    static func start(profile: Profile, session: WearSession, secondsBefore: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = BraceActivityAttributes.ContentState(sessionStart: session.startedAt, secondsBeforeSession: secondsBefore, goalHours: profile.goalHours)
        if let existing = Activity<BraceActivityAttributes>.activities.first {
            Task { await existing.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }
        let attributes = BraceActivityAttributes(wearerName: profile.name)
        _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil), pushType: nil)
    }

    static func end() {
        let activities = Activity<BraceActivityAttributes>.activities
        guard !activities.isEmpty else { return }
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
