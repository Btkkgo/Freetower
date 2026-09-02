# FT-GD-001 — Freetower Godot Foundation

## Status

Foundation whitebox only. This document records the first Godot scene contract; it is not a claim that the full game is implemented.

## Runtime

- Godot: 4.6.stable.official.89cea1439
- Renderer: Forward+
- Language: GDScript (no gameplay scripts are required by FT-GD-001)
- Entry scene: `res://scenes/game/Game.tscn`

## Scene structure

```text
Game
├── World
│   └── World_VerticalSlice_01
└── DebugMarkers

World_VerticalSlice_01
├── Terrain
├── Environment
│   ├── Sun
│   └── WorldEnvironment
├── Water
│   ├── River
│   ├── Shore
│   └── Ocean
├── Blockout
│   ├── SpawnGrassland
│   ├── SuggestedCampArea
│   ├── Forest
│   ├── StoneHills
│   └── AncientRuinsPlateau
├── Landmarks
│   ├── AncientBanyan_Blockout
│   ├── RuinsCore_Blockout
│   └── Freetower_Blockout
├── SpawnPoints
│   ├── Spawn_Player_Default
│   └── SuggestedCampArea
└── WhiteboxPreviewCamera
```

## Whitebox layout

The playable planning area is approximately 100m × 100m, with the origin near the spawn grassland. North is positive Z and south is negative Z.

| Area | Approximate position / relationship |
| --- | --- |
| Spawn grassland | `(0, 0, 0)`, low and gently sloped blockout |
| Suggested camp | `(12, 0, -21)`, flat area near the river and forest |
| Forest | centered near `(-28, 0, 6)`, with an open natural path |
| Ancient banyan blockout | `(-25, 0, 13)` inside the forest |
| Stone hills | centered near `(28, 0, 7)`, raised rocks up to roughly +7m |
| Shallow river | x≈0, width≈5m, crossing the core map north–south |
| Coast / shore | south edge near z≈-52 |
| Ocean | south of the shore near z≈-88 |
| Ancient ruins plateau | `(0, 5, 36)`, elevated northern landmark |
| Freetower blockout | `(0, 0, -220)`, distant and visible beyond the coast |

The preview camera starts above the northern side of the slice and looks south across the grassland, camp, river, coast, ocean and distant Freetower.

## Deliberately not implemented

FT-GD-001 does not implement a player, movement, camera controller, UI, inventory, crafting, gathering, building, combat, enemies, day/night, save, NPC, AI, wallet, Bitcoin, Ordinals, multiplayer or civilization selection.

## Next-task interface

FT-GD-002 may add a player scene and controller while treating `Spawn_Player_Default` as the spawn contract and `WhiteboxPreviewCamera` as temporary preview-only content. The world scene and its spatial relationships should remain stable.
