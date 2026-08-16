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
                content.camera = .virtual
                content.add(TerrariumSceneFactory.makeCamera())
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
            .id("\(seed)-\(growthPoints)-\(hydration)-\(period.rawValue)")

            if hydration >= 40 {
                WaterGlintsView(
                    droplets: layout.droplets,
                    yaw: displayedYaw,
                    reduceMotion: reduceMotion
                )
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
        root.addChild(makeCompactBase())

        let collar = ModelEntity(
            mesh: .generateCylinder(height: 0.15, radius: 0.40),
            materials: [darkMetal]
        )
        collar.position.y = 2.16
        root.addChild(collar)

        let knob = ModelEntity(mesh: .generateSphere(radius: 0.20), materials: [darkMetal])
        knob.scale.y = 0.72
        knob.position.y = 2.39
        root.addChild(knob)
        return root
    }

    static func makeCompactBase() -> Entity {
        let root = Entity()
        root.name = "CompactBase"
        let blackenedMetal = TerrariumMaterialFactory.blackenedBaseMetal()
        let bronze = TerrariumMaterialFactory.bronze()

        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.14, radius: 1.04),
            materials: [blackenedMetal]
        )
        body.position.y = -1.03
        root.addChild(body)

        let topSupport = ModelEntity(
            mesh: .generateCylinder(height: 0.055, radius: 0.91),
            materials: [blackenedMetal]
        )
        topSupport.position.y = -0.91
        root.addChild(topSupport)

        let upperTrim = ModelEntity(
            mesh: .generateCylinder(height: 0.022, radius: 0.96),
            materials: [bronze]
        )
        upperTrim.position.y = -0.885
        root.addChild(upperTrim)

        let lowerTrim = ModelEntity(
            mesh: .generateCylinder(height: 0.024, radius: 1.06),
            materials: [bronze]
        )
        lowerTrim.position.y = -1.135
        root.addChild(lowerTrim)
        return root
    }

    static func makeGlassDroplets(
        _ droplets: [TerrariumLayout.Droplet],
        hydrated: Bool
    ) -> Entity {
        let root = Entity()
        root.name = "GlassDroplets"
        guard hydrated else { return root }

        for (index, droplet) in droplets.enumerated() {
            let radius = max(0.016, droplet.size * 0.68)
            let entity = ModelEntity(
                mesh: GlassClocheFactory.condensationDropletMesh(variant: index),
                materials: [TerrariumMaterialFactory.droplet(glint: droplet.glint)]
            )
            entity.name = "CondensationDroplet-\(index)"
            GlassClocheFactory.configureAsCondensation(entity)
            entity.scale = SIMD3<Float>(
                radius * (0.70 + Float(index % 3) * 0.04),
                radius * (1.18 + Float(index % 4) * 0.10),
                radius * 0.20
            )
            let yPosition = -0.45 + droplet.yRatio * 2.42
            let glassRadius = GlassClocheFactory.glassRadius(at: yPosition)
            let xPosition = cos(droplet.azimuth) * glassRadius
            let zPosition = sin(droplet.azimuth) * glassRadius
            let surfacePosition = SIMD3<Float>(xPosition, yPosition, zPosition)
            let outwardNormal = GlassClocheFactory.outwardNormal(
                at: yPosition,
                xPosition: xPosition,
                zPosition: zPosition
            )
            let surfaceInset = entity.scale.z + 0.010
            entity.position = surfacePosition - outwardNormal * surfaceInset
            let yaw = atan2(outwardNormal.x, outwardNormal.z)
            let pitch = -asin(max(-1, min(1, outwardNormal.y)))
            entity.orientation = simd_quatf(
                angle: yaw,
                axis: SIMD3<Float>(0, 1, 0)
            ) * simd_quatf(
                angle: pitch,
                axis: SIMD3<Float>(1, 0, 0)
            )
            root.addChild(entity)
        }
        return root
    }

}

