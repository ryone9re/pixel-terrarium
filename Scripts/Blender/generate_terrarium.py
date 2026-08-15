#!/usr/bin/env python3
"""共通ベルジャー外装のUSDZと確認用PNGを決定的に生成する。"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


PREVIEW_SIZE = 1024


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--blend-file", type=Path, required=True)
    return parser.parse_args(argv)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for data_collection in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for block in list(data_collection):
            if block.users == 0:
                data_collection.remove(block)


def material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    metallic: float = 0,
    roughness: float = 0.5,
    glass: bool = False,
) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    result.diffuse_color = color
    result.use_nodes = True
    principled = result.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Alpha"].default_value = color[3]
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if glass:
        principled.inputs["Transmission Weight"].default_value = 0.22
        principled.inputs["IOR"].default_value = 1.45
        result.surface_render_method = "DITHERED"
    return result


def add_cylinder(
    name: str,
    radius: float,
    depth: float,
    z_position: float,
    object_material: bpy.types.Material,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=48,
        radius=radius,
        depth=depth,
        location=(0, 0, z_position),
    )
    result = bpy.context.object
    result.name = name
    result.data.materials.append(object_material)
    bevel = result.modifiers.new("SoftEdge", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 2
    return result


def add_shell() -> None:
    dark_metal = material("DarkMetal", (0.045, 0.042, 0.030, 1), metallic=0.72, roughness=0.30)
    bronze = material("BronzeEdge", (0.17, 0.105, 0.028, 1), metallic=0.78, roughness=0.30)
    glass_material = material(
        "Glass",
        (0.60, 0.86, 0.91, 0.075),
        roughness=0.06,
        glass=True,
    )

    add_cylinder("Base", 1.46, 0.20, -1.03, dark_metal)
    add_cylinder("BaseLowerRim", 1.50, 0.045, -1.145, bronze)
    add_cylinder("BaseUpperRim", 1.50, 0.05, -0.91, bronze)

    for index in range(24):
        angle = index / 24 * 6.283185307
        bpy.ops.mesh.primitive_cube_add(
            location=(1.455 * __import__("math").cos(angle), 1.455 * __import__("math").sin(angle), -1.03),
            rotation=(0, 0, angle),
            scale=(0.024, 0.038, 0.064),
        )
        rib = bpy.context.object
        rib.name = f"BaseRib_{index:02d}"
        rib.data.materials.append(bronze if index % 4 == 0 else dark_metal)

    glass_root = bpy.data.objects.new("GlassBowl", None)
    bpy.context.collection.objects.link(glass_root)
    wall = add_cylinder("GlassWall", 1.34, 2.72, 0.52, glass_material)
    wall.parent = glass_root
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=48,
        ring_count=24,
        radius=1.34,
        location=(0, 0, 1.83),
    )
    dome = bpy.context.object
    dome.name = "GlassDome"
    dome.scale = (1, 1, 0.58)
    dome.data.materials.append(glass_material)
    dome.parent = glass_root

    add_cylinder("TopCollarLower", 0.40, 0.15, 2.68, dark_metal)
    add_cylinder("TopCollarEdge", 0.45, 0.055, 2.77, bronze)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.20, location=(0, 0, 2.94))
    knob = bpy.context.object
    knob.name = "TopKnob"
    knob.scale = (1, 1, 0.72)
    knob.data.materials.append(dark_metal)


def point_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def add_camera_and_lights() -> None:
    bpy.ops.object.camera_add(location=(4.8, -8.0, 4.1))
    camera = bpy.context.object
    camera.name = "RenderCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 6.1
    point_at(camera, (0, 0, 0.62))
    bpy.context.scene.camera = camera

    lights = (
        ((4.5, -3.2, 6.2), 1150, 4.0, (1.0, 0.72, 0.28)),
        ((-4.0, -2.0, 3.8), 900, 3.2, (0.18, 0.52, 1.0)),
        ((0.0, 4.2, 2.0), 480, 2.4, (0.20, 0.72, 0.62)),
    )
    for index, (location, energy, size, color) in enumerate(lights):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = f"Light_{index}"
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        point_at(light, (0, 0, 0.5))


def configure_render() -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = PREVIEW_SIZE
    scene.render.resolution_y = PREVIEW_SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.world.color = (0.02, 0.045, 0.065)
    scene.view_settings.look = "AgX - Medium High Contrast"


def export_usdz(path: Path) -> None:
    bpy.ops.wm.usd_export(
        filepath=str(path),
        export_animation=False,
        export_cameras=False,
        export_lights=False,
        export_materials=True,
        generate_preview_surface=True,
        selected_objects_only=False,
        triangulate_meshes=True,
        convert_scene_units="METERS",
        relative_paths=True,
    )


def triangle_count() -> int:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    total = 0
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    return total


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    args = parse_args()
    output_dir = args.output_dir.resolve()
    blend_file = args.blend_file.resolve()
    usdz_dir = output_dir / "USDZ"
    preview_dir = output_dir / "Preview"
    usdz_dir.mkdir(parents=True, exist_ok=True)
    preview_dir.mkdir(parents=True, exist_ok=True)
    for stale_path in usdz_dir.glob("terrarium_stage_*.usdz"):
        stale_path.unlink()
    for stale_path in (output_dir / "Widget").glob("terrarium_stage_*.png"):
        stale_path.unlink()
    blend_file.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    add_shell()
    add_camera_and_lights()
    configure_render()
    count = triangle_count()
    if count > 25_000:
        raise RuntimeError(f"shell exceeds triangle budget: {count}")

    usdz_path = usdz_dir / "terrarium_shell.usdz"
    preview_path = preview_dir / "terrarium_shell.png"
    export_usdz(usdz_path)
    bpy.context.scene.render.filepath = str(preview_path)
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_file))

    manifest = {
        "schemaVersion": 2,
        "generator": f"Blender {bpy.app.version_string}",
        "architecture": "shared-shell-plus-seeded-procedural-ecosystem",
        "assets": [
            {
                "file": str(usdz_path.relative_to(output_dir)),
                "kind": "shell-usdz",
                "triangleCount": count,
                "bytes": usdz_path.stat().st_size,
                "sha256": sha256(usdz_path),
            },
            {
                "file": str(preview_path.relative_to(output_dir)),
                "kind": "preview-png",
                "width": PREVIEW_SIZE,
                "height": PREVIEW_SIZE,
                "bytes": preview_path.stat().st_size,
                "sha256": sha256(preview_path),
            },
        ],
    }
    manifest_path = output_dir.parent / "asset-manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated shared shell ({count} triangles) and preview in {output_dir}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Asset generation failed: {error}", file=sys.stderr)
        raise
