import RealityKit

@MainActor
enum OrganicMeshFactory {
    private static var mossPatchCache: [Int: MeshResource] = [:]
    private static var stoneCache: [Int: MeshResource] = [:]
    private static var fernCache: [Int: MeshResource] = [:]
    private static var terrainCache: MeshResource?
    private static var driftwoodCache: MeshResource?

    static func mossPatch(variant: Int) -> MeshResource {
        let key = variant % 5
        if let cached = mossPatchCache[key] {
            return cached
        }

        var builder = MeshBuilder()
        let phase = Float(key) * 0.73
        let lobes: [(SIMD3<Float>, SIMD3<Float>)] = [
            (.zero, SIMD3<Float>(1.0, 0.82, 0.92)),
            (SIMD3<Float>(-0.48, 0.08, 0.08), SIMD3<Float>(0.63, 0.58, 0.58)),
            (SIMD3<Float>(0.43, 0.11, -0.10), SIMD3<Float>(0.58, 0.62, 0.54)),
            (SIMD3<Float>(-0.06, 0.13, 0.43), SIMD3<Float>(0.60, 0.55, 0.52)),
            (SIMD3<Float>(0.12, 0.16, -0.39), SIMD3<Float>(0.54, 0.52, 0.50))
        ]
        for (index, lobe) in lobes.enumerated() {
            let offset = SIMD3<Float>(
                lobe.0.x + sin(phase + Float(index)) * 0.035,
                lobe.0.y,
                lobe.0.z + cos(phase + Float(index) * 1.7) * 0.035
            )
            builder.appendEllipsoid(
                center: offset,
                scale: lobe.1,
                detail: OrganicDetail(rings: 5, segments: 9, variant: key * 7 + index, crag: 0.16)
            )
        }
        let mesh = builder.makeMesh(name: "MossPatch-\(key)")
        mossPatchCache[key] = mesh
        return mesh
    }

    static func stone(variant: Int) -> MeshResource {
        let key = variant % 4
        if let cached = stoneCache[key] {
            return cached
        }
        var builder = MeshBuilder()
        builder.appendFacetedRock(variant: key)
        let mesh = builder.makeMesh(name: "Stone-\(key)")
        stoneCache[key] = mesh
        return mesh
    }

    // swiftlint:disable:next function_body_length
    static func terrain() -> MeshResource {
        if let terrainCache {
            return terrainCache
        }

        let rings = 9
        let segments = 36
        let radius: Float = 1.03
        var builder = MeshBuilder()
        builder.positions.append(SIMD3<Float>(
            0,
            terrainHeight(xPosition: 0, zPosition: 0),
            0
        ))
        builder.normals.append(SIMD3<Float>(-0.12, 0.98, 0.08))
        builder.textureCoordinates.append(SIMD2<Float>(0.5, 0.5))

        for ring in 1...rings {
            let radialProgress = Float(ring) / Float(rings)
            for segment in 0..<segments {
                let angle = Float(segment) / Float(segments) * .pi * 2
                let horizontalPosition = cos(angle) * radius * radialProgress
                let depthPosition = sin(angle) * radius * radialProgress * 0.88
                builder.positions.append(SIMD3<Float>(
                    horizontalPosition,
                    terrainHeight(xPosition: horizontalPosition, zPosition: depthPosition),
                    depthPosition
                ))
                builder.normals.append(simd_normalize(SIMD3<Float>(
                    horizontalPosition * 0.28 - 0.12,
                    1,
                    depthPosition * 0.34 + 0.08
                )))
                builder.textureCoordinates.append(SIMD2<Float>(
                    0.5 + horizontalPosition / (radius * 2),
                    0.5 + depthPosition / (radius * 1.76)
                ))
            }
        }

        for segment in 0..<segments {
            let next = (segment + 1) % segments
            builder.indices += [0, UInt32(1 + segment), UInt32(1 + next)]
        }
        if rings > 1 {
            for ring in 1..<rings {
                let lowerStart = 1 + (ring - 1) * segments
                let upperStart = 1 + ring * segments
                for segment in 0..<segments {
                    let next = (segment + 1) % segments
                    let lower = UInt32(lowerStart + segment)
                    let lowerNext = UInt32(lowerStart + next)
                    let upper = UInt32(upperStart + segment)
                    let upperNext = UInt32(upperStart + next)
                    builder.indices += [lower, upper, lowerNext, lowerNext, upper, upperNext]
                }
            }
        }

        let mesh = builder.makeMesh(name: "SlopedForestFloor")
        terrainCache = mesh
        return mesh
    }

