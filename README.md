# claude-code-quota-bar

A status line for [Claude Code](https://docs.claude.com/en/docs/claude-code) that shows how much of your quota you have used, your pace, and when each limit resets. Optionally, it also shows the Fable limit and a second line with your running agents and their progress.

Unofficial: this project is not made by Anthropic, nor affiliated with or endorsed by it.

```
Opus 5.5 · 5h ▕████31 %░░░░▏ -29.0 14:34 · Fable ▮▮▮▮▯ 77 % (12:31) · Week ▕██████████████98 %███▌▏ +4.2 Thu 23:00
3 agents · 12/20 · done 14h05 | Tests 2/5 · Docs 4/4 · Build 6/11
```

In the terminal the bars are coloured (see below): the percentage is written inside each bar, and the number after it is your gap to the pace. The second line (running agents) is optional.

## What it shows

| Part | Meaning |
|---|---|
| Model | The current model, for example `Opus`. |
| **5h bar** | The 5-hour limit, drawn as a 20-cell bar with its pace over the 5 hours, the gap, and its reset time. |
| Fable (optional) | The Fable limit, `Fable ▮▮▮▮▯ 77 % (12:31)` (time of the last reading), when installed with `--fable`. Any other model with its own limit is shown the same way. Without the option, nothing about Fable is read or shown. |
| **Other limits** | Any other limit Claude Code reports (hourly, daily, …) appears on its own, with its reset time. |
| **Week bar** | The weekly limit, drawn as a 40-cell bar with its pace over the 7 days, the gap, and its reset day and time. |
| **Gap** | Shown after each bar: `+4.2` means ahead of an even pace (orange), `-29.0` means you have margin left (green). |
| Agents line (optional) | A second line, `3 agents · 12/20 · done 14h05 \| Tests 2/5 · Docs 4/4 · Build 6/11`: running agents and their progress, when installed with `--agents`. |

Bar colours:

- **blue**: what you used, up to the pace;
- **orange**: how far ahead of an even pace you are;
- **green**: the margin you still have;
- **grey**: the rest of the window.

Percentage colours: green below 70 %, orange from 70 %, red from 90 %.

## Install

You need `bash`, `jq`, `python3` and GNU `date` (Linux, WSL, or macOS with `coreutils`).

```bash
git clone https://github.com/joonhkt/claude-code-quota-bar.git
cd claude-code-quota-bar
./install.sh                # status line only
./install.sh --fable        # status line + Fable bar (same as --per-model)
./install.sh --agents       # status line + a second line with your running agents
./install.sh --fable --agents   # both
```

The install script does three things:

- it copies the scripts to `~/.claude/statusline/`;
- it sets `statusLine` in `~/.claude/settings.json`, after saving a dated backup;
- it sets a refresh every 60 seconds.

## About `--fable` (`--per-model`)

`quota-usage.sh` reads your Claude Code login token (`~/.claude/.credentials.json`) to ask the account usage endpoint for per-model limits, at most every 5 minutes. It writes only percentages and reset dates to `~/.cache/claude-usage.json`, never the token.

The endpoint is not a documented public API and may change. Enable this option only if you accept this read.

## About `--agents`

The agents line reads plain text files under `~/.claude/agents-progress/` (override with `AGENTS_LINE_DIR`):

- `agents.txt`: one running agent per line, `<id>=<Label>`;
- `<id>/progress.txt`: the agent's steps, one per line, `[ ]` to do, `[>]` in progress, `[x]` done; an optional first line `# started=<date>` gives an end-time estimate.

The line shows the number of agents, the steps done over the total, and an end-time estimate; then each agent with the step it is on (`Tests 2/5` = on step 2 of 5).

Ask your agents (in `CLAUDE.md` or their brief) to write their steps first, tick them as they go, and add/remove their line in `agents.txt`. The same script is also part of [claude-code-agent-guards](https://github.com/joonhkt/claude-code-agent-guards).

## Skills

One [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills) in [`skills/`](skills):

| Skill | What it does |
|---|---|
| [`quota-pacing`](skills/quota-pacing/SKILL.md) | Before launching agents or a long job, reads the quota (status line `rate_limits`, or `~/.cache/claude-usage.json`), compares weekly use to the pace, slows down when ahead (fewer agents, cheaper model), tells you around 95 % and suggests waiting for the reset, and never silently stops work in progress. |

Install:

```bash
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/
```

## Uninstall

1. Remove the `statusLine` key from `~/.claude/settings.json`, or restore the `settings.json.before-statusline-…` backup.
2. Delete `~/.claude/statusline/`.

## Licence

MIT, see [LICENSE](LICENSE).
