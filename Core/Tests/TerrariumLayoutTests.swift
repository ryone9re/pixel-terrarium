import Testing
@testable import TerrariumCore

struct TerrariumLayoutTests {
    @Test
    func sameSeedAndStateProduceSameLayout() {
        let first = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 10, hydration: 70)
        let second = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 10, hydration: 70)

        #expect(first == second)
    }

    @Test
    func differentSeedsProduceDifferentLayouts() {
        let first = TerrariumLayoutGenerator.generate(seed: 1, growthPoints: 10, hydration: 70)
        let second = TerrariumLayoutGenerator.generate(seed: 2, growthPoints: 10, hydration: 70)

        #expect(first != second)
    }

    @Test
    func growthAddsMossAndFernWithoutMovingExistingMoss() {
        let young = TerrariumLayoutGenerator.generate(seed: 99, growthPoints: 3, hydration: 70)
        let mature = TerrariumLayoutGenerator.generate(seed: 99, growthPoints: 21, hydration: 70)

        #expect(mature.mossMounds.count > young.mossMounds.count)
        #expect(mature.fernFronds.count > young.fernFronds.count)
        for index in young.mossMounds.indices {
            #expect(mature.mossMounds[index].xPosition == young.mossMounds[index].xPosition)
            #expect(mature.mossMounds[index].zPosition == young.mossMounds[index].zPosition)
        }
    }

    @Test
    func hydratedTerrariumHasMoreDroplets() {
        let dry = TerrariumLayoutGenerator.generate(seed: 7, growthPoints: 10, hydration: 20)
        let wet = TerrariumLayoutGenerator.generate(seed: 7, growthPoints: 10, hydration: 70)

        #expect(wet.droplets.count > dry.droplets.count)
    }
}
