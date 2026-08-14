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
                let root = Entity()
                root.name = "terrarium-root"
                root.position = SIMD3<Float>(0, -0.68, -2.75)

                if let shell = try? await Entity(named: "terrarium_shell", in: .main) {
                    shell.findEntity(named: "GlassBowl")?.isEnabled = false
                    root.addChild(shell)
                } else {
                    root.addChild(TerrariumEntityFactory.makeHardware())
                }
                root.addChild(TerrariumEntityFactory.makeGlassCloche())
                root.addChild(TerrariumEntityFactory.makeContents(
                    layout: layout,
                    hydration: hydration
                ))
                content.add(root)
                for light in TerrariumEntityFactory.makeLights(period: period) {
                    content.add(light)
                }
            } update: { content in
                guard let root = content.entities.first(where: { $0.name == "terrarium-root" }) else {
                    return
                }
                root.orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            }
            .id("\(seed)-\(growthPoints)")

            if hydration >= 40 && (period == .evening || period == .night) {
                WaterGlintsView(droplets: layout.droplets, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    yaw = Float(max(-0.35, min(0.35, value.translation.width / 280)))
                }
                .onEnded { _ in
                    withAnimation(.spring(duration: 0.8, bounce: 0.15)) {
                        yaw = 0
                    }
                }
        )
    }
}

@MainActor
private enum TerrariumEntityFactory {
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
        return [keyLight, fillLight]
    }

    static func makeHardware() -> Entity {
        let root = Entity()
        let darkMetal = SimpleMaterial(
            color: UIColor(red: 0.07, green: 0.065, blue: 0.045, alpha: 1),
            roughness: 0.34,
            isMetallic: true
        )
        let bronze = SimpleMaterial(
            color: UIColor(red: 0.24, green: 0.16, blue: 0.055, alpha: 1),
            roughness: 0.28,
            isMetallic: true
        )

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

    static func makeGlassCloche() -> Entity {
        let root = Entity()
        root.name = "RealityKitGlassBowl"
        var glass = UnlitMaterial(color: UIColor(red: 0.66, green: 0.91, blue: 0.94, alpha: 1))
        glass.blending = .transparent(opacity: 0.075)

        let cloche = ModelEntity(
            mesh: makeClocheMesh(radius: 1.34, wallBottom: -0.90, wallTop: 1.84, domeHeight: 0.78),
            materials: [glass]
        )
        root.addChild(cloche)
        return root
    }

    private static func makeClocheMesh(
        radius: Float,
        wallBottom: Float,
        wallTop: Float,
        domeHeight: Float
    ) -> MeshResource {
        let segments = 48
        let domeRings = 12
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        appendRing(radius: radius, yPosition: wallBottom, segments: segments, to: &positions)
        appendRing(radius: radius, yPosition: wallTop, segments: segments, to: &positions)
        for ring in 1...domeRings {
            let latitude = .pi / 2 * (1 - Float(ring) / Float(domeRings))
            appendRing(
                radius: sin(latitude) * radius,
                yPosition: wallTop + cos(latitude) * domeHeight,
                segments: segments,
                to: &positions
            )
        }
        for ring in 0..<(domeRings + 1) {
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let lower = UInt32(ring * segments + segment)
                let lowerNext = UInt32(ring * segments + next)
                let upper = UInt32((ring + 1) * segments + segment)
                let upperNext = UInt32((ring + 1) * segments + next)
                indices += [lower, upper, lowerNext, lowerNext, upper, upperNext]
            }
        }
        return makeMesh(name: "GlassCloche", positions: positions, indices: indices)
    }

    private static func appendRing(
        radius: Float,
        yPosition: Float,
        segments: Int,
        to positions: inout [SIMD3<Float>]
    ) {
        for segment in 0..<segments {
            let angle = Float(segment) / Float(segments) * .pi * 2
            positions.append(SIMD3<Float>(cos(angle) * radius, yPosition, sin(angle) * radius))
        }
    }

    private static func makeMesh(
        name: String,
        positions: [SIMD3<Float>],
        indices: [UInt32]
    ) -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions)
        descriptor.primitives = .triangles(indices)
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            assertionFailure("ガラスメッシュを生成できませんでした: \(error)")
            return .generateSphere(radius: 0.001)
        }
    }
}

private extension TerrariumEntityFactory {
    static func makeContents(layout: TerrariumLayout, hydration: Int) -> Entity {
        let root = Entity()
        let hydrated = hydration >= 40
        let soilMaterial = SimpleMaterial(
            color: UIColor(red: hydrated ? 0.12 : 0.20, green: 0.075, blue: 0.035, alpha: 1),
            roughness: 0.92,
            isMetallic: false
        )
        let soil = ModelEntity(
            mesh: .generateCylinder(height: 0.46, radius: 1.24),
            materials: [soilMaterial]
        )
        soil.position.y = -0.91
        root.addChild(soil)

        let carpet = ModelEntity(
            mesh: .generateCylinder(height: 0.045, radius: 1.18),
            materials: [SimpleMaterial(
                color: UIColor(red: 0.07, green: hydrated ? 0.25 : 0.20, blue: 0.045, alpha: 1),
                roughness: 0.98,
                isMetallic: false
            )]
        )
        carpet.position.y = -0.66
        root.addChild(carpet)

        addMoss(layout.mossMounds, hydrated: hydrated, to: root)
        addStones(layout.stones, to: root)
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
        let colors: [UIColor] = hydrated
            ? [
                .init(red: 0.045, green: 0.27, blue: 0.055, alpha: 1),
                .init(red: 0.09, green: 0.42, blue: 0.075, alpha: 1),
                .init(red: 0.24, green: 0.55, blue: 0.09, alpha: 1)
            ]
            : [
                .init(red: 0.18, green: 0.24, blue: 0.07, alpha: 1),
                .init(red: 0.28, green: 0.31, blue: 0.08, alpha: 1),
                .init(red: 0.38, green: 0.36, blue: 0.10, alpha: 1)
            ]

        for (index, mound) in mounds.enumerated() {
            let material = SimpleMaterial(color: colors[mound.tone], roughness: 0.96, isMetallic: false)
            let entity = ModelEntity(mesh: .generateSphere(radius: mound.radius), materials: [material])
            entity.scale = SIMD3<Float>(1, mound.height / mound.radius, 0.88)
            entity.position = SIMD3<Float>(mound.xPosition, -0.68 + mound.height * 0.46, mound.zPosition)
            entity.orientation = simd_quatf(angle: mound.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)

            addMossTexture(mound: mound, material: material, index: index, to: root)
        }
    }

