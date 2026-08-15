import RealityKit
import SwiftUI
import TerrariumCore

struct TerrariumSceneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let seed: UInt64
    let growthPoints: Int
    let hydration: Int
    let period: DayPeriod
    @State private var yaw: Float = 0
    @GestureState private var dragYaw: Float = 0

    private var displayedYaw: Float {
        yaw + dragYaw
    }

    private var layout: TerrariumLayout {
        TerrariumLayoutGenerator.generate(
            seed: seed,
            growthPoints: growthPoints,
            hydration: hydration
        )
    }

    var body: some View {
        ZStack {
            RealityView { content in
                let root = await TerrariumSceneFactory.makeRoot(
                    layout: layout,
                    hydration: hydration
                )
                content.add(root)
                for light in TerrariumEntityFactory.makeLights(period: period) {
                    content.add(light)
                }
            } update: { content in
                guard let root = content.entities.first(where: { $0.name == "terrarium-root" }) else {
                    return
                }
                root.orientation = simd_quatf(angle: displayedYaw, axis: SIMD3<Float>(0, 1, 0))
            }
            .id("\(seed)-\(growthPoints)")

            if hydration >= 40 && (period == .evening || period == .night) {
                WaterGlintsView(droplets: layout.droplets, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
            }

            if period == .evening || period == .night {
                RomanticMotesView(reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .updating($dragYaw) { value, state, _ in
                    state = Float(value.translation.width / 180)
                }
                .onEnded { value in
                    yaw = normalizedYaw(yaw + Float(value.translation.width / 180))
                }
        )
    }

    private func normalizedYaw(_ angle: Float) -> Float {
        let fullRotation = Float.pi * 2
        let remainder = angle.truncatingRemainder(dividingBy: fullRotation)
        if remainder > .pi {
            return remainder - fullRotation
        }
        if remainder < -.pi {
            return remainder + fullRotation
        }
        return remainder
    }
}

@MainActor
enum TerrariumEntityFactory {
    static func makeLights(period: DayPeriod) -> [Entity] {
        let keyLight = DirectionalLight()
        let warmIntensity: Float = period == .night || period == .evening ? 5_600 : 4_100
        keyLight.light = DirectionalLightComponent(
            color: UIColor(red: 1, green: 0.82, blue: 0.43, alpha: 1),
            intensity: warmIntensity
        )
        keyLight.look(
            at: SIMD3<Float>(0, 0.3, -3.8),
            from: SIMD3<Float>(2.8, 3.6, -1.0),
            relativeTo: nil
        )

        let fillLight = PointLight()
        fillLight.light = PointLightComponent(
            cgColor: UIColor(red: 0.22, green: 0.58, blue: 1, alpha: 1).cgColor,
            intensity: period == .night || period == .evening ? 9_500 : 5_500,
            attenuationRadius: 9
        )
        fillLight.position = SIMD3<Float>(-2.5, 1.8, -2.0)

        let lanternLight = PointLight()
        lanternLight.light = PointLightComponent(
            cgColor: UIColor(red: 1, green: 0.62, blue: 0.20, alpha: 1).cgColor,
            intensity: period == .night || period == .evening ? 4_800 : 1_900,
            attenuationRadius: 3.4
        )
        lanternLight.position = SIMD3<Float>(0.72, 0.65, -2.05)
        return [keyLight, fillLight, lanternLight]
    }

    static func makeHardware() -> Entity {
        let root = Entity()
        let darkMetal = TerrariumMaterialFactory.darkMetal()
        let bronze = TerrariumMaterialFactory.bronze()

        let base = ModelEntity(
            mesh: .generateCylinder(height: 0.38, radius: 1.48),
            materials: [darkMetal]
        )
        base.position.y = -0.98
        root.addChild(base)

        let baseRim = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 1.56),
            materials: [bronze]
        )
        baseRim.position.y = -0.77
        root.addChild(baseRim)

        let collar = ModelEntity(
            mesh: .generateCylinder(height: 0.22, radius: 0.48),
            materials: [darkMetal]
        )
        collar.position.y = 2.34
        root.addChild(collar)

        let knob = ModelEntity(mesh: .generateSphere(radius: 0.24), materials: [darkMetal])
        knob.scale.y = 0.72
        knob.position.y = 2.62
        root.addChild(knob)
        return root
    }

    static func makeGlassDroplets(
        _ droplets: [TerrariumLayout.Droplet],
        hydrated: Bool
    ) -> Entity {
        let root = Entity()
        root.name = "GlassDroplets"
        guard hydrated else { return root }

        for (index, droplet) in droplets.prefix(18).enumerated() {
            let radius = max(0.018, droplet.size * 0.72)
            let entity = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [TerrariumMaterialFactory.droplet(glint: droplet.glint)]
            )
            entity.scale = SIMD3<Float>(0.72, 1.34 + Float(index % 3) * 0.08, 0.26)
            entity.position = SIMD3<Float>(
                droplet.xRatio * 1.10,
                -0.42 + droplet.yRatio * 2.45,
                1.285 - abs(droplet.xRatio) * 0.22
            )
            root.addChild(entity)
        }
        return root
    }

}

