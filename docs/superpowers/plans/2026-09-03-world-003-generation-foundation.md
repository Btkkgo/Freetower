# WORLD-003 World Generation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deterministic, data-driven, human-layout-first Terrain3D world-generation foundation and isolated engineering Sandbox for WORLD-004.

**Architecture:** Focused Godot Resources hold authored intent and reference one another through stable IDs. Independent services validate and canonicalize inputs, generate terrain/splines/biomes/scatter/sightlines, and report results; `WorldGenerator` only coordinates those stages, while `Terrain3DAdapter` is the sole plugin boundary.

**Tech Stack:** Godot 4.6, typed GDScript, Terrain3D v1.0.2-stable, Forward+ Vulkan/MoltenVK, Godot Resource files, MultiMeshInstance3D, FastNoiseLite, SHA-256 via `HashingContext`.

**Spec:** `docs/superpowers/specs/2026-09-03-world-003-generation-foundation-design.md`

## Global Constraints

- Work only on `codex/world-003-generation-foundation`, based on `719df1498c4ba53196af7f8a71d11e3cba598dc0`.
- Do not modify `godot/scenes/world/World_VerticalSlice_01.tscn`, FT-GD-001A visual content, Build in Public Pack #001, or `godot/addons/terrain_3d/`.
- Do not modify or replace `godot/scenes/game/Game.tscn`; execute it only as a regression target.
- Keep Godot 4.6, Forward+, macOS Vulkan/MoltenVK, and Terrain3D v1.0.2-stable.
- Resource cross-links use stable IDs and registry resolution; no mutual Resource back-references.
- Canonical generation hashes exclude runtime-only fields and sort/quantize all deterministic inputs.
- Sightlines use 32 fixed interior samples, 0.25 m occluder clearance, and `CLEAR <= 0.10`, `PARTIAL <= 0.60`, `BLOCKED > 0.60` thresholds.
- Terrain3D is accessed only through `Terrain3DAdapter`.
- Performance evidence records duration, instances, MultiMeshes, and generated nodes; no FPS or duration gate.
- Debug proxies are `is_debug_proxy = true` and `production_approved = false`; production mode rejects them.
- Do not add gameplay, production art, a final map definition, Blender, image generation, WORLD-004, or FT-GD-002.
- Do not push or create a GitHub Issue or PR.

---

### Task 1: Add the headless test harness and canonical hashing utility

**Files:**
- Create: `godot/tests/world_generation/world_generation_test_runner.gd`
- Create: `godot/tests/world_generation/canonical_hash_test.gd`
- Create: `godot/scripts/world_generation/generation/canonical_data.gd`

**Interfaces:**
- Produces: `CanonicalData.canonicalize(value: Variant) -> Variant`
- Produces: `CanonicalData.to_json(value: Variant) -> String`
- Produces: `CanonicalData.sha256(value: Variant) -> String`
- Produces: a headless runner that discovers and executes test methods in a stable order and exits non-zero on failure.

- [ ] **Step 1: Write failing canonicalization tests**

```gdscript
func test_dictionary_key_order_is_stable() -> void:
    assert_equal(CanonicalData.to_json({"b": 2, "a": 1}), "{\"a\":1,\"b\":2}")

func test_runtime_fields_are_excluded() -> void:
    var left := {"seed": 7, "duration_ms": 1.0, "node_count": 4}
    var right := {"seed": 7, "duration_ms": 999.0, "node_count": 99}
    assert_equal(CanonicalData.sha256(left), CanonicalData.sha256(right))
```

