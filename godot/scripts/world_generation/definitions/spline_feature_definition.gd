class_name SplineFeatureDefinition
extends Resource

const TYPES := ["RIVER", "COAST", "PATH"]

@export var feature_id := ""
@export_enum("RIVER", "COAST", "PATH") var feature_type := "RIVER"
@export var control_points := PackedVector3Array()
@export var width := 1.0
@export var depth := 0.0
@export var bank_width := 0.0
@export var falloff := 1.0
@export var terrain_influence := 1.0
@export var vegetation_exclusion_radius := 0.0
@export var rock_influence_radius := 0.0
@export var navigation_cost := 1.0


func to_canonical_data() -> Dictionary:
	return {
		"bank_width": bank_width, "control_points": Array(control_points), "depth": depth,
		"falloff": falloff, "feature_id": feature_id, "feature_type": feature_type,
		"navigation_cost": navigation_cost, "rock_influence_radius": rock_influence_radius,
		"terrain_influence": terrain_influence,
		"vegetation_exclusion_radius": vegetation_exclusion_radius, "width": width,
	}
