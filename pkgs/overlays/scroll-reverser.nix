final: prev:
let
  version = prev.scroll-reverser.version;
in
{
  scroll-reverser = prev.scroll-reverser.overrideAttrs (oldAttrs: {
    src = final.fetchurl {
      url = "https://github.com/pilotmoon/Scroll-Reverser/releases/download/v${version}/ScrollReverser-${version}.zip";
      hash = "sha256-CWHbtvjvTl7dQyvw3W583UIZ2LrIs7qj9XavmkK79YU=";
    };

    # Enable unpack phase to properly extract with signature preservation
    dontUnpack = false;

    nativeBuildInputs = [ prev.unzip ];

    sourceRoot = ".";

    # Remove AppleDouble files (._*) that break code signature verification
    postUnpack = ''
      /usr/sbin/dot_clean .
    '';

    # Use cp -R (same as claude package) to preserve code signature
    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r "Scroll Reverser.app" $out/Applications/

      runHook postInstall
    '';

    # Skip fixup phase to preserve signature
    dontFixup = true;

    # Add custom maintainer
    meta = oldAttrs.meta or { } // {
      maintainers = (oldAttrs.meta.maintainers or [ ]) ++ [ final.lib.maintainers.cffnpwr ];
    };
  });
}
