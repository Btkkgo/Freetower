class_name EnvironmentAssetDefinition
extends Resource

@export var asset_id := ""
@export var display_name := ""
@export var packed_scene: PackedScene
@export var asset_tags := PackedStringArray()
@export var allowed_biomes := PackedStringArray()
@export var scale_min := 1.0
@export var scale_max := 1.0
@export_enum("NONE", "YAW", "FULL") var rotation_mode := "YAW"
@export_range(0.0, 90.0) var slope_min := 0.0
@export_range(0.0, 90.0) var slope_max := 90.0
@export var height_min := -1000.0
@export var height_max := 1000.0
@export var lod_profile := ""
@export var collision_profile := ""
@export var is_debug_proxy := false
@export var production_approved := false
@export var asset_revision := ""
@export var source_reference := ""


func to_canonical_data() -> Dictionary:
	return {
		"allowed_biomes": Array(allowed_biomes), "asset_id": asset_id,
		"asset_revision": asset_revision, "asset_tags": Array(asset_tags),
		"collision_profile": collision_profile, "height_max": height_max, "height_min": height_min,
		"is_debug_proxy": is_debug_proxy, "lod_profile": lod_profile,
		"production_approved": production_approved, "rotation_mode": rotation_mode,
		"scale_max": scale_max, "scale_min": scale_min, "slope_max": slope_max,
		"slope_min": slope_min, "source_reference": source_reference,
	}