extension TerrariumEntityFactory {
    static func makeContents(layout: TerrariumLayout, hydration: Int) -> Entity {
        let root = Entity()
        let hydrated = hydration >= 40
        let soilMaterial = TerrariumMaterialFactory.soil(hydrated: hydrated)
        let soil = ModelEntity(
            mesh: .generateCylinder(height: 0.46, radius: 1.24),
            materials: [soilMaterial]
        )
        soil.position.y = -0.91
        root.addChild(soil)

        let carpet = ModelEntity(
            mesh: .generateCylinder(height: 0.045, radius: 1.18),
            materials: [TerrariumMaterialFactory.moss(tone: hydrated ? 1 : 0, hydrated: hydrated)]
        )
        carpet.position.y = -0.66
        root.addChild(carpet)

        addMoss(layout.mossMounds, hydrated: hydrated, to: root)
        addStones(layout.stones, hydrated: hydrated, to: root)
        addBranch(rotation: layout.branchRotation, to: root)
        addFern(layout.fernFronds, hydrated: hydrated, to: root)
        if layout.growthProgress >= 1 {
            addForestGlows(to: root)
        }
        return root
    }

    private static func addMoss(
        _ mounds: [TerrariumLayout.MossMound],
        hydrated: Bool,
        to root: Entity
    ) {
        for (index, mound) in mounds.enumerated() {
            let material = TerrariumMaterialFactory.moss(tone: 0, hydrated: hydrated)
            let entity = ModelEntity(mesh: OrganicMeshFactory.moss(variant: index), materials: [material])
            entity.scale = SIMD3<Float>(mound.radius, mound.height * 0.60, mound.radius * 0.88)
            entity.position = SIMD3<Float>(mound.xPosition, -0.68 + mound.height * 0.27, mound.zPosition)
            entity.orientation = simd_quatf(angle: mound.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)

            addMossTexture(mound: mound, hydrated: hydrated, index: index, to: root)
        }
    }

    private static func addMossTexture(
        mound: TerrariumLayout.MossMound,
        hydrated: Bool,
        index: Int,
        to root: Entity
    ) {
        for tuftIndex in 0..<4 {
            let angle = mound.rotation + Float(tuftIndex) * 2.399 + Float(index % 3) * 0.35
            let spread = mound.radius * (0.10 + Float((tuftIndex + index) % 4) * 0.075)
            let size = mound.radius * (0.23 + Float((index + tuftIndex) % 3) * 0.035)
            let tuft = ModelEntity(
                mesh: OrganicMeshFactory.moss(variant: index + tuftIndex + 1),
                materials: [TerrariumMaterialFactory.moss(
                    tone: (mound.tone + tuftIndex) % 3,
                    hydrated: hydrated
                )]
            )
            tuft.scale = SIMD3<Float>(size, size * 0.62, size * 0.82)
            tuft.position = SIMD3<Float>(
                mound.xPosition + cos(angle) * spread,
                -0.66 + mound.height * (0.78 + Float(tuftIndex % 3) * 0.055),
                mound.zPosition + sin(angle) * spread * 0.88
            )
            tuft.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(tuft)
        }
    }

