import Foundation
import SwiftData
import TerrariumCore

@Model
final class TerrariumRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var plantedAt: Date
    var timeZoneIdentifier: String
    var seed: UInt64
    var lastResolvedDay: Date
    var hydration: Int
    var growthPoints: Int

    init(state: TerrariumState) {
        id = state.id
        name = state.name
        plantedAt = state.plantedAt
        timeZoneIdentifier = state.timeZoneIdentifier
        seed = state.seed
        lastResolvedDay = state.lastResolvedDay
        hydration = state.hydration
        growthPoints = state.growthPoints
    }

    var state: TerrariumState {
        TerrariumState(
            id: id,
            name: name,
            plantedAt: plantedAt,
            timeZoneIdentifier: timeZoneIdentifier,
            seed: seed,
            lastResolvedDay: lastResolvedDay,
            hydration: hydration,
            growthPoints: growthPoints
        )
    }

    func apply(_ state: TerrariumState) {
        name = state.name
        lastResolvedDay = state.lastResolvedDay
        hydration = state.hydration
        growthPoints = state.growthPoints
    }
}

@Model
final class WateringEventRecord {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var dayKey: String
    var terrariumID: UUID
    var wateredAt: Date
    var amount: Int

    init(event: WateringEvent, timeZoneIdentifier: String) {
        id = event.id
        terrariumID = event.terrariumID
        wateredAt = event.wateredAt
        amount = event.amount
        dayKey = Self.makeDayKey(
            terrariumID: event.terrariumID,
            date: event.wateredAt,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    var event: WateringEvent {
        WateringEvent(
            id: id,
            terrariumID: terrariumID,
            wateredAt: wateredAt,
            amount: amount
        )
    }

    private static func makeDayKey(
        terrariumID: UUID,
        date: Date,
        timeZoneIdentifier: String
    ) -> String {
        let calendar = GrowthEngine.calendar(for: timeZoneIdentifier)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%@|%04d-%02d-%02d",
            terrariumID.uuidString,
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
