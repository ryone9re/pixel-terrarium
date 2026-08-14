import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TerrariumRecord.plantedAt) private var terrariums: [TerrariumRecord]
    @Query(sort: \WateringEventRecord.wateredAt, order: .reverse) private var events: [WateringEventRecord]

    var body: some View {
        Group {
            if let terrarium = terrariums.first {
                TerrariumHomeView(
                    terrarium: terrarium,
                    allTerrariums: terrariums,
                    eventRecords: events
                )
            } else {
                OnboardingView()
            }
        }
        .task {
            seedForUITestingIfNeeded()
        }
        .task(id: terrariums.first?.lastResolvedDay) {
            guard let terrarium = terrariums.first else { return }
            try? TerrariumPersistence.resolve(
                terrarium,
                eventRecords: events,
                now: AppClock.now,
                in: modelContext
            )
        }
        .onOpenURL { url in
            guard url.scheme == "pixelterrarium" else { return }
        }
    }

    @MainActor
    private func seedForUITestingIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--seed-sample"), terrariums.isEmpty else { return }
        guard let record = try? TerrariumPersistence.create(
            name: "星あかりの森",
            now: AppClock.now,
            in: modelContext
        ) else { return }
        record.growthPoints = 21
        record.hydration = 78
        try? modelContext.save()
    }
}
