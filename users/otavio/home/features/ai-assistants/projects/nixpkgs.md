# nixpkgs project guidance

## Automation/AI disclosure (live policy)

Nixpkgs's `CONTRIBUTING.md` "Automation/AI policy" requires non-trivial
AI-assisted commits to carry an `Assisted-by:` Git trailer with at least the
tool name and primary model name + version, e.g.:

    Assisted-by: Claude Code (claude-opus-4-7)

Do **not** use `Co-authored-by:` for AI tooling — the policy treats that as a
violation. Exemptions: deterministic tools (formatters, IDEs, plain
autocomplete) and established bots like `nix-update`.

Disclosure also applies to pull-request bodies and review comments when AI
assistance is non-trivial there.

## Verify policy / PR / RFC status from the live repo

Before claiming any nixpkgs policy, RFC, or PR is in a particular status
(proposed, draft, merged, closed), verify against the current repo state — not
against a research-agent summary, which can be days stale. Quick checks:

- Policy text: `git show origin/master:CONTRIBUTING.md | grep -iE "AI|LLM|Assisted-by"`
- PR/RFC status: `gh pr view <num> --repo NixOS/nixpkgs --json state,mergedAt`

If the answer will be acted on (advice, PR comment, commit content), reverify
first.