- [ ] **Step 2: Run the new test runner and verify it fails because `CanonicalData` does not exist**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/world_generation/world_generation_test_runner.gd`

Expected: non-zero exit with an unresolved `CanonicalData` reference.

- [ ] **Step 3: Implement canonical recursion, stable dictionary sorting, six-decimal float quantization, vector/transform arrays, runtime-field exclusion, JSON encoding, and SHA-256**

Runtime exclusions are exactly `duration_ms`, `renderer`, `adapter`, `display_server`, `process_id`, `node_instance_id`, `capture_path`, `timestamp`, `generated_node_count`, and `multimesh_count`.

- [ ] **Step 4: Run the canonical tests and verify they pass**

Run the headless command from Step 2; expected: `WORLD003_TEST_RESULT=PASS`.

### Task 2: Implement focused Resource definitions with stable-ID references

**Files:**
- Create: `godot/scripts/world_generation/definitions/map_definition.gd`
- Create: `godot/scripts/world_generation/definitions/biome_definition.gd`
- Create: `godot/scripts/world_generation/definitions/spline_feature_definition.gd`
- Create: `godot/scripts/world_generation/definitions/poi_definition.gd`
- Create: `godot/scripts/world_generation/definitions/world_exclusion_zone.gd`
- Create: `godot/scripts/world_generation/definitions/terrain_control_region.gd`
- Create: `godot/scripts/world_generation/definitions/environment_asset_definition.gd`
- Create: `godot/scripts/world_generation/definitions/environment_asset_registry.gd`
- Create: `godot/scripts/world_generation/definitions/sightline_definition.gd`
- Create: `godot/tests/world_generation/definition_test.gd`

**Interfaces:**
- Produces: typed `Resource` classes with exported fields from the approved design.
- Produces: `MapDefinition.to_canonical_data() -> Dictionary`.
- Produces: stable enum names for spline, POI, exclusion, terrain-region, rotation, and sightline types.
- Consumes: `CanonicalData` for deterministic representations.

- [ ] **Step 1: Write failing Resource construction and canonical-data tests**

```gdscript
func test_map_definition_keeps_stable_ids() -> void:
    var map := MapDefinition.new()
    map.map_id = "foundation_test"
    map.biome_ids = PackedStringArray(["forest", "grassland"])
    assert_equal(map.to_canonical_data().biome_ids, ["forest", "grassland"])
```

- [ ] **Step 2: Run headless tests and confirm Resource classes are unresolved**

- [ ] **Step 3: Implement each Resource with stable IDs rather than cyclic Resource references**

`MapDefinition` owns authoring arrays but cross-links such as sightline endpoints, allowed biomes, and assets remain strings or string arrays. Every Resource exposes deterministic data without runtime objects.

- [ ] **Step 4: Run headless tests and confirm construction and canonical representations pass**

### Task 3: Implement fail-fast definition and registry validation

**Files:**
- Create: `godot/scripts/world_generation/validation/map_definition_validator.gd`
- Create: `godot/tests/world_generation/map_definition_validator_test.gd`

**Interfaces:**
- Consumes: `MapDefinition`, definition registries, and `EnvironmentAssetRegistry`.
- Produces: `validate(map_definition: MapDefinition, registries: Dictionary) -> Array[Dictionary]`.
- Error shape: `{code: String, resource_id: String, field: String, message: String}` sorted by code, ID, and field.

- [ ] **Step 1: Write tests for valid data, invalid map size, duplicate biome/POI/asset IDs, out-of-bounds POI, invalid spline width, and invalid exclusion geometry**

```gdscript
func test_duplicate_biome_id_is_rejected() -> void:
    var errors := validator.validate(fixture.with_duplicate_biome(), fixture.registries)
    assert_has_error(errors, "DUPLICATE_BIOME_ID")
