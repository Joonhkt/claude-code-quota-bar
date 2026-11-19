#!/bin/bash
# Claude Code status line: model, every rate limit Claude Code reports (5 h, week, and any other),
# with reset times. Percentages turn orange at 70 % and red at 90 %.
# The weekly limit is drawn as a bar with your pace (see statusline-bar.py).
input=$(cat)
field() { echo "$input" | jq -r "$1 // empty"; }

color() {
    local p=$1
    if [ "$p" -ge 90 ]; then printf '\033[31m'; elif [ "$p" -ge 70 ]; then printf '\033[33m'; else printf '\033[32m'; fi
}

# part <label> <percent> <reset epoch> <date format> [decimals]
part() {
    local label=$1 pct=$2 reset=$3 fmt=$4 dec=${5:-0}
    [ -z "$pct" ] && return
    local p shown
    p=$(printf '%.0f' "$pct")
    shown=$(LC_NUMERIC=C printf "%.${dec}f" "$pct")
    printf '%s%s %s %%\033[0m resets %s' "$(color "$p")" "$label" "$shown" "$(date -d "@$reset" "$fmt")"
}

FIVE=$(part "5h" "$(field .rate_limits.five_hour.used_percentage)" "$(field .rate_limits.five_hour.resets_at)" '+%H:%M')
WEEK=$(part "Week" "$(field .rate_limits.seven_day.used_percentage)" "$(field .rate_limits.seven_day.resets_at)" '+%a %d %H:%M' 1)

# Bars: filled with the percentage written inside, pace edge, gap after it.
# 5-hour bar (20 cells, pace over 5 hours) then weekly bar (40 cells, pace over 7 days).
FPCT=$(field .rate_limits.five_hour.used_percentage); FRES=$(field .rate_limits.five_hour.resets_at)
if [ -n "$FPCT" ] && [ -n "$FRES" ]; then
    BAR=$(timeout 1 python3 -I "$(dirname "$0")/statusline-bar.py" "$FPCT" "$FRES" 18000 20 2>/dev/null)
    [ -n "$BAR" ] && FIVE="5h $BAR $(date -d "@$FRES" '+%H:%M')"
fi
WPCT=$(field .rate_limits.seven_day.used_percentage); WRES=$(field .rate_limits.seven_day.resets_at)
if [ -n "$WPCT" ] && [ -n "$WRES" ]; then
    BAR=$(timeout 1 python3 -I "$(dirname "$0")/statusline-bar.py" "$WPCT" "$WRES" 604800 40 2>/dev/null)
    [ -n "$BAR" ] && WEEK="Week $BAR $(date -d "@$WRES" '+%a %H:%M')"
fi

# Any other limit Claude Code may report (hourly, daily, ...) is shown too, with its reset time.
OTHERS=""
for k in $(echo "$input" | jq -r '.rate_limits // {} | keys[]' 2>/dev/null); do
    case "$k" in five_hour|seven_day) continue ;; esac
    case "$k" in one_hour|hour|hourly) L="1h" ;; daily|one_day|day) L="Day" ;; *) L=$(echo "$k" | tr '_' ' ') ;; esac
    P=$(part "$L" "$(field ".rate_limits.$k.used_percentage")" "$(field ".rate_limits.$k.resets_at")" '+%H:%M')
    [ -n "$P" ] && OTHERS="${OTHERS:+$OTHERS · }$P"
done
[ -n "$OTHERS" ] && FIVE="${OTHERS}${FIVE:+ · $FIVE}"

# Optional per-model limits (install with --per-model): read from ~/.cache/claude-usage.json,
# refreshed in the background at most every 5 minutes by quota-usage.sh.
MODELS=""
U=~/.cache/claude-usage.json
if [ -x "$(dirname "$0")/quota-usage.sh" ]; then
    if [ ! -f "$U" ] || [ $(( $(date +%s) - $(stat -c %Y "$U") )) -gt 300 ]; then
        touch "$U"; (timeout 15 "$(dirname "$0")/quota-usage.sh" >/dev/null 2>&1 &)
    fi
    while IFS=$'\t' read -r M MP; do
        [ -z "$M" ] && continue
        MP=${MP%.*}; n=$(( (MP + 10) / 20 )); [ "$n" -gt 5 ] && n=5
        MB=$(printf '%*s' "$n" '' | sed 's/ /▮/g')$(printf '%*s' $(( 5 - n )) '' | sed 's/ /▯/g')
        MODELS="${MODELS:+$MODELS · }$M $(color "$MP")${MB} ${MP} %$(printf '\033[0m') ($(date -r "$U" +%H:%M))"
    done < <(jq -r '.limits[]? | select(.model != null) | [.model, (.percent|tostring)] | @tsv' "$U" 2>/dev/null)
fi

MODEL=$(field .model.display_name)
out=$(printf "%s\n" "$FIVE" "$MODELS" "$WEEK" | grep -v "^$" | paste -sd "\n" | sed ":a;N;\$!ba;s/\n/ · /g")
echo "${MODEL:+$MODEL · }${out:-Quota: waiting for the first response}"

# Optional second line (install with --agents): running agents and their progress (see agents-line.py).
if [ -x "$(dirname "$0")/agents-line.py" ]; then
    AGENTS=$(timeout 2 python3 -I "$(dirname "$0")/agents-line.py" 2>/dev/null)
    [ -n "$AGENTS" ] && printf '\033[36m%s\033[0m\n' "$AGENTS"
fi