    private static func addStones(
        _ stones: [TerrariumLayout.Stone],
        hydrated: Bool,
        to root: Entity
    ) {
        for (index, stone) in stones.enumerated() {
            let material = TerrariumMaterialFactory.stone(tone: stone.tone, hydrated: hydrated)
            let entity = ModelEntity(mesh: OrganicMeshFactory.stone(variant: index), materials: [material])
            entity.scale = SIMD3<Float>(stone.radius, stone.height, stone.radius * 0.82)
            entity.position = SIMD3<Float>(stone.xPosition, -0.62 + stone.height * 0.45, stone.zPosition)
            entity.orientation = simd_quatf(angle: stone.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
        }
    }

    private static func addBranch(rotation: Float, to root: Entity) {
        let bark = TerrariumMaterialFactory.bark()
        for index in 0..<4 {
            let segment = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.34, 0.075, 0.09), cornerRadius: 0.018),
                materials: [bark]
            )
            segment.position = SIMD3<Float>(-0.32 + Float(index) * 0.27, -0.53, 0.20 - Float(index) * 0.06)
            segment.orientation = simd_quatf(angle: rotation + Float(index) * 0.045, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(segment)
        }
    }

    private static func addFern(
        _ fronds: [TerrariumLayout.FernFrond],
        hydrated: Bool,
        to root: Entity
    ) {
        let stem = TerrariumMaterialFactory.stem(hydrated: hydrated)
        let leafColors = hydrated
            ? [
                UIColor(red: 0.10, green: 0.40, blue: 0.055, alpha: 1),
                UIColor(red: 0.19, green: 0.52, blue: 0.075, alpha: 1),
                UIColor(red: 0.075, green: 0.32, blue: 0.045, alpha: 1)
            ]
            : [
                UIColor(red: 0.39, green: 0.40, blue: 0.10, alpha: 1),
                UIColor(red: 0.46, green: 0.43, blue: 0.11, alpha: 1),
                UIColor(red: 0.31, green: 0.34, blue: 0.08, alpha: 1)
            ]

        for frond in fronds {
            addFrond(
                frond,
                stem: stem,
                leafMaterial: TerrariumMaterialFactory.leaf(
                    color: leafColors[frond.tone],
                    hydrated: hydrated
                ),
                to: root
            )
        }

        if fronds.isEmpty {
            let seed = ModelEntity(
                mesh: .generateSphere(radius: 0.08),
                materials: [SimpleMaterial(color: .brown, roughness: 1, isMetallic: false)]
            )
            seed.position = SIMD3<Float>(0, -0.59, 0)
            root.addChild(seed)
        }
    }

    private static func addFrond(
        _ frond: TerrariumLayout.FernFrond,
        stem: PhysicallyBasedMaterial,
        leafMaterial: PhysicallyBasedMaterial,
        to root: Entity
    ) {
        let segmentCount = max(3, frond.leafletPairs)
        let direction = SIMD2<Float>(cos(frond.angle), sin(frond.angle))
        var previous = SIMD3<Float>(0, -0.58, 0)

        for level in 1...segmentCount {
            let progress = Float(level) / Float(segmentCount)
            let horizontal = frond.bend * progress * progress
            let point = SIMD3<Float>(
                direction.x * horizontal,
                -0.58 + frond.height * progress,
                direction.y * horizontal
            )
            addSegment(from: previous, to: point, thickness: 0.025, material: stem, to: root)
            if level < segmentCount {
                addLeafPair(
                    at: point,
                    angle: frond.angle,
                    length: 0.18 * sin(progress * .pi) + 0.055,
                    material: leafMaterial,
                    to: root
                )
            }
            previous = point
        }
    }

    private static func addLeafPair(
        at point: SIMD3<Float>,
        angle: Float,
        length: Float,
        material: PhysicallyBasedMaterial,
        to root: Entity
    ) {
        let direction = SIMD2<Float>(cos(angle), sin(angle))
        let side = SIMD3<Float>(-direction.y, 0, direction.x)
        for sign: Float in [-1, 1] {
            let leaf = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(length, 0.022, 0.055), cornerRadius: 0.008),
                materials: [material]
            )
            leaf.position = point + side * (sign * length * 0.42)
            leaf.orientation = simd_quatf(
                angle: angle + (sign > 0 ? -.pi / 2 : .pi / 2),
                axis: SIMD3<Float>(0, 1, 0)
            )
            root.addChild(leaf)
        }
    }

    private static func addSegment(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        thickness: Float,
        material: PhysicallyBasedMaterial,
        to root: Entity
    ) {
        let vector = end - start
        let length = simd_length(vector)
        let segment = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(thickness, length, thickness), cornerRadius: thickness * 0.25),
            materials: [material]
        )
        segment.position = (start + end) / 2
        segment.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(vector))
        root.addChild(segment)
    }
    private static func addForestGlows(to root: Entity) {
        let material = UnlitMaterial(color: UIColor(red: 0.92, green: 1, blue: 0.43, alpha: 0.95))
        for index in 0..<9 {
            let glow = ModelEntity(mesh: .generateSphere(radius: 0.025), materials: [material])
            let angle = Float(index) / 9 * .pi * 2
            glow.position = SIMD3<Float>(cos(angle) * 0.76, -0.05 + Float(index % 3) * 0.19, sin(angle) * 0.48)
            root.addChild(glow)
        }
    }
}
