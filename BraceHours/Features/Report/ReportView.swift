import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \WearSession.startedAt, order: .reverse) private var sessions: [WearSession]
    @Query(sort: \SkinCheck.date, order: .reverse) private var skinChecks: [SkinCheck]

    @State private var period: Period = .days30
    @State private var exportFile: ExportFile?
    @State private var exportError: String?
    @State private var editingCheck: SkinCheck?

    enum Period: String, CaseIterable, Identifiable {
        case days7 = "7 days", days30 = "30 days", days90 = "90 days", all = "Since start"
        var id: String { rawValue }
    }

    private var profile: Profile? { profiles.first }

    private var start: Date {
        let today = Calendar.current.startOfDay(for: .now)
        let days: Int
        switch period {
        case .days7: days = 6
        case .days30: days = 29
        case .days90: days = 89
        case .all: return Calendar.current.startOfDay(for: min(profile?.startDate ?? today, sessions.map(\.startedAt).min() ?? today))
        }
        let candidate = Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
        return max(candidate, Calendar.current.startOfDay(for: profile?.startDate ?? candidate))
    }

    private var stats: WearMath.Stats {
        guard let profile else { return WearMath.Stats() }
        return WearMath.stats(sessions: sessions, goalHours: profile.goalHours, from: start, to: .now)
    }

    private var periodChecks: [SkinCheck] { skinChecks.filter { $0.date >= start } }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    List {
                        Section {
                            Picker("Period", selection: $period) { ForEach(Period.allCases) { Text($0.rawValue).tag($0) } }
                                .pickerStyle(.segmented).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                        }
                        Section("\(Formatters.date.string(from: start)) to today · \(stats.days) day\(stats.days == 1 ? "" : "s")") {
                            LabeledContent("Average per day", value: Formatters.duration(stats.averageHours * 3600))
                            LabeledContent("Days at goal", value: "\(stats.daysMet) of \(stats.days)")
                            LabeledContent("Share of prescribed hours", value: "\(stats.compliancePercent)%")
                            LabeledContent("Longest run of goal days", value: "\(stats.longestStreak)")
                            LabeledContent("Best day", value: Formatters.duration(stats.bestDayHours * 3600))
                            LabeledContent("Lowest day", value: Formatters.duration(stats.lowestDayHours * 3600))
                            LabeledContent("Goal", value: "\(Formatters.hours(profile.goalHours)) a day")
                        }
                        Section("Skin checks (\(periodChecks.count))") {
                            if periodChecks.isEmpty { Text("None in this period.").foregroundStyle(.secondary) }
                            ForEach(periodChecks) { check in
                                Button { editingCheck = check } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Formatters.date.string(from: check.date)) · \(check.severityValue.short)")
                                        Text(check.areasLabel).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Section("Export") {
                            Button { export { try ReportExporter.export(profile: profile, sessions: sessions, skinChecks: skinChecks, from: start) } } label: {
                                Label("PDF report for the orthopedist", systemImage: "doc.richtext")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.dailyCSV(WearMath.dailyTotals(sessions: sessions, from: start, to: .now), goalHours: profile.goalHours), suffix: "daily") } } label: {
                                Label("Hours per day CSV", systemImage: "tablecells")
                            }
                            Button { export { try CSVExporter.write(CSVExporter.sessionsCSV(sessions.filter { ($0.endedAt ?? .now) >= start }), suffix: "sessions") } } label: {
                                Label("Sessions CSV", systemImage: "tablecells")
                            }
                        }
                        Section { Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary) }
                    }
                } else {
                    ContentUnavailableView("No brace plan yet", systemImage: "doc.text", description: Text("Set up the plan on Today to start a report."))
                }
            }
            .navigationTitle("Report")
            .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
            .sheet(item: $editingCheck) { SkinCheckEditorView(check: $0) }
            .alert("Export failed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK") { exportError = nil }
            } message: { Text(exportError ?? "") }
        }
    }

    private func export(_ make: () throws -> URL) {
        do { exportFile = ExportFile(url: try make()) } catch { exportError = error.localizedDescription }
    }
}
