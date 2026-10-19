# Brace Hours

A wear-time diary for scoliosis bracing. Tap when the brace goes on and off, see hours against the orthopedist's daily goal, and hand over a PDF at each appointment. For families of children in a brace.

One of a set of niche iPhone apps built from a shared SwiftUI template. It was never released on the App Store; the code is here for anyone to use. The template is [somexai-ios-template](https://github.com/victorboba/somexai-ios-template) and the collection is [somexai-ios-apps](https://github.com/victorboba/somexai-ios-apps).

## What it does

- **Brace plan**: wearer, brace type, daily goal (default 18 hours), bracing start date, clinic and next appointment.
- **Today**: a ring of hours against the goal, one large Brace on / Brace off button, the running timer, today's sessions (tap to edit), Add missed time, skin check, streak and appointment countdown.
- **Sessions cross midnight** and one can be running; daily totals are computed by overlap and capped at 24 hours (`WearMath`).
- **Live Activity** on the Lock Screen and Dynamic Island while the brace is on.
- **Siri / Shortcuts**: "Brace on in Brace Hours" and "Brace off in Brace Hours" run in the background and speak the day's total.
- **Off-too-long reminder**: one local notification when the brace has been off longer than the limit (default 2 hours), only between 7 am and 10 pm, cancelled when the brace goes back on.
- **Skin checks**: areas, severity, notes and a photo.
- **History**: a 14-day bar chart (Swift Charts) with the goal line, every day back to the start, and day detail with editable sessions.
- **Report**: 7, 30 or 90 days or since start; average, goal days, share of prescribed hours and longest streak; a PDF with the chart, skin notes and hours per day; two CSVs.
- A Home Screen widget and a How do I use guide.

## The boundary

The app records the wear time and goal the family enters. It never sets or changes a prescription, and the report says the numbers are user-entered, not a clinical measurement. `AppConfig.disclaimer` tells users to follow their orthopedist's and orthotist's instructions.

## Privacy

All data stays on the device in SwiftData. There is no account, no analytics and no network code, and `AppConfig.iCloudSyncEnabled` is `false`. The off-too-long reminder is a local notification scheduled on the device. CSV and PDF export happen only when you choose to share a file.

## Build and run

Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), and iOS 17+.

```bash
xcodegen generate
open BraceHours.xcodeproj
```

Pick the `BraceHours` scheme and an iPhone simulator, then Run.

Tests:

```bash
xcodebuild -scheme BraceHours -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

Paywall: the app has a hard paywall (annual subscription or lifetime purchase). Running from Xcode uses the bundled `Products.storekit` file, so purchases are simulated and free. Debug builds can also skip it with the `-unlock` launch argument or the Debug switch in Settings. In Debug builds, Settings has a Debug section with sample data (six weeks), and the launch arguments `-sampleData`, `-resetData`, `-skipOnboarding` and `-mockPrices` are available.

To run on your own device or ship it: set your team in `project.yml` (`DEVELOPMENT_TEAM`), change the `com.example` bundle ID prefix in `project.yml`, both `.entitlements` files and `Products.storekit`, and update `supportEmail`, `privacyPolicyURL` and `appStoreID` in `Shared/AppConfig.swift`.

## Project layout

- `BraceHours/App/`: app entry point and the root view that gates onboarding, paywall and the app.
- `BraceHours/Core/`: StoreKit entitlement, CSV and PDF export, App Intents, review prompt, widget sync, debug flags and sample data.
- `BraceHours/Features/`: the screens, including onboarding, paywall, settings and the How do I use guide.
- `BraceHours/Models/`: the SwiftData models and the calculation code. The app also ships a Live Activity and its App Intents (`BraceIntents.swift`).
- `BraceHours/StoreKit/Products.storekit`: local StoreKit configuration.
- `BraceHoursWidget/`: the Home Screen widget, fed by a snapshot in the App Group.
- `BraceHoursTests/` and `BraceHoursUITests/`: unit and UI tests.
- `Shared/AppConfig.swift`: everything that changes per app (name, copy, onboarding, paywall benefits, How-to steps, disclaimer, product IDs, links).
- `scripts/`: icon and screenshot helpers. `docs/` has notes on capabilities such as iCloud and App Groups.

## Technical notes

- Live Activities need a device, or a simulator with them enabled in Settings.
- `WearMath` has no SwiftData dependency and is unit-tested directly.

## License

MIT. See [LICENSE](LICENSE).
