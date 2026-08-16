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

public struct TerrariumWidgetPublication: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let currentRendererVersion = 7

    public let schemaVersion: Int
    public let rendererVersion: Int
    public let generationID: UUID
    public let generatedAt: Date
    public let snapshot: TerrariumWidgetSnapshot

    public init(
        schemaVersion: Int = currentSchemaVersion,
        rendererVersion: Int = currentRendererVersion,
        generationID: UUID,
        generatedAt: Date,
        snapshot: TerrariumWidgetSnapshot
    ) {
        self.schemaVersion = schemaVersion
        self.rendererVersion = rendererVersion
        self.generationID = generationID
        self.generatedAt = generatedAt
        self.snapshot = snapshot
    }
}

public enum WidgetPublicationError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case unsupportedRendererVersion(Int)
}

public struct WidgetPublicationStore: Sendable {
    public static let fileName = "terrarium-widget-publication.json"
    public let fileURL: URL

    public init(containerURL: URL) {
        fileURL = containerURL.appendingPathComponent(Self.fileName, isDirectory: false)
    }

    public func write(_ publication: TerrariumWidgetPublication) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(publication).write(to: fileURL, options: .atomic)
    }

    public func read() throws -> TerrariumWidgetPublication {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let publication = try decoder.decode(
            TerrariumWidgetPublication.self,
            from: Data(contentsOf: fileURL)
        )
        guard publication.schemaVersion == TerrariumWidgetPublication.currentSchemaVersion else {
            throw WidgetPublicationError.unsupportedSchemaVersion(publication.schemaVersion)
        }
        guard publication.rendererVersion == TerrariumWidgetPublication.currentRendererVersion else {
            throw WidgetPublicationError.unsupportedRendererVersion(publication.rendererVersion)
        }
        return publication
    }

    public func remove() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}

public struct WidgetArtworkStore: Sendable {
    private static let filePrefix = "terrarium-widget-artwork-"
    public let fileURL: URL

    public init(containerURL: URL, period: DayPeriod) {
        fileURL = containerURL.appendingPathComponent(
            "\(Self.filePrefix)\(period.rawValue).png",
            isDirectory: false
        )
    }

    public init(containerURL: URL, generationID: UUID, period: DayPeriod) {
        fileURL = containerURL.appendingPathComponent(
            "\(Self.filePrefix)\(generationID.uuidString.lowercased())-\(period.rawValue).png",
            isDirectory: false
        )
    }

    public func write(_ data: Data) throws {
        try data.write(to: fileURL, options: .atomic)
    }

    public func read() throws -> Data {
        try Data(contentsOf: fileURL)
    }

    public func remove() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    public static func removeAll(
        containerURL: URL,
        keeping generationIDs: Set<UUID> = []
    ) {
        let keptFileNames = Set(generationIDs.flatMap { generationID in
            DayPeriod.allCases.map { period in
                WidgetArtworkStore(
                    containerURL: containerURL,
                    generationID: generationID,
                    period: period
                ).fileURL.lastPathComponent
            }
        })
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: containerURL,
            includingPropertiesForKeys: nil
        ) else { return }
        for fileURL in fileURLs where
            fileURL.lastPathComponent.hasPrefix(filePrefix)
            && fileURL.pathExtension == "png"
            && !keptFileNames.contains(fileURL.lastPathComponent) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

public enum TerrariumCore {
    public static let appGroupIdentifier = "group.dev.ryo.pixelterrarium"
    public static let widgetKind = "PixelTerrariumWidget"
    public static let debugPeriodKey = "debugDayPeriodOverride"
}
