# Overlay packages to include in the build matrix.
# Each entry represents a package that is overridden by an overlay in this directory.
# Packages already defined in pkgs/default.nix (e.g. swiftPackages.sourcekitd-inproc,
# python3Packages.pybit7z) are intentionally excluded to avoid duplicate build entries.
pkgs:
let
  lib = pkgs.lib;

  # Helper: return a single-element list if pkg exists in prev (upstream nixpkgs),
  # else [].
  mkEntry =
    name:
    let
      drv = pkgs.${name} or null;
    in
    lib.optional (drv != null && lib.isDerivation drv) {
      inherit name;
      platforms = drv.meta.platforms or lib.platforms.all;
    };
in
lib.flatten [
  (mkEntry "aerospace")
  (mkEntry "discord")
  (mkEntry "spotify")
  (mkEntry "scroll-reverser")
  (mkEntry "swiftformat")
  (mkEntry "swiftlint")
  # zen-browser: only included when present in nixpkgs
  (mkEntry "zen-browser")
]