    static func driftwood() -> MeshResource {
        if let driftwoodCache {
            return driftwoodCache
        }
        var builder = MeshBuilder()
        let trunk: [SIMD3<Float>] = (0...9).map { index in
            let progress = Float(index) / 9
            return SIMD3<Float>(
                -0.72 + progress * 1.44,
                sin(progress * .pi) * 0.075 + sin(progress * .pi * 3) * 0.018,
                -0.10 + progress * 0.18 + sin(progress * .pi * 2) * 0.055
            )
        }
        builder.appendTube(
            points: trunk,
            radii: (0...9).map { 0.085 - Float($0) * 0.0045 },
            segments: 8
        )
        builder.appendTube(
            points: [
                SIMD3<Float>(-0.08, 0.05, -0.01),
                SIMD3<Float>(0.02, 0.18, 0.02),
                SIMD3<Float>(0.16, 0.27, 0.07)
            ],
            radii: [0.048, 0.035, 0.018],
            segments: 7
        )
        let mesh = builder.makeMesh(name: "TaperedDriftwood")
        driftwoodCache = mesh
        return mesh
    }

    static func fernFrond(leafletPairs: Int, variant: Int) -> MeshResource {
        let pairs = max(5, min(15, leafletPairs))
        let key = pairs * 10 + variant % 3
        if let cached = fernCache[key] {
            return cached
        }

        var builder = MeshBuilder()
        let direction: Float = variant.isMultiple(of: 2) ? 1 : -1
        let bend = 0.34 + Float(variant % 3) * 0.085
        let sway = Float(variant % 3 - 1) * 0.045
        let stemSegments = 12
        let pointAt: (Float) -> SIMD3<Float> = { progress in
            SIMD3<Float>(
                sway * sin(progress * .pi),
                progress,
                direction * bend * progress * progress
            )
        }
        let points: [SIMD3<Float>] = (0...stemSegments).map { index in
            let progress = Float(index) / Float(stemSegments)
            return pointAt(progress)
        }
        builder.appendTube(
            points: points,
            radii: (0...stemSegments).map { index in
                let progress = Float(index) / Float(stemSegments)
                return 0.0105 - progress * 0.0075
            },
            segments: 5
        )

        appendFernLeaflets(to: &builder, pairs: pairs, pointAt: pointAt)
        builder.appendLeaflet(
            at: pointAt(0.91),
            sign: 0,
            length: 0.12,
            width: 0.014,
            lift: 1
        )

        let mesh = builder.makeMesh(name: "FernFrond-\(key)")
        fernCache[key] = mesh
        return mesh
    }

    private static func appendFernLeaflets(
        to builder: inout MeshBuilder,
        pairs: Int,
        pointAt: (Float) -> SIMD3<Float>
    ) {
        for level in 1...pairs {
            let progress = Float(level) / Float(pairs + 1)
            let stagger: Float = level.isMultiple(of: 2) ? 0.007 : -0.007
            let leftProgress = min(0.93, max(0.07, progress + stagger))
            let rightProgress = min(0.93, max(0.07, progress - stagger))
            let leftLength = fernLeafletLength(at: leftProgress)
            let rightLength = fernLeafletLength(at: rightProgress)
            let leftLift = 0.012 + (1 - leftProgress) * 0.012
            let rightLift = 0.012 + (1 - rightProgress) * 0.012

            builder.appendLeaflet(
                at: pointAt(leftProgress),
                sign: -1,
                length: leftLength,
                width: leftLength * 0.095,
                lift: leftLift
            )
            builder.appendLeaflet(
                at: pointAt(rightProgress),
                sign: 1,
                length: rightLength,
                width: rightLength * 0.095,
                lift: rightLift
            )
        }
    }

    private static func fernLeafletLength(at progress: Float) -> Float {
        let foliageProgress = min(1, max(0, (progress - 0.07) / 0.86))
        let featherProfile = pow(max(0, sin(foliageProgress * .pi)), 0.68)
        return 0.045 + featherProfile * (1 - foliageProgress * 0.22) * 0.22
    }

