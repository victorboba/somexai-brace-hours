import SwiftUI
import SwiftData

/// The daily screen: the ring, the big on/off button, today's sessions.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \WearSession.startedAt, order: .reverse) private var sessions: [WearSession]

    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingSkinCheck = false
    @State private var addingSession = false
    @State private var editingSession: WearSession?
    @State private var tick = Date.now

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var profile: Profile? { profiles.first }
    private var active: WearSession? { sessions.first { $0.isActive } }
    private var todaySeconds: TimeInterval { WearMath.seconds(sessions: sessions, on: tick, now: tick) }
    private var todaySessions: [WearSession] {
        sessions.filter { Calendar.current.isDateInToday($0.startedAt) || Calendar.current.isDateInToday($0.endedAt ?? tick) || $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    VStack(spacing: 20) {
                        header(profile)
                        ring(profile)
                        bigButton
                        sessionsList
                        Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                } else {
                    ContentUnavailableView {
                        Label("Set up the brace plan", systemImage: "person.crop.circle.badge.plus")
                    } description: {
                        Text("Enter the wearer, the brace, and the daily goal your orthopedist gave you.")
                    } actions: {
                        Button("Set Up") { showingProfile = true }.buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                    NavigationLink { HowToView() } label: { Image(systemName: "questionmark.circle") }.accessibilityLabel("How do I use this app")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if profile != nil {
                        Menu {
                            Button("Add missed time", systemImage: "clock.arrow.circlepath") { addingSession = true }
                            Button("Skin check", systemImage: "bandage") { showingSkinCheck = true }
                            Button("Edit brace plan", systemImage: "pencil") { showingProfile = true }
                        } label: { Image(systemName: "plus") }
                        .accessibilityLabel("More")
                    }
                }
            }
            .sheet(isPresented: $showingProfile) { ProfileEditorView(profile: profile) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingSkinCheck) { SkinCheckEditorView(check: nil) }
            .sheet(isPresented: $addingSession) { SessionEditorView(session: nil) }
            .sheet(item: $editingSession) { SessionEditorView(session: $0) }
        }
        .onReceive(timer) { tick = $0 }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sampleData"), profiles.isEmpty { SampleData.insert(into: context) }
            #endif
            BraceActions.afterChange(in: context)
        }
    }

    private func header(_ profile: Profile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.title.isEmpty ? "Brace plan" : profile.title).font(.title3.bold())
                Text("Goal \(Formatters.hours(profile.goalHours)) a day").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                let streak = WearMath.streak(sessions: sessions, goalHours: profile.goalHours, now: tick)
                Text(streak == 0 ? "No streak yet" : "\(streak) goal day\(streak == 1 ? "" : "s") in a row").font(.caption).foregroundStyle(.secondary)
                if let next = profile.nextAppointment {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: tick), to: Calendar.current.startOfDay(for: next)).day ?? 0
                    Text(days < 0 ? "Appointment was \(Formatters.date.string(from: next))" : days == 0 ? "Appointment today" : "Appointment in \(days) day\(days == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func ring(_ profile: Profile) -> some View {
        ProgressRing(progress: todaySeconds / (profile.goalHours * 3600), lineWidth: 20) {
            VStack(spacing: 4) {
                if let active {
                    Text("On for").font(.caption).foregroundStyle(.secondary)
                    Text(timerInterval: active.startedAt...Date.distantFuture, countsDown: false)
                        .font(.title2.weight(.semibold)).monospacedDigit()
                        .accessibilityIdentifier("brace.timer")
                } else {
                    Text("Today").font(.caption).foregroundStyle(.secondary)
                }
                Text(Formatters.duration(todaySeconds)).font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
                Text("of \(Formatters.hours(profile.goalHours))").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(width: 240, height: 240)
        .padding(.vertical, 8)
    }

    private var bigButton: some View {
        Button {
            if active != nil {
                BraceActions.takeOff(in: context)
                ReviewPrompter.recordSuccess(request: requestReview)
            } else {
                BraceActions.putOn(in: context)
            }
            tick = .now
        } label: {
            Label(active != nil ? "Brace off" : "Brace on", systemImage: active != nil ? "stop.circle.fill" : "play.circle.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(active != nil ? .orange : .accentColor)
        .controlSize(.large)
    }

    @ViewBuilder
    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's sessions").font(.headline)
                Spacer()
                Button("Add missed time") { addingSession = true }.font(.subheadline)
            }
            if todaySessions.isEmpty {
                Text("Nothing logged yet today.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(todaySessions) { session in
                Button { editingSession = session } label: {
                    HStack {
                        Image(systemName: session.isActive ? "circle.fill" : "checkmark.circle")
                            .foregroundStyle(session.isActive ? Color.green : Color.secondary).font(.caption)
                        Text("\(Formatters.time.string(from: session.startedAt)) – \(session.endedAt.map { Formatters.time.string(from: $0) } ?? "now")")
                        Spacer()
                        Text(Formatters.duration(session.duration(now: tick))).monospacedDigit().foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
