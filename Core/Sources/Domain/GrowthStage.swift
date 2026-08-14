import Foundation

public enum GrowthStage: Int, CaseIterable, Codable, Sendable {
    case seed
    case sprout
    case shoot
    case sapling
    case growing
    case mature
    case forest

    public init(growthPoints: Int) {
        switch growthPoints {
        case 21...: self = .forest
        case 15...: self = .mature
        case 10...: self = .growing
        case 6...: self = .sapling
        case 3...: self = .shoot
        case 1...: self = .sprout
        default: self = .seed
        }
    }

    public var displayName: String {
        switch self {
        case .seed: "種"
        case .sprout: "発芽"
        case .shoot: "若芽"
        case .sapling: "幼木"
        case .growing: "成長期"
        case .mature: "成木"
        case .forest: "豊かな森"
        }
    }

    public var requiredGrowthPoints: Int {
        switch self {
        case .seed: 0
        case .sprout: 1
        case .shoot: 3
        case .sapling: 6
        case .growing: 10
        case .mature: 15
        case .forest: 21
        }
    }
}

public enum HydrationStatus: String, Codable, Sendable {
    case hydrated
    case dry

    public init(hydration: Int) {
        self = hydration >= 40 ? .hydrated : .dry
    }

    public var displayName: String {
        switch self {
        case .hydrated: "潤っている"
        case .dry: "乾いている"
        }
    }
}

public enum DayPeriod: String, CaseIterable, Codable, Sendable {
    case morning
    case daytime
    case evening
    case night

    public init(date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        switch calendar.component(.hour, from: date) {
        case 5 ..< 10: self = .morning
        case 10 ..< 17: self = .daytime
        case 17 ..< 20: self = .evening
        default: self = .night
        }
    }
}

public enum Season: String, Codable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    public init(date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        switch calendar.component(.month, from: date) {
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default: self = .winter
        }
    }
}
