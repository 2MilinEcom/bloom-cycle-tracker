import SwiftUI
import SwiftData
import UIKit

@main struct BloomApp: App {
    private let container: ModelContainer?
    private let storageError: String?
    init() {
        do {
            let directory = URL.applicationSupportDirectory.appending(path: "Bloom", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                     attributes: [.protectionKey: FileProtectionType.complete])
            var resource = directory
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try resource.setResourceValues(values)
            let configuration = ModelConfiguration(url: directory.appending(path: "Bloom.store"), cloudKitDatabase: .none)
            container = try ModelContainer(for: DayLog.self, Preferences.self, configurations: configuration)
            storageError = nil
        } catch { container = nil; storageError = error.localizedDescription }
    }
    var body: some Scene {
        WindowGroup {
            if let container { RootView().modelContainer(container).tint(BloomStyle.berry).preferredColorScheme(.light) }
            else { ContentUnavailableView("Your journal could not open", systemImage: "lock.shield", description: Text("Your data has not been reset. Restart Bloom or check available storage. \(storageError ?? "")")) }
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @Query private var preferences: [Preferences]
    @State private var gate = PrivacyGate()
    @State private var error: String?
    var body: some View {
        ZStack {
            BloomStyle.paper.ignoresSafeArea()
            if let prefs = preferences.first {
                if !prefs.onboarded { OnboardingView(prefs: prefs) }
                else if prefs.lockEnabled && !gate.unlocked {
                    VStack(spacing: 24) {
                        Image(systemName: "lock.shield").font(.system(size: 50)).foregroundStyle(BloomStyle.berry)
                        Text("Your space, protected.").font(.largeTitle.bold())
                        Text("Unlock with Face ID, Touch ID, or your device passcode.").multilineTextAlignment(.center)
                        Button("Unlock Bloom") { Task { await gate.unlock() } }.buttonStyle(BloomButton()).disabled(gate.authenticating)
                        if let message = gate.error { Text(message).font(.footnote).foregroundStyle(.secondary) }
                    }.padding(32)
                } else { OwnerTabs(prefs: prefs) }
            } else { ProgressView().task { let p = Preferences(); context.insert(p); do { try context.save() } catch { self.error = error.localizedDescription } } }
            if phase != .active {
                BloomStyle.paper.ignoresSafeArea()
                Label("Bloom • Private", systemImage: "lock.fill").font(.title2.bold()).foregroundStyle(BloomStyle.berry)
            }
        }
        .onChange(of: phase) { _, value in if value != .active { gate.unlocked = false } }
        .privacySensitive()
        .alert("Storage issue", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
