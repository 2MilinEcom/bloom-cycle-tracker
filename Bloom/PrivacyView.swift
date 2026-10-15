import SwiftUI
import SwiftData

struct PrivacyView: View {
    @Bindable var prefs: Preferences
    @Query(sort: \DayLog.date) private var logs: [DayLog]
    @Environment(\.modelContext) private var context
    @State private var exportDocument: HealthExport?
    @State private var exporting = false
    @State private var deleting = false
    @State private var message: String?
    @State private var scheduling = false
    @State private var showPartner = false
    @State private var authenticating = false
    var body: some View {
        Form {
            Section {
                Label("Your body. Your data.", systemImage: "lock.shield.fill").font(.title2).fontDesign(.serif).foregroundStyle(BloomStyle.berry)
                Text("Stored in this app’s local SwiftData database. No account, network service, advertising, or analytics. The store directory uses iOS complete file protection and is excluded from device backups. Uninstalling may lose your data; export if you need a copy.").font(.footnote)
                Text("App lock and the app-switcher cover limit casual access. They cannot prevent screenshots, someone using an unlocked device, or access on a compromised device.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Your experience") {
                TextField("Name", text: $prefs.name)
                Stepper("Starting cycle length: \(prefs.cycleLength) days", value: $prefs.cycleLength, in: 15...60)
                Toggle("Show rough fertility estimates", isOn: $prefs.fertilityEstimates)
                Text("Requires at least three usable completed cycles. Ovulation uses a fixed 14-day assumption. Do not use these estimates for contraception.").font(.caption)
                Toggle("Lock when leaving Bloom", isOn: Binding(get: { prefs.lockEnabled }, set: { value in
                    if value { prefs.lockEnabled = true }
                    else { Task { await disableLock() } }
                })).disabled(authenticating)
            }
            Section {
                Toggle("Daily check-in at 8 PM", isOn: Binding(get: { prefs.reminders }, set: { value in Task { await reminders(value) } })).disabled(scheduling)
                Text("Notifications use neutral wording and include no cycle or journal information. You control lock-screen previews in iOS Settings.").font(.caption)
            } header: { Text("Optional reminders") }
            Section {
                Toggle("Enable local Partner Mode preview", isOn: Binding(get: { prefs.partnerEnabled }, set: { value in
                    if value { prefs.partnerEnabled = true } else { revoke() }
                }))
                Text("Owner controls only. This is a preview on this iPhone, not a separate partner account. There is no remote connection, invitation, or synchronization.").font(.footnote)
                if prefs.partnerEnabled {
                    Toggle("Period prediction", isOn: $prefs.sharePrediction)
                    Toggle("Today’s flow", isOn: $prefs.shareFlow)
                    Toggle("Today’s symptoms", isOn: $prefs.shareSymptoms)
                    Toggle("Today’s mood", isOn: $prefs.shareMood)
                    Toggle("Individually approved journal entries", isOn: $prefs.shareJournal)
                    Button("Open partner preview") { showPartner = true }
                    Button("Revoke all preview access", role: .destructive) { revoke() }
                }
                Text("Revoking clears every sharing permission and all entry approvals. It cannot erase information someone has already seen or copied.").font(.caption).foregroundStyle(.secondary)
            } header: { Text("Sharing is your choice") }
            Section("Data controls") {
                Button("Export all entries as JSON") { makeExport() }
                Text("An export contains sensitive, unencrypted health information. Choose a destination you trust. Copies you save are outside Bloom’s control. Import is not included in this version.").font(.caption)
                Button("Delete all Bloom data", role: .destructive) { deleting = true }
                Text("Deletes entries, preferences and sharing approvals, cancels Bloom reminders, and returns to onboarding. Previously exported files are not deleted. Logical deletion is not a forensic secure wipe.").font(.caption)
            }
            Section { SafetyNote() }.listRowBackground(Color.clear)
        }.scrollContentBackground(.hidden).background(BloomStyle.paper).navigationTitle("Privacy & care")
         .onDisappear { savePreferences() }
         .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "Bloom-private-export") { result in if case .failure(let error) = result { message = error.localizedDescription } }
         .fullScreenCover(isPresented: $showPartner) { PartnerPreview(prefs: prefs, logs: logs) }
         .confirmationDialog("Permanently delete all Bloom data on this device?", isPresented: $deleting, titleVisibility: .visible) { Button("Delete all data", role: .destructive) { deleteAll() } }
         .alert("Bloom", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK") {} } message: { Text(message ?? "") }
    }
    private func revoke() {
        prefs.revoke(); for log in logs { log.shareJournal = false }; savePreferences()
    }
    private func savePreferences() { do { try context.save() } catch { context.rollback(); message = "Changes could not be saved: \(error.localizedDescription)" } }
    private func reminders(_ enabled: Bool) async {
        scheduling = true; defer { scheduling = false }
        if !enabled { Reminders.cancel(); prefs.reminders = false; savePreferences(); return }
        do {
            prefs.reminders = try await Reminders.enable()
            if !prefs.reminders { message = "Notifications are disabled. You can allow Bloom notifications in iOS Settings." }
            savePreferences()
        } catch { Reminders.cancel(); prefs.reminders = false; message = error.localizedDescription }
    }
    private func disableLock() async {
        authenticating = true; defer { authenticating = false }
        let check = PrivacyGate(); await check.unlock()
        if check.unlocked { prefs.lockEnabled = false; savePreferences() }
        else { message = check.error }
    }
    private func makeExport() {
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(ExportArchive(schemaVersion: 1, created: Date(), note: "Private health data. Dates are local calendar days. Flow: 0 none, 1 spotting, 2 light, 3 medium, 4 heavy. Export is not encrypted. Preferences and device authentication are not included.", days: logs.map(ExportDay.init)))
            exportDocument = HealthExport(data: data); exporting = true
        } catch { message = error.localizedDescription }
    }
    private func deleteAll() {
        for log in logs { context.delete(log) }
        prefs.revoke(); prefs.onboarded = false; prefs.name = ""; prefs.cycleLength = 28
        prefs.fertilityEstimates = false; prefs.lockEnabled = true; prefs.reminders = false
        do { try context.save(); Reminders.cancel() } catch { context.rollback(); message = error.localizedDescription }
    }
}

