# Terrain3D integration

Free Tower uses Terrain3D as its terrain backend so later world-building work can use a maintained Godot-native terrain system. WORLD-002 only installs and validates that foundation; it does not define or replace the production map.

- Godot: `4.6.stable.official.89cea1439`
- Terrain3D: `v1.0.2-stable` (`plugin.cfg` version `1.0.2`)
- Source: `https://github.com/TokisanGames/Terrain3D/releases/tag/v1.0.2-stable`
- Verified release ZIP SHA-256: `a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2`
- Plugin path: `res://addons/terrain_3d/`
- License: MIT; the upstream `LICENSE.txt` remains in the plugin directory.

## Approved macOS renderer

macOS development requires Forward+ with the `vulkan` rendering-device driver (Vulkan through MoltenVK). Metal is not approved for Terrain3D. Compatibility/OpenGL3 is also not approved on the current development machine because the compatibility spike rendered large black terrain areas.

The project settings enforce this path on macOS. Windows keeps Godot's normal Forward+ path and has no platform-specific driver override from this integration; Windows runtime remains to be validated on a Windows machine or CI.

## Integration check

Open or run `res://scenes/world/tests/Terrain3DIntegrationTest.tscn`. Its single test-only Terrain3D region uses 256 samples at 0.25 m vertex spacing, producing an approximately 64 m by 64 m validation surface with a hill, a low area, and flat ground. All related files are under `scenes/world/tests/` and are not production map data.

The test intentionally uses one texture asset with automatic slope-texture mixing disabled. Enabling that two-texture mode with only one asset causes the absent second texture slot to render black.
