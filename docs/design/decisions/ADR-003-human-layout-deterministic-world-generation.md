# ADR-003 — Human Layout with Deterministic Procedural Naturalization

- Status: Accepted
- Date: 2026-09-03

## Context

Free Tower requires intentional exploration routes, stable landmarks, civilization spaces, and protected views of its central tower. Fully random procedural generation would allow seeds to rewrite the identity of the world and undermine deliberate level design.

The project still benefits from procedural variation, but only where that variation can be reproduced, reviewed, and constrained by authored intent.

## Decision

Free Tower adopts **Human Layout + Deterministic Procedural Naturalization**.

The macro world structure is human-authored. Authored data includes:

- points of interest;
- spline routes for rivers, coasts, and paths;
- terrain control regions;
- sightlines;
- exclusion zones;
- landmarks and major map structure.

Procedural systems may vary:

- micro-terrain variation;
- environment scatter and density;
- scale and rotation;
- asset selection.

All procedural variation must be deterministic for a given seed and generation revision. Stable IDs and registries resolve Resource relationships. Terrain3D access remains isolated behind an adapter. Generation hashes use canonicalized deterministic data and exclude runtime-only fields.

Changing a seed may change naturalization, but it must not change authored POIs, river control points, or macro map design.

## Consequences

Positive consequences:

- Bugs and generated results are reproducible.
- Humans retain control over exploration and landmark placement.
- Map changes can be reviewed and compared as authored data.
- Independent stages are testable without requiring the full runtime.
- Stable landmarks and sightlines can be validated automatically.

Tradeoffs:

- Maps require explicit authoring instead of emerging automatically from a random seed.
- The system is less automatic than fully random world generation.
- Asset registries, stable IDs, validation, and production-approval metadata must be maintained.
- Procedural freedom is intentionally constrained by level-design requirements.
