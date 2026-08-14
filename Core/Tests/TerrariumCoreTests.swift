import Testing
@testable import TerrariumCore

@Suite("TerrariumCore")
struct TerrariumCoreTests {
    @Test("core target is available")
    func coreIsReady() {
        #expect(TerrariumCore.isReady)
    }
}
