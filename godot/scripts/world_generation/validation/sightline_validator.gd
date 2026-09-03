class_name SightlineValidator
extends RefCounted

const HEIGHT_CLEARANCE := 0.25
const CLEAR_MAX := 0.10
const PARTIAL_MAX := 0.60


func validate(definition: Resource, poi_index: Dictionary, height_provider: Callable, occluders: Array) -> Dictionary:
	if not poi_index.has(definition.source_poi_id) or not poi_index.has(definition.target_poi_id):
		return {"sightline_id": definition.sightline_id, "classification": "BLOCKED", "occluded_samples": definition.sample_count, "sample_count": definition.sample_count, "occlusion_ratio": 1.0, "requirement_met": false, "error": "MISSING_POI"}
	var source: Resource = poi_index[definition.source_poi_id]
	var target: Resource = poi_index[definition.target_poi_id]
	var start: Vector3 = source.position + Vector3.UP * source.sightline_height
	var finish: Vector3 = target.position + Vector3.UP * target.sightline_height
	var occluded := 0
	for sample_index in range(1, definition.sample_count + 1):
		var factor := float(sample_index) / float(definition.sample_count + 1)
		var point := start.lerp(finish, factor)
		var occluder_height: float = height_provider.call(point)
		for occluder in occluders:
			var occluder_position: Vector3 = occluder.get("position", Vector3.ZERO)
			var radius: float = occluder.get("radius", 0.0) + definition.clearance_width * 0.5
			if Vector2(point.x - occluder_position.x, point.z - occluder_position.z).length() <= radius:
				occluder_height = maxf(occluder_height, float(occluder.get("height", 0.0)))
		if occluder_height >= point.y + HEIGHT_CLEARANCE:
			occluded += 1
	var ratio := float(occluded) / float(maxi(definition.sample_count, 1))
	var classification := "CLEAR" if ratio <= CLEAR_MAX else ("PARTIAL" if ratio <= PARTIAL_MAX else "BLOCKED")
	var requirement_met: bool = _meets_requirement(classification, definition.required_visibility) and ratio <= definition.max_allowed_occlusion
	return {
		"classification": classification, "occluded_samples": occluded,
		"occlusion_ratio": ratio, "requirement_met": requirement_met,
		"sample_count": definition.sample_count, "sightline_id": definition.sightline_id,
	}


func _meets_requirement(actual: String, required: String) -> bool:
	var rank := {"CLEAR": 0, "PARTIAL": 1, "BLOCKED": 2}
	return int(rank.get(actual, 2)) <= int(rank.get(required, 0))
