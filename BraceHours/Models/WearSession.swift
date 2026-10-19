import Foundation
import SwiftData

/// One stretch of time with the brace on. `endedAt == nil` means it is on right now.
@Model
final class WearSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date? = nil
    var note: String = ""
    var createdAt: Date = Date()

    init(startedAt: Date = .now, endedAt: Date? = nil, note: String = "") {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.note = note
    }

    var isActive: Bool { endedAt == nil }

    func duration(now: Date = .now) -> TimeInterval {
        max(0, (endedAt ?? now).timeIntervalSince(startedAt))
    }
}
