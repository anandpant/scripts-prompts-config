---
name: repo-quality-guardrails
description: Decide whether repeated defects or quality issues should become tests, hooks, CI checks, Nx targets, AST rules, lint rules, docs, or architecture changes.
---

# Repo Quality Guardrails

## Use This When

Use this when a repeated bug, review comment, or user frustration suggests a
missing mechanical guardrail.

Do not automatically turn every bug into a skill. Skills are for agent behavior;
quality guardrails are for repo behavior.

## Decision Matrix

- Deterministic code defect: add or adjust tests.
- Formatting/import/schema convention: lint, formatter, or AST rule.
- Monorepo build/test sequencing: Nx target, package script, or CI job.
- Runtime integration regression: integration/e2e test or smoke script.
- UI representation failure: visual regression, Storybook, screenshot test, or
  Playwright check.
- Repeated manual verification: CI workflow or local preflight.
- Ambiguous product behavior: issue/spec before enforcement.
- Architectural mismatch: design doc or implementation slice, not a prompt tweak.
- Agent process mistake: skill or AGENTS/CLAUDE instruction.

## Output

Recommend the simplest useful enforcement path. Include a fallback only when there is a real tradeoff. Cover relevant items:

- evidence
- affected repo/files
- proposed command or check
- where it should run: local hook, CI, Nx, test suite, or manual review
- expected false-positive risk
- migration/cleanup needed

## Bias

Prefer simple, repo-native checks over bespoke machinery. Use existing project
test runners, package scripts, and Nx graph conventions before adding new tools.
