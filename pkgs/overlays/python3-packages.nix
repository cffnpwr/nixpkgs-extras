final: prev: {
  python3Packages = prev.python3Packages.override (oldAttrs: {
    overrides = prev.lib.composeExtensions (oldAttrs.overrides or (_: _: { })) (
      pfinal: _: {
        pybit7z = pfinal.callPackage ../pybit7z { pkgs = final; };
      }
    );
  });
}
