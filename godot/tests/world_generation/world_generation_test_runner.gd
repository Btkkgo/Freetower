extends SceneTree

const SUITE_PATHS := [
	"res://tests/world_generation/canonical_hash_test.gd",
	"res://tests/world_generation/definition_validation_test.gd",
	"res://tests/world_generation/generation_services_test.gd",
	"res://tests/world_generation/orchestration_adapter_test.gd",
	"res://tests/world_generation/sandbox_contract_test.gd",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var passed := 0
	var failures: Array[String] = []
	for suite_path in SUITE_PATHS:
		var suite_script := load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("suite_loads:%s" % suite_path)
			continue
		var result: Dictionary = suite_script.new().run()
		passed += int(result.get("passed", 0))
		for failure in result.get("failures", []):
			failures.append(str(failure))

	for failure in failures:
		printerr("WORLD003_TEST_FAIL ", failure)
	print("WORLD003_TEST_SUMMARY tests=", passed + failures.size(),
		" passed=", passed, " failed=", failures.size())
	print("WORLD003_TEST_RESULT=", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
