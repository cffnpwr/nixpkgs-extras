# Overlay packages to include in the build matrix.
# Each entry represents a package that is overridden by an overlay in this directory.
# Packages already defined in pkgs/default.nix (e.g. swiftPackages.sourcekitd-inproc,
# python3Packages.pybit7z) are intentionally excluded to avoid duplicate build entries.
#
# updatable: if true, the package is included as an update target in the update-pkg script.
#            Set to true only for packages that define their own updateScript in this repo.
pkgs:
let
  lib = pkgs.lib;

  # Helper: return a single-element list if pkg exists in prev (upstream nixpkgs),
  # else [].
  mkEntry =
    name: extra:
    let
      drv = pkgs.${name} or null;
    in
    lib.optional (drv != null && lib.isDerivation drv) (
      {
        inherit name;
        platforms = drv.meta.platforms or lib.platforms.all;
        updatable = false;
      }
      // extra
    );
in
lib.flatten [
  (mkEntry "aerospace" { })
  (mkEntry "discord" { })
  (mkEntry "spotify" { })
  (mkEntry "scroll-reverser" { updatable = true; })
  (mkEntry "swiftformat" { updatable = true; })
  (mkEntry "swiftlint" { updatable = true; })
  (mkEntry "lefthook" { updatable = true; })
  (mkEntry "zed-editor" { })
  # zen-browser: only included when present in nixpkgs
  (mkEntry "zen-browser" { })
]