extension TerrariumEntityFactory {
    private static let terrainBaseY: Float = -0.27
    private static let groundSurfaceY: Float = -0.245

    static func makeContents(layout: TerrariumLayout, hydration: Int) -> Entity {
        let root = Entity()
        let hydrated = hydration >= 40

        let drainage = ModelEntity(
            mesh: .generateCylinder(height: 0.12, radius: 0.72),
            materials: [TerrariumMaterialFactory.gravel()]
        )
        drainage.position.y = -0.89
        root.addChild(drainage)

        let charcoal = ModelEntity(
            mesh: .generateCylinder(height: 0.15, radius: 0.78),
            materials: [TerrariumMaterialFactory.charcoal()]
        )
        charcoal.position.y = -0.755
        root.addChild(charcoal)

        let soil = ModelEntity(
            mesh: GlassClocheFactory.substrateMesh(),
            materials: [TerrariumMaterialFactory.soil(hydrated: hydrated)]
        )
        root.addChild(soil)

        let sculptedSoil = ModelEntity(
            mesh: OrganicMeshFactory.terrain(),
            materials: [TerrariumMaterialFactory.soil(hydrated: hydrated)]
        )
        sculptedSoil.scale = SIMD3<Float>(1.34, 1, 1.48)
        sculptedSoil.position.y = terrainBaseY
        root.addChild(sculptedSoil)

        addMossyEarthRim(
            growthProgress: layout.growthProgress,
            hydrated: hydrated,
            to: root
        )
        addStones(
            layout.stones,
            growthProgress: layout.growthProgress,
            hydrated: hydrated,
            to: root
        )
        addBranch(rotation: layout.branchRotation, to: root)
        addMoss(
            layout.mossMounds,
            growthProgress: layout.growthProgress,
            hydrated: hydrated,
            to: root
        )
        addFern(layout.fernFronds, hydrated: hydrated, to: root)
        if layout.growthProgress >= 1 {
            addForestGlows(to: root)
        }
        return root
    }

    private static func addMossyEarthRim(
        growthProgress: Float,
        hydrated: Bool,
        to root: Entity
    ) {
        let moss = (0..<3).map {
            TerrariumMaterialFactory.moss(tone: $0, hydrated: hydrated)
        }
        let clodCount = Int((growthProgress * 24).rounded(.down))
        guard clodCount > 0 else { return }
        let horizontalScale = 0.10 + growthProgress * 0.10
        let verticalScale = 0.055 + growthProgress * 0.195
        for index in 0..<clodCount {
            let angle = Float(index) / Float(clodCount) * .pi * 2
            let radiusVariation = 0.96 + Float(index % 4) * 0.022
            let widthVariation = 0.94 + Float(index % 3) * 0.06
            let clod = ModelEntity(
                mesh: OrganicMeshFactory.mossPatch(variant: index),
                materials: [moss[index % moss.count]]
            )
            clod.scale = SIMD3<Float>(
                horizontalScale * widthVariation,
                verticalScale,
                horizontalScale * 0.85 * widthVariation
            )
            clod.position = SIMD3<Float>(
                cos(angle) * 1.12 * radiusVariation,
                -0.35 + sin(Float(index) * 1.7) * 0.022,
                sin(angle) * 1.12 * radiusVariation
            )
            clod.orientation = simd_quatf(
                angle: angle - .pi / 2,
                axis: SIMD3<Float>(0, 1, 0)
            )
            root.addChild(clod)
        }
    }

