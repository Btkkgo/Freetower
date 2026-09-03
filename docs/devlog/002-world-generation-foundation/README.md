# Free Tower Devlog #002 — Building a Deterministic World Generation Foundation

[简体中文](./README.zh-CN.md)

## From Terrain to a World-Building System

WORLD-002 proved that Terrain3D `v1.0.2-stable` could run safely in the Free Tower Godot project on the approved macOS Vulkan path. WORLD-003 answers the next question: how can an AI-assisted workflow build a designed world without turning the map into random procedural terrain?

The result is a reusable world-generation foundation. It is an engineering system, not the final Free Tower map.

## Human Layout First

Free Tower uses **Human Layout + Deterministic Procedural Naturalization**.

Humans author the world's identity:

- points of interest and exploration structure;
- river and coast routes;
- landmarks and major elevations;
- exclusion zones and important sightlines.

Procedural systems are limited to naturalizing that approved structure through micro-terrain, vegetation, rock, density, scale, rotation, and asset-selection variation. A seed may change those details, but it may not move authored POIs, rewrite the river route, or replace the macro map design.

## Resource-Driven Architecture

WORLD-003 splits world data into focused Godot Resources: `MapDefinition`, `BiomeDefinition`, `SplineFeatureDefinition`, `POIDefinition`, `WorldExclusionZone`, `TerrainControlRegion`, `EnvironmentAssetDefinition`, `EnvironmentAssetRegistry`, and `SightlineDefinition`.

`WorldGenerator` coordinates independent validation, terrain, biome, scatter, sightline, and reporting stages. Stable IDs and registries resolve relationships without circular Resource dependencies. Terrain3D access is isolated behind `Terrain3DAdapter`, keeping the generation pipeline independent from the terrain plugin API.

Generation hashes are built from canonicalized deterministic data. Runtime-only fields such as timing, renderer details, generated node counts, and capture paths are excluded.

## Determinism

Seed A (`3003`) produced the same generation hash in three independent runs:

`3f10628f8db0a69e3e5bcf1068edeeaa15436c0150240870a704e70436ae6e50`

Seed B (`4004`) produced a different naturalization hash:

`95e25d8db32c5734e88725933d53a642f27d58250514c0559be9953b5a658b20`

Across both seeds, the authored POI hash remained `16625905bde4b97e2b86123a2c33f29742cb3af7845854f79ed357f4392f9d8d`, and the river-control-point hash remained `938c4eef79d0453287c1d2ce7690642bfbef4ecc303298191d3e7fa2c1b8082f`.

This gives us reproducible bugs, reviewable map changes, controlled iteration, and a foundation that could support future server or multiplayer consistency. Multiplayer is not implemented.

## Biomes and Scatter

The engineering Sandbox covers Grassland, Forest, Bamboo, RockHill, RiverBank, Coast, and Ruins. Scatter placement respects biome, height, slope, water distance, POI clearance, exclusion zones, and spline vegetation exclusion.

High-density environment instances are grouped into MultiMeshes instead of becoming thousands of independent scene nodes. Seed A generated 3,252 instances using three MultiMeshes and three generated nodes; Seed B generated 3,286 instances.

## Production Asset Gate

WORLD-003 deliberately refuses to treat debug geometry as production art. Production mode rejects debug proxies and assets without explicit production approval.

The current state is:

- **TECHNICALLY VALID**
- **MISSING APPROVED ASSETS**

The Sandbox trees, bamboo, and rocks remain engineering proxies. This boundary prevents a functioning programmer-art scene from being mistaken for completed environment art.

## Sightline Validation

Sightlines use 32 fixed interior samples and a 0.25 m occlusion margin. Occlusion ratios at or below 0.10 are `CLEAR`; ratios at or below 0.60 are `PARTIAL`; larger ratios are `BLOCKED`.

This deterministic system will allow WORLD-004 to protect views such as Spawn → Free Tower, Stone Hill → Free Tower, Forest → partial Free Tower visibility, and Ruins → Free Tower. WORLD-003 does not yet contain the production Free Tower Map Definition.

## Validation

- 44 / 44 tests passed.
- Seed A reproduced the same hash in three independent launches.
- Seed B changed naturalization while preserving authored POIs and river control points.
- Terrain3D integration passed.
- Forward+ / Vulkan runtime passed on Apple M4.
- The Sandbox passed 3 / 3 launches.
- Existing `Game.tscn` regression passed.
- The existing Vertical Slice remained unchanged.

No hard FPS or generation-time pass/fail limit is defined in WORLD-003. Generation is one-shot, never regenerated continuously in `_process()`. The report records duration, instance count, MultiMesh count, and generated node count as a baseline for later work.

## What WORLD-003 Is Not

WORLD-003 is not final terrain, final art, production vegetation, a final Free Tower landmark design, or gameplay implementation. Human review concluded **TECHNICAL PASS**, not final map approval and not final art approval.

## Next

WORLD-004 will rebuild the Phase 0 Vertical Slice by applying this foundation to the actual Free Tower map. That work has not started in this devlog.
