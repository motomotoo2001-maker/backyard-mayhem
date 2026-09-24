class_name HeroRunMotionValidator
extends RefCounted

const SAMPLE_GRID := 24
const DISTINCT_DELTA_THRESHOLD := 0.018
const MIN_DISTINCT_POSES := 4
const MIN_MEAN_POSE_DELTA := 0.01

static func _normalized_alpha_signature(image: Image) -> PackedFloat32Array:
    var signature := PackedFloat32Array()
    if image == null or image.is_empty():
        return signature

    var used := image.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return signature

    signature.resize(SAMPLE_GRID * SAMPLE_GRID)
    var write_index := 0
    for gy in range(SAMPLE_GRID):
        var sample_y := used.position.y + int(floor((float(gy) + 0.5) * float(used.size.y) / float(SAMPLE_GRID)))
        sample_y = clampi(sample_y, used.position.y, used.end.y - 1)
        for gx in range(SAMPLE_GRID):
            var sample_x := used.position.x + int(floor((float(gx) + 0.5) * float(used.size.x) / float(SAMPLE_GRID)))
            sample_x = clampi(sample_x, used.position.x, used.end.x - 1)
            signature[write_index] = image.get_pixel(sample_x, sample_y).a
            write_index += 1
    return signature

static func _signature_delta(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
    if a.size() == 0 or a.size() != b.size():
        return 1.0
    var total := 0.0
    for index in range(a.size()):
        total += absf(a[index] - b[index])
    return total / float(a.size())

static func validate_sequence(frames: Array[Image]) -> Dictionary:
    var errors: Array[String] = []
    if frames.size() < MIN_DISTINCT_POSES:
        errors.append("insufficient_frame_count")
        return {
            "ok": false,
            "errors": errors,
            "distinct_pose_count": 0,
            "mean_pose_delta": 0.0,
        }

    var signatures: Array[PackedFloat32Array] = []
    for frame in frames:
        var signature := _normalized_alpha_signature(frame)
        if signature.is_empty():
            errors.append("empty_run_frame")
            return {
                "ok": false,
                "errors": errors,
                "distinct_pose_count": 0,
                "mean_pose_delta": 0.0,
            }
        signatures.append(signature)

    var representatives: Array[PackedFloat32Array] = []
    for signature in signatures:
        var is_distinct := true
        for representative in representatives:
            if _signature_delta(signature, representative) < DISTINCT_DELTA_THRESHOLD:
                is_distinct = false
                break
        if is_distinct:
            representatives.append(signature)

    var transition_total := 0.0
    var transition_count := 0
    for index in range(1, signatures.size()):
        transition_total += _signature_delta(signatures[index - 1], signatures[index])
        transition_count += 1
    # Include loop closure because RUN is a looping animation.
    transition_total += _signature_delta(signatures[signatures.size() - 1], signatures[0])
    transition_count += 1
    var mean_pose_delta := transition_total / float(maxi(1, transition_count))

    if representatives.size() < MIN_DISTINCT_POSES:
        errors.append("insufficient_pose_diversity")
    if mean_pose_delta <= MIN_MEAN_POSE_DELTA:
        if not errors.has("insufficient_pose_diversity"):
            errors.append("insufficient_pose_diversity")

    return {
        "ok": errors.is_empty(),
        "errors": errors,
        "distinct_pose_count": representatives.size(),
        "mean_pose_delta": mean_pose_delta,
    }
