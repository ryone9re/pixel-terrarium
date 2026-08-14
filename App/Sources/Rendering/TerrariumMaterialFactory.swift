import RealityKit
import UIKit

@MainActor
enum TerrariumMaterialFactory {
    static func soil(hydrated: Bool) -> PhysicallyBasedMaterial {
        material(
            color: UIColor(
                red: hydrated ? 0.075 : 0.15,
                green: hydrated ? 0.045 : 0.07,
                blue: 0.022,
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
        return material(
            color: (hydrated ? wetColors : dryColors)[tone],
            roughness: hydrated ? 0.76 : 0.95,
            specular: hydrated ? 0.22 : 0.08,
            clearcoat: hydrated ? 0.055 : 0.02,
            clearcoatRoughness: hydrated ? 0.46 : 0.80
        )
    }

    static func stone(tone: Int, hydrated: Bool) -> PhysicallyBasedMaterial {
        let colors: [UIColor] = [
            .init(red: 0.30, green: 0.31, blue: 0.26, alpha: 1),
            .init(red: 0.20, green: 0.25, blue: 0.23, alpha: 1),
            .init(red: 0.38, green: 0.35, blue: 0.29, alpha: 1)
        ]
        return material(
            color: colors[tone],
            roughness: hydrated ? 0.36 : 0.76,
            specular: hydrated ? 0.55 : 0.24,
            clearcoat: hydrated ? 0.38 : 0.05,
            clearcoatRoughness: hydrated ? 0.18 : 0.62
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
        material(
            color: color,
            roughness: hydrated ? 0.48 : 0.86,
            specular: hydrated ? 0.34 : 0.10,
            clearcoat: hydrated ? 0.12 : 0,
            clearcoatRoughness: 0.32
        )
    }

    static func glass() -> PhysicallyBasedMaterial {
        var glass = material(
            color: UIColor(red: 0.72, green: 0.94, blue: 0.98, alpha: 1),
            roughness: 0.05,
            specular: 1,
            clearcoat: 1,
            clearcoatRoughness: 0.02
        )
        glass.blending = .transparent(opacity: 0.085)
        glass.faceCulling = .none
        return glass
    }

    static func droplet(glint: Float) -> PhysicallyBasedMaterial {
        var water = material(
            color: UIColor(red: 0.78, green: 0.96, blue: 1, alpha: 1),
            roughness: 0.02,
            specular: 1,
            clearcoat: 1,
            clearcoatRoughness: 0.01,
            emissiveColor: UIColor(red: 0.24, green: 0.70, blue: 1, alpha: 1),
            emissiveIntensity: 0.06 + glint * 0.12
        )
        water.blending = .transparent(opacity: .init(scale: 0.30 + glint * 0.28))
        return water
    }

    static func darkMetal() -> PhysicallyBasedMaterial {
        material(
            color: UIColor(red: 0.055, green: 0.05, blue: 0.032, alpha: 1),
            roughness: 0.22,
            metallic: 0.92,
            specular: 0.78,
            clearcoat: 0.32,
            clearcoatRoughness: 0.16
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
