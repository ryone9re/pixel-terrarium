import SwiftData
import SwiftUI
import TerrariumCore

@main
struct TerraritApp: App {
    private let modelContainer: ModelContainer

    init() {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            UserDefaults.standard.removeObject(forKey: "debugTimeOffsetDays")
            UserDefaults(suiteName: TerrariumCore.appGroupIdentifier)?
                .removeObject(forKey: TerrariumCore.debugPeriodKey)
        }
        let schema = Schema([TerrariumRecord.self, WateringEventRecord.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("--ui-testing")
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftDataの初期化に失敗しました: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .tint(.terrariumGreen)
        }
        .modelContainer(modelContainer)
    }
}
