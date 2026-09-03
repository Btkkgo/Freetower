# WORLD-003 World Generation Foundation Design

**Status:** Approved

**Date:** 2026-09-03

**Base commit:** `719df1498c4ba53196af7f8a71d11e3cba598dc0`

**Branch:** `codex/world-003-generation-foundation`

## Purpose

WORLD-003 establishes a data-driven, deterministic, human-layout-first world-generation foundation for the Godot project. It produces an engineering Sandbox and reusable interfaces for WORLD-004; it does not rebuild the Phase 0 map or create production art.

The governing model is:

`Human-authored macro layout + deterministic procedural naturalization`

FastNoiseLite may add bounded micro-variation. It must not choose POIs, biome regions, river or coast macro geometry, landmark positions, routes, or sightlines.

## Fixed Technical Baseline

- Godot `4.6 Stable`.
- Forward+ renderer.
- macOS rendering driver `Vulkan / MoltenVK`.
- Terrain3D `v1.0.2-stable`.
- No Terrain3D upgrade or vendor-source modification.
- No Metal or Compatibility/OpenGL3 fallback.
- No Blender dependency.
- No image generation.

## Protected Scope

The implementation must not modify:

- `godot/scenes/world/World_VerticalSlice_01.tscn`;
- existing FT-GD-001A visual content;
- `godot/scenes/game/Game.tscn` except that it is executed as an unchanged regression target;
- Terrain3D files under `godot/addons/terrain_3d/`;
- Build in Public Pack #001, Discussion #8, historical issues, or PR #7.

No gameplay, production map, production art, Bitcoin identity, Tower design, or WORLD-004 definition is in scope.

## Architecture

The implementation uses a Resource data graph plus focused, independently testable generation stages. `WorldGenerator` is an orchestration boundary only. It invokes each stage in a fixed order and passes a `WorldGenerationContext`; it does not absorb terrain, biome, scatter, registry, sightline, or reporting logic.

Generation order:

1. Validate Resources and registry references.
2. Initialize `WorldGenerationContext` with a local seeded RNG.
3. Generate base terrain samples.
4. Apply human-authored terrain control regions.
5. Apply river, coast, and path spline influence.
6. Add bounded FastNoiseLite naturalization.
7. Resolve biome samples.
8. Protect POIs and exclusion zones.
9. Produce deterministic asset placements and MultiMeshes.
10. Validate sightlines using fixed samples and thresholds.
11. Canonicalize deterministic output and produce `WorldGenerationReport`.

## Resource Data Graph

The data model is composed of focused Godot Resources:

- `MapDefinition`: map metadata, seed, bounds, height range, resolution, spawn, stable child IDs, and top-level generation settings.
- `BiomeDefinition`: biome constraints, priority, density, stable asset tags, exclusions, noise settings, and Sandbox-only debug color.
- `SplineFeatureDefinition`: River, Coast, or Path control points and influence parameters.
- `POIDefinition`: human-authored POI type, transform intent, clearance, tags, buildability, and debug visibility.
- `WorldExclusionZone`: Circle or Box exclusion geometry, tags, and purpose.
- `TerrainControlRegion`: Flat, Raise, Lower, Slope, Plateau, or Valley macro-height intent.
- `EnvironmentAssetDefinition`: stable asset metadata, `PackedScene`, placement constraints, LOD/collision profiles, revision/source evidence, debug-proxy flag, and production approval.
- `EnvironmentAssetRegistry`: deterministic lookup of asset definitions by stable asset ID.
- `SightlineDefinition`: stable source/target POI IDs, required visibility, allowed occlusion, clearance width, sample count, and debug visibility.

### Stable references and cycle prevention

Resource relationships prefer stable string IDs resolved through registries. Map, biome, spline, POI, asset, and sightline records do not maintain mutual Resource back-references. The top-level map owns ordered Resource arrays where authoring requires Inspector visibility, while cross-links use IDs such as `source_poi_id`, `target_poi_id`, `allowed_biome_ids`, and `asset_tags`.

Validation builds immutable lookup dictionaries for one generation run. Missing IDs, duplicate IDs, and ambiguous registry entries fail before scene mutation. This keeps the Resource graph acyclic and makes serialization and hashing stable.

## Validation and Failure Model

`MapDefinitionValidator` returns a deterministic array of structured error dictionaries containing `code`, `resource_id`, `field`, and `message`. `WorldGenerator` stops before terrain or scene mutation when any error exists.

