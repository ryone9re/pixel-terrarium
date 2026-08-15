#if DEBUG
import Testing
@testable import TerrariumCore

struct DebugDayPeriodOverrideTests {
    @Test
    func mapsPreviewChoicesToPeriods() {
        #expect(DebugDayPeriodOverride.automatic.period == nil)
        #expect(DebugDayPeriodOverride.morning.period == .morning)
        #expect(DebugDayPeriodOverride.daytime.period == .daytime)
        #expect(DebugDayPeriodOverride.evening.period == .evening)
        #expect(DebugDayPeriodOverride.night.period == .night)
    }
}
#endif
