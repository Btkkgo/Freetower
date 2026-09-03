class_name MapDefinition
extends Resource

@export var map_id := ""
@export var display_name := ""
@export var seed := 0
@export var generation_revision := "foundation-v1"
@export var world_size := Vector2(100.0, 100.0)
@export var terrain_height_min := -4.0
@export var terrain_height_max := 18.0
@export var terrain_resolution := 101
@export var spawn_position := Vector3.ZERO
@export var naturalization_amplitude := 0.35
@export var naturalization_frequency := 0.045
@export var biomes: Array = []
@export var spline_features: Array = []
@export var points_of_interest: Array = []
@export var exclusion_zones: Array = []
@export var terrain_control_regions: Array = []
@export var sightlines: Array = []
@export var review_viewpoints: Array[Dictionary] = []
@export var landmark_targets := PackedStringArray()


func to_canonical_data() -> Dictionary:
	return {
		"biomes": _resource_data(biomes, "biome_id"),
		"exclusion_zones": _resource_data(exclusion_zones, "zone_id"),
		"generation_revision": generation_revision, "landmark_targets": Array(landmark_targets),
		"map_id": map_id, "naturalization_amplitude": naturalization_amplitude,
		"naturalization_frequency": naturalization_frequency,
		"points_of_interest": _resource_data(points_of_interest, "poi_id"),
		"review_viewpoints": review_viewpoints, "seed": seed,
		"sightlines": _resource_data(sightlines, "sightline_id"),
		"spawn_position": spawn_position,
		"spline_features": _resource_data(spline_features, "feature_id"),
		"terrain_control_regions": _resource_data(terrain_control_regions, "region_id"),
		"terrain_height_max": terrain_height_max, "terrain_height_min": terrain_height_min,
		"terrain_resolution": terrain_resolution, "world_size": world_size,
	}


func poi_index() -> Dictionary:
	var result := {}
	for poi in points_of_interest:
		result[poi.poi_id] = poi
	return result


func _resource_data(resources: Array, id_field: String) -> Array:
	var data: Array = []
	for resource in resources:
		data.append(resource.to_canonical_data())
	data.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left[id_field]) < str(right[id_field]))
	return data
