# ADR-001 — Human-Directed, Codex-Assisted Development

- Status: Accepted
- Date: 2026-09-03

## Context

Early Free Tower work asked Codex to carry too much continuous implementation and design responsibility. FT-GD-001 and FT-GD-001A both passed their engineering checks but failed human visual review. ART-001 produced stronger concept images, but human review rejected them because the Bitcoin-native identity and the idea of freedom were still not expressed clearly enough.

Coding agents can execute scoped engineering work efficiently. They do not automatically replace a Product Owner, Game Designer, Technical Director, Art Director, or Human Playtester.

## Decision

Free Tower adopts this development loop:

Human Design → Scoped Codex Task → Implementation → Runtime / Visual Inspection → Human Approval → Next Task

Technical completion, visual acceptance, product approval, and human approval remain separate states. Codex may report its evidence, but may not promote a technical pass into human approval.

## Consequences

Positive consequences:

- Architecture remains intentional.
- Gameplay remains human-controlled.
- Visual failures are caught before they become production assumptions.
- AI tasks remain bounded and reviewable.
- Development history becomes auditable.

Tradeoffs:

- The process is slower than autonomous task chaining.
- Explicit human review gates are required.
- Rejected work remains visible as part of the development record.
