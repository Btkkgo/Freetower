class_name MapDefinitionValidator
extends RefCounted


func validate(map_definition: Resource, registries: Dictionary = {}) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	if map_definition.map_id.strip_edges().is_empty():
		_add(errors, "EMPTY_MAP_ID", "", "map_id", "Map ID must not be empty")
	if map_definition.world_size.x <= 0.0 or map_definition.world_size.y <= 0.0:
		_add(errors, "INVALID_WORLD_SIZE", map_definition.map_id, "world_size", "World size must be positive")
	if map_definition.terrain_height_min >= map_definition.terrain_height_max:
		_add(errors, "INVALID_HEIGHT_RANGE", map_definition.map_id, "terrain_height", "Height minimum must be below maximum")
	if map_definition.terrain_resolution < 2:
		_add(errors, "INVALID_TERRAIN_RESOLUTION", map_definition.map_id, "terrain_resolution", "Resolution must be at least two")
	if not _inside(map_definition.spawn_position, map_definition.world_size):
		_add(errors, "SPAWN_OUTSIDE_BOUNDS", map_definition.map_id, "spawn_position", "Spawn must be inside map bounds")
	_validate_unique(errors, map_definition.biomes, "biome_id", "DUPLICATE_BIOME_ID")
	_validate_unique(errors, map_definition.points_of_interest, "poi_id", "DUPLICATE_POI_ID")
	_validate_unique(errors, map_definition.spline_features, "feature_id", "DUPLICATE_SPLINE_ID")
	_validate_unique(errors, map_definition.exclusion_zones, "zone_id", "DUPLICATE_EXCLUSION_ID")
	_validate_unique(errors, map_definition.terrain_control_regions, "region_id", "DUPLICATE_TERRAIN_REGION_ID")
	_validate_unique(errors, map_definition.sightlines, "sightline_id", "DUPLICATE_SIGHTLINE_ID")
	for biome in map_definition.biomes:
		if biome.biome_id.strip_edges().is_empty() or biome.height_min > biome.height_max or biome.slope_min > biome.slope_max:
			_add(errors, "INVALID_BIOME", biome.biome_id, "range", "Biome ID and ranges must be valid")
	for poi in map_definition.points_of_interest:
		if not _inside(poi.position, map_definition.world_size):
			_add(errors, "POI_OUTSIDE_BOUNDS", poi.poi_id, "position", "POI must be inside map bounds")
	for feature in map_definition.spline_features:
		if feature.width <= 0.0:
			_add(errors, "INVALID_SPLINE_WIDTH", feature.feature_id, "width", "Spline width must be positive")
		if feature.control_points.size() < 2:
			_add(errors, "INVALID_SPLINE_POINTS", feature.feature_id, "control_points", "Spline needs at least two points")
	for zone in map_definition.exclusion_zones:
		var invalid: bool = (zone.shape == "CIRCLE" and zone.radius <= 0.0) or (zone.shape == "BOX" and (zone.size.x <= 0.0 or zone.size.z <= 0.0))
		if invalid:
			_add(errors, "INVALID_EXCLUSION_ZONE", zone.zone_id, "shape", "Exclusion geometry must be positive")
	var registry = registries.get("asset_registry")
	if registry != null:
		errors.append_array(registry.build_index())
	errors.sort_custom(_sort_errors)
	return errors


func _validate_unique(errors: Array[Dictionary], resources: Array, field: String, code: String) -> void:
	var seen := {}
	for resource in resources:
		var value := str(resource.get(field))
		if seen.has(value):
			_add(errors, code, value, field, "%s must be unique" % field)
		seen[value] = true


func _inside(position: Vector3, world_size: Vector2) -> bool:
	var half := world_size * 0.5
	return position.x >= -half.x and position.x <= half.x and position.z >= -half.y and position.z <= half.y


func _add(errors: Array[Dictionary], code: String, resource_id: String, field: String, message: String) -> void:
	errors.append({"code": code, "resource_id": resource_id, "field": field, "message": message})


func _sort_errors(left: Dictionary, right: Dictionary) -> bool:
	var left_key := "%s|%s|%s" % [left.code, left.resource_id, left.field]
	var right_key := "%s|%s|%s" % [right.code, right.resource_id, right.field]
	return left_key < right_key
