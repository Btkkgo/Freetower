extends RefCounted

const MapScript := preload("res://scripts/world_generation/definitions/map_definition.gd")
const BiomeScript := preload("res://scripts/world_generation/definitions/biome_definition.gd")
const SplineScript := preload("res://scripts/world_generation/definitions/spline_feature_definition.gd")
const POIScript := preload("res://scripts/world_generation/definitions/poi_definition.gd")
const ExclusionScript := preload("res://scripts/world_generation/definitions/world_exclusion_zone.gd")
const RegionScript := preload("res://scripts/world_generation/definitions/terrain_control_region.gd")
const AssetScript := preload("res://scripts/world_generation/definitions/environment_asset_definition.gd")
const RegistryScript := preload("res://scripts/world_generation/definitions/environment_asset_registry.gd")
const SightlineScript := preload("res://scripts/world_generation/definitions/sightline_definition.gd")
const ContextScript := preload("res://scripts/world_generation/generation/world_generation_context.gd")
const ReportScript := preload("res://scripts/world_generation/generation/world_generation_report.gd")
const TerrainScript := preload("res://scripts/world_generation/generation/terrain_height_generator.gd")
const SplineSamplerScript := preload("res://scripts/world_generation/generation/spline_feature_sampler.gd")
const BiomeSamplerScript := preload("res://scripts/world_generation/placement/biome_sampler.gd")
const ScatterScript := preload("res://scripts/world_generation/placement/environment_scatter_generator.gd")
const SightlineValidatorScript := preload("res://scripts/world_generation/validation/sightline_validator.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	_test_registry_stable_lookup(failures)
	_test_registry_rejects_debug_proxy(failures)
	_test_registry_rejects_unapproved(failures)
	_test_same_seed_rng(failures)
	_test_different_seed_rng(failures)
	_test_report_ignores_runtime_fields(failures)
	_test_spline_samples_are_stable(failures)
	_test_same_seed_naturalization(failures)
	_test_different_seed_naturalization(failures)
	_test_noise_amplitude_is_bounded(failures)
	_test_authored_poi_is_seed_independent(failures)
	_test_authored_river_is_seed_independent(failures)
	_test_biome_respects_height(failures)
	_test_biome_respects_slope(failures)
	_test_scatter_respects_exclusion(failures)
	_test_scatter_respects_poi_clearance(failures)
	_test_scatter_respects_spline_exclusion(failures)
	_test_scatter_creates_multimesh(failures)
	_test_same_seed_scatter_transforms(failures)
	_test_sightline_clear(failures)
	_test_sightline_partial(failures)
	_test_sightline_blocked(failures)
	return {"passed": 22 - failures.size(), "failures": failures}


func _test_registry_stable_lookup(failures: Array[String]) -> void:
	var registry: Resource = _registry(false, true)
	_expect(registry.resolve("debug_tree", false).get("ok", false), "asset_id_lookup_stable", failures)


func _test_registry_rejects_debug_proxy(failures: Array[String]) -> void:
	var result: Dictionary = _registry(true, true).resolve("debug_tree", true)
	_expect(not result.ok and result.error == "MISSING APPROVED ASSET", "production_registry_rejects_debug_proxy", failures)


func _test_registry_rejects_unapproved(failures: Array[String]) -> void:
	var result: Dictionary = _registry(false, false).resolve("debug_tree", true)
	_expect(not result.ok and result.error == "MISSING APPROVED ASSET", "production_registry_rejects_unapproved_asset", failures)


func _test_same_seed_rng(failures: Array[String]) -> void:
	var left: RefCounted = _context(3003)
	var right: RefCounted = _context(3003)
	_expect(left.make_rng("scatter", "tree").randf() == right.make_rng("scatter", "tree").randf(), "same_seed_rng_stream_identical", failures)


func _test_different_seed_rng(failures: Array[String]) -> void:
	var left: RefCounted = _context(3003)
	var right: RefCounted = _context(4004)
	_expect(left.make_rng("scatter", "tree").randf() != right.make_rng("scatter", "tree").randf(), "different_seed_rng_stream_changes", failures)


func _test_report_ignores_runtime_fields(failures: Array[String]) -> void:
	var left: RefCounted = ReportScript.new()
	left.map_id = "foundation_test"
	left.seed = 3003
	left.duration_ms = 1.0
	left.generated_node_count = 3
	var right: RefCounted = ReportScript.new()
	right.map_id = "foundation_test"
	right.seed = 3003
	right.duration_ms = 999.0
	right.generated_node_count = 300
	_expect(left.finalize_hash() == right.finalize_hash(), "generation_report_deterministic_fields_stable", failures)


func _test_spline_samples_are_stable(failures: Array[String]) -> void:
	var spline: Resource = _river()
	var sampler: RefCounted = SplineSamplerScript.new()
	_expect(sampler.sample(spline, 2.0) == sampler.sample(spline, 2.0), "spline_sampling_deterministic", failures)


func _test_same_seed_naturalization(failures: Array[String]) -> void:
	var generator: RefCounted = TerrainScript.new()
	var point := Vector3(11.0, 0.0, -7.0)
	_expect(generator.naturalized_height(_map(3003), point) == generator.naturalized_height(_map(3003), point), "same_seed_naturalization_identical", failures)


func _test_different_seed_naturalization(failures: Array[String]) -> void:
	var generator: RefCounted = TerrainScript.new()
	var point := Vector3(11.0, 0.0, -7.0)
	_expect(generator.naturalized_height(_map(3003), point) != generator.naturalized_height(_map(4004), point), "different_seed_changes_naturalization", failures)


func _test_noise_amplitude_is_bounded(failures: Array[String]) -> void:
	var generator: RefCounted = TerrainScript.new()
	var map: Resource = _map(3003)
	var point := Vector3(11.0, 0.0, -7.0)
	var designed: float = generator.designed_height(map, point)
	var naturalized: float = generator.naturalized_height(map, point)
	_expect(absf(naturalized - designed) <= map.naturalization_amplitude + 0.000001, "noise_amplitude_within_maximum", failures)


func _test_authored_poi_is_seed_independent(failures: Array[String]) -> void:
	_expect(_map(3003).points_of_interest[0].position == _map(4004).points_of_interest[0].position, "different_seed_does_not_move_authored_poi", failures)


func _test_authored_river_is_seed_independent(failures: Array[String]) -> void:
	_expect(_map(3003).spline_features[0].control_points == _map(4004).spline_features[0].control_points, "different_seed_does_not_alter_river_control_points", failures)


func _test_biome_respects_height(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	_expect(BiomeSamplerScript.new().resolve(Vector3.ZERO, {"height": 30.0, "slope": 0.0, "distance_to_water": 10.0}, context) == "", "biome_sampler_respects_height", failures)


func _test_biome_respects_slope(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	_expect(BiomeSamplerScript.new().resolve(Vector3.ZERO, {"height": 0.0, "slope": 95.0, "distance_to_water": 10.0}, context) == "", "biome_sampler_respects_slope", failures)


func _test_scatter_respects_exclusion(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	var result: Dictionary = ScatterScript.new().generate(context, {"samples": [_sample(Vector3.ZERO)]}, null)
	_expect(result.placements.is_empty() and result.excluded_count == 1, "scatter_respects_exclusion_zone", failures)


func _test_scatter_respects_poi_clearance(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	context.map_definition.exclusion_zones.clear()
	var result: Dictionary = ScatterScript.new().generate(context, {"samples": [_sample(Vector3(2.0, 0.0, 2.0))]}, null)
	_expect(result.placements.is_empty() and result.excluded_count == 1, "scatter_respects_poi_clearance", failures)


func _test_scatter_respects_spline_exclusion(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	context.map_definition.exclusion_zones.clear()
	context.map_definition.points_of_interest.clear()
	var result: Dictionary = ScatterScript.new().generate(context, {"samples": [_sample(Vector3.ZERO)]}, null)
	_expect(result.placements.is_empty() and result.excluded_count == 1, "scatter_respects_spline_exclusion", failures)


func _test_scatter_creates_multimesh(failures: Array[String]) -> void:
	var context: RefCounted = _context(3003)
	context.map_definition.exclusion_zones.clear()
	context.map_definition.points_of_interest.clear()
	var parent := Node3D.new()
	var result: Dictionary = ScatterScript.new().generate(context, {"samples": [_sample(Vector3(10.0, 0.0, 10.0)), _sample(Vector3(14.0, 0.0, 10.0))]}, parent)
	_expect(result.multimesh_count == 1 and parent.get_child_count() == 1, "multimesh_output_created", failures)
	parent.free()


func _test_same_seed_scatter_transforms(failures: Array[String]) -> void:
	var left: RefCounted = _context(3003)
	left.map_definition.exclusion_zones.clear()
	left.map_definition.points_of_interest.clear()
	var right: RefCounted = _context(3003)
	right.map_definition.exclusion_zones.clear()
	right.map_definition.points_of_interest.clear()
	var samples := {"samples": [_sample(Vector3(10.0, 0.0, 10.0))]}
	var first: Dictionary = ScatterScript.new().generate(left, samples, null)
	var second: Dictionary = ScatterScript.new().generate(right, samples, null)
	_expect(first.placements == second.placements, "same_seed_scatter_transforms_identical", failures)


func _test_sightline_clear(failures: Array[String]) -> void:
	_expect(_sightline(func(_position: Vector3) -> float: return 0.0).classification == "CLEAR", "sightline_clear_classification", failures)


func _test_sightline_partial(failures: Array[String]) -> void:
	_expect(_sightline(func(position: Vector3) -> float: return 2.0 if position.x < 17.0 else 0.0).classification == "PARTIAL", "sightline_partial_classification", failures)


func _test_sightline_blocked(failures: Array[String]) -> void:
	_expect(_sightline(func(_position: Vector3) -> float: return 2.0).classification == "BLOCKED", "sightline_blocked_classification", failures)


func _map(seed_value: int) -> Resource:
	var map: Resource = MapScript.new()
	map.map_id = "foundation_test"
	map.seed = seed_value
	map.generation_revision = "foundation-v1"
	map.world_size = Vector2(100.0, 100.0)
	map.terrain_height_min = -4.0
	map.terrain_height_max = 18.0
	map.terrain_resolution = 11
	map.naturalization_amplitude = 0.35
	map.naturalization_frequency = 0.045
	var biome: Resource = BiomeScript.new()
	biome.biome_id = "grassland"
	biome.asset_tags = PackedStringArray(["tree"])
	biome.height_min = -4.0
	biome.height_max = 18.0
	biome.slope_min = 0.0
	biome.slope_max = 45.0
	biome.region_size = Vector2(100.0, 100.0)
	map.biomes = [biome]
	var region: Resource = RegionScript.new()
	region.region_id = "foundation_flat"
	region.region_type = "FLAT"
	region.center = Vector2.ZERO
	region.size = Vector2(100.0, 100.0)
	region.target_height = 0.0
	map.terrain_control_regions = [region]
	map.spline_features = [_river()]
	var poi: Resource = POIScript.new()
	poi.poi_id = "spawn"
	poi.position = Vector3.ZERO
	poi.vegetation_exclusion_radius = 5.0
	map.points_of_interest = [poi]
	var exclusion: Resource = ExclusionScript.new()
	exclusion.zone_id = "center_clearance"
	exclusion.shape = "CIRCLE"
	exclusion.center = Vector3.ZERO
	exclusion.radius = 1.0
	map.exclusion_zones = [exclusion]
	return map


func _river() -> Resource:
	var river: Resource = SplineScript.new()
	river.feature_id = "test_river"
	river.feature_type = "RIVER"
	river.control_points = PackedVector3Array([Vector3(-40.0, 0.0, -20.0), Vector3(40.0, 0.0, 20.0)])
	river.width = 4.0
	river.depth = 2.0
	river.bank_width = 3.0
	river.vegetation_exclusion_radius = 3.0
	return river


func _registry(debug_proxy: bool, approved: bool) -> Resource:
	var asset: Resource = AssetScript.new()
	asset.asset_id = "debug_tree"
	asset.asset_tags = PackedStringArray(["tree"])
	asset.allowed_biomes = PackedStringArray(["grassland"])
	asset.is_debug_proxy = debug_proxy
	asset.production_approved = approved
	asset.packed_scene = _proxy_scene()
	var registry: Resource = RegistryScript.new()
	registry.assets = [asset]
	return registry


func _proxy_scene() -> PackedScene:
	var root := MeshInstance3D.new()
	root.name = "DebugTreeProxy"
	root.mesh = BoxMesh.new()
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	return packed


func _context(seed_value: int) -> RefCounted:
	var context: RefCounted = ContextScript.new()
	context.configure(_map(seed_value), _registry(true, false), seed_value, false, true)
	return context


func _sample(position: Vector3) -> Dictionary:
	return {"position": position, "height": 0.0, "slope": 0.0, "distance_to_water": 10.0, "biome_id": "grassland"}


func _sightline(height_provider: Callable) -> Dictionary:
	var source: Resource = POIScript.new()
	source.poi_id = "source"
	source.position = Vector3.ZERO
	source.sightline_height = 1.7
	var target: Resource = POIScript.new()
	target.poi_id = "target"
	target.position = Vector3(33.0, 0.0, 0.0)
	target.sightline_height = 1.7
	var definition: Resource = SightlineScript.new()
	definition.sightline_id = "source_to_target"
	definition.source_poi_id = "source"
	definition.target_poi_id = "target"
	definition.sample_count = 32
	return SightlineValidatorScript.new().validate(definition, {"source": source, "target": target}, height_provider, [])


func _expect(condition: bool, test_name: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(test_name)
