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
        let coverageLevel = if coverage < 0.34 {
            1
        } else if coverage < 0.67 {
            2
        } else {
            3
        }
        let skin = ModelEntity(
            mesh: FacetedRockMeshFactory.mossSkin(
                variant: index,
                coverageLevel: coverageLevel
            ),
            materials: [material]
        )
        skin.scale = SIMD3<Float>(stone.radius, stone.height, stone.radius * 0.82)
        skin.position = position
        skin.orientation = simd_quatf(angle: stone.rotation, axis: SIMD3<Float>(0, 1, 0))
        return [skin]
    }
}
