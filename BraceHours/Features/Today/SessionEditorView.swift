import SwiftUI
import SwiftData

/// Add missed time or fix a session. End can be left open ("still on") only when no other session is running.
struct SessionEditorView: View {
    let session: WearSession?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WearSession.startedAt, order: .reverse) private var sessions: [WearSession]

    @State private var startedAt: Date = Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now
    @State private var hasEnd = true
    @State private var endedAt: Date = .now
    @State private var note = ""
    @State private var confirmingDelete = false

    private var otherActive: Bool { sessions.contains { $0.isActive && $0.id != session?.id } }
    private var valid: Bool { !hasEnd || endedAt > startedAt }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Brace on", selection: $startedAt)
                    Toggle("Brace came off", isOn: $hasEnd).disabled(otherActive && !hasEnd)
                    if hasEnd {
                        DatePicker("Brace off", selection: $endedAt, in: startedAt...)
                        LabeledContent("Duration", value: Formatters.duration(max(0, endedAt.timeIntervalSince(startedAt))))
                    } else {
                        Text("Leaving this open means the brace is on right now and the timer keeps running.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Note") {
                    TextField("Optional (PE class, shower, adjustment…)", text: $note)
                }
                if session != nil {
                    Section { Button("Delete session", role: .destructive) { confirmingDelete = true } }
                }
            }
            .navigationTitle(session == nil ? "Add Missed Time" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(!valid) }
            }
            .onAppear {
                if let session {
                    startedAt = session.startedAt
                    hasEnd = session.endedAt != nil
                    endedAt = session.endedAt ?? .now
                    note = session.note
                } else if otherActive {
                    hasEnd = true
                }
            }
            .confirmationDialog("Delete this session?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let session { context.delete(session) }
                    try? context.save()
                    BraceActions.afterChange(in: context)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = session ?? WearSession()
        target.startedAt = startedAt
        target.endedAt = hasEnd ? endedAt : nil
        target.note = note
        if session == nil { context.insert(target) }
        try? context.save()
        BraceActions.afterChange(in: context)
        dismiss()
    }
}
