import Foundation
import SwiftData

/// One SwiftData container shared by the app and its App Intents (Siri "brace on / off" runs in-process).
enum AppContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Profile.self, WearSession.self, SkinCheck.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: AppConfig.iCloudSyncEnabled ? .automatic : .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }()
}
