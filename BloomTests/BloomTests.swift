import XCTest
import SwiftData
@testable import Bloom

final class BloomTests: XCTestCase {
    let origin = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    func starts(_ offsets: [Int]) -> [Date] { offsets.map { PredictionEngine.add($0, to: origin) } }
    func testEmptyHistoryDoesNotInventPeriod() { XCTAssertNil(PredictionEngine.estimate(starts: [])) }
    func testSparseHistoryUsesPreferenceAndBroadRange() {
        let e = PredictionEngine.estimate(starts: starts([0]), fallback: 31, now: origin)!
        XCTAssertEqual(e.typicalLength, 31)
        XCTAssertEqual(PredictionEngine.distance(e.earliest, e.latest), 14)
    }
    func testLearnsMedianAndHandlesDuplicatesAndFutureEntries() {
        let history = starts([0, 28, 58, 87, 87, 2000])
        let e = PredictionEngine.estimate(starts: history, now: PredictionEngine.add(90, to: origin))!
        XCTAssertEqual(e.lengths, [28, 30, 29]); XCTAssertEqual(e.typicalLength, 29)
        XCTAssertEqual(PredictionEngine.distance(origin, e.next), 116)
        XCTAssertEqual(PredictionEngine.distance(e.earliest, e.latest), 6)
    }
    func testOutliersAreReportedAndVariationWidensRange() {
        let e = PredictionEngine.estimate(starts: starts([0, 10, 38, 73, 102]), now: PredictionEngine.add(103, to: origin))!
        XCTAssertEqual(e.excluded, 1); XCTAssertEqual(e.typicalLength, 29)
        XCTAssertEqual(PredictionEngine.distance(e.earliest, e.latest), 16)
    }
    func testOverdueDoesNotRollForecastForward() {
        let e = PredictionEngine.estimate(starts: starts([0, 28]), now: PredictionEngine.add(150, to: origin))!
        XCTAssertTrue(e.overdue); XCTAssertEqual(PredictionEngine.distance(origin, e.next), 56)
    }
    func testOnlyLatestTwelveIntervalsUsed() {
        let e = PredictionEngine.estimate(starts: starts((0...20).map { $0 * 28 }), now: PredictionEngine.add(600, to: origin))!
        XCTAssertEqual(e.lengths.count, 12); XCTAssertEqual(e.excluded, 0)
    }
    @MainActor func testSwiftDataPersistsAllFieldsAndDeletion() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".store")
        defer { for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) } }
        let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
        do {
            let store = try ModelContainer(for: DayLog.self, Preferences.self, configurations: config)
            let ctx = ModelContext(store)
            ctx.insert(DayLog(date: origin, flow: 3, startsPeriod: true, symptoms: ["Cramps"], mood: "Calm", journal: "Private words", shareJournal: true))
            let p = Preferences(); p.partnerEnabled = true; p.shareJournal = true; p.shareFlow = true; p.shareMood = true; p.shareSymptoms = true; p.sharePrediction = true; ctx.insert(p)
            try ctx.save()
        }
        let reopened = try ModelContainer(for: DayLog.self, Preferences.self, configurations: config)
        let ctx = ModelContext(reopened)
        let logs = try ctx.fetch(FetchDescriptor<DayLog>())
        XCTAssertEqual(logs.count, 1); XCTAssertEqual(logs[0].journal, "Private words"); XCTAssertEqual(logs[0].symptoms, ["Cramps"])
        let p = try XCTUnwrap(ctx.fetch(FetchDescriptor<Preferences>()).first)
        p.revoke(); XCTAssertFalse(p.partnerEnabled); XCTAssertFalse(p.shareJournal); XCTAssertFalse(p.shareMood); XCTAssertFalse(p.shareFlow); XCTAssertFalse(p.shareSymptoms); XCTAssertFalse(p.sharePrediction)
        let data = try JSONEncoder().encode(ExportDay(logs[0]))
        let decoded = try JSONDecoder().decode(ExportDay.self, from: data)
        XCTAssertEqual(decoded.date, "2025-01-01"); XCTAssertEqual(decoded.flow, 3)
        ctx.delete(logs[0]); try ctx.save()
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<DayLog>()).isEmpty)
    }
}
