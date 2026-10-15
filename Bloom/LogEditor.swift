import SwiftUI
import SwiftData

struct LogEditor: View {
    static let flowNames = ["None", "Spotting", "Light", "Medium", "Heavy"]
    static let symptomNames = ["Cramps", "Bloating", "Headache", "Tender breasts", "Fatigue", "Acne", "Backache", "Nausea", "Sleep changes"]
    static let moods = ["", "Calm", "Happy", "Sensitive", "Anxious", "Low", "Irritable", "Energized"]
    let date: Date
    let logs: [DayLog]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var flow = 0
    @State private var starts = false
    @State private var symptoms: Set<String> = []
    @State private var mood = ""
    @State private var journal = ""
    @State private var shareJournal = false
    @State private var error: String?
    @State private var confirmDelete = false
    private var existing: DayLog? { logs.first { Calendar.current.isDate($0.date, inSameDayAs: date) } }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(date.formatted(date: .complete, time: .omitted)).font(.headline)
                    Picker("Flow", selection: $flow) { ForEach(0..<Self.flowNames.count, id: \.self) { Text(Self.flowNames[$0]).tag($0) } }.accessibilityIdentifier("log.flow")
                    Toggle("First day of a new period", isOn: $starts).disabled(flow == 0)
                    Text("Mark only the first day of each period. Spotting alone may not be a new period; choose based on your experience.").font(.caption).foregroundStyle(.secondary)
                } header: { Text("Period & flow") }
                Section("Body") {
                    ForEach(Self.symptomNames, id: \.self) { symptom in
                        Toggle(symptom, isOn: Binding(get: { symptoms.contains(symptom) }, set: { if $0 { symptoms.insert(symptom) } else { symptoms.remove(symptom) } }))
                    }
                }
                Section("Mind") { Picker("Mood", selection: $mood) { ForEach(Self.moods, id: \.self) { Text($0.isEmpty ? "Not recorded" : $0).tag($0) } } }
                Section {
                    TextEditor(text: $journal).frame(minHeight: 150).accessibilityLabel("Journal entry").accessibilityIdentifier("log.journal")
                    Toggle("Allow this entry in partner preview", isOn: $shareJournal)
                    Text("This entry appears only when Partner Mode AND journal sharing are enabled. No data is sent to another device.").font(.caption).foregroundStyle(.secondary)
                } header: { Text("Your journal") }
                if existing != nil { Section { Button("Delete this day’s entry", role: .destructive) { confirmDelete = true } } }
            }.scrollContentBackground(.hidden).background(BloomStyle.paper)
             .navigationTitle("Daily check-in").navigationBarTitleDisplayMode(.inline)
             .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().accessibilityIdentifier("log.save") }
             }
        }.onAppear { if let log = existing { flow = log.flow; starts = log.startsPeriod; symptoms = Set(log.symptoms); mood = log.mood; journal = log.journal; shareJournal = log.shareJournal } }
         .onChange(of: flow) { _, value in if value == 0 { starts = false } }
         .confirmationDialog("Delete this day’s entry?", isPresented: $confirmDelete, titleVisibility: .visible) { Button("Delete entry", role: .destructive) { if let existing { context.delete(existing); persist() } } }
         .alert("Couldn’t save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") {} } message: { Text(error ?? "") }
    }
    private func save() {
        let log = existing ?? DayLog(date: date)
        if existing == nil { context.insert(log) }
        log.flow = flow; log.startsPeriod = starts && flow > 0; log.symptoms = symptoms.sorted()
        log.mood = mood; log.journal = journal; log.shareJournal = shareJournal
        persist()
    }
    private func persist() { do { try context.save(); dismiss() } catch { context.rollback(); self.error = error.localizedDescription } }
}
