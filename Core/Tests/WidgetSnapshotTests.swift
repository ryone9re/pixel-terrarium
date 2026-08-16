import Foundation
import Testing
@testable import TerrariumCore

@Suite("Widgetスナップショット")
struct WidgetSnapshotTests {
    @Test("JSON書き込みと読み込みが一致する")
    func roundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = WidgetSnapshotStore(containerURL: directory)
        let snapshot = TerrariumWidgetSnapshot.placeholder(at: Date(timeIntervalSince1970: 1_000))
        try store.write(snapshot)
        #expect(try store.read() == snapshot)
    }

    @Test("未知のschemaVersionを拒否する")
    func rejectsUnknownSchema() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(containerURL: directory)
        let invalid = TerrariumWidgetSnapshot(
            schemaVersion: 999,
            terrariumID: UUID(),
            name: "未来",
            resolvedAt: .now,
            timeZoneIdentifier: "Asia/Tokyo",
            seed: 1,
            hydration: 70,
            growthPoints: 0,
            wateredToday: false,
            lastWateredAt: nil
        )
        try store.write(invalid)

        #expect(throws: WidgetSnapshotError.unsupportedSchemaVersion(999)) {
            try store.read()
        }
    }

    @Test("Widget画像を原子的に保存して読み戻せる")
    func artworkRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = WidgetArtworkStore(containerURL: directory, period: .night)
        let artwork = Data([0x89, 0x50, 0x4E, 0x47])
        try store.write(artwork)

        #expect(try store.read() == artwork)
        try store.remove()
        #expect(!FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    @Test("公開情報と同じ世代の画像を読み戻せる")
    func publicationRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let generationID = UUID()
        let snapshot = TerrariumWidgetSnapshot.placeholder(at: Date(timeIntervalSince1970: 1_000))
        let publication = TerrariumWidgetPublication(
            generationID: generationID,
            generatedAt: Date(timeIntervalSince1970: 1_100),
            snapshot: snapshot
        )
        let artwork = Data([0x89, 0x50, 0x4E, 0x47])
        try WidgetArtworkStore(
            containerURL: directory,
            generationID: generationID,
            period: .night
        ).write(artwork)
        let publicationStore = WidgetPublicationStore(containerURL: directory)
        try publicationStore.write(publication)

        #expect(try publicationStore.read() == publication)
        #expect(
            try WidgetArtworkStore(
                containerURL: directory,
                generationID: generationID,
                period: .night
            ).read() == artwork
        )
    }

    @Test("画像整理では指定した世代だけを残す")
    func artworkCleanupKeepsPublishedGenerations() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let keptGenerationID = UUID()
        let removedGenerationID = UUID()
        let data = Data([1])
        let keptStore = WidgetArtworkStore(
            containerURL: directory,
            generationID: keptGenerationID,
            period: .daytime
        )
        let removedStore = WidgetArtworkStore(
            containerURL: directory,
            generationID: removedGenerationID,
            period: .daytime
        )
        try keptStore.write(data)
        try removedStore.write(data)

        WidgetArtworkStore.removeAll(
            containerURL: directory,
            keeping: [keptGenerationID]
        )

        #expect(FileManager.default.fileExists(atPath: keptStore.fileURL.path))
        #expect(!FileManager.default.fileExists(atPath: removedStore.fileURL.path))
    }
}
