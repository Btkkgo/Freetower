class_name WorldExclusionZone
extends Resource

@export var zone_id := ""
@export_enum("CIRCLE", "BOX") var shape := "CIRCLE"
@export var center := Vector3.ZERO
@export var radius := 1.0
@export var size := Vector3.ONE
@export var tags := PackedStringArray()
@export var reason := ""


func contains(point: Vector3) -> bool:
	if shape == "CIRCLE":
		return Vector2(point.x - center.x, point.z - center.z).length() <= radius
	var half := Vector2(size.x, size.z) * 0.5
	return absf(point.x - center.x) <= half.x and absf(point.z - center.z) <= half.y


func to_canonical_data() -> Dictionary:
	return {
		"center": center, "radius": radius, "reason": reason, "shape": shape,
		"size": size, "tags": Array(tags), "zone_id": zone_id,
	}
