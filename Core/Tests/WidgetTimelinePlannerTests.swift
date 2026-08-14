import Foundation
import Testing
@testable import TerrariumCore

@Suite("Widgetタイムライン")
struct WidgetTimelinePlannerTests {
    @Test("時間帯境界と次の午前0時を含む")
    func containsBoundaries() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-08-14T16:30:00+09:00"))
        let boundaries = WidgetTimelinePlanner.timelineBoundaries(
            after: now,
            timeZoneIdentifier: "Asia/Tokyo",
            days: 1
        )
        let formatter = ISO8601DateFormatter()
        let values = boundaries.map(formatter.string(from:))

        #expect(values.contains("2026-08-14T08:00:00Z"))
        #expect(values.contains("2026-08-14T11:00:00Z"))
        #expect(values.contains("2026-08-14T15:00:00Z"))
    }

    @Test(arguments: [
        ("2026-08-14T05:00:00+09:00", DayPeriod.morning),
        ("2026-08-14T10:00:00+09:00", DayPeriod.daytime),
        ("2026-08-14T17:00:00+09:00", DayPeriod.evening),
        ("2026-08-14T20:00:00+09:00", DayPeriod.night)
    ])
    func dayPeriod(value: String, expected: DayPeriod) throws {
        let parsed = try #require(ISO8601DateFormatter().date(from: value))
        #expect(DayPeriod(date: parsed, timeZone: TimeZone(identifier: "Asia/Tokyo")!) == expected)
    }
}
