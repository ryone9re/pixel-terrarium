import Foundation

public struct TerrariumState: Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public let plantedAt: Date
    public let timeZoneIdentifier: String
    public let seed: UInt64
    public var lastResolvedDay: Date
    public var hydration: Int
    public var growthPoints: Int

    public init(
        id: UUID = UUID(),
        name: String,
        plantedAt: Date,
        timeZoneIdentifier: String,
        seed: UInt64,
        lastResolvedDay: Date,
        hydration: Int = 70,
        growthPoints: Int = 0
    ) {
        self.id = id
        self.name = name
        self.plantedAt = plantedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.seed = seed
        self.lastResolvedDay = lastResolvedDay
        self.hydration = hydration
        self.growthPoints = growthPoints
    }

    public static func new(
        name: String,
        now: Date,
        timeZone: TimeZone,
        seed: UInt64 = UInt64.random(in: .min ... .max)
    ) -> TerrariumState {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return TerrariumState(
            name: name,
            plantedAt: now,
            timeZoneIdentifier: timeZone.identifier,
            seed: seed,
            lastResolvedDay: calendar.startOfDay(for: now)
        )
    }
}

public struct WateringEvent: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let terrariumID: UUID
    public let wateredAt: Date
    public let amount: Int

    public init(
        id: UUID = UUID(),
        terrariumID: UUID,
        wateredAt: Date,
        amount: Int
    ) {
        self.id = id
        self.terrariumID = terrariumID
        self.wateredAt = wateredAt
        self.amount = amount
    }
}
