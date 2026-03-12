final: prev:
let
  lib = prev.lib;

  # Read all entries in the current directory
  overlayEntries = builtins.readDir ./.;

  # Collect overlay attrsets from:
  #   - regular .nix files (excluding default.nix and matrix.nix)
  #   - subdirectories containing a default.nix
  overlays = builtins.concatMap (
    name:
    let
      fileType = overlayEntries.${name};
    in
    if
      fileType == "regular"
      && lib.strings.hasSuffix ".nix" name
      && name != "default.nix"
      && name != "matrix.nix"
    then
      [ (import (./. + "/${name}") final prev) ]
    else if fileType == "directory" && builtins.pathExists (./. + "/${name}/default.nix") then
      [ (import (./. + "/${name}/default.nix") final prev) ]
    else
      [ ]
  ) (builtins.attrNames overlayEntries);
in
# Merge all overlays
lib.foldl' (acc: overlay: acc // overlay) { } overlays