    private static func addMossTexture(
        mound: TerrariumLayout.MossMound,
        material: SimpleMaterial,
        index: Int,
        to root: Entity
    ) {
        for tuftIndex in 0..<2 {
            let angle = mound.rotation + Float(tuftIndex) * 2.1 + Float(index % 3) * 0.35
            let tuft = ModelEntity(
                mesh: .generateBox(
                    size: SIMD3<Float>(mound.radius * 0.30, 0.045, mound.radius * 0.25),
                    cornerRadius: 0.008
                ),
                materials: [material]
            )
            tuft.position = SIMD3<Float>(
                mound.xPosition + cos(angle) * mound.radius * 0.35,
                -0.67 + mound.height * (0.82 + Float(tuftIndex) * 0.08),
                mound.zPosition + sin(angle) * mound.radius * 0.30
            )
            tuft.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(tuft)
        }
    }

    private static func addStones(_ stones: [TerrariumLayout.Stone], to root: Entity) {
        let colors = [
            UIColor(red: 0.35, green: 0.35, blue: 0.29, alpha: 1),
            UIColor(red: 0.25, green: 0.29, blue: 0.27, alpha: 1),
            UIColor(red: 0.42, green: 0.39, blue: 0.31, alpha: 1)
        ]
        for stone in stones {
            let material = SimpleMaterial(color: colors[stone.tone], roughness: 0.72, isMetallic: false)
            let entity = ModelEntity(mesh: .generateSphere(radius: stone.radius), materials: [material])
            entity.scale = SIMD3<Float>(1, stone.height / stone.radius, 0.82)
            entity.position = SIMD3<Float>(stone.xPosition, -0.62 + stone.height * 0.45, stone.zPosition)
            entity.orientation = simd_quatf(angle: stone.rotation, axis: SIMD3<Float>(0, 1, 0))
            root.addChild(entity)
        }
    }

    private static func addBranch(rotation: Float, to root: Entity) {
        let bark = SimpleMaterial(
            color: UIColor(red: 0.29, green: 0.14, blue: 0.045, alpha: 1),
            roughness: 0.9,
            isMetallic: false
        )
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
        let stem = SimpleMaterial(
            color: UIColor(red: 0.17, green: hydrated ? 0.48 : 0.34, blue: 0.08, alpha: 1),
            roughness: 0.9,
            isMetallic: false
        )
        let leafColors = hydrated
            ? [
                UIColor(red: 0.18, green: 0.54, blue: 0.08, alpha: 1),
                UIColor(red: 0.31, green: 0.67, blue: 0.10, alpha: 1),
                UIColor(red: 0.12, green: 0.42, blue: 0.06, alpha: 1)
            ]
            : [
                UIColor(red: 0.39, green: 0.40, blue: 0.10, alpha: 1),
                UIColor(red: 0.46, green: 0.43, blue: 0.11, alpha: 1),
                UIColor(red: 0.31, green: 0.34, blue: 0.08, alpha: 1)
            ]

        for frond in fronds {
            addFrond(frond, stem: stem, leafColor: leafColors[frond.tone], to: root)
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
        stem: SimpleMaterial,
        leafColor: UIColor,
        to root: Entity
    ) {
        let segmentCount = max(3, frond.leafletPairs)
        let direction = SIMD2<Float>(cos(frond.angle), sin(frond.angle))
        let leafMaterial = SimpleMaterial(color: leafColor, roughness: 0.9, isMetallic: false)
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
        material: SimpleMaterial,
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
        material: SimpleMaterial,
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

private struct WaterGlintsView: View {
    let droplets: [TerrariumLayout.Droplet]
    let reduceMotion: Bool
    @State private var shimmering = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(droplets.prefix(14).enumerated()), id: \.offset) { index, droplet in
                Image(systemName: index.isMultiple(of: 4) ? "sparkle" : "drop.fill")
                    .font(.system(size: 5 + CGFloat(droplet.size) * 130, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70 + Double(droplet.glint) * 0.24))
                    .shadow(color: .cyan.opacity(0.72), radius: 4)
                    .position(
                        x: geometry.size.width * CGFloat(0.5 + droplet.xRatio * 0.31),
                        y: geometry.size.height * CGFloat(0.14 + droplet.yRatio * 0.69)
                    )
                    .opacity(reduceMotion ? 0.65 : (shimmering == index.isMultiple(of: 2) ? 1 : 0.32))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 1.1 + Double(index % 5) * 0.17)
                                .repeatForever(autoreverses: true),
                        value: shimmering
                    )
            }
        }
        .onAppear { shimmering = true }
        .accessibilityHidden(true)
    }
}
