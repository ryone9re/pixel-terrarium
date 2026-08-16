import RealityKit
import UIKit

@MainActor
enum TerrariumMaterialFactory {
    private static var mossAlbedo: TextureResource?

    static func prepareTextures() async {
        guard mossAlbedo == nil else { return }
        mossAlbedo = try? await TextureResource(named: "MossAlbedo", in: .main)
    }

    static func gravel() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.17, green: 0.16, blue: 0.13, alpha: 1),
            roughness: 0.78,
            specular: 0.30
        )
    }

    static func charcoal() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.035, green: 0.040, blue: 0.032, alpha: 1),
            roughness: 0.90,
            specular: 0.08
        )
    }

    static func soil(hydrated: Bool) -> PhysicallyBasedMaterial {
        material(
            color: UIColor(
                red: hydrated ? 0.115 : 0.17,
                green: hydrated ? 0.065 : 0.08,
                blue: hydrated ? 0.028 : 0.024,
                alpha: 1
            ),
            roughness: hydrated ? 0.72 : 0.96,
            specular: hydrated ? 0.28 : 0.08,
            clearcoat: hydrated ? 0.08 : 0
        )
    }

    static func moss(tone: Int, hydrated: Bool) -> PhysicallyBasedMaterial {
        let wetColors: [UIColor] = [
            .init(red: 0.025, green: 0.19, blue: 0.035, alpha: 1),
            .init(red: 0.055, green: 0.34, blue: 0.045, alpha: 1),
            .init(red: 0.18, green: 0.46, blue: 0.055, alpha: 1)
        ]
        let dryColors: [UIColor] = [
            .init(red: 0.16, green: 0.21, blue: 0.055, alpha: 1),
            .init(red: 0.25, green: 0.28, blue: 0.065, alpha: 1),
            .init(red: 0.34, green: 0.32, blue: 0.075, alpha: 1)
        ]
        var result = material(
            color: (hydrated ? wetColors : dryColors)[tone],
            roughness: hydrated ? 0.76 : 0.95,
            specular: hydrated ? 0.22 : 0.08,
            clearcoat: hydrated ? 0.055 : 0.02,
            clearcoatRoughness: hydrated ? 0.46 : 0.80
        )
        if let mossAlbedo {
            let wetTints: [UIColor] = [
                .init(red: 0.92, green: 0.98, blue: 0.86, alpha: 1),
                .init(red: 0.98, green: 1.00, blue: 0.90, alpha: 1),
                .init(red: 1.00, green: 1.00, blue: 0.94, alpha: 1)
            ]
            let dryTints: [UIColor] = [
                .init(red: 0.94, green: 0.90, blue: 0.72, alpha: 1),
                .init(red: 0.98, green: 0.94, blue: 0.76, alpha: 1),
                .init(red: 1.00, green: 0.96, blue: 0.80, alpha: 1)
            ]
            result.baseColor = .init(
                tint: (hydrated ? wetTints : dryTints)[tone],
                texture: .init(mossAlbedo)
            )
            result.emissiveColor = .init(color: UIColor(
                red: hydrated ? 0.08 : 0.05,
                green: hydrated ? 0.24 + CGFloat(tone) * 0.04 : 0.13,
                blue: 0.025,
                alpha: 1
            ))
            result.emissiveIntensity = hydrated ? 0.055 + Float(tone) * 0.020 : 0.022
        }
        return result
    }

    static func stone(tone: Int, hydrated: Bool) -> PhysicallyBasedMaterial {
        let colors: [UIColor] = [
            .init(red: 0.27, green: 0.28, blue: 0.25, alpha: 1),
            .init(red: 0.18, green: 0.22, blue: 0.21, alpha: 1),
            .init(red: 0.34, green: 0.32, blue: 0.28, alpha: 1)
        ]
        return material(
            color: colors[tone],
            roughness: hydrated ? 0.62 : 0.82,
            specular: hydrated ? 0.28 : 0.17,
            clearcoat: hydrated ? 0.10 : 0.025,
            clearcoatRoughness: hydrated ? 0.42 : 0.68
        )
    }

    static func bark() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.23, green: 0.095, blue: 0.025, alpha: 1),
            roughness: 0.84,
            specular: 0.16
        )
    }

    static func stem(hydrated: Bool) -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.12, green: hydrated ? 0.42 : 0.29, blue: 0.045, alpha: 1),
            roughness: hydrated ? 0.55 : 0.88,
            specular: hydrated ? 0.26 : 0.08,
            clearcoat: hydrated ? 0.12 : 0
        )
    }

    static func leaf(color: UIColor, hydrated: Bool) -> PhysicallyBasedMaterial {
        var result = material(
            color: color,
            roughness: hydrated ? 0.48 : 0.86,
            specular: hydrated ? 0.34 : 0.10,
            clearcoat: hydrated ? 0.12 : 0,
            clearcoatRoughness: 0.32
        )
        result.faceCulling = .none
        return result
    }

    static func glass() -> PhysicallyBasedMaterial {
        var glass = material(
            color: UIColor(red: 0.72, green: 0.94, blue: 0.98, alpha: 1),
            roughness: 0.32,
            specular: 0.06,
            clearcoat: 0,
            clearcoatRoughness: 0.50
        )
        glass.blending = .transparent(opacity: 0.018)
        glass.faceCulling = .back
        return glass
    }

    static func droplet(glint: Float) -> PhysicallyBasedMaterial {
        var water = material(
            color: UIColor(red: 0.86, green: 0.97, blue: 1, alpha: 1),
            roughness: 0.015,
            specular: 1,
            clearcoat: 1,
            clearcoatRoughness: 0.008,
            emissiveColor: UIColor(red: 0.44, green: 0.78, blue: 1, alpha: 1),
            emissiveIntensity: 0.01 + glint * 0.035
        )
        water.blending = .transparent(opacity: .init(scale: 0.16 + glint * 0.18))
        return water
    }

    static func darkMetal() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.055, green: 0.05, blue: 0.032, alpha: 1),
            roughness: 0.36,
            metallic: 0.72,
            specular: 0.58,
            clearcoat: 0.20,
            clearcoatRoughness: 0.24
        )
    }

    static func blackenedBaseMetal() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.018, green: 0.024, blue: 0.025, alpha: 1),
            roughness: 0.42,
            metallic: 0.86,
            specular: 0.54,
            clearcoat: 0.12,
            clearcoatRoughness: 0.30
        )
    }

    static func bronze() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.31, green: 0.18, blue: 0.045, alpha: 1),
            roughness: 0.20,
            metallic: 0.84,
            specular: 0.74,
            clearcoat: 0.28,
            clearcoatRoughness: 0.14
        )
    }

    private static func material(
        color: UIColor,
        roughness: Float,
        metallic: Float = 0,
        specular: Float,
        clearcoat: Float = 0,
        clearcoatRoughness: Float = 0.5,
        emissiveColor: UIColor = .black,
        emissiveIntensity: Float = 0
    ) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: metallic)
        material.specular = .init(floatLiteral: specular)
        material.clearcoat = .init(floatLiteral: clearcoat)
        material.clearcoatRoughness = .init(floatLiteral: clearcoatRoughness)
        material.emissiveColor = .init(color: emissiveColor)
        material.emissiveIntensity = emissiveIntensity
        return material
    }
}
