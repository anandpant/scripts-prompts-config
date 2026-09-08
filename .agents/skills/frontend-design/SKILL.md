---
name: frontend-design
description: Design or refine interfaces with clear hierarchy, concise copy, recognizable icons, and progressive disclosure. Use for new UI and changes to an existing product's design.
---

# Frontend design

Start with the audience, the task, and the existing product. Preserve its design system and interaction conventions unless the brief asks to change them. For new work, choose a coherent visual direction grounded in the subject. Use the repository's framework, component library, and state/lifecycle conventions.

## Content and controls

- Keep user-facing text succinct and clear. Name what users can do and what happens next; omit implementation details unless they help a decision.
- No all-caps eyebrow labels above headings. Remove redundant labels rather than restyling them into another decorative treatment.
- Prefer recognizable icons over text for familiar actions and compact navigation. Use the project's icon family. Give icon-only controls accessible names and discoverable tooltips; retain a short visible label when the action is unfamiliar, consequential, or otherwise ambiguous. Never make users guess to save space.
- Show the primary task and essential information first. Reveal advanced settings, supporting evidence, and secondary actions on demand. Keep errors, required decisions, and important consequences visible.
- Group related information and give it a clear hierarchy. Avoid overwhelming users with every control, explanation, metric, or status at once. Use tables for comparisons and lists for straightforward content when they make scanning easier.
- Keep names consistent across controls, results, and messages. Empty and error states should explain the next useful action briefly.

## Visual choices

Use typography, spacing, color, and imagery to communicate hierarchy. Avoid decorative labels, arbitrary style rotation, and forced novelty. Choose layouts from the actual content; do not fit every section into the same cards or impose a fixed hero size.

Use real product assets when fidelity matters. Generate imagery only when it serves the brief. Motion should explain a change or support the narrative, respect reduced-motion preferences, and remain usable on slower devices. See `references/patterns.md` for optional patterns, not a required checklist.

## Verify the result

Inspect the rendered interface at relevant desktop and mobile sizes. Exercise the changed interaction and check keyboard access, accessible names, contrast, overflow, and applicable loading/error/empty states. Confirm that progressive disclosure leaves the main task easy to find. Review the actual visual result and user flow, not just the source code or a screenshot's existence.

Scale the work to the change. A copy fix does not require a redesign, another agent, or a full design-system exercise.
