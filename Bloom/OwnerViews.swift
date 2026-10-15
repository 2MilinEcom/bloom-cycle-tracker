import SwiftUI
import SwiftData
import Charts

struct OwnerTabs: View {
    @Bindable var prefs: Preferences
    var body: some View {
        TabView {
            NavigationStack { TodayView(prefs: prefs) }.tabItem { Label("Today", systemImage: "sun.max") }
            NavigationStack { CycleCalendarView(prefs: prefs) }.tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationStack { TrendsView(prefs: prefs) }.tabItem { Label("Patterns", systemImage: "chart.xyaxis.line") }
            NavigationStack { JournalView() }.tabItem { Label("Journal", systemImage: "book.closed") }
            NavigationStack { PrivacyView(prefs: prefs) }.tabItem { Label("Privacy", systemImage: "lock.shield") }
        }
    }
}
struct TodayView: View {
    let prefs: Preferences
    @Query(sort: \DayLog.date) private var logs: [DayLog]
    @State private var showLog = false
    var estimate: CycleEstimate? { PredictionEngine.estimate(starts: logs.filter(\.startsPeriod).map(\.date), fallback: prefs.cycleLength) }
    var body: some View {
        Page(eyebrow: Date().formatted(.dateTime.weekday(.wide).month().day()), title: prefs.name.isEmpty ? "Welcome to your day." : "Hello, \(prefs.name).") {
            BloomCard {
                HStack { Label("YOUR RHYTHM", systemImage: "sparkle").font(.caption.weight(.semibold)); Spacer(); Image(systemName: "leaf") }
                if let e = estimate {
                    Text(e.overdue ? "Your forecast has passed" : "A little room to prepare").font(.title2).fontDesign(.serif)
                    Text(dateRange(e.earliest, e.latest)).font(.system(.largeTitle, design: .serif)).foregroundStyle(BloomStyle.berry)
                    Text(e.overdue ? "Log a new period if it started. Bloom won’t assume an unlogged cycle occurred." : "Estimated next period • center \(shortDate(e.next))").font(.subheadline)
                    if let last = logs.last(where: \.startsPeriod) { Text("Day \(PredictionEngine.distance(last.date, Date()) + 1) since your last logged start").foregroundStyle(.secondary) }
                    Text("Heuristic uncertainty range, not a statistical confidence interval. \(e.lengths.count) completed cycles used.").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Every pattern begins\nwith a first entry.").font(.system(.title, design: .serif))
                    Text("Log the first day of a period to begin forecasting. No sample health data has been added.").foregroundStyle(.secondary)
                }
                Button("Check in / log a period") { showLog = true }.buttonStyle(BloomButton()).accessibilityIdentifier("today.log")
            }
            if let today = logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
                BloomCard {
                    Label("Today, in your words", systemImage: "heart")
                    Text(today.mood.isEmpty ? "No mood recorded" : today.mood).font(.title3.bold())
                    Text(today.symptoms.isEmpty ? "No symptoms recorded" : today.symptoms.joined(separator: " • "))
                    Text("Flow: \(LogEditor.flowNames[min(4, max(0, today.flow))])").foregroundStyle(.secondary)
                }
            }
            BloomCard {
                Label("Space for how you actually feel", systemImage: "cup.and.saucer")
                Text("A prediction is a pattern, not a prescription. Let your own experience guide today’s pace.").font(.system(.title3, design: .serif))
            }
            if prefs.fertilityEstimates, let e = estimate, e.lengths.count >= 3, !e.overdue {
                BloomCard {
                    Text("Rough fertility estimate").font(.headline)
                    Text("Ovulation: around \(shortDate(e.ovulation))\nPossible fertile window: \(dateRange(e.fertileStart, e.fertileEnd))")
                    Text("Based on a fixed 14-day assumption before the predicted period. Actual ovulation may be earlier, later, or absent. This window does not identify safe days.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            SafetyNote()
        }.sheet(isPresented: $showLog) { LogEditor(date: Date(), logs: logs) }
    }
}

struct CycleCalendarView: View {
    let prefs: Preferences
    @Query(sort: \DayLog.date) private var logs: [DayLog]
    @State private var month = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var selected: Date?
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var estimate: CycleEstimate? { PredictionEngine.estimate(starts: logs.filter(\.startsPeriod).map(\.date), fallback: prefs.cycleLength) }
    var body: some View {
        Page(eyebrow: "Your cycle", title: "A wider view.") {
            BloomCard {
                HStack {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left").padding(8) }.accessibilityLabel("Previous month")
                    Spacer(); Text(month.formatted(.dateTime.month(.wide).year())).font(.headline); Spacer()
                    Button { shift(1) } label: { Image(systemName: "chevron.right").padding(8) }.accessibilityLabel("Next month")
                }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in Text(symbol).font(.caption).foregroundStyle(.secondary) }
                    ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 40) }
                    ForEach(days, id: \.self) { date in
                        let flow = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.flow ?? 0
                        Button { selected = date } label: {
                            Text(date.formatted(.dateTime.day())).font(.body.weight(Calendar.current.isDateInToday(date) ? .bold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(flow > 0 ? BloomStyle.berry : predicted(date) ? BloomStyle.berry.opacity(0.12) : Color.clear, in: Circle())
                                .foregroundStyle(flow > 0 ? .white : BloomStyle.ink)
                                .overlay { if Calendar.current.isDateInToday(date) { Circle().stroke(BloomStyle.berry, lineWidth: 1) } }
                        }.disabled(date > PredictionEngine.day(Date()))
                         .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(flow > 0 ? "logged bleeding" : predicted(date) ? "possible period start" : "no bleeding logged")")
                    }
                }
                Label("Solid: logged bleeding", systemImage: "circle.fill").foregroundStyle(BloomStyle.berry).font(.caption)
                Label("Pale: possible next start dates", systemImage: "circle").font(.caption)
                Text("Tap today or a past date to add, edit, or remove a daily entry. Pale dates show start uncertainty, not predicted bleeding duration.").font(.footnote).foregroundStyle(.secondary)
            }
            SafetyNote()
        }.sheet(item: Binding(get: { selected.map { SelectedDay(date: $0) } }, set: { selected = $0?.date })) { day in LogEditor(date: day.date, logs: logs) }
    }
    private var weekdaySymbols: [String] {
        let c = Calendar.current; let s = c.veryShortStandaloneWeekdaySymbols; let i = c.firstWeekday - 1
        return Array(s[i...] + s[..<i])
    }
    private var offset: Int { (Calendar.current.component(.weekday, from: month) - Calendar.current.firstWeekday + 7) % 7 }
    private var days: [Date] { (0..<(Calendar.current.range(of: .day, in: .month, for: month)?.count ?? 0)).map { PredictionEngine.add($0, to: month) } }
    private func shift(_ n: Int) { month = Calendar.current.date(byAdding: .month, value: n, to: month)! }
    private func predicted(_ date: Date) -> Bool { guard let e = estimate else { return false }; return date >= e.earliest && date <= e.latest }
}
struct SelectedDay: Identifiable { let date: Date; var id: Date { date } }

