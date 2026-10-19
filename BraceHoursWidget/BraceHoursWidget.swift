import WidgetKit
import SwiftUI
import ActivityKit

// MARK: Home Screen widget

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry { SnapshotEntry(date: .now, snapshot: .placeholder) }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        // The running-session timer text updates itself; refresh every 15 minutes for the totals and at midnight.
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [SnapshotEntry(date: .now, snapshot: snapshot)], policy: .after(refresh)))
    }
}

struct BraceHoursWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(s.wearerName.isEmpty ? AppConfig.appName : "\(s.wearerName) · \(AppConfig.appName)")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).lineLimit(1)
            if !s.hasProfile {
                Text("Set up the brace plan").font(.headline)
            } else if let start = s.sessionStart {
                Label("Brace on", systemImage: "play.circle.fill").font(.headline).foregroundStyle(.green)
                // Counts up from today's total as of when this session began.
                Text(timerInterval: start.addingTimeInterval(-s.secondsBeforeSession)...Date.distantFuture, countsDown: false)
                    .font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit()
            } else {
                Label(s.lastOff.map { "Off since \($0.formatted(date: .omitted, time: .shortened))" } ?? "Brace off", systemImage: "pause.circle")
                    .font(.headline).foregroundStyle(.orange)
                Text(Formatters.duration(s.secondsToday(now: entry.date)))
                    .font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit()
            }
            Text("of \(Formatters.hours(s.goalHours)) today").font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if family != .systemSmall {
                HStack {
                    if s.streakDays > 0 { Text("\(s.streakDays) goal days in a row").font(.caption2) }
                    Spacer()
                    if let next = s.nextAppointment { Text("Appt \(next.formatted(.dateTime.month(.abbreviated).day()))").font(.caption2) }
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Widget-side copy of the duration format (the widget target does not compile the app's Formatters).
private enum Formatters {
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds / 60)
        let h = total / 60, m = total % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
    static func hours(_ hours: Double) -> String {
        hours == hours.rounded() ? "\(Int(hours)) hr" : String(format: "%.1f hr", hours)
    }
}

struct BraceHoursWidget: Widget {
    let kind = "BraceHoursWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { BraceHoursWidgetView(entry: $0) }
            .configurationDisplayName(AppConfig.appName)
            .description("Today's brace hours and whether it is on right now.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: Live Activity (Lock Screen and Dynamic Island while the brace is on)

struct BraceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BraceActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "figure.stand").font(.title).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brace on\(context.attributes.wearerName.isEmpty ? "" : " · \(context.attributes.wearerName)")").font(.headline)
                    Text("Today, of \(Formatters.hours(context.state.goalHours))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(timerInterval: context.state.sessionStart.addingTimeInterval(-context.state.secondsBeforeSession)...Date.distantFuture, countsDown: false)
                    .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemBackground).opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Brace on", systemImage: "figure.stand").font(.headline).foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.sessionStart.addingTimeInterval(-context.state.secondsBeforeSession)...Date.distantFuture, countsDown: false)
                        .font(.title2.bold()).monospacedDigit().frame(maxWidth: 110)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Goal \(Formatters.hours(context.state.goalHours)) today").font(.caption).foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "figure.stand").foregroundStyle(.green)
            } compactTrailing: {
                Text(timerInterval: context.state.sessionStart.addingTimeInterval(-context.state.secondsBeforeSession)...Date.distantFuture, countsDown: false)
                    .monospacedDigit().frame(maxWidth: 64)
            } minimal: {
                Image(systemName: "figure.stand").foregroundStyle(.green)
            }
        }
    }
}

@main
struct BraceHoursWidgetBundle: WidgetBundle {
    var body: some Widget {
        BraceHoursWidget()
        BraceLiveActivity()
    }
}
