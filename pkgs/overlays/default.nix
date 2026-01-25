final: prev:
let
  lib = prev.lib;

  # Read all files in the current directory
  overlayFiles = builtins.readDir ./.;

  # Filter to get only .nix files (excluding default.nix)
  overlayNames = builtins.filter (
    name:
    let
      fileType = overlayFiles.${name};
    in
    fileType == "regular" && lib.strings.hasSuffix ".nix" name && name != "default.nix"
  ) (builtins.attrNames overlayFiles);

  # Import and apply each overlay
  overlays = builtins.map (name: import (./. + "/${name}") final prev) overlayNames;
in
# Merge all overlays
lib.foldl' (acc: overlay: acc // overlay) { } overlays
