class_name WorldGenerationReport
extends RefCounted

const CanonicalDataScript := preload("res://scripts/world_generation/generation/canonical_data.gd")

var map_id := ""
var seed := 0
var generation_revision := ""
var terrain_status := "NOT_RUN"
var biome_counts := {}
var asset_instance_counts := {}
var spline_count := 0
var poi_count := 0
var sightline_results: Array = []
var warnings: Array[String] = []
var errors: Array = []
var generation_hash := ""
var duration_ms := 0.0
var instance_count := 0
var multimesh_count := 0
var generated_node_count := 0
var renderer := ""
var adapter := ""
var visual_review_status := "NOT_READY"
var authored_poi_data: Array = []
var authored_river_data: Array = []
var naturalization_data: Array = []
var placements: Array = []


func deterministic_data() -> Dictionary:
	return {
		"asset_instance_counts": asset_instance_counts,
		"authored_poi_data": authored_poi_data,
		"authored_river_data": authored_river_data,
		"biome_counts": biome_counts,
		"errors": errors,
		"generation_revision": generation_revision,
		"map_id": map_id,
		"naturalization_data": naturalization_data,
		"placements": placements,
		"poi_count": poi_count,
		"seed": seed,
		"sightline_results": sightline_results,
		"spline_count": spline_count,
		"terrain_status": terrain_status,
		"warnings": warnings,
	}


func finalize_hash() -> String:
	generation_hash = CanonicalDataScript.sha256(deterministic_data())
	return generation_hash


func to_dictionary() -> Dictionary:
	return {
		"asset_instance_counts": asset_instance_counts, "biome_counts": biome_counts,
		"duration_ms": duration_ms, "errors": errors, "generated_node_count": generated_node_count,
		"generation_hash": generation_hash, "generation_revision": generation_revision,
		"instance_count": instance_count, "map_id": map_id, "multimesh_count": multimesh_count,
		"poi_count": poi_count, "seed": seed, "sightline_results": sightline_results,
		"spline_count": spline_count, "terrain_status": terrain_status,
		"visual_review_status": visual_review_status, "warnings": warnings,
	}
