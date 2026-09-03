extends RefCounted

const MapScript := preload("res://scripts/world_generation/definitions/map_definition.gd")
const BiomeScript := preload("res://scripts/world_generation/definitions/biome_definition.gd")
const RegionScript := preload("res://scripts/world_generation/definitions/terrain_control_region.gd")
const AdapterScript := preload("res://scripts/world_generation/generation/terrain_3d_adapter.gd")
const GeneratorScript := preload("res://scripts/world_generation/generation/world_generator.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	_test_terrain3d_class_available(failures)
	_test_adapter_binds_real_terrain(failures)
	_test_adapter_applies_height(failures)
	_test_generator_fails_before_mutation(failures)
	_test_generation_order_is_fixed(failures)
	_test_same_seed_generation_hash(failures)
	_test_visual_review_status_is_engineering_only(failures)
	return {"passed": 7 - failures.size(), "failures": failures}


func _test_terrain3d_class_available(failures: Array[String]) -> void:
	_expect(ClassDB.class_exists("Terrain3D"), "terrain3d_loads", failures)


func _test_adapter_binds_real_terrain(failures: Array[String]) -> void:
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	Engine.get_main_loop().root.add_child(terrain)
	var result: Dictionary = AdapterScript.new().bind(terrain)
	_expect(result.get("ok", false), "terrain3d_adapter_binds_real_node", failures)
	terrain.free()


func _test_adapter_applies_height(failures: Array[String]) -> void:
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	Engine.get_main_loop().root.add_child(terrain)
	var adapter: RefCounted = AdapterScript.new()
	adapter.bind(terrain)
	var result: Dictionary = adapter.apply_height_samples({"samples": [{"position": Vector3.ZERO, "height": 3.25}]})
	_expect(result.get("ok", false) and is_equal_approx(adapter.sample_height(Vector3.ZERO), 3.25), "terrain3d_adapter_applies_height_samples", failures)
	terrain.free()


func _test_generator_fails_before_mutation(failures: Array[String]) -> void:
	var map: Resource = _map()
	map.world_size = Vector2.ZERO
	var output := Node3D.new()
	output.add_child(Node3D.new())
	var report: RefCounted = GeneratorScript.new().generate(map, {}, null, output)
	_expect(not report.errors.is_empty() and output.get_child_count() == 1, "world_generator_fail_fast_before_mutation", failures)
	output.free()


func _test_generation_order_is_fixed(failures: Array[String]) -> void:
	var generator: RefCounted = GeneratorScript.new()
	var output := Node3D.new()
	var report: RefCounted = generator.generate(_map(), {}, null, output)
	var expected := ["validate", "context", "terrain", "regions", "splines", "noise", "biomes", "protect", "scatter", "sightlines", "report"]
	_expect(report.errors.is_empty() and generator.stage_events == expected, "world_generator_fixed_stage_order", failures)
	output.free()


func _test_same_seed_generation_hash(failures: Array[String]) -> void:
	var first: RefCounted = GeneratorScript.new().generate(_map(), {}, null, null)
	var second: RefCounted = GeneratorScript.new().generate(_map(), {}, null, null)
	_expect(first.generation_hash == second.generation_hash, "same_seed_generation_hash_identical", failures)


func _test_visual_review_status_is_engineering_only(failures: Array[String]) -> void:
	var report: RefCounted = GeneratorScript.new().generate(_map(), {}, null, null)
	_expect(report.get("visual_review_status") == "ENGINEERING_VALIDATION_ONLY", "sandbox_never_claims_final_art_approval", failures)


func _map() -> Resource:
	var map: Resource = MapScript.new()
	map.map_id = "orchestration_test"
	map.seed = 3003
	map.world_size = Vector2(10.0, 10.0)
	map.terrain_resolution = 3
	map.terrain_height_min = -4.0
	map.terrain_height_max = 8.0
	var biome: Resource = BiomeScript.new()
	biome.biome_id = "grassland"
	biome.height_min = -4.0
	biome.height_max = 8.0
	biome.region_size = Vector2(10.0, 10.0)
	map.biomes = [biome]
	var region: Resource = RegionScript.new()
	region.region_id = "flat"
	region.region_type = "FLAT"
	region.size = Vector2(10.0, 10.0)
	map.terrain_control_regions = [region]
	return map


func _expect(condition: bool, test_name: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(test_name)
