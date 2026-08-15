#if DEBUG
public enum DebugDayPeriodOverride: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case morning
    case daytime
    case evening
    case night

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .automatic: "自動"
        case .morning: "朝"
        case .daytime: "昼"
        case .evening: "夕方"
        case .night: "夜"
        }
    }

    public var period: DayPeriod? {
        switch self {
        case .automatic: nil
        case .morning: .morning
        case .daytime: .daytime
        case .evening: .evening
        case .night: .night
        }
    }
}
#endif
