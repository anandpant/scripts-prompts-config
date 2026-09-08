---
name: automation-audit
description: Audit Codex automations against remembered or requested intent, including cadence, active/paused status, prompt scope, target thread, and quiet/no-op behavior.
---

# Automation Audit

## Use This When

Use this when checking whether a recurring Codex automation still matches user
intent, especially monitors, PR babysitters, Sentry checks, reminders, and daily
digests.

Do not create or update automations directly from this skill. Produce a
reviewable recommendation unless the user explicitly asks to mutate an
automation.

## Helper Script

```sh
python3 ~/.agents/skills/automation-audit/scripts/audit_automations.py
```

The script reads `~/.codex/automations/*/automation.toml` and reports:

- id
- name
- kind
- status
- rrule
- target thread
- prompt hash
- prompt preview

## Audit Questions

- Is the automation active when it should be active?
- Is the cadence intentional, including 10-to-60 minute backoff patterns?
- Does the prompt instruct quiet no-op behavior when desired?
- Does it continue the right thread or run as the right cron/workspace job?
- Does it have enough source-of-truth context to act safely?
- Which update modes does the currently available automation tool support? Carry forward existing authorization for the same scope.

## Output

Return a table plus one recommendation per automation:

- keep
- pause
- update cadence
- update prompt
- convert heartbeat/cron
- archive owning thread after terminal completion
- no action
