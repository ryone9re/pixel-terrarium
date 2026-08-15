import RealityKit
import TerrariumCore
import UIKit

@MainActor
enum TerrariumWidgetArtworkRenderer {
    private static let imageSize = CGSize(width: 492, height: 600)

    static func render(
        snapshot: TerrariumWidgetSnapshot,
        period: DayPeriod
    ) async -> Data? {
        guard !Task.isCancelled else { return nil }
        let view = ARView(
            frame: CGRect(origin: .zero, size: imageSize),
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        view.isOpaque = false
        view.backgroundColor = .clear
        view.environment.background = .color(.clear)
        view.contentScaleFactor = 1

        let layout = TerrariumLayoutGenerator.generate(
            seed: snapshot.seed,
            growthPoints: snapshot.growthPoints,
            hydration: snapshot.hydration
        )
        let root = await TerrariumSceneFactory.makeRoot(
            layout: layout,
            hydration: snapshot.hydration
        )
        guard !Task.isCancelled else { return nil }
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(root)
        for light in TerrariumEntityFactory.makeLights(period: period) {
            anchor.addChild(light)
        }
        view.scene.addAnchor(anchor)
        view.layoutIfNeeded()

        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled,
              let image = await captureImage(of: view) else { return nil }
        return image.pngData()
    }

    private static func captureImage(of view: ARView) async -> UIImage? {
        await withCheckedContinuation { continuation in
            view.snapshot(saveToHDR: false) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
