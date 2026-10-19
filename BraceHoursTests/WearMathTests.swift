import XCTest
@testable import BraceHours

@MainActor
final class WearMathTests: XCTestCase {
    private let calendar = Calendar.current
    private func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: .now))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func testSessionCrossingMidnightSplitsAcrossDays() {
        let s = WearSession(startedAt: at(-1, 22), endedAt: at(0, 7))
        XCTAssertEqual(WearMath.seconds(sessions: [s], on: at(-1, 12)), 2 * 3600, accuracy: 1)
        XCTAssertEqual(WearMath.seconds(sessions: [s], on: at(0, 12)), 7 * 3600, accuracy: 1)
    }

    func testRunningSessionCountsUpToNow() {
        let now = at(0, 10)
        let s = WearSession(startedAt: at(0, 8), endedAt: nil)
        XCTAssertEqual(WearMath.seconds(sessions: [s], on: now, now: now), 2 * 3600, accuracy: 1)
    }

    func testDayTotalCapsAtTwentyFourHours() {
        let a = WearSession(startedAt: at(-1, 20), endedAt: at(1, 4))
        let b = WearSession(startedAt: at(0, 9), endedAt: at(0, 17))
        XCTAssertEqual(WearMath.seconds(sessions: [a, b], on: at(0, 12)), 24 * 3600, accuracy: 1)
    }

    func testStreakEndsYesterdayWhenTodayNotYetMet() {
        var sessions: [WearSession] = []
        for d in -3...(-1) { sessions.append(WearSession(startedAt: at(d, 0), endedAt: at(d, 19))) }
        sessions.append(WearSession(startedAt: at(0, 0), endedAt: at(0, 2)))
        XCTAssertEqual(WearMath.streak(sessions: sessions, goalHours: 18, now: at(0, 3)), 3)
    }

    func testStreakBreaksOnLowDay() {
        var sessions: [WearSession] = []
        sessions.append(WearSession(startedAt: at(-3, 0), endedAt: at(-3, 19)))
        sessions.append(WearSession(startedAt: at(-2, 0), endedAt: at(-2, 10)))
        sessions.append(WearSession(startedAt: at(-1, 0), endedAt: at(-1, 19)))
        XCTAssertEqual(WearMath.streak(sessions: sessions, goalHours: 18, now: at(0, 3)), 1)
    }

    func testStatsOverPeriod() {
        let sessions = [
            WearSession(startedAt: at(-2, 0), endedAt: at(-2, 20)),
            WearSession(startedAt: at(-1, 0), endedAt: at(-1, 12)),
            WearSession(startedAt: at(0, 0), endedAt: at(0, 18)),
        ]
        let stats = WearMath.stats(sessions: sessions, goalHours: 18, from: at(-2, 12), to: at(0, 23), now: at(0, 23))
        XCTAssertEqual(stats.days, 3)
        XCTAssertEqual(stats.daysMet, 2)
        XCTAssertEqual(stats.totalHours, 50, accuracy: 0.01)
        XCTAssertEqual(stats.averageHours, 50.0 / 3, accuracy: 0.01)
        XCTAssertEqual(stats.compliancePercent, 93)
        XCTAssertEqual(stats.longestStreak, 1)
        XCTAssertEqual(stats.bestDayHours, 20, accuracy: 0.01)
        XCTAssertEqual(stats.lowestDayHours, 12, accuracy: 0.01)
    }

    func testDurationFormatting() {
        XCTAssertEqual(Formatters.duration(14 * 3600 + 20 * 60 + 30), "14 hr 20 min")
        XCTAssertEqual(Formatters.duration(45 * 60), "45 min")
        XCTAssertEqual(Formatters.duration(2 * 3600), "2 hr")
        XCTAssertEqual(Formatters.duration(0), "0 min")
        XCTAssertEqual(Formatters.hours(17.5), "17.5 hr")
        XCTAssertEqual(Formatters.hours(18), "18 hr")
    }
}
