class_name Terrain3DAdapter
extends RefCounted

var _terrain: Node
var _data: Object


func bind(terrain: Node) -> Dictionary:
	if not ClassDB.class_exists("Terrain3D"):
		return {"ok": false, "error": "TERRAIN3D_CLASS_MISSING"}
	if terrain == null or terrain.get_class() != "Terrain3D":
		return {"ok": false, "error": "INVALID_TERRAIN3D_NODE"}
	_terrain = terrain
	_data = terrain.get("data")
	if _data == null:
		return {"ok": false, "error": "TERRAIN3D_DATA_MISSING"}
	return {
		"ok": true, "region_count": _data.get_region_count(),
		"region_size": terrain.call("get_region_size"),
		"vertex_spacing": terrain.call("get_vertex_spacing"),
	}


func apply_height_samples(sample_data: Dictionary) -> Dictionary:
	if _data == null:
		return {"ok": false, "error": "TERRAIN3D_ADAPTER_NOT_BOUND"}
	var samples: Array = sample_data.get("samples", [])
	for sample in samples:
		var position: Vector3 = sample.position
		if not _data.has_regionp(position):
			_data.add_region_blankp(position, false)
	if not samples.is_empty():
		_data.update_maps()
	for sample in samples:
		_data.set_height(sample.position, float(sample.height))
	if not samples.is_empty():
		_data.update_maps(0, false)
	return {"ok": true, "region_count": _data.get_region_count(), "sample_count": samples.size()}


func sample_height(position: Vector3) -> float:
	return NAN if _data == null else float(_data.get_height(position))


func sample_slope_degrees(position: Vector3) -> float:
	if _data == null:
		return NAN
	var normal: Vector3 = _data.get_normal(position)
	return rad_to_deg(normal.angle_to(Vector3.UP))


func terrain_node() -> Node:
	return _terrain
