import Foundation

public struct TerrariumLayout: Equatable, Sendable {
    public struct MossMound: Equatable, Sendable {
        public let xPosition: Float
        public let zPosition: Float
        public let radius: Float
        public let height: Float
        public let tone: Int
        public let rotation: Float
    }

    public struct Stone: Equatable, Sendable {
        public let xPosition: Float
        public let zPosition: Float
        public let radius: Float
        public let height: Float
        public let rotation: Float
        public let tone: Int
    }

    public struct FernFrond: Equatable, Sendable {
        public let angle: Float
        public let height: Float
        public let bend: Float
        public let leafletPairs: Int
        public let tone: Int
    }

    public struct Droplet: Equatable, Sendable {
        public let xRatio: Float
        public let yRatio: Float
        public let size: Float
        public let glint: Float
    }

    public let mossMounds: [MossMound]
    public let stones: [Stone]
    public let fernFronds: [FernFrond]
    public let droplets: [Droplet]
    public let branchRotation: Float
    public let growthProgress: Float
}

public enum TerrariumLayoutGenerator {
    public static func generate(
        seed: UInt64,
        growthPoints: Int,
        hydration: Int
    ) -> TerrariumLayout {
        let stage = GrowthStage(growthPoints: growthPoints)
        let progress = min(1, max(0, Float(growthPoints) / 21))
        var mossRandom = SplitMix64(seed: seed ^ 0x4D4F_5353)
        var decorRandom = SplitMix64(seed: seed ^ 0x4445_434F_52)
        var fernRandom = SplitMix64(seed: seed ^ 0x4645_524E)
        var dropletRandom = SplitMix64(seed: seed ^ 0x4452_4F50)

        return TerrariumLayout(
            mossMounds: makeMoss(
                stage: stage,
                growthPoints: growthPoints,
                progress: progress,
                random: &mossRandom
            ),
            stones: makeStones(random: &decorRandom),
            fernFronds: makeFronds(stage: stage, random: &fernRandom),
            droplets: makeDroplets(hydration: hydration, random: &dropletRandom),
            branchRotation: decorRandom.range(-0.55 ... -0.20),
            growthProgress: progress
        )
    }

    private static func makeMoss(
        stage: GrowthStage,
        growthPoints: Int,
        progress: Float,
        random: inout SplitMix64
    ) -> [TerrariumLayout.MossMound] {
        let baseAnchors: [(Float, Float)] = [
            (-0.78, -0.08), (-0.48, 0.34), (-0.18, -0.34), (0.18, 0.32),
            (0.52, -0.28), (0.79, 0.10), (0.02, 0.57)
        ]
        let anchors = baseAnchors.map { xPosition, zPosition in
            (
                xPosition + random.range(-0.10...0.10),
                zPosition + random.range(-0.08...0.08)
            )
        }
        // Each entry becomes a multi-lobed cushion in RealityKit. Keeping the
        // number of entities modest preserves smooth rotation while the mesh
        // itself supplies the fine moss detail.
        let mossCount = min(22, 8 + stage.rawValue * 2 + growthPoints / 7)
        return (0..<mossCount).map { index in
            let anchor = anchors[index % anchors.count]
            let angle = random.range(0...(Float.pi * 2))
            let scatter = random.range(0.02...0.20) * (index < anchors.count ? 0.25 : 1)
            let radius = random.range(0.15...0.25) * (0.90 + progress * 0.20)
            return TerrariumLayout.MossMound(
                xPosition: clamp(anchor.0 + cos(angle) * scatter, to: -1.02...1.02),
                zPosition: clamp(anchor.1 + sin(angle) * scatter * 0.72, to: -0.70...0.70),
                radius: radius,
                height: random.range(0.15...0.33) * (0.82 + progress * 0.32),
                tone: Int(random.next() % 3),
                rotation: random.range(0...(Float.pi * 2))
            )
        }
    }

    private static func makeStones(random: inout SplitMix64) -> [TerrariumLayout.Stone] {
        let stonePositions: [(Float, Float)] = [(-0.48, 0.06), (0.72, -0.18), (0.47, 0.52), (-0.84, 0.48)]
        return stonePositions.enumerated().map { index, position in
            TerrariumLayout.Stone(
                xPosition: position.0 + random.range(-0.10...0.10),
                zPosition: position.1 + random.range(-0.08...0.08),
                radius: index == 0 ? random.range(0.35...0.43) : random.range(0.14...0.22),
                height: index == 0 ? random.range(0.28...0.36) : random.range(0.10...0.18),
                rotation: random.range(0...(Float.pi * 2)),
                tone: index % 3
            )
        }
    }

    private static func makeFronds(
        stage: GrowthStage,
        random: inout SplitMix64
    ) -> [TerrariumLayout.FernFrond] {
        let frondCount = stage == .seed ? 0 : min(6, stage.rawValue + 1)
        return (0..<frondCount).map { index in
            let fan = frondCount == 1 ? 0 : Float(index) / Float(frondCount - 1) - 0.5
            return TerrariumLayout.FernFrond(
                angle: fan * 1.75 + random.range(-0.14...0.14),
                height: (0.53 + Float(stage.rawValue) * 0.16) * random.range(0.86...1.14),
                bend: fan * random.range(0.24...0.48),
                leafletPairs: min(9, 3 + stage.rawValue + index % 2),
                tone: index % 3
            )
        }
    }

    private static func makeDroplets(
        hydration: Int,
        random: inout SplitMix64
    ) -> [TerrariumLayout.Droplet] {
        let dropletCount = hydration >= 40 ? 21 : 6
        return (0..<dropletCount).map { _ in
            TerrariumLayout.Droplet(
                xRatio: random.range(-0.82...0.82),
                yRatio: random.range(0.16...0.86),
                size: random.range(0.018...0.045),
                glint: random.range(0.35...1)
            )
        }
    }

    private static func clamp(_ value: Float, to range: ClosedRange<Float>) -> Float {
        min(range.upperBound, max(range.lowerBound, value))
    }
}

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func unit() -> Float {
        Float(Double(next() >> 11) / Double(1 << 53))
    }

    mutating func range(_ range: ClosedRange<Float>) -> Float {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }
}
