import AppIntents
import Foundation
import SwiftData

/// "Brace on in Brace Hours" / "Brace off in Brace Hours". Runs in the background, no need to open the app.
struct BraceOnIntent: AppIntent {
    static var title: LocalizedStringResource = "Brace On"
    static var description = IntentDescription("Starts timing brace wear.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppContainer.shared.mainContext
        guard BraceActions.profile(in: context) != nil else {
            return .result(dialog: "Set up your brace plan in Brace Hours first.")
        }
        if BraceActions.putOn(in: context) == nil {
            return .result(dialog: "The brace is already on.")
        }
        let today = WearMath.seconds(sessions: BraceActions.sessions(in: context), on: .now)
        return .result(dialog: "Brace on. \(Formatters.duration(today)) so far today.")
    }
}

struct BraceOffIntent: AppIntent {
    static var title: LocalizedStringResource = "Brace Off"
    static var description = IntentDescription("Stops timing brace wear.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppContainer.shared.mainContext
        guard let session = BraceActions.takeOff(in: context) else {
            return .result(dialog: "The brace is already off.")
        }
        let today = WearMath.seconds(sessions: BraceActions.sessions(in: context), on: .now)
        let goal = BraceActions.profile(in: context)?.goalHours ?? AppConfig.defaultGoalHours
        return .result(dialog: "Brace off after \(Formatters.duration(session.duration())). \(Formatters.duration(today)) of \(Formatters.hours(goal)) today.")
    }
}

struct BraceHoursShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: BraceOnIntent(), phrases: ["Brace on in \(.applicationName)", "Start the brace timer in \(.applicationName)"],
                    shortTitle: "Brace On", systemImageName: "play.circle")
        AppShortcut(intent: BraceOffIntent(), phrases: ["Brace off in \(.applicationName)", "Stop the brace timer in \(.applicationName)"],
                    shortTitle: "Brace Off", systemImageName: "stop.circle")
    }
}