    private static func addMoss(
        _ mounds: [TerrariumLayout.MossMound],
        growthProgress: Float,
        hydrated: Bool,
        to root: Entity
    ) {
        let materials = (0..<3).map {
            TerrariumMaterialFactory.moss(tone: $0, hydrated: hydrated)
        }
        for (index, mound) in mounds.enumerated() {
            let entity = ModelEntity(
                mesh: OrganicMeshFactory.mossPatch(variant: index),
                materials: [materials[mound.tone]]
            )
            let horizontalGrowth = 0.92 + growthProgress * 0.38
            let verticalScale = max(0.026, mound.height * 0.42)
            entity.scale = SIMD3<Float>(
                mound.radius * horizontalGrowth,
                verticalScale,
                mound.radius * horizontalGrowth * 0.94
            )
            entity.position = SIMD3<Float>(
                mound.xPosition,
                surfaceY(xPosition: mound.xPosition, zPosition: mound.zPosition)
                    + verticalScale * 0.68,
                mound.zPosition
            )
            entity.orientation = simd_quatf(angle: mound.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
        }
    }

    private static func addStones(
        _ stones: [TerrariumLayout.Stone],
        growthProgress: Float,
        hydrated: Bool,
        to root: Entity
    ) {
        for (index, stone) in stones.enumerated() {
            let material = TerrariumMaterialFactory.stone(tone: stone.tone, hydrated: hydrated)
            let entity = ModelEntity(mesh: OrganicMeshFactory.stone(variant: index), materials: [material])
            entity.scale = SIMD3<Float>(stone.radius, stone.height, stone.radius * 0.82)
            let stonePosition = SIMD3<Float>(
                stone.xPosition,
                surfaceY(xPosition: stone.xPosition, zPosition: stone.zPosition) + stone.height * 0.42,
                stone.zPosition
            )
            entity.position = stonePosition
            entity.orientation = simd_quatf(angle: stone.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
            for moss in StoneMossFactory.makeEntities(
                stone: stone,
                position: stonePosition,
                index: index,
                growthProgress: growthProgress,
                hydrated: hydrated
            ) {
                root.addChild(moss)
            }
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
            let anchorX = frond.xPosition
            let anchorZ = frond.zPosition
            entity.scale = SIMD3<Float>(1.13, frond.height, 1.14 + abs(frond.bend) * 0.52)
            entity.position = SIMD3<Float>(
                anchorX,
                surfaceY(xPosition: anchorX, zPosition: anchorZ),
                anchorZ
            )
            let radialRotation = simd_quatf(angle: frond.rotation, axis: SIMD3<Float>(0, 1, 0))
            let fanTilt = simd_quatf(
                angle: frond.angle * 0.70 + frond.bend * 0.58,
                axis: SIMD3<Float>(0, 0, 1)
            )
            entity.orientation = radialRotation * fanTilt
            root.addChild(entity)
            fitFernInsideGlass(entity, relativeTo: root)
        }

        if fronds.isEmpty {
            let seed = ModelEntity(
                mesh: .generateSphere(radius: 0.08),
                materials: [SimpleMaterial(color: .brown, roughness: 1, isMetallic: false)]
            )
            seed.position = SIMD3<Float>(-0.10, surfaceY(xPosition: -0.10, zPosition: 0.12), 0.12)
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
        groundSurfaceY + OrganicMeshFactory.terrainHeight(
            xPosition: xPosition,
            zPosition: zPosition
        )
    }

    private static func fitFernInsideGlass(_ entity: Entity, relativeTo root: Entity) {
        let glassClearance: Float = 0.12
        for _ in 0..<3 {
            let bounds = entity.visualBounds(relativeTo: root)
            let radialExtent = [
                SIMD2<Float>(bounds.min.x, bounds.min.z),
                SIMD2<Float>(bounds.min.x, bounds.max.z),
                SIMD2<Float>(bounds.max.x, bounds.min.z),
                SIMD2<Float>(bounds.max.x, bounds.max.z)
            ].map(simd_length).max() ?? 0
            let availableRadius = [bounds.min.y, bounds.center.y, bounds.max.y]
                .map { GlassClocheFactory.glassRadius(at: $0) - glassClearance }
                .min() ?? radialExtent
            guard radialExtent > availableRadius, radialExtent > 0 else { return }
            let shrink = max(0.72, availableRadius / radialExtent * 0.97)
            entity.scale *= shrink
        }
    }
}
