class_name TerrainHeightGenerator
extends RefCounted

const SplineSamplerScript := preload("res://scripts/world_generation/generation/spline_feature_sampler.gd")


func designed_height(map_definition: Resource, point: Vector3) -> float:
	var height := 0.0
	var ordered: Array = map_definition.terrain_control_regions.duplicate()
	ordered.sort_custom(func(left: Resource, right: Resource) -> bool:
		return left.priority < right.priority if left.priority != right.priority else left.region_id < right.region_id)
	for region in ordered:
		var influence := _region_influence(region, point)
		if influence <= 0.0:
			continue
		var target := _region_target(region, point)
		match region.region_type:
			"RAISE": height = maxf(height, lerpf(height, target, influence))
			"LOWER", "VALLEY": height = minf(height, lerpf(height, target, influence))
			_: height = lerpf(height, target, influence)
	var spline_sampler := SplineSamplerScript.new()
	for feature in map_definition.spline_features:
		var distance: float = spline_sampler.distance_to_feature(point, feature)
		if feature.feature_type == "RIVER":
			var reach: float = feature.width * 0.5 + feature.bank_width
			if distance < reach:
				var strength := 1.0 - smoothstep(feature.width * 0.5, reach, distance)
				height -= feature.depth * strength * feature.terrain_influence
		elif feature.feature_type == "COAST" and distance < feature.width + feature.bank_width:
			var coast_strength := 1.0 - smoothstep(feature.width, feature.width + feature.bank_width, distance)
			height -= feature.depth * coast_strength * feature.terrain_influence
	return clampf(height, map_definition.terrain_height_min, map_definition.terrain_height_max)


func naturalized_height(map_definition: Resource, point: Vector3, seed_override: int = -1) -> float:
	var noise := FastNoiseLite.new()
	noise.seed = map_definition.seed if seed_override < 0 else seed_override
	noise.frequency = map_definition.naturalization_frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var offset: float = noise.get_noise_2d(point.x, point.z) * map_definition.naturalization_amplitude
	return clampf(designed_height(map_definition, point) + offset,
		map_definition.terrain_height_min, map_definition.terrain_height_max)


func generate_designed_samples(context: RefCounted) -> Dictionary:
	var map: Resource = context.map_definition
	var samples: Array = []
	var resolution: int = map.terrain_resolution
	var step := Vector2(map.world_size.x / float(resolution - 1), map.world_size.y / float(resolution - 1))
	for z_index in range(resolution):
		for x_index in range(resolution):
			var point := Vector3(-map.world_size.x * 0.5 + step.x * x_index, 0.0,
				-map.world_size.y * 0.5 + step.y * z_index)
			var designed := designed_height(map, point)
			samples.append({"position": point, "designed_height": designed, "height": designed})
	return {"resolution": resolution, "step": step, "samples": samples}


func apply_naturalization(sample_data: Dictionary, context: RefCounted) -> Dictionary:
	var result := sample_data.duplicate(true)
	for sample in result.samples:
		sample.height = naturalized_height(context.map_definition, sample.position, context.seed)
	return result


func _region_influence(region: Resource, point: Vector3) -> float:
	var local: Vector2 = Vector2(point.x, point.z) - region.center
	var half: Vector2 = region.size * 0.5
	if absf(local.x) > half.x or absf(local.y) > half.y:
		return 0.0
	if region.falloff <= 0.0:
		return 1.0
	var edge_distance := minf(half.x - absf(local.x), half.y - absf(local.y))
	return clampf(edge_distance / region.falloff, 0.0, 1.0)


func _region_target(region: Resource, point: Vector3) -> float:
	if region.region_type == "SLOPE":
		var left: float = region.center.x - region.size.x * 0.5
		var factor := clampf((point.x - left) / maxf(region.size.x, 0.001), 0.0, 1.0)
		return lerpf(region.target_height, region.secondary_height, factor)
	return region.target_height
