class_name WorldGenerator
extends RefCounted

const ValidatorScript := preload("res://scripts/world_generation/validation/map_definition_validator.gd")
const ContextScript := preload("res://scripts/world_generation/generation/world_generation_context.gd")
const ReportScript := preload("res://scripts/world_generation/generation/world_generation_report.gd")
const TerrainScript := preload("res://scripts/world_generation/generation/terrain_height_generator.gd")
const SplineSamplerScript := preload("res://scripts/world_generation/generation/spline_feature_sampler.gd")
const BiomeSamplerScript := preload("res://scripts/world_generation/placement/biome_sampler.gd")
const ScatterScript := preload("res://scripts/world_generation/placement/environment_scatter_generator.gd")
const SightlineValidatorScript := preload("res://scripts/world_generation/validation/sightline_validator.gd")

var stage_events: Array[String] = []


func generate(map_definition: Resource, registries: Dictionary, terrain_adapter: RefCounted, output_root: Node3D, options: Dictionary = {}) -> RefCounted:
	var start_usec := Time.get_ticks_usec()
	stage_events.clear()
	stage_events.append("validate")
	var report: RefCounted = ReportScript.new()
	report.map_id = map_definition.map_id
	report.seed = int(options.get("seed", map_definition.seed))
	report.generation_revision = map_definition.generation_revision
	report.visual_review_status = "ENGINEERING_VALIDATION_ONLY"
	report.errors = ValidatorScript.new().validate(map_definition, registries)
	if not report.errors.is_empty():
		report.terrain_status = "VALIDATION_FAILED"
		report.duration_ms = float(Time.get_ticks_usec() - start_usec) / 1000.0
		report.finalize_hash()
		return report

	stage_events.append("context")
	var context: RefCounted = ContextScript.new().configure(
		map_definition, registries.get("asset_registry"), report.seed,
		bool(options.get("production_mode", false)), bool(options.get("debug_mode", true))
	)
	var generated_root: Node3D
	if output_root != null:
		var existing := output_root.get_node_or_null("WORLD003Generated")
		if existing != null:
			existing.free()
		generated_root = Node3D.new()
		generated_root.name = "WORLD003Generated"
		output_root.add_child(generated_root)

	stage_events.append("terrain")
	var terrain_generator := TerrainScript.new()
	var sample_data: Dictionary = terrain_generator.generate_designed_samples(context)
	stage_events.append("regions")
	stage_events.append("splines")
	stage_events.append("noise")
	sample_data = terrain_generator.apply_naturalization(sample_data, context)
	if terrain_adapter != null:
		var terrain_result: Dictionary = terrain_adapter.apply_height_samples(sample_data)
		report.terrain_status = "TERRAIN3D_READY" if terrain_result.get("ok", false) else "TERRAIN3D_ERROR"
		if not terrain_result.get("ok", false):
			report.errors.append({"code": terrain_result.get("error", "TERRAIN3D_ERROR"), "resource_id": map_definition.map_id, "field": "terrain", "message": "Terrain3D Adapter failed"})
	else:
		report.terrain_status = "SAMPLES_ONLY"
		report.warnings.append("Terrain3D Adapter was not supplied")

	stage_events.append("biomes")
	_resolve_biomes(sample_data, context, terrain_adapter)
	stage_events.append("protect")
	stage_events.append("scatter")
	var scatter_result := {"placements": [], "asset_instance_counts": {}, "excluded_count": 0, "invalid_count": 0, "multimesh_count": 0, "generated_node_count": 0}
	if context.asset_registry != null:
		scatter_result = ScatterScript.new().generate(context, sample_data, generated_root)

	stage_events.append("sightlines")
	var height_provider := func(position: Vector3) -> float:
		return terrain_adapter.sample_height(position) if terrain_adapter != null else _nearest_height(sample_data.samples, position)
	for sightline in map_definition.sightlines:
		report.sightline_results.append(SightlineValidatorScript.new().validate(
			sightline, map_definition.poi_index(), height_provider, []))

	stage_events.append("report")
	report.biome_counts = _biome_counts(sample_data.samples)
	report.asset_instance_counts = scatter_result.asset_instance_counts
	report.instance_count = scatter_result.placements.size()
	report.multimesh_count = scatter_result.multimesh_count
	report.generated_node_count = scatter_result.generated_node_count
	report.spline_count = map_definition.spline_features.size()
	report.poi_count = map_definition.points_of_interest.size()
	report.authored_poi_data = map_definition.to_canonical_data().points_of_interest
	report.authored_river_data = map_definition.to_canonical_data().spline_features.filter(
		func(feature: Dictionary) -> bool: return feature.feature_type == "RIVER")
	report.naturalization_data = sample_data.samples.map(
		func(sample: Dictionary) -> Dictionary: return {"position": sample.position, "height": sample.height})
	report.placements = scatter_result.placements
	report.duration_ms = float(Time.get_ticks_usec() - start_usec) / 1000.0
	report.finalize_hash()
	return report


func _resolve_biomes(sample_data: Dictionary, context: RefCounted, terrain_adapter: RefCounted) -> void:
	var biome_sampler := BiomeSamplerScript.new()
	var spline_sampler := SplineSamplerScript.new()
	var water_features: Array = context.map_definition.spline_features.filter(
		func(feature: Resource) -> bool: return feature.feature_type == "RIVER" or feature.feature_type == "COAST")
	for sample in sample_data.samples:
		sample.slope = terrain_adapter.sample_slope_degrees(sample.position) if terrain_adapter != null else 0.0
		var distance := INF
		for feature in water_features:
			distance = minf(distance, spline_sampler.distance_to_feature(sample.position, feature))
		sample.distance_to_water = distance
		sample.biome_id = biome_sampler.resolve(sample.position, sample, context)


func _nearest_height(samples: Array, point: Vector3) -> float:
	var best_distance := INF
	var height := 0.0
	for sample in samples:
		var position: Vector3 = sample.position
		var distance := Vector2(point.x - position.x, point.z - position.z).length_squared()
		if distance < best_distance:
			best_distance = distance
			height = sample.height
	return height


func _biome_counts(samples: Array) -> Dictionary:
	var counts := {}
	for sample in samples:
		var biome_id: String = sample.get("biome_id", "")
		if not biome_id.is_empty():
			counts[biome_id] = int(counts.get(biome_id, 0)) + 1
	return counts
