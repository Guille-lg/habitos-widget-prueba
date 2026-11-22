import SwiftUI
import WidgetKit
import AppIntents

struct WaterEntry: TimelineEntry {
    let date: Date
    let count: Int
    var storageReady = true
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry { WaterEntry(date: Date(), count: 0) }
    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now)!)
        completion(Timeline(entries: [entry()], policy: .after(midnight)))
    }
    private func entry() -> WaterEntry {
        do { return WaterEntry(date: Date(), count: try SharedStorage.ledger().count()) }
        catch { return WaterEntry(date: Date(), count: 0, storageReady: false) }
    }
}

struct WaterWidgetView: View {
    let entry: WaterEntry
    var liters: String { (Double(entry.count) / 2).formatted(.number.locale(Locale(identifier: "es_ES"))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Agua", systemImage: "drop.fill").font(.subheadline.bold())
                Spacer(minLength: 0)
            }
            if entry.storageReady {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(liters).font(.system(size: 34, weight: .bold)).minimumScaleFactor(0.6)
                    Text("/ 3 L").font(.subheadline).foregroundStyle(.secondary)
                }.accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                Button(intent: AddWaterIntent()) {
                    Label("0,5 L", systemImage: "plus")
                        .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 9)
                }
                .buttonStyle(.plain).foregroundStyle(.white)
                .background(.black, in: RoundedRectangle(cornerRadius: 9))
                .accessibilityLabel("Añadir medio litro de agua")
            } else {
                Text("Abre la app para comprobar la instalación.").font(.caption)
            }
        }
        .containerBackground(.white, for: .widget)
    }
}

@main
struct WaterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStorage.widgetKind, provider: WaterProvider()) { entry in
            WaterWidgetView(entry: entry)
        }
        .configurationDisplayName("Agua")
        .description("Registra medio litro sin abrir la app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
