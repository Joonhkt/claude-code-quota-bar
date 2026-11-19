#!/bin/bash
# Optional (installed with --per-model): per-model quota for the status line.
# Reads the Claude Code login token from ~/.claude/.credentials.json, asks the account usage endpoint,
# and writes ONLY percentages and reset dates to ~/.cache/claude-usage.json (never the token).
# Started in the background by statusline-quota.sh, at most every 5 minutes.
set -u
out=~/.cache/claude-usage.json
tok=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null) || exit 0
[ -n "$tok" ] || exit 0
resp=$(curl -s -m 10 https://api.anthropic.com/api/oauth/usage \
    -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)
unset tok
# Keep only the limits (week, 5 h, per model): no other account data.
echo "$resp" | jq -c '{limits: [.limits[]? | {kind, percent, resets_at, model: .scope.model.display_name}]}' > "$out.tmp" 2>/dev/null \
    && [ -s "$out.tmp" ] && mv "$out.tmp" "$out"
rm -f "$out.tmp"
