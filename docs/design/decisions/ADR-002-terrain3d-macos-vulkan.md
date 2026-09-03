# ADR-002 — Terrain3D on macOS Uses Vulkan / MoltenVK

- Status: Accepted with platform constraint
- Date: 2026-09-03

## Context

Godot 4.6 on Apple Silicon defaults to Metal. Terrain3D `v1.0.2-stable` does not officially support Metal, so a compatibility spike was performed on an Apple M4 rather than treating a successful launch as sufficient evidence.

Forward+ with Metal ran on the current machine, but it is not an approved Terrain3D path. Forward+ with Vulkan through MoltenVK passed Editor, runtime, terrain editing, persistence, and LOD validation. Compatibility / OpenGL3 produced large black terrain areas on the current development machine.

## Decision

Terrain3D development for Free Tower on macOS uses:

- Godot: 4.6 Stable
- Rendering Method: Forward+
- Rendering Device Driver: Vulkan
- Runtime on Apple Silicon: MoltenVK
- Terrain3D: `v1.0.2-stable`

Rejected paths:

- Metal is not approved because Terrain3D does not officially support it.
- Compatibility / OpenGL3 is rejected on the current development machine because of black terrain rendering.

## Consequences

- The macOS project setting explicitly requests Vulkan.
- The macOS-specific setting does not override Windows.
- Windows runtime is **NOT TESTED ON THIS MACHINE**.
- Every future Terrain3D upgrade requires renewed compatibility validation.

## Evidence

- [Terrain3D integration and platform guard](../../../godot/docs/terrain3d.md)
- [Devlog #001 — Rebuilding the World-Building Pipeline](../../devlog/001-world-building-pipeline/README.md)
