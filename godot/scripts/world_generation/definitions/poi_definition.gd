class_name POIDefinition
extends Resource

@export var poi_id := ""
@export_enum("SPAWN", "SUGGESTED_CAMP", "ANCIENT_BANYAN", "STONE_HILL_VIEWPOINT", "ANCIENT_RUINS", "FREE_TOWER_SIGHTLINE_ANCHOR", "GENERAL_LANDMARK") var poi_type := "GENERAL_LANDMARK"
@export var position := Vector3.ZERO
@export var radius := 1.0
@export var rotation_degrees := Vector3.ZERO
@export var tags := PackedStringArray()
@export var required_clearance := 0.0
@export var vegetation_exclusion_radius := 0.0
@export var buildable := false
@export var debug_visible := true
@export var sightline_height := 1.7


func to_canonical_data() -> Dictionary:
	return {
		"buildable": buildable, "poi_id": poi_id, "poi_type": poi_type, "position": position,
		"radius": radius, "required_clearance": required_clearance,
		"rotation_degrees": rotation_degrees, "sightline_height": sightline_height,
		"tags": Array(tags), "vegetation_exclusion_radius": vegetation_exclusion_radius,
	}
