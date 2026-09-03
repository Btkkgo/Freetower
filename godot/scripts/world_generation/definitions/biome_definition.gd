class_name BiomeDefinition
extends Resource

@export var biome_id := ""
@export var display_name := ""
@export var priority := 0
@export var height_min := -1000.0
@export var height_max := 1000.0
@export_range(0.0, 90.0) var slope_min := 0.0
@export_range(0.0, 90.0) var slope_max := 90.0
@export var distance_to_water_min := 0.0
@export var distance_to_water_max := 10000.0
@export var density_multiplier := 1.0
@export var asset_tags := PackedStringArray()
@export var exclusion_tags := PackedStringArray()
@export var noise_scale := 0.05
@export var noise_strength := 0.0
@export var seed_offset := 0
@export var region_center := Vector2.ZERO
@export var region_size := Vector2.ZERO
@export var debug_color := Color.WHITE


func to_canonical_data() -> Dictionary:
	return {
		"asset_tags": Array(asset_tags), "biome_id": biome_id,
		"density_multiplier": density_multiplier, "distance_to_water_max": distance_to_water_max,
		"distance_to_water_min": distance_to_water_min, "exclusion_tags": Array(exclusion_tags),
		"height_max": height_max, "height_min": height_min, "noise_scale": noise_scale,
		"noise_strength": noise_strength, "priority": priority, "region_center": region_center,
		"region_size": region_size, "seed_offset": seed_offset, "slope_max": slope_max,
		"slope_min": slope_min,
	}
