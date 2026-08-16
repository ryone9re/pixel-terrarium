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

    @Test
    func matureLayoutStaysWithinRuntimeEntityBudget() {
        let mature = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 100, hydration: 70)

        #expect(mature.mossMounds.count == 42)
        #expect(mature.fernFronds.count <= 6)
        #expect(mature.fernFronds.allSatisfy { (5...15).contains($0.leafletPairs) })
        #expect(mature.fernFronds.contains { $0.leafletPairs >= 13 })
    }

    @Test
    func forestMossDenselyCoversEveryQuadrant() {
        let forest = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 21, hydration: 70)
        let quadrantCounts = [
            forest.mossMounds.count { $0.xPosition < 0 && $0.zPosition < 0 },
            forest.mossMounds.count { $0.xPosition < 0 && $0.zPosition >= 0 },
            forest.mossMounds.count { $0.xPosition >= 0 && $0.zPosition < 0 },
            forest.mossMounds.count { $0.xPosition >= 0 && $0.zPosition >= 0 }
        ]

        #expect(forest.mossMounds.count == 42)
        #expect(quadrantCounts.allSatisfy { $0 >= 6 })
        #expect(forest.mossMounds.count { $0.zPosition > 0.48 } >= 6)
    }

    @Test
    func matureFernSpreadsAcrossMultipleCrowns() {
        let mature = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 21, hydration: 70)
        let xPositions = mature.fernFronds.map(\.xPosition)
        let zPositions = mature.fernFronds.map(\.zPosition)

        #expect((xPositions.max() ?? 0) - (xPositions.min() ?? 0) > 0.55)
        #expect((zPositions.max() ?? 0) - (zPositions.min() ?? 0) > 0.35)
    }

    @Test
    func firstStoneIsTheCompositionalAnchor() {
        let layout = TerrariumLayoutGenerator.generate(seed: 42, growthPoints: 21, hydration: 70)
        let heroStone = layout.stones[0]

        #expect(layout.stones.dropFirst().allSatisfy { heroStone.radius > $0.radius })
        #expect(layout.stones.dropFirst().allSatisfy { heroStone.height > $0.height })
    }
}