Validation covers:

- non-empty IDs and valid integer seed;
- positive map bounds and terrain resolution;
- ordered terrain height range;
- spawn and POIs inside bounds;
- spline type, minimum control-point count, finite points, positive width, and non-negative influence radii;
- unique biome, spline, POI, exclusion-zone, terrain-region, sightline, and asset IDs;
- valid Circle/Box exclusion geometry;
- resolvable stable references;
- valid slope, height, scale, density, distance, and noise ranges;
- production asset policy.

Errors are sorted by `code`, `resource_id`, and `field` so repeated invalid inputs produce identical reports.

## Determinism and Canonical Hashing

Every random stream is derived from:

`map seed + generation revision + stable subsystem namespace + stable resource ID`

The implementation never uses global random state. Independent namespaces prevent adding one biome or asset from perturbing unrelated streams.

The generation hash is SHA-256 over a canonical UTF-8 JSON representation. Canonicalization follows these rules:

- dictionary keys sorted lexicographically;
- ID-addressed Resource arrays sorted by stable ID;
- placement arrays sorted by biome ID, asset ID, then quantized transform;
- vectors and transforms represented as ordered numeric arrays;
- floating-point values quantized to six decimal places before serialization;
- booleans, integers, strings, arrays, and dictionaries use explicit JSON-compatible values;
- no object instance IDs, Resource UIDs, absolute paths, timestamps, frame counts, unordered dictionary iteration, or locale-formatted values.

Runtime-only fields are excluded from the hash, including:

- `duration_ms`;
- renderer, adapter, display server, and process metadata;
- node instance IDs;
- transient warning presentation text;
- capture paths and timestamps;
- runtime scene-tree counts used only for performance evidence.

Authored POI positions and authored spline control points are included in canonical input data and remain unchanged across seed variants. Seed changes may alter only permitted naturalization, asset selection, transforms, and other procedural output.

## Terrain3D Adapter

Terrain3D is accessed only through `Terrain3DAdapter`. No definition, generator, sampler, validator, or report class calls Terrain3D APIs directly.

The Adapter:

- verifies `ClassDB.class_exists("Terrain3D")` and receives a Sandbox-owned Terrain3D node;
- validates region size, vertex spacing, bounds, and data availability;
- accepts deterministic height samples from the terrain pipeline;
- applies samples only to the Sandbox-owned Terrain3D data;
- exposes height and normal/slope sampling through project-owned methods;
- returns structured status and metrics without leaking Terrain3D objects into definitions;
- never writes into WORLD-002 or production-map terrain data;
- never modifies plugin or vendor files.

The base height field is produced from human control regions and spline influences. FastNoiseLite runs last with a configured maximum amplitude, and tests verify every naturalized height remains within that bound relative to the designed height.

## River and Coast Pipeline

`SplineFeatureDefinition` is the single authored source for River, Coast, and Path geometry. A deterministic spline sampler generates fixed-distance samples and signed influence distances.

River output coordinates terrain depression, bed profile, bank falloff, RiverBank biome influence, vegetation exclusion, rock influence, and future water/navigation metadata. Coast output coordinates shoreline falloff, vegetation reduction, and future beach/rock/water metadata. WORLD-003 renders only explicit debug lines or markers; it does not implement production water or coast art.

## Biome Sampling

`BiomeSampler` resolves candidates using human biome regions first, then filters and ranks by:

- biome priority;
- height and slope;
- distance to River and Coast splines;
- POI clearance and exclusion zones;
- allowed bounded noise variation.

Noise may soften a supplied boundary but may not create a new biome region. Debug colors are marked Sandbox-only and do not represent production materials.

## Asset Registry and Production Gate

Generators request assets by stable `asset_id` or tag query. They do not contain environment asset paths.

Registry lookup order is deterministic. If `production_mode` is true, the registry rejects records where `is_debug_proxy` is true or `production_approved` is false, returning `MISSING APPROVED ASSET` with the requested stable ID. Sandbox debug assets are explicitly named and configured with:

- `is_debug_proxy = true`;
- `production_approved = false`.

No proxy can satisfy a production asset request or scenic approval gate.

## Deterministic Scatter and MultiMesh

`EnvironmentScatterGenerator` creates a stable candidate grid with seeded jitter. Candidates are processed in canonical cell order and filtered by biome, height, slope, spline distances, POI clearance, and exclusion zones. Asset selection, scale, and rotation use namespaced local RNG streams.

