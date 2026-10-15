import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var prefs: Preferences
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var length = 28
    @State private var knowsStart = false
    @State private var start = Date()
    @State private var consent = false
    @State private var lock = true
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Page(eyebrow: "Bloom / A little closer to yourself", title: "Your rhythm.\nYour own space.") {
                Image(systemName: "leaf.circle").font(.system(size: 78, weight: .ultraLight)).foregroundStyle(BloomStyle.berry).frame(maxWidth: .infinity).padding(.vertical, 12)
                BloomCard {
                    Text("A quiet place to notice your patterns.").font(.title2).fontDesign(.serif)
                    Text("Your entries stay on this iPhone. No account, ads, analytics, or cloud sync. Partner preview starts off; you decide what it can show.").foregroundStyle(.secondary)
                }
                BloomCard {
                    TextField("What should we call you? (optional)", text: $name).textContentType(.givenName).accessibilityIdentifier("onboarding.name")
                    Stepper("Usual cycle: \(length) days", value: $length, in: 15...60)
                    Text("Used only until your history is available. You can change this later.").font(.caption).foregroundStyle(.secondary)
                    Toggle("I know my last period start", isOn: $knowsStart)
                    if knowsStart { DatePicker("First day", selection: $start, in: ...Date(), displayedComponents: .date) }
                }
                SafetyNote()
                Toggle("I understand these are estimates", isOn: $consent)
                Toggle("Lock when leaving Bloom", isOn: $lock).accessibilityIdentifier("onboarding.lock")
                Text("Bloom locks when you leave the app when this option is on. A device passcode is required to unlock it. You can adjust this in Privacy after setup.").font(.footnote).foregroundStyle(.secondary)
                Button("Begin my journal") { complete() }.buttonStyle(BloomButton()).disabled(!consent).accessibilityIdentifier("onboarding.begin")
            }.navigationBarHidden(true)
        }.alert("Couldn’t save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") {} } message: { Text(error ?? "") }
    }
    private func complete() {
        prefs.lockEnabled = lock
        prefs.name = String(name.prefix(80)); prefs.cycleLength = length; prefs.onboarded = true
        if knowsStart { context.insert(DayLog(date: start, flow: 1, startsPeriod: true)) }
        do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
    }
}
