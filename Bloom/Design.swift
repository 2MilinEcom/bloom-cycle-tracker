import SwiftUI

enum BloomStyle {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let berry = Color(red: 0.49, green: 0.19, blue: 0.31)
    static let ink = Color(red: 0.22, green: 0.17, blue: 0.22)
    static let sage = Color(red: 0.29, green: 0.44, blue: 0.37)
}
struct BloomButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(16)
            .background(BloomStyle.berry.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule()).foregroundStyle(.white)
    }
}
struct BloomCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 14) { content }.frame(maxWidth: .infinity, alignment: .leading).padding(22).background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 26)) }
}
struct Page<Content: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 22) {
            Text(eyebrow.uppercased()).font(.caption.weight(.semibold)).tracking(3).foregroundStyle(BloomStyle.berry)
            Text(title).font(.system(.largeTitle, design: .serif).weight(.medium)).foregroundStyle(BloomStyle.ink)
            content
        }.padding(22) }.background(BloomStyle.paper).toolbarBackground(BloomStyle.paper, for: .navigationBar)
    }
}
func shortDate(_ date: Date) -> String { date.formatted(.dateTime.month(.abbreviated).day()) }
func dateRange(_ first: Date, _ last: Date) -> String { "\(shortDate(first)) – \(shortDate(last))" }
struct SafetyNote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Awareness, never contraception", systemImage: "exclamationmark.shield").font(.headline)
            Text(PredictionEngine.disclaimer).font(.footnote)
            Link("Read ACOG’s fertility awareness guidance", destination: URL(string: "https://www.acog.org/womens-health/faqs/fertility-awareness-based-methods-of-family-planning")!).font(.footnote.bold())
        }.foregroundStyle(BloomStyle.ink).padding(18).background(BloomStyle.berry.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}
