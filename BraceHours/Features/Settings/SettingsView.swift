import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @AppStorage(OffReminder.enabledKey) private var offReminderEnabled = true
    @AppStorage(OffReminder.hoursKey) private var offReminderHours = AppConfig.defaultOffReminderHours
    @State private var confirmingDeleteAll = false
    @State private var editingProfile = false
    #if DEBUG
    @State private var sampleDataImported = false
    @AppStorage(DebugFlags.unlockKey) private var debugUnlock = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = true
    #endif

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Brace plan") {
                    if let profile = profiles.first {
                        Button { editingProfile = true } label: {
                            VStack(alignment: .leading) {
                                Text(profile.title.isEmpty ? "Brace plan" : profile.title).foregroundStyle(.primary)
                                Text("Goal \(Formatters.hours(profile.goalHours)) a day").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No plan yet. Set it up on Today.").foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("Remind me when the brace is off too long", isOn: $offReminderEnabled)
                    if offReminderEnabled {
                        Picker("Off for more than", selection: $offReminderHours) {
                            ForEach([0.5, 1.0, 1.5, 2.0, 3.0, 4.0], id: \.self) { Text(Formatters.hours($0)).tag($0) }
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Sent only between 7 am and 10 pm. Cancelled the moment the brace goes back on.")
                }

                Section("Help") {
                    NavigationLink { HowToView() } label: { Label("How do I use \(AppConfig.appName)?", systemImage: "questionmark.circle") }
                }

                Section("Your plan") {
                    LabeledContent("Status", value: planDescription)
                    if store.isEntitled && !store.isLifetime {
                        Button("Manage Subscription") { openURL(URL(string: "https://apps.apple.com/account/subscriptions")!) }
                    }
                    Button("Restore Purchases") { Task { await store.restore() } }
                    if let error = store.lastError { Text(error).font(.footnote).foregroundStyle(.red) }
                }

                Section("Your data") {
                    Text("Everything you record stays on this device\(AppConfig.iCloudSyncEnabled ? " and in your private iCloud" : ""). Nothing is sent to us.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Delete All Data", role: .destructive) { confirmingDeleteAll = true }
                }

                Section("About") {
                    Text(AppConfig.disclaimer).font(.footnote).foregroundStyle(.secondary)
                    if !AppConfig.appStoreID.isEmpty {
                        Button("Rate \(AppConfig.appName)") { openURL(URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)?action=write-review")!) }
                    }
                    Button("Contact Support") {
                        let subject = "\(AppConfig.appName) \(version)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL(URL(string: "mailto:\(AppConfig.supportEmail)?subject=\(subject)")!)
                    }
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    LabeledContent("Version", value: version)
                }

                #if DEBUG
                Section("Debug (not in release builds)") {
                    Toggle("Unlock without purchase", isOn: $debugUnlock)
                        .onChange(of: debugUnlock) { Task { await store.refreshEntitlements() } }
                    Button("Show onboarding again") { onboardingCompleted = false; dismiss() }
                    Button(sampleDataImported ? "Imported ✓" : "Insert sample data (6 weeks)") {
                        SampleData.insert(into: context)
                        sampleDataImported = true
                        Task { try? await Task.sleep(for: .seconds(2)); sampleDataImported = false }
                    }
                    .disabled(sampleDataImported)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $editingProfile) { ProfileEditorView(profile: profiles.first) }
            .confirmationDialog("Delete the brace plan, every session and every skin check on this device?", isPresented: $confirmingDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    try? context.delete(model: WearSession.self)
                    try? context.delete(model: SkinCheck.self)
                    try? context.delete(model: Profile.self)
                    try? context.save()
                    OffReminder.cancel()
                    LiveActivityManager.end()
                    WidgetSync.update(profile: nil, sessions: [])
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone. Export a report first if you want a copy.") }
        }
    }

    private var planDescription: String {
        guard store.isEntitled else { return "Not active" }
        if store.isLifetime { return "Lifetime" }
        if let expiry = store.expiresAt { return "Annual, renews \(expiry.formatted(date: .abbreviated, time: .omitted))" }
        return "Active"
    }
}
