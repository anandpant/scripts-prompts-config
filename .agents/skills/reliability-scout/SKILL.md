---
name: reliability-scout
description: Mine Codex transcripts, thread metadata, skills, automations, and repo instructions into reviewable evidence cards for repeated preferences, struggle patterns, contradictions, and improvement proposals.
---

# Reliability Scout

## Use This When

Use this for daily or ad hoc audits of agent reliability patterns:

- the user repeats the same instruction across threads
- agents struggle with a tool or process
- instructions conflict or confuse the model
- the user asks for information represented differently
- a defect pattern might need tests, hooks, CI, Nx, AST rules, or architecture
- skills/docs/catalogs may need updates

## Principle

Do cheap deterministic extraction first. Do not burn model tokens parsing raw
transcripts when a script can extract compact evidence references.

This skill is not allowed to update memory or durable config by itself. It
produces suggestion cards for user review.

## Helper Script

```sh
python3 ~/.agents/skills/reliability-scout/scripts/mine_codex_transcripts.py \
  --out .memory/reliability-scout/$(date +%F) \
  --max-files 650 \
  --since 2026-09-01 --until 2026-09-08
```

The script reads:

- `~/.codex/sessions/**/rollout-*.jsonl`
- `~/.codex/archived_sessions/rollout-*.jsonl`
- `~/.codex/state_5.sqlite`

It writes:

- `summary.json`
- `topic-message-candidates.csv`
- `assistant-struggle-candidates.csv`
- `token-usage-samples.csv`

## Suggestion Card Schema

Each proposal should include:

- category
- evidence refs
- quoted/excerpted evidence
- proposed action
- confidence
- impact
- risk
- whether this is one-off, repeated, or drift
- required user decision

## Accepted Action Types

- memory note
- skill patch
- repo instruction patch
- hook/CI/Nx/AST rule
- docs catalog update
- automation proposal
- architecture follow-up
- no action

## Evidence quality

Choose a date window for the audit. The helper samples files by modification time, filters events by UTC date, records original path/line/timestamp/model/channel/origin, and deduplicates repeated history within a thread. Human, delegated, review, automation, and ambiguous messages remain separate candidates. Confirm authorship and surrounding context before treating an excerpt as a preference or failure. Do not count wrappers, assistant analysis, or coordinator briefs as human complaints. Historical token counters are not a measure of spend, waste, model quality, or savings.
