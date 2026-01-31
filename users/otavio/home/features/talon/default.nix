{ inputs, lib, pkgs, ... }:
let
  gazeOcr = false;
  eyeTracking = false;
in
{
  nixpkgs.overlays = [ inputs.talon-nix.overlays.default ];

  services.snixembed = {
    enable = true;
    beforeUnits = [ "talon.service" ];
  };

  systemd.user.services.snixembed.Unit.After = [ "graphical-session.target" "dbus.service" ];

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
      (pkgs.python311.withPackages (p: (lib.attrValues { inherit (p) lxml beautifulsoup4 requests; })))
      (lib.optional pkgs.stdenv.isLinux [
        pkgs.xsel
        pkgs.xdg-utils
      ])
      (lib.optional gazeOcr pkgs.tesseract)
      (lib.optional eyeTracking pkgs.v4l-utils)
    ];

  # NOTE: If instead you use the git entry in the home.packages list above, you well encounter in error:
  # ```
  # error: collision between `/nix/store/sjrpbscvbwa3djc1fhgrcjc7q1qf9638-git-with-svn-2.42.0/bin/git-receive-pack'
  # and `/nix/store/gj71wiyzb6x8sxkkd7xxymk6m4jp3s1m-git-2.42.0/bin/git-receive-pack'
  # ```
  programs.git.enable = true;

  # Installing collected packages: pytz, tzdata, tifffile, six, screen-ocr, scipy, pytesseract, networkx, lazy-loader, imageio, scikit-image, python-
  # dateutil, pandas
  # ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the fo
  # llowing dependency conflicts.
  # torch 2.0.1+cpu requires filelock, which is not installed.
  # torch 2.0.1+cpu requires jinja2, which is not installed.
  # torch 2.0.1+cpu requires sympy, which is not installed.
  # 2024-04-24 08:12:35.281  INFO Talon OCR not available, will rely on external support.
  # 2024-04-24 08:12:35.284 DEBUG Dispatched launch events at 7.7976s, done at 14.2285s
  # 2024-04-24 08:12:35.310 ERROR cron interval error <function _rescan at 0x7f87cf7ae160>
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
          After = [
            "snixembed.service"
            "graphical-session.target"
            "graphical-session-pre.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];

        Service = {
          ExecStart = "${lib.getBin pkgs.talon}/bin/talon";
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
            PartOf = [ "graphical-session.target" ];
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
