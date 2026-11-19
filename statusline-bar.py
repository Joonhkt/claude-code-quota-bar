#!/usr/bin/env python3
"""Quota bar for the Claude Code status line (used for the 5-hour and the weekly limit).

Eighth-of-a-cell precision (▏▎▍▌▋▊▉).
Blue up to the smaller of (used, pace); orange from pace to used when ahead of pace,
green from used to pace when behind; grey after. The blue/orange (or green/grey) edge is the pace.
The percentage is written inside the bar, and the gap to the pace after it (+0.4).
Pace = share of the window already elapsed (5 hours or 7 days).

Usage: statusline-bar.py <used percent> <reset epoch> [window seconds, default 604800] [width, default 40]
"""
import sys
import time

used, reset = float(sys.argv[1]), float(sys.argv[2])
window = float(sys.argv[3]) if len(sys.argv) > 3 else 604800
WIDTH = int(sys.argv[4]) if len(sys.argv) > 4 else 40
STEPS = 8
BASE, AHEAD, MARGIN, EMPTY = 25, 208, 40, 242  # 256-colour codes

pace = max(0.0, min(100.0, (1 - (reset - time.time()) / window) * 100))
gap = used - pace
total = WIDTH * STEPS
a = round(min(used, pace) / 100 * total)
b = round(max(used, pace) / 100 * total)
if abs(gap) >= 0.15 and b == a:
    b = a + 1  # keep a real gap visible (at least one step)
mid = AHEAD if used > pace else MARGIN


def color(k):
    return BASE if k < a else mid if k < b else EMPTY


label = f"{used:.0f} %"
start = (WIDTH - len(label)) // 2
BLOCKS = " ▏▎▍▌▋▊▉"
out = []
for i in range(WIDTH):
    cols = [color(i * STEPS + j) for j in range(STEPS)]
    left = cols[0]
    k = next((j for j in range(STEPS) if cols[j] != left), STEPS)
    right = cols[k] if k < STEPS else left
    if start <= i < start + len(label):
        bg = max(set(cols), key=cols.count)
        out.append(f"\033[1;97;48;5;{bg}m{label[i - start]}")
    elif k == STEPS:
        out.append(f"\033[48;5;{left}m ")
    else:
        out.append(f"\033[38;5;{left};48;5;{right}m{BLOCKS[k]}")
gap_color = "1;38;5;208" if gap > 0 else "1;32"
sign = "+" if gap > 0 else ""
print("".join(out) + f"\033[0m \033[{gap_color}m{sign}{gap:.1f}\033[0m", end="")
