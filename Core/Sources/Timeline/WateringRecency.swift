import Foundation

public enum WateringRecency {
    public static func label(lastWateredAt: Date?, relativeTo date: Date) -> String {
        guard let lastWateredAt else {
            return "まだ水やりしていません"
        }

        let elapsed = max(0, date.timeIntervalSince(lastWateredAt))
        let hours = Int(elapsed / 3_600)
        if hours == 0 {
            return "たった今、水やり"
        }
        if hours < 24 {
            return "\(hours)時間前に水やり"
        }
        return "\(Int(elapsed / 86_400))日前に水やり"
    }

    public static func timelineBoundaries(
        lastWateredAt: Date?,
        after date: Date,
        through endDate: Date
    ) -> [Date] {
        guard let lastWateredAt, date < endDate else { return [] }

        let elapsed = max(0, date.timeIntervalSince(lastWateredAt))
        let interval = elapsed < 86_400 ? 3_600.0 : 86_400.0
        let completedIntervals = floor(elapsed / interval)
        var boundary = lastWateredAt.addingTimeInterval((completedIntervals + 1) * interval)
        var boundaries: [Date] = []
        while boundary <= endDate {
            if boundary > date {
                boundaries.append(boundary)
            }
            let elapsed = boundary.timeIntervalSince(lastWateredAt)
            boundary = boundary.addingTimeInterval(elapsed < 86_400 ? 3_600 : 86_400)
        }
        return boundaries
    }
}
