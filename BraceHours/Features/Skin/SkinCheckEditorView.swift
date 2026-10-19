import SwiftUI
import SwiftData
import PhotosUI

struct SkinCheckEditorView: View {
    let check: SkinCheck?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var areas: Set<SkinArea> = []
    @State private var severity: SkinSeverity = .mild
    @State private var notes = ""
    @State private var photo: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("When", selection: $date) }
                Section("Where") {
                    ChipPicker(options: SkinArea.allCases, label: { $0.rawValue }, selection: $areas)
                }
                Section("How bad") {
                    Picker("Severity", selection: $severity) {
                        ForEach(SkinSeverity.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.inline).labelsHidden()
                }
                Section("Photo") {
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220).clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("Remove photo", role: .destructive) { self.photo = nil }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(photo == nil ? "Add photo" : "Replace photo", systemImage: "photo")
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 70)
                }
                Section {
                    Text("Broken skin, blisters, numbness or pain that does not ease when the brace is off are reasons to call the orthotist. This app only records what you saw.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if check != nil {
                    Section { Button("Delete skin check", role: .destructive) { confirmingDelete = true } }
                }
            }
            .navigationTitle(check == nil ? "Skin Check" : "Edit Skin Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .onAppear {
                guard let check else { return }
                date = check.date
                areas = Set(check.areas)
                severity = check.severityValue
                notes = check.notes
                photo = check.photo
            }
            .onChange(of: pickerItem) {
                guard let pickerItem else { return }
                Task { if let data = try? await pickerItem.loadTransferable(type: Data.self) { photo = ImageCompressor.compress(data) } }
            }
            .confirmationDialog("Delete this skin check?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let check { context.delete(check) }; dismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = check ?? SkinCheck(date: date)
        target.date = date
        target.areas = Array(areas)
        target.severityValue = severity
        target.notes = notes
        target.photo = photo
        if check == nil { context.insert(target) }
        dismiss()
    }
}

enum ImageCompressor {
    static func compress(_ data: Data, maxDimension: CGFloat = 1200) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