```

- [ ] **Step 2: Run the validator suite and verify all new cases fail**

- [ ] **Step 3: Implement range, uniqueness, bounds, spline, exclusion, stable-reference, and asset validation**

- [ ] **Step 4: Run the suite and verify deterministic fail-fast errors pass**

### Task 4: Implement the asset registry, production gate, context, and report

**Files:**
- Create: `godot/scripts/world_generation/generation/world_generation_context.gd`
- Create: `godot/scripts/world_generation/generation/world_generation_report.gd`
- Create: `godot/tests/world_generation/asset_registry_test.gd`
- Create: `godot/tests/world_generation/generation_report_test.gd`

**Interfaces:**
- `EnvironmentAssetRegistry.build_index() -> Array[Dictionary]`
- `EnvironmentAssetRegistry.resolve(asset_id: String, production_mode: bool) -> Dictionary`
- `WorldGenerationContext.stream_seed(namespace: String, stable_id: String) -> int`
- `WorldGenerationContext.make_rng(namespace: String, stable_id: String) -> RandomNumberGenerator`
- `WorldGenerationReport.deterministic_data() -> Dictionary`
- `WorldGenerationReport.finalize_hash() -> String`

- [ ] **Step 1: Write failing tests for stable lookup, missing IDs, duplicate IDs, debug-proxy rejection, unapproved-asset rejection, RNG namespaces, and runtime-field-independent report hashing**

- [ ] **Step 2: Run and observe the missing implementations**

- [ ] **Step 3: Implement deterministic registry resolution, `MISSING APPROVED ASSET`, local RNG derivation, report fields, and canonical hashing**

- [ ] **Step 4: Run tests and verify all registry/context/report cases pass**

### Task 5: Implement human terrain, spline influence, bounded naturalization, and the Terrain3D Adapter

**Files:**
- Create: `godot/scripts/world_generation/generation/terrain_height_generator.gd`
- Create: `godot/scripts/world_generation/generation/spline_feature_sampler.gd`
- Create: `godot/scripts/world_generation/generation/terrain_3d_adapter.gd`
- Create: `godot/tests/world_generation/terrain_generation_test.gd`
- Create: `godot/tests/world_generation/terrain_3d_adapter_test.gd`

**Interfaces:**
- `TerrainHeightGenerator.generate_designed_samples(context: WorldGenerationContext) -> Dictionary`
- `TerrainHeightGenerator.apply_naturalization(samples: Dictionary, context: WorldGenerationContext) -> Dictionary`
- `SplineFeatureSampler.sample(feature: SplineFeatureDefinition, spacing_m: float) -> PackedVector3Array`
- `SplineFeatureSampler.distance_to_feature(point: Vector3, feature: SplineFeatureDefinition) -> float`
- `Terrain3DAdapter.bind(terrain: Node) -> Dictionary`
- `Terrain3DAdapter.apply_height_samples(samples: Dictionary) -> Dictionary`
- `Terrain3DAdapter.sample_height(position: Vector3) -> float`
- `Terrain3DAdapter.sample_slope_degrees(position: Vector3) -> float`

- [ ] **Step 1: Write failing tests for flat/high/low/slope/valley control regions, spline macro stability, bounded noise, seed-dependent naturalization, and plugin-boundary behavior**

- [ ] **Step 2: Run tests and confirm missing generators/Adapter fail**

- [ ] **Step 3: Implement deterministic human-region composition, fixed spline sampling, and FastNoiseLite micro-variation clamped to configured amplitude**

- [ ] **Step 4: Implement `Terrain3DAdapter` as the only class containing Terrain3D calls and keep all writes inside Sandbox-owned data**

- [ ] **Step 5: Run headless terrain tests and the existing Terrain3D integration scene**

Expected: bounded-noise and macro-layout invariants pass; WORLD-002 reports `WORLD002_RESULT=PASS`.

### Task 6: Implement biome sampling and deterministic scatter

**Files:**
- Create: `godot/scripts/world_generation/placement/biome_sampler.gd`
- Create: `godot/scripts/world_generation/placement/environment_scatter_generator.gd`
- Create: `godot/tests/world_generation/biome_scatter_test.gd`

**Interfaces:**
- `BiomeSampler.resolve(point: Vector3, sample: Dictionary, context: WorldGenerationContext) -> String`
- `EnvironmentScatterGenerator.generate(context: WorldGenerationContext, samples: Dictionary, parent: Node3D) -> Dictionary`
- Scatter result: `{placements: Array, asset_instance_counts: Dictionary, excluded_count: int, invalid_count: int, multimesh_count: int}`.

- [ ] **Step 1: Write failing tests for biome, slope, height, spline, exclusion, POI-clearance, same-seed transform equality, and different-seed naturalization**

- [ ] **Step 2: Run and verify failures occur before implementation**

- [ ] **Step 3: Implement canonical grid traversal, seeded jitter, stable filtering, asset selection, scale, and rotation**

- [ ] **Step 4: Group at least one high-density debug asset into `MultiMeshInstance3D` and forbid per-instance scene nodes**

- [ ] **Step 5: Run tests and verify deterministic transforms and MultiMesh output pass**

### Task 7: Implement fixed-sample sightline validation

**Files:**
- Create: `godot/scripts/world_generation/validation/sightline_validator.gd`
- Create: `godot/tests/world_generation/sightline_validator_test.gd`

**Interfaces:**
- `SightlineValidator.validate(definition: SightlineDefinition, poi_index: Dictionary, height_provider: Callable, occluders: Array) -> Dictionary`
- Result: `{sightline_id: String, classification: String, occluded_samples: int, sample_count: int, occlusion_ratio: float, requirement_met: bool}`.

- [ ] **Step 1: Write exact CLEAR, PARTIAL, and BLOCKED fixtures using 32 samples and threshold boundary cases**

```gdscript
func test_partial_sightline() -> void:
    var result := validator.validate(fixture.sightline, fixture.poi_index, fixture.partial_height_provider, [])
    assert_equal(result.classification, "PARTIAL")
    assert_equal(result.sample_count, 32)
