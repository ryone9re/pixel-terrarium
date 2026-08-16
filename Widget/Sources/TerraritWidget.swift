import SwiftUI
import TerrariumCore
import WidgetKit

struct TerrariumTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: TerrariumWidgetSnapshot
    let artworkData: Data?
}

private func resolvedPeriod(at date: Date, snapshot: TerrariumWidgetSnapshot) -> DayPeriod {
    #if DEBUG
    if let rawValue = UserDefaults(suiteName: TerrariumCore.appGroupIdentifier)?
        .string(forKey: TerrariumCore.debugPeriodKey),
       let override = DebugDayPeriodOverride(rawValue: rawValue),
       let period = override.period {
        return period
    }
    #endif
    let timeZone = TimeZone(identifier: snapshot.timeZoneIdentifier) ?? .current
    return DayPeriod(date: date, timeZone: timeZone)
}

struct TerrariumTimelineProvider: TimelineProvider {
    private struct LoadedContent {
        let snapshot: TerrariumWidgetSnapshot
        let artworkByPeriod: [DayPeriod: Data]
    }

    func placeholder(in context: Context) -> TerrariumTimelineEntry {
        TerrariumTimelineEntry(date: .now, snapshot: .placeholder(), artworkData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TerrariumTimelineEntry) -> Void) {
        let now = Date.now
        let content = loadContent()
        completion(TerrariumTimelineEntry(
            date: now,
            snapshot: content.snapshot,
            artworkData: content.artworkByPeriod[period(at: now, snapshot: content.snapshot)]
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TerrariumTimelineEntry>) -> Void) {
        let now = Date.now
        let content = loadContent()
        let snapshot = content.snapshot
        let periodBoundaries = WidgetTimelinePlanner.timelineBoundaries(
            after: now,
            timeZoneIdentifier: snapshot.timeZoneIdentifier
        )
        let endDate = periodBoundaries.last ?? now.addingTimeInterval(86_400)
        let wateringBoundaries = WateringRecency.timelineBoundaries(
            lastWateredAt: snapshot.lastWateredAt,
            after: now,
            through: endDate
        )
        let dates = Array(Set([now] + periodBoundaries + wateringBoundaries)).sorted()
        let entries = dates.map { date in
            TerrariumTimelineEntry(
                date: date,
                snapshot: snapshot,
                artworkData: content.artworkByPeriod[period(at: date, snapshot: snapshot)]
            )
        }
        let nextReload = entries.last?.date.addingTimeInterval(3_600)
            ?? now.addingTimeInterval(3_600)
        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }

    private func loadContent() -> LoadedContent {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: TerrariumCore.appGroupIdentifier
        ) else {
            return LoadedContent(snapshot: .placeholder(), artworkByPeriod: [:])
        }
        if let publication = try? WidgetPublicationStore(containerURL: containerURL).read() {
            let artworkByPeriod: [DayPeriod: Data] = Dictionary(
                uniqueKeysWithValues: DayPeriod.allCases.compactMap { period in
                    guard let data = try? WidgetArtworkStore(
                        containerURL: containerURL,
                        generationID: publication.generationID,
                        period: period
                    ).read() else { return nil }
                    return (period, data)
                }
            )
            return LoadedContent(
                snapshot: publication.snapshot,
                artworkByPeriod: artworkByPeriod
            )
        }

        // 旧形式から更新した直後は、新しい一式が完成するまで最後の有効画像を使う。
        let snapshot = (try? WidgetSnapshotStore(containerURL: containerURL).read()) ?? .placeholder()
        let legacyArtwork: [DayPeriod: Data] = Dictionary(
            uniqueKeysWithValues: DayPeriod.allCases.compactMap { period in
                guard let data = try? WidgetArtworkStore(
                    containerURL: containerURL,
                    period: period
                ).read() else { return nil }
                return (period, data)
            }
        )
        return LoadedContent(snapshot: snapshot, artworkByPeriod: legacyArtwork)
    }

    private func period(at date: Date, snapshot: TerrariumWidgetSnapshot) -> DayPeriod {
        resolvedPeriod(at: date, snapshot: snapshot)
    }
}

struct TerrariumWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TerrariumTimelineEntry

    private var period: DayPeriod {
        resolvedPeriod(at: entry.date, snapshot: entry.snapshot)
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
        .widgetURL(URL(string: "terrarit://home"))
    }

    private var smallContent: some View {
        VStack(spacing: 3) {
            TerrariumWidgetArtworkView(snapshot: entry.snapshot, artworkData: entry.artworkData)
                .frame(maxHeight: 95)

            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("\(entry.snapshot.hydration)%")
                    .monospacedDigit()
            }
            .font(.caption.bold())

            lastWateredLabel
                .font(.caption2)
                .foregroundStyle(foregroundColor.opacity(0.72))
                .lineLimit(1)
        }
        .padding(10)
        .foregroundStyle(foregroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(smallAccessibilityPrefix)\(lastWateredLabel)")
        )
    }

    private var mediumContent: some View {
        HStack(spacing: 10) {
            TerrariumWidgetArtworkView(snapshot: entry.snapshot, artworkData: entry.artworkData)
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

                lastWateredLabel
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

    private var lastWateredLabel: Text {
        Text(WateringRecency.label(
            lastWateredAt: entry.snapshot.lastWateredAt,
            relativeTo: entry.date
        ))
    }

    private var smallAccessibilityPrefix: String {
        "\(entry.snapshot.stage.displayName)、水分\(entry.snapshot.hydration)パーセント、"
    }

    private var mediumAccessibilityLabel: Text {
        Text("\(mediumAccessibilityPrefix)\(lastWateredLabel)")
    }

    private var mediumAccessibilityPrefix: String {
        "\(entry.snapshot.name)、\(entry.snapshot.stage.displayName)、" +
            "水分\(entry.snapshot.hydration)パーセント、"
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
struct TerraritWidget: Widget {
    let kind = TerrariumCore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TerrariumTimelineProvider()) { entry in
            TerrariumWidgetView(entry: entry)
        }
        .configurationDisplayName("Terrarit")
        .description("育っているテラリウムを眺められます。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview("Small", as: .systemSmall) {
    TerraritWidget()
} timeline: {
    TerrariumTimelineEntry(date: .now, snapshot: .placeholder(), artworkData: nil)
}

#Preview("Medium", as: .systemMedium) {
    TerraritWidget()
} timeline: {
    TerrariumTimelineEntry(date: .now, snapshot: .placeholder(), artworkData: nil)
}
