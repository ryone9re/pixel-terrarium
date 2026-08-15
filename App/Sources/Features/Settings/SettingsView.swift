import SwiftData
import SwiftUI
import TerrariumCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    #if DEBUG
    @AppStorage(AppClock.debugOffsetKey) private var debugOffsetDays = 0
    @AppStorage(
        TerrariumCore.debugPeriodKey,
        store: UserDefaults(suiteName: TerrariumCore.appGroupIdentifier)
    ) private var debugPeriodRawValue =
        DebugDayPeriodOverride.automatic.rawValue
    #endif

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
                Section {
                    Picker("時間帯プレビュー", selection: $debugPeriodRawValue) {
                        ForEach(DebugDayPeriodOverride.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .accessibilityIdentifier("debug-period-picker")
                    .accessibilityValue(
                        DebugDayPeriodOverride(rawValue: debugPeriodRawValue)?.displayName ?? "自動"
                    )
                    .onChange(of: debugPeriodRawValue) {
                        TerrariumPersistence.reloadWidgetTimelines()
                    }

                    LabeledContent("進めた日数", value: "\(debugOffsetDays)日")
                        .accessibilityIdentifier("advanced-day-count")
                        .accessibilityValue("\(debugOffsetDays)日")
                    Button("翌日へ進める") {
                        debugOffsetDays += 1
                        try? TerrariumPersistence.resolve(
                            terrarium,
                            eventRecords: events,
                            now: AppClock.now,
                            in: modelContext
                        )
                    }
                    .accessibilityIdentifier("advance-day-button")
                    Button("現在の日付へ戻す") {
                        debugOffsetDays = 0
                    }
                    .accessibilityIdentifier("reset-day-button")
                } header: {
                    Text("開発者メニュー")
                } footer: {
                    Text("時間帯プレビューは表示だけを変更します。日付、成長、水やり状態には影響しません。")
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
        .onDisappear {
            TerrariumPersistence.resumeArtworkRendering()
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
