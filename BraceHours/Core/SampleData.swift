import Foundation
import SwiftData

#if DEBUG
/// Debug-only sample data: six weeks of a typical school-week pattern (on for school, off for sport
/// and showers, on overnight) averaging around 19 hours, a few low days, two skin notes, and the brace
/// currently on. Clearly fictional.
@MainActor
enum SampleData {
    static func insert(into context: ModelContext) {
        let calendar = Calendar.current
        if BraceActions.profile(in: context) == nil {
            let profile = Profile(name: "Ava", braceName: "Rigo-Cheneau", goalHours: 18)
            profile.startDate = calendar.date(byAdding: .day, value: -60, to: .now) ?? .now
            profile.clinicName = "Children's Orthopedics"
            profile.nextAppointment = calendar.date(byAdding: .day, value: 16, to: .now)
            context.insert(profile)
        }
        let existing = BraceActions.sessions(in: context)
        let loggedDays = Set(existing.map { calendar.startOfDay(for: $0.startedAt) })

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: .now)) ?? .now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        for offset in stride(from: -42, through: -1, by: 1) {
            guard !loggedDays.contains(at(offset, 0, 0)) else { continue }
            let weekday = calendar.component(.weekday, from: at(offset, 12, 0))
            let lowDay = offset % 11 == 0
            let weekend = weekday == 1 || weekday == 7
            // Overnight session that started the evening before and ends this morning.
            context.insert(WearSession(startedAt: at(offset - 1, 21, 30 + (abs(offset) % 3) * 5), endedAt: at(offset, 7, (abs(offset) % 4) * 5)))
            if weekend {
                context.insert(WearSession(startedAt: at(offset, 9, 15), endedAt: at(offset, lowDay ? 11 : 13, 30)))
                context.insert(WearSession(startedAt: at(offset, 15, 0), endedAt: at(offset, 21, 20)))
            } else {
                context.insert(WearSession(startedAt: at(offset, 7, 45), endedAt: at(offset, lowDay ? 12 : 15, 40)))
                if !lowDay { context.insert(WearSession(startedAt: at(offset, 17, 10), endedAt: at(offset, 21, 25))) }
            }
        }
        // Today: overnight ended this morning, brace back on for the school day and still on.
        if !loggedDays.contains(at(0, 0, 0)) {
            context.insert(WearSession(startedAt: at(-1, 21, 40), endedAt: at(0, 6, 50)))
            let now = Date.now
            let hour = calendar.component(.hour, from: now)
            if hour >= 9 {
                context.insert(WearSession(startedAt: at(0, 7, 50), endedAt: nil))
            }
        }
        if (try? context.fetch(FetchDescriptor<SkinCheck>()))?.isEmpty ?? true {
            let a = SkinCheck(date: at(-18, 20, 0))
            a.areas = [.hips, .ribs]
            a.severityValue = .moderate
            a.notes = "Red marks on the right hip after PE, faded by morning. Orthotist adjusted the pad."
            context.insert(a)
            let b = SkinCheck(date: at(-4, 21, 0))
            b.areas = [.underarms]
            b.severityValue = .mild
            b.notes = "Slight chafing, using the cotton liner."
            context.insert(b)
        }
        try? context.save()
        BraceActions.afterChange(in: context)
    }
}
#endif
