import Foundation

public struct TerrariumWidgetSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let terrariumID: UUID
    public let name: String
    public let resolvedAt: Date
    public let timeZoneIdentifier: String
    public let seed: UInt64
    public let hydration: Int
    public let growthPoints: Int
    public let wateredToday: Bool
    public let lastWateredAt: Date?

    public init(
        schemaVersion: Int = currentSchemaVersion,
        terrariumID: UUID,
        name: String,
        resolvedAt: Date,
        timeZoneIdentifier: String,
        seed: UInt64,
        hydration: Int,
        growthPoints: Int,
        wateredToday: Bool,
        lastWateredAt: Date?
    ) {
        self.schemaVersion = schemaVersion
        self.terrariumID = terrariumID
        self.name = name
        self.resolvedAt = resolvedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.seed = seed
        self.hydration = hydration
        self.growthPoints = growthPoints
        self.wateredToday = wateredToday
        self.lastWateredAt = lastWateredAt
    }

    public static func placeholder(at date: Date = .now) -> TerrariumWidgetSnapshot {
        TerrariumWidgetSnapshot(
            terrariumID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "わたしのテラリウム",
            resolvedAt: date,
            timeZoneIdentifier: TimeZone.current.identifier,
            seed: 0,
            hydration: 70,
            growthPoints: 0,
            wateredToday: false,
            lastWateredAt: nil
        )
    }

    public var stage: GrowthStage { GrowthStage(growthPoints: growthPoints) }
    public var hydrationStatus: HydrationStatus { HydrationStatus(hydration: hydration) }
}

public enum WidgetSnapshotError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}

public struct WidgetSnapshotStore: Sendable {
    public static let fileName = "terrarium-widget-snapshot.json"
    public let fileURL: URL

    public init(containerURL: URL) {
        fileURL = containerURL.appendingPathComponent(Self.fileName, isDirectory: false)
    }

    public func write(_ snapshot: TerrariumWidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }

    public func read() throws -> TerrariumWidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(
            TerrariumWidgetSnapshot.self,
            from: Data(contentsOf: fileURL)
        )
        guard snapshot.schemaVersion == TerrariumWidgetSnapshot.currentSchemaVersion else {
            throw WidgetSnapshotError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
        return snapshot
    }
}

public enum TerrariumCore {
    public static let appGroupIdentifier = "group.dev.ryo.pixelterrarium"
    public static let widgetKind = "PixelTerrariumWidget"
}
