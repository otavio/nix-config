{
  # Keep --enable-unsafe-webgpu without Brave's "unsupported command-line flag"
  # infobar on every window.
  environment.etc."brave/policies/managed/command-line-flags.json".text = builtins.toJSON {
    CommandLineFlagSecurityWarningsEnabled = false;
  };
}
