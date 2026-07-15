#!/usr/bin/env bash
# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
dir_name=$(basename "$project_dir")
model_name=$(echo "$input" | jq -r '.model.display_name')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

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

# Format a token count compactly: 45231 -> 45.2k, 1200000 -> 1.2M
fmt_tokens() {
	local n=$1
	if [ "$n" -ge 1000000 ]; then
		printf '%d.%dM' $((n / 1000000)) $(((n % 1000000) / 100000))
	elif [ "$n" -ge 1000 ]; then
		printf '%d.%dk' $((n / 1000)) $(((n % 1000) / 100))
	else
		printf '%d' "$n"
	fi
}

# Calculate used percentage with normalized context (accounting for ~16.5% autocompact buffer)
if [ -n "$remaining_pct" ]; then
	# remaining_pct is 0-100, scale to 0-1000 for integer math
	remaining_scaled=$((remaining_pct * 10))
	# Normalize: subtract 165 (16.5%) buffer, scale to usable range
	usable_remaining=$(((remaining_scaled - 165) * 1000 / (1000 - 165)))
	# Clamp to 0-1000
	[ "$usable_remaining" -lt 0 ] 2>/dev/null && usable_remaining=0
	[ "$usable_remaining" -gt 1000 ] 2>/dev/null && usable_remaining=1000
	used_scaled=$((1000 - usable_remaining))
	used_pct=$((used_scaled / 10))
else
	# Fallback to token-based calculation
	context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
	if [ "$current_usage" != "null" ]; then
		used_pct=$((current_tokens * 100 / context_size))
	else
		used_pct=0
	fi
fi

# Clamp used_pct to 0-100
[ "$used_pct" -lt 0 ] 2>/dev/null && used_pct=0
[ "$used_pct" -gt 100 ] 2>/dev/null && used_pct=100

# Build 10-segment progress bar
filled=$((used_pct / 10))
empty=$((10 - filled))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

# Dynamic color based on usage thresholds
if [ "$used_pct" -lt 50 ]; then
	color="\033[32m" # green
elif [ "$used_pct" -lt 65 ]; then
	color="\033[33m" # yellow
elif [ "$used_pct" -lt 80 ]; then
	color="\033[38;5;208m" # orange
else
	color="\033[5;31m" # blinking red
	bar="💀 ${bar}"
fi
reset="\033[0m"

# Until the harness reports any usage, omit the meaningless "0% · 0" segment
if [ "$current_tokens" -eq 0 ]; then
	printf "\033[36m%s${reset} | \033[35m%s${reset}" \
		"$dir_name" \
		"$model_name"
else
	# Output: directory | model | ████░░░░░░ 40% · 45.2k
	printf "\033[36m%s${reset} | \033[35m%s${reset} | ${color}%s %d%% · %s${reset}" \
		"$dir_name" \
		"$model_name" \
		"$bar" \
		"$used_pct" \
		"$(fmt_tokens "$current_tokens")"
fi
