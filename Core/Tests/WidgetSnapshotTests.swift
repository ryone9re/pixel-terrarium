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
}
