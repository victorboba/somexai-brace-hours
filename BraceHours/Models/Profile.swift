import Foundation
import SwiftData

/// The wearer and the prescription: who, which brace, how many hours a day the orthopedist asked for.
@Model
final class Profile {
    var id: UUID = UUID()
    var name: String = ""
    var braceName: String = ""
    var goalHours: Double = AppConfig.defaultGoalHours
    var startDate: Date = Date()
    var clinicName: String = ""
    var nextAppointment: Date? = nil
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String = "", braceName: String = "", goalHours: Double = AppConfig.defaultGoalHours) {
        self.name = name
        self.braceName = braceName
        self.goalHours = goalHours
    }

    var title: String {
        [name, braceName].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

enum BraceKinds {
    static let common = ["Boston brace", "Rigo-Cheneau", "Wilmington", "Providence (night)", "Charleston (night)", "Milwaukee", "SpineCor", "Other TLSO"]
}
