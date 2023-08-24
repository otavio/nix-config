_:

{
  xdg = {
    enable = true;
    mimeApps.enable = true;

    # We force the override so we workaround the error below:
    #   Existing file '/.../.config/mimeapps.list' is in the way of
    #   '/nix/store/...-home-manager-files/.config/mimeapps.list'
    # Issue: https://github.com/nix-community/home-manager/issues/1213
    configFile."mimeapps.list".force = true;
  };
}