```

- [ ] **Step 2: Run and confirm the missing validator fails**

- [ ] **Step 3: Implement fixed interior samples, 0.25 m clearance comparison, clearance-width occluders, ratio calculation, and fixed thresholds**

- [ ] **Step 4: Run sightline tests and verify classification boundaries pass**

### Task 8: Implement the WorldGenerator coordinator

**Files:**
- Create: `godot/scripts/world_generation/generation/world_generator.gd`
- Create: `godot/tests/world_generation/world_generator_test.gd`

**Interfaces:**
- `WorldGenerator.generate(map_definition: MapDefinition, registries: Dictionary, terrain_adapter: Terrain3DAdapter, output_root: Node3D, options: Dictionary = {}) -> WorldGenerationReport`
- Produces the exact 11-stage order from the design and stops before mutation on validation errors.

- [ ] **Step 1: Write a failing orchestration test with recording fakes**

```gdscript
func test_generation_order_is_fixed() -> void:
    var report := fixture.generator.generate(fixture.map, fixture.registries, fixture.adapter, fixture.output)
    assert_equal(fixture.events, ["validate", "context", "terrain", "regions", "splines", "noise", "biomes", "protect", "scatter", "sightlines", "report"])
    assert_true(report.errors.is_empty())
```

- [ ] **Step 2: Run and verify the coordinator test fails**

- [ ] **Step 3: Implement orchestration without moving subsystem behavior into the coordinator**

- [ ] **Step 4: Add fail-fast and idempotent generated-root replacement tests and make them pass**

### Task 9: Build the isolated Sandbox Resources, proxies, scene, cameras, and optional overlay

**Files:**
- Create: `godot/data/world/tests/foundation_world_generation_test.tres`
- Create: `godot/data/world/tests/foundation_biomes.tres`
- Create: `godot/data/world/tests/foundation_environment_asset_registry.tres`
- Create: `godot/scenes/world/tests/debug_tree_proxy.tscn`
- Create: `godot/scenes/world/tests/debug_bamboo_proxy.tscn`
- Create: `godot/scenes/world/tests/debug_rock_proxy.tscn`
- Create: `godot/scenes/world/tests/world_generation_foundation_test.gd`
- Create: `godot/scenes/world/tests/WorldGenerationFoundationTest.tscn`
- Create: Sandbox-owned Terrain3D data under `godot/scenes/world/tests/data/foundation_terrain_data/` only when required by Terrain3D.

**Interfaces:**
- Sandbox controller consumes the test `MapDefinition`, registry, and Terrain3D node, runs once on scene initialization, prints a machine-readable report, and exits under `WORLD003_AUTOCLOSE=1`.
- Environment seed override: `WORLD003_SEED`.

- [ ] **Step 1: Add a scene-load test and verify it fails before the scene exists**

- [ ] **Step 2: Create the approximately 100 m by 100 m test data with seven biome types, River, Coast, four or more POIs, two or more exclusions, and three or more sightlines**

- [ ] **Step 3: Create debug proxies with registry flags `is_debug_proxy = true` and `production_approved = false`**

- [ ] **Step 4: Assemble the isolated Terrain3D Sandbox and fixed `ReviewCamera_Spawn`, `ReviewCamera_Forest`, `ReviewCamera_StoneHill`, and `ReviewCamera_Ruins` nodes**

- [ ] **Step 5: Add the small engineering overlay only if it remains isolated and does not add game UI dependencies**

- [ ] **Step 6: Run headless scene-load validation and verify there are no missing resources or script errors**

### Task 10: Complete the 30-case test suite and runtime evidence

**Files:**
- Modify: `godot/tests/world_generation/world_generation_test_runner.gd`
- Modify: focused test files from Tasks 1–9.

**Interfaces:**
- Produces a summary with `tests`, `passed`, `failed`, and `WORLD003_TEST_RESULT`.

- [ ] **Step 1: Map each of the 30 required acceptance cases to a named test method and add any missing test first**

- [ ] **Step 2: Run the complete headless suite**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/world_generation/world_generation_test_runner.gd`

