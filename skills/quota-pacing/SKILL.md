---
name: quota-pacing
description: Check the Claude Code usage quota and pace work before launching agents or a long job. Use before starting parallel agents, large refactors, overnight batches, or when the quota is high or the user mentions limits, quota, or running out.
---

# Quota pacing

Check the quota before starting expensive work, and adapt the plan to it.

## 1. Read the quota

- Status line JSON: Claude Code passes `rate_limits.five_hour` and `rate_limits.seven_day` (each with `used_percentage` and `resets_at`) to the status line command. If you can see it (installed status line, or `~/.claude/statusline/statusline-quota.sh`), use it.
- With `quota-usage.sh` installed (`./install.sh --fable`), `~/.cache/claude-usage.json` holds the limits: `jq . ~/.cache/claude-usage.json` (`kind`, `percent`, `resets_at`, `model`). It is refreshed at most every 5 minutes.
- If neither exists, say you cannot read the quota and ask the user for the percentages. Do not guess.

## 2. Compute the pace

Weekly pace = share of the week already elapsed: `(now - (resets_at - 7 days)) / 7 days`, in percent. Compare it with the weekly use.

```bash
jq -r '.limits[] | select(.kind|test("week|seven";"i")) | "\(.percent)% used, resets \(.resets_at)"' ~/.cache/claude-usage.json
```

Gap = use minus pace. Negative: margin left. Positive: ahead of pace.

## 3. Adapt

- Margin left: go ahead as planned.
- Slightly ahead (a few points): fewer agents at once, shorter briefs, targeted tests instead of full suites.
- Clearly ahead or 5-hour window above 70 %: cheaper model for routine work (smaller model for mechanical edits), no new large batches, keep only what is essential.
- Around 95 % (either window): tell the user plainly, with the percentage and the reset time, and suggest waiting for the reset or asking for one. Do not start new work.

## 4. Never stop silently

Do not abandon work in progress without saying so. Let running agents finish or reach a clean stopping point, write down the state (what is done, what is left), and report it to the user. Re-check the quota between batches, not at every step.
