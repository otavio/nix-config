# herdr's agent-state hooks, generated from the herdr in the flake so they track
# its version instead of being vendored by hand. Each agent's SessionStart hook
# reports its session to the running herdr server when inside a herdr pane; it is
# a no-op otherwise. Registration lives in claude.nix / codex.nix.
{ pkgs, inputs }:

pkgs.runCommandLocal "herdr-agent-hooks"
{
  nativeBuildInputs = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];
} ''
  export HOME=$TMPDIR/home
  mkdir -p "$HOME/.claude" "$HOME/.codex"
  echo '{}' >"$HOME/.claude/settings.json"
  : >"$HOME/.codex/config.toml"
  herdr integration install claude
  herdr integration install codex
  mkdir -p "$out"
  cp "$HOME/.claude/hooks/herdr-agent-state.sh" "$out/claude-hook.sh"
  cp "$HOME/.codex/herdr-agent-state.sh" "$out/codex-hook.sh"
''
