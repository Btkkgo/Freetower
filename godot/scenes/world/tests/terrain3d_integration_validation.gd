extends Node3D

const EXPECTED_REGION_COUNT := 1
const EXPECTED_REGION_SIZE := 256
const EXPECTED_VERTEX_SPACING := 0.25
const EXPECTED_PHYSICAL_SIZE_METERS := 64.0
const CAPTURE_PATH := "res://docs/visual-review/WORLD-002/terrain3d-runtime.png"

@onready var terrain: Terrain3D = $Terrain3D
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.look_at(Vector3(29.0, 1.5, 29.0), Vector3.UP)
	call_deferred("_run_validation")


func _run_validation() -> void:
	var frame_count := 8 if OS.get_environment("WORLD002_FAST") == "1" else 180
	for frame in frame_count:
		await get_tree().process_frame

	var method := RenderingServer.get_current_rendering_method()
	var driver := RenderingServer.get_current_rendering_driver_name()
	var region_count := terrain.data.get_region_count()
	var region_size := terrain.get_region_size()
	var vertex_spacing := terrain.get_vertex_spacing()
	var physical_size := region_size * vertex_spacing
	var hill_height := terrain.data.get_height(Vector3(18.0, 0.0, 20.0))
	var low_height := terrain.data.get_height(Vector3(46.0, 0.0, 39.0))
	var flat_height := terrain.data.get_height(Vector3(58.0, 0.0, 58.0))

	print("WORLD002_RUNTIME method=", method,
		" driver=", driver,
		" display=", DisplayServer.get_name(),
		" adapter=", RenderingServer.get_video_adapter_name())
	print("WORLD002_TERRAIN regions=", region_count,
		" region_size=", region_size,
		" vertex_spacing=", vertex_spacing,
		" physical_size_m=", physical_size,
		" hill=", hill_height,
		" low=", low_height,
		" flat=", flat_height)

	var valid := (
		method == "forward_plus"
		and (
			driver == "vulkan"
			or OS.get_environment("WORLD002_ALLOW_NON_VULKAN") == "1"
		)
		and region_count == EXPECTED_REGION_COUNT
		and region_size == EXPECTED_REGION_SIZE
		and is_equal_approx(vertex_spacing, EXPECTED_VERTEX_SPACING)
		and is_equal_approx(physical_size, EXPECTED_PHYSICAL_SIZE_METERS)
		and hill_height > 7.5
		and low_height < -2.0
		and absf(flat_height) < 0.01
	)

	if OS.get_environment("WORLD002_CAPTURE") == "1":
		var image := get_viewport().get_texture().get_image()
		var capture_error := image.save_png(ProjectSettings.globalize_path(CAPTURE_PATH))
		var mean_luminance := _sample_mean_luminance(image)
		var black_ratio := _sample_black_ratio(image)
		print("WORLD002_CAPTURE path=", ProjectSettings.globalize_path(CAPTURE_PATH),
			" size=", image.get_size(),
			" mean_luminance=", mean_luminance,
			" black_ratio=", black_ratio,
			" error=", capture_error)
		valid = valid and capture_error == OK and mean_luminance > 0.08 and black_ratio < 0.2

	print("WORLD002_RESULT=", "PASS" if valid else "FAIL")
	if OS.get_environment("WORLD002_AUTOCLOSE") == "1":
		get_tree().quit(0 if valid else 1)


func _sample_mean_luminance(image: Image) -> float:
	var total := 0.0
	var samples := 0
	for y in range(0, image.get_height(), 16):
		for x in range(0, image.get_width(), 16):
			var color := image.get_pixel(x, y)
			total += color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			samples += 1
	return total / maxf(float(samples), 1.0)


func _sample_black_ratio(image: Image) -> float:
	var black_samples := 0
	var samples := 0
	for y in range(0, image.get_height(), 16):
		for x in range(0, image.get_width(), 16):
			var color := image.get_pixel(x, y)
			if maxf(color.r, maxf(color.g, color.b)) < 0.04:
				black_samples += 1
			samples += 1
	return float(black_samples) / maxf(float(samples), 1.0)
