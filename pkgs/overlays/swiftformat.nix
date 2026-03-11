final: prev: {
  swiftformat = prev.swiftformat.overrideAttrs (oldAttrs: rec {
    version = "0.58.7";
    src = prev.fetchFromGitHub {
      owner = "nicklockwood";
      repo = "SwiftFormat";
      rev = version;
      hash = "sha256-CL+3z7wCIIJGWz7FPTFY9A+vBqyS6uGb6hgGRkJobUk=";
    };

    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };
  });
}
