---
name: agent-browser
description: Use agent-browser for public, local, or otherwise unauthenticated browser interaction and verification. Inspect rendered UI and exercise changed behavior after starting a web dev server.
---

# Browser interaction and verification

Use `agent-browser` for public/local work. Preserve an existing signed-in session through a supported app integration when required by the task. Follow the selected integration's current tool contract; do not require a historical model or missing skill.

Check `command -v agent-browser` and relevant `--help` before relying on commands. Use a named session for the task so another agent's browser is not closed or changed.

```sh
agent-browser --session task open http://localhost:3000
agent-browser --session task snapshot -i
agent-browser --session task screenshot
agent-browser --session task console
agent-browser --session task errors
```

Wait for an observed element, route, or expected state. Do not assume network-idle on a streaming/realtime app. Interact using the snapshot's refs and re-snapshot after navigation or meaningful DOM changes.

When verifying UI, inspect the screenshot and exercise the changed interaction. Check actual console messages and uncaught page errors through the browser tool. `window.__consoleErrors` is not a browser API; an absent ad hoc collector proves nothing. A framework overlay check alone also does not establish error-free behavior.

Capture collection before the action being tested. If the tool attached too late to capture startup errors, reload or repeat the action with collection active. Do not clear errors before examining them. Confirm the changed flow's content, state, and navigation, not just a nonempty page. Correlate browser failures with the relevant server logs without dumping secrets.

Fix in-scope failures and repeat affected checks. Report what was exercised and any unobserved behavior. Close only the task's owned session when done. Browser proof is part of a UI implementation task, not an optional offer after declaring it complete.

For a repeatable healthy/error capture smoke test, see `scripts/verify_error_capture.py`.
