import Foundation

public struct WidgetProjection: Equatable, Sendable {
    public let date: Date
    public let snapshot: TerrariumWidgetSnapshot
}

public enum WidgetTimelinePlanner {
    public static func projections(
        from snapshot: TerrariumWidgetSnapshot,
        now: Date,
        days: Int = 7
    ) -> [WidgetProjection] {
        let state = TerrariumState(
            id: snapshot.terrariumID,
            name: snapshot.name,
            plantedAt: snapshot.resolvedAt,
            timeZoneIdentifier: snapshot.timeZoneIdentifier,
            seed: snapshot.seed,
            lastResolvedDay: GrowthEngine.calendar(for: snapshot.timeZoneIdentifier).startOfDay(
                for: snapshot.resolvedAt
            ),
            hydration: snapshot.hydration,
            growthPoints: snapshot.growthPoints
        )
        let boundaries = timelineBoundaries(
            after: now,
            timeZoneIdentifier: snapshot.timeZoneIdentifier,
            days: days
        )

        return ([now] + boundaries).map { date in
            let projected = GrowthEngine.resolve(state, at: date)
            return WidgetProjection(
                date: date,
                snapshot: TerrariumWidgetSnapshot(
                    terrariumID: projected.id,
                    name: projected.name,
                    resolvedAt: date,
                    timeZoneIdentifier: projected.timeZoneIdentifier,
                    seed: projected.seed,
                    hydration: projected.hydration,
                    growthPoints: projected.growthPoints,
                    wateredToday: date == now ? snapshot.wateredToday : false,
                    lastWateredAt: snapshot.lastWateredAt
                )
            )
        }
    }

    public static func timelineBoundaries(
        after date: Date,
        timeZoneIdentifier: String,
        days: Int = 7
    ) -> [Date] {
        let calendar = GrowthEngine.calendar(for: timeZoneIdentifier)
        let startDay = calendar.startOfDay(for: date)
        guard let endDate = calendar.date(byAdding: .day, value: days, to: startDay) else {
            return []
        }

        var boundaries: [Date] = []
        var day = startDay
        while day <= endDate {
            for hour in [0, 5, 10, 17, 20] {
                guard let boundary = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      boundary > date,
                      boundary <= endDate else { continue }
                boundaries.append(boundary)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        return Array(Set(boundaries)).sorted()
    }
}
