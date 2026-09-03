extends Node3D

const AdapterScript := preload("res://scripts/world_generation/generation/terrain_3d_adapter.gd")
const GeneratorScript := preload("res://scripts/world_generation/generation/world_generator.gd")
const CanonicalDataScript := preload("res://scripts/world_generation/generation/canonical_data.gd")

@export var map_definition: Resource
@export var asset_registry: Resource

@onready var terrain: Node = $Terrain3D
@onready var generated_output: Node3D = $GeneratedOutput
@onready var overlay: Label = $DebugOverlay/Margin/Label


func _ready() -> void:
	call_deferred("_generate_once")


func _generate_once() -> void:
	await get_tree().process_frame
	var adapter: RefCounted = AdapterScript.new()
	var bind_result: Dictionary = adapter.bind(terrain)
	if not bind_result.get("ok", false):
		printerr("WORLD003_ADAPTER_ERROR=", JSON.stringify(bind_result))
		if OS.get_environment("WORLD003_AUTOCLOSE") == "1":
			get_tree().quit(1)
		return
	var seed_value: int = map_definition.seed
	if not OS.get_environment("WORLD003_SEED").is_empty():
		seed_value = OS.get_environment("WORLD003_SEED").to_int()
	var generator: RefCounted = GeneratorScript.new()
	var report: RefCounted = generator.generate(
		map_definition, {"asset_registry": asset_registry}, adapter, generated_output,
		{"seed": seed_value, "production_mode": false, "debug_mode": true}
	)
	var poi_hash: String = CanonicalDataScript.sha256(map_definition.to_canonical_data().points_of_interest)
	var river_data: Array = map_definition.to_canonical_data().spline_features.filter(
		func(feature: Dictionary) -> bool: return feature.feature_type == "RIVER")
	var river_hash: String = CanonicalDataScript.sha256(river_data)
	overlay.text = "WORLD-003 ENGINEERING SANDBOX\nMap: %s  Seed: %d\nHash: %s\nInstances: %d  MultiMesh: %d  Nodes: %d\nSightlines: %s" % [
		report.map_id, report.seed, report.generation_hash, report.instance_count,
		report.multimesh_count, report.generated_node_count, JSON.stringify(report.sightline_results)
	]
	print("WORLD003_RUNTIME method=", RenderingServer.get_current_rendering_method(),
		" driver=", RenderingServer.get_current_rendering_driver_name(),
		" display=", DisplayServer.get_name(), " adapter=", RenderingServer.get_video_adapter_name())
	print("WORLD003_REPORT_JSON=", JSON.stringify(report.to_dictionary()))
	print("WORLD003_AUTHORED poi_hash=", poi_hash, " river_hash=", river_hash)
	print("WORLD003_RESULT=", "PASS" if report.errors.is_empty() else "FAIL")
	if OS.get_environment("WORLD003_AUTOCLOSE") == "1":
		await get_tree().process_frame
		get_tree().quit(0 if report.errors.is_empty() else 1)
