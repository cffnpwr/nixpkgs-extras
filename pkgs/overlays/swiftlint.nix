final: prev: {
  swiftlint = prev.swiftlint.overrideAttrs (oldAttrs: rec {
    version = "0.63.0";
    src = prev.fetchurl {
      url = "https://github.com/realm/SwiftLint/releases/download/${version}/portable_swiftlint.zip";
      hash = "sha256-apzA4+CUZvzl6r1LkgzXFp6eVrYOEu4TQKeT6otgzrk=";
    };

    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };
  });
}
