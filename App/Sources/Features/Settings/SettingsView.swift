import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true

    let terrarium: TerrariumRecord
    let allTerrariums: [TerrariumRecord]
    let events: [WateringEventRecord]

    @State private var name: String
    @State private var confirmsDeletion = false

    init(
        terrarium: TerrariumRecord,
        allTerrariums: [TerrariumRecord],
        events: [WateringEventRecord]
    ) {
        self.terrarium = terrarium
        self.allTerrariums = allTerrariums
        self.events = events
        _name = State(initialValue: terrarium.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("テラリウム") {
                    TextField("名前", text: $name)
                        .accessibilityIdentifier("settings-name-field")
                }

                Section("体験") {
                    Toggle("効果音", isOn: $soundEnabled)
                    Toggle("触覚フィードバック", isOn: $hapticsEnabled)
                }

                #if DEBUG
                Section("開発者メニュー") {
                    LabeledContent("進めた日数", value: "\(AppClock.debugOffsetDays)日")
                    Button("翌日へ進める") {
                        AppClock.advanceOneDay()
                        try? TerrariumPersistence.resolve(
                            terrarium,
                            eventRecords: events,
                            now: AppClock.now,
                            in: modelContext
                        )
                    }
                    Button("現在の日付へ戻す") {
                        AppClock.reset()
                    }
                }
                #endif

                Section {
                    Button("すべての育成データを削除", role: .destructive) {
                        confirmsDeletion = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("delete-data-button")
                } footer: {
                    Text("この操作は元に戻せません。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveAndDismiss() }
                }
            }
            .confirmationDialog(
                "育成データを削除しますか？",
                isPresented: $confirmsDeletion,
                titleVisibility: .visible
            ) {
                Button("すべて削除", role: .destructive, action: deleteAll)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("テラリウムと水やりの記録が端末から削除されます。")
            }
        }
    }

    private func saveAndDismiss() {
        try? TerrariumPersistence.rename(terrarium, to: name, in: modelContext)
        dismiss()
    }

    private func deleteAll() {
        try? TerrariumPersistence.deleteAll(
            terrariums: allTerrariums,
            events: events,
            in: modelContext
        )
        dismiss()
    }
}
