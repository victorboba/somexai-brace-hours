import Foundation
import SwiftData

/// The two things the app does all day: brace on, brace off. Used by the Today button and the Siri intents,
/// so the widget, Live Activity and reminder stay in step no matter where the tap came from.
@MainActor
enum BraceActions {
    static func profile(in context: ModelContext) -> Profile? {
        (try? context.fetch(FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])))?.first
    }

    static func sessions(in context: ModelContext) -> [WearSession] {
        (try? context.fetch(FetchDescriptor<WearSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))) ?? []
    }

    static func activeSession(in context: ModelContext) -> WearSession? {
        sessions(in: context).first { $0.isActive }
    }

    /// Starts a session now. Returns nil if one is already running.
    @discardableResult
    static func putOn(in context: ModelContext, at date: Date = .now) -> WearSession? {
        guard activeSession(in: context) == nil else { return nil }
        let session = WearSession(startedAt: date)
        context.insert(session)
        try? context.save()
        afterChange(in: context)
        OffReminder.cancel()
        return session
    }

    /// Ends the running session. Returns it, or nil if none was running.
    @discardableResult
    static func takeOff(in context: ModelContext, at date: Date = .now) -> WearSession? {
        guard let session = activeSession(in: context) else { return nil }
        session.endedAt = max(date, session.startedAt)
        try? context.save()
        afterChange(in: context)
        Task { await OffReminder.scheduleAfterStop(at: session.endedAt ?? date) }
        return session
    }

    /// Recomputes the widget snapshot and the Live Activity after any edit.
    static func afterChange(in context: ModelContext) {
        let all = sessions(in: context)
        let profile = profile(in: context)
        WidgetSync.update(profile: profile, sessions: all)
        if let active = all.first(where: \.isActive), let profile {
            let before = WearMath.seconds(sessions: all.filter { !$0.isActive }, on: .now)
            LiveActivityManager.start(profile: profile, session: active, secondsBefore: before)
        } else {
            LiveActivityManager.end()
        }
    }
}
