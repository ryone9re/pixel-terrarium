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
        let warmIntensity: Float = switch period {
        case .night: 1_650
        case .evening: 2_800
        default: 4_200
        }
        let fillIntensity: Float = switch period {
        case .night: 2_300
        case .evening: 3_800
        default: 4_800
        }
        let lanternIntensity: Float = switch period {
        case .night: 3_100
        case .evening: 2_500
        default: 1_600
        }
        keyLight.light = DirectionalLightComponent(
            color: UIColor(red: 1, green: 0.82, blue: 0.43, alpha: 1),
            intensity: warmIntensity
        )
        keyLight.shadow = DirectionalLightComponent.Shadow(maximumDistance: 5, depthBias: 1.2)
        keyLight.look(
            at: SIMD3<Float>(0, 0.3, -3.8),
            from: SIMD3<Float>(2.8, 3.6, -1.0),
            relativeTo: nil
        )

        let fillLight = PointLight()
        fillLight.light = PointLightComponent(
            cgColor: UIColor(red: 0.22, green: 0.58, blue: 1, alpha: 1).cgColor,
            intensity: fillIntensity,
            attenuationRadius: 9
        )
        fillLight.position = SIMD3<Float>(-2.5, 1.8, -2.0)

        let lanternLight = PointLight()
        lanternLight.light = PointLightComponent(
            cgColor: UIColor(red: 1, green: 0.62, blue: 0.20, alpha: 1).cgColor,
            intensity: lanternIntensity,
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
            mesh: .generateCylinder(height: 0.20, radius: 1.46),
            materials: [darkMetal]
        )
        base.position.y = -1.03
        root.addChild(base)

        let baseRim = ModelEntity(
            mesh: .generateCylinder(height: 0.055, radius: 1.50),
            materials: [bronze]
        )
        baseRim.position.y = -0.91
        root.addChild(baseRim)

        let collar = ModelEntity(
            mesh: .generateCylinder(height: 0.15, radius: 0.40),
            materials: [darkMetal]
        )
        collar.position.y = 2.68
        root.addChild(collar)

        let knob = ModelEntity(mesh: .generateSphere(radius: 0.20), materials: [darkMetal])
        knob.scale.y = 0.72
        knob.position.y = 2.91
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

        for (index, droplet) in droplets.prefix(16).enumerated() {
            let radius = max(0.018, droplet.size * 0.72)
            let entity = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [TerrariumMaterialFactory.droplet(glint: droplet.glint)]
            )
            entity.scale = SIMD3<Float>(0.72, 1.34 + Float(index % 3) * 0.08, 0.26)
            entity.position = SIMD3<Float>(
                droplet.xRatio * 1.10,
                -0.36 + droplet.yRatio * 2.38,
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

        let drainage = ModelEntity(
            mesh: .generateCylinder(height: 0.14, radius: 1.24),
            materials: [TerrariumMaterialFactory.gravel()]
        )
        drainage.position.y = -0.90
        root.addChild(drainage)

        let charcoal = ModelEntity(
            mesh: .generateCylinder(height: 0.075, radius: 1.22),
            materials: [TerrariumMaterialFactory.charcoal()]
        )
        charcoal.position.y = -0.795
        root.addChild(charcoal)

        let soil = ModelEntity(
            mesh: .generateCylinder(height: 0.11, radius: 1.17),
            materials: [TerrariumMaterialFactory.soil(hydrated: hydrated)]
        )
        soil.position.y = -0.675
        root.addChild(soil)

        let sculptedSoil = ModelEntity(
            mesh: OrganicMeshFactory.terrain(),
            materials: [TerrariumMaterialFactory.soil(hydrated: hydrated)]
        )
        sculptedSoil.position.y = -0.61
        root.addChild(sculptedSoil)

        let carpet = ModelEntity(
            mesh: OrganicMeshFactory.terrain(),
            materials: [TerrariumMaterialFactory.moss(tone: hydrated ? 1 : 0, hydrated: hydrated)]
        )
        carpet.scale = SIMD3<Float>(0.975, 1, 0.975)
        carpet.position.y = -0.585
        root.addChild(carpet)

        addStones(layout.stones, hydrated: hydrated, to: root)
        addBranch(rotation: layout.branchRotation, to: root)
        addMoss(layout.mossMounds, hydrated: hydrated, to: root)
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
            let material = TerrariumMaterialFactory.moss(tone: mound.tone, hydrated: hydrated)
            let entity = ModelEntity(
                mesh: OrganicMeshFactory.mossPatch(variant: index),
                materials: [material]
            )
            entity.scale = SIMD3<Float>(mound.radius, mound.height * 0.62, mound.radius * 0.92)
            entity.position = SIMD3<Float>(
                mound.xPosition,
                surfaceY(xPosition: mound.xPosition, zPosition: mound.zPosition) + mound.height * 0.30,
                mound.zPosition
            )
            entity.orientation = simd_quatf(angle: mound.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
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
            entity.position = SIMD3<Float>(
                stone.xPosition,
                surfaceY(xPosition: stone.xPosition, zPosition: stone.zPosition) + stone.height * 0.42,
                stone.zPosition
            )
            entity.orientation = simd_quatf(angle: stone.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
        }
    }

    private static func addBranch(rotation: Float, to root: Entity) {
        let branch = ModelEntity(
            mesh: OrganicMeshFactory.driftwood(),
            materials: [TerrariumMaterialFactory.bark()]
        )
        branch.scale = SIMD3<Float>(1.22, 1.12, 1.12)
        branch.position = SIMD3<Float>(0.08, surfaceY(xPosition: 0.08, zPosition: 0.14) + 0.11, 0.14)
        branch.orientation = simd_quatf(angle: rotation, axis: SIMD3<Float>(0, 1, 0))
        root.addChild(branch)
    }

    private static func addFern(
        _ fronds: [TerrariumLayout.FernFrond],
        hydrated: Bool,
        to root: Entity
    ) {
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

        for (index, frond) in fronds.enumerated() {
            let entity = ModelEntity(
                mesh: OrganicMeshFactory.fernFrond(leafletPairs: frond.leafletPairs, variant: index),
                materials: [TerrariumMaterialFactory.leaf(
                    color: leafColors[frond.tone], hydrated: hydrated
                )]
            )
            let anchorX: Float = -0.10 + Float(index % 2) * 0.025
            let anchorZ: Float = 0.25 + Float(index % 3) * 0.012
            entity.scale = SIMD3<Float>(1.20, frond.height, 1.18 + abs(frond.bend) * 0.35)
            entity.position = SIMD3<Float>(
                anchorX,
                surfaceY(xPosition: anchorX, zPosition: anchorZ),
                anchorZ
            )
            let radialRotation = simd_quatf(angle: frond.angle, axis: SIMD3<Float>(0, 1, 0))
            let fanTilt = simd_quatf(angle: frond.angle * 0.58, axis: SIMD3<Float>(0, 0, 1))
            entity.orientation = radialRotation * fanTilt
            root.addChild(entity)
        }

        if fronds.isEmpty {
            let seed = ModelEntity(
                mesh: .generateSphere(radius: 0.08),
                materials: [SimpleMaterial(color: .brown, roughness: 1, isMetallic: false)]
            )
            seed.position = SIMD3<Float>(-0.10, surfaceY(xPosition: -0.10, zPosition: 0.25), 0.25)
            root.addChild(seed)
        }
    }

    private static func addForestGlows(to root: Entity) {
        let material = UnlitMaterial(color: UIColor(red: 0.80, green: 0.96, blue: 0.42, alpha: 0.72))
        for index in 0..<5 {
            let glow = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [material])
            let angle = Float(index) / 5 * .pi * 2
            glow.position = SIMD3<Float>(cos(angle) * 0.72, 0.02 + Float(index % 3) * 0.16, sin(angle) * 0.44)
            root.addChild(glow)
        }
    }

    private static func surfaceY(xPosition: Float, zPosition: Float) -> Float {
        -0.585 + OrganicMeshFactory.terrainHeight(xPosition: xPosition, zPosition: zPosition)
    }
}
