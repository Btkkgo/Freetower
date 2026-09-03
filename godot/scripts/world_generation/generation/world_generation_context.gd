class_name WorldGenerationContext
extends RefCounted

const CanonicalDataScript := preload("res://scripts/world_generation/generation/canonical_data.gd")

var map_definition: Resource
var seed := 0
var asset_registry: Resource
var production_mode := false
var debug_mode := true
var generation_revision := ""


func configure(map: Resource, registry: Resource = null, seed_override: int = -1, production: bool = false, debug: bool = true) -> WorldGenerationContext:
	map_definition = map
	seed = map.seed if seed_override < 0 else seed_override
	asset_registry = registry
	production_mode = production
	debug_mode = debug
	generation_revision = map.generation_revision
	return self


func stream_seed(stream_namespace: String, stable_id: String = "") -> int:
	var digest := CanonicalDataScript.sha256({
		"generation_revision": generation_revision,
		"namespace": stream_namespace,
		"seed": seed,
		"stable_id": stable_id,
	})
	return int(digest.substr(0, 8).hex_to_int()) & 0x7fffffff


func make_rng(stream_namespace: String, stable_id: String = "") -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = stream_seed(stream_namespace, stable_id)
	return rng
