import Foundation
import Testing
@testable import TerrariumCore

@Suite("育成ルール")
struct GrowthEngineTests {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    @Test("作成直後は水分70、成長0、段階0")
    func initialState() throws {
        let now = try date("2026-08-14T08:00:00+09:00")
        let state = TerrariumState.new(name: "テスト", now: now, timeZone: tokyo, seed: 1)

        #expect(state.hydration == 70)
        #expect(state.growthPoints == 0)
        #expect(GrowthStage(growthPoints: state.growthPoints) == .seed)
    }

    @Test("同日の水やりは一度だけで水分は100を超えない")
    func waterOncePerDay() throws {
        let now = try date("2026-08-14T08:00:00+09:00")
        let state = TerrariumState.new(name: "テスト", now: now, timeZone: tokyo, seed: 1)
        let first = GrowthEngine.water(state, events: [], at: now)

        guard case let .accepted(wateredState, event) = first else {
            Issue.record("最初の水やりが拒否された")
            return
        }
        #expect(wateredState.hydration == 100)

        let second = GrowthEngine.water(wateredState, events: [event], at: now.addingTimeInterval(3_600))
        guard case let .alreadyWatered(unchanged) = second else {
            Issue.record("同日の二度目の水やりが受理された")
            return
        }
        #expect(unchanged.hydration == 100)
    }

    @Test("午前0時ごとに水分と成長を一度だけ確定する")
    func resolvesMidnightOnce() throws {
        let createdAt = try date("2026-08-14T08:00:00+09:00")
        let state = TerrariumState.new(name: "テスト", now: createdAt, timeZone: tokyo, seed: 1)
        let nextDay = try date("2026-08-15T00:01:00+09:00")

        let resolved = GrowthEngine.resolve(state, at: nextDay)
        #expect(resolved.hydration == 50)
        #expect(resolved.growthPoints == 1)
        #expect(GrowthEngine.resolve(resolved, at: nextDay).growthPoints == 1)
    }

    @Test("日末水分40未満では成長しない")
    func dryDayStopsGrowth() throws {
        let createdAt = try date("2026-08-14T08:00:00+09:00")
        var state = TerrariumState.new(name: "テスト", now: createdAt, timeZone: tokyo, seed: 1)
        state.hydration = 39

        let resolved = GrowthEngine.resolve(state, at: try date("2026-08-15T12:00:00+09:00"))
        #expect(resolved.hydration == 19)
        #expect(resolved.growthPoints == 0)
    }

    @Test("毎日水をあげると21日で最終段階になる")
    func reachesForestInTwentyOneDays() throws {
        let createdAt = try date("2026-08-01T08:00:00+09:00")
        var state = TerrariumState.new(name: "テスト", now: createdAt, timeZone: tokyo, seed: 1)
        var events: [WateringEvent] = []

        for dayOffset in 0...21 {
            let wateringDate = calendarWithTimeZone(tokyo).date(byAdding: .day, value: dayOffset, to: createdAt)!
            switch GrowthEngine.water(state, events: events, at: wateringDate) {
            case let .accepted(nextState, event):
                state = nextState
                events.append(event)
            case .alreadyWatered:
                Issue.record("異なる日の水やりが拒否された")
            }
        }

        #expect(state.growthPoints == 21)
        #expect(GrowthStage(growthPoints: state.growthPoints) == .forest)
    }

    @Test("30日放置しても水分は0未満にならず成長は巻き戻らない")
    func abandonmentAndClockRollback() throws {
        let createdAt = try date("2026-08-01T08:00:00+09:00")
        let state = TerrariumState.new(name: "テスト", now: createdAt, timeZone: tokyo, seed: 1)
        let future = calendarWithTimeZone(tokyo).date(byAdding: .day, value: 30, to: createdAt)!
        let resolved = GrowthEngine.resolve(state, at: future)

        #expect(resolved.hydration == 0)
        #expect(resolved.growthPoints == 2)
        #expect(GrowthEngine.resolve(resolved, at: createdAt) == resolved)
    }

    @Test("夏時間をまたいでも暦日を一度ずつ処理する")
    func daylightSavingTime() throws {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let createdAt = try date("2026-03-07T12:00:00-08:00")
        let state = TerrariumState.new(name: "DST", now: createdAt, timeZone: losAngeles, seed: 1)
        let afterTransition = try date("2026-03-09T12:00:00-07:00")
        let resolved = GrowthEngine.resolve(state, at: afterTransition)

        #expect(resolved.growthPoints == 2)
        #expect(resolved.hydration == 30)
    }
}

private func date(_ value: String) throws -> Date {
    try #require(ISO8601DateFormatter().date(from: value))
}

private func calendarWithTimeZone(_ timeZone: TimeZone) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
}
