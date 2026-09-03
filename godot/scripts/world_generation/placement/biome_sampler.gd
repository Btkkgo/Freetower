class_name BiomeSampler
extends RefCounted


func resolve(point: Vector3, sample: Dictionary, context: RefCounted) -> String:
	var candidates: Array = context.map_definition.biomes.duplicate()
	candidates.sort_custom(func(left: Resource, right: Resource) -> bool:
		return left.priority > right.priority if left.priority != right.priority else left.biome_id < right.biome_id)
	for biome in candidates:
		if sample.get("height", point.y) < biome.height_min or sample.get("height", point.y) > biome.height_max:
			continue
		if sample.get("slope", 0.0) < biome.slope_min or sample.get("slope", 0.0) > biome.slope_max:
			continue
		var water_distance: float = sample.get("distance_to_water", INF)
		if water_distance < biome.distance_to_water_min or water_distance > biome.distance_to_water_max:
			continue
		if biome.region_size.x > 0.0 and biome.region_size.y > 0.0:
			var local: Vector2 = Vector2(point.x, point.z) - biome.region_center
			if absf(local.x) > biome.region_size.x * 0.5 or absf(local.y) > biome.region_size.y * 0.5:
				continue
		return biome.biome_id
	return ""
