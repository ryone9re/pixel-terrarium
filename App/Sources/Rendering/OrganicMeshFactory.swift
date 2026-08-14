import RealityKit

@MainActor
enum OrganicMeshFactory {
    private static var mossCache: [Int: MeshResource] = [:]
    private static var stoneCache: [Int: MeshResource] = [:]

    static func moss(variant: Int) -> MeshResource {
        let key = variant % 5
        if let cached = mossCache[key] {
            return cached
        }
        let mesh = organicEllipsoid(name: "Moss-\(key)", rings: 7, segments: 12, variant: key, crag: 0.12)
        mossCache[key] = mesh
        return mesh
    }

    static func stone(variant: Int) -> MeshResource {
        let key = variant % 4
        if let cached = stoneCache[key] {
            return cached
        }
        let mesh = organicEllipsoid(name: "Stone-\(key)", rings: 6, segments: 10, variant: key + 19, crag: 0.075)
        stoneCache[key] = mesh
        return mesh
    }

    private static func organicEllipsoid(
        name: String,
        rings: Int,
        segments: Int,
        variant: Int,
        crag: Float
    ) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for ring in 0...rings {
            let verticalProgress = Float(ring) / Float(rings)
            let latitude = -.pi / 2 + verticalProgress * .pi
            let ringRadius = cos(latitude)
            let yPosition = sin(latitude)

            for segment in 0..<segments {
                let angle = Float(segment) / Float(segments) * .pi * 2
                let wobble = radialNoise(angle: angle, ring: ring, variant: variant, amount: crag)
                let squash = 1 + 0.035 * sin(Float(variant + 1) * angle * 0.7)
                let position = SIMD3<Float>(
                    cos(angle) * ringRadius * wobble,
                    yPosition * (0.96 + 0.04 * wobble),
                    sin(angle) * ringRadius * wobble * squash
                )
                positions.append(position)
                normals.append(simd_normalize(position))
            }
        }

        for ring in 0..<rings {
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let lower = UInt32(ring * segments + segment)
                let lowerNext = UInt32(ring * segments + next)
                let upper = UInt32((ring + 1) * segments + segment)
                let upperNext = UInt32((ring + 1) * segments + next)
                indices += [lower, upper, lowerNext, lowerNext, upper, upperNext]
            }
        }

        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            assertionFailure("有機メッシュを生成できませんでした: \(error)")
            return .generateSphere(radius: 1)
        }
    }

    private static func radialNoise(angle: Float, ring: Int, variant: Int, amount: Float) -> Float {
        let phase = Float(variant) * 1.713 + Float(ring) * 0.61
        let broad = sin(angle * 3 + phase) * 0.55
        let fine = cos(angle * 7 - phase * 0.73) * 0.30
        let irregular = sin(angle * 11 + Float(ring * variant + 3)) * 0.15
        return 1 + (broad + fine + irregular) * amount
    }
}
