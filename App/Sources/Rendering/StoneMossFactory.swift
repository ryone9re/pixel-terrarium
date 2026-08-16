import RealityKit
import TerrariumCore

@MainActor
enum StoneMossFactory {
    static func makeEntities(
        stone: TerrariumLayout.Stone,
        position: SIMD3<Float>,
        index: Int,
        growthProgress: Float,
        hydrated: Bool
    ) -> [Entity] {
        let stagger = Float(index) * 0.025
        let coverage = min(1, max(0, (growthProgress - 0.10 - stagger) / 0.78))
        guard coverage > 0 else { return [] }
        let material = TerrariumMaterialFactory.moss(
            tone: (index + 1) % 3,
            hydrated: hydrated
        )
        var entities: [Entity] = [makeTopPatch(
            stone: stone,
            position: position,
            index: index,
            coverage: coverage,
            material: material
        )]
        if coverage > 0.58 {
            entities.append(makeShoulderPatch(
                stone: stone,
                position: position,
                index: index,
                coverage: coverage,
                material: material
            ))
        }
        return entities
    }

    private static func makeTopPatch(
        stone: TerrariumLayout.Stone,
        position: SIMD3<Float>,
        index: Int,
        coverage: Float,
        material: PhysicallyBasedMaterial
    ) -> Entity {
        let patch = ModelEntity(
            mesh: OrganicMeshFactory.mossPatch(variant: index + 31),
            materials: [material]
        )
        patch.scale = SIMD3<Float>(
            stone.radius * (0.18 + coverage * 0.62),
            0.018 + coverage * 0.030,
            stone.radius * (0.16 + coverage * 0.52)
        )
        patch.position = SIMD3<Float>(
            position.x + cos(stone.rotation) * stone.radius * 0.06,
            position.y + stone.height * 0.64,
            position.z + sin(stone.rotation) * stone.radius * 0.06
        )
        patch.orientation = simd_quatf(
            angle: stone.rotation + 0.35,
            axis: SIMD3<Float>(0, 1, 0)
        )
        return patch
    }

    private static func makeShoulderPatch(
        stone: TerrariumLayout.Stone,
        position: SIMD3<Float>,
        index: Int,
        coverage: Float,
        material: PhysicallyBasedMaterial
    ) -> Entity {
        let shoulderProgress = (coverage - 0.58) / 0.42
        let shoulderAngle = stone.rotation + (index.isMultiple(of: 2) ? 1.2 : -1.0)
        let patch = ModelEntity(
            mesh: OrganicMeshFactory.mossPatch(variant: index + 47),
            materials: [material]
        )
        patch.scale = SIMD3<Float>(
            stone.radius * (0.15 + shoulderProgress * 0.30),
            0.016 + shoulderProgress * 0.020,
            stone.radius * (0.12 + shoulderProgress * 0.25)
        )
        patch.position = SIMD3<Float>(
            position.x + cos(shoulderAngle) * stone.radius * 0.48,
            position.y + stone.height * 0.31,
            position.z + sin(shoulderAngle) * stone.radius * 0.48
        )
        patch.orientation = simd_quatf(
            angle: shoulderAngle,
            axis: SIMD3<Float>(0, 1, 0)
        ) * simd_quatf(
            angle: 0.46,
            axis: SIMD3<Float>(1, 0, 0)
        )
        return patch
    }
}
