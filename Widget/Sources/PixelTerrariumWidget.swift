import SwiftUI
import TerrariumCore
import WidgetKit

struct TerrariumTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: TerrariumWidgetSnapshot
}

struct TerrariumTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TerrariumTimelineEntry {
        TerrariumTimelineEntry(date: .now, snapshot: .placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (TerrariumTimelineEntry) -> Void) {
        completion(TerrariumTimelineEntry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TerrariumTimelineEntry>) -> Void) {
        let now = Date.now
        let projections = WidgetTimelinePlanner.projections(
            from: loadSnapshot(),
            now: now
        )
        let entries = projections.map {
            TerrariumTimelineEntry(date: $0.date, snapshot: $0.snapshot)
        }
        let nextReload = entries.last?.date.addingTimeInterval(3_600)
            ?? now.addingTimeInterval(3_600)
        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }

    private func loadSnapshot() -> TerrariumWidgetSnapshot {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: TerrariumCore.appGroupIdentifier
        ) else {
            return .placeholder()
        }
        return (try? WidgetSnapshotStore(containerURL: containerURL).read()) ?? .placeholder()
    }
}

struct TerrariumWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TerrariumTimelineEntry

    private var period: DayPeriod {
        DayPeriod(
            date: entry.date,
            timeZone: TimeZone(identifier: entry.snapshot.timeZoneIdentifier) ?? .current
        )
    }

    private var foregroundColor: Color {
        period == .night || period == .evening ? .white : .black
    }

    var body: some View {
        ZStack {
            WidgetPeriodBackground(period: period)

            switch family {
            case .systemMedium:
                mediumContent
            default:
                smallContent
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "pixelterrarium://home"))
    }

    private var smallContent: some View {
        VStack(spacing: 3) {
            ProceduralTerrariumSnapshotView(snapshot: entry.snapshot)
                .frame(maxHeight: 95)

            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("\(entry.snapshot.hydration)%")
                    .monospacedDigit()
            }
            .font(.caption.bold())

            Text(lastWateredText)
                .font(.caption2)
                .foregroundStyle(foregroundColor.opacity(0.72))
                .lineLimit(1)
        }
        .padding(10)
        .foregroundStyle(foregroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.snapshot.stage.displayName)、水分\(entry.snapshot.hydration)パーセント、\(lastWateredText)"
        )
    }

    private var mediumContent: some View {
        HStack(spacing: 10) {
            ProceduralTerrariumSnapshotView(snapshot: entry.snapshot)
                .frame(maxWidth: 145, maxHeight: 140)

            VStack(alignment: .leading, spacing: 7) {
                Text(entry.snapshot.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.snapshot.stage.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(foregroundColor.opacity(0.72))

                ProgressView(value: Double(entry.snapshot.hydration), total: 100)
                    .tint(entry.snapshot.hydration >= 40 ? .cyan : .orange)

                Text(statusMessage)
                    .font(.caption)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .foregroundStyle(foregroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mediumAccessibilityLabel)
    }

    private var lastWateredText: String {
        guard let lastWateredAt = entry.snapshot.lastWateredAt else {
            return "まだ水やりしていません"
        }
        return "最終水やり " + lastWateredAt.formatted(.dateTime.month().day())
    }

    private var mediumAccessibilityLabel: String {
        "\(entry.snapshot.name)、\(entry.snapshot.stage.displayName)、" +
            "水分\(entry.snapshot.hydration)パーセント、\(statusMessage)"
    }

    private var statusMessage: String {
        if entry.snapshot.wateredToday {
            return "今日は水やり済みです"
        }
        return entry.snapshot.hydration >= 40
            ? "ゆっくり育っています"
            : "アプリで水をあげましょう"
    }
}

private struct WidgetPeriodBackground: View {
    let period: DayPeriod

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var colors: [Color] {
        switch period {
        case .morning:
            [Color(red: 0.62, green: 0.82, blue: 0.91), Color(red: 0.98, green: 0.80, blue: 0.53)]
        case .daytime:
            [Color(red: 0.72, green: 0.92, blue: 0.74), .white]
        case .evening:
            [Color(red: 0.96, green: 0.56, blue: 0.35), Color.purple.opacity(0.65)]
        case .night:
            [Color(red: 0.07, green: 0.14, blue: 0.34), Color(red: 0.04, green: 0.19, blue: 0.16)]
        }
    }
}

@main
struct PixelTerrariumWidget: Widget {
    let kind = TerrariumCore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TerrariumTimelineProvider()) { entry in
            TerrariumWidgetView(entry: entry)
        }
        .configurationDisplayName("Pixel Terrarium")
        .description("育っているテラリウムを眺められます。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview("Small", as: .systemSmall) {
    PixelTerrariumWidget()
} timeline: {
    TerrariumTimelineEntry(date: .now, snapshot: .placeholder())
}

#Preview("Medium", as: .systemMedium) {
    PixelTerrariumWidget()
} timeline: {
    TerrariumTimelineEntry(date: .now, snapshot: .placeholder())
}
