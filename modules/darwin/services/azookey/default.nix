{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.azookey;
in
{
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

  system.defaults.inputsources.AppleEnabledThirdPartyInputSources = [
    {
      "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
      InputSourceKind = "Keyboard Input Method";
    }
    {
      "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
      "Input Mode" = "com.apple.inputmethod.Roman";
      InputSourceKind = "Input Mode";
    }
    {
      "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
      "Input Mode" = "com.apple.inputmethod.Japanese";
      InputSourceKind = "Input Mode";
    }
  ];

  meta = with lib; {
    maintainers = with maintainers; [ cffnpwr ];
  };
}
