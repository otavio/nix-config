{ lib, pkgs, ... }:
let
  gazeOcr = false;
  eyeTracking = false;
in
{
  imports = [ ../snixembed ];

  home.packages =
    assert (
      lib.assertMsg
        (
          !gazeOcr || (gazeOcr && eyeTracking)
        ) "gaze-ocr cannot be enabled without eye-tracking"
    );
    lib.flatten [
      # These are from my fidgetingbits-talon repo, so need to be global
      pkgs.just

      # FIXME: Double check these are actually needed anymore?
      (pkgs.python312.withPackages (p: (lib.attrValues { inherit (p) lxml beautifulsoup4 requests; })))
      (lib.optional pkgs.stdenv.isLinux [
        pkgs.xsel
        pkgs.xdg-utils
      ])
      (lib.optional gazeOcr pkgs.tesseract)
      (lib.optional eyeTracking pkgs.v4l-utils)
    ];

  # Enabled through the module rather than added to home.packages, where a
  # second git derivation collides with git-with-svn on git-receive-pack.
  programs.git.enable = true;

  home.activation.talonInstallTesseract = lib.mkIf gazeOcr ''
    if ! ~/.talon/bin/pip show screen-ocr\[tesseract\] >/dev/null 2>&1; then
      ~/.talon/bin/pip install screen-ocr\[tesseract\]
    fi
  '';

  # WARNING: This is undocumented, so very likely to break
  home.file.".config/Talon/Talon.conf".text = ''
    [General]
    IAgreeToEULAVersion=5
  '';

  systemd.user = {
    targets = {
      talon = {
        Unit = {
          description = "Talon is running";
          wants = [ "talon.service" ];
        };
      };
    };
    services = {
      talon = {
        Unit = {
          Description = "Talon Voice";
          Documentation = "https://talonvoice.com/";
          Wants = [ "tray.target" ];
          After = [
            "tray.target"
            "graphical-session-pre.target"
          ];
        };
        # Wanted by, never PartOf: graphical-session.target sets
        # StopWhenUnneeded, which would take Talon down with it.
        Install.WantedBy = [ "graphical-session.target" ];

        Service = {
          ExecStart = "${lib.getBin pkgs.talon-fhs}/bin/talon";
          Restart = "always";
        };
      };
      talon-watchdog =
        let
          # FIXME(talon): once we correctly fix the app installation for talon to use the icon,
          # maybe we could use that to set the icon?
          talon-notify = pkgs.writeShellApplication {
            name = "talon-notify";
            runtimeInputs = [ pkgs.libnotify ];
            text = ''
              #shellcheck disable=SC2086,SC2068
              ${lib.getBin pkgs.libnotify}/bin/notify-send -i ${./talon-48x48.png} "''$@"
            '';
          };

          watchdogScript = pkgs.writeShellApplication {
            name = "talon-watchdog";
            runtimeInputs = lib.flatten [
              (builtins.attrValues {
                inherit (pkgs)
                  inotify-tools# inotifywait
                  coreutils# cut
                  ;
              })
              talon-notify
            ];
            text = builtins.readFile ./talon-watchdog.sh;
          };
        in
        {
          Unit = {
            Description = "Talon Voice Watchdog";
            Documentation = "https://talonvoice.com/";
            After = [ "talon.target" ];
          };
          Service = {
            ExecStart = "${lib.getBin watchdogScript}/bin/talon-watchdog";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
    };
  };
}
