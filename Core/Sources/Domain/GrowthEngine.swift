import Foundation

public enum WateringResult: Equatable, Sendable {
    case accepted(state: TerrariumState, event: WateringEvent)
    case alreadyWatered(state: TerrariumState)
}

public enum GrowthEngine {
    public static let initialHydration = 70
    public static let dailyHydrationLoss = 20
    public static let wateringAmount = 50
    public static let hydratedThreshold = 40

    public static func resolve(_ original: TerrariumState, at date: Date) -> TerrariumState {
        var state = original
        let calendar = calendar(for: state.timeZoneIdentifier)
        let targetDay = calendar.startOfDay(for: date)
        var resolvedDay = calendar.startOfDay(for: state.lastResolvedDay)

        guard targetDay > resolvedDay else {
            return state
        }

        while resolvedDay < targetDay {
            if state.hydration >= hydratedThreshold {
                state.growthPoints += 1
            }
            state.hydration = max(0, state.hydration - dailyHydrationLoss)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: resolvedDay) else {
                break
            }
            resolvedDay = nextDay
        }

        state.lastResolvedDay = resolvedDay
        return state
    }

    public static func water(
        _ original: TerrariumState,
        events: [WateringEvent],
        at date: Date,
        amount: Int = wateringAmount
    ) -> WateringResult {
        let state = resolve(original, at: date)
        let calendar = calendar(for: state.timeZoneIdentifier)
        let alreadyWatered = events.contains { event in
            event.terrariumID == state.id && calendar.isDate(event.wateredAt, inSameDayAs: date)
        }

        guard !alreadyWatered else {
            return .alreadyWatered(state: state)
        }

        var wateredState = state
        wateredState.hydration = min(100, wateredState.hydration + amount)
        let event = WateringEvent(
            terrariumID: state.id,
            wateredAt: date,
            amount: amount
        )
        return .accepted(state: wateredState, event: event)
    }

    public static func hasWateredToday(
        terrariumID: UUID,
        events: [WateringEvent],
        at date: Date,
        timeZoneIdentifier: String
    ) -> Bool {
        let calendar = calendar(for: timeZoneIdentifier)
        return events.contains { event in
            event.terrariumID == terrariumID && calendar.isDate(event.wateredAt, inSameDayAs: date)
        }
    }

    public static func calendar(for timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        return calendar
    }
}
