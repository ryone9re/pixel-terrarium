import RealityKit
import TerrariumCore

@MainActor
enum TerrariumSceneFactory {
    static func makeRoot(layout: TerrariumLayout, hydration: Int) async -> Entity {
        await TerrariumMaterialFactory.prepareTextures()
        let root = Entity()
        root.name = "terrarium-root"
        root.position = SIMD3<Float>(0, -0.60, -2.62)

        if let shell = try? await Entity(named: "terrarium_shell", in: .main) {
            shell.findEntity(named: "GlassBowl")?.isEnabled = false
            let legacyBaseNames = ["Base", "BaseLowerRim", "BaseUpperRim"]
                + (0..<24).map { $0 < 10 ? "BaseRib_0\($0)" : "BaseRib_\($0)" }
            for name in legacyBaseNames {
                shell.findEntity(named: name)?.isEnabled = false
            }
            for name in ["TopCollarLower", "TopCollarEdge", "TopKnob"] {
                guard let topHardware = shell.findEntity(named: name) else { continue }
                var position = topHardware.position
                position.z -= 0.52
                topHardware.position = position
            }
            root.addChild(shell)
            root.addChild(TerrariumEntityFactory.makeCompactBase())
        } else {
            root.addChild(TerrariumEntityFactory.makeHardware())
        }
        root.addChild(GlassClocheFactory.makeGlassCloche(hydrated: hydration >= 40))
        root.addChild(TerrariumEntityFactory.makeContents(layout: layout, hydration: hydration))
        root.addChild(TerrariumEntityFactory.makeGlassDroplets(
            layout.droplets,
            hydrated: hydration >= 40
        ))
        return root
    }
}
