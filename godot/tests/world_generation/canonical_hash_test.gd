extends RefCounted

const CanonicalData := preload("res://scripts/world_generation/generation/canonical_data.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	_expect_equal(
		CanonicalData.to_json({"b": 2, "a": 1}),
		"{\"a\":1,\"b\":2}",
		"canonical_dictionary_key_order",
		failures
	)
	var left := {"seed": 7, "duration_ms": 1.0, "generated_node_count": 4}
	var right := {"seed": 7, "duration_ms": 999.0, "generated_node_count": 99}
	_expect_equal(
		CanonicalData.sha256(left),
		CanonicalData.sha256(right),
		"canonical_hash_excludes_runtime_fields",
		failures
	)
	_expect_equal(
		CanonicalData.to_json({"position": Vector3(1.2345678, 2.0, -3.0)}),
		"{\"position\":[1.234568,2.0,-3.0]}",
		"canonical_vector_and_float_quantization",
		failures
	)
	return {"passed": 3 - failures.size(), "failures": failures}


func _expect_equal(actual: Variant, expected: Variant, test_name: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s expected=%s actual=%s" % [test_name, str(expected), str(actual)])
