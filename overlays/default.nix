final: prev:
{
  discord = prev.discord.override { withOpenASAR = true; };
} // (import ../pkgs) { pkgs = final; }
