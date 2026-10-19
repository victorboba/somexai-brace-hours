import Foundation
import SwiftData

/// A note about the skin under the brace: where, how bad, a photo. Goes on the report.
@Model
final class SkinCheck {
    var id: UUID = UUID()
    var date: Date = Date()
    var areasRaw: String = ""
    var severity: Int = SkinSeverity.mild.rawValue
    var notes: String = ""
    @Attribute(.externalStorage) var photo: Data? = nil
    var createdAt: Date = Date()

    init(date: Date = .now) {
        self.date = date
    }

    var areas: [SkinArea] {
        get { areasRaw.split(separator: "|").compactMap { SkinArea(rawValue: String($0)) } }
        set { areasRaw = newValue.map(\.rawValue).joined(separator: "|") }
    }

    var severityValue: SkinSeverity {
        get { SkinSeverity(rawValue: severity) ?? .mild }
        set { severity = newValue.rawValue }
    }

    var areasLabel: String { areas.isEmpty ? "No area listed" : areas.map(\.rawValue).joined(separator: ", ") }
}

enum SkinArea: String, CaseIterable, Identifiable {
    case hips = "Hips", ribs = "Ribs", underarms = "Underarms", lowerBack = "Lower back", abdomen = "Abdomen"
    case chest = "Chest", shoulderBlades = "Shoulder blades", waist = "Waist", other = "Other"
    var id: String { rawValue }
}

enum SkinSeverity: Int, CaseIterable, Identifiable {
    case mild = 1, moderate = 2, severe = 3
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .mild: "Mild (redness)"
        case .moderate: "Moderate (sore, marks last)"
        case .severe: "Severe (blister or broken skin)"
        }
    }
    var short: String {
        switch self {
        case .mild: "Mild"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }
}
