import RealityKit
import TerrariumCore

@MainActor
enum TerrariumSceneFactory {
    static func makeRoot(layout: TerrariumLayout, hydration: Int) async -> Entity {
        let root = Entity()
        root.name = "terrarium-root"
        root.position = SIMD3<Float>(0, -0.68, -2.75)

        if let shell = try? await Entity(named: "terrarium_shell", in: .main) {
            shell.findEntity(named: "GlassBowl")?.isEnabled = false
            root.addChild(shell)
        } else {
            root.addChild(TerrariumEntityFactory.makeHardware())
        }
        root.addChild(GlassClocheFactory.makeGlassCloche())
        root.addChild(TerrariumEntityFactory.makeContents(layout: layout, hydration: hydration))
        root.addChild(TerrariumEntityFactory.makeGlassDroplets(
            layout.droplets,
            hydrated: hydration >= 40
        ))
        return root
    }
}
