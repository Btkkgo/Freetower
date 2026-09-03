class_name EnvironmentScatterGenerator
extends RefCounted

const BiomeSamplerScript := preload("res://scripts/world_generation/placement/biome_sampler.gd")
const SplineSamplerScript := preload("res://scripts/world_generation/generation/spline_feature_sampler.gd")


func generate(context: RefCounted, sample_data: Dictionary, parent: Node3D = null) -> Dictionary:
	var placements: Array = []
	var excluded_count := 0
	var invalid_count := 0
	var ordered: Array = sample_data.get("samples", []).duplicate(true)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var a: Vector3 = left.position
		var b: Vector3 = right.position
		return a.z < b.z if not is_equal_approx(a.z, b.z) else a.x < b.x)
	var biome_sampler := BiomeSamplerScript.new()
	for sample in ordered:
		var position: Vector3 = sample.position
		if _is_excluded(position, context.map_definition):
			excluded_count += 1
			continue
		var biome_id: String = sample.get("biome_id", "")
		if biome_id.is_empty():
			biome_id = biome_sampler.resolve(position, sample, context)
		if biome_id.is_empty():
			invalid_count += 1
			continue
		var biome: Resource = _find_biome(context.map_definition, biome_id)
		var assets: Array = context.asset_registry.find_by_tags(biome.asset_tags, biome_id, context.production_mode)
		assets = assets.filter(func(asset: Resource) -> bool:
			return sample.get("height", position.y) >= asset.height_min \
				and sample.get("height", position.y) <= asset.height_max \
				and sample.get("slope", 0.0) >= asset.slope_min \
				and sample.get("slope", 0.0) <= asset.slope_max)
		if assets.is_empty():
			invalid_count += 1
			continue
		var cell_id := "%.4f,%.4f" % [position.x, position.z]
		var rng: RandomNumberGenerator = context.make_rng("scatter", "%s|%s" % [biome_id, cell_id])
		var asset: Resource = assets[rng.randi_range(0, assets.size() - 1)]
		if _spline_excludes_asset(position, asset, context.map_definition):
			excluded_count += 1
			continue
		if rng.randf() > clampf(biome.density_multiplier, 0.0, 1.0):
			excluded_count += 1
			continue
		var scale_value := rng.randf_range(asset.scale_min, asset.scale_max)
		var yaw := rng.randf_range(-PI, PI) if asset.rotation_mode == "YAW" else 0.0
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value)
		var transform := Transform3D(basis, Vector3(position.x, sample.get("height", position.y), position.z))
		placements.append({"asset_id": asset.asset_id, "biome_id": biome_id, "transform": transform})
	var multimesh_count := _build_multimeshes(placements, context.asset_registry, parent) if parent != null else 0
	var counts := {}
	for placement in placements:
		counts[placement.asset_id] = int(counts.get(placement.asset_id, 0)) + 1
	return {
		"asset_instance_counts": counts, "excluded_count": excluded_count,
		"generated_node_count": multimesh_count, "invalid_count": invalid_count,
		"multimesh_count": multimesh_count, "placements": placements,
	}


func _is_excluded(position: Vector3, map_definition: Resource) -> bool:
	for zone in map_definition.exclusion_zones:
		if zone.contains(position):
			return true
	for poi in map_definition.points_of_interest:
		var clearance := maxf(poi.required_clearance, poi.vegetation_exclusion_radius)
		if Vector2(position.x - poi.position.x, position.z - poi.position.z).length() <= clearance:
			return true
	return false


func _find_biome(map_definition: Resource, biome_id: String) -> Resource:
	for biome in map_definition.biomes:
		if biome.biome_id == biome_id:
			return biome
	return null


func _spline_excludes_asset(position: Vector3, asset: Resource, map_definition: Resource) -> bool:
	if not asset.asset_tags.has("vegetation") and not asset.asset_tags.has("tree") and not asset.asset_tags.has("bamboo"):
		return false
	var sampler := SplineSamplerScript.new()
	for feature in map_definition.spline_features:
		if feature.vegetation_exclusion_radius > 0.0 \
			and sampler.distance_to_feature(position, feature) <= feature.vegetation_exclusion_radius:
			return true
	return false


func _build_multimeshes(placements: Array, registry: Resource, parent: Node3D) -> int:
	var groups := {}
	for placement in placements:
		groups.get_or_add(placement.asset_id, []).append(placement.transform)
	var asset_ids := groups.keys()
	asset_ids.sort()
	var created := 0
	for asset_id in asset_ids:
		var resolved: Dictionary = registry.resolve(asset_id, false)
		if not resolved.ok:
			continue
		var mesh := _extract_mesh(resolved.asset.packed_scene)
		if mesh == null:
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = groups[asset_id].size()
		for index in range(groups[asset_id].size()):
			multimesh.set_instance_transform(index, groups[asset_id][index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "FoundationScatter_%s" % asset_id
		instance.multimesh = multimesh
		parent.add_child(instance)
		created += 1
	return created


func _extract_mesh(packed_scene: PackedScene) -> Mesh:
	if packed_scene == null:
		return null
	var instance := packed_scene.instantiate()
	var mesh: Mesh
	if instance is MeshInstance3D:
		mesh = instance.mesh
	else:
		var child := instance.find_child("*", true, false)
		if child is MeshInstance3D:
			mesh = child.mesh
	instance.free()
	return mesh
