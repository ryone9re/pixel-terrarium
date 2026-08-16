import RealityKit

@MainActor
enum GlassClocheFactory {
    private struct ProfileRing {
        let yPosition: Float
        let radius: Float
    }

    private struct VertexBuffers {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
    }

    private static let orbProfile = makeOrbProfile()
    private static var dropletMeshCache: [Int: MeshResource] = [:]

    static func makeGlassCloche(hydrated: Bool) -> Entity {
        let root = Entity()
        root.name = "RealityKitGlassBowl"
        let glass = TerrariumMaterialFactory.glass()

        let cloche = ModelEntity(
            mesh: makeOrbMesh(),
            materials: [glass]
        )
        root.addChild(cloche)

        return root
    }

    static func glassRadius(at yPosition: Float) -> Float {
        guard let first = orbProfile.first, let last = orbProfile.last else { return 1 }
        if yPosition <= first.yPosition { return first.radius }
        if yPosition >= last.yPosition { return last.radius }
        for index in 0..<(orbProfile.count - 1) {
            let lower = orbProfile[index]
            let upper = orbProfile[index + 1]
            guard yPosition <= upper.yPosition else { continue }
            let progress = (yPosition - lower.yPosition) / (upper.yPosition - lower.yPosition)
            return lower.radius + (upper.radius - lower.radius) * progress
        }
        return last.radius
    }

    static func outwardNormal(
        at yPosition: Float,
        xPosition: Float,
        zPosition: Float
    ) -> SIMD3<Float> {
        let sampleDistance: Float = 0.01
        let lowerRadius = glassRadius(at: yPosition - sampleDistance)
        let upperRadius = glassRadius(at: yPosition + sampleDistance)
        let radiusSlope = (upperRadius - lowerRadius) / (sampleDistance * 2)
        let radialLength = max(0.001, sqrt(xPosition * xPosition + zPosition * zPosition))
        return simd_normalize(SIMD3<Float>(
            xPosition / radialLength,
            -radiusSlope,
            zPosition / radialLength
        ))
    }

    // swiftlint:disable:next function_body_length
    static func condensationDropletMesh(variant: Int) -> MeshResource {
        let key = variant % 4
        if let cached = dropletMeshCache[key] {
            return cached
        }

        let rings = 12
        let segments = 20
        let phase = Float(key) * 0.83
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for ring in 0...rings {
            let progress = Float(ring) / Float(rings)
            let latitude = -.pi / 2 + progress * .pi
            let verticalPosition = sin(latitude)
            let roundedRadius = max(0, cos(latitude))
            let upperTaper = 1 - max(0, verticalPosition) * 0.18
            let lowerBulge = 1 + max(0, -verticalPosition) * 0.07

            for segment in 0..<segments {
                let angle = Float(segment) / Float(segments) * .pi * 2
                let irregularity = 1 + sin(angle * 3 + phase) * 0.018
                    + cos(angle * 5 - phase) * 0.012
                let radial = roundedRadius * upperTaper * lowerBulge * irregularity
                let position = SIMD3<Float>(
                    cos(angle) * radial,
                    verticalPosition,
                    sin(angle) * radial
                )
                positions.append(position)
                normals.append(simd_normalize(SIMD3<Float>(
                    position.x,
                    verticalPosition * 0.92,
                    position.z
                )))
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

        let mesh = makeMesh(
            name: "CondensationDroplet-\(key)",
            positions: positions,
            normals: normals,
            indices: indices
        )
        dropletMeshCache[key] = mesh
        return mesh
    }

    private static func makeOrbMesh() -> MeshResource {
        let segments = 64
        var buffers = VertexBuffers()
        var indices: [UInt32] = []
        for index in orbProfile.indices {
            let previous = orbProfile[max(0, index - 1)]
            let next = orbProfile[min(orbProfile.count - 1, index + 1)]
            let radiusChange = next.radius - previous.radius
            let heightChange = max(0.001, next.yPosition - previous.yPosition)
            appendRing(
                radius: orbProfile[index].radius,
                yPosition: orbProfile[index].yPosition,
                segments: segments,
                normal: simd_normalize(SIMD2<Float>(1, -radiusChange / heightChange)),
                buffers: &buffers
            )
        }
        for ring in 0..<(orbProfile.count - 1) {
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
            name: "GlassOrb",
            positions: buffers.positions,
            normals: buffers.normals,
            indices: indices
        )
    }

    private static func makeOrbProfile() -> [ProfileRing] {
        let sphereCenterY: Float = 0.29
        let sphereRadius: Float = 1.51
        let bodyBottom: Float = -0.91
        let bodyTop: Float = 1.62
        let bodyRingCount = 36
        var profile = (0...bodyRingCount).map { index in
            let progress = Float(index) / Float(bodyRingCount)
            let yPosition = bodyBottom + (bodyTop - bodyBottom) * progress
            let distanceFromCenter = yPosition - sphereCenterY
            let radius = sqrt(max(
                0.01,
                sphereRadius * sphereRadius - distanceFromCenter * distanceFromCenter
            ))
            return ProfileRing(yPosition: yPosition, radius: radius)
        }

        let shoulderStartRadius = profile.last?.radius ?? 0.72
        let shoulderTop: Float = 1.92
        let neckRadius: Float = 0.39
        let shoulderRingCount = 10
        for index in 1...shoulderRingCount {
            let progress = Float(index) / Float(shoulderRingCount)
            let smoothProgress = progress * progress * (3 - 2 * progress)
            profile.append(ProfileRing(
                yPosition: bodyTop + (shoulderTop - bodyTop) * progress,
                radius: shoulderStartRadius + (neckRadius - shoulderStartRadius) * smoothProgress
            ))
        }

        let neckTop: Float = 2.10
        let neckRingCount = 4
        for index in 1...neckRingCount {
            let progress = Float(index) / Float(neckRingCount)
            profile.append(ProfileRing(
                yPosition: shoulderTop + (neckTop - shoulderTop) * progress,
                radius: neckRadius
            ))
        }
        return profile
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
