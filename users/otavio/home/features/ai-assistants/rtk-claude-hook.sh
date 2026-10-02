input=$(cat)

output=$(printf '%s' "$input" | rtk hook claude) || exit $?

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
rewritten=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.updatedInput.command // empty' 2>/dev/null || true)

if [[ "$cwd" == */.claude/worktrees/* && "$rewritten" =~ (^|[^[:alnum:]_-])rtk[[:space:]]+git([[:space:]]|$) ]]; then
  exit 0
fi

printf '%s' "$output"
