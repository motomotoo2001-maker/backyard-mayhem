class_name EnemyAssetPolicy
extends RefCounted

const RUNTIME_ROOT := "res://assets/runtime/enemies/"
const ALLOWED_FAMILIES := [
    "raccoon",
    "cat",
    "bulldog",
    "pigeon",
    "neighbor_kid",
    "skateboard_teen",
    "boss",
]

const FORBIDDEN_TOKENS := [
    "sheet",
    "concept",
    "reference",
    "user_pack",
    "preview",
    "contact",
]

static func is_valid_runtime_frame_path(path: String) -> bool:
    if not path.begins_with(RUNTIME_ROOT):
        return false
    if path.get_extension().to_lower() != "png":
        return false

    var lowered := path.to_lower()
    for token in FORBIDDEN_TOKENS:
        if lowered.contains(token):
            return false

    var relative: String = path.trim_prefix(RUNTIME_ROOT)
    var parts: PackedStringArray = relative.split("/", false)
    if parts.size() != 3:
        return false

    var family: String = String(parts[0])
    var action: String = String(parts[1])
    var file_name: String = String(parts[2])
    if not ALLOWED_FAMILIES.has(family):
        return false
    if action.is_empty():
        return false

    var expected_prefix := "%s_" % action
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
        if not is_valid_runtime_frame_path(path):
            invalid.append(path)
    invalid.sort()

    return {
        "ok": invalid.is_empty(),
        "invalid": invalid,
        "checked_count": paths.size(),
    }
