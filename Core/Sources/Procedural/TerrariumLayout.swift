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
        public let xPosition: Float
        public let zPosition: Float
        public let rotation: Float
        public let angle: Float
        public let height: Float
        public let bend: Float
        public let leafletPairs: Int
        public let tone: Int
    }

    public struct Droplet: Equatable, Sendable {
        public let xRatio: Float
        public let yRatio: Float
        public let azimuth: Float
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
            (-0.22, 0.14), (0.30, -0.12), (-0.58, -0.28), (0.61, 0.27),
            (-0.14, -0.56), (0.18, 0.58), (-0.84, 0.04), (0.86, -0.06),
            (-0.56, 0.56), (0.54, -0.58), (-0.94, -0.43), (0.95, 0.44),
            (-0.40, -0.78), (0.42, 0.78), (-0.76, 0.34), (0.78, -0.36),
            (-0.10, 0.84), (0.08, -0.84), (-1.00, 0.52), (1.00, -0.50),
            (-0.72, -0.68), (0.70, 0.68), (-0.96, -0.02), (0.98, 0.02)
        ]
        let anchors = baseAnchors.map { xPosition, zPosition in
            (
                xPosition + random.range(-0.10...0.10),
                zPosition + random.range(-0.08...0.08)
            )
        }
        // Low patches expand and overlap across the soil as growth advances.
        let mossCount = min(42, 4 + stage.rawValue * 6 + growthPoints / 5)
        return (0..<mossCount).map { index in
            let anchor = anchors[index % anchors.count]
            let angle = random.range(0...(Float.pi * 2))
            let scatter = random.range(0.015...0.14) * (index < anchors.count ? 0.15 : 1)
            let layerScale: Float = if index < anchors.count {
                1
            } else if index < anchors.count * 2 {
                0.74
            } else {
                0.58
            }
            let radius = random.range(0.18...0.28)
                * (0.55 + progress * 0.75)
                * layerScale
            let toneRoll = Int(random.next() % 5)
            let tone = [0, 1, 2, 2, 2][toneRoll]
            return TerrariumLayout.MossMound(
                xPosition: clamp(anchor.0 + cos(angle) * scatter, to: -1.06...1.06),
                zPosition: clamp(anchor.1 + sin(angle) * scatter * 0.72, to: -0.90...0.90),
                radius: radius,
                height: random.range(0.055...0.11) * (0.64 + progress * 0.48),
                tone: tone,
                rotation: random.range(0...(Float.pi * 2))
            )
        }
    }

    private static func makeStones(random: inout SplitMix64) -> [TerrariumLayout.Stone] {
        let stonePositions: [(Float, Float)] = [
            (-0.24, 0.03), (0.24, -0.08), (0.05, 0.27), (-0.34, 0.30),
            (0.36, 0.23), (-0.05, -0.30)
        ]
        return stonePositions.enumerated().map { index, position in
            TerrariumLayout.Stone(
                xPosition: position.0 + random.range(-0.055...0.055),
                zPosition: position.1 + random.range(-0.045...0.045),
                radius: index == 0 ? random.range(0.34...0.41) : random.range(0.17...0.25),
                height: index == 0 ? random.range(0.29...0.36) : random.range(0.13...0.22),
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
        let crownAnchors: [(Float, Float)] = [
            (-0.52, 0.27),
            (0.50, 0.13),
            (-0.10, -0.34)
        ]
        let crownRotations: [Float] = [0.35, -0.62, 2.35]
        let crownHeightScales: [Float] = [0.82, 0.72, 0.62]
        return (0..<frondCount).map { index in
            let fan: Float = index.isMultiple(of: 2) ? -0.42 : 0.42
            let outerFrondScale = 1 - abs(fan) * 0.12
            let crownIndex = min(crownAnchors.count - 1, index / 2)
            let crown = crownAnchors[crownIndex]
            return TerrariumLayout.FernFrond(
                xPosition: crown.0 + random.range(-0.045...0.045),
                zPosition: crown.1 + random.range(-0.035...0.035),
                rotation: crownRotations[crownIndex] + random.range(-0.16...0.16),
                angle: fan * 1.35 + random.range(-0.20...0.20),
                height: (0.53 + Float(stage.rawValue) * 0.16)
                    * random.range(0.86...1.14)
                    * outerFrondScale
                    * crownHeightScales[crownIndex],
                bend: fan * random.range(0.55...0.82),
                leafletPairs: min(15, 6 + stage.rawValue + index % 4),
                tone: index % 3
            )
        }
    }

    private static func makeDroplets(
        hydration: Int,
        random: inout SplitMix64
    ) -> [TerrariumLayout.Droplet] {
        let dropletCount = hydration >= 40 ? 21 : 6
        let goldenAngle = Float.pi * (3 - sqrt(5 as Float))
        return (0..<dropletCount).map { index in
            let xRatio = random.range(-0.82...0.82)
            let yRatio = random.range(0.16...0.86)
            let rawAzimuth = (Float(index) * goldenAngle + random.range(-0.16...0.16))
                .truncatingRemainder(dividingBy: .pi * 2)
            let azimuth = rawAzimuth < 0 ? rawAzimuth + .pi * 2 : rawAzimuth
            return TerrariumLayout.Droplet(
                xRatio: xRatio,
                yRatio: yRatio,
                azimuth: azimuth,
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
