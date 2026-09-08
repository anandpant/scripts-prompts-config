---
name: evidence-renderer
description: "Choose the right representation for complex agent findings: table, timeline, diagram, screenshot, diff summary, checklist, or source-backed bullets."
---

# Evidence Renderer

## Use This When

Use this when the user asks to see something differently, when a result is hard
to scan, or when evidence spans several tools, threads, repos, or PRs.

## Representation Choices

- Status comparison: table.
- Time/order/process: timeline.
- System boundaries or data flow: Mermaid diagram.
- UI/visual truth: screenshot or rendered artifact.
- Code review: findings-first list with file/line refs.
- Debugging evidence: command/result table.
- Long transcript evidence: compact cards with source refs.
- Tradeoff decision: options table with recommendation.
- Work orchestration: owner/status/blocker table.

## Rules

- Do not make the user ask twice for proof when the task is evidence-heavy.
- Prefer direct source links, local file links, PR links, command names, and
  exact timestamps over vague summaries.
- Avoid dumping raw logs unless the raw log itself is the requested artifact.
- Keep screenshots and diagrams tied to a specific claim.

## Output Template

Choose only the structure needed to explain the finding and its evidence. State material limits and next actions when relevant; do not force every answer into a template.
