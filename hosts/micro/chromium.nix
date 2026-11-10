{
  # Keep --enable-unsafe-webgpu without Chromium's "unsupported command-line flag"
  # infobar on every window.
  programs.chromium = {
    enable = true;
    extraOpts.CommandLineFlagSecurityWarningsEnabled = false;
  };
}
