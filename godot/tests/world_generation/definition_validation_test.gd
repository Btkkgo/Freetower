extends RefCounted

const MapDefinitionScript := preload("res://scripts/world_generation/definitions/map_definition.gd")
const BiomeDefinitionScript := preload("res://scripts/world_generation/definitions/biome_definition.gd")
const SplineDefinitionScript := preload("res://scripts/world_generation/definitions/spline_feature_definition.gd")
const POIDefinitionScript := preload("res://scripts/world_generation/definitions/poi_definition.gd")
const ExclusionZoneScript := preload("res://scripts/world_generation/definitions/world_exclusion_zone.gd")
const TerrainRegionScript := preload("res://scripts/world_generation/definitions/terrain_control_region.gd")
const AssetDefinitionScript := preload("res://scripts/world_generation/definitions/environment_asset_definition.gd")
const AssetRegistryScript := preload("res://scripts/world_generation/definitions/environment_asset_registry.gd")
const SightlineDefinitionScript := preload("res://scripts/world_generation/definitions/sightline_definition.gd")
const ValidatorScript := preload("res://scripts/world_generation/validation/map_definition_validator.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	_test_valid_definition(failures)
	_test_invalid_map_size(failures)
	_test_duplicate_biome(failures)
	_test_duplicate_poi(failures)
	_test_poi_outside_bounds(failures)
	_test_invalid_spline_width(failures)
	_test_duplicate_asset(failures)
	_test_invalid_exclusion(failures)
	_test_stable_id_canonical_data(failures)
	return {"passed": 9 - failures.size(), "failures": failures}


func _test_valid_definition(failures: Array[String]) -> void:
	_expect_error_absent(_validate(_valid_map()), "", "map_definition_valid_case", failures)


func _test_invalid_map_size(failures: Array[String]) -> void:
	var map := _valid_map()
	map.world_size = Vector2.ZERO
	_expect_error(_validate(map), "INVALID_WORLD_SIZE", "invalid_map_size_rejected", failures)


func _test_duplicate_biome(failures: Array[String]) -> void:
	var map := _valid_map()
	var duplicate := BiomeDefinitionScript.new()
	duplicate.biome_id = map.biomes[0].biome_id
	map.biomes.append(duplicate)
	_expect_error(_validate(map), "DUPLICATE_BIOME_ID", "duplicate_biome_id_rejected", failures)


func _test_duplicate_poi(failures: Array[String]) -> void:
	var map := _valid_map()
	var duplicate := POIDefinitionScript.new()
	duplicate.poi_id = map.points_of_interest[0].poi_id
	map.points_of_interest.append(duplicate)
	_expect_error(_validate(map), "DUPLICATE_POI_ID", "duplicate_poi_id_rejected", failures)


func _test_poi_outside_bounds(failures: Array[String]) -> void:
	var map := _valid_map()
	map.points_of_interest[0].position = Vector3(80.0, 0.0, 0.0)
	_expect_error(_validate(map), "POI_OUTSIDE_BOUNDS", "poi_outside_bounds_rejected", failures)


func _test_invalid_spline_width(failures: Array[String]) -> void:
	var map := _valid_map()
	map.spline_features[0].width = 0.0
	_expect_error(_validate(map), "INVALID_SPLINE_WIDTH", "invalid_spline_width_rejected", failures)


func _test_duplicate_asset(failures: Array[String]) -> void:
	var map := _valid_map()
	var registry := AssetRegistryScript.new()
	var first := AssetDefinitionScript.new()
	first.asset_id = "debug_tree"
	var second := AssetDefinitionScript.new()
	second.asset_id = "debug_tree"
	registry.assets = [first, second]
	_expect_error(_validate(map, {"asset_registry": registry}), "DUPLICATE_ASSET_ID", "duplicate_asset_id_rejected", failures)


func _test_invalid_exclusion(failures: Array[String]) -> void:
	var map := _valid_map()
	map.exclusion_zones[0].radius = 0.0
	_expect_error(_validate(map), "INVALID_EXCLUSION_ZONE", "invalid_exclusion_zone_rejected", failures)


func _test_stable_id_canonical_data(failures: Array[String]) -> void:
	var map := _valid_map()
	var data: Dictionary = map.to_canonical_data()
	_expect(data.map_id == "foundation_test" and data.biomes[0].biome_id == "grassland",
		"resource_graph_uses_stable_ids", failures)


func _valid_map() -> Resource:
	var map := MapDefinitionScript.new()
	map.map_id = "foundation_test"
	map.display_name = "Foundation Test"
	map.seed = 3003
	map.world_size = Vector2(100.0, 100.0)
	map.terrain_height_min = -4.0
	map.terrain_height_max = 18.0
	map.terrain_resolution = 101
	map.spawn_position = Vector3(-40.0, 0.0, -40.0)

	var biome := BiomeDefinitionScript.new()
	biome.biome_id = "grassland"
	biome.height_min = -4.0
	biome.height_max = 18.0
	biome.slope_min = 0.0
	biome.slope_max = 90.0
	biome.region_size = Vector2(100.0, 100.0)
	map.biomes = [biome]

	var river := SplineDefinitionScript.new()
	river.feature_id = "test_river"
	river.feature_type = "RIVER"
	river.control_points = PackedVector3Array([Vector3(-40.0, 0.0, -20.0), Vector3(40.0, 0.0, 20.0)])
	river.width = 4.0
	map.spline_features = [river]

	var spawn := POIDefinitionScript.new()
	spawn.poi_id = "spawn"
	spawn.poi_type = "SPAWN"
	spawn.position = map.spawn_position
	map.points_of_interest = [spawn]

	var exclusion := ExclusionZoneScript.new()
	exclusion.zone_id = "spawn_clearance"
	exclusion.shape = "CIRCLE"
	exclusion.center = map.spawn_position
	exclusion.radius = 4.0
	map.exclusion_zones = [exclusion]

	var region := TerrainRegionScript.new()
	region.region_id = "foundation_flat"
	region.region_type = "FLAT"
	region.center = Vector2.ZERO
	region.size = Vector2(100.0, 100.0)
	region.target_height = 0.0
	map.terrain_control_regions = [region]

	var sightline := SightlineDefinitionScript.new()
	sightline.sightline_id = "spawn_to_landmark"
	sightline.source_poi_id = "spawn"
	sightline.target_poi_id = "spawn"
	map.sightlines = [sightline]
	return map


func _validate(map, registries: Dictionary = {}) -> Array:
	return ValidatorScript.new().validate(map, registries)


func _expect_error(errors: Array, code: String, test_name: String, failures: Array[String]) -> void:
	for error in errors:
		if error.get("code", "") == code:
			return
	failures.append("%s expected_error=%s actual=%s" % [test_name, code, str(errors)])


func _expect_error_absent(errors: Array, _code: String, test_name: String, failures: Array[String]) -> void:
	if not errors.is_empty():
		failures.append("%s expected_no_errors actual=%s" % [test_name, str(errors)])


func _expect(condition: bool, test_name: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(test_name)
