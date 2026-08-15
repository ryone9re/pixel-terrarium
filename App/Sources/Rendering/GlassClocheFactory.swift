import RealityKit

@MainActor
enum GlassClocheFactory {
    private struct VertexBuffers {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
    }

    static func makeGlassCloche(hydrated: Bool) -> Entity {
        let root = Entity()
        root.name = "RealityKitGlassBowl"
        let glass = TerrariumMaterialFactory.glass()

        let cloche = ModelEntity(
            mesh: makeClocheMesh(radius: 1.34, wallBottom: -0.90, wallTop: 1.84, domeHeight: 0.78),
            materials: [glass]
        )
        root.addChild(cloche)

        let longReflection = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.026, 1.52, 0.018), cornerRadius: 0.009),
            materials: [TerrariumMaterialFactory.glassHighlight()]
        )
        longReflection.position = SIMD3<Float>(-0.93, 0.40, 0.91)
        longReflection.orientation = simd_quatf(angle: -0.07, axis: SIMD3<Float>(0, 0, 1))
        root.addChild(longReflection)

        let shortReflection = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.018, 0.58, 0.014), cornerRadius: 0.007),
            materials: [TerrariumMaterialFactory.glassHighlight()]
        )
        shortReflection.position = SIMD3<Float>(0.98, 0.92, 0.82)
        shortReflection.orientation = simd_quatf(angle: 0.05, axis: SIMD3<Float>(0, 0, 1))
        root.addChild(shortReflection)

        if hydrated {
            addCondensation(to: root)
        }
        return root
    }

    private static func addCondensation(to root: Entity) {
        let material = TerrariumMaterialFactory.condensationFog()
        let patches: [(SIMD3<Float>, SIMD3<Float>)] = [
            (SIMD3<Float>(-0.53, 1.25, 1.14), SIMD3<Float>(0.34, 0.52, 0.010)),
            (SIMD3<Float>(0.66, 1.48, 1.08), SIMD3<Float>(0.25, 0.34, 0.009)),
            (SIMD3<Float>(0.93, 0.18, 0.84), SIMD3<Float>(0.16, 0.42, 0.008))
        ]
        for patch in patches {
            let fog = ModelEntity(
                mesh: .generateSphere(radius: 1),
                materials: [material]
            )
            fog.position = patch.0
            fog.scale = patch.1
            root.addChild(fog)
        }
    }

    private static func makeClocheMesh(
        radius: Float,
        wallBottom: Float,
        wallTop: Float,
        domeHeight: Float
    ) -> MeshResource {
        let segments = 48
        let domeRings = 12
        var buffers = VertexBuffers()
        var indices: [UInt32] = []
        appendRing(
            radius: radius,
            yPosition: wallBottom,
            segments: segments,
            normal: SIMD2<Float>(1, 0),
            buffers: &buffers
        )
        appendRing(
            radius: radius,
            yPosition: wallTop,
            segments: segments,
            normal: SIMD2<Float>(1, 0),
            buffers: &buffers
        )
        for ring in 1...domeRings {
            let latitude = .pi / 2 * (1 - Float(ring) / Float(domeRings))
            appendRing(
                radius: sin(latitude) * radius,
                yPosition: wallTop + cos(latitude) * domeHeight,
                segments: segments,
                normal: SIMD2<Float>(sin(latitude), cos(latitude)),
                buffers: &buffers
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
        return makeMesh(
            name: "GlassCloche",
            positions: buffers.positions,
            normals: buffers.normals,
            indices: indices
        )
    }

    private static func appendRing(
        radius: Float,
        yPosition: Float,
        segments: Int,
        normal: SIMD2<Float>,
        buffers: inout VertexBuffers
    ) {
        for segment in 0..<segments {
            let angle = Float(segment) / Float(segments) * .pi * 2
            buffers.positions.append(SIMD3<Float>(cos(angle) * radius, yPosition, sin(angle) * radius))
            buffers.normals.append(simd_normalize(SIMD3<Float>(
                cos(angle) * normal.x,
                normal.y,
                sin(angle) * normal.x
            )))
        }
    }

    private static func makeMesh(
        name: String,
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        indices: [UInt32]
    ) -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            assertionFailure("ガラスメッシュを生成できませんでした: \(error)")
            return .generateSphere(radius: 0.001)
        }
    }
}
