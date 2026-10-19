import SwiftUI
import SwiftData

struct ProfileEditorView: View {
    let profile: Profile?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var braceName = ""
    @State private var goalHours = AppConfig.defaultGoalHours
    @State private var startDate = Date.now
    @State private var clinicName = ""
    @State private var hasAppointment = false
    @State private var nextAppointment = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Wearer") {
                    TextField("Name", text: $name).textContentType(.givenName)
                }
                Section("Brace") {
                    TextField("Brace (Boston, Rigo-Cheneau, night brace…)", text: $braceName)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BraceKinds.common, id: \.self) { kind in
                                Button(kind) { braceName = kind }.buttonStyle(.bordered).controlSize(.small).tint(braceName == kind ? .accentColor : .secondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 0))
                    DatePicker("Bracing since", selection: $startDate, displayedComponents: .date)
                }
                Section {
                    Stepper("Daily goal: \(Formatters.hours(goalHours))", value: $goalHours, in: 1...23, step: 0.5)
                    Text("Enter the hours per day your orthopedist prescribed. Full-time bracing is often 16 to 23 hours; night braces 8 to 10.")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: {
                    Text("Prescribed wear time")
                }
                Section("Clinic") {
                    TextField("Clinic or orthopedist", text: $clinicName)
                    Toggle("Next appointment scheduled", isOn: $hasAppointment)
                    if hasAppointment {
                        DatePicker("Next appointment", selection: $nextAppointment, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(profile == nil ? "Brace Plan" : "Edit Brace Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .onAppear {
                guard let profile else { return }
                name = profile.name
                braceName = profile.braceName
                goalHours = profile.goalHours
                startDate = profile.startDate
                clinicName = profile.clinicName
                hasAppointment = profile.nextAppointment != nil
                nextAppointment = profile.nextAppointment ?? nextAppointment
                notes = profile.notes
            }
        }
    }

    private func save() {
        let target = profile ?? Profile()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.braceName = braceName.trimmingCharacters(in: .whitespaces)
        target.goalHours = goalHours
        target.startDate = startDate
        target.clinicName = clinicName
        target.nextAppointment = hasAppointment ? nextAppointment : nil
        target.notes = notes
        if profile == nil { context.insert(target) }
        try? context.save()
        BraceActions.afterChange(in: context)
        dismiss()
    }
}
