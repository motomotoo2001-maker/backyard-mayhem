class_name HeroFrameManifest
extends RefCounted

const Profile = preload("res://scripts/art/hero_animation_profile.gd")

const ACTIONS: Array[StringName] = [
    &"idle",
    &"run",
    &"fire",
    &"build",
    &"hurt",
    &"dash",
    &"death",
]

static func expected_frame_names() -> PackedStringArray:
    var result := PackedStringArray()
    for action in ACTIONS:
        var count: int = Profile.frame_count(action)
        for direction in Profile.DIRECTIONS:
            for frame_index in range(count):
                result.append(Profile.frame_name(action, direction, frame_index))
    return result

static func validate_names(actual_names: PackedStringArray) -> Dictionary:
    var expected: PackedStringArray = expected_frame_names()
    var expected_set := {}
    var actual_counts := {}

    for file_name in expected:
        expected_set[file_name] = true

    for file_name in actual_names:
        actual_counts[file_name] = int(actual_counts.get(file_name, 0)) + 1

    var missing := PackedStringArray()
    var unexpected := PackedStringArray()
    var duplicates := PackedStringArray()

    for file_name in expected:
        if int(actual_counts.get(file_name, 0)) == 0:
            missing.append(file_name)

    for file_name in actual_counts.keys():
        if not expected_set.has(file_name):
            unexpected.append(String(file_name))
        if int(actual_counts[file_name]) > 1:
            duplicates.append(String(file_name))

    missing.sort()
    unexpected.sort()
    duplicates.sort()

    return {
        "ok": missing.is_empty() and unexpected.is_empty() and duplicates.is_empty(),
        "expected_count": expected.size(),
        "actual_count": actual_names.size(),
        "missing": missing,
        "unexpected": unexpected,
        "duplicates": duplicates,
    }