struct PartnerPreview: View {
    let prefs: Preferences
    let logs: [DayLog]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Page(eyebrow: "Partner / Local preview", title: "Care starts with listening.") {
                BloomCard {
                    Label("On this iPhone only", systemImage: "iphone")
                    Text("Only the categories approved by the owner appear here. This screen is not a secure second account and cannot connect your own iPhone.").font(.footnote)
                }
                if prefs.partnerEnabled {
                    if prefs.sharePrediction, let e = PredictionEngine.estimate(starts: logs.filter(\.startsPeriod).map(\.date), fallback: prefs.cycleLength) {
                        BloomCard { Text("Shared period estimate").font(.headline); Text(dateRange(e.earliest, e.latest)); if e.overdue { Text("This estimated window has passed.") }; Text("An uncertain planning estimate, not a guarantee.").font(.caption) }
                    }
                    if let today = logs.first(where: { Calendar.current.isDateInToday($0.date) }), prefs.shareFlow || prefs.shareSymptoms || prefs.shareMood {
                        BloomCard {
                            Text("Shared today").font(.headline)
                            if prefs.shareFlow { Text("Flow: \(LogEditor.flowNames[min(4, max(0, today.flow))])") }
                            if prefs.shareSymptoms { Text(today.symptoms.isEmpty ? "No symptoms recorded" : today.symptoms.joined(separator: ", ")) }
                            if prefs.shareMood { Text(today.mood.isEmpty ? "No mood recorded" : today.mood) }
                        }
                    }
                    if prefs.shareJournal {
                        ForEach(logs.filter { $0.shareJournal && !$0.journal.isEmpty }) { log in
                            BloomCard { Text(log.date.formatted(date: .abbreviated, time: .omitted)).font(.caption); Text(log.journal) }
                        }
                    }
                    BloomCard { Text("A simple way to show up").font(.headline); Text("Ask what would feel supportive today. Listen without assuming how someone feels from their cycle dates.") }
                } else { Text("Preview access has been revoked.") }
                SafetyNote()
            }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("Return to owner") { dismiss() } } }
        }
    }
}