    static func terrainHeight(xPosition: Float, zPosition: Float) -> Float {
        let radial = min(1, sqrt(
            (xPosition / 1.03) * (xPosition / 1.03) +
                (zPosition / 0.91) * (zPosition / 0.91)
        ))
        let centralMound = 0.25 * pow(max(0, 1 - radial), 0.72)
        let leftRise = 0.13 * exp(-pow(xPosition + 0.42, 2) * 3.4 - pow(zPosition - 0.24, 2) * 4.2)
        let backRise = 0.08 * exp(-pow(xPosition - 0.34, 2) * 4.0 - pow(zPosition - 0.40, 2) * 5.0)
        return centralMound + leftRise + backRise
    }
}

private struct OrganicDetail {
    let rings: Int
    let segments: Int
    let variant: Int
    let crag: Float
}

@MainActor
private struct MeshBuilder {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []

    mutating func appendEllipsoid(
        center: SIMD3<Float>,
        scale: SIMD3<Float>,
        detail: OrganicDetail
    ) {
        let baseIndex = UInt32(positions.count)
        for ring in 0...detail.rings {
            let verticalProgress = Float(ring) / Float(detail.rings)
            let latitude = -.pi / 2 + verticalProgress * .pi
            let ringRadius = cos(latitude)
            let yPosition = sin(latitude)

            for segment in 0..<detail.segments {
                let horizontalProgress = Float(segment) / Float(detail.segments)
                let angle = horizontalProgress * .pi * 2
                let wobble = radialNoise(
                    angle: angle,
                    ring: ring,
                    variant: detail.variant,
                    amount: detail.crag
                )
                let unit = SIMD3<Float>(
                    cos(angle) * ringRadius * wobble,
                    yPosition * (0.96 + 0.04 * wobble),
                    sin(angle) * ringRadius * wobble
                )
                positions.append(center + unit * scale)
                normals.append(simd_normalize(SIMD3<Float>(
                    unit.x / max(0.001, scale.x),
                    unit.y / max(0.001, scale.y),
                    unit.z / max(0.001, scale.z)
                )))
                textureCoordinates.append(SIMD2<Float>(horizontalProgress, 1 - verticalProgress))
            }
        }

        for ring in 0..<detail.rings {
            for segment in 0..<detail.segments {
                let next = (segment + 1) % detail.segments
                let lower = baseIndex + UInt32(ring * detail.segments + segment)
                let lowerNext = baseIndex + UInt32(ring * detail.segments + next)
                let upper = baseIndex + UInt32((ring + 1) * detail.segments + segment)
                let upperNext = baseIndex + UInt32((ring + 1) * detail.segments + next)
                indices += [lower, upper, lowerNext, lowerNext, upper, upperNext]
            }
        }
    }

