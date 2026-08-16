import RealityKit

@MainActor
enum FacetedRockMeshFactory {
    private static var stoneCache: [Int: MeshResource] = [:]
    private static var mossCache: [Int: MeshResource] = [:]

    static func stone(variant: Int) -> MeshResource {
        let key = variant % 4
        if let cached = stoneCache[key] {
            return cached
        }
        let geometry = makeGeometry(variant: key)
        var builder = RockMeshBuilder()
        builder.appendRock(geometry: geometry, variant: key)
        let mesh = builder.makeMesh(name: "FacetedStone-\(key)")
        stoneCache[key] = mesh
        return mesh
    }

    static func mossSkin(variant: Int, coverageLevel: Int) -> MeshResource {
        let stoneVariant = variant % 4
        let level = min(3, max(1, coverageLevel))
        let key = stoneVariant * 10 + level
        if let cached = mossCache[key] {
            return cached
        }
        let geometry = makeGeometry(variant: stoneVariant)
        var builder = RockMeshBuilder()
        builder.appendMossSkin(
            geometry: geometry,
            variant: stoneVariant,
            coverageLevel: level
        )
        let mesh = builder.makeMesh(name: "FacetedStoneMoss-\(key)")
        mossCache[key] = mesh
        return mesh
    }

    private static func makeGeometry(variant: Int) -> RockGeometry {
        let segments = 7 + variant % 2
        let ringHeights: [Float] = [-0.62, -0.24, 0.22, 0.58]
        let ringRadii: [Float] = [0.72, 1.00, 0.88, 0.54]
        let rings = ringHeights.indices.map { ringIndex in
            let angleOffset = Float(ringIndex % 2) * 0.16 + Float(variant) * 0.11
            return (0..<segments).map { segment in
                let angle = Float(segment) / Float(segments) * .pi * 2 + angleOffset
                let noise = radialNoise(
                    angle: angle,
                    ring: ringIndex + 2,
                    variant: variant + 31,
                    amount: 0.14
                )
                let heightNoise = sin(angle * 2.7 + Float(variant) * 1.3) * 0.045
                let radius = ringRadii[ringIndex] * noise
                return SIMD3<Float>(
                    cos(angle) * radius + ringHeights[ringIndex] * 0.055,
                    ringHeights[ringIndex] + heightNoise,
                    sin(angle) * radius * (0.86 + Float(variant % 3) * 0.035)
                )
            }
        }
        return RockGeometry(
            segments: segments,
            rings: rings,
            bottom: SIMD3<Float>(-0.08, -0.68, 0.04),
            top: SIMD3<Float>(0.10 - Float(variant) * 0.025, 0.66, -0.06)
        )
    }

    private static func radialNoise(
        angle: Float,
        ring: Int,
        variant: Int,
        amount: Float
    ) -> Float {
        let phase = Float(variant) * 1.713 + Float(ring) * 0.61
        let broad = sin(angle * 3 + phase) * 0.55
        let fine = cos(angle * 7 - phase * 0.73) * 0.30
        let irregular = sin(angle * 11 + Float(ring * variant + 3)) * 0.15
        return 1 + (broad + fine + irregular) * amount
    }
}

private struct RockGeometry {
    let segments: Int
    let rings: [[SIMD3<Float>]]
    let bottom: SIMD3<Float>
    let top: SIMD3<Float>
}

@MainActor
private struct RockMeshBuilder {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []

    mutating func appendRock(geometry: RockGeometry, variant: Int) {
        for segment in 0..<geometry.segments {
            let next = (segment + 1) % geometry.segments
            appendTriangle(geometry.bottom, geometry.rings[0][segment], geometry.rings[0][next])
            appendTriangle(geometry.rings[3][segment], geometry.top, geometry.rings[3][next])
        }
        for ringIndex in 0..<(geometry.rings.count - 1) {
            for segment in 0..<geometry.segments {
                appendRingFace(
                    geometry: geometry,
                    ringIndex: ringIndex,
                    segment: segment,
                    variant: variant
                )
            }
        }
    }

    mutating func appendMossSkin(
        geometry: RockGeometry,
        variant: Int,
        coverageLevel: Int
    ) {
        let lift = 0.026 + Float(coverageLevel) * 0.005
        for segment in 0..<geometry.segments {
            let next = (segment + 1) % geometry.segments
            let topGap = (variant * 2 + geometry.segments - 1) % geometry.segments
            let topVisible = if coverageLevel >= 3 {
                segment != topGap
            } else if coverageLevel == 2 {
                (segment + variant * 2) % geometry.segments < 5
            } else {
                (segment + variant * 2) % geometry.segments < 3
            }
            if topVisible {
                appendTriangle(
                    geometry.rings[3][segment],
                    geometry.top,
                    geometry.rings[3][next],
                    surfaceLift: lift
                )
            }
            let shoulderVisible = coverageLevel >= 3
                ? (segment + variant) % 4 != 0
                : (segment + variant) % 3 == 0
            if coverageLevel >= 2, shoulderVisible {
                appendMossRingFace(
                    geometry: geometry,
                    ringIndex: 2,
                    segment: segment,
                    variant: variant,
                    lift: lift
                )
            }
            if coverageLevel >= 3, (segment + variant) % 3 == 0 {
                appendMossRingFace(
                    geometry: geometry,
                    ringIndex: 1,
                    segment: segment,
                    variant: variant,
                    lift: lift * 0.86
                )
            }
        }
    }

    private mutating func appendRingFace(
        geometry: RockGeometry,
        ringIndex: Int,
        segment: Int,
        variant: Int
    ) {
        appendMossRingFace(
            geometry: geometry,
            ringIndex: ringIndex,
            segment: segment,
            variant: variant,
            lift: 0
        )
    }

    private mutating func appendMossRingFace(
        geometry: RockGeometry,
        ringIndex: Int,
        segment: Int,
        variant: Int,
        lift: Float
    ) {
        let next = (segment + 1) % geometry.segments
        let lower = geometry.rings[ringIndex][segment]
        let lowerNext = geometry.rings[ringIndex][next]
        let upper = geometry.rings[ringIndex + 1][segment]
        let upperNext = geometry.rings[ringIndex + 1][next]
        if (segment + ringIndex + variant).isMultiple(of: 2) {
            appendTriangle(lower, upper, lowerNext, surfaceLift: lift)
            appendTriangle(lowerNext, upper, upperNext, surfaceLift: lift)
        } else {
            appendTriangle(lower, upper, upperNext, surfaceLift: lift)
            appendTriangle(lower, upperNext, lowerNext, surfaceLift: lift)
        }
    }

    private mutating func appendTriangle(
        _ first: SIMD3<Float>,
        _ second: SIMD3<Float>,
        _ third: SIMD3<Float>,
        surfaceLift: Float = 0
    ) {
        let baseIndex = UInt32(positions.count)
        var adjustedSecond = second
        var adjustedThird = third
        var normal = simd_normalize(simd_cross(adjustedSecond - first, adjustedThird - first))
        let centroid = (first + adjustedSecond + adjustedThird) / 3
        if simd_dot(normal, centroid) < 0 {
            swap(&adjustedSecond, &adjustedThird)
            normal = -normal
        }
        let offset = normal * surfaceLift
        positions += [first + offset, adjustedSecond + offset, adjustedThird + offset]
        normals += Array(repeating: normal, count: 3)
        textureCoordinates += [SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 1)]
        indices += [baseIndex, baseIndex + 1, baseIndex + 2]
    }

    func makeMesh(name: String) -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            assertionFailure("石メッシュを生成できませんでした: \(error)")
            return .generateSphere(radius: 0.001)
        }
    }
}
