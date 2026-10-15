import Foundation

struct CycleEstimate {
    let next: Date
    let earliest: Date
    let latest: Date
    let typicalLength: Int
    let lengths: [Int]
    let excluded: Int
    let overdue: Bool
    var ovulation: Date { Calendar.current.date(byAdding: .day, value: -14, to: next)! }
    var fertileStart: Date { Calendar.current.date(byAdding: .day, value: -5, to: ovulation)! }
    var fertileEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: ovulation)! }
}

enum PredictionEngine {
    static let disclaimer = "Never use Bloom to prevent pregnancy. Calendar estimates cannot confirm ovulation or identify safe days. Predictions may be inaccurate with irregular cycles, hormonal contraception, pregnancy, postpartum changes, or perimenopause. Bloom is not a medical device or a diagnosis."
    static func day(_ date: Date) -> Date { Calendar.current.startOfDay(for: date) }
    static func add(_ days: Int, to date: Date) -> Date { Calendar.current.date(byAdding: .day, value: days, to: date)! }
    static func distance(_ a: Date, _ b: Date) -> Int { Calendar.current.dateComponents([.day], from: day(a), to: day(b)).day! }
    static func estimate(starts: [Date], fallback: Int = 28, now: Date = Date()) -> CycleEstimate? {
        let sorted = Array(Set(starts.map(day).filter { $0 <= day(now) })).sorted()
        guard let last = sorted.last else { return nil }
        let all = zip(sorted, sorted.dropFirst()).map { distance($0, $1) }
        // These are computational bounds, not clinical definitions of a normal cycle.
        let usable = Array(all.filter { (15...90).contains($0) }.suffix(12))
        let ordered = usable.sorted()
        let median: Int
        if ordered.isEmpty { median = min(60, max(15, fallback)) }
        else if ordered.count % 2 == 0 { median = (ordered[ordered.count / 2 - 1] + ordered[ordered.count / 2]) / 2 }
        else { median = ordered[ordered.count / 2] }
        let spread = usable.map { abs($0 - median) }.max() ?? 0
        // Heuristic range, deliberately broad for sparse history. Not a calibrated confidence interval.
        let radius = max(usable.count < 3 ? 7 : 3, spread + 2)
        let next = add(median, to: last)
        let early = add(max(1, median - radius), to: last)
        let late = add(median + radius, to: last)
        return CycleEstimate(next: next, earliest: early, latest: late, typicalLength: median,
                             lengths: usable, excluded: all.filter { !(15...90).contains($0) }.count, overdue: day(now) > late)
    }
}