Expected: at least 30 named tests, zero failures, `WORLD003_TEST_RESULT=PASS`.

- [ ] **Step 3: Run editor/import validation**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --editor --headless --path godot --quit-after 8`

Expected: exit 0, no parse error, missing dependency, or fatal shader error.

- [ ] **Step 4: Run Seed A three separate times through the Vulkan Sandbox**

Run three times: `WORLD003_AUTOCLOSE=1 WORLD003_SEED=3003 /Applications/Godot.app/Contents/MacOS/Godot --path godot --editor-pid 0 res://scenes/world/tests/WorldGenerationFoundationTest.tscn`

Expected: all three outputs have the same generation hash, instance counts, and sightline results.

- [ ] **Step 5: Run Seed B and verify only naturalization output changes**

Run: `WORLD003_AUTOCLOSE=1 WORLD003_SEED=4004 /Applications/Godot.app/Contents/MacOS/Godot --path godot --editor-pid 0 res://scenes/world/tests/WorldGenerationFoundationTest.tscn`

Expected: generation hash differs; canonical POI positions and River control points equal Seed A.

- [ ] **Step 6: Run the existing Terrain3D integration scene and unchanged Game scene**

Run: `WORLD002_FAST=1 WORLD002_AUTOCLOSE=1 /Applications/Godot.app/Contents/MacOS/Godot --path godot res://scenes/world/tests/Terrain3DIntegrationTest.tscn`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit-after 8 res://scenes/game/Game.tscn`

Expected: WORLD-002 PASS; Game scene exits without parse, dependency, or fatal shader error.

### Task 11: Document the public foundation and perform the isolation audit

**Files:**
- Create: `godot/docs/world-generation.md`
- Modify: `docs/superpowers/plans/2026-09-03-world-003-generation-foundation.md` only to mark completed checkboxes.

**Interfaces:**
- Documents architecture, data model, generation order, Terrain3D boundary, biome/spline/registry models, determinism, production gate, sightlines, Sandbox, limitations, and WORLD-004 interface.

- [ ] **Step 1: Write concise implementation documentation without restating the full Free Tower PRD**

- [ ] **Step 2: Verify protected file hashes against base commit**

Run: `git diff 719df1498c4ba53196af7f8a71d11e3cba598dc0 -- godot/scenes/world/World_VerticalSlice_01.tscn godot/scenes/game/Game.tscn godot/addons/terrain_3d docs/build-in-public docs/devlog docs/design/decisions`

Expected: no output.

- [ ] **Step 3: Run final Git and contamination checks**

Run: `git status --short`, `git diff --check`, and `git diff --stat 719df1498c4ba53196af7f8a71d11e3cba598dc0`.

Expected: only WORLD-003 scripts, Resources, Sandbox, tests, design/plan documents, and `godot/docs/world-generation.md`.

- [ ] **Step 4: Precisely stage implementation files and create the required local commit**

Run explicit `git add` paths for WORLD-003-owned files, then:

```bash
git commit -m "feat: add world generation foundation"
```

- [ ] **Step 5: Verify the final branch without pushing**

Run: `git status --short`, `git log --oneline --decorate -5`, and `git branch --show-current`.

Expected: clean worktree on `codex/world-003-generation-foundation`, local commits present, no remote branch created.
