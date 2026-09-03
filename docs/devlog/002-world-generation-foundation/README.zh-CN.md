# Free Tower 开发日志 #002 —— 给 AI 建立一个可控、可复现的世界生成系统

[English](./README.md)

## 从 Terrain3D 到世界生成系统

WORLD-002 回答的是：“Terrain3D 能不能在 Free Tower 的 Godot 工程里安全使用？”经过真实 Editor、Runtime 和 Vulkan 验证后，答案是可以。

WORLD-003 回答的是下一层问题：“Codex 怎么在不随机破坏地图设计的前提下，真正生成一个可以持续迭代的世界？”

这次完成的是一套可复用的世界生成基础，不是正式 Free Tower 地图。

## Human Layout + Procedural Naturalization

Free Tower 正式采用：

**Human Layout + Deterministic Procedural Naturalization**

它不是 Random World Generation。人类决定地图的身份和探索意图：

- 出生点、遗迹、营地和主要 POI；
- 河流与海岸的主路线；
- 主要高地、地标和空间结构；
- 排除区域和重要视线。

程序系统只能在这个设计上进行自然化：加入微地形变化、草木和岩石变化、密度差异、缩放、旋转和资产选择。Seed 可以改变草、树、岩石和微地形，但不能移动遗迹和出生点，不能重写河流主路线，也不能改变主要视线和宏观地图结构。

这让每一次地图修改都能够被复现、比较和审计。

## Resource 数据图与独立生成阶段

世界数据被拆成职责单一的 Godot Resource：`MapDefinition`、`BiomeDefinition`、`SplineFeatureDefinition`、`POIDefinition`、`WorldExclusionZone`、`TerrainControlRegion`、`EnvironmentAssetDefinition`、`EnvironmentAssetRegistry` 和 `SightlineDefinition`。

Resource 之间通过 stable ID 和 Registry 解析关系，避免循环依赖。`WorldGenerator` 只负责协调验证、地形、Biome、Scatter、Sightline 和 Report 等独立阶段。Terrain3D 的直接 API 调用全部隔离在 `Terrain3DAdapter` 内，世界生成逻辑不依赖插件细节。

Generation hash 使用 canonicalized deterministic data。字典顺序、浮点精度和向量表达被固定，耗时、Renderer、进程信息、生成节点数和截图路径等 runtime 字段不会污染 hash。

## 确定性意味着什么

Seed A（`3003`）独立运行三次，generation hash 完全一致：

`3f10628f8db0a69e3e5bcf1068edeeaa15436c0150240870a704e70436ae6e50`

Seed B（`4004`）产生了不同的自然化结果：

`95e25d8db32c5734e88725933d53a642f27d58250514c0559be9953b5a658b20`

但两个 Seed 的 authored POI hash 始终为 `16625905bde4b97e2b86123a2c33f29742cb3af7845854f79ed357f4392f9d8d`，River control point hash 始终为 `938c4eef79d0453287c1d2ce7690642bfbef4ecc303298191d3e7fa2c1b8082f`。

确定性能够支持可复现 Bug、可审查的地图变更和受控迭代，也为未来可能的服务器或多人一致性留下基础；WORLD-003 并没有实现多人游戏。

## Biome 与环境 Scatter

工程 Sandbox 覆盖 Grassland、Forest、Bamboo、RockHill、RiverBank、Coast 和 Ruins。Scatter 会检查 Biome、高度、坡度、水体距离、POI clearance、排除区和 Spline 植被排除范围。

高密度环境实例通过 MultiMesh 合并，而不是建立数千个独立节点。Seed A 生成 3,252 个实例，只使用三个 MultiMesh 和三个生成节点；Seed B 生成 3,286 个实例。

## Production Asset Gate

当前 Sandbox 的树、竹和岩石只是工程测试代理。它们明确标记为：

- `is_debug_proxy = true`
- `production_approved = false`

系统会在 production mode 主动拒绝这些资产。当前真实状态是：

- **TECHNICALLY VALID**
- **MISSING APPROVED ASSETS**

这个限制是有意设计的。它避免“程序员几何体已经跑起来了，于是被误认为美术完成”的问题再次发生。

## Sightline 验证

Sightline 使用 32 个固定内部采样点和 0.25 m 遮挡余量。遮挡比例不超过 0.10 为 `CLEAR`，不超过 0.60 为 `PARTIAL`，超过 0.60 为 `BLOCKED`。

Free Tower 将是世界中的主要地标，因此地图生成不能意外抹掉关键视线。WORLD-004 可以用这套系统保护 Spawn → Free Tower、Stone Hill → Free Tower、Forest → partial Free Tower visibility 和 Ruins → Free Tower。WORLD-003 尚未建立正式 Free Tower Map Definition。

## 验证结果

- 44 / 44 tests PASS；
- Seed A 三次独立运行 hash 一致；
- Seed B 改变自然化结果，但 authored POIs 与河流控制点不变；
- Terrain3D integration PASS；
- Apple M4 上 Forward+ / Vulkan Runtime PASS；
- Sandbox 3 / 3 PASS；
- 现有 `Game.tscn` regression PASS；
- 现有 Vertical Slice 未修改。

WORLD-003 有意不设置 FPS hard limit 或 generation millisecond hard limit。生成只运行一次，不会在 `_process()` 中持续重建世界。报告只记录 generation duration、instance count、MultiMesh count 和 generated node count，作为 WORLD-004 的工程基线。

## WORLD-003 不是什么

WORLD-003 不是最终地形、最终美术、生产级植被、最终 Free Tower 地标设计或 Gameplay 实现。人工验收结论是 **TECHNICAL PASS**，不是 FINAL MAP APPROVED，也不是 FINAL ART APPROVED。

## 下一步

WORLD-004 将用这套基础重建 Phase 0 Vertical Slice，把经过人类设计的正式地图数据接入生成流程。本开发日志没有开始 WORLD-004。