struct TrendsView: View {
    let prefs: Preferences
    @Query(sort: \DayLog.date) private var logs: [DayLog]
    var estimate: CycleEstimate? { PredictionEngine.estimate(starts: logs.filter(\.startsPeriod).map(\.date), fallback: prefs.cycleLength) }
    var body: some View {
        Page(eyebrow: "Patterns / Not prescriptions", title: "Know your rhythm.") {
            if let e = estimate, !e.lengths.isEmpty {
                BloomCard {
                    Text("\(e.typicalLength) days").font(.system(.largeTitle, design: .serif)).foregroundStyle(BloomStyle.berry)
                    Text("Median cycle • latest \(e.lengths.count) usable intervals").foregroundStyle(.secondary)
                    Chart(Array(e.lengths.enumerated()), id: \.offset) { item in
                        LineMark(x: .value("Cycle", item.offset + 1), y: .value("Days", item.element)).foregroundStyle(BloomStyle.berry)
                        PointMark(x: .value("Cycle", item.offset + 1), y: .value("Days", item.element)).foregroundStyle(BloomStyle.berry)
                    }.chartXAxisLabel("Completed cycle").chartYAxisLabel("Days").frame(height: 200)
                    Text("Range: \(e.lengths.min()!)–\(e.lengths.max()!) days. \(e.excluded) intervals excluded by the 15–90 day calculation bounds. These bounds do not define what is medically normal.").font(.footnote)
                }
            } else { BloomCard { Text("Your history will tell a story.").font(.title2).fontDesign(.serif); Text("Log at least two period starts to see a completed cycle. Daily bleeding does not automatically mark a new cycle.") } }
            BloomCard {
                Text("Symptoms you’ve noticed").font(.headline)
                let counts = symptomCounts
                if counts.isEmpty { Text("No symptoms logged yet.").foregroundStyle(.secondary) }
                ForEach(counts, id: \.name) { row in
                    HStack { Text(row.name); Spacer(); Text("\(row.count) days").foregroundStyle(BloomStyle.berry) }
                }
            }
            BloomCard {
                Text("How forecasts work").font(.headline)
                Text("Bloom uses the median of your latest 12 completed cycles between 15 and 90 days. With fewer than three cycles, it uses a minimum ±7-day range. With more history, the minimum is ±3 days; observed variation widens it. If no completed cycle exists, your chosen cycle length is used. Missed periods are never invented.")
                Text("These are unvalidated planning estimates. They do not diagnose irregularity or predict hormonal changes.").font(.footnote).foregroundStyle(.secondary)
            }
            SafetyNote()
        }
    }
    private var symptomCounts: [(name: String, count: Int)] {
        let counts = logs.flatMap(\.symptoms).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.map { (name: $0.key, count: $0.value) }.sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }
}

struct JournalView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var selected: SelectedDay?
    @State private var search = ""
    var body: some View {
        Page(eyebrow: "Only your words", title: "A place to land.") {
            Button("Write today") { selected = SelectedDay(date: Date()) }.buttonStyle(BloomButton())
            let entries = logs.filter { !$0.journal.isEmpty && (search.isEmpty || $0.journal.localizedCaseInsensitiveContains(search)) }
            if entries.isEmpty { BloomCard { Text("Room for the things a chart can’t hold.").font(.title2).fontDesign(.serif); Text("Your journal is private. Even in partner preview, each entry needs its own sharing permission.") } }
            ForEach(entries) { log in
                Button { selected = SelectedDay(date: log.date) } label: {
                    BloomCard {
                        HStack { Text(log.date.formatted(date: .abbreviated, time: .omitted)).font(.caption.bold()); Spacer(); Image(systemName: log.shareJournal ? "person.crop.circle.badge.checkmark" : "lock") }
                        Text(log.journal).lineLimit(5).frame(maxWidth: .infinity, alignment: .leading)
                    }.foregroundStyle(BloomStyle.ink)
                }.buttonStyle(.plain)
            }
        }.searchable(text: $search, prompt: "Search your journal")
         .sheet(item: $selected) { LogEditor(date: $0.date, logs: logs) }
    }
}