The result records asset ID, biome ID, transform, excluded count, invalid count, instance count, seed namespace, and deterministic hash material. High-density debug vegetation is grouped into at least one `MultiMeshInstance3D`; thousands of independent `MeshInstance3D` nodes are prohibited.

## Sightline Algorithm

Sightline validation uses a fixed sampling algorithm rather than physics timing or frame-dependent ray results:

1. Resolve source and target by stable POI ID.
2. Sample exactly `32` evenly spaced interior points along the source-to-target segment; endpoints are excluded.
3. At each sample, compare the expected line height with deterministic terrain height plus registered deterministic occluder height inside half the configured clearance width.
4. A sample is occluded when the occluder height is at least `0.25 m` above the expected line height.
5. Compute `occlusion_ratio = occluded_samples / 32.0`.
6. Classify `CLEAR` when the ratio is `<= 0.10`, `PARTIAL` when it is `> 0.10` and `<= 0.60`, and `BLOCKED` when it is `> 0.60`.

The constants are project-owned defaults and serialized into canonical report inputs. A sightline may additionally fail its authored `required_visibility` or `max_allowed_occlusion` requirement even when its raw classification is valid.

## Generation Report

`WorldGenerationReport` contains:

- map ID, seed, and generation revision;
- terrain and Terrain3D Adapter status;
- biome counts;
- per-asset instance counts;
- spline and POI counts;
- sightline results;
- warnings and errors;
- generation hash;
- performance evidence.

Performance evidence records only:

- generation duration in milliseconds;
- total generated instance count;
- MultiMesh count;
- generated node count.

There is no FPS threshold, frame-time threshold, or millisecond pass/fail gate in WORLD-003. Duration and node-count evidence is excluded from the generation hash.

## Sandbox

`godot/scenes/world/tests/WorldGenerationFoundationTest.tscn` is an engineering validation scene. It does not replace `Game.tscn` or the existing Vertical Slice.

Its approximately 100 m by 100 m test definition contains all seven required biome types, one River spline, one Coast spline, at least four authored POIs, at least two exclusions, at least three sightlines, designed flat/slope/high/low/valley terrain features, and clearly labeled debug proxies. It includes fixed Spawn, Forest, Stone Hill, and Ruins review cameras with recorded transforms and FOV.

The Sandbox may display a minimal debug overlay if it remains isolated and reports only map ID, seed, generation hash, terrain status, instance counts, and sightlines. It is not formal game UI and is not subject to art review.

## Testing Strategy

A minimal Godot headless test runner executes focused Resource and service tests without adding a third-party test framework. Tests cover all 30 cases listed in WORLD-003, including validation failures, registry gates, deterministic hashing, seed invariants, scatter constraints, MultiMesh creation, sightline classifications, scene loading, Terrain3D availability, script/dependency checks, and unchanged `Game.tscn` regression.

Runtime evidence runs the Sandbox three separate times with Seed A and once with Seed B. Seed A hashes must match. Seed B must change permitted naturalization output while authored POI positions and River control points remain byte-for-byte canonical-equivalent.

The existing Vertical Slice file hash is captured before implementation and compared after all work. Godot editor/import validation, headless tests, Vulkan/MoltenVK Sandbox runtime, and existing `Game.tscn` startup are separate acceptance checks.

## Documentation and WORLD-004 Boundary

`godot/docs/world-generation.md` documents the implemented architecture, data model, generation order, Terrain3D boundary, biome and spline models, registry gate, determinism, sightlines, Sandbox, known limitations, and the public WORLD-004 interface.

WORLD-004 will create `Phase0VerticalSliceMapDefinition` using these Resource types. WORLD-003 must not create that Resource or encode final Spawn Grassland, Forest, Bamboo, River, Stone Hills, Camp, Ancient Ruins, Coast, or Free Tower layout coordinates.

## Completion State

WORLD-003 may be reported `TECHNICALLY VALID` only after all required data, generation, Terrain3D, deterministic, MultiMesh, sightline, Sandbox, regression, and Git-isolation evidence passes. It does not produce production art and cannot be reported `FINAL ART APPROVED`.

The final implementation is committed locally with `feat: add world generation foundation`. No push, GitHub Issue, GitHub PR, WORLD-004, or FT-GD-002 work is permitted.
