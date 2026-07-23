#!/usr/bin/env bash
# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .workspace.project_dir')
path_disp=${current_dir/#"$HOME"/\~}
model_name=$(echo "$input" | jq -r '.model.display_name')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Current context-window token usage (input + cache creation + cache read)
current_usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$current_usage" != "null" ]; then
	input_tokens=$(echo "$current_usage" | jq '.input_tokens // 0')
	cache_creation=$(echo "$current_usage" | jq '.cache_creation_input_tokens // 0')
	cache_read=$(echo "$current_usage" | jq '.cache_read_input_tokens // 0')
	current_tokens=$((input_tokens + cache_creation + cache_read))
else
	current_tokens=0
fi

dim=$'\033[38;5;247m'   # labels, path, separators, numbers
track=$'\033[38;5;242m' # unfilled portion of a bar
bold=$'\033[1m'
reset=$'\033[0m'
sep=" ${dim}>${reset} "

# Format a token count compactly with no decimals: 31000 -> 31k, 1000000 -> 1M
fmt_short() {
	local n=$1
	if [ "$n" -ge 1000000 ]; then
		printf '%dM' $(((n + 500000) / 1000000))
	elif [ "$n" -ge 1000 ]; then
		printf '%dk' $(((n + 500) / 1000))
	else
		printf '%d' "$n"
	fi
}

# ANSI color for a 0-100 usage percentage (higher usage = worse)
color_for() {
	local pct=$1
	if [ "$pct" -lt 50 ]; then
		printf '\033[32m' # green
	elif [ "$pct" -lt 65 ]; then
		printf '\033[33m' # yellow
	elif [ "$pct" -lt 80 ]; then
		printf '\033[38;5;208m' # orange
	else
		printf '\033[31m' # red
	fi
}

# Thin 11-cell bar for a 0-100 percentage: colored ━ for filled, dim ─ for empty
make_bar() {
	local pct=$1 width=11 filled i out
	filled=$(((pct * width + 50) / 100))
	[ "$filled" -lt 0 ] && filled=0
	[ "$filled" -gt "$width" ] && filled=$width
	out=$(color_for "$pct")
	for ((i = 0; i < filled; i++)); do out+="━"; done
	out+="$track"
	for ((i = filled; i < width; i++)); do out+="─"; done
	out+="$reset"
	printf '%s' "$out"
}

# Compact countdown from a number of seconds: 3360 -> 56m, 302400 -> 3d12h
fmt_reset() {
	local secs=$1 d h m
	[ "$secs" -lt 0 ] 2>/dev/null && secs=0
	d=$((secs / 86400))
	h=$(((secs % 86400) / 3600))
	m=$(((secs % 3600) / 60))
	if [ "$d" -gt 0 ]; then
		printf '%dd%dh' "$d" "$h"
	elif [ "$h" -gt 0 ]; then
		printf '%dh%dm' "$h" "$m"
	else
		printf '%dm' "$m"
	fi
}

# Calculate used percentage with normalized context (accounting for ~16.5% autocompact buffer)
if [ -n "$remaining_pct" ]; then
	remaining_scaled=$(($(printf '%.0f' "$remaining_pct") * 10))
	usable_remaining=$(((remaining_scaled - 165) * 1000 / (1000 - 165)))
	[ "$usable_remaining" -lt 0 ] 2>/dev/null && usable_remaining=0
	[ "$usable_remaining" -gt 1000 ] 2>/dev/null && usable_remaining=1000
	used_scaled=$((1000 - usable_remaining))
	used_pct=$((used_scaled / 10))
elif [ "$current_usage" != "null" ] && [ "$context_size" -gt 0 ]; then
	used_pct=$((current_tokens * 100 / context_size))
else
	used_pct=0
fi
[ "$used_pct" -lt 0 ] 2>/dev/null && used_pct=0
[ "$used_pct" -gt 100 ] 2>/dev/null && used_pct=100

# Current git branch (empty outside a repo)
branch=$(git -C "$current_dir" symbolic-ref --quiet --short HEAD 2>/dev/null ||
	git -C "$current_dir" rev-parse --short HEAD 2>/dev/null || true)

# Line 1: path > branch > ctx <bar> <pct>% <used>/<total>
line1="${dim}${path_disp}${reset}"
[ -n "$branch" ] && line1+="${sep}${dim}${branch}${reset}"
line1+="${sep}${dim}ctx${reset} $(make_bar "$used_pct") $(color_for "$used_pct")${bold}${used_pct}%${reset}"
if [ "$current_tokens" -gt 0 ]; then
	line1+=" ${dim}$(fmt_short "$current_tokens")/$(fmt_short "$context_size")${reset}"
fi

# Line 2: model > 5h <bar> <pct>% <reset> > Week <bar> <pct>% <reset>
# rate_limits is only populated for Claude.ai (Pro/Max) sessions and only after
# the first API response, so each window is guarded independently.
now=$(date +%s)
build_window() {
	local label=$1 pct_raw=$2 reset_at=$3 pct seg
	[ -z "$pct_raw" ] && return 1
	pct=$(printf '%.0f' "$pct_raw")
	seg="${dim}${label}${reset} $(make_bar "$pct") $(color_for "$pct")${bold}${pct}%${reset}"
	if [ -n "$reset_at" ]; then
		seg+=" ${dim}$(fmt_reset $((${reset_at%.*} - now)))${reset}"
	fi
	printf '%s' "$seg"
}

fh_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
fh_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
wk_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
wk_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

line2="${dim}${model_name}${reset}"
if seg=$(build_window "5h" "$fh_pct" "$fh_reset"); then
	line2+="${sep}${seg}"
fi
if seg=$(build_window "Week" "$wk_pct" "$wk_reset"); then
	line2+="${sep}${seg}"
fi

printf '%s\n%s' "$line1" "$line2"
