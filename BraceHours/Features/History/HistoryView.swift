import SwiftUI
import SwiftData

/// Two weeks of bars, then every day back to the start of bracing. Tap a day to see and fix its sessions.
struct HistoryView: View {
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \WearSession.startedAt, order: .reverse) private var sessions: [WearSession]
    @Query(sort: \SkinCheck.date, order: .reverse) private var skinChecks: [SkinCheck]

    private var profile: Profile? { profiles.first }

    private var chartTotals: [WearMath.DayTotal] {
        let start = Calendar.current.date(byAdding: .day, value: -13, to: .now) ?? .now
        return WearMath.dailyTotals(sessions: sessions, from: start, to: .now)
    }

    private var allTotals: [WearMath.DayTotal] {
        guard let profile else { return [] }
        let first = min(profile.startDate, sessions.map(\.startedAt).min() ?? .now)
        return WearMath.dailyTotals(sessions: sessions, from: first, to: .now).reversed()
    }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    List {
                        Section("Last 14 days") {
                            WearChart(totals: chartTotals, goalHours: profile.goalHours)
                                .frame(height: 200)
                                .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 8, trailing: 16))
                        }
                        Section("Every day") {
                            ForEach(allTotals) { total in
                                NavigationLink(value: total.day) {
                                    DayRow(total: total, goalHours: profile.goalHours,
                                           skinCheck: skinChecks.contains { Calendar.current.isDate($0.date, inSameDayAs: total.day) })
                                }
                            }
                        }
                    }
                    .navigationDestination(for: Date.self) { day in DayDetailView(day: day) }
                } else {
                    ContentUnavailableView("No brace plan yet", systemImage: "chart.bar", description: Text("Set up the plan on Today to start the history."))
                }
            }
            .navigationTitle("History")
        }
    }
}

struct DayRow: View {
    let total: WearMath.DayTotal
    let goalHours: Double
    var skinCheck = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: total.hours >= goalHours ? "checkmark.circle.fill" : total.seconds == 0 ? "circle" : "circle.lefthalf.filled")
                .foregroundStyle(total.hours >= goalHours ? .green : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(total.day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    if skinCheck { Image(systemName: "bandage").font(.caption).foregroundStyle(.orange) }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.accentColor.opacity(0.12))
                        Capsule().fill(total.hours >= goalHours ? Color.green : Color.accentColor)
                            .frame(width: geo.size.width * min(1, total.hours / 24))
                    }
                }
                .frame(height: 6)
            }
            Spacer()
            Text(Formatters.duration(total.seconds)).monospacedDigit().foregroundStyle(.secondary)
        }
    }
}

/// One day: its sessions (editable) and skin checks.
struct DayDetailView: View {
    let day: Date

    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \WearSession.startedAt, order: .reverse) private var sessions: [WearSession]
    @Query(sort: \SkinCheck.date, order: .reverse) private var skinChecks: [SkinCheck]

    @State private var editingSession: WearSession?
    @State private var editingCheck: SkinCheck?
    @State private var adding = false

    private var daySessions: [WearSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) || calendar.isDate($0.endedAt ?? .now, inSameDayAs: day) || ($0.startedAt < calendar.startOfDay(for: day) && ($0.endedAt ?? .now) > calendar.startOfDay(for: day)) }
    }
    private var dayChecks: [SkinCheck] { skinChecks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) } }
    private var seconds: TimeInterval { WearMath.seconds(sessions: sessions, on: day) }

    var body: some View {
        List {
            Section {
                LabeledContent("Worn", value: Formatters.duration(seconds))
                if let goal = profiles.first?.goalHours {
                    LabeledContent("Goal", value: Formatters.hours(goal))
                    LabeledContent("Result", value: seconds >= goal * 3600 ? "Goal met" : "Below goal")
                }
            }
            Section {
                ForEach(daySessions) { session in
                    Button { editingSession = session } label: {
                        HStack {
                            Text("\(Formatters.dateTime.string(from: session.startedAt)) – \(session.endedAt.map { Formatters.time.string(from: $0) } ?? "now")")
                            Spacer()
                            Text(Formatters.duration(session.duration())).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in offsets.map { daySessions[$0] }.forEach(context.delete); try? context.save(); BraceActions.afterChange(in: context) }
                Button { adding = true } label: { Label("Add missed time", systemImage: "plus") }
            } header: {
                Text("Sessions")
            } footer: {
                Text("A session that crosses midnight counts toward both days.")
            }
            if !dayChecks.isEmpty {
                Section("Skin checks") {
                    ForEach(dayChecks) { check in
                        Button { editingCheck = check } label: {
                            VStack(alignment: .leading) {
                                Text("\(check.severityValue.short) · \(check.areasLabel)")
                                if !check.notes.isEmpty { Text(check.notes).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingSession) { SessionEditorView(session: $0) }
        .sheet(item: $editingCheck) { SkinCheckEditorView(check: $0) }
        .sheet(isPresented: $adding) { SessionEditorView(session: nil) }
    }
}
