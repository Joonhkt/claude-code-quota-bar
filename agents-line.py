#!/usr/bin/env python3
"""agents-line.py: a status line showing the agents that are running and how far they are.

Output example:  3 agents · 12/20 · done 14h05 | Tests 2/5 · Docs 4/4 · Build 6/11

File convention (all under AGENTS_LINE_DIR, default ~/.claude/agents-progress/):
  agents.txt            one running agent per line:  <id>=<Label>   ('#' lines are comments)
                        agents with the same Label are grouped
  agents-<name>.txt     another session's list; its line is prefixed with "<Name> : "
  <id>/progress.txt     the steps of agent <id>, one per line:
                          [ ] step not done      [>] step in progress      [x] step done
                        an optional first line "# started=<unix seconds or ISO date>" enables the end-time estimate
Each agent writes its steps first, then ticks them, and adds/removes its line in agents.txt
when it starts/finishes. Usage: agents-line.py   (reads nothing on stdin, prints one line per session).
"""
import datetime
import os
import pathlib
import re
import sys
import time

BASE = pathlib.Path(os.environ.get("AGENTS_LINE_DIR", pathlib.Path.home() / ".claude" / "agents-progress")).expanduser()
STEP = re.compile(r"\s*\[[x> ]\]")
STARTED = re.compile(r"#\s*started=(\S+)")


def read_lines(path):
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []


def steps(agent):
    lines = read_lines(BASE / agent / "progress.txt")
    return lines, [x for x in lines if STEP.match(x)]


def started(agent, lines):
    for l in lines[:3]:
        m = STARTED.match(l)
        if m:
            v = m.group(1)
            try:
                return float(v)
            except ValueError:
                try:
                    return datetime.datetime.fromisoformat(v).timestamp()
                except ValueError:
                    return None
    try:
        return (BASE / agent).stat().st_ctime  # approximation: creation of the agent folder
    except OSError:
        return None


def short(label):
    words = re.sub(r"[^\w' ]", " ", label.split(":")[0]).split() or ["?"]
    return words[0][:10]


def summary(path):
    entries = [l.strip() for l in read_lines(path) if l.strip() and not l.startswith("#")]
    groups = {}
    done_all = total_all = 0
    ends = []
    for l in entries:
        agent, _, label = l.partition("=")
        agent, label = agent.strip(), label.strip() or agent.strip()
        g = groups.setdefault(label, [0, 0, 0])
        g[0] += 1
        raw, st = steps(agent)
        done = sum(1 for x in st if x.lstrip().startswith("[x]"))
        g[1] += done
        g[2] += len(st)
        done_all += done
        total_all += len(st)
        t0 = started(agent, raw)
        if t0 and done and len(st) > done:
            ends.append(time.time() + (time.time() - t0) / done * (len(st) - done))
    count = sum(g[0] for g in groups.values())
    if not count:
        return 0, "0 agent"
    parts = [f"{short(n)} {min(d + 1, t)}/{t}" if t else f"{short(n)} ?" for n, (_, d, t) in groups.items()]
    eta = datetime.datetime.fromtimestamp(max(ends)).strftime("done %Hh%M") if ends else ""
    head = " · ".join(x for x in [f"{count} agent{'s' if count > 1 else ''}",
                                  f"{done_all}/{total_all}" if total_all else "", eta] if x)
    return count, head + " | " + " · ".join(parts)


def main():
    main_file = BASE / "agents.txt"
    for f in sorted(BASE.glob("agents*.txt"), key=lambda g: (g.name != "agents.txt", g.name)):
        count, line = summary(f)
        if f == main_file:
            print(line)
        elif count:
            name = f.stem.split("-", 1)[1].capitalize() if "-" in f.stem else f.stem
            print(f"{name} : {line}")
    if not main_file.exists():
        print("0 agent")


if __name__ == "__main__":
    sys.exit(main())