    mutating func appendFacetedRock(variant: Int) {
        let segments = 7 + variant % 2
        let ringHeights: [Float] = [-0.62, -0.24, 0.22, 0.58]
        let ringRadii: [Float] = [0.72, 1.00, 0.88, 0.54]
        var rings: [[SIMD3<Float>]] = []

        for ringIndex in ringHeights.indices {
            let angleOffset = Float(ringIndex % 2) * 0.16 + Float(variant) * 0.11
            let ring = (0..<segments).map { segment -> SIMD3<Float> in
                let angle = Float(segment) / Float(segments) * .pi * 2 + angleOffset
                let radiusNoise = radialNoise(
                    angle: angle,
                    ring: ringIndex + 2,
                    variant: variant + 31,
                    amount: 0.14
                )
                let heightNoise = sin(angle * 2.7 + Float(variant) * 1.3) * 0.045
                let radius = ringRadii[ringIndex] * radiusNoise
                return SIMD3<Float>(
                    cos(angle) * radius + ringHeights[ringIndex] * 0.055,
                    ringHeights[ringIndex] + heightNoise,
                    sin(angle) * radius * (0.86 + Float(variant % 3) * 0.035)
                )
            }
            rings.append(ring)
        }

        let bottom = SIMD3<Float>(-0.08, -0.68, 0.04)
        let top = SIMD3<Float>(0.10 - Float(variant) * 0.025, 0.66, -0.06)
        for segment in 0..<segments {
            let next = (segment + 1) % segments
            appendFacetedTriangle(bottom, rings[0][segment], rings[0][next])
            appendFacetedTriangle(rings[3][segment], top, rings[3][next])
        }

        for ringIndex in 0..<(rings.count - 1) {
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let lower = rings[ringIndex][segment]
                let lowerNext = rings[ringIndex][next]
                let upper = rings[ringIndex + 1][segment]
                let upperNext = rings[ringIndex + 1][next]
                if (segment + ringIndex + variant).isMultiple(of: 2) {
                    appendFacetedTriangle(lower, upper, lowerNext)
                    appendFacetedTriangle(lowerNext, upper, upperNext)
                } else {
                    appendFacetedTriangle(lower, upper, upperNext)
                    appendFacetedTriangle(lower, upperNext, lowerNext)
                }
            }
        }
    }

    private mutating func appendFacetedTriangle(
        _ first: SIMD3<Float>,
        _ second: SIMD3<Float>,
        _ third: SIMD3<Float>
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

        positions += [first, adjustedSecond, adjustedThird]
        normals += Array(repeating: normal, count: 3)
        textureCoordinates += [SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 1)]
        indices += [baseIndex, baseIndex + 1, baseIndex + 2]
    }

    mutating func appendTube(points: [SIMD3<Float>], radii: [Float], segments: Int) {
        guard points.count >= 2, points.count == radii.count else { return }
        let baseIndex = UInt32(positions.count)
        for pointIndex in points.indices {
            let previous = points[max(0, pointIndex - 1)]
            let next = points[min(points.count - 1, pointIndex + 1)]
            let tangent = simd_normalize(next - previous)
            let reference = abs(simd_dot(tangent, SIMD3<Float>(0, 0, 1))) > 0.92
                ? SIMD3<Float>(1, 0, 0)
                : SIMD3<Float>(0, 0, 1)
            let side = simd_normalize(simd_cross(tangent, reference))
            let binormal = simd_normalize(simd_cross(tangent, side))

            for segment in 0..<segments {
                let progress = Float(segment) / Float(segments)
                let angle = progress * .pi * 2
                let radial = side * cos(angle) + binormal * sin(angle)
                positions.append(points[pointIndex] + radial * radii[pointIndex])
                normals.append(radial)
                textureCoordinates.append(SIMD2<Float>(progress, Float(pointIndex) / Float(points.count - 1)))
            }
        }

        for pointIndex in 0..<(points.count - 1) {
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let lower = baseIndex + UInt32(pointIndex * segments + segment)
                let lowerNext = baseIndex + UInt32(pointIndex * segments + next)
                let upper = baseIndex + UInt32((pointIndex + 1) * segments + segment)
                let upperNext = baseIndex + UInt32((pointIndex + 1) * segments + next)
                indices += [lower, upper, lowerNext, lowerNext, upper, upperNext]
            }
        }
    }

    mutating func appendLeaflet(
        at center: SIMD3<Float>,
        sign: Float,
        length: Float,
        width: Float,
        lift: Float
    ) {
        let baseIndex = UInt32(positions.count)
        let direction = simd_normalize(SIMD3<Float>(sign, lift, 0.11))
        let perpendicular = simd_normalize(SIMD3<Float>(-direction.y, direction.x, 0))
        let base = center + SIMD3<Float>(sign * 0.008, 0, 0)
        let tip = base + direction * length
        let shoulder = base + direction * length * 0.26
        let middle = base + direction * length * 0.54
        let vertices = [
            base,
            shoulder + perpendicular * width * 0.58,
            middle + perpendicular * width,
            tip,
            middle - perpendicular * width,
            shoulder - perpendicular * width * 0.58
        ]
        positions += vertices
        normals += Array(repeating: SIMD3<Float>(0, 0, -1), count: 6)
        textureCoordinates += [
            SIMD2<Float>(0.5, 1), SIMD2<Float>(0.18, 0.72), SIMD2<Float>(0, 0.46),
            SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0.46), SIMD2<Float>(0.82, 0.72)
        ]
        indices += [
            baseIndex, baseIndex + 1, baseIndex + 2,
            baseIndex, baseIndex + 2, baseIndex + 3,
            baseIndex, baseIndex + 3, baseIndex + 4,
            baseIndex, baseIndex + 4, baseIndex + 5
        ]
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
            assertionFailure("有機メッシュを生成できませんでした: \(error)")
            return .generateSphere(radius: 0.001)
        }
    }

    private func radialNoise(angle: Float, ring: Int, variant: Int, amount: Float) -> Float {
        let phase = Float(variant) * 1.713 + Float(ring) * 0.61
        let broad = sin(angle * 3 + phase) * 0.55
        let fine = cos(angle * 7 - phase * 0.73) * 0.30
        let irregular = sin(angle * 11 + Float(ring * variant + 3)) * 0.15
        return 1 + (broad + fine + irregular) * amount
    }
}
