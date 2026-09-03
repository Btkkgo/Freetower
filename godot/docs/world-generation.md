# WORLD-003 World Generation Foundation

WORLD-003 provides the Godot-side foundation for human-authored, deterministic world generation. It creates an engineering Sandbox only. It does not rebuild the Free Tower Vertical Slice and does not produce production art.

## Architecture

The system uses a Resource data graph and focused generation stages. Cross-resource relationships use stable IDs so Resources do not form cycles. `WorldGenerator` coordinates stages but leaves validation, height generation, splines, biomes, scatter, Terrain3D access, sightlines, and hashing in separate services.

Generation order:

1. Validate data and registry references.
2. Initialize a local seeded context.
3. Generate base terrain samples.
4. Apply human terrain regions.
5. Apply River and Coast spline influence.
6. Add bounded FastNoiseLite micro-variation.
7. Resolve biomes.
8. Protect POIs and exclusion zones.
9. Generate deterministic asset placements and MultiMeshes.
10. Validate sightlines.
11. Canonicalize deterministic output and create a report.

## Data model

`MapDefinition` is the map-design entry point. It owns authored collections of `BiomeDefinition`, `SplineFeatureDefinition`, `POIDefinition`, `WorldExclusionZone`, `TerrainControlRegion`, and `SightlineDefinition`. Cross-links such as sightline endpoints and allowed biomes remain stable string IDs.

The Sandbox definition is `res://data/world/tests/world_generation_foundation_test.tres`. It is approximately 100 m by 100 m and contains the seven foundation biomes, River and Coast splines, five POIs, two exclusion zones, four sightlines, and human terrain controls. Its coordinates are test data, not the Phase 0 layout.

Invalid definitions fail before scene mutation. Validation reports stable error dictionaries with a code, Resource ID, field, and message.

## Terrain3D boundary

`Terrain3DAdapter` is the only project class that calls Terrain3D APIs. It verifies the installed class, binds a Sandbox-owned `Terrain3D` node, creates in-memory regions when required, applies deterministic height samples, updates height maps, and exposes height/slope samples to project code.

The Adapter never writes to the WORLD-002 integration data, the existing Vertical Slice, or Terrain3D vendor files. The approved baseline remains Godot 4.6, Forward+, macOS Vulkan/MoltenVK, and Terrain3D v1.0.2-stable.

## Human terrain and naturalization

`TerrainControlRegion` expresses Flat, Raise, Lower, Slope, Plateau, and Valley intent. These human controls determine the macro height field. River and Coast definitions then apply their authored depth and falloff.

FastNoiseLite runs only after those controls. Its seed, frequency, and maximum amplitude come from `MapDefinition`; tests verify naturalized height never exceeds the configured amplitude relative to designed height. Changing the seed cannot move authored POIs or spline control points.

## Biomes and splines

`BiomeSampler` combines human biome regions with priority, height, slope, and water-distance constraints. Noise does not create biome locations. `debug_color` is Sandbox-only and is not a production material definition.

`SplineFeatureDefinition` represents River, Coast, and Path control points and influence parameters. The foundation sampler uses deterministic fixed-distance linear segment sampling. River influence coordinates terrain depression, bank falloff, RiverBank sampling, vegetation exclusion, and rock metadata. Coast influence exposes the corresponding shoreline and future transition boundary. Production water, coast materials, and navigation are not implemented here.

## Asset registry and production gate

Environment generation resolves stable asset IDs through `EnvironmentAssetRegistry`; generators do not embed environment asset paths. Registry results are sorted for deterministic lookup.

When `production_mode` is true, debug proxies and unapproved assets return `MISSING APPROVED ASSET`. All WORLD-003 proxy records are explicitly `is_debug_proxy = true` and `production_approved = false`. They validate the pipeline only and cannot satisfy a production or visual-approval gate.

## Deterministic scatter

`EnvironmentScatterGenerator` processes candidates in canonical grid order. Namespaced local RNG streams control density, asset selection, scale, and rotation. Candidates are filtered by biome, asset height/slope constraints, exclusion zones, POI clearance, and Spline vegetation clearance.

Repeated proxy instances are grouped by stable asset ID into `MultiMeshInstance3D` nodes. The report records per-asset counts, excluded and invalid candidates, total instances, MultiMesh count, and generated node count.

## Canonical generation hash

The generation hash is SHA-256 over canonical JSON. Dictionary keys and stable-ID Resource arrays are sorted, vectors and transforms become ordered arrays, and floats are quantized to six decimal places.

The hash excludes runtime-only fields such as duration, renderer/device metadata, process and instance IDs, capture paths, timestamps, generated node counts, and MultiMesh counts. Authored POIs, authored River data, naturalized heights, deterministic placements, and sightline results remain hash inputs.

## Sightlines

Every sightline uses 32 evenly spaced interior samples. A sample is occluded when deterministic terrain or registered occluder height is at least 0.25 m above the expected line. Classification thresholds are:

- `CLEAR`: occlusion ratio at or below 0.10;
- `PARTIAL`: above 0.10 and at or below 0.60;
- `BLOCKED`: above 0.60.

The validator separately reports whether the classification and ratio meet the authored requirement.

## Sandbox and review cameras

Run `res://scenes/world/tests/WorldGenerationFoundationTest.tscn`. It generates once at scene initialization and uses a real Terrain3D node, debug landmark marker, deterministic proxy scatter, and an engineering overlay.

Fixed review cameras are provided for Spawn, Forest, Stone Hill, and Ruins. Their transforms and FOV are stored in the Sandbox scene. They preserve a future review interface but do not make WORLD-003 an art-review task. The report state is `ENGINEERING_VALIDATION_ONLY`, never `FINAL ART APPROVED`.

`WORLD003_SEED` overrides the test seed. `WORLD003_AUTOCLOSE=1` prints a machine-readable report and exits for automation.

## Performance evidence

WORLD-003 records generation duration, generated instance count, MultiMesh count, and generated node count. It defines no FPS, frame-time, or duration pass/fail threshold. Generation is explicit and one-shot; it does not regenerate every frame.

## Tests

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/world_generation/world_generation_test_runner.gd
```

The suite covers definition validation, duplicate IDs, bounds, spline errors, registry gates, canonical hashing, RNG namespaces, human-layout seed invariants, bounded naturalization, biome constraints, exclusion-aware scatter, MultiMesh creation, fixed sightline classifications, the Terrain3D Adapter, coordinator order, and Sandbox loading.

## Current limitations

- Human biome and terrain regions use simple rectangular controls; there is no polygon editor.
- Spline sampling is deterministic linear interpolation between authored control points; curve handles are not exposed yet.
- Terrain3D regions are generated in memory for the Sandbox and are not production terrain assets.
- Debug proxies have no production approval, asset LOD, authored collision, or scenic acceptance.
- Water shaders, beach/rock transitions, navigation baking, gameplay, and production-map generation are outside WORLD-003.
- Runtime warnings inherited from the current project/user-data naming and Terrain3D/Godot backend are reported separately from fatal errors.

## WORLD-004 interface

WORLD-004 should create a new `Phase0VerticalSliceMapDefinition` using the Resources and registries defined here. That future authored definition will describe Spawn Grassland, Forest, Bamboo, River, Stone Hills, Suggested Camp, Ancient Ruins, Coast, and Free Tower sightlines. WORLD-004 should supply approved production assets and layout approval, then invoke `WorldGenerator` with production-mode registry gates enabled.
