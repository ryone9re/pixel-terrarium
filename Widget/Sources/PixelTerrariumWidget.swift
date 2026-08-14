import SwiftUI
import TerrariumCore
import WidgetKit

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}

struct PlaceholderWidgetView: View {
    var entry: PlaceholderEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tree.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Pixel Terrarium")
                .font(.headline)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct PixelTerrariumWidget: Widget {
    let kind = TerrariumCore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            PlaceholderWidgetView(entry: entry)
        }
        .configurationDisplayName("Pixel Terrarium")
        .description("育っているテラリウムを眺められます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
