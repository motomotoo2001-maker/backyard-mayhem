class_name HeroAssetPolicy
extends RefCounted

const Manifest = preload("res://scripts/art/hero_frame_manifest.gd")
const RUNTIME_ROOT := "res://assets/runtime/characters/builder_hero/"

static func is_valid_runtime_frame_path(path: String) -> bool:
    if not path.begins_with(RUNTIME_ROOT):
        return false
    if path.get_extension().to_lower() != "png":
        return false

    var relative := path.trim_prefix(RUNTIME_ROOT)
    if relative.is_empty() or relative.contains("/") or relative.contains("\\"):
        return false

    return Manifest.expected_frame_names().has(relative)

static func validate_runtime_paths(paths: PackedStringArray) -> Dictionary:
    var invalid := PackedStringArray()
    for path in paths:
        if not is_valid_runtime_frame_path(path):
            invalid.append(path)
    invalid.sort()

    return {
        "ok": invalid.is_empty(),
        "invalid": invalid,
        "checked_count": paths.size(),
    }
