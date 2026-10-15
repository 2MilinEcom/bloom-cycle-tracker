import Foundation
import SwiftData

@Model final class DayLog {
    @Attribute(.unique) var date: Date
    var flow: Int
    var startsPeriod: Bool
    var symptoms: [String]
    var mood: String
    var journal: String
    var shareJournal: Bool
    init(date: Date, flow: Int = 0, startsPeriod: Bool = false, symptoms: [String] = [], mood: String = "", journal: String = "", shareJournal: Bool = false) {
        self.date = PredictionEngine.day(date); self.flow = flow; self.startsPeriod = startsPeriod
        self.symptoms = symptoms; self.mood = mood; self.journal = journal; self.shareJournal = shareJournal
    }
}

@Model final class Preferences {
    var onboarded = false
    var name = ""
    var cycleLength = 28
    var fertilityEstimates = false
    var lockEnabled = true
    var reminders = false
    var partnerEnabled = false
    var sharePrediction = false
    var shareFlow = false
    var shareSymptoms = false
    var shareMood = false
    var shareJournal = false
    init() {}
    func revoke() {
        partnerEnabled = false; sharePrediction = false; shareFlow = false
        shareSymptoms = false; shareMood = false; shareJournal = false
    }
}

struct ExportDay: Codable {
    let date: String
    let flow: Int
    let startsPeriod: Bool
    let symptoms: [String]
    let mood: String
    let journal: String
    let shareJournal: Bool
    init(_ log: DayLog) {
        let f = DateFormatter(); f.calendar = .current; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        date = f.string(from: log.date); flow = log.flow; startsPeriod = log.startsPeriod
        symptoms = log.symptoms; mood = log.mood; journal = log.journal; shareJournal = log.shareJournal
    }
}
struct ExportArchive: Codable {
    let schemaVersion: Int
    let created: Date
    let note: String
    let days: [ExportDay]
}
