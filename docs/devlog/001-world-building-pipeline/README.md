# Free Tower Devlog #001 — Rebuilding the World-Building Pipeline

From AI-generated whiteboxes to a controlled Godot world-building workflow.

[简体中文](./README.zh-CN.md)

## Why We Restarted

Free Tower is being rebuilt around a human-directed, AI-assisted development process. The goal is not to ask an agent to autonomously “finish the game.” Humans retain control of product direction, gameplay, architecture, art direction, visual acceptance, and major technical decisions. Codex executes bounded tasks whose implementation and evidence can be reviewed before the next task begins.

Our working loop is deliberately explicit: human design, scoped Codex task, implementation, runtime and visual inspection, human approval, and only then the next task.

## The First Godot Whitebox

FT-GD-001 established the Godot 4.6 foundation and an approximately 100 m × 100 m vertical slice containing a spawn grassland, forest, stone hills, river, coast, ancient ruins, and a distant Free Tower landmark.

The engineering result passed. Godot launched, the scenes worked, the spatial relationships existed, and runtime and headless checks completed successfully. Human visual review rejected it. The scene communicated the layout, but it looked like a technical blockout made from primitive geometry rather than a credible adventure-game world.

The original technical whitebox screenshot was reviewed during development, but is not currently stored in the public devlog package.

## Trying to Fix the Art With More Code

FT-GD-001A added stylized grass, procedural tree and rock proxies, an Ancient Banyan proxy, curved water and coast transitions, a stylized water shader, soft toon materials, improved sky and lighting, and a redesigned Free Tower proxy.

![FT-GD-001A scenic prototype runtime](../../../godot/docs/visual-review/FT-GD-001A/spawn-view.png)

The result was technically better and passed its automated checks. Human visual review rejected it again. It still relied too heavily on procedural proxy art and did not reach the quality bar for Free Tower's visual identity.

A coding agent can improve geometry and implementation, but that does not automatically give it the judgment or production assets of an environment art team.

## Concept Art Was Not Enough

ART-001 moved visual exploration into image generation. Four environment concepts improved composition, atmosphere, natural scenery, spatial depth, and forest and river readability.

Their formal status is **HUMAN REVIEW: REJECTED**. They did not express a sufficiently strong Bitcoin-native identity, and the Free Tower landmark did not communicate the project's idea of freedom clearly enough. The images remain exploration references, not approved production ground truth, and are intentionally not published in this pack.

## Changing the Pipeline

We stopped treating “generate a nicer image” or “add more procedural meshes” as the solution. Two specialized Codex skills now separate visual judgment from implementation:

- `free-tower-art-director` evaluates whether a visual result works and keeps human approval explicit.
- `free-tower-world-builder` translates approved layouts into a real Godot world-building workflow.

Concept art now supplies visual reference. The map itself needs a controlled terrain system, an asset pipeline, deliberate points of interest, runtime review, and human approval.

## Choosing a Real Terrain System

Terrain3D `v1.0.2-stable` was evaluated in an isolated compatibility spike on an Apple M4 running Godot 4.6 on macOS.

| Path | Result | Decision |
| --- | --- | --- |
| Forward+ / Metal | Ran on this machine | Not approved because Terrain3D does not officially support Metal |
| Forward+ / Vulkan / MoltenVK | Passed | Approved macOS development path |
| Compatibility / OpenGL3 | Large black terrain areas | Rejected on the current development machine |

The Vulkan path passed Editor and runtime validation, three independent launches, terrain raise/lower, smoothing, texture painting, persistence, and LOD checks without fatal shader errors.

The approved macOS terrain stack is Godot 4.6, Forward+, Vulkan through MoltenVK, and Terrain3D `v1.0.2-stable`.

## WORLD-002

WORLD-002 integrated the pinned Terrain3D release into the main Free Tower Godot project without replacing the existing vertical slice.

![WORLD-002 Terrain3D runtime integration](../../../godot/docs/visual-review/WORLD-002/terrain3d-runtime.png)

The plugin loaded, the runtime confirmed Vulkan, the integration scene rendered correctly in three independent launches, the existing `Game.tscn` still ran, and the existing vertical slice remained untouched. The macOS-specific Vulkan setting introduced no Windows renderer override. Windows runtime is **NOT TESTED ON THIS MACHINE**.

The implementation is recorded in commit [`be1288729f358375f1a83a5305eb37cb3967a6bd`](https://github.com/Btkkgo/Freetower/commit/be1288729f358375f1a83a5305eb37cb3967a6bd).

## What We Learned

Technical correctness is not visual quality. More reasoning does not replace an art pipeline, and concept art is a visual target rather than a terrain generator. World building needs real tools. AI is most useful inside human-approved constraints, and rejected work should remain visible in the development record because it explains why the pipeline changed.

## Current State

| Area | Status |
| --- | --- |
| Terrain3D foundation | READY |
| World generation framework | NEXT |
| Production environment assets | NOT READY |
| Approved final Free Tower landmark | NOT READY |
| Player Controller | NOT STARTED |

## Next

The planned engineering stages are WORLD-003, World Generation Foundation, followed by WORLD-004, Rebuild Phase 0 Vertical Slice. Neither stage is complete or started by this devlog.
