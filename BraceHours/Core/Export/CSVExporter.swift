import Foundation

enum CSVExporter {
    static func sessionsCSV(_ sessions: [WearSession], now: Date = .now) -> String {
        let iso = ISO8601DateFormatter()
        var lines = ["started,ended,minutes,note"]
        for s in sessions.sorted(by: { $0.startedAt < $1.startedAt }) {
            lines.append([
                iso.string(from: s.startedAt),
                s.endedAt.map { iso.string(from: $0) } ?? "",
                String(Int(s.duration(now: now) / 60)),
                s.note,
            ].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func dailyCSV(_ totals: [WearMath.DayTotal], goalHours: Double) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        var lines = ["date,hours,goal_hours,goal_met"]
        for t in totals {
            lines.append([df.string(from: t.day), String(format: "%.2f", t.hours), String(format: "%.1f", goalHours), t.hours >= goalHours ? "yes" : "no"].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func write(_ csv: String, suffix: String) throws -> URL {
        let url = ExportFile.temporaryURL(suffix: suffix, extension: "csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func quote(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.path }

    static func temporaryURL(suffix: String, extension ext: String) -> URL {
        let stamp = Formatters.fileStamp.string(from: .now)
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(suffix)-\(stamp)")
            .appendingPathExtension(ext)
    }
}
