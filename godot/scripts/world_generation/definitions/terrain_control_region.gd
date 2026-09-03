class_name TerrainControlRegion
extends Resource

@export var region_id := ""
@export_enum("FLAT", "RAISE", "LOWER", "SLOPE", "PLATEAU", "VALLEY") var region_type := "FLAT"
@export var center := Vector2.ZERO
@export var size := Vector2.ONE
@export var radius := 1.0
@export var target_height := 0.0
@export var secondary_height := 0.0
@export var falloff := 1.0
@export var priority := 0


func to_canonical_data() -> Dictionary:
	return {
		"center": center, "falloff": falloff, "priority": priority, "radius": radius,
		"region_id": region_id, "region_type": region_type, "secondary_height": secondary_height,
		"size": size, "target_height": target_height,
	}
