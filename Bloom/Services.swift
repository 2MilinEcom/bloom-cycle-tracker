import SwiftUI
import UserNotifications
import LocalAuthentication
import UniformTypeIdentifiers

struct HealthExport: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

enum Reminders {
    static let identifier = "bloom.checkin"
    static func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    static func enable() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { cancel(); return false }
        let content = UNMutableNotificationContent()
        content.title = "A moment for you"; content.body = "Your daily check-in is ready."; content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 20), repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        return true
    }
}

@MainActor @Observable final class PrivacyGate {
    var unlocked = false
    var authenticating = false
    var error: String?
    func unlock() async {
        guard !authenticating else { return }
        authenticating = true; defer { authenticating = false }
        let context = LAContext()
        do {
            unlocked = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Open your private Bloom journal")
            error = nil
        } catch { self.error = "Unlock was not completed. Try again, or set a device passcode in Settings." }
    }
}
