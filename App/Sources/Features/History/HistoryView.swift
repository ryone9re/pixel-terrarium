import SwiftUI
import TerrariumCore

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let terrarium: TerrariumRecord
    let events: [WateringEventRecord]

    var body: some View {
        NavigationStack {
            List {
                Section("現在の成長") {
                    LabeledContent(
                        "成長段階",
                        value: GrowthStage(growthPoints: terrarium.growthPoints).displayName
                    )
                    LabeledContent("成長ポイント", value: "\(terrarium.growthPoints)")
                    LabeledContent("植えた日", value: terrarium.plantedAt.formatted(date: .long, time: .omitted))
                }

                Section("水やりの記録") {
                    if events.isEmpty {
                        ContentUnavailableView(
                            "まだ記録がありません",
                            systemImage: "drop",
                            description: Text("最初の水やりがここに残ります")
                        )
                    } else {
                        ForEach(events) { event in
                            HStack {
                                Label("水をあげました", systemImage: "drop.fill")
                                Spacer()
                                Text(event.wateredAt, format: .dateTime.month().day().hour().minute())
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .navigationTitle("育成の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
