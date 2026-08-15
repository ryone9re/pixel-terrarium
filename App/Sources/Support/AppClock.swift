import Foundation

@MainActor
enum AppClock {
    static let debugOffsetKey = "debugTimeOffsetDays"

    static var now: Date {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-day") {
            return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        }
        let days = UserDefaults.standard.integer(forKey: debugOffsetKey)
        return Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        #else
        return .now
        #endif
    }
}
