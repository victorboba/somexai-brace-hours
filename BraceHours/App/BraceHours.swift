import SwiftUI
import SwiftData

@main
struct BraceHours: App {
    @State private var entitlements = EntitlementStore()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            let context = AppContainer.shared.mainContext
            try? context.delete(model: WearSession.self)
            try? context.delete(model: SkinCheck.self)
            try? context.delete(model: Profile.self)
            try? context.save()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
        }
        .modelContainer(AppContainer.shared)
    }
}
