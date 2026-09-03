# DEV-DESIGN-001 — Why Free Tower Changed Its AI Development Workflow

> Discussion draft saved because GitHub Discussions is not currently enabled for this repository.

# 为什么 Free Tower 改变了 AI 开发方式

Free Tower 在 Godot 重启后，第一步是让 Codex 建立一张可以运行的约 100 m × 100 m Whitebox。

工程上它是成功的，但视觉上完全不够。

随后 Codex 在原 Whitebox 上加入草、树、岩石、水、Shader、灯光和新的塔体。第二次依旧没有达到项目的视觉要求。

这两次失败帮助我们确认了一件事：Coding Agent 很适合执行明确的工程任务，但不能因为它会写 Shader、生成 Mesh、修改 Scene，就假设它自动拥有 Environment Artist、Level Designer 和 Art Director 的能力。

后来我们又尝试了 Concept Art。图像质量提高了，但 Free Tower 的核心身份——Bitcoin-native，以及“Freedom / 自由”——仍然没有真正建立起来。四张 Concept Art 因此全部停留在 Exploration Reference，Human Review 没有批准。

我们最终没有继续堆 Prompt，而是改变了生产方式：

Human Design → Art Direction → World Builder → Terrain System → Asset Pipeline → Runtime Review → Human Approval

Codex 仍然参与开发，但它在明确的边界内工作。技术通过不等于视觉通过，视觉通过也不能替代 Human Approval。Rejected 的场景、概念和设计决策同样属于项目历史，失败不会被隐藏。

下一步计划是 WORLD-003，建立真正的 World Generation Foundation；之后是 WORLD-004，使用新的工具链重新构建第一张 Vertical Slice。这两项工作目前都没有开始。

## English Summary

Free Tower is moving from prompt-driven, primitive-based environment generation toward a human-directed, tool-driven world-building pipeline.

The key lesson from our first Godot iterations was simple: technical correctness is not visual quality. We now separate art direction, world building, asset production, runtime validation, and human approval. Rejected prototypes remain part of the public record because they explain why the pipeline changed.
