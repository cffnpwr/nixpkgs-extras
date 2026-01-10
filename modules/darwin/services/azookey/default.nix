{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.azookey;
in {
  options.services.azookey = {
    enable = lib.mkEnableOption "azooKey Japanese Input Method Service";

    package = lib.mkPackageOption pkgs "azookey" { };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    system.activationScripts.extraActivation.text = ''
      OLD="/Library/Input Methods/azooKeyMac.app"
      NEW="${cfg.package}/Library/Input Methods/azooKeyMac.app"

      echo copying azookey into "$OLD"...
      if [ -d "$OLD" ]; then
        if ! diff -rq "$NEW" "$OLD" &>/dev/null; then
          rm -rf "$OLD"
          cp -R "$NEW" "$OLD"
        fi
      else
        cp -R "$NEW" "$OLD"
      fi
    '';
  };

  meta = with lib; {
    maintainers = with maintainers; [ cffnpwr ];
  };
}
