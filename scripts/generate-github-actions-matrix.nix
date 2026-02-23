{
  pkgs,
  lib,
  flake,
  allPackages,
}:
let
  scriptsLib = import ./lib.nix { inherit lib; };
  inherit (scriptsLib) getUpdatablePackages;

  updatablePkgPaths = getUpdatablePackages allPackages;

  systemToRunner = {
    "x86_64-linux" = "ubuntu-24.04";
    "aarch64-linux" = "ubuntu-24.04-arm";
    # Note: DeterminateNix does not support x86_64-darwin. Use aarch64-darwin runner with Rosetta 2.
    "x86_64-darwin" = "macos-15";
    "aarch64-darwin" = "macos-15";
  };

  # collect packages recursively from attrset
  collectPackagesRecursive =
    system: prefix: attrset:
    lib.flatten (
      lib.mapAttrsToList (
        name: value:
        let
          fullName = if prefix == "" then name else "${prefix}.${name}";
          updateGroup = value.meta.updateGroup or null;
        in
        # check if value is a derivation
        if lib.isDerivation value then
          # Check if package is available on the target system
          if lib.meta.availableOn { inherit system; } value then
            [
              {
                inherit system;
                package = fullName;
                os = systemToRunner.${system} or null;
                updatable = lib.elem fullName updatablePkgPaths;
                inherit updateGroup;
              }
            ]
          else
            [ ]
        # if value is an attrset with recurseForDerivations, recurse into it
        else if lib.isAttrs value && (value.recurseForDerivations or false) then
          collectPackagesRecursive system fullName value
        else
          [ ]
      ) attrset
    );

  # collect packages across all systems in flake.legacyPackages
  collectPackages =
    let
      systemPackages = lib.mapAttrsToList (
        system: packages: collectPackagesRecursive system "" packages
      ) flake.legacyPackages;
    in
    # flatten and filter out packages without os
    lib.filter (item: item.os != null) (lib.flatten systemPackages);

  # convert to GitHub Actions matrix format
  matrix = {
    include = collectPackages;
  };

  # convert to JSON
  matrixJson = builtins.toJSON matrix;
in
lib.getExe (
  pkgs.writeShellScriptBin "generate-github-actions-matrix" ''
    echo '${matrixJson}'
  ''
)
