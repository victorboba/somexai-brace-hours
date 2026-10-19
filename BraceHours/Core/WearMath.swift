import Foundation

/// Pure wear-time arithmetic: sessions can cross midnight and one can still be running.
enum WearMath {
    struct DayTotal: Identifiable, Equatable {
        let day: Date
        let seconds: TimeInterval
        var id: Date { day }
        var hours: Double { seconds / 3600 }
    }

    struct Stats: Equatable {
        var days = 0
        var daysMet = 0
        var totalHours = 0.0
        var averageHours = 0.0
        var compliancePercent = 0
        var longestStreak = 0
        var bestDayHours = 0.0
        var lowestDayHours = 0.0
    }

    static func overlap(start: Date, end: Date, dayStart: Date, dayEnd: Date) -> TimeInterval {
        let s = max(start, dayStart), e = min(end, dayEnd)
        return max(0, e.timeIntervalSince(s))
    }

    /// Seconds worn on `day`, counting a running session up to `now`, capped at 24 hours.
    static func seconds(sessions: [WearSession], on day: Date, now: Date = .now, calendar: Calendar = .current) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let total = sessions.reduce(0.0) { sum, session in
            sum + overlap(start: session.startedAt, end: session.endedAt ?? now, dayStart: dayStart, dayEnd: dayEnd)
        }
        return min(total, 24 * 3600)
    }

    static func dailyTotals(sessions: [WearSession], from start: Date, to end: Date, now: Date = .now, calendar: Calendar = .current) -> [DayTotal] {
        var totals: [DayTotal] = []
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            totals.append(DayTotal(day: day, seconds: seconds(sessions: sessions, on: day, now: now, calendar: calendar)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return totals
    }

    /// Consecutive days meeting the goal, ending today if today already met it, otherwise ending yesterday.
    static func streak(sessions: [WearSession], goalHours: Double, now: Date = .now, calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: now)
        if seconds(sessions: sessions, on: day, now: now, calendar: calendar) < goalHours * 3600 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while seconds(sessions: sessions, on: day, now: now, calendar: calendar) >= goalHours * 3600 {
            count += 1
            guard count < 3650, let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    static func stats(sessions: [WearSession], goalHours: Double, from start: Date, to end: Date, now: Date = .now, calendar: Calendar = .current) -> Stats {
        let totals = dailyTotals(sessions: sessions, from: start, to: end, now: now, calendar: calendar)
        var s = Stats()
        s.days = totals.count
        guard s.days > 0 else { return s }
        s.daysMet = totals.filter { $0.hours >= goalHours }.count
        s.totalHours = totals.reduce(0) { $0 + $1.hours }
        s.averageHours = s.totalHours / Double(s.days)
        s.compliancePercent = goalHours > 0 ? min(100, Int((s.totalHours / (Double(s.days) * goalHours) * 100).rounded())) : 0
        s.bestDayHours = totals.map(\.hours).max() ?? 0
        s.lowestDayHours = totals.map(\.hours).min() ?? 0
        var run = 0
        for t in totals {
            run = t.hours >= goalHours ? run + 1 : 0
            s.longestStreak = max(s.longestStreak, run)
        }
        return s
    }
}
