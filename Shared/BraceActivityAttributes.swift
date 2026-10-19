import ActivityKit
import Foundation

/// Live Activity shown on the Lock Screen and Dynamic Island while the brace is on.
struct BraceActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the current session started.
        var sessionStart: Date
        /// Seconds already worn today before this session, so the total keeps counting from the right number.
        var secondsBeforeSession: Double
        var goalHours: Double
    }

    var wearerName: String
}
