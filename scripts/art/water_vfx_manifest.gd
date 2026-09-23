class_name WaterVFXManifest
extends RefCounted

const SequenceProfile = preload("res://scripts/art/water_vfx_sequence_profile.gd")
const AssetPolicy = preload("res://scripts/art/water_vfx_asset_policy.gd")

const SEQUENCE_ORDER := [
    &"stream",
    &"projectile",
    &"splash",
    &"impact",
    &"foam",
    &"vortex",
]

static func required_filenames() -> Array[String]:
    var result: Array[String] = []
    for kind_variant in SEQUENCE_ORDER:
        var kind := StringName(kind_variant)
        var count := SequenceProfile.frame_count(kind)
        for frame in range(count):
            result.append("%s_%02d.png" % [String(kind), frame])
    return result

static func required_paths() -> Array[String]:
    var result: Array[String] = []
    for kind_variant in SEQUENCE_ORDER:
        var kind := StringName(kind_variant)
        var count := SequenceProfile.frame_count(kind)
        for frame in range(count):
            var filename := "%s_%02d.png" % [String(kind), frame]
            result.append("%s%s/%s" % [AssetPolicy.RUNTIME_ROOT, String(kind), filename])
    return result
