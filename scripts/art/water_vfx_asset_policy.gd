class_name WaterVFXAssetPolicy
extends RefCounted

const RUNTIME_ROOT := "res://assets/runtime/vfx/water/"
const ALLOWED_KINDS := [
    "stream",
    "splash",
    "impact",
    "projectile",
    "foam",
    "vortex",
]

static func is_valid_runtime_path(path: String) -> bool:
    if not path.begins_with(RUNTIME_ROOT):
        return false
    if path.get_extension().to_lower() != "png":
        return false

    var relative: String = path.trim_prefix(RUNTIME_ROOT)
    var parts: PackedStringArray = relative.split("/", false)
    if parts.size() != 2:
        return false

    var kind: String = String(parts[0])
    var file_name: String = String(parts[1])
    if not ALLOWED_KINDS.has(kind):
        return false

    var expected_prefix := "%s_" % kind
    if not file_name.begins_with(expected_prefix):
        return false

    var stem: String = file_name.get_basename()
    var index_text: String = stem.trim_prefix(expected_prefix)
    if index_text.length() != 2 or not index_text.is_valid_int():
        return false

    return true

static func validate_runtime_paths(paths: PackedStringArray) -> Dictionary:
    var invalid := PackedStringArray()
    for path in paths:
        if not is_valid_runtime_path(path):
            invalid.append(path)
    invalid.sort()

    return {
        "ok": invalid.is_empty(),
        "invalid": invalid,
        "checked_count": paths.size(),
    }
