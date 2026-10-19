import Foundation

/// The one file to edit per app. Compiled into the app and the widget: Foundation only.
enum AppConfig {
    // MARK: Identity
    static let appName = "Brace Hours"
    static let bundleID = "com.example.brace-hours"
    static let appGroupID = "group.com.example.brace-hours"
    static let appStoreID = ""

    // MARK: Sync
    static let iCloudSyncEnabled = false

    // MARK: StoreKit
    static let productPrefix = bundleID.replacingOccurrences(of: "-", with: "")
    static let annualProductID = "\(productPrefix).pro.annual"
    static let lifetimeProductID = "\(productPrefix).pro.lifetime"

    // MARK: Links
    static let supportEmail = "support@somexai.com"
    static let privacyPolicyURL = URL(string: "https://somexai.com/privacy/brace-hours/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Copy
    static let entryNoun = "Session"
    static let entryNounPlural = "Sessions"
    static let exportFileStem = "brace-hours"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "timer", title: "One tap when the brace goes on",
                       body: "Tap when it goes on, tap when it comes off. The hours add up on their own, even overnight."),
        OnboardingPage(symbol: "chart.bar.fill", title: "See the daily goal, every day",
                       body: "Your orthopedist's target (usually 16 to 23 hours) sits on a ring. Streaks and a two-week chart keep it honest."),
        OnboardingPage(symbol: "doc.text.fill", title: "A wear-time report for the clinic",
                       body: "Hours per day, goal days, skin notes and photos in one PDF for the next appointment. Everything stays on the phone."),
    ]

    static let paywallSymbol = "checkmark.seal.fill"
    static let paywallHeadline = "Unlock \(appName)"
    static let paywallBenefits = [
        "Unlimited wear-time history",
        "Lock Screen timer while the brace is on",
        "Reminder when the brace has been off too long",
        "Skin checks with photos",
        "PDF report for the orthopedist, widget and Siri",
    ]

    static let disclaimer = "\(appName) records the wear time and goal you enter. It does not set or change your bracing prescription. Follow your orthopedist's and orthotist's instructions, and call them about pain, numbness or skin breakdown."

    // MARK: How-to guide
    static let howToIntro = "From install to your first report in four short steps."
    static let howTo: [HowToStep] = [
        HowToStep(symbol: "person.crop.circle", title: "Set up the brace plan",
                  body: "On Today, tap Set Up. Enter the wearer's name, the brace, and the daily goal your orthopedist gave you (for example 18 hours). Add the next appointment if you know it."),
        HowToStep(symbol: "timer", title: "Tap when the brace goes on and off",
                  body: "The big button on Today starts and stops the timer. Leave it running overnight; the hours split across days automatically. The Lock Screen shows the running time.",
                  tip: "Say \"Brace on in Brace Hours\" or \"Brace off in Brace Hours\" to Siri."),
        HowToStep(symbol: "clock.arrow.circlepath", title: "Forgot to tap? Add the time",
                  body: "Tap Add missed time on Today, or open a day in History, and enter the start and end. Edit or delete any session by tapping it."),
        HowToStep(symbol: "bandage", title: "Note skin problems",
                  body: "Tap Skin check, pick the areas (hips, ribs, underarms…), rate it, add a photo. It goes on the report."),
        HowToStep(symbol: "doc.text", title: "Bring the report to the appointment",
                  body: "Report tab → PDF report. It has hours per day, goal days, streaks and skin notes for the period you choose."),
        HowToStep(symbol: "bell", title: "Turn on the off-too-long reminder",
                  body: "Settings → Reminders. When the brace has been off longer than your limit during the day, the phone nudges you."),
    ]

    /// Display prices used only by DEBUG screenshot runs (`-mockPrices`). Keep in sync with StoreKit/Products.storekit.
    static let mockPrices = (annual: "$9.99", lifetime: "$24.99")

    // MARK: Behaviour
    static let reviewAfterSuccesses = 3
    static let defaultGoalHours = 18.0
    static let defaultOffReminderHours = 2.0
}

struct HowToStep: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
    var tip: String? = nil
}

struct OnboardingPage: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
}
