# Nix module to manage macOS third-party input sources.
#
# This module provides options for configuring third-party input sources on macOS.
#
# NOTE: The `defaults write com.apple.inputsources` command fails because cfprefsd
# enforces entitlement-based access control on this domain. Only processes with the
# private entitlement `com.apple.private.security.storage.inputsources` (currently
# only Apple's KeyboardSettings.appex) can write to this domain.
# The activation script is temporarily disabled pending a proper CLI tool
# ([cffnpwr/darwin-ism](https://github.com/cffnpwr/darwin-ism)) that uses
# TISEnableInputSource API to manage input sources.
#
# This module is inspired by:
# - https://github.com/natsukium/dotfiles/blob/main/modules/darwin/inputsources.nix
# - https://github.com/nix-darwin/nix-darwin/blob/master/modules/system/defaults-write.nix

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.system.defaults.inputsources;

  inherit (lib)
    mkOption
    types
    mdDoc
    literalExpression
    mkIf
    ;
in
{
  options.system.defaults.inputsources = {
    AppleEnabledThirdPartyInputSources = mkOption {
      type = types.nullOr (types.listOf types.attrs);
      default = null;
      description = mdDoc ''
        List of third-party input sources to enable.

        This option manages the `AppleEnabledThirdPartyInputSources` list in
        `~/Library/Preferences/com.apple.inputsources.plist` at the user level.
        This list contains only third-party input sources (such as Google Japanese IME,
        Sogou Pinyin, etc.) and does not affect system default input sources
        (like U.S. keyboard or built-in Japanese input).

        Each input source is specified as an attribute set with keys like:
        - `Bundle ID`: The bundle identifier of the input source
        - `InputSourceKind`: The kind of input source ("Keyboard Input Method", "Input Mode", etc.)
        - `Input Mode`: (Optional) The input mode identifier

        To view the current third-party input sources on your system, run:
        ```bash
        defaults read ~/Library/Preferences/com.apple.inputsources AppleEnabledThirdPartyInputSources
        ```
      '';
      example = literalExpression ''
        [
          {
            "Bundle ID" = "com.google.inputmethod.Japanese";
            InputSourceKind = "Keyboard Input Method";
          }
          {
            "Bundle ID" = "com.google.inputmethod.Japanese";
            "Input Mode" = "com.apple.inputmethod.Roman";
            InputSourceKind = "Input Mode";
          }
          {
            "Bundle ID" = "com.google.inputmethod.Japanese";
            "Input Mode" = "com.apple.inputmethod.Japanese";
            InputSourceKind = "Input Mode";
          }
        ]
      '';
    };
  };

  # TODO: Re-enable activation script once [cffnpwr/darwin-ism](https://github.com/cffnpwr/darwin-ism) CLI tool is available.
  # The tool will use TISEnableInputSource API to manage input sources without
  # requiring the private entitlement `com.apple.private.security.storage.inputsources`.
  config = mkIf (pkgs.stdenv.isDarwin && cfg.AppleEnabledThirdPartyInputSources != null) { };

  meta.maintainers = with lib.maintainers; [ cffnpwr ];
}
