import Foundation
import SwiftData
import TerrariumCore
import WidgetKit

@MainActor
enum TerrariumPersistence {
    private struct ArtworkRequest {
        let snapshot: TerrariumWidgetSnapshot
        let containerURL: URL
        let generationID: UUID
    }

    private static var artworkTask: Task<Void, Never>?
    private static var pendingArtworkRequest: ArtworkRequest?
    private static var isArtworkRenderingSuspended = false

    static func create(name: String, now: Date, in context: ModelContext) throws -> TerrariumRecord {
        let resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let state = TerrariumState.new(
            name: resolvedName.isEmpty ? "わたしのテラリウム" : resolvedName,
            now: now,
            timeZone: .current
        )
        let record = TerrariumRecord(state: state)
        context.insert(record)
        try context.save()
        scheduleSnapshotPublication(for: record, eventRecords: [], now: now)
        return record
    }

    static func resolve(
        _ record: TerrariumRecord,
        eventRecords: [WateringEventRecord],
        now: Date,
        in context: ModelContext
    ) throws {
        let state = GrowthEngine.resolve(record.state, at: now)
        guard state != record.state else {
            scheduleSnapshotPublication(for: record, eventRecords: eventRecords, now: now)
            return
        }
        record.apply(state)
        try context.save()
        scheduleSnapshotPublication(for: record, eventRecords: eventRecords, now: now)
    }

    static func water(
        _ record: TerrariumRecord,
        eventRecords: [WateringEventRecord],
        now: Date,
        in context: ModelContext
    ) throws -> Bool {
        let events = eventRecords.filter { $0.terrariumID == record.id }.map(\.event)
        switch GrowthEngine.water(record.state, events: events, at: now) {
        case let .accepted(state, event):
            record.apply(state)
            let newRecord = WateringEventRecord(
                event: event,
                timeZoneIdentifier: record.timeZoneIdentifier
            )
            context.insert(newRecord)
            try context.save()
            scheduleSnapshotPublication(
                for: record,
                eventRecords: eventRecords + [newRecord],
                now: now
            )
            return true
        case let .alreadyWatered(state):
            record.apply(state)
            return false
        }
    }

    static func rename(
        _ record: TerrariumRecord,
        to name: String,
        eventRecords: [WateringEventRecord],
        now: Date,
        in context: ModelContext
    ) throws {
        let resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        record.name = resolvedName.isEmpty ? "わたしのテラリウム" : resolvedName
        try context.save()
        scheduleSnapshotPublication(for: record, eventRecords: eventRecords, now: now)
    }

    static func deleteAll(
        terrariums: [TerrariumRecord],
        events: [WateringEventRecord],
        in context: ModelContext
    ) throws {
        events.forEach(context.delete)
        terrariums.forEach(context.delete)
        try context.save()
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: TerrariumCore.appGroupIdentifier
        ) {
            try? FileManager.default.removeItem(
                at: WidgetSnapshotStore(containerURL: containerURL).fileURL
            )
            try? WidgetPublicationStore(containerURL: containerURL).remove()
            WidgetArtworkStore.removeAll(containerURL: containerURL)
        }
        artworkTask?.cancel()
        artworkTask = nil
        pendingArtworkRequest = nil
        WidgetCenter.shared.reloadTimelines(ofKind: TerrariumCore.widgetKind)
    }

    static func suspendArtworkRendering() {
        isArtworkRenderingSuspended = true
        artworkTask?.cancel()
        artworkTask = nil
    }

    static func resumeArtworkRendering() {
        isArtworkRenderingSuspended = false
        guard let request = pendingArtworkRequest else { return }
        startArtworkRender(request)
    }

    #if DEBUG
    static func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: TerrariumCore.widgetKind)
    }
    #endif

    private static func scheduleSnapshotPublication(
        for record: TerrariumRecord,
        eventRecords: [WateringEventRecord],
        now: Date
    ) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: TerrariumCore.appGroupIdentifier
        ) else { return }
        let relevantEvents = eventRecords
            .filter { $0.terrariumID == record.id }
            .sorted { $0.wateredAt > $1.wateredAt }
        let snapshot = TerrariumWidgetSnapshot(
            terrariumID: record.id,
            name: record.name,
            resolvedAt: now,
            timeZoneIdentifier: record.timeZoneIdentifier,
            seed: record.seed,
            hydration: record.hydration,
            growthPoints: record.growthPoints,
            wateredToday: GrowthEngine.hasWateredToday(
                terrariumID: record.id,
                events: relevantEvents.map(\.event),
                at: now,
                timeZoneIdentifier: record.timeZoneIdentifier
            ),
            lastWateredAt: relevantEvents.first?.wateredAt
        )
        let request = ArtworkRequest(
            snapshot: snapshot,
            containerURL: containerURL,
            generationID: UUID()
        )
        pendingArtworkRequest = request
        guard !isArtworkRenderingSuspended else { return }
        startArtworkRender(request)
    }

    private static func startArtworkRender(_ request: ArtworkRequest) {
        artworkTask?.cancel()
        artworkTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            for period in DayPeriod.allCases {
                guard !Task.isCancelled else { return }
                guard let artwork = await TerrariumWidgetArtworkRenderer.render(
                    snapshot: request.snapshot,
                    period: period
                ), isCurrent(request) else { return }
                do {
                    try WidgetArtworkStore(
                        containerURL: request.containerURL,
                        generationID: request.generationID,
                        period: period
                    ).write(artwork)
                } catch {
                    return
                }
                await Task.yield()
            }
            guard isCurrent(request) else { return }
            let publicationStore = WidgetPublicationStore(containerURL: request.containerURL)
            let previousGenerationID = try? publicationStore.read().generationID
            let publication = TerrariumWidgetPublication(
                generationID: request.generationID,
                generatedAt: .now,
                snapshot: request.snapshot
            )
            do {
                try publicationStore.write(publication)
            } catch {
                return
            }
            pendingArtworkRequest = nil
            WidgetCenter.shared.reloadTimelines(ofKind: TerrariumCore.widgetKind)
            WidgetArtworkStore.removeAll(
                containerURL: request.containerURL,
                keeping: Set([previousGenerationID, request.generationID].compactMap { $0 })
            )
        }
    }

    private static func isCurrent(_ request: ArtworkRequest) -> Bool {
        !Task.isCancelled && pendingArtworkRequest?.generationID == request.generationID
    }
}
