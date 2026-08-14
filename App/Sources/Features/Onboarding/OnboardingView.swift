import SwiftData
import SwiftUI
import TerrariumCore

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name = "わたしのテラリウム"
    @FocusState private var isNameFocused: Bool

    private var period: DayPeriod {
        DayPeriod(date: AppClock.now, timeZone: .current)
    }

    var body: some View {
        ZStack {
            TerrariumBackground(period: period)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    TerrariumSceneView(
                        seed: 1,
                        growthPoints: 0,
                        hydration: 70,
                        period: period
                    )
                        .frame(height: 300)
                        .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text("小さな森を育てよう")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("一日一回の水やりから始まります")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("テラリウムの名前")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("わたしのテラリウム", text: $name)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .focused($isNameFocused)
                            .padding(16)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
                            .accessibilityIdentifier("terrarium-name-field")
                    }

                    Button("この名前で始める", action: start)
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("start-terrarium-button")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(period == .night || period == .evening ? .dark : .light)
    }

    private func start() {
        isNameFocused = false
        _ = try? TerrariumPersistence.create(name: name, now: AppClock.now, in: modelContext)
    }
}

#Preview("初回設定") {
    OnboardingView()
        .modelContainer(for: [TerrariumRecord.self, WateringEventRecord.self], inMemory: true)
}
