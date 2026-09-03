extends RefCounted

const MAP_PATH := "res://data/world/tests/world_generation_foundation_test.tres"
const REGISTRY_PATH := "res://data/world/tests/foundation_environment_asset_registry.tres"
const SCENE_PATH := "res://scenes/world/tests/WorldGenerationFoundationTest.tscn"


func run() -> Dictionary:
	var failures: Array[String] = []
	_test_sandbox_map_contract(failures)
	_test_debug_proxy_contract(failures)
	_test_sandbox_scene_contract(failures)
	return {"passed": 3 - failures.size(), "failures": failures}


func _test_sandbox_map_contract(failures: Array[String]) -> void:
	var map: Resource = load(MAP_PATH)
	if map == null:
		failures.append("sandbox_map_definition_loads")
		return
	var biome_ids := PackedStringArray()
	for biome in map.biomes:
		biome_ids.append(biome.biome_id)
	var required := PackedStringArray(["grassland", "forest", "bamboo", "rock_hill", "river_bank", "coast", "ruins"])
	for biome_id in required:
		if not biome_ids.has(biome_id):
			failures.append("sandbox_map_has_biome_%s" % biome_id)
	var river_count: int = map.spline_features.filter(func(feature: Resource) -> bool: return feature.feature_type == "RIVER").size()
	var coast_count: int = map.spline_features.filter(func(feature: Resource) -> bool: return feature.feature_type == "COAST").size()
	if map.world_size != Vector2(100.0, 100.0) or river_count != 1 or coast_count != 1 \
		or map.points_of_interest.size() < 4 or map.exclusion_zones.size() < 2 or map.sightlines.size() < 3:
		failures.append("sandbox_map_required_foundation_content")


func _test_debug_proxy_contract(failures: Array[String]) -> void:
	var registry: Resource = load(REGISTRY_PATH)
	if registry == null:
		failures.append("sandbox_asset_registry_loads")
		return
	for asset in registry.assets:
		if not asset.is_debug_proxy or asset.production_approved:
			failures.append("sandbox_debug_proxy_flags_%s" % asset.asset_id)


func _test_sandbox_scene_contract(failures: Array[String]) -> void:
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		failures.append("sandbox_scene_loads")
		return
	var scene := packed.instantiate()
	var required_nodes := PackedStringArray([
		"Terrain3D", "ReviewCamera_Spawn", "ReviewCamera_Forest",
		"ReviewCamera_StoneHill", "ReviewCamera_Ruins",
	])
	for node_name in required_nodes:
		if scene.find_child(node_name, true, false) == null:
			failures.append("sandbox_scene_has_%s" % node_name)
	scene.free()
