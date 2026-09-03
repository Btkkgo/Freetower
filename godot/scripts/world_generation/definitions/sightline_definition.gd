class_name SightlineDefinition
extends Resource

@export var sightline_id := ""
@export var source_poi_id := ""
@export var target_poi_id := ""
@export_enum("CLEAR", "PARTIAL", "BLOCKED") var required_visibility := "CLEAR"
@export_range(0.0, 1.0) var max_allowed_occlusion := 0.1
@export var clearance_width := 2.0
@export var sample_count := 32
@export var debug_visible := true


func to_canonical_data() -> Dictionary:
	return {
		"clearance_width": clearance_width, "max_allowed_occlusion": max_allowed_occlusion,
		"required_visibility": required_visibility, "sample_count": sample_count,
		"sightline_id": sightline_id, "source_poi_id": source_poi_id,
		"target_poi_id": target_poi_id,
	}
