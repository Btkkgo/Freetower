# FT-GD-001A — Freetower Visual Foundation Pass

本次 pass 将 FT-GD-001 的 Technical Whitebox 收敛为可审阅的 Scenic Prototype。范围严格限定为视觉基础，不加入玩法、运行时交互、经济系统、多人、AI 或在线服务。场景继续使用可替换的程序化代理几何，便于下一阶段替换正式资产。

## 交付记录（29 项）

1. **Branch** — `codex/free-tower-godot`
2. **Base commit** — `7f881609e307eeb1e99a4d355d7ea5ec651f6335`
3. **Files changed** — 世界场景、Freetower 场景、3 个 shader、视觉审阅文档及 A/B/C 截图。
4. **Terrain improvements** — 120×120 连续草地基底；营地、坡地与海岸采用低起伏自然过渡，移除大块平台式抬升。
5. **River improvements** — 以多段重叠椭圆水体形成弯曲、宽度变化的河道，并加入前景池、弯道与岸边小石。
6. **Coast improvements** — EarthBank、SandBank、左右沙袋与多枚 ShoreRock 形成草地→土→沙/岩→海水的分层岸线。
7. **Grass implementation** — `stylized_grass.gdshader` 提供 3 片/簇的低多边形草叶与轻微风摆；场景内布置多个草簇。
8. **Tree proxy implementation** — Young/Green/Core 三档树代理使用不规则多冠层、分叉树干与不同尺度，避免球冠+圆柱的单一重复。
9. **Ancient Banyan** — 粗主干、左右外展根系与三层冠幅组成 Ancient Banyan 地标。
10. **Rock proxy implementation** — 4 枚圆润低多边形岩石、不同旋转/尺度，并补充海岸岩石与河岸小石。
11. **Ruins improvements** — NaturalPlateau、ApproachRamp、柱体、残墙、立石与断拱梁组成连续遗迹坡台。
12. **Water shader** — `stylized_water.gdshader` 提供 TIME 驱动波动、透明度、边缘 Fresnel 高光及河/海两套参数。
13. **Soft toon material** — `stylized_toon.gdshader` 统一漫反射 toon 分段、粗糙度与柔和轮廓光参数。
14. **Sky improvements** — ProceduralSkyMaterial 使用蓝色天顶、明亮地平线与轻量化云朵代理。
15. **Lighting changes** — 暖色午后 Directional Sun、冷色天空环境光、软阴影与低密度高度雾。
16. **Freetower redesign** — Freetower 改为高挑多层塔体、脱离式浮层、三重环结构与青色浮动核心，避免棋子轮廓。
17. **Freetower scale/position** — 世界场景实例位于 `(40, -0.5, -225)`，缩放 `(0.8, 0.8, 0.8)`。
18. **Scenic Preview Camera** — 默认 `ScenicPreviewCamera` 位于 `(0, 3.4, 14)`，俯角 `-23°`，FOV `72°`。
19. **Screenshot A path** — `godot/docs/visual-review/FT-GD-001A/spawn-view.png`
20. **Screenshot B path** — `godot/docs/visual-review/FT-GD-001A/stone-hill-view.png`
21. **Screenshot C path** — `godot/docs/visual-review/FT-GD-001A/forest-edge-view.png`
22. **Runtime validation** — Forward+ Movie Maker 运行 10 帧成功，三张 1280×720 截图均由真实场景捕获。
23. **Headless validation** — Godot editor/headless 与 headless runtime 均退出码 `0`，未发现项目级 parse/script/resource 错误。
24. **Shader warnings** — 未发现 shader 编译错误；仅有 Godot 用户缓存目录旧 `FreeTower`/新 `Freetower` 大小写不一致警告。
25. **Approximate FPS** — Movie Maker 以 60 FPS 输出；CPU render average 约 `0.18–0.19 ms/frame`，不将其表述为独立实时 FPS 基准。
26. **Known visual limitations** — 当前仍是低多边形程序化代理；云朵、树冠、地形与遗迹尚未替换正式美术资产，缺少真实玩家尺度参照与完整地形雕刻。
27. **git diff --check** — 提交前执行并要求无输出。
28. **Commit hash** — 由本次独立提交的 Git 元数据记录（提交后以 `git log` 为准）。
29. **Final git status** — 本次提交后工作树应干净；不推送远程，不开始 FT-GD-002。

## 资产与范围边界

本 pass 只建立视觉方向与可替换代理：没有玩家控制器、采集、建造、战斗、敌人、昼夜、存档、NPC、任务、钱包、Bitcoin/Ordinals、多人或 AI 创作者逻辑。下一步必须先进行人工视觉验收，再决定是否进入后续任务。
