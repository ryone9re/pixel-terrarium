import AudioToolbox
import SwiftData
import SwiftUI
import TerrariumCore

private enum HomeSheet: String, Identifiable {
    case history
    case settings

    var id: String { rawValue }
}

struct TerrariumHomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    #if DEBUG
    @AppStorage(
        TerrariumCore.debugPeriodKey,
        store: UserDefaults(suiteName: TerrariumCore.appGroupIdentifier)
    ) private var debugPeriodRawValue =
        DebugDayPeriodOverride.automatic.rawValue
    #endif

    let terrarium: TerrariumRecord
    let allTerrariums: [TerrariumRecord]
    let eventRecords: [WateringEventRecord]

    @State private var presentedSheet: HomeSheet?
    @State private var isWateringAnimationVisible = false
    @State private var statusMessage: String?

    private var events: [WateringEventRecord] {
        eventRecords.filter { $0.terrariumID == terrarium.id }
    }

    private var isWateredToday: Bool {
        GrowthEngine.hasWateredToday(
            terrariumID: terrarium.id,
            events: events.map(\.event),
            at: AppClock.now,
            timeZoneIdentifier: terrarium.timeZoneIdentifier
        )
    }

    private var stage: GrowthStage { GrowthStage(growthPoints: terrarium.growthPoints) }

    private var period: DayPeriod {
        #if DEBUG
        if let override = DebugDayPeriodOverride(rawValue: debugPeriodRawValue),
           let period = override.period {
            return period
        }
        #endif
        return DayPeriod(
            date: AppClock.now,
            timeZone: TimeZone(identifier: terrarium.timeZoneIdentifier) ?? .current
        )
    }

    var body: some View {
        ZStack {
            TerrariumBackground(period: period)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    toolbar

                    TerrariumSceneView(
                        seed: terrarium.seed,
                        growthPoints: terrarium.growthPoints,
                        hydration: terrarium.hydration,
                        period: period
                    )
                    .frame(minHeight: 340, idealHeight: 430)
                    .overlay {
                        if isWateringAnimationVisible {
                            WaterDropsView(reduceMotion: reduceMotion)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(stage.displayName)のテラリウム")

                    informationCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .history:
                HistoryView(terrarium: terrarium, events: events)
            case .settings:
                SettingsView(
                    terrarium: terrarium,
                    allTerrariums: allTerrariums,
                    events: eventRecords
                )
            }
        }
        .preferredColorScheme(period == .night || period == .evening ? .dark : .light)
    }

    private var toolbar: some View {
        HStack {
            Button {
                presentedSheet = .history
            } label: {
                Label("記録", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("history-button")

            Spacer()

            Button {
                TerrariumPersistence.suspendArtworkRendering()
                presentedSheet = .settings
            } label: {
                Label("設定", systemImage: "gearshape")
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("settings-button")
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .padding(.top, 8)
    }

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(terrarium.name)
                    .font(.title2.bold())
                Text("\(stage.displayName) · 成長ポイント \(terrarium.growthPoints)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        HydrationStatus(hydration: terrarium.hydration).displayName,
                        systemImage: "drop.fill"
                    )
                    Spacer()
                    Text("\(terrarium.hydration)%")
                        .monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))

                ProgressView(value: Double(terrarium.hydration), total: 100)
                    .tint(terrarium.hydration >= 40 ? .cyan : .orange)
                    .accessibilityLabel("水分")
                    .accessibilityValue("\(terrarium.hydration)パーセント")
            }

            Button(isWateredToday ? "今日は水やり済み" : "水をあげる", action: water)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isWateredToday)
                .accessibilityHint(isWateredToday ? "明日もう一度水をあげられます" : "水分を50増やします")
                .accessibilityIdentifier("water-button")

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
                    .accessibilityIdentifier("watering-status")
            }
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }

    private func water() {
        guard (try? TerrariumPersistence.water(
            terrarium,
            eventRecords: eventRecords,
            now: AppClock.now,
            in: modelContext
        )) == true else { return }

        if hapticsEnabled {
            HapticManager.shared.success()
        }
        if soundEnabled {
            AudioServicesPlaySystemSound(1104)
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            statusMessage = "明日の成長につながります"
            isWateringAnimationVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 350 : 800))
            withAnimation(.easeOut(duration: 0.2)) {
                isWateringAnimationVisible = false
            }
        }
    }
}
