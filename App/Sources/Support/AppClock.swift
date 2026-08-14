import Foundation

@MainActor
enum AppClock {
    private static let offsetKey = "debugTimeOffsetDays"

    static var now: Date {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-day") {
            return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        }
        let days = UserDefaults.standard.integer(forKey: offsetKey)
        return Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        #else
        return .now
        #endif
    }

    #if DEBUG
    static var debugOffsetDays: Int {
        UserDefaults.standard.integer(forKey: offsetKey)
    }

    static func advanceOneDay() {
        UserDefaults.standard.set(debugOffsetDays + 1, forKey: offsetKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: offsetKey)
    }
    #endif
}
