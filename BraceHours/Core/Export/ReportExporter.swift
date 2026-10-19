import SwiftUI
import UIKit

/// The wear-time report for the orthopedist: stats, a chart, hours per day, skin notes with photos.
@MainActor
enum ReportExporter {
    static func export(profile: Profile, sessions: [WearSession], skinChecks: [SkinCheck], from start: Date, to end: Date = .now) throws -> URL {
        let totals = WearMath.dailyTotals(sessions: sessions, from: start, to: end)
        let stats = WearMath.stats(sessions: sessions, goalHours: profile.goalHours, from: start, to: end)
        let checks = skinChecks.filter { $0.date >= Calendar.current.startOfDay(for: start) && $0.date <= end }.sorted { $0.date < $1.date }
        let chart = ImageRenderer(content: WearChart(totals: totals, goalHours: profile.goalHours).frame(width: 720, height: 260).padding(8).background(Color.white))
        chart.scale = 2
        let chartImage = chart.uiImage

        let footer = "\(AppConfig.appName) · wear time entered by the wearer or family · not a clinical measurement"
        return try PDFCanvas.render(footer: footer) { pdf in
            pdf.title("Brace wear-time report")
            pdf.subtitle("\(profile.title) · \(Formatters.date.string(from: start)) to \(Formatters.date.string(from: end)) · generated \(Formatters.dateTime.string(from: .now))")

            pdf.heading("Prescription as entered")
            var pairs: [(String, String)] = [
                ("Wearer", profile.name.isEmpty ? "—" : profile.name),
                ("Brace", profile.braceName.isEmpty ? "—" : profile.braceName),
                ("Daily goal", "\(Formatters.hours(profile.goalHours)) per day"),
                ("Bracing since", Formatters.date.string(from: profile.startDate)),
            ]
            if !profile.clinicName.isEmpty { pairs.append(("Clinic", profile.clinicName)) }
            if let next = profile.nextAppointment { pairs.append(("Next appointment", Formatters.date.string(from: next))) }
            pdf.keyValues(pairs)

            pdf.heading("Summary for the period")
            pdf.keyValues([
                ("Days in period", "\(stats.days)"),
                ("Average per day", Formatters.duration(stats.averageHours * 3600)),
                ("Days at or above goal", "\(stats.daysMet) of \(stats.days)"),
                ("Share of prescribed hours", "\(stats.compliancePercent)%"),
                ("Longest run of goal days", "\(stats.longestStreak)"),
                ("Best day", Formatters.duration(stats.bestDayHours * 3600)),
                ("Lowest day", Formatters.duration(stats.lowestDayHours * 3600)),
            ])

            if let chartImage {
                pdf.spacer(6)
                pdf.image(chartImage, caption: "Hours per day; the line is the daily goal.", maxHeight: 190)
            }

            pdf.heading("Skin checks")
            pdf.table(headers: ["Date", "Areas", "Severity", "Notes"], widths: [0.16, 0.26, 0.14, 0.44],
                      rows: checks.map { [Formatters.date.string(from: $0.date), $0.areasLabel, $0.severityValue.short, $0.notes] })
            for check in checks {
                if let data = check.photo, let image = UIImage(data: data) {
                    pdf.image(image, caption: "\(Formatters.date.string(from: check.date)) · \(check.areasLabel)")
                }
            }

            pdf.heading("Hours per day")
            pdf.table(headers: ["Date", "Hours worn", "Goal met", "Sessions"], widths: [0.3, 0.25, 0.2, 0.25],
                      rows: totals.reversed().map { t in
                          let count = sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: t.day) || Calendar.current.isDate($0.endedAt ?? .now, inSameDayAs: t.day) }.count
                          return [Formatters.date.string(from: t.day), Formatters.duration(t.seconds), t.hours >= profile.goalHours ? "Yes" : "No", "\(count)"]
                      })

            pdf.spacer(10)
            pdf.paragraph(AppConfig.disclaimer, color: .darkGray)
        }
    }
}
