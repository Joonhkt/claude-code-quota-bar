#!/bin/bash
# Installs the quota status line for the current user (Linux, WSL, or macOS with GNU coreutils).
# Copies the scripts to ~/.claude/statusline/ and sets "statusLine" in ~/.claude/settings.json (a backup is kept).
set -eu
cd "$(dirname "$0")"
for c in jq python3; do command -v "$c" >/dev/null || { echo "Missing \"$c\": install it and run again."; exit 1; }; done
D=~/.claude/statusline
mkdir -p "$D" ~/.cache
install -m 755 statusline-quota.sh statusline-bar.py "$D/"
FABLE=0; AGENTS=0
for a in "$@"; do case "$a" in --per-model|--fable) FABLE=1 ;; --agents) AGENTS=1 ;; *) echo "Unknown option: $a"; exit 1 ;; esac; done
if [ "$AGENTS" = 1 ]; then
    install -m 755 agents-line.py "$D/"; mkdir -p ~/.claude/agents-progress
    echo "Agents line enabled (reads ~/.claude/agents-progress/, see README.md)."
else
    rm -f "$D/agents-line.py"
fi
if [ "$FABLE" = 1 ]; then
    command -v curl >/dev/null || { echo "Missing \"curl\" for --per-model."; exit 1; }
    install -m 755 quota-usage.sh "$D/"
    echo "Per-model quota enabled (quota-usage.sh reads the Claude Code login token, see README.md)."
else
    rm -f "$D/quota-usage.sh"
fi
S=~/.claude/settings.json
[ -f "$S" ] || echo '{}' > "$S"
cp "$S" "$S.before-statusline-$(date +%Y%m%d-%H%M%S)"
jq '.statusLine = {"type":"command","command":"~/.claude/statusline/statusline-quota.sh","refreshInterval":60}' "$S" > "$S.tmp" && mv "$S.tmp" "$S"
echo "Status line installed. It shows up after Claude Code's next response."
